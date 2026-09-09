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

local function applyIndicators(vehicle)
    if not vehicle or vehicle == 0 then
        return
    end

    -- 0 = links, 1 = rechts
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
            local handbrake = GetVehicleHandbrake(vehicle)

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
                left = showLeft,
                right = showRight,
                hazard = hazardOn,
                handbrake = handbrake,
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
        else
            applyIndicators(vehicle)
            return
        end
        applyIndicators(vehicle)
    end, false)

    RegisterKeyMapping('ms_left_indicator', 'Knipperlicht links', 'keyboard', Config.Keys.left)
    RegisterKeyMapping('ms_right_indicator', 'Knipperlicht rechts', 'keyboard', Config.Keys.right)
    RegisterKeyMapping('ms_hazard', 'Noodknippers', 'keyboard', Config.Keys.hazard)
end
