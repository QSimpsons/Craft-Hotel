local function ResourceStarted(name)
    return type(name) == 'string' and name ~= '' and GetResourceState(name) == 'started'
end

local function Trim(value)
    if value == nil then
        return ''
    end

    return (tostring(value):gsub('^%s*(.-)%s*$', '%1'))
end

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

local CallExport = SafeCallExport

SafeNotify = function(nType, message, duration)
    duration = duration or 4000
    if Config and SafeCallExport(Config.Notify, 'Notify', nType, message, duration) then
        return true
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message)
        return true
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
    return true
end

-- Fallback als a_helpers.lua niet in fxmanifest staat: keys.lua laadt vaak wél als eerste.
if type(OpenSavedOutfitsMenu) ~= 'function' then
    local function IsFemalePed(ped)
        return GetEntityModel(ped) == `mp_f_freemode_01`
    end

    ApplyAnwbOutfit = function(outfit)
        if type(outfit) ~= 'table' then return false end
        local ped = PlayerPedId()
        local genderData = IsFemalePed(ped) and (outfit.female or outfit.male) or (outfit.male or outfit.female)
        if type(genderData) ~= 'table' then return false end
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

    OpenSavedOutfitsMenu = function()
        local clothing = (Config and Config.Kleding) or 'jg-clothingmenu'
        local methods = { 'openSavedOutfits', 'OpenSavedOutfits', 'openOutfitMenu', 'OpenOutfitMenu', 'showOutfitMenu' }
        for i = 1, #methods do
            if SafeCallExport(clothing, methods[i]) then return true end
        end
        if SafeCallExport('ox_appearance', 'showOutfitMenu') then return true end
        pcall(function()
            TriggerEvent('ox_appearance:outfitMenu')
            TriggerEvent('illenium-appearance:client:openOutfitMenu')
            TriggerEvent('esx_skin:openSaveableMenu')
        end)
        SafeNotify('error', 'Geen persoonlijk kledingmenu gevonden.', 4000)
        return false
    end

    OpenJobOutfitMenu = function(outfits)
        outfits = outfits or (Config and Config.Outfits) or {}
        if SafeCallExport(Config.Jobsmenu, 'OpenOutfitMenu', outfits) then return true end
        local categories = {}
        for categoryName, categoryOutfits in pairs(outfits) do
            if type(categoryOutfits) == 'table' then
                categories[#categories + 1] = {
                    title = categoryName,
                    arrow = true,
                    onSelect = function()
                        local options = {}
                        for outfitName, outfitData in pairs(categoryOutfits) do
                            options[#options + 1] = {
                                title = outfitName,
                                onSelect = function()
                                    ApplyAnwbOutfit(outfitData)
                                end
                            }
                        end
                        lib.registerContext({
                            id = 'anwb:job-outfits:' .. categoryName,
                            title = categoryName,
                            options = options
                        })
                        lib.showContext('anwb:job-outfits:' .. categoryName)
                    end
                }
            end
        end
        if #categories == 0 then return false end
        lib.registerContext({ id = 'anwb:job-outfits', title = 'ANWB outfits', options = categories })
        lib.showContext('anwb:job-outfits')
        return true
    end

    SafeToggleDuty = function()
        local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
        if SafeCallExport(Config.Jobsmenu, 'ToggleDuty', jobName) then return true end
        TriggerServerEvent('jg-anwb:server:toggleDuty')
        return true
    end

    SafeOpenManagement = function()
        local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name or 'mechanic'
        if SafeCallExport(Config.Jobsmenu, 'OpenManagementMenu', jobName) then return true end
        pcall(function()
            TriggerEvent('esx_society:openBossMenu', 'mechanic', function() end, { wash = false })
        end)
        return true
    end
end

