local myVehicle = 0
local myNetId = 0
local stage = 0
local scene = false
local extras = {}
local leftExtras = {}
local rightExtras = {}
local savedExtras = {}
local strobe = 0
local remoteStrobe = 0
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
    if type(IsVehicleExtraTurnedOn) ~= 'function' then
        return false
    end
    return IsVehicleExtraTurnedOn(veh, extraId)
end

local function isIndicatorExtra(extraId)
    local ignore = Config.IndicatorExtras
    if type(ignore) ~= 'table' then
        return extraId >= 5
    end
    for i = 1, #ignore do
        if ignore[i] == extraId then
            return true
        end
    end
    return false
end

local function lightExtraIds()
    local list = Config.LightExtras
    if type(list) ~= 'table' or #list == 0 then
        return { 1, 2, 3, 4 }
    end
    return list
end

local function setExtra(veh, extraId, enabled)
    extraId = tonumber(extraId)
    if not extraId or extraId < 1 or extraId > 14 then
        return
    end
    if isIndicatorExtra(extraId) then
        return
    end
    SetVehicleExtra(veh, extraId, enabled and 0 or 1)
end

local function restoreIndicatorExtras(veh)
    local ignore = Config.IndicatorExtras
    if type(ignore) ~= 'table' then
        return
    end
    for i = 1, #ignore do
        local extraId = ignore[i]
        local wasOn = savedExtras[extraId]
        if wasOn == nil then
            SetVehicleExtra(veh, extraId, 1)
        else
            SetVehicleExtra(veh, extraId, wasOn and 0 or 1)
        end
    end
end

local function forceAllExtras(veh, on)
    local list = lightExtraIds()
    for i = 1, #list do
        setExtra(veh, list[i], on)
    end
end

local function forceOddExtras(veh, on)
    local list = lightExtraIds()
    for i = 1, #list do
        if list[i] % 2 == 1 then
            setExtra(veh, list[i], on)
        end
    end
end

local function forceEvenExtras(veh, on)
    local list = lightExtraIds()
    for i = 1, #list do
        if list[i] % 2 == 0 then
            setExtra(veh, list[i], on)
        end
    end
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
    local list = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
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
        extraId = tonumber(extraId)
        if extraId and extraId >= 1 and extraId <= 14 then
            SetVehicleExtra(veh, extraId, wasOn and 0 or 1)
        end
    end
end

local function clearIndicators(veh)
    SetVehicleIndicatorLights(veh, 0, false)
    SetVehicleIndicatorLights(veh, 1, false)
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

