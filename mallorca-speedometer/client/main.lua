local visible = false
local leftIndicator = false
local rightIndicator = false
local hazardOn = false

local function healthState(value, greenAt, yellowAt)
    if value >= greenAt then
        return 'green'
    elseif value >= yellowAt then
        return 'yellow'
    end
    return 'red'
end

local function fuelState(percent)
    local greenAt = (Config.Fuel and Config.Fuel.green) or 40
    local yellowAt = (Config.Fuel and Config.Fuel.yellow) or 15
    return healthState(percent, greenAt, yellowAt)
end

local function getFuelPercent(vehicle)
    local cfg = Config.Fuel or {}
    local resource = cfg.Resource
    local exportName = cfg.Export or 'GetFuel'

    if type(resource) == 'string' and resource ~= '' and GetResourceState(resource) == 'started' then
        local ok, value = pcall(function()
            return exports[resource][exportName](vehicle)
        end)
        if ok and type(value) == 'number' then
            return math.max(0.0, math.min(100.0, value + 0.0))
        end
    end

    -- Fallbacks voor populaire fuel-scripts zonder config
    local fallbacks = {
        { 'LegacyFuel', 'GetFuel' },
        { 'ox_fuel', 'GetFuel' },
        { 'cdn-fuel', 'GetFuel' },
        { 'qs-fuelstations', 'GetFuel' },
        { 'lc_fuel', 'GetFuel' },
        { 'ti_fuel', 'getFuel' },
    }

    for i = 1, #fallbacks do
        local name, exp = fallbacks[i][1], fallbacks[i][2]
        if GetResourceState(name) == 'started' then
            local ok, value = pcall(function()
                return exports[name][exp](vehicle)
            end)
            if ok and type(value) == 'number' then
                return math.max(0.0, math.min(100.0, value + 0.0))
            end
        end
    end

    local level = GetVehicleFuelLevel(vehicle)
    if type(level) ~= 'number' then
        return 100.0
    end
    return math.max(0.0, math.min(100.0, level + 0.0))
end

local function applyIndicators(vehicle)
    if not vehicle or vehicle == 0 then
        return
    end

    if hazardOn then
        SetVehicleIndicatorLights(vehicle, 0, true)
        SetVehicleIndicatorLights(vehicle, 1, true)
    else
        SetVehicleIndicatorLights(vehicle, 0, leftIndicator)
        SetVehicleIndicatorLights(vehicle, 1, rightIndicator)
    end
end

local function hideHud()
    if not visible then
        return
    end
    visible = false
    SendNUIMessage({ action = 'hide' })
end

local function pushHud(payload)
    visible = true
    SendNUIMessage({
        action = 'update',
        data = payload
    })
end

local function getDriverVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return 0
    end

    return vehicle
end

local function isHandbrakeOn(vehicle)
    if GetVehicleHandbrake(vehicle) then
        return true
    end
    -- Extra fallback terwijl je stilstaat met handrem-input
    if IsControlPressed(0, 76) then -- INPUT_VEH_HANDBRAKE
        return true
    end
    return false
end

local function areLightsOn(vehicle)
    local ok, lightsOn, highbeams = pcall(GetVehicleLightsState, vehicle)
    if not ok then
        return false
    end
    return lightsOn == 1 or highbeams == 1 or lightsOn == true or highbeams == true
end

CreateThread(function()
    while true do
        local vehicle = getDriverVehicle()

        if vehicle == 0 then
            if visible then
                hideHud()
            end
            leftIndicator = false
            rightIndicator = false
            hazardOn = false
            Wait(400)
        elseif Config.HideInPauseMenu and IsPauseMenuActive() then
            hideHud()
            Wait(200)
        else
            local speedRaw = GetEntitySpeed(vehicle)
            local speed = Config.UseKmh and (speedRaw * 3.6) or (speedRaw * 2.236936)
            local engineHealth = GetVehicleEngineHealth(vehicle)
            local bodyHealth = GetVehicleBodyHealth(vehicle)
            local fuel = getFuelPercent(vehicle)

            local showLeft = hazardOn or leftIndicator
            local showRight = hazardOn or rightIndicator

            pushHud({
                speed = math.floor(speed + 0.5),
                maxSpeed = Config.MaxSpeed or 280,
                unit = Config.UseKmh and 'km/h' or 'mph',
                engine = healthState(engineHealth, Config.Engine.green, Config.Engine.yellow),
                engineHealth = math.floor(math.max(0.0, math.min(1000.0, engineHealth)) / 10.0),
                damage = healthState(bodyHealth, Config.Body.green, Config.Body.yellow),
                bodyHealth = math.floor(math.max(0.0, math.min(1000.0, bodyHealth)) / 10.0),
                fuel = math.floor(fuel + 0.5),
                fuelState = fuelState(fuel),
                left = showLeft,
                right = showRight,
                hazard = hazardOn,
                handbrake = isHandbrakeOn(vehicle),
                lights = areLightsOn(vehicle),
                engineOn = GetIsVehicleEngineRunning(vehicle)
            })

            Wait(Config.TickMs or 50)
        end
    end
end)

if Config.EnableIndicatorKeys then
    RegisterCommand('ms_left_indicator', function()
        local vehicle = getDriverVehicle()
        if vehicle == 0 then return end

        hazardOn = false
        leftIndicator = not leftIndicator
        if leftIndicator then
            rightIndicator = false
        end
        applyIndicators(vehicle)
    end, false)

    RegisterCommand('ms_right_indicator', function()
        local vehicle = getDriverVehicle()
        if vehicle == 0 then return end

        hazardOn = false
        rightIndicator = not rightIndicator
        if rightIndicator then
            leftIndicator = false
        end
        applyIndicators(vehicle)
    end, false)

    RegisterCommand('ms_hazard', function()
        local vehicle = getDriverVehicle()
        if vehicle == 0 then return end

        hazardOn = not hazardOn
        if hazardOn then
            leftIndicator = false
            rightIndicator = false
        end
        applyIndicators(vehicle)
    end, false)

    RegisterKeyMapping('ms_left_indicator', 'Knipperlicht links', 'keyboard', Config.Keys.left)
    RegisterKeyMapping('ms_right_indicator', 'Knipperlicht rechts', 'keyboard', Config.Keys.right)
    RegisterKeyMapping('ms_hazard', 'Noodknippers', 'keyboard', Config.Keys.hazard)
end
