local menuOpen = false
local currentPreset = Config.DefaultPreset
local presetById = {}

for i = 1, #Config.Presets do
    local preset = Config.Presets[i]
    presetById[preset.id] = preset
end

local function nuiPresets()
    local list = {}
    for i = 1, #Config.Presets do
        local preset = Config.Presets[i]
        list[i] = {
            id = preset.id,
            title = preset.title,
            description = preset.description
        }
    end
    return list
end

local function applyPreset(id)
    local preset = presetById[id]
    if not preset then
        return
    end

    currentPreset = id
    RopeDrawShadowEnabled(preset.ropeShadows)

    if preset.shadowScale <= 0.0 then
        CascadeShadowsClearShadowSampleType()
    end

    CascadeShadowsSetAircraftMode(preset.aircraftShadows)
    CascadeShadowsEnableEntityTracker(preset.entityTracker)
    CascadeShadowsSetDynamicDepthMode(preset.dynamicDepth)
    CascadeShadowsSetEntityTrackerScale(preset.trackerScale)
    CascadeShadowsSetDynamicDepthValue(preset.depthValue)
    CascadeShadowsSetCascadeBoundsScale(preset.shadowScale)
    SetFlashLightFadeDistance(preset.lightDistance)
    SetLightsCutoffDistanceTweak(preset.lightDistance)
    DistantCopCarSirens(preset.sirens)
    SetForceVehicleTrails(preset.id <= 4)
    SetForcePedFootstepsTracks(preset.id <= 3)
end

local function closeMenu()
    if not menuOpen then
        return
    end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu()
    if menuOpen then
        return
    end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        selected = currentPreset,
        presets = nuiPresets()
    })
end

RegisterCommand(Config.Command, function()
    openMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Open het Mallorca FPS menu')

RegisterNUICallback('select', function(data, cb)
    local id = tonumber(data and data.id)
    if id and presetById[id] then
        SetResourceKvpInt('mallorca_fps_preset', id)
        applyPreset(id)
    end
    cb({ ok = true, selected = currentPreset })
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    if menuOpen then
        SetNuiFocus(false, false)
    end
end)

CreateThread(function()
    local saved = GetResourceKvpInt('mallorca_fps_preset')
    if saved >= 1 and presetById[saved] then
        currentPreset = saved
    end
    applyPreset(currentPreset)
end)

CreateThread(function()
    while true do
        local preset = presetById[currentPreset]
        if preset then
            if not preset.distantLights then
                DisableVehicleDistantlights(true)
            end
            if not preset.occlusion then
                DisableOcclusionThisFrame()
            end
            if not preset.decals then
                SetDisableDecalRenderingThisFrame()
            end
            if preset.lodScale < 1.0 then
                OverrideLodScaleThisFrame(preset.lodScale)
            end
            local light = preset.occlusion and preset.decals and preset.lodScale >= 1.0 and preset.distantLights
            Wait(light and 500 or 0)
        else
            Wait(500)
        end
    end
end)
