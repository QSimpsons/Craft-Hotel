local ESX
local PlayerData = {}
local nuiOpen = false
local onDuty = false
local callBlip
local depotBlip
local impoundBlip
local garageTruck = 0
local parkedVehicles = {}

local function notify(key, extra)
    local text = Config.Locale[key] or key
    if extra then
        text = text .. ' ' .. tostring(extra)
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(text)
    else
        BeginTextCommandThefeedDisplay('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedDisplay(false, true)
    end
end

local function loadESX()
    if Config.Framework ~= 'esx' then
        return true
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
    return ESX ~= nil
end

local function isEmployee()
    if Config.Framework ~= 'esx' or not Config.RequireJob then
        return true
    end
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

local function jobGrade()
    if PlayerData.job and PlayerData.job.grade then
        return PlayerData.job.grade
    end
    return 0
end

local function canWork()
    if not isEmployee() then
        return false, 'not_employee'
    end
    if Config.RequireDuty and not onDuty then
        return false, 'need_duty'
    end
    return true
end

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function setWaypoint(coords)
    SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
end

local function clearCallBlip()
    if callBlip then
        RemoveBlip(callBlip)
        callBlip = nil
    end
end

local function addCallBlip(coords)
    clearCallBlip()
    callBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(callBlip, 68)
    SetBlipColour(callBlip, 47)
    SetBlipScale(callBlip, 0.95)
    SetBlipRoute(callBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Takeloproep')
    EndTextCommandSetBlipName(callBlip)
end

local function nearbyPlayers(maxDist)
    local myPed = PlayerPedId()
    local myId = PlayerId()
    local myCoords = GetEntityCoords(myPed)
    local list = {}
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= myId then
            local ped = GetPlayerPed(player)
            local dist = #(GetEntityCoords(ped) - myCoords)
            if dist <= (maxDist or Config.BillDistance) then
                list[#list + 1] = {
                    id = GetPlayerServerId(player),
                    name = GetPlayerName(player),
                    dist = math.floor(dist * 10) / 10
                }
            end
        end
    end
    return list
end

local function nearbyTowInfo()
    local ped = PlayerPedId()
    local tow = Tow.FindTruck(ped)
    local attached = Tow.GetAttached()
    local target = 0
    if tow ~= 0 and attached == 0 then
        target = Tow.FindTarget(tow)
    end
    return {
        truck = Tow.Describe(tow),
        attached = Tow.Describe(attached),
        target = Tow.Describe(target)
    }
end

local function nuiPayload(extra)
    local info = nearbyTowInfo()
    local data = {
        duty = onDuty,
        employee = isEmployee(),
        grade = jobGrade(),
        job = Config.JobName,
        prices = Config.Prices,
        garage = Config.GarageVehicles,
        truck = info.truck,
        attached = info.attached,
        target = info.target,
        players = nearbyPlayers(8.0),
        depot = { x = Config.Depot.coords.x, y = Config.Depot.coords.y },
        impound = { x = Config.Impound.coords.x, y = Config.Impound.coords.y }
    }
    if extra then
        for k, v in pairs(extra) do
            data[k] = v
        end
    end
    return data
end

local function closeNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openNui(extra)
    if not isEmployee() then
        notify('not_employee')
        return
    end
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = nuiPayload(extra)
    })
    TriggerServerEvent('mallorca-takel:server:sync')
end

local function refreshNui(extra)
    if not nuiOpen then return end
    SendNUIMessage({
        action = 'update',
        data = nuiPayload(extra)
    })
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer or {}
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    if not isEmployee() then
        onDuty = false
        closeNui()
    end
end)

RegisterNetEvent('mallorca-takel:client:notify', function(key, extra)
    notify(key, extra)
end)

RegisterNetEvent('mallorca-takel:client:setDuty', function(state)
    onDuty = state and true or false
    notify(onDuty and 'duty_on' or 'duty_off')
    refreshNui()
end)

RegisterNetEvent('mallorca-takel:client:sync', function(payload)
    refreshNui(payload)
end)

RegisterNetEvent('mallorca-takel:client:newCall', function(call)
    if not onDuty then return end
    notify('call_new')
    PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
    refreshNui({ highlightCall = call and call.id })
end)

RegisterNetEvent('mallorca-takel:client:callAccepted', function(call)
    if not call then return end
    local coords = vector3(call.x + 0.0, call.y + 0.0, call.z + 0.0)
    addCallBlip(coords)
    setWaypoint(coords)
    notify('call_taken')
    closeNui()
end)

