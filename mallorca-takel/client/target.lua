local function employeeOnDuty()
    if not MallorcaTakelIsEmployee or not MallorcaTakelIsEmployee() then
        return false
    end
    if Config.RequireDuty then
        return MallorcaTakelOnDuty and MallorcaTakelOnDuty()
    end
    return true
end

local function isParkedTow(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if not Tow.IsTowVehicle(entity) then
        return false
    end
    if Entity(entity).state and Entity(entity).state.mallorcaTakelParked then
        return true
    end
    local plate = (GetVehicleNumberPlateText(entity) or ''):gsub('%s+', '')
    return plate:find('TAKEL') ~= nil
end

local function registerOxTarget()
    if GetResourceState('ox_target') ~= 'started' then
        return false
    end

    exports.ox_target:addGlobalVehicle({
        {
            name = 'mallorca_takel_tow',
            icon = 'fa-solid fa-link',
            label = Config.Locale.eye_tow,
            distance = Config.TargetDistance or 2.5,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                if not entity or Tow.IsTowVehicle(entity) then return false end
                local attached = Tow.GetAttached()
                return attached == 0
            end,
            onSelect = function(data)
                TriggerEvent('mallorca-takel:internal:eyeTow', data.entity)
            end
        },
        {
            name = 'mallorca_takel_detach',
            icon = 'fa-solid fa-link-slash',
            label = Config.Locale.eye_detach,
            distance = Config.TargetDistance or 2.5,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                local attached = Tow.GetAttached()
                if attached == 0 then return false end
                return entity == attached or Tow.IsTowVehicle(entity)
            end,
            onSelect = function()
                TriggerEvent('mallorca-takel:internal:eyeDetach')
            end
        },
        {
            name = 'mallorca_takel_impound',
            icon = 'fa-solid fa-warehouse',
            label = Config.Locale.eye_impound,
            distance = Config.TargetDistance or 2.5,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                local attached = Tow.GetAttached()
                if attached == 0 then return false end
                if entity ~= attached and not Tow.IsTowVehicle(entity) then return false end
                return #(GetEntityCoords(PlayerPedId()) - Config.Impound.coords) <= (Config.ImpoundDistance + 4.0)
            end,
            onSelect = function()
                TriggerEvent('mallorca-takel:internal:eyeImpound')
            end
        },
        {
            name = 'mallorca_takel_take',
            icon = 'fa-solid fa-key',
            label = Config.Locale.eye_take_truck,
            distance = Config.TargetDistance or 2.5,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                return isParkedTow(entity)
            end,
            onSelect = function(data)
                TriggerEvent('mallorca-takel:internal:eyeTakeTruck', data.entity)
            end
        },
        {
            name = 'mallorca_takel_call',
            icon = 'fa-solid fa-phone',
            label = Config.Locale.eye_call,
            distance = Config.TargetDistance or 2.5,
            canInteract = function(entity)
                if Tow.IsTowVehicle(entity) then return false end
                return true
            end,
            onSelect = function(data)
                TriggerEvent('mallorca-takel:internal:eyeCall', data.entity)
            end
        }
    })

    pcall(function()
        exports.ox_target:addBoxZone({
            coords = Config.Depot.coords,
            size = vec3(2.4, 2.4, 2.2),
            rotation = Config.Depot.heading or 0,
            debug = false,
            options = {
                {
                    name = 'mallorca_takel_tablet',
                    icon = 'fa-solid fa-tablet-screen-button',
                    label = Config.Locale.eye_tablet,
                    canInteract = function()
                        return MallorcaTakelIsEmployee and MallorcaTakelIsEmployee()
                    end,
                    onSelect = function()
                        TriggerEvent('mallorca-takel:internal:eyeTablet')
                    end
                }
            }
        })
    end)

    return true
end

local function qbOptions()
    return {
        {
            icon = 'fas fa-link',
            label = Config.Locale.eye_tow,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                if not entity or Tow.IsTowVehicle(entity) then return false end
                return Tow.GetAttached() == 0
            end,
            action = function(entity)
                TriggerEvent('mallorca-takel:internal:eyeTow', entity)
            end
        },
        {
            icon = 'fas fa-unlink',
            label = Config.Locale.eye_detach,
            canInteract = function(entity)
                if not employeeOnDuty() then return false end
                local attached = Tow.GetAttached()
                if attached == 0 then return false end
                return entity == attached or Tow.IsTowVehicle(entity)
            end,
            action = function()
                TriggerEvent('mallorca-takel:internal:eyeDetach')
            end
        },
        {
            icon = 'fas fa-key',
            label = Config.Locale.eye_take_truck,
            canInteract = function(entity)
                return employeeOnDuty() and isParkedTow(entity)
            end,
            action = function(entity)
                TriggerEvent('mallorca-takel:internal:eyeTakeTruck', entity)
            end
        },
        {
            icon = 'fas fa-phone',
            label = Config.Locale.eye_call,
            canInteract = function(entity)
                return entity and not Tow.IsTowVehicle(entity)
            end,
            action = function(entity)
                TriggerEvent('mallorca-takel:internal:eyeCall', entity)
            end
        }
    }
end

local function registerQbTarget()
    local resource = nil
    if GetResourceState('qb-target') == 'started' then
        resource = 'qb-target'
    elseif GetResourceState('qtarget') == 'started' then
        resource = 'qtarget'
    end
    if not resource then
        return false
    end

    exports[resource]:AddGlobalVehicle({
        options = qbOptions(),
        distance = Config.TargetDistance or 2.5
    })

    exports[resource]:AddBoxZone('mallorca_takel_depot', Config.Depot.coords, 2.4, 2.4, {
        name = 'mallorca_takel_depot',
        heading = Config.Depot.heading or 0,
        minZ = Config.Depot.coords.z - 1.0,
        maxZ = Config.Depot.coords.z + 2.0
    }, {
        options = {
            {
                icon = 'fas fa-tablet-alt',
                label = Config.Locale.eye_tablet,
                canInteract = function()
                    return MallorcaTakelIsEmployee and MallorcaTakelIsEmployee()
                end,
                action = function()
                    TriggerEvent('mallorca-takel:internal:eyeTablet')
                end
            }
        },
        distance = 2.5
    })

    return true
end

CreateThread(function()
    if Config.UseTarget == false then
        return
    end

    local timeout = GetGameTimer() + 15000
    while GetGameTimer() < timeout do
        if registerOxTarget() then
            return
        end
        if registerQbTarget() then
            return
        end
        Wait(500)
    end
end)
