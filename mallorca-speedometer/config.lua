Config = {}

-- Eenheden
Config.UseKmh = true
Config.MaxSpeed = 280

-- Motor (engine health 0-1000)
Config.Engine = {
    green = 700,
    yellow = 300
}

-- Schade (body health 0-1000)
Config.Body = {
    green = 800,
    yellow = 400
}

-- Brandstof / tank
Config.Fuel = {
    -- SQL: sql/install.sql -> kolom owned_vehicles.fuel
    UseDatabase = true,

    -- Extern fuel-script (heeft voorrang). Leeg = native/SQL
    -- Voorbeelden: 'LegacyFuel', 'ox_fuel', 'cdn-fuel'
    Resource = '',
    Export = 'GetFuel',

    -- Verbruik (alleen zonder extern fuel-script)
    Consume = true,
    IdleDrain = 0.01,      -- % per seconde stilstand
    DriveDrain = 0.035,    -- % per seconde rijden
    SpeedDrain = 0.00025,  -- extra % per km/h per seconde

    SaveMs = 15000,        -- opslaan naar SQL

    green = 40,            -- >= groen
    yellow = 15            -- >= geel, anders rood
}

Config.TickMs = 50
Config.HideInPauseMenu = true

Config.EnableIndicatorKeys = true
Config.Keys = {
    left = 'LEFT',
    right = 'RIGHT',
    hazard = 'DOWN'
}