RegisterNetEvent('mallorca-takel:client:spawnNpcVehicle', function(call)
    if not call or not call.model then return end
    local model = joaat(call.model)
    RequestModel(model)
    local timeout = GetGameTimer() + 4000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(model) then return end
    local veh = CreateVehicle(model, call.x, call.y, call.z, call.heading or 0.0, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineHealth(veh, 180.0)
    SetVehicleBodyHealth(veh, 240.0)
    SetVehicleDoorsLocked(veh, 1)
    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent('mallorca-takel:client:releaseVehicle', function(record)
    if not record or not record.props then return end
    local props = record.props
    if type(props) == 'string' then
        props = json.decode(props)
    end
    if type(props) ~= 'table' then return end

    local model = props.model
    if not model then return end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(model) then return end

    local spawn = Config.Impound.spawn
    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    SetVehicleOnGroundProperly(veh)
    if ESX and ESX.Game and ESX.Game.SetVehicleProperties then
        ESX.Game.SetVehicleProperties(veh, props)
    end
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(model)
    notify('paid')
end)

local function doAttach(specificTarget)
    local ok, reason = canWork()
    if not ok then
        notify(reason)
        return
    end
    local success, msg = Tow.Attach(specificTarget)
    notify(msg)
    refreshNui()
    if success then
        TriggerServerEvent('mallorca-takel:server:towing', Tow.Describe(Tow.GetAttached()))
    end
end

local function takeParkedTruck(entity)
    local ok, reason = canWork()
    if not ok then
        notify(reason)
        return
    end
    if entity == 0 or not DoesEntityExist(entity) or not Tow.IsTowVehicle(entity) then
        notify('no_truck')
        return
    end
    Tow.EnsureControl(entity)
    FreezeEntityPosition(entity, false)
    SetVehicleDoorsLocked(entity, 1)
    SetVehicleUndriveable(entity, false)
    SetPedIntoVehicle(PlayerPedId(), entity, -1)
    garageTruck = entity
    if Entity(entity).state then
        Entity(entity).state:set('mallorcaTakelParked', false, true)
    end
    notify('truck_taken')
end

local function spawnParkedVehicles()
    if not Config.PlaceVehicles or not Config.ParkedVehicles then
        return
    end

    local created = 0
    for i = 1, #Config.ParkedVehicles do
        local slot = Config.ParkedVehicles[i]
        local c = slot.coords
        local existing = GetClosestVehicle(c.x, c.y, c.z, 2.8, 0, 71)
        if existing ~= 0 and #(GetEntityCoords(existing) - vector3(c.x, c.y, c.z)) < 2.8 then
            parkedVehicles[#parkedVehicles + 1] = existing
        else
            local hash = joaat(slot.model)
            RequestModel(hash)
            local timeout = GetGameTimer() + 4000
            while not HasModelLoaded(hash) and GetGameTimer() < timeout do
                Wait(10)
            end
            if HasModelLoaded(hash) then
                local veh = CreateVehicle(hash, c.x, c.y, c.z, c.w, true, true)
                SetVehicleOnGroundProperly(veh)
                SetVehicleNumberPlateText(veh, slot.plate or ('TAKEL' .. i))
                SetVehicleDoorsLocked(veh, 2)
                SetEntityAsMissionEntity(veh, true, true)
                SetVehicleHasBeenOwnedByPlayer(veh, true)
                FreezeEntityPosition(veh, true)
                if Entity(veh).state then
                    Entity(veh).state:set('mallorcaTakelParked', true, true)
                end
                parkedVehicles[#parkedVehicles + 1] = veh
                created = created + 1
                SetModelAsNoLongerNeeded(hash)
            end
        end
    end
    if created > 0 and isEmployee() then
        notify('parked_ready')
    end
end

AddEventHandler('mallorca-takel:internal:eyeTow', function(entity)
    doAttach(entity)
end)

AddEventHandler('mallorca-takel:internal:eyeDetach', function()
    doDetach()
end)

AddEventHandler('mallorca-takel:internal:eyeImpound', function()
    doImpound()
end)

AddEventHandler('mallorca-takel:internal:eyeCall', function(entity)
    local coords = GetEntityCoords(PlayerPedId())
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        coords = GetEntityCoords(entity)
    end
    TriggerServerEvent('mallorca-takel:server:createCall', {
        x = coords.x, y = coords.y, z = coords.z,
        message = 'Takelhulp via oogje'
    })
end)

AddEventHandler('mallorca-takel:internal:eyeTakeTruck', function(entity)
    takeParkedTruck(entity)
end)

AddEventHandler('mallorca-takel:internal:eyeTablet', function()
    if isEmployee() then
        openNui({ page = 'garage' })
    else
        notify('not_employee')
    end
end)

function MallorcaTakelIsEmployee()
    return isEmployee()
end

function MallorcaTakelCanWork()
    return canWork()
end

function MallorcaTakelOnDuty()
    return onDuty
end

local function doImpound()
    local ok, reason = canWork()
    if not ok then
        notify(reason)
        return
    end

    local attached = Tow.GetAttached()
    if attached == 0 then
        notify('need_attached')
        return
    end

    local pos = GetEntityCoords(PlayerPedId())
    if #(pos - Config.Impound.coords) > Config.ImpoundDistance then
        notify('need_attached')
        return
    end

    local info = Tow.Describe(attached)
    local props = nil
    if ESX and ESX.Game and ESX.Game.GetVehicleProperties then
        props = ESX.Game.GetVehicleProperties(attached)
    else
        props = {
            model = GetEntityModel(attached),
            plate = info and info.plate or ''
        }
    end

    TriggerServerEvent('mallorca-takel:server:impound', {
        plate = info and info.plate or '',
        model = info and info.model or '',
        props = props,
        reason = 'Getakeld'
    })
end

RegisterNetEvent('mallorca-takel:client:impoundOk', function()
    local attached = Tow.GetAttached()
    if attached ~= 0 then
        Tow.Detach(false)
        Tow.EnsureControl(attached)
        SetEntityAsMissionEntity(attached, true, true)
        DeleteVehicle(attached)
    end
    notify('impounded')
    TriggerServerEvent('mallorca-takel:server:towing', nil)
    TriggerServerEvent('mallorca-takel:server:sync')
    refreshNui()
end)

local function spawnTruck(model)
    local ok, reason = canWork()
    if not ok then
        notify(reason)
        return
    end
    if #(GetEntityCoords(PlayerPedId()) - Config.Depot.coords) > 18.0 then
        notify('no_truck')
        return
    end

    local spawn = Config.Depot.spawn
    local blocker = GetClosestVehicle(spawn.x, spawn.y, spawn.z, 3.0, 0, 71)
    if blocker ~= 0 then
        notify('spawn_blocked')
        return
    end

    local hash = joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then
        notify('no_vehicle')
        return
    end

    if garageTruck ~= 0 and DoesEntityExist(garageTruck) then
        DeleteVehicle(garageTruck)
    end

    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, 'TAKEL')
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)
    garageTruck = veh
    notify('truck_out')
    closeNui()
end

local function storeTruck()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = Tow.FindTruck(ped)
    end
    if veh == 0 or not Tow.IsTowVehicle(veh) then
        notify('no_truck')
        return
    end
    if #(GetEntityCoords(veh) - Config.Depot.store) > 12.0 then
        notify('no_truck')
        return
    end
    TaskLeaveVehicle(ped, veh, 16)
    Wait(700)
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    garageTruck = 0
    notify('truck_in')
    closeNui()
end

RegisterNUICallback('close', function(_, cb)
    closeNui()
    cb({ ok = true })
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('mallorca-takel:server:toggleDuty')
    cb({ ok = true })
end)

RegisterNUICallback('attach', function(_, cb)
    doAttach()
    cb({ ok = true })
end)

RegisterNUICallback('detach', function(_, cb)
    doDetach()
    cb({ ok = true })
end)

RegisterNUICallback('impound', function(_, cb)
    doImpound()
    cb({ ok = true })
end)

RegisterNUICallback('spawnTruck', function(data, cb)
    spawnTruck(data and data.model or 'flatbed')
    cb({ ok = true })
end)

RegisterNUICallback('storeTruck', function(_, cb)
    storeTruck()
    cb({ ok = true })
end)

RegisterNUICallback('sendBill', function(data, cb)
    TriggerServerEvent('mallorca-takel:server:bill', data and data.target, data and data.amount, data and data.reason)
    cb({ ok = true })
end)

RegisterNUICallback('acceptCall', function(data, cb)
    TriggerServerEvent('mallorca-takel:server:acceptCall', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('waypoint', function(data, cb)
    if data and data.x and data.y then
        setWaypoint(data)
    end
    cb({ ok = true })
end)

RegisterNUICallback('release', function(data, cb)
    TriggerServerEvent('mallorca-takel:server:release', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('mallorca-takel:server:sync')
    refreshNui()
    cb({ ok = true })
end)

RegisterCommand(Config.Command, function()
    if nuiOpen then
        closeNui()
    else
        openNui()
    end
end, false)

RegisterCommand('mallorca_takel_toggle', function()
    local attached = Tow.GetAttached()
    if attached ~= 0 then
        doDetach()
    else
        doAttach()
    end
end, false)

RegisterCommand(Config.CallCommand, function(_, args)
    local msg = table.concat(args or {}, ' ')
    if msg == '' then
        msg = 'Pechhulp nodig'
    end
    local c = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('mallorca-takel:server:createCall', {
        x = c.x, y = c.y, z = c.z,
        message = msg
    })
end, false)

RegisterKeyMapping(Config.Command, 'Mallorca Takel tablet', 'keyboard', Config.Keys.menu)
RegisterKeyMapping('mallorca_takel_toggle', 'Voertuig takelen / loskoppelen', 'keyboard', Config.Keys.toggle)

CreateThread(function()
    loadESX()
    if ESX and ESX.GetPlayerData then
        PlayerData = ESX.GetPlayerData() or {}
    end

    depotBlip = AddBlipForCoord(Config.Depot.coords.x, Config.Depot.coords.y, Config.Depot.coords.z)
    SetBlipSprite(depotBlip, Config.Depot.blip.sprite)
    SetBlipDisplay(depotBlip, 4)
    SetBlipScale(depotBlip, Config.Depot.blip.scale)
    SetBlipColour(depotBlip, Config.Depot.blip.color)
    SetBlipAsShortRange(depotBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Depot.label)
    EndTextCommandSetBlipName(depotBlip)

    impoundBlip = AddBlipForCoord(Config.Impound.retrieve.x, Config.Impound.retrieve.y, Config.Impound.retrieve.z)
    SetBlipSprite(impoundBlip, Config.Impound.blip.sprite)
    SetBlipDisplay(impoundBlip, 4)
    SetBlipScale(impoundBlip, Config.Impound.blip.scale)
    SetBlipColour(impoundBlip, Config.Impound.blip.color)
    SetBlipAsShortRange(impoundBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Impound.label)
    EndTextCommandSetBlipName(impoundBlip)

    CreateThread(function()
        Wait(2000)
        spawnParkedVehicles()
    end)
end)

CreateThread(function()
    while true do
        local sleep = 800
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local depotDist = #(coords - Config.Depot.coords)
        local impoundDist = #(coords - Config.Impound.coords)
        local retrieveDist = #(coords - Config.Impound.retrieve)

        if depotDist < 25.0 then
            sleep = 0
            DrawMarker(
                Config.Markers.type,
                Config.Depot.coords.x, Config.Depot.coords.y, Config.Depot.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Markers.scale.x, Config.Markers.scale.y, Config.Markers.scale.z,
                Config.Markers.color.r, Config.Markers.color.g, Config.Markers.color.b, Config.Markers.color.a,
                false, false, 2, false, nil, nil, false
            )
            if depotDist < Config.InteractDistance then
                helpText('~INPUT_CONTEXT~ Mallorca Takel depot')
                if IsControlJustReleased(0, 38) then
                    if isEmployee() then
                        openNui({ page = 'garage' })
                    else
                        notify('not_employee')
                    end
                end
            end
        end

        if isEmployee() and impoundDist < 25.0 then
            sleep = 0
            DrawMarker(
                Config.Markers.type,
                Config.Impound.coords.x, Config.Impound.coords.y, Config.Impound.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Markers.scale.x, Config.Markers.scale.y, Config.Markers.scale.z,
                Config.Markers.color.r, Config.Markers.color.g, Config.Markers.color.b, Config.Markers.color.a,
                false, false, 2, false, nil, nil, false
            )
            if impoundDist < Config.InteractDistance then
                helpText('~INPUT_CONTEXT~ Voertuig inbeslag nemen')
                if IsControlJustReleased(0, 38) then
                    doImpound()
                end
            end
        end

        if retrieveDist < 25.0 then
            sleep = 0
            DrawMarker(
                Config.Markers.type,
                Config.Impound.retrieve.x, Config.Impound.retrieve.y, Config.Impound.retrieve.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Markers.scale.x, Config.Markers.scale.y, Config.Markers.scale.z,
                255, 193, 77, 140,
                false, false, 2, false, nil, nil, false
            )
            if retrieveDist < Config.InteractDistance then
                helpText('~INPUT_CONTEXT~ Inbeslagname ophalen')
                if IsControlJustReleased(0, 38) then
                    nuiOpen = true
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'open',
                        data = nuiPayload({ page = 'impound', civilian = not isEmployee() })
                    })
                    TriggerServerEvent('mallorca-takel:server:sync')
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(400)
        if nuiOpen then
            refreshNui()
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeNui()
    clearCallBlip()
    if depotBlip then RemoveBlip(depotBlip) end
    if impoundBlip then RemoveBlip(impoundBlip) end
    for i = 1, #parkedVehicles do
        local veh = parkedVehicles[i]
        if veh and DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
        end
    end
end)
