local isMenuOpen = false
local currentFps = 0

-- Tabel om bij te houden welke knoppen de speler heeft aanstaan
local actieveModifiers = {
    ["btn-laag"] = false,
    ["btn-boost"] = false,
    ["btn-texturen"] = false,
    ["btn-nogpu"] = false,
    ["btn-grafics"] = false,
    ["btn-vignette"] = false,
    ["btn-zwartwit"] = false,
    ["btn-schaduwen"] = false
}

-- FPS teller die op de achtergrond meedraait
Citizen.CreateThread(function()
    local frameCount = 0
    local lastTime = GetGameTimer()

    while true do
        Citizen.Wait(0)
        frameCount = frameCount + 1
        local currentTime = GetGameTimer()

        if currentTime - lastTime >= 1000 then
            currentFps = frameCount
            frameCount = 0
            lastTime = currentTime
        end
    end
end)

-- De complete opschonings-functie
local function ClearGameGarbage(ped)
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    LeaderboardsReadClearAll()
    ClearBrief()
    ClearGpsFlags()
    ClearPrints()
    ClearSmallPrints()
    ClearReplayStats()
    LeaderboardsClearCacheData()
    ClearFocus()
    ClearHdArea()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    ClearOverrideWeather()
    DisableScreenblurFade()
    SetRainLevel(0.0)
    SetWindSpeed(0.0)
end

local function ApplyShadows(disabled)
    if disabled then
        RopeDrawShadowEnabled(false)
        CascadeShadowsClearShadowSampleType()
        CascadeShadowsSetAircraftMode(false)
        CascadeShadowsEnableEntityTracker(true)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetEntityTrackerScale(0.0)
        CascadeShadowsSetDynamicDepthValue(0.0)
        CascadeShadowsSetCascadeBoundsScale(0.0)
    else
        RopeDrawShadowEnabled(true)
        CascadeShadowsSetAircraftMode(true)
        CascadeShadowsEnableEntityTracker(false)
        CascadeShadowsSetDynamicDepthMode(true)
        CascadeShadowsSetEntityTrackerScale(5.0)
        CascadeShadowsSetDynamicDepthValue(5.0)
        CascadeShadowsSetCascadeBoundsScale(1.0)
    end
end

-- Functie die kijkt wat er allemaal aanstaat en dit combineert
local function BerekenEnToepassenModifiers()
    local ped = PlayerPedId()

    -- Reset eerst de basis
    SetTimecycleModifier()
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()

    -- Bepaal de belangrijkste timecycle modifier op basis van prioriteit (van zwaar naar licht)
    if actieveModifiers["btn-nogpu"] then
        SetTimecycleModifier('HicksbarNEW')
        ClearGameGarbage(ped)
    elseif actieveModifiers["btn-boost"] then
        SetTimecycleModifier('yell_tunnel_nodirect')
        ClearGameGarbage(ped)
    elseif actieveModifiers["btn-texturen"] then
        SetTimecycleModifier('v_janitor')
        ClearGameGarbage(ped)
    elseif actieveModifiers["btn-laag"] then
        SetTimecycleModifier('exile1_plane')
        ClearGameGarbage(ped)
    elseif actieveModifiers["btn-grafics"] then
        SetTimecycleModifier('v_torture')
        SetExtraTimecycleModifier('reflection_correct_ambient')
    end

    -- Losse effecten die we hiernaast kunnen forceren
    if actieveModifiers["btn-zwartwit"] then
        SetTimecycleModifier('NG_filmnoir_BW01') -- Overschrijft tijdelijk de kleur naar zwart-wit
    end

    if actieveModifiers["btn-vignette"] then
        -- Als zwart-wit niet aanstaat, zetten we vignette aan
        if not actieveModifiers["btn-zwartwit"] then
            SetTimecycleModifier('rply_vignette')
        end
    end

    ApplyShadows(actieveModifiers["btn-schaduwen"])
end

-- Functie om alle gegevens te verzamelen en naar het menu te sturen
local function updateMenuStats()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local health = GetEntityHealth(ped) - 100
    if health < 0 then health = 0 end
    local armor = GetPedArmour(ped)

    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    local zoneLabel = GetNameOfZone(coords.x, coords.y, coords.z)
    local zone = GetLabelText(zoneLabel)

    if zone == "BUBBLES" then zone = "Unknown" end

    SendNUIMessage({
        action = "updateStats",
        fps = tostring(currentFps),
        ping = "25",
        health = tostring(health),
        armor = tostring(armor),
        location = currentStreetName .. " (" .. zone .. ")"
    })
end

-- Commando's om te openen
RegisterCommand('fpspanel', function()
    if not isMenuOpen then
        isMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "open" })
        updateMenuStats()
    end
end, false)

RegisterCommand('fps', function()
    ExecuteCommand('fpspanel')
end, false)

-- NUI Callback om het menu te sluiten
RegisterNUICallback('close', function(data, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    cb('ok')
end)

-- NUI Callback voor de algemene footer Reset knop
RegisterNUICallback('reset', function(data, cb)
    for k, v in pairs(actieveModifiers) do
        actieveModifiers[k] = false
    end
    SetTimecycleModifier()
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    ApplyShadows(false)
    cb('ok')
end)

-- De verwerking van de instellingen (met multi-select ondersteuning!)
RegisterNUICallback('toggleSetting', function(data, cb)
    if data.setting == "btn-reset-graphics" then
        for k, v in pairs(actieveModifiers) do
            actieveModifiers[k] = false
        end
    else
        -- Sla de status (true of false) op in onze tabel
        actieveModifiers[data.setting] = data.status
    end

    -- Bereken direct de nieuwe in-game combinaties
    BerekenEnToepassenModifiers()
    cb('ok')
end)

-- Loop die de cijfers live bijwerkt als het menu open staat
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isMenuOpen then
            updateMenuStats()
        end
    end
end)

-- Schaduwen blijven uit zolang de knop aanstaat
Citizen.CreateThread(function()
    while true do
        if actieveModifiers["btn-schaduwen"] then
            ApplyShadows(true)
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)
