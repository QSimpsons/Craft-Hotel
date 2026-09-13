--[[ Mallorca Speedometer - server (SQL fuel) ]]

local function cleanPlate(plate)
    if type(plate) ~= 'string' then return '' end
    return (plate:gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

local function clamp(v)
    v = tonumber(v) or 100.0
    if v < 0.0 then return 0.0 end
    if v > 100.0 then return 100.0 end
    return v + 0.0
end

local function hasOx()
    return GetResourceState('oxmysql') == 'started'
end

local function hasMysqlAsync()
    return MySQL ~= nil and MySQL.Async ~= nil
end

local function dbScalar(query, params, cb)
    if hasOx() then
        exports.oxmysql:scalar(query, params, cb)
        return true
    end
    if hasMysqlAsync() then
        MySQL.Async.fetchScalar(query, params, cb)
        return true
    end
    return false
end

local function dbExec(query, params)
    if hasOx() then
        exports.oxmysql:execute(query, params)
        return true
    end
    if hasMysqlAsync() then
        MySQL.Async.execute(query, params)
        return true
    end
    return false
end

RegisterNetEvent('mallorca-speedometer:server:getFuel', function(plate)
    local src = source
    plate = cleanPlate(plate)

    if not Config.Fuel or not Config.Fuel.UseDatabase or plate == '' then
        TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, 100.0)
        return
    end

    local ok = dbScalar(
        'SELECT fuel FROM owned_vehicles WHERE UPPER(TRIM(plate)) = ? LIMIT 1',
        { plate },
        function(result)
            local fuel = 100.0
            if result ~= nil then
                fuel = clamp(result)
            end
            TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, fuel)
        end
    )

    if not ok then
        print('^3[mallorca-speedometer]^7 Geen oxmysql/mysql-async — tank start op 100%.')
        TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, 100.0)
    end
end)

RegisterNetEvent('mallorca-speedometer:server:saveFuel', function(plate, fuel)
    if not Config.Fuel or not Config.Fuel.UseDatabase then return end
    plate = cleanPlate(plate)
    fuel = clamp(fuel)
    if plate == '' then return end

    if not dbExec('UPDATE owned_vehicles SET fuel = ? WHERE UPPER(TRIM(plate)) = ?', { fuel, plate }) then
        -- stil falen als er geen DB-connector is
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    print('^2[mallorca-speedometer]^7 Gestart. SQL fuel = ' .. tostring(Config.Fuel and Config.Fuel.UseDatabase))
end)
