local ESX
local onDuty = {}
local towing = {}
local liveCalls = {}
local callSeq = 0

local function loadESX()
    if Config.Framework ~= 'esx' then
        return
    end
    while ESX == nil do
        if GetResourceState('es_extended') == 'started' then
            local ok, obj = pcall(function()
                return exports['es_extended']:getSharedObject()
            end)
            if ok and obj then
                ESX = obj
                break
            end
        end
        Wait(100)
    end
end

local function getPlayer(src)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

local function identifierOf(src)
    local xPlayer = getPlayer(src)
    if xPlayer then
        return xPlayer.getIdentifier(), xPlayer.getName()
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find('license:') then
            return id, GetPlayerName(src)
        end
    end
    return GetPlayerIdentifier(src, 0), GetPlayerName(src)
end

local function isEmployee(src)
    if Config.Framework ~= 'esx' or not Config.RequireJob then
        return true, 0
    end
    local xPlayer = getPlayer(src)
    if not xPlayer or not xPlayer.job then
        return false, 0
    end
    local name = xPlayer.job.name
    local grade = xPlayer.job.grade or 0
    local nameOk = (Config.IsAllowedJob and Config.IsAllowedJob(name)) or name == Config.JobName
    if not nameOk then
        return false, 0
    end
    if Config.IsAllowedGrade and not Config.IsAllowedGrade(grade) then
        return false, 0
    end
    return true, grade
end

local function isOnDuty(src)
    if not Config.RequireDuty then
        return true
    end
    return onDuty[src] == true
end

local function canWork(src)
    local employee = isEmployee(src)
    if not employee then
        return false, 'not_employee'
    end
    if not isOnDuty(src) then
        return false, 'need_duty'
    end
    return true
end

local function notify(src, key, extra)
    TriggerClientEvent('mallorca-takel:client:notify', src, key, extra)
end

local function dbAvailable()
    return GetResourceState('oxmysql') == 'started'
        or (MySQL and (MySQL.Async or MySQL.query or MySQL.Async ~= nil))
end

local function dbExecute(query, params, cb)
    params = params or {}
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params, function(result)
            if cb then cb(result) end
        end)
        return true
    end
    if MySQL and MySQL.Async and MySQL.Async.execute then
        MySQL.Async.execute(query, params, function(result)
            if cb then cb(result) end
        end)
        return true
    end
    if MySQL and MySQL.query then
        MySQL.query(query, params, function(result)
            if cb then cb(result) end
        end)
        return true
    end
    return false
end

local function dbFetch(query, params, cb)
    params = params or {}
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params, function(result)
            cb(result or {})
        end)
        return true
    end
    if MySQL and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll(query, params, function(result)
            cb(result or {})
        end)
        return true
    end
    if MySQL and MySQL.query then
        MySQL.query(query, params, function(result)
            cb(result or {})
        end)
        return true
    end
    cb({})
    return false
end

local function dbInsert(query, params, cb)
    params = params or {}
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:insert(query, params, function(id)
            if cb then cb(id) end
        end)
        return true
    end
    if MySQL and MySQL.Async and MySQL.Async.insert then
        MySQL.Async.insert(query, params, function(id)
            if cb then cb(id) end
        end)
        return true
    end
    return dbExecute(query, params, function()
        if cb then cb(nil) end
    end)
end

