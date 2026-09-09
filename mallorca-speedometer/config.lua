Config = {}

-- km/h of mph
Config.UseKmh = true

-- Max waarde op de snelheidsboog
Config.MaxSpeed = 280

-- Motorstatus drempels (engine health 0–1000)
Config.Engine = {
    green = 700,
    yellow = 300
}

-- Carrosserieschade drempels (body health 0–1000)
Config.Body = {
    green = 800,
    yellow = 400
}

-- Tank / brandstof
Config.Fuel = {
    -- Leeg laten = native GetVehicleFuelLevel (0–100)
    -- Of bv. 'LegacyFuel', 'ox_fuel', 'cdn-fuel', 'qs-fuelstations'
    Resource = '',
    -- Export-naam als je een fuel-script gebruikt (vaak 'GetFuel')
    Export = 'GetFuel',
    -- Drempels in %
    green = 40,
    yellow = 15
}

Config.TickMs = 50
Config.HideInPauseMenu = true

Config.EnableIndicatorKeys = true
Config.Keys = {
    left = 'LEFT',
    right = 'RIGHT',
    hazard = 'DOWN'
}
