local ownedKeys = {}

local function Trim(value)
    if value == nil then
        return ''
    end

    return (tostring(value):gsub('^%s*(.-)%s*$', '%1'))
end

local function ResourceStarted(name)
    return type(name) == 'string' and name ~= '' and GetResourceState(name) == 'started'
end

local function Notify(nType, message, duration)
    duration = duration or 4000

    if ResourceStarted(Config.Notify) then
        pcall(function()
            exports[Config.Notify]:Notify(nType, message, duration)
        end)
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function GetPlateFromArgs(plate, props, vehicle)
    local resolved = Trim(plate)

    if resolved == '' and type(props) == 'table' and props.plate then
        resolved = Trim(props.plate)
    end

    if resolved == '' and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        resolved = Trim(GetVehicleNumberPlateText(vehicle))
    end

    return resolved
end

local function GetVehicleModelName(vehicle, props)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    end

    if type(props) == 'table' and props.model then
        return GetDisplayNameFromVehicleModel(props.model)
    end

    return 'UNKNOWN'
end

local function FindVehicleByPlate(plate)
    plate = Trim(plate)
    if plate == '' then
        return 0
    end

    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        if Trim(GetVehicleNumberPlateText(vehicles[i])) == plate then
            return vehicles[i]
        end
    end

    return 0
end

local function UnlockVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
end

local function CallExport(resource, method, ...)
    if not ResourceStarted(resource) then
        return false
    end

    local args = { ... }
    local ok = pcall(function()
        exports[resource][method](table.unpack(args))
    end)

    return ok
end

local function DetectKeySystem()
    if Config.KeySystem ~= 'auto' then
        return Config.KeySystem
    end

    local systems = {
        'qs-vehiclekeys',
        'wasabi_carlock',
        'qb-vehiclekeys',
        'qbx_vehiclekeys',
        'mk_vehiclekeys',
        'cd_garage',
        'okokGarage',
        'vehicles_keys',
        't1ger_keys'
    }

    for i = 1, #systems do
        if ResourceStarted(systems[i]) then
            return systems[i]
        end
    end

    return 'standalone'
end

local function ForwardGiveKeys(plate, props, vehicle)
    local system = DetectKeySystem()
    local model = GetVehicleModelName(vehicle, props)

    if system == 'qs-vehiclekeys' then
        return CallExport('qs-vehiclekeys', 'GiveKeys', plate, model, false)
    elseif system == 'wasabi_carlock' then
        return CallExport('wasabi_carlock', 'GiveKey', plate)
    elseif system == 'qb-vehiclekeys' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        return true
    elseif system == 'qbx_vehiclekeys' then
        if vehicle and vehicle ~= 0 then
            return CallExport('qbx_vehiclekeys', 'GiveKeys', vehicle)
        end
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        return true
    elseif system == 'mk_vehiclekeys' then
        if vehicle and vehicle ~= 0 then
            return CallExport('mk_vehiclekeys', 'AddKey', vehicle)
        end
    elseif system == 'cd_garage' then
        TriggerEvent('cd_garage:AddKeys', plate)
        return true
    elseif system == 'okokGarage' then
        TriggerServerEvent('okokGarage:GiveKeys', plate)
        return true
    elseif system == 'vehicles_keys' then
        TriggerServerEvent('vehicles_keys:selfGiveVehicleKeys', plate)
        return true
    elseif system == 't1ger_keys' then
        TriggerServerEvent('t1ger_keys:updateOwnedKeys', plate, true)
        return true
    end

    -- Harmless fallbacks for Dutch JG packs that luisteren naar events i.p.v. exports.
    TriggerEvent('jg-carkeys:client:giveKeys', plate, props, vehicle)
    TriggerEvent('jg-carkeys:giveCarKeys', plate, props)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    return system == 'standalone'
end