local function ensureTables()
    dbExecute([[
        CREATE TABLE IF NOT EXISTS `mallorca_impound` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `plate` VARCHAR(12) NOT NULL,
            `owner` VARCHAR(64) DEFAULT NULL,
            `props` LONGTEXT NOT NULL,
            `reason` VARCHAR(128) NOT NULL DEFAULT 'Getakeld',
            `officer` VARCHAR(64) DEFAULT NULL,
            `officer_name` VARCHAR(80) DEFAULT NULL,
            `price` INT NOT NULL DEFAULT 1500,
            `model` VARCHAR(64) DEFAULT NULL,
            `impounded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `plate` (`plate`),
            KEY `owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    dbExecute([[
        CREATE TABLE IF NOT EXISTS `mallorca_takel_calls` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `caller` VARCHAR(64) DEFAULT NULL,
            `caller_name` VARCHAR(80) DEFAULT NULL,
            `pos_x` FLOAT NOT NULL DEFAULT 0,
            `pos_y` FLOAT NOT NULL DEFAULT 0,
            `pos_z` FLOAT NOT NULL DEFAULT 0,
            `message` VARCHAR(180) DEFAULT NULL,
            `kind` VARCHAR(16) NOT NULL DEFAULT 'player',
            `status` VARCHAR(16) NOT NULL DEFAULT 'open',
            `taker` VARCHAR(64) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

local function dutyCount()
    local n = 0
    for src, state in pairs(onDuty) do
        if state then n = n + 1 end
    end
    return n
end

local function openCalls()
    local list = {}
    for _, call in pairs(liveCalls) do
        if call.status == 'open' or call.status == 'taken' then
            list[#list + 1] = call
        end
    end
    table.sort(list, function(a, b) return (a.id or 0) > (b.id or 0) end)
    return list
end

local function pushSync(src)
    local ident = select(1, identifierOf(src))
    local employee = isEmployee(src)

    local function send(impounds)
        TriggerClientEvent('mallorca-takel:client:sync', src, {
            duty = isOnDuty(src),
            employee = employee,
            onDutyCount = dutyCount(),
            calls = openCalls(),
            impounds = impounds or {},
            towing = towing[src]
        })
    end

    if not dbAvailable() then
        send({})
        return
    end

    if employee then
        dbFetch('SELECT * FROM mallorca_impound ORDER BY id DESC LIMIT 40', {}, send)
    else
        dbFetch(
            'SELECT * FROM mallorca_impound WHERE owner = ? ORDER BY id DESC LIMIT 20',
            { ident },
            send
        )
    end
end

local function addSocietyMoney(amount)
    if amount <= 0 then return end
    if GetResourceState('esx_addonaccount') == 'started' and ESX and ESX.GetSharedAccount then
        local account = ESX.GetSharedAccount(Config.Society)
        if account then
            account.addMoney(amount)
            return
        end
    end
    dbExecute(
        'UPDATE addon_account_data SET money = money + ? WHERE account_name = ?',
        { amount, Config.Society }
    )
end

CreateThread(function()
    loadESX()
    Wait(500)
    ensureTables()
    print('^3[mallorca-takel]^7 Custom takelscript gestart.')
end)

RegisterNetEvent('mallorca-takel:server:toggleDuty', function()
    local src = source
    if not isEmployee(src) then
        notify(src, 'not_employee')
        return
    end
    onDuty[src] = not onDuty[src]
    TriggerClientEvent('mallorca-takel:client:setDuty', src, onDuty[src])
    pushSync(src)
end)

RegisterNetEvent('mallorca-takel:server:sync', function()
    pushSync(source)
end)

RegisterNetEvent('mallorca-takel:server:towing', function(info)
    local src = source
    towing[src] = info
end)

RegisterNetEvent('mallorca-takel:server:impound', function(payload)
    local src = source
    local ok, reason = canWork(src)
    if not ok then
        notify(src, reason)
        return
    end

    payload = payload or {}
    local plate = tostring(payload.plate or ''):gsub('^%s+', ''):gsub('%s+$', ''):upper()
    if plate == '' then
        notify(src, 'no_vehicle')
        return
    end

    local officer, officerName = identifierOf(src)
    local props = payload.props or {}
    local propsJson = json.encode(props)
    local price = Config.Prices.impound
    local model = tostring(payload.model or props.name or '')
    local owner = nil

    local function finishInsert()
        dbInsert(
            [[INSERT INTO mallorca_impound (plate, owner, props, reason, officer, officer_name, price, model)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
            { plate, owner, propsJson, payload.reason or 'Getakeld', officer, officerName, price, model },
            function()
                dbExecute(
                    'UPDATE owned_vehicles SET stored = 1 WHERE UPPER(TRIM(plate)) = ?',
                    { plate }
                )
                addSocietyMoney(math.floor(price * 0.35))
                TriggerClientEvent('mallorca-takel:client:impoundOk', src)
            end
        )
    end

    dbFetch(
        'SELECT owner FROM owned_vehicles WHERE UPPER(TRIM(plate)) = ? LIMIT 1',
        { plate },
        function(rows)
            if rows and rows[1] then
                owner = rows[1].owner
            end
            finishInsert()
        end
    )
end)

RegisterNetEvent('mallorca-takel:server:release', function(id)
    local src = source
    id = tonumber(id)
    if not id then
        notify(src, 'no_vehicle')
        return
    end

    dbFetch('SELECT * FROM mallorca_impound WHERE id = ? LIMIT 1', { id }, function(rows)
        local rec = rows and rows[1]
        if not rec then
            notify(src, 'no_vehicle')
            return
        end

        local ident = select(1, identifierOf(src))
        local employee = isEmployee(src)
        if not employee and rec.owner and rec.owner ~= ident then
            notify(src, 'not_employee')
            return
        end

        local price = tonumber(rec.price) or Config.Prices.impound
        local xPlayer = getPlayer(src)

        if not employee then
            if xPlayer then
                if xPlayer.getMoney() < price then
                    notify(src, 'cannot_pay')
                    return
                end
                xPlayer.removeMoney(price, 'mallorca-takel-impound')
                addSocietyMoney(price)
            end
        end

        dbExecute('DELETE FROM mallorca_impound WHERE id = ?', { id }, function()
            TriggerClientEvent('mallorca-takel:client:releaseVehicle', src, rec)
            pushSync(src)
        end)
    end)
end)

RegisterNetEvent('mallorca-takel:server:bill', function(target, amount, reason)
    local src = source
    local ok, err = canWork(src)
    if not ok then
        notify(src, err)
        return
    end

    target = tonumber(target)
    amount = math.floor(tonumber(amount) or 0)
    reason = tostring(reason or 'Takeldienst')
    if not target or amount < Config.Prices.minBill or amount > Config.Prices.maxBill then
        return
    end

    local srcPed = GetPlayerPed(src)
    local tgtPed = GetPlayerPed(target)
    if srcPed == 0 or tgtPed == 0 then return end
    local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(tgtPed))
    if dist > 12.0 then return end

    if GetResourceState('esx_billing') == 'started' then
        local senderIdent = select(1, identifierOf(src))
        local targetIdent = select(1, identifierOf(target))
        dbInsert(
            [[INSERT INTO billing (identifier, sender, target_type, target, label, amount)
              VALUES (?, ?, 'society', ?, ?, ?)]],
            { targetIdent, senderIdent, Config.Society, reason, amount }
        )
        notify(src, 'billed')
        notify(target, 'bill_received')
        return
    end

    local billed = getPlayer(target)
    if billed and billed.getMoney() >= amount then
        billed.removeMoney(amount, 'mallorca-takel-bill')
        addSocietyMoney(math.floor(amount * 0.7))
        local xPlayer = getPlayer(src)
        if xPlayer then
            xPlayer.addMoney(math.floor(amount * 0.3), 'mallorca-takel-commission')
        end
        notify(src, 'billed')
        notify(target, 'bill_received')
    else
        notify(src, 'cannot_pay')
    end
end)

RegisterNetEvent('mallorca-takel:server:createCall', function(data)
    local src = source
    data = data or {}
    local ident, name = identifierOf(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    callSeq = callSeq + 1
    local call = {
        id = callSeq,
        caller = ident,
        callerName = name,
        src = src,
        x = data.x or coords.x,
        y = data.y or coords.y,
        z = data.z or coords.z,
        message = tostring(data.message or 'Pechhulp nodig'):sub(1, 180),
        kind = 'player',
        status = 'open'
    }
    liveCalls[call.id] = call
    dbInsert(
        [[INSERT INTO mallorca_takel_calls (caller, caller_name, pos_x, pos_y, pos_z, message, kind, status)
          VALUES (?, ?, ?, ?, ?, ?, 'player', 'open')]],
        { ident, name, call.x, call.y, call.z, call.message }
    )
    notify(src, 'call_sent')
    for employeeSrc, duty in pairs(onDuty) do
        if duty then
            TriggerClientEvent('mallorca-takel:client:newCall', employeeSrc, call)
            pushSync(employeeSrc)
        end
    end
end)

RegisterNetEvent('mallorca-takel:server:acceptCall', function(id)
    local src = source
    local ok, err = canWork(src)
    if not ok then
        notify(src, err)
        return
    end
    id = tonumber(id)
    local call = id and liveCalls[id]
    if not call or call.status ~= 'open' then
        return
    end
    call.status = 'taken'
    call.taker = select(1, identifierOf(src))
    dbExecute('UPDATE mallorca_takel_calls SET status = ?, taker = ? WHERE id = ? OR (status = ? AND pos_x = ? AND pos_y = ?)', {
        'taken', call.taker, id, 'open', call.x, call.y
    })
    TriggerClientEvent('mallorca-takel:client:callAccepted', src, call)
    if call.kind == 'npc' and call.model then
        TriggerClientEvent('mallorca-takel:client:spawnNpcVehicle', src, call)
    end
    if call.kind ~= 'npc' then
        local xPlayer = getPlayer(src)
        if xPlayer then
            xPlayer.addMoney(Config.Prices.callReward, 'mallorca-takel-call')
        end
    else
        local xPlayer = getPlayer(src)
        if xPlayer then
            xPlayer.addMoney(Config.Prices.npcCallReward, 'mallorca-takel-npc')
        end
    end
    for employeeSrc, duty in pairs(onDuty) do
        if duty then pushSync(employeeSrc) end
    end
end)

CreateThread(function()
    while true do
        local waitTime = (Config.NpcCalls and Config.NpcCalls.intervalMs) or 180000
        Wait(waitTime)
        if Config.NpcCalls and Config.NpcCalls.enabled and dutyCount() >= (Config.NpcCalls.minOnDuty or 1) then
            local spots = Config.NpcCalls.spots
            local models = Config.NpcCalls.models
            if spots and #spots > 0 then
                local spot = spots[math.random(1, #spots)]
                local model = models[math.random(1, #models)]
                callSeq = callSeq + 1
                local call = {
                    id = callSeq,
                    callerName = 'Pechhulp',
                    x = spot.x, y = spot.y, z = spot.z,
                    heading = 0.0,
                    message = 'Voertuig gestrand — NPC-oproep',
                    kind = 'npc',
                    status = 'open',
                    model = model
                }
                liveCalls[call.id] = call
                for src, duty in pairs(onDuty) do
                    if duty then
                        TriggerClientEvent('mallorca-takel:client:newCall', src, call)
                        pushSync(src)
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    onDuty[src] = nil
    towing[src] = nil
end)
