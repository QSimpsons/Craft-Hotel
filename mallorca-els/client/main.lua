local myVehicle = 0
local myNetId = 0
local stage = 0
local scene = false
local extras = {}
local leftExtras = {}
local rightExtras = {}
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
    if enabled then
        SetVehicleExtra(veh, extraId, 0)
    else
        SetVehicleExtra(veh, extraId, 1)
        SetVehicleExtra(veh, extraId, 1)
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
    local wanted = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
    if type(cfg.extras) == 'table' then
        for i = 1, #cfg.extras do
            wanted[#wanted + 1] = cfg.extras[i]
        end
    end
    local seen = {}
    local list = {}
    for i = 1, #wanted do
        local extraId = wanted[i]
        if extraId and not seen[extraId] and extraExists(veh, extraId) then
            seen[extraId] = true
            list[#list + 1] = extraId
        end
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
    -- Eerst alles uit, anders blijft één kant vast branden
    allExtras(veh, list, false)
    if #left == 0 and #right == 0 then
        allExtras(veh, list, flash)
        return
    end
    if #left == 0 or #right == 0 then
        allExtras(veh, list, flash)
        return
    end
    if flash then
        allExtras(veh, left, true)
    else
        allExtras(veh, right, true)
    end
end

local function muteSiren(veh)
    SetVehicleSiren(veh, false)
    if type(SetVehicleHasMutedSirens) == 'function' then
        SetVehicleHasMutedSirens(veh, true)
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
        allExtras(veh, list, true)
        setHazards(veh, true)
        muteSiren(veh)
        return
    end

    if st <= 0 then
        restoreExtras(veh, saved)
        setHazards(veh, false)
        muteSiren(veh)
        return
    end

    -- Koplampen nooit overrulen: speler houdt eigen lichtstand
    SetVehicleLights(veh, 0)
    setHazards(veh, false)

    if st == 1 then
        local rear = rearExtras(list)
        allExtras(veh, list, false)
        allExtras(veh, rear, true)
        muteSiren(veh)
        return
    end

    -- Links/rechts afwisselen: nooit beide kanten tegelijk
    SetVehicleIndicatorLights(veh, 0, flash and true or false)
    SetVehicleIndicatorLights(veh, 1, flash and false or true)
    alternateSides(veh, list, left, right, flash)
    muteSiren(veh)
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
    if stage <= 0 then
        scene = false
    end
    applyPattern(veh, stage, mineMeta(), true, flashOn, scene, sweep)
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
    applyPattern(veh, stage, mineMeta(), true, flashOn, scene, sweep)
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
                applyPattern(veh, stage, mineMeta(), true, flashOn, true, sweep)
                Wait(250)
            elseif stage <= 0 then
                Wait(250)
            elseif stage >= 2 then
                flashOn = not flashOn
                applyPattern(veh, stage, mineMeta(), true, flashOn, false, sweep)
                Wait(Config.FlashMs[stage] or 80)
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
                        applyPattern(veh, st, remoteMeta[netId], false, remoteFlash, true, 1)
                    elseif st >= 2 then
                        anyFlash = true
                        applyPattern(veh, st, remoteMeta[netId], false, remoteFlash, false, 1)
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
