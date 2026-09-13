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
