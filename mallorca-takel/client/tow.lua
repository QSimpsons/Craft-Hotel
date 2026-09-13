Tow = Tow or {}

local attachedVehicle = 0
local attachedTow = 0
local attachedType = nil

local function modelConfig(vehicle)
    if vehicle == 0 then return nil end
    return Config.TowVehicles[GetEntityModel(vehicle)]
end

function Tow.IsTowVehicle(vehicle)
    return modelConfig(vehicle) ~= nil
end

function Tow.GetAttached()
    if attachedVehicle ~= 0 and DoesEntityExist(attachedVehicle) then
        return attachedVehicle, attachedTow, attachedType
    end
    attachedVehicle = 0
    attachedTow = 0
    attachedType = nil
    return 0, 0, nil
end

function Tow.EnsureControl(entity)
    if entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if NetworkHasControlOfEntity(entity) then
        return true
    end
    local timeout = GetGameTimer() + 1500
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

function Tow.IsClassAllowed(vehicle)
    local class = GetVehicleClass(vehicle)
    return Config.AllowedClasses[class] == true
end

function Tow.EmptyVehicle(vehicle)
    local occupied = false
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxPassengers do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 then
            occupied = true
            if IsPedAPlayer(ped) then
                TaskLeaveVehicle(ped, vehicle, 16)
            else
                TaskLeaveVehicle(ped, vehicle, 16)
            end
        end
    end
    if occupied then
        Wait(900)
        if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
            return false
        end
    end
    return true
end

local function closestFromPoint(point, maxDist, ignore)
    local vehicles = GetGamePool('CVehicle')
    local closest, dist = 0, maxDist
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if veh ~= ignore and DoesEntityExist(veh) then
            local d = #(GetEntityCoords(veh) - point)
            if d < dist then
                closest = veh
                dist = d
            end
        end
    end
    return closest, dist
end

function Tow.FindTruck(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and Tow.IsTowVehicle(veh) then
        return veh
    end

    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closest, dist = 0, 6.0
    for i = 1, #vehicles do
        local v = vehicles[i]
        if Tow.IsTowVehicle(v) then
            local d = #(GetEntityCoords(v) - coords)
            if d < dist then
                closest = v
                dist = d
            end
        end
    end
    return closest
end

function Tow.FindTarget(tow)
    local cfg = modelConfig(tow)
    if not cfg then return 0 end

    local point
    if cfg.type == 'hook' then
        point = GetOffsetFromEntityInWorldCoords(tow, 0.0, 7.0, 0.0)
    else
        point = GetOffsetFromEntityInWorldCoords(tow, 0.0, -7.5, 0.0)
    end

    local target = closestFromPoint(point, Config.TowSearchDistance, tow)
    if target == 0 or Tow.IsTowVehicle(target) then
        return 0
    end
    return target
end

local function attachHook(tow, target)
    SetVehicleTowTruckArmPosition(tow, 1.0)
    Wait(250)
    AttachVehicleToTowTruck(tow, target, true, 0.0, 0.0, 0.0)
    return IsVehicleAttachedToTowTruck(tow, target)
end

local function attachFlatbed(tow, target, cfg)
    local bone = GetEntityBoneIndexByName(tow, cfg.bone or 'bodyshell')
    if bone == -1 then bone = 0 end
    local off = cfg.offset or vector3(0.0, -2.0, 1.0)
    local rot = cfg.rotation or vector3(0.0, 0.0, 0.0)
    AttachEntityToEntity(
        target, tow, bone,
        off.x, off.y, off.z,
        rot.x, rot.y, rot.z,
        false, false, true, false, 2, true
    )
    return IsEntityAttachedToEntity(target, tow)
end

function Tow.Attach()
    local ped = PlayerPedId()
    local current = Tow.GetAttached()
    if current ~= 0 then
        return false, 'already_towing'
    end

    local tow = Tow.FindTruck(ped)
    if tow == 0 then
        return false, 'no_truck'
    end

    local cfg = modelConfig(tow)
    local target = Tow.FindTarget(tow)
    if target == 0 then
        return false, 'no_target'
    end

    if not Tow.IsClassAllowed(target) then
        return false, 'class_blocked'
    end

    if not Tow.EmptyVehicle(target) then
        return false, 'occupied'
    end

    if not Tow.EnsureControl(tow) or not Tow.EnsureControl(target) then
        return false, 'no_target'
    end

    SetVehicleEngineOn(target, false, true, true)
    local ok
    if cfg.type == 'hook' then
        ok = attachHook(tow, target)
    else
        ok = attachFlatbed(tow, target, cfg)
    end

    if not ok then
        return false, 'no_target'
    end

    attachedVehicle = target
    attachedTow = tow
    attachedType = cfg.type
    return true, 'attached', target, tow
end

function Tow.Detach(dropOnGround)
    local target, tow, kind = Tow.GetAttached()
    if target == 0 then
        return false, 'not_towing'
    end

    Tow.EnsureControl(target)
    Tow.EnsureControl(tow)

    if kind == 'hook' and tow ~= 0 then
        DetachVehicleFromTowTruck(tow, target)
        SetVehicleTowTruckArmPosition(tow, 0.0)
    else
        DetachEntity(target, true, true)
    end

    FreezeEntityPosition(target, false)
    if dropOnGround ~= false and tow ~= 0 and DoesEntityExist(tow) then
        local drop = GetOffsetFromEntityInWorldCoords(tow, 0.0, kind == 'hook' and 8.5 or -10.0, 0.2)
        SetEntityCoords(target, drop.x, drop.y, drop.z, false, false, false, false)
        SetVehicleOnGroundProperly(target)
    end

    attachedVehicle = 0
    attachedTow = 0
    attachedType = nil
    return true, 'detached', target
end

function Tow.Describe(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end
    local plate = GetVehicleNumberPlateText(vehicle) or ''
    plate = plate:gsub('^%s+', ''):gsub('%s+$', '')
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or 'VOERTUIG'
    local body = math.floor((GetVehicleBodyHealth(vehicle) / 10.0) + 0.5)
    local engine = math.floor((GetVehicleEngineHealth(vehicle) / 10.0) + 0.5)
    return {
        plate = plate,
        model = model,
        body = body,
        engine = engine,
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    }
end
