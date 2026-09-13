Tow = Tow or {}

local attachedVehicle = 0
local attachedTow = 0
local attachedType = nil
local extraHashes

local function extraModelSet()
    if extraHashes then
        return extraHashes
    end
    extraHashes = {}
    for i = 1, #(Config.ExtraTowModels or {}) do
        extraHashes[joaat(Config.ExtraTowModels[i])] = true
    end
    return extraHashes
end

local function defaultFlatbed()
    return {
        type = 'flatbed',
        label = 'Takelwagen',
        bone = 'bodyshell',
        offset = vector3(0.0, -2.0, 1.0),
        rotation = vector3(0.0, 0.0, 0.0)
    }
end

local function defaultHook()
    return { type = 'hook', label = 'Takelwagen' }
end

function Tow.GetProfile(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local model = GetEntityModel(vehicle)
    if Config.TowVehicles[model] then
        return Config.TowVehicles[model]
    end

    if extraModelSet()[model] then
        if IsThisModelATowTruck(model) then
            return defaultHook()
        end
        return defaultFlatbed()
    end

    if IsThisModelATowTruck(model) then
        return defaultHook()
    end

    local name = string.lower(GetDisplayNameFromVehicleModel(model) or '')
    if name:find('tow', 1, true) or name:find('wreck', 1, true) then
        return defaultHook()
    end
    if name:find('flat', 1, true) or name:find('slam', 1, true) or name:find('takel', 1, true) or name:find('bed', 1, true) then
        return defaultFlatbed()
    end

    return nil
end

function Tow.IsTowVehicle(vehicle)
    return Tow.GetProfile(vehicle) ~= nil
end

function Tow.IsUsableTow(vehicle)
    if Tow.IsTowVehicle(vehicle) then
        return true
    end
    if not Config.AllowCurrentVehicle then
        return false
    end
    local class = GetVehicleClass(vehicle)
    return class == 10 or class == 11 or class == 17 or class == 20
end

function Tow.ResolveProfile(vehicle)
    return Tow.GetProfile(vehicle) or (Tow.IsUsableTow(vehicle) and defaultFlatbed()) or nil
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
    local timeout = GetGameTimer() + 2500
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

function Tow.FindTruck(ped, maxDist)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and Tow.IsUsableTow(veh) then
        return veh
    end

    maxDist = maxDist or 8.0
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closest, dist = 0, maxDist
    for i = 1, #vehicles do
        local v = vehicles[i]
        if Tow.IsUsableTow(v) then
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
    local cfg = Tow.ResolveProfile(tow)
    if not cfg then return 0 end

    local point
    if cfg.type == 'hook' then
        point = GetOffsetFromEntityInWorldCoords(tow, 0.0, 7.0, 0.0)
    else
        point = GetOffsetFromEntityInWorldCoords(tow, 0.0, -7.5, 0.0)
    end

    local target = closestFromPoint(point, Config.TowSearchDistance or 12.0, tow)
    if target == 0 then
        target = closestFromPoint(GetEntityCoords(tow), Config.TowSearchDistance or 12.0, tow)
    end
    if target == 0 or Tow.IsUsableTow(target) then
        return 0
    end
    return target
end

local function prepareEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    SetVehicleHasBeenOwnedByPlayer(entity, true)
    if not NetworkGetEntityIsNetworked(entity) then
        NetworkRegisterEntityAsNetworked(entity)
    end
end

local function attachHook(tow, target)
    prepareEntity(target)
    prepareEntity(tow)
    SetVehicleTowTruckArmPosition(tow, 1.0)
    Wait(200)
    AttachVehicleToTowTruck(tow, target, true, 0.0, 0.0, 0.0)
    Wait(150)
    if IsVehicleAttachedToTowTruck(tow, target) or IsEntityAttachedToEntity(target, tow) then
        return true
    end
    AttachVehicleToTowTruck(tow, target, false, 0.0, 0.0, 0.0)
    Wait(150)
    if IsVehicleAttachedToTowTruck(tow, target) or IsEntityAttachedToEntity(target, tow) then
        return true
    end
    local bone = GetEntityBoneIndexByName(tow, 'bodyshell')
    if bone == -1 then
        bone = GetEntityBoneIndexByName(tow, 'chassis')
    end
    if bone == -1 then bone = 0 end
    AttachEntityToEntity(target, tow, bone, 0.0, 2.8, 0.35, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
    return IsEntityAttachedToEntity(target, tow) or IsVehicleAttachedToTowTruck(tow, target)
end

local function attachFlatbed(tow, target, cfg)
    prepareEntity(target)
    prepareEntity(tow)

    local bones = { cfg.bone or 'bodyshell', 'bodyshell', 'chassis', 'chassis_dummy', 'boot' }
    local offsets = {
        cfg.offset or vector3(0.0, -2.0, 1.0),
        vector3(0.0, -2.2, 1.05),
        vector3(0.0, -1.7, 0.9),
        vector3(0.0, -2.5, 1.15),
        vector3(0.0, -1.4, 0.65)
    }
    local rot = cfg.rotation or vector3(0.0, 0.0, 0.0)

    for b = 1, #bones do
        local bone = GetEntityBoneIndexByName(tow, bones[b])
        if bone ~= -1 or b == #bones then
            if bone == -1 then bone = 0 end
            for o = 1, #offsets do
                local off = offsets[o]
                AttachEntityToEntity(
                    target, tow, bone,
                    off.x, off.y, off.z,
                    rot.x, rot.y, rot.z,
                    false, false, true, false, 20, true
                )
                Wait(50)
                if IsEntityAttachedToEntity(target, tow) then
                    return true
                end
            end
        end
    end
    return IsEntityAttachedToEntity(target, tow)
end

function Tow.Attach(specificTarget)
    local ped = PlayerPedId()
    local current = Tow.GetAttached()
    if current ~= 0 then
        return false, 'already_towing'
    end

    local searchDist = specificTarget and 18.0 or 10.0
    local tow = Tow.FindTruck(ped, searchDist)
    if tow == 0 then
        return false, 'no_truck'
    end

    local cfg = Tow.ResolveProfile(tow)
    if not cfg then
        return false, 'no_truck'
    end

    local target = specificTarget
    if not target or target == 0 or not DoesEntityExist(target) then
        target = Tow.FindTarget(tow)
    end
    if target == 0 or target == tow then
        return false, 'no_target'
    end
    if Tow.IsUsableTow(target) then
        return false, 'class_blocked'
    end

    if #(GetEntityCoords(tow) - GetEntityCoords(target)) > 18.0 then
        return false, 'too_far_truck'
    end

    if not Tow.IsClassAllowed(target) then
        return false, 'class_blocked'
    end

    if not Tow.EmptyVehicle(target) then
        return false, 'occupied'
    end

    Tow.EnsureControl(tow)
    Tow.EnsureControl(target)

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
