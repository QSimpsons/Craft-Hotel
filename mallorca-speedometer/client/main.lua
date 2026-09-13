--[[ Mallorca Speedometer - client ]]

local visible = false
local leftOn = false
local rightOn = false
local hazardOn = false

local currentPlate = nil
local fuelReady = true
local lastSaveAt = 0
local lastFuelSaved = nil

local function colorFor(value, greenAt, yellowAt)
    if value >= greenAt then return 'green' end
    if value >= yellowAt then return 'yellow' end
    return 'red'
end

local function fuelColor(pct)
    local g = (Config.Fuel and Config.Fuel.green) or 40
    local y = (Config.Fuel and Config.Fuel.yellow) or 15
    return colorFor(pct, g, y)
end

local function cleanPlate(plate)
    if type(plate) ~= 'string' then return '' end
    return (plate:gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

local function plateOf(vehicle)
    return cleanPlate(GetVehicleNumberPlateText(vehicle))
end

local function driverVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return 0 end
    local veh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(veh, -1) ~= ped then return 0 end
    return veh
end

local function externalFuel()
    local cfg = Config.Fuel or {}
    if type(cfg.Resource) == 'string' and cfg.Resource ~= '' and GetResourceState(cfg.Resource) == 'started' then
        return cfg.Resource, cfg.Export or 'GetFuel'
    end
    local list = {
        { 'LegacyFuel', 'GetFuel' },
        { 'ox_fuel', 'GetFuel' },
        { 'cdn-fuel', 'GetFuel' },
        { 'qs-fuelstations', 'GetFuel' },
        { 'lc_fuel', 'GetFuel' },
        { 'ti_fuel', 'getFuel' },
    }
    for i = 1, #list do
        if GetResourceState(list[i][1]) == 'started' then
            return list[i][1], list[i][2]
        end
    end
    return nil, nil
end

local function readFuel(vehicle)
    local res, exp = externalFuel()
    if res then
        local ok, val = pcall(function() return exports[res][exp](vehicle) end)
        if ok and type(val) == 'number' then
            return math.max(0.0, math.min(100.0, val + 0.0))
        end
    end
    local lvl = GetVehicleFuelLevel(vehicle)
    if type(lvl) ~= 'number' then return 100.0 end
    return math.max(0.0, math.min(100.0, lvl + 0.0))
end

local function writeFuel(vehicle, amount)
    amount = math.max(0.0, math.min(100.0, amount + 0.0))
    SetVehicleFuelLevel(vehicle, amount)
    local res = externalFuel()
    if res then
        pcall(function()
            if exports[res].SetFuel then
                exports[res]:SetFuel(vehicle, amount)
            end
        end)
    end
end

local function saveFuel(vehicle, force)
    if not Config.Fuel or not Config.Fuel.UseDatabase then return end
    if externalFuel() then return end
    if not vehicle or vehicle == 0 then return end

    local plate = plateOf(vehicle)
    if plate == '' then return end

    local fuel = readFuel(vehicle)
    local now = GetGameTimer()
    local every = (Config.Fuel.SaveMs or 15000)

    if not force then
        if (now - lastSaveAt) < every then return end
        if lastFuelSaved and math.abs(lastFuelSaved - fuel) < 0.5 then return end
    end

    lastSaveAt = now
    lastFuelSaved = fuel
    TriggerServerEvent('mallorca-speedometer:server:saveFuel', plate, fuel)
end

local function loadFuel(vehicle)
    if not Config.Fuel or not Config.Fuel.UseDatabase or externalFuel() then
        fuelReady = true
        return
    end

    local plate = plateOf(vehicle)
    if plate == '' then
        fuelReady = true
        return
    end

    currentPlate = plate
    fuelReady = false
    TriggerServerEvent('mallorca-speedometer:server:getFuel', plate)

    -- Fallback als SQL niet antwoordt
    Citizen.SetTimeout(1500, function()
        if currentPlate == plate and not fuelReady then
            fuelReady = true
        end
    end)
end

RegisterNetEvent('mallorca-speedometer:client:setFuel', function(plate, fuel)
    plate = cleanPlate(plate)
    if currentPlate ~= plate then return end
    local veh = driverVehicle()
    if veh ~= 0 then
        writeFuel(veh, tonumber(fuel) or 100.0)
    end
    fuelReady = true
end)

local function setIndicators(vehicle)
    if vehicle == 0 then return end
    if hazardOn then
        SetVehicleIndicatorLights(vehicle, 0, true)
        SetVehicleIndicatorLights(vehicle, 1, true)
    else
        SetVehicleIndicatorLights(vehicle, 0, leftOn)
        SetVehicleIndicatorLights(vehicle, 1, rightOn)
    end
end

local function hide()
    if not visible then return end
    visible = false
    SendNUIMessage({ action = 'hide' })
end

local function show(data)
    visible = true
    SendNUIMessage({ action = 'update', data = data })
end

local function handbrakeOn(vehicle)
    local ok, hb = pcall(function() return GetVehicleHandbrake(vehicle) end)
    if ok and hb then return true end
    return IsControlPressed(0, 76)
end

local function lightsOn(vehicle)
    local on, high = 0, 0
    local ok = pcall(function()
        local _, a, b = GetVehicleLightsState(vehicle)
        on, high = a, b
    end)
    if not ok then return false end
    return on == 1 or high == 1 or on == true or high == true
end

local function burnFuel(vehicle, dt)
    if not Config.Fuel or Config.Fuel.Consume == false then return end
    if externalFuel() then return end
    if not GetIsVehicleEngineRunning(vehicle) then return end

    local speed = GetEntitySpeed(vehicle) * 3.6
    local use = (Config.Fuel.IdleDrain or 0.01) * dt
    if speed > 1.0 then
        use = use + ((Config.Fuel.DriveDrain or 0.035) + speed * (Config.Fuel.SpeedDrain or 0.00025)) * dt
    end

    local fuel = readFuel(vehicle)
    local nextFuel = math.max(0.0, fuel - use)
    if math.abs(nextFuel - fuel) > 0.0001 then
        writeFuel(vehicle, nextFuel)
    end
    if nextFuel <= 0.0 then
        SetVehicleEngineOn(vehicle, false, true, true)
    end
end

CreateThread(function()
    local wasIn = false
    local lastVeh = 0
    local lastTick = GetGameTimer()

    while true do
        local veh = driverVehicle()
        local now = GetGameTimer()
        local dt = math.max(0.0, (now - lastTick) / 1000.0)
        lastTick = now

        if veh == 0 then
            if wasIn and lastVeh ~= 0 then
                saveFuel(lastVeh, true)
            end
            wasIn = false
            lastVeh = 0
            currentPlate = nil
            fuelReady = true
            leftOn, rightOn, hazardOn = false, false, false
            hide()
            Wait(400)
        elseif Config.HideInPauseMenu and IsPauseMenuActive() then
            hide()
            Wait(200)
        else
            if (not wasIn) or lastVeh ~= veh then
                loadFuel(veh)
            end
            wasIn = true
            lastVeh = veh

            if fuelReady then
                burnFuel(veh, dt)
                saveFuel(veh, false)
            end

            local speedRaw = GetEntitySpeed(veh)
            local speed = Config.UseKmh and (speedRaw * 3.6) or (speedRaw * 2.236936)
            local engineHp = GetVehicleEngineHealth(veh)
            local bodyHp = GetVehicleBodyHealth(veh)
            local fuel = readFuel(veh)

            show({
                speed = math.floor(speed + 0.5),
                maxSpeed = Config.MaxSpeed or 280,
                unit = Config.UseKmh and 'km/h' or 'mph',
                engine = colorFor(engineHp, Config.Engine.green, Config.Engine.yellow),
                engineHealth = math.floor(math.max(0.0, math.min(1000.0, engineHp)) / 10.0),
                damage = colorFor(bodyHp, Config.Body.green, Config.Body.yellow),
                bodyHealth = math.floor(math.max(0.0, math.min(1000.0, bodyHp)) / 10.0),
                fuel = math.floor(fuel + 0.5),
                fuelState = fuelColor(fuel),
                left = hazardOn or leftOn,
                right = hazardOn or rightOn,
                hazard = hazardOn,
                handbrake = handbrakeOn(veh),
                lights = lightsOn(veh),
                engineOn = GetIsVehicleEngineRunning(veh)
            })

            Wait(Config.TickMs or 50)
        end
    end
end)

if Config.EnableIndicatorKeys then
    RegisterCommand('ms_left_indicator', function()
        local veh = driverVehicle()
        if veh == 0 then return end
        hazardOn = false
        leftOn = not leftOn
        if leftOn then rightOn = false end
        setIndicators(veh)
    end, false)

    RegisterCommand('ms_right_indicator', function()
        local veh = driverVehicle()
        if veh == 0 then return end
        hazardOn = false
        rightOn = not rightOn
        if rightOn then leftOn = false end
        setIndicators(veh)
    end, false)

    RegisterCommand('ms_hazard', function()
        local veh = driverVehicle()
        if veh == 0 then return end
        hazardOn = not hazardOn
        if hazardOn then leftOn, rightOn = false, false end
        setIndicators(veh)
    end, false)

    RegisterKeyMapping('ms_left_indicator', 'Knipperlicht links', 'keyboard', Config.Keys.left)
    RegisterKeyMapping('ms_right_indicator', 'Knipperlicht rechts', 'keyboard', Config.Keys.right)
    RegisterKeyMapping('ms_hazard', 'Noodknippers', 'keyboard', Config.Keys.hazard)
end
