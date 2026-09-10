local visible = false
local leftIndicator = false
local rightIndicator = false
local hazardOn = false

local currentPlate = nil
local dbFuelLoaded = false
local lastSaveAt = 0
local lastFuelSaved = nil

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

local function normalizePlate(plate)
    if type(plate) ~= 'string' then
        return ''
    end
    return (plate:gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

local function getPlate(vehicle)
    return normalizePlate(GetVehicleNumberPlateText(vehicle))
end

local function hasExternalFuel()
    local cfg = Config.Fuel or {}
    if type(cfg.Resource) == 'string' and cfg.Resource ~= '' and GetResourceState(cfg.Resource) == 'started' then
        return true, cfg.Resource, cfg.Export or 'GetFuel'
    end

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
            return true, name, exp
        end
    end

    return false
end

local function getExternalFuel(vehicle)
    local okExt, resource, exportName = hasExternalFuel()
    if not okExt then
        return nil
    end

    local ok, value = pcall(function()
        return exports[resource][exportName](vehicle)
    end)

    if ok and type(value) == 'number' then
        return math.max(0.0, math.min(100.0, value + 0.0))
    end

    return nil
end

local function getFuelPercent(vehicle)
    local external = getExternalFuel(vehicle)
    if external ~= nil then
        return external
    end

    local level = GetVehicleFuelLevel(vehicle)
    if type(level) ~= 'number' then
        return 100.0
    end
    return math.max(0.0, math.min(100.0, level + 0.0))
end

local function setFuelLevel(vehicle, amount)
    amount = math.max(0.0, math.min(100.0, amount + 0.0))
    SetVehicleFuelLevel(vehicle, amount)

    local okExt, resource = hasExternalFuel()
    if okExt then
        pcall(function()
            if exports[resource].SetFuel then
                exports[resource]:SetFuel(vehicle, amount)
            end
        end)
    end
end

local function saveFuel(vehicle, force)
    if not Config.Fuel or not Config.Fuel.UseDatabase then
        return
    end
    if hasExternalFuel() then
        return
    end
    if not vehicle or vehicle == 0 then
        return
    end

    local plate = getPlate(vehicle)
    if plate == '' then
        return
    end

    local fuel = getFuelPercent(vehicle)
    local now = GetGameTimer()
    local saveMs = (Config.Fuel and Config.Fuel.SaveMs) or 15000

    if not force then
        if (now - lastSaveAt) < saveMs then
            return
        end
        if lastFuelSaved ~= nil and math.abs(lastFuelSaved - fuel) < 0.5 then
            return
        end
    end

    lastSaveAt = now
    lastFuelSaved = fuel
    TriggerServerEvent('mallorca-speedometer:server:saveFuel', plate, fuel)
end

local function requestFuelFromDb(vehicle)
    if not Config.Fuel or not Config.Fuel.UseDatabase then
        return
    end
    if hasExternalFuel() then
        dbFuelLoaded = true
        return
    end

    local plate = getPlate(vehicle)
    if plate == '' then
        return
    end

    currentPlate = plate
    dbFuelLoaded = false
    TriggerServerEvent('mallorca-speedometer:server:getFuel', plate)
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

RegisterNetEvent('mallorca-speedometer:client:setFuel', function(plate, fuel)
    plate = normalizePlate(plate)
    if currentPlate ~= plate then
        return
    end

    local vehicle = getDriverVehicle()
    if vehicle ~= 0 then
        setFuelLevel(vehicle, tonumber(fuel) or 100.0)
    end
    dbFuelLoaded = true
end)

local function isHandbrakeOn(vehicle)
    if GetVehicleHandbrake(vehicle) then
        return true
    end
    if IsControlPressed(0, 76) then
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

local function consumeFuel(vehicle, dt)
    if not Config.Fuel or Config.Fuel.Consume == false then
        return
    end
    if hasExternalFuel() then
        return
    end
    if not GetIsVehicleEngineRunning(vehicle) then
        return
    end

    local speed = GetEntitySpeed(vehicle) * 3.6
    local idle = (Config.Fuel.IdleDrain or 0.01) * dt
    local drive = 0.0
    if speed > 1.0 then
        drive = ((Config.Fuel.DriveDrain or 0.035) + speed * (Config.Fuel.SpeedDrain or 0.00025)) * dt
    end

    local fuel = getFuelPercent(vehicle)
    local nextFuel = math.max(0.0, fuel - idle - drive)
    if math.abs(nextFuel - fuel) > 0.0001 then
        setFuelLevel(vehicle, nextFuel)
    end

    if nextFuel <= 0.0 and GetIsVehicleEngineRunning(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, true)
    end
end

CreateThread(function()
    local wasInVehicle = false
    local lastVehicle = 0
    local lastTick = GetGameTimer()

    while true do
        local vehicle = getDriverVehicle()
        local now = GetGameTimer()
        local dt = math.max(0.0, (now - lastTick) / 1000.0)
        lastTick = now

        if vehicle == 0 then
            if wasInVehicle and lastVehicle ~= 0 then
                saveFuel(lastVehicle, true)
            end
            wasInVehicle = false
            lastVehicle = 0
            currentPlate = nil
            dbFuelLoaded = false

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
            if not wasInVehicle or lastVehicle ~= vehicle then
                requestFuelFromDb(vehicle)
            end
            wasInVehicle = true
            lastVehicle = vehicle

            if dbFuelLoaded or not (Config.Fuel and Config.Fuel.UseDatabase) or hasExternalFuel() then
                consumeFuel(vehicle, dt)
                saveFuel(vehicle, false)
            end

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
