local myVehicle = 0
local myNetId = 0
local stage = 0
local siren = false
local extras = {}
local groupA = {}
local groupB = {}
local savedExtras = {}
local flashOn = false
local remoteFlash = false
local profile = nil
local remote = {}
local remoteMeta = {}

local function notify(text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, true)
end

local function extraExists(veh, extraId)
    if veh == 0 or extraId == nil then
        return false
    end
    if type(DoesExtraExist) ~= 'function' then
        return extraId >= 1 and extraId <= 14
    end
    return DoesExtraExist(veh, extraId)
end

local function extraIsOn(veh, extraId)
    if not extraExists(veh, extraId) then
        return false
    end
    if type(IsVehicleExtraTurnedOn) ~= 'function' then
        return false
    end
    return IsVehicleExtraTurnedOn(veh, extraId)
end

local function setExtra(veh, extraId, enabled)
    if not extraExists(veh, extraId) then
        return
    end
    SetVehicleExtra(veh, extraId, enabled and 0 or 1)
end

local function filterExisting(veh, list)
    local out = {}
    if type(list) ~= 'table' then
        return out
    end
    for i = 1, #list do
        local extraId = list[i]
        if extraExists(veh, extraId) then
            out[#out + 1] = extraId
        end
    end
    return out
end

local function modelName(veh)
    if veh == 0 or not DoesEntityExist(veh) then
        return nil
    end
    local hash = GetEntityModel(veh)
    if hash == `fmltow` then
        return 'fmltow'
    end
    if hash == `dlbrickade` then
        return 'dlbrickade'
    end
    return nil
end

local function isPechhulp(veh)
    if veh == 0 or not DoesEntityExist(veh) then
        return false, nil
    end
    local cfg = Config.Vehicles[GetEntityModel(veh)]
    return cfg ~= nil, cfg
end

local function driverVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        return 0
    end
    return veh
end

local function disableAutoRepair(veh)
    if type(SetVehicleAutoRepairDisabled) == 'function' then
        SetVehicleAutoRepairDisabled(veh, true)
    end
end

local function snapshotExtras(veh, cfg)
    local list = filterExisting(veh, cfg.extras)
    if #list == 0 then
        list = filterExisting(veh, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 })
    end
    local saved = {}
    for i = 1, #list do
        saved[list[i]] = extraIsOn(veh, list[i])
    end
    return list, saved
end

local function restoreExtras(veh, saved)
    if type(saved) ~= 'table' then
        return
    end
    for extraId, wasOn in pairs(saved) do
        setExtra(veh, extraId, wasOn)
    end
end

local function setHazards(veh, on)
    SetVehicleIndicatorLights(veh, 0, on)
    SetVehicleIndicatorLights(veh, 1, on)
end

local function allExtras(veh, list, on)
    for i = 1, #list do
        setExtra(veh, list[i], on)
    end
end

local function setOwnerSiren(veh, on)
    SetVehicleSiren(veh, on and true or false)
    if type(SetVehicleHasMutedSirens) == 'function' then
        SetVehicleHasMutedSirens(veh, false)
    end
end

local function pushUi()
    if not Config.ShowPanel then
        SendNUIMessage({ action = 'hide' })
        return
    end
    SendNUIMessage({
        action = (myVehicle ~= 0) and 'show' or 'hide',
        data = {
            visible = myVehicle ~= 0,
            stage = stage,
            stageName = Config.StageNames[stage] or 'UIT',
            siren = siren,
            vehicle = profile and profile.label or '',
            model = modelName(myVehicle) or 'fmltow / dlbrickade'
        }
    })
end

local function broadcast()
    if myNetId == 0 then
        return
    end
    TriggerServerEvent('mallorca-els:update', myNetId, {
        stage = stage,
        siren = siren,
        model = modelName(myVehicle) or ''
    })
end

local function applyPattern(veh, st, meta, isOwner, flash)
    if not DoesEntityExist(veh) then
        return
    end
    disableAutoRepair(veh)

    local useHazards = Config.UseHazardsFromStage and st >= Config.UseHazardsFromStage
    setHazards(veh, useHazards)

    local list = (meta and meta.extras) or extras
    local a = (meta and meta.groupA) or groupA
    local b = (meta and meta.groupB) or groupB
    local saved = meta and meta.saved or savedExtras

    if st <= 0 then
        restoreExtras(veh, saved)
        SetVehicleLights(veh, 0)
        if isOwner then
            setOwnerSiren(veh, false)
        end
        return
    end

    if st == 1 then
        if #list > 0 then
            allExtras(veh, list, true)
        else
            setHazards(veh, true)
        end
        SetVehicleLights(veh, 0)
        if isOwner then
            setOwnerSiren(veh, false)
        end
        return
    end

    if st == 2 then
        if #a > 0 or #b > 0 then
            for i = 1, #a do
                setExtra(veh, a[i], flash)
            end
            for i = 1, #b do
                setExtra(veh, b[i], not flash)
            end
        elseif #list > 0 then
            allExtras(veh, list, flash)
        else
            setHazards(veh, flash)
        end
        SetVehicleLights(veh, 0)
    elseif st == 3 then
        if #list > 0 then
            allExtras(veh, list, flash)
        else
            setHazards(veh, true)
        end
        if Config.HeadlightWigwag then
            SetVehicleLights(veh, flash and 2 or 1)
        end
    end

    if isOwner then
        local horn = Config.HornOverride and IsControlPressed(0, 86)
        setOwnerSiren(veh, siren or (st >= 2 and horn))
    end
end

local function mineMeta()
    return {
        extras = extras,
        groupA = groupA,
        groupB = groupB,
        saved = savedExtras
    }
end