local function ForwardRemoveKeys(plate, props, vehicle)
    local system = DetectKeySystem()
    local model = GetVehicleModelName(vehicle, props)

    if system == 'qs-vehiclekeys' then
        return CallExport('qs-vehiclekeys', 'RemoveKeys', plate, model)
    elseif system == 'wasabi_carlock' then
        return CallExport('wasabi_carlock', 'RemoveKey', plate)
    elseif system == 'qb-vehiclekeys' then
        TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plate)
        return true
    elseif system == 'qbx_vehiclekeys' then
        if vehicle and vehicle ~= 0 then
            return CallExport('qbx_vehiclekeys', 'RemoveKeys', vehicle)
        end
    elseif system == 't1ger_keys' then
        TriggerServerEvent('t1ger_keys:updateOwnedKeys', plate, false)
        return true
    end

    TriggerEvent('jg-carkeys:client:removeKeys', plate)
    return true
end

local function GiveCarKeys(plate, props, vehicle)
    plate = GetPlateFromArgs(plate, props, vehicle)
    if plate == '' then
        return false
    end

    if (not vehicle or vehicle == 0) then
        vehicle = FindVehicleByPlate(plate)
    end

    ownedKeys[plate] = true
    UnlockVehicle(vehicle)
    ForwardGiveKeys(plate, props, vehicle)
    Notify('success', ('Sleutels ontvangen: %s'):format(plate), 3500)
    return true
end

local function RemoveCarKeys(plate, props, vehicle)
    plate = GetPlateFromArgs(plate, props, vehicle)
    if plate == '' then
        return false
    end

    ownedKeys[plate] = nil
    ForwardRemoveKeys(plate, props, vehicle)
    return true
end

local function HasCarKeys(plate)
    return ownedKeys[GetPlateFromArgs(plate)] == true
end

local function GetClosestOwnedVehicle(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local current = GetVehiclePedIsIn(ped, false)

    if current ~= 0 and HasCarKeys(GetVehicleNumberPlateText(current)) then
        return current
    end

    local closest, closestDist = 0, maxDistance or Config.LockDistance
    local vehicles = GetGamePool('CVehicle')

    for i = 1, #vehicles do
        local veh = vehicles[i]
        local plate = Trim(GetVehicleNumberPlateText(veh))
        if ownedKeys[plate] then
            local dist = #(coords - GetEntityCoords(veh))
            if dist <= closestDist then
                closest = veh
                closestDist = dist
            end
        end
    end

    return closest
end

local function ToggleLock()
    local vehicle = GetClosestOwnedVehicle(Config.LockDistance)
    if vehicle == 0 then
        Notify('error', 'Geen voertuig in de buurt waar je sleutels van hebt.', 3500)
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    local plate = Trim(GetVehicleNumberPlateText(vehicle))

    if lockStatus == 2 or lockStatus == 3 then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        Notify('success', ('Voertuig %s ontgrendeld'):format(plate), 2500)
    else
        SetVehicleDoorsLocked(vehicle, 2)
        Notify('success', ('Voertuig %s vergrendeld'):format(plate), 2500)
    end

    PlayVehicleDoorCloseSound(vehicle, 1)
end

exports('giveCarKeys', GiveCarKeys)
exports('GiveCarKeys', GiveCarKeys)
exports('GiveKeys', GiveCarKeys)
exports('GiveKey', GiveCarKeys)
exports('removeCarKeys', RemoveCarKeys)
exports('RemoveCarKeys', RemoveCarKeys)
exports('hasCarKeys', HasCarKeys)
exports('HasCarKeys', HasCarKeys)

RegisterNetEvent('jg-givekey:client:giveCarKeys', function(plate, props, vehicle)
    GiveCarKeys(plate, props, vehicle)
end)

RegisterNetEvent('jg-givekey:client:removeCarKeys', function(plate, props, vehicle)
    RemoveCarKeys(plate, props, vehicle)
end)

RegisterCommand('jg_givekey_togglelock', function()
    ToggleLock()
end, false)

RegisterKeyMapping('jg_givekey_togglelock', 'Voertuig vergrendelen/ontgrendelen', 'keyboard', Config.LockKey or 'U')

CreateThread(function()
    while true do
        local sleep = 500

        if Config.BlockEngineWithoutKeys then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local plate = Trim(GetVehicleNumberPlateText(vehicle))
                if not ownedKeys[plate] then
                    sleep = 100
                    SetVehicleEngineOn(vehicle, false, true, true)
                end
            end
        end

        Wait(sleep)
    end
end)