local function sideGroups(veh, cfg, list)
    local left = filterExisting(veh, cfg and cfg.left)
    local right = filterExisting(veh, cfg and cfg.right)
    if #left == 0 or #right == 0 then
        left, right = {}, {}
        for i = 1, #list do
            if list[i] % 2 == 1 then
                left[#left + 1] = list[i]
            else
                right[#right + 1] = list[i]
            end
        end
    end
    return left, right
end

local function alternateSides(veh, list, left, right, flash)
    -- Addon-balken: extra 1 is vaak de voeding. Eerst HELE balk aan,
    -- daarna één kant uit — zo branden beide kanten, met afwisseling.
    local beat = math.floor(tonumber(flash) or 0) % 4
    forceAllExtras(veh, true)
    if beat == 1 then
        forceOddExtras(veh, false)
    elseif beat == 3 then
        forceEvenExtras(veh, false)
    end
end

local function muteSiren(veh, lightsOn)
    if type(SetVehicleHasMutedSirens) == 'function' then
        SetVehicleHasMutedSirens(veh, true)
    end
    if Config.MutedSirenLights and lightsOn then
        SetVehicleSiren(veh, true)
    else
        SetVehicleSiren(veh, false)
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
    local left = (meta and meta.left) or leftExtras
    local right = (meta and meta.right) or rightExtras

    if sceneOn then
        restoreIndicatorExtras(veh)
        forceAllExtras(veh, true)
        muteSiren(veh, false)
        return
    end

    if st <= 0 then
        restoreExtras(veh, saved)
        muteSiren(veh, false)
        return
    end

    -- Koplampen en richtingaanwijzers nooit meenemen
    SetVehicleLights(veh, 0)
    clearIndicators(veh)
    restoreIndicatorExtras(veh)

    if st == 1 then
        forceAllExtras(veh, false)
        forceEvenExtras(veh, true)
        muteSiren(veh, false)
        return
    end

    local beat = math.floor(tonumber(flash) or 0)
    alternateSides(veh, list, left, right, beat)
    restoreIndicatorExtras(veh)
    muteSiren(veh, true)
end

local function mineMeta()
    return {
        extras = extras,
        left = leftExtras,
        right = rightExtras,
        saved = savedExtras
    }
end

local function resetMine(veh)
    stage = 0
    scene = false
    if veh ~= 0 and DoesEntityExist(veh) then
        applyPattern(veh, 0, mineMeta(), true, false, false, 1)
        if myNetId ~= 0 then
            TriggerServerEvent('mallorca-els:update', myNetId, {
                stage = 0,
                scene = false,
                model = modelName(veh) or ''
            })
        end
    end
    myVehicle = 0
    myNetId = 0
    extras = {}
    leftExtras = {}
    rightExtras = {}
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
    leftExtras, rightExtras = sideGroups(veh, cfg, extras)
    local start = math.floor(tonumber(Config.StartStageOnEnter) or 0)
    if start < 0 then start = 0 end
    if start > 3 then start = 3 end
    stage = start
    scene = false
    strobe = 0
    disableAutoRepair(veh)
    if stage > 0 then
        applyPattern(veh, stage, mineMeta(), true, strobe, scene, 0)
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
    if stage <= 0 then
        scene = false
    end
    applyPattern(veh, stage, mineMeta(), true, strobe, scene, 0)
    notify(('%s: %s'):format(Config.Locale.stage, Config.StageNames[stage] or 'UIT'))
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
    applyPattern(veh, stage, mineMeta(), true, strobe, scene, 0)
    notify(scene and Config.Locale.scene_on or Config.Locale.scene_off)
    pushUi()
    broadcast()
end

RegisterCommand('mallorca_els_1', function() setStage(1) end, false)
RegisterCommand('mallorca_els_2', function() setStage(2) end, false)
RegisterCommand('mallorca_els_3', function() setStage(3) end, false)
RegisterCommand('mallorca_els_off', function() setStage(0) end, false)
RegisterCommand('mallorca_els_scene', function() toggleScene() end, false)

RegisterCommand('els', function()
    notify('Pechhulp ELS: 1 achter · 2 zwaai · 3 vol · 0 uit · R werklicht. Geen sirene. Alleen fmltow / dlbrickade.')
end, false)

RegisterKeyMapping('mallorca_els_1', 'Pechhulp ELS achter', 'keyboard', Config.Keys.stage1)
RegisterKeyMapping('mallorca_els_2', 'Pechhulp ELS zwaai', 'keyboard', Config.Keys.stage2)
RegisterKeyMapping('mallorca_els_3', 'Pechhulp ELS vol', 'keyboard', Config.Keys.stage3)
RegisterKeyMapping('mallorca_els_off', 'Pechhulp ELS uit', 'keyboard', Config.Keys.off)
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
    if st <= 0 and not data.scene then
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
                applyPattern(veh, stage, mineMeta(), true, strobe, true, 0)
                Wait(250)
            elseif stage <= 0 then
                Wait(250)
            elseif stage >= 2 then
                strobe = strobe + 1
                applyPattern(veh, stage, mineMeta(), true, strobe, false, 0)
                Wait(Config.FlashMs[stage] or 80)
            else
                applyPattern(veh, stage, mineMeta(), true, strobe, false, 0)
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
        remoteStrobe = remoteStrobe + 1

        for netId, data in pairs(remote) do
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh ~= 0 and veh ~= myVehicle and DoesEntityExist(veh) and #(GetEntityCoords(veh) - coords) <= 120.0 then
                local ok, cfg = isPechhulp(veh)
                if ok then
                    if not remoteMeta[netId] then
                        local list, saved = snapshotExtras(veh, cfg)
                        local left, right = sideGroups(veh, cfg, list)
                        remoteMeta[netId] = {
                            extras = list,
                            left = left,
                            right = right,
                            saved = saved
                        }
                    end
                    local st = data.stage or 0
                    if data.scene then
                        applyPattern(veh, st, remoteMeta[netId], false, remoteStrobe, true, 1)
                    elseif st >= 2 then
                        anyFlash = true
                        applyPattern(veh, st, remoteMeta[netId], false, remoteStrobe, false, 1)
                    else
                        applyPattern(veh, st, remoteMeta[netId], false, remoteStrobe, false, 1)
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