GiveJobVehicleKeys = function(vehicle, plate, props)
    plate = Trim(plate)

    if plate == '' and type(props) == 'table' and props.plate then
        plate = Trim(props.plate)
    end

    if plate == '' and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        plate = Trim(GetVehicleNumberPlateText(vehicle))
    end

    if (not props or type(props) ~= 'table') and vehicle and vehicle ~= 0 and ESX and ESX.Game then
        props = ESX.Game.GetVehicleProperties(vehicle)
    end

    local methods = { 'giveCarKeys', 'GiveCarKeys', 'GiveKeys', 'GiveKey', 'giveKeys' }
    local resources = {
        'jg-givekey',
        Config.Carkeys,
        'jg-carkeys',
        'qs-vehiclekeys',
        'wasabi_carlock',
        'qb-vehiclekeys',
        'qbx_vehiclekeys',
        'mk_vehiclekeys'
    }

    local tried = {}
    for i = 1, #resources do
        local resource = resources[i]
        if resource and not tried[resource] then
            tried[resource] = true
            for m = 1, #methods do
                if CallExport(resource, methods[m], plate, props, vehicle) then
                    return true
                end
            end
        end
    end

    -- Events blijven staan als vangnet; missende listeners crashen niet.
    TriggerEvent('jg-givekey:client:giveCarKeys', plate, props, vehicle)
    TriggerEvent('jg-carkeys:client:giveKeys', plate, props, vehicle)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerEvent('cd_garage:AddKeys', plate)
    return false
end

RemoveJobVehicleKeys = function(vehicle, plate, props)
    plate = Trim(plate)

    if plate == '' and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        plate = Trim(GetVehicleNumberPlateText(vehicle))
    end

    local resources = { 'jg-givekey', Config.Carkeys, 'jg-carkeys' }
    local methods = { 'removeCarKeys', 'RemoveCarKeys', 'RemoveKeys', 'RemoveKey' }
    local tried = {}

    for i = 1, #resources do
        local resource = resources[i]
        if resource and not tried[resource] then
            tried[resource] = true
            for m = 1, #methods do
                if CallExport(resource, methods[m], plate, props, vehicle) then
                    return true
                end
            end
        end
    end

    return false
end

SetJobVehicleFuel = function(vehicle, amount)
    amount = amount or 100.0

    if ResourceStarted(Config.Benzine) then
        if CallExport(Config.Benzine, 'setFuel', vehicle, amount) then
            return true
        end
        if CallExport(Config.Benzine, 'SetFuel', vehicle, amount) then
            return true
        end
    end

    if CallExport('LegacyFuel', 'SetFuel', vehicle, amount) then
        return true
    end

    if ResourceStarted('ox_fuel') and vehicle and vehicle ~= 0 then
        Entity(vehicle).state.fuel = amount
        return true
    end

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleFuelLevel(vehicle, amount + 0.0)
    end

    return true
end

BindAnwbLocationActions = function()
    if type(Config) ~= 'table' or type(Config.Locations) ~= 'table' then
        return false
    end

    local map = {
        OpenGarage = OpenGarage,
        DeleteVehicle = DeleteVehicle,
        CloakroomMenu = CloakroomMenu,
        OnOffDuty = OnOffDuty,
        GetGear = GetGear,
        OpenManagement = OpenManagement,
        ManagementMenu = OpenManagement,
        ['Garage'] = OpenGarage,
        ['Voertuig wegzetten'] = DeleteVehicle,
        ['Omkleden'] = CloakroomMenu,
        ['In-/uitklokken'] = OnOffDuty,
        ['Werkspullen pakken'] = GetGear,
        ['Baas acties'] = OpenManagement,
    }

    local bound = 0
    for _, loc in pairs(Config.Locations) do
        local fn = loc.functionDefine
        if type(fn) == 'string' then
            fn = map[fn] or rawget(_G, fn)
        end
        if type(fn) ~= 'function' then
            fn = map[loc.drawText]
        end
        if type(fn) == 'function' then
            loc.functionDefine = fn
            bound = bound + 1
        end
    end

    return bound > 0
end

CreateThread(function()
    print('^2[jg-anwb] keys.lua v3: locatie-acties worden gekoppeld^7')
    for _ = 1, 100 do
        if type(OpenGarage) == 'function' and BindAnwbLocationActions() then
            print('^2[jg-anwb] Garage/omkleden/duty acties gekoppeld^7')
            return
        end
        Wait(100)
    end
    print('^1[jg-anwb] Kon locatie-acties niet koppelen. Vervang de hele map jg-anwb.^7')
end)
