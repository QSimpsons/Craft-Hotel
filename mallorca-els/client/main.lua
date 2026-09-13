local myVehicle = 0
local myNetId = 0
local stage = 0
local siren = false
local scene = false
local extras = {}
local savedExtras = {}
local flashOn = false
local remoteFlash = false
local sweep = 1
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

local function seatedDriver()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then
        return 0
    end
    if not IsPedInVehicle(ped, veh, false) then
        return 0
    end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        return 0
    end
    return veh
end

local function driverVehicle()
    return seatedDriver()
end

local function hideUi()
    SendNUIMessage({ action = 'hide' })
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

local function rearExtras(list)
    local out = {}
    local startAt = math.max(1, math.ceil(#list / 2))
    for i = startAt, #list do
        out[#out + 1] = list[i]
    end
    if #out == 0 then
        return list
    end
    return out
end

local function setOwnerSiren(veh, on)
    SetVehicleSiren(veh, on and true or false)
    if type(SetVehicleHasMutedSirens) == 'function' then
        SetVehicleHasMutedSirens(veh, false)
    end
end

local function pushUi()
    local veh = seatedDriver()
    local inTruck = veh ~= 0 and veh == myVehicle and isPechhulp(veh)
    if not Config.ShowPanel or not inTruck then
        hideUi()
        return
    end
    SendNUIMessage({
        action = 'show',
        data = {
            visible = true,
            stage = stage,
            stageName = Config.StageNames[stage] or 'UIT',
            siren = siren,
            scene = scene,
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
        scene = scene,
        model = modelName(myVehicle) or ''
    })
end

local function applyPattern(veh, st, meta, isOwner, flash, sceneOn, sweepAt)
    if not DoesEntityExist(veh) then
        return
    end
    disableAutoRepair(veh)

    local list = (meta and meta.extras) or extras
    local saved = meta and meta.saved or savedExtras

    if sceneOn then
        allExtras(veh, list, true)
        setHazards(veh, true)
        SetVehicleLights(veh, 2)
        if isOwner then
            setOwnerSiren(veh, false)
        end
        return
    end

    if st <= 0 then
        restoreExtras(veh, saved)
        setHazards(veh, false)
        SetVehicleLights(veh, 0)
        if isOwner then
            setOwnerSiren(veh, false)
        end
        return
    end

    local useHazards = Config.UseHazardsFromStage and st >= Config.UseHazardsFromStage
    setHazards(veh, useHazards)

    if st == 1 then
        local rear = rearExtras(list)
        allExtras(veh, list, false)
        allExtras(veh, rear, true)
        SetVehicleLights(veh, 0)
        if isOwner then
            setOwnerSiren(veh, false)
        end
        return
    end

    if st == 2 then
        if #list > 0 then
            local idx = sweepAt or 1
            if idx < 1 then idx = 1 end
            if idx > #list then idx = 1 end
            for i = 1, #list do
                setExtra(veh, list[i], i == idx or i == idx - 1)
            end
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
        saved = savedExtras
    }
end

local function resetMine(veh)
    stage = 0
    siren = false
    scene = false
    if veh ~= 0 and DoesEntityExist(veh) then
        applyPattern(veh, 0, mineMeta(), true, false, false, 1)
        if myNetId ~= 0 then
            TriggerServerEvent('mallorca-els:update', myNetId, {
                stage = 0,
                siren = false,
                scene = false,
                model = modelName(veh) or ''
            })
        end
    end
    myVehicle = 0
    myNetId = 0
    extras = {}
    savedExtras = {}
    profile = nil
    hideUi()
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
    local start = math.floor(tonumber(Config.StartStageOnEnter) or 0)
    if start < 0 then start = 0 end
    if start > 3 then start = 3 end
    stage = start
    siren = false
    scene = false
    sweep = 1
    disableAutoRepair(veh)
    if stage > 0 then
        applyPattern(veh, stage, mineMeta(), true, flashOn, scene, sweep)
        broadcast()
    end
    pushUi()
end

local function setStage(nextStage)
    local veh = driverVehicle()
    local ok, cfg = isPechhulp(veh)
    if not ok then
        return
    end
    if myVehicle ~= veh then
        armVehicle(veh, cfg)
    end
    stage = nextStage
    if stage < 2 then
        siren = false
    end
    if stage <= 0 then
        scene = false
    end
    applyPattern(veh, stage, mineMeta(), true, flashOn, scene, sweep)
    notify(('%s: %s'):format(Config.Locale.stage, Config.StageNames[stage] or 'UIT'))
    pushUi()
    broadcast()
end

local function toggleSiren()
    local veh = driverVehicle()
    local ok, cfg = isPechhulp(veh)
    if not ok then
        return
    end
    if myVehicle ~= veh then
        armVehicle(veh, cfg)
    end
    if scene then
        return
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

local function toggleScene()
    local veh = driverVehicle()
    local ok, cfg = isPechhulp(veh)
    if not ok then
        return
    end
    if myVehicle ~= veh then
        armVehicle(veh, cfg)
    end
    scene = not scene
    if scene then
        siren = false
        setOwnerSiren(veh, false)
    end
    applyPattern(veh, stage, mineMeta(), true, flashOn, scene, sweep)
    notify(scene and Config.Locale.scene_on or Config.Locale.scene_off)
    pushUi()
    broadcast()
end

RegisterCommand('mallorca_els_1', function() setStage(1) end, false)
RegisterCommand('mallorca_els_2', function() setStage(2) end, false)
RegisterCommand('mallorca_els_3', function() setStage(3) end, false)
RegisterCommand('mallorca_els_off', function() setStage(0) end, false)
RegisterCommand('mallorca_els_siren', function() toggleSiren() end, false)
RegisterCommand('mallorca_els_scene', function() toggleScene() end, false)

RegisterCommand('els', function()
    notify('Pechhulp ELS: 1 achter · 2 zwaai · 3 vol · 0 uit · R werklicht · G toon. Alleen fmltow / dlbrickade.')
end, false)

RegisterKeyMapping('mallorca_els_1', 'Pechhulp ELS achter', 'keyboard', Config.Keys.stage1)
RegisterKeyMapping('mallorca_els_2', 'Pechhulp ELS zwaai', 'keyboard', Config.Keys.stage2)
RegisterKeyMapping('mallorca_els_3', 'Pechhulp ELS vol', 'keyboard', Config.Keys.stage3)
RegisterKeyMapping('mallorca_els_off', 'Pechhulp ELS uit', 'keyboard', Config.Keys.off)
RegisterKeyMapping('mallorca_els_siren', 'Pechhulp ELS toon', 'keyboard', Config.Keys.siren)
RegisterKeyMapping('mallorca_els_scene', 'Pechhulp ELS werklicht', 'keyboard', Config.Keys.scene)

RegisterNetEvent('mallorca-els:apply', function(src, netId, data)
    if src == GetPlayerServerId(PlayerId()) then
        return
    end
    netId = tonumber(netId)
    if not netId or type(data) ~= 'table' then
        return
    end
    local st = tonumber(data.stage) or 0
    if st <= 0 and not data.siren and not data.scene then
        local meta = remoteMeta[netId]
        local veh = NetworkGetEntityFromNetworkId(netId)
        if meta and veh ~= 0 and DoesEntityExist(veh) then
            applyPattern(veh, 0, meta, false, false, false, 1)
        end
        remote[netId] = nil
        remoteMeta[netId] = nil
        return
    end
    remote[netId] = {
        stage = st,
        siren = data.siren == true,
        scene = data.scene == true
    }
end)

CreateThread(function()
    while true do
        local veh = driverVehicle()
        local ok, cfg = isPechhulp(veh)
        if not ok then
            hideUi()
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
            if scene then
                applyPattern(veh, stage, mineMeta(), true, flashOn, true, sweep)
                Wait(250)
            elseif stage <= 0 then
                Wait(250)
            elseif stage == 2 then
                sweep = sweep + 1
                if sweep > math.max(1, #extras) then
                    sweep = 1
                end
                applyPattern(veh, stage, mineMeta(), true, flashOn, false, sweep)
                Wait(Config.FlashMs[2] or 140)
            elseif stage >= 3 then
                flashOn = not flashOn
                applyPattern(veh, stage, mineMeta(), true, flashOn, false, sweep)
                Wait(Config.FlashMs[3] or 90)
            else
                applyPattern(veh, stage, mineMeta(), true, flashOn, false, sweep)
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
                            saved = saved
                        }
                    end
                    local st = data.stage or 0
                    if data.scene then
                        applyPattern(veh, st, remoteMeta[netId], false, remoteFlash, true, 1)
                    elseif st >= 2 then
                        anyFlash = true
                        local idx = (math.floor(GetGameTimer() / (Config.FlashMs[2] or 140)) % math.max(1, #remoteMeta[netId].extras)) + 1
                        applyPattern(veh, st, remoteMeta[netId], false, remoteFlash, false, idx)
                    else
                        applyPattern(veh, st, remoteMeta[netId], false, remoteFlash, false, 1)
                    end
                end
            end
        end

        if anyFlash then
            waitMs = Config.FlashMs[3] or 90
        end
        Wait(waitMs)
    end
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    hideUi()
    stage = 0
    siren = false
    scene = false
    myVehicle = 0
    myNetId = 0
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    if myVehicle ~= 0 then
        resetMine(myVehicle)
    end
end)
