-- Laadt alfabetisch vóór client.lua (a_helpers.lua).
-- Definieert OpenSavedOutfitsMenu / SafeToggleDuty zodat oude client.lua niet crasht.

local function ResourceStarted(name)
    return type(name) == 'string' and name ~= '' and GetResourceState(name) == 'started'
end

if type(SafeCallExport) ~= 'function' then
    SafeCallExport = function(resource, method, ...)
        if not ResourceStarted(resource) then
            return false
        end
        local args = { ... }
        local ok = pcall(function()
            exports[resource][method](table.unpack(args))
        end)
        return ok
    end
end

if type(SafeNotify) ~= 'function' then
    SafeNotify = function(nType, message, duration)
        duration = duration or 4000
        if Config and SafeCallExport(Config.Notify, 'Notify', nType, message, duration) then
            return true
        end
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(message)
            return true
        end
        return true
    end
end

local function IsFemalePed(ped)
    return GetEntityModel(ped) == `mp_f_freemode_01`
end

ApplyAnwbOutfit = function(outfit)
    if type(outfit) ~= 'table' then
        return false
    end
    local ped = PlayerPedId()
    local genderData = IsFemalePed(ped) and (outfit.female or outfit.male) or (outfit.male or outfit.female)
    if type(genderData) ~= 'table' then
        return false
    end
    if type(genderData.components) == 'table' then
        for _, comp in pairs(genderData.components) do
            if type(comp) == 'table' and comp.component_id ~= nil then
                SetPedComponentVariation(ped, tonumber(comp.component_id) or 0, tonumber(comp.drawable) or 0, tonumber(comp.texture) or 0, 0)
            end
        end
    end
    if type(genderData.props) == 'table' then
        for _, prop in pairs(genderData.props) do
            if type(prop) == 'table' and prop.prop_id ~= nil then
                local propId = tonumber(prop.prop_id) or 0
                local drawable = tonumber(prop.drawable) or -1
                if drawable < 0 then
                    ClearPedProp(ped, propId)
                else
                    SetPedPropIndex(ped, propId, drawable, tonumber(prop.texture) or 0, true)
                end
            end
        end
    end
    return true
end

setClothing = function(item, reset)
    if reset then
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
        return true
    end
    if type(item) == 'table' then
        return ApplyAnwbOutfit(item)
    end
    return false
end

OpenSavedOutfitsMenu = function()
    local clothing = (Config and Config.Kleding) or 'jg-clothingmenu'
    local methods = { 'openSavedOutfits', 'OpenSavedOutfits', 'openOutfitMenu', 'OpenOutfitMenu', 'showOutfitMenu' }
    for i = 1, #methods do
        if SafeCallExport(clothing, methods[i]) then
            return true
        end
    end
    if SafeCallExport('ox_appearance', 'showOutfitMenu') then return true end
    if SafeCallExport('illenium-appearance', 'openOutfitMenu') then return true end
    if SafeCallExport('fivem-appearance', 'openOutfitMenu') then return true end
    pcall(function()
        TriggerEvent('ox_appearance:outfitMenu')
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
        TriggerEvent('fivem-appearance:client:openOutfitMenu')
        TriggerEvent('qb-clothing:client:openOutfitMenu')
        TriggerEvent('esx_skin:openSaveableMenu')
    end)
    SafeNotify('error', 'Geen persoonlijk kledingmenu gevonden.', 4000)
    return false
end

local function OpenOutfitCategory(categoryName, outfits)
    local options = {}
    for outfitName, outfitData in pairs(outfits) do
        options[#options + 1] = {
            title = outfitName,
            onSelect = function()
                if ApplyAnwbOutfit(outfitData) then
                    SafeNotify('success', ('Outfit aangetrokken: %s'):format(outfitName), 3500)
                else
                    SafeNotify('error', 'Deze outfit heeft geen data voor jouw ped.', 4000)
                end
            end
        }
    end
    table.sort(options, function(a, b) return a.title < b.title end)
    lib.registerContext({
        id = 'anwb:job-outfits:' .. tostring(categoryName),
        title = tostring(categoryName),
        menu = 'anwb:job-outfits',
        options = options
    })
    lib.showContext('anwb:job-outfits:' .. tostring(categoryName))
end

OpenJobOutfitMenu = function(outfits)
    outfits = outfits or (Config and Config.Outfits) or {}
    local jobsmenu = (Config and Config.Jobsmenu) or 'jg-jobsmenu'
    if SafeCallExport(jobsmenu, 'OpenOutfitMenu', outfits) then return true end
    if SafeCallExport(jobsmenu, 'openOutfitMenu', outfits) then return true end

    local categories = {}
    for categoryName, categoryOutfits in pairs(outfits) do
        if type(categoryOutfits) == 'table' then
            categories[#categories + 1] = {
                title = categoryName,
                arrow = true,
                onSelect = function()
                    OpenOutfitCategory(categoryName, categoryOutfits)
                end
            }
        end
    end
    if #categories == 0 then
        SafeNotify('error', 'Geen ANWB outfits in config/outfits.lua.', 4000)
        return false
    end
    table.sort(categories, function(a, b) return a.title < b.title end)
    lib.registerContext({
        id = 'anwb:job-outfits',
        title = 'ANWB outfits',
        options = categories
    })
    lib.showContext('anwb:job-outfits')
    return true
end

SafeToggleDuty = function()
    local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
    local jobsmenu = (Config and Config.Jobsmenu) or 'jg-jobsmenu'
    if SafeCallExport(jobsmenu, 'ToggleDuty', jobName) then return true end
    if SafeCallExport(jobsmenu, 'toggleDuty', jobName) then return true end
    TriggerServerEvent('jg-anwb:server:toggleDuty')
    return true
end

SafeOpenManagement = function()
    local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name or 'mechanic'
    local jobsmenu = (Config and Config.Jobsmenu) or 'jg-jobsmenu'
    if SafeCallExport(jobsmenu, 'OpenManagementMenu', jobName) then return true end
    if SafeCallExport(jobsmenu, 'openManagementMenu', jobName) then return true end
    pcall(function()
        TriggerEvent('esx_society:openBossMenu', 'mechanic', function() end, { wash = false })
    end)
    return true
end

print('^2[jg-anwb] a_helpers.lua geladen (OpenSavedOutfitsMenu/SafeToggleDuty)^7')