local function resetMine(veh)
    stage = 0
    siren = false
    if veh ~= 0 and DoesEntityExist(veh) then
        applyPattern(veh, 0, mineMeta(), true, false)
        if myNetId ~= 0 then
            TriggerServerEvent('mallorca-els:update', myNetId, {
                stage = 0,
                siren = false,
                model = modelName(veh) or ''
            })
        end
    end
    myVehicle = 0
    myNetId = 0
    extras = {}
    groupA = {}
    groupB = {}
    savedExtras = {}
    profile = nil
    SendNUIMessage({ action = 'hide' })
end

local function armVehicle(veh, cfg)
    myVehicle = veh
    myNetId = NetworkGetNetworkIdFromEntity(veh)
    if myNetId ~= 0 then
        if type(SetNetworkIdExistsOnAllMachines) == 'function' then
            SetNetworkIdExistsOnAllMachines(myNetId, true)
        end
        if type(SetNetworkIdCanMigrate) == 'function' then
            SetNetworkIdCanMigrate(myNetId, true)
        end
    end
    profile = cfg
    extras, savedExtras = snapshotExtras(veh, cfg)
    groupA = filterExisting(veh, cfg.groupA)
    groupB = filterExisting(veh, cfg.groupB)
    stage = 0
    siren = false
    disableAutoRepair(veh)
    applyPattern(veh, 0, mineMeta(), true, false)
    pushUi()
    broadcast()
end

local function cycleStage()
    local veh = driverVehicle()
    local ok, cfg = isPechhulp(veh)
    if not ok then
        notify(Config.Locale.no_vehicle)
        return
    end
    if myVehicle ~= veh then
        armVehicle(veh, cfg)
    end
    stage = stage + 1
    if stage > 3 then
        stage = 0
        siren = false
    end
    if stage < 2 then
        siren = false
    end
    applyPattern(veh, stage, mineMeta(), true, flashOn)
    notify(('Zwaailichten: %s'):format(Config.StageNames[stage] or 'UIT'))
    pushUi()
    broadcast()
end

local function toggleSiren()
    local veh = driverVehicle()
    local ok, cfg = isPechhulp(veh)
    if not ok then
        notify(Config.Locale.no_vehicle)
        return
    end
    if myVehicle ~= veh then
        armVehicle(veh, cfg)
    end
    if Config.SirenNeedsLights and stage < 2 then
        notify(Config.Locale.need_lights)
        return
    end
    siren = not siren
    setOwnerSiren(veh, siren)
    notify(siren and Config.Locale.siren_on or Config.Locale.siren_off)
    pushUi()
    broadcast()
end

RegisterCommand('mallorca_els_stage', function()
    cycleStage()
end, false)

RegisterCommand('mallorca_els_siren', function()
    toggleSiren()
end, false)

RegisterCommand('els', function()
    notify('Pechhulp ELS: Q = zwaailichten, G = sirene. Alleen fmltow / dlbrickade.')
end, false)

RegisterKeyMapping('mallorca_els_stage', 'Pechhulp ELS zwaailichten', 'keyboard', Config.Keys.stage)
RegisterKeyMapping('mallorca_els_siren', 'Pechhulp ELS sirene', 'keyboard', Config.Keys.siren)

RegisterNetEvent('mallorca-els:apply', function(src, netId, data)
    if src == GetPlayerServerId(PlayerId()) then
        return
    end
    netId = tonumber(netId)
    if not netId or type(data) ~= 'table' then
        return
    end
    if (tonumber(data.stage) or 0) <= 0 and not data.siren then
        local meta = remoteMeta[netId]
        local veh = NetworkGetEntityFromNetworkId(netId)
        if meta and veh ~= 0 and DoesEntityExist(veh) then
            applyPattern(veh, 0, meta, false, false)
        end
        remote[netId] = nil
        remoteMeta[netId] = nil
        return
    end
    remote[netId] = {
        stage = tonumber(data.stage) or 0,
        siren = data.siren == true
    }
end)

CreateThread(function()
    while true do
        local veh = driverVehicle()
        local ok, cfg = isPechhulp(veh)
        if not ok then
            if myVehicle ~= 0 then
                resetMine(myVehicle)
            end
            Wait(400)
        else
            if myVehicle ~= veh then
                if myVehicle ~= 0 then
                    resetMine(myVehicle)
                end
                armVehicle(veh, cfg)
            end
            if stage >= 2 then
                flashOn = not flashOn
                applyPattern(veh, stage, mineMeta(), true, flashOn)
                Wait(Config.FlashMs[stage] or 160)
            else
                applyPattern(veh, stage, mineMeta(), true, flashOn)
                Wait(200)
            end
            pushUi()
        end
    end
end)

CreateThread(function()
    while true do
        local waitMs = 400
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local anyFlash = false
        remoteFlash = not remoteFlash

        for netId, data in pairs(remote) do
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh ~= 0 and veh ~= myVehicle and DoesEntityExist(veh) and #(GetEntityCoords(veh) - coords) <= 120.0 then
                local ok, cfg = isPechhulp(veh)
                if ok then
                    if not remoteMeta[netId] then
                        local list, saved = snapshotExtras(veh, cfg)
                        remoteMeta[netId] = {
                            extras = list,
                            groupA = filterExisting(veh, cfg.groupA),
                            groupB = filterExisting(veh, cfg.groupB),
                            saved = saved
                        }
                    end
                    if data.stage >= 2 then
                        anyFlash = true
                    end
                    applyPattern(veh, data.stage, remoteMeta[netId], false, remoteFlash)
                end
            end
        end

        if anyFlash then
            waitMs = Config.FlashMs[3] or 110
        end
        Wait(waitMs)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    if myVehicle ~= 0 then
        resetMine(myVehicle)
    end
end)
