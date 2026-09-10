Config = {}

Config.UseKmh = true
Config.MaxSpeed = 280

Config.Engine = {
    green = 700,
    yellow = 300
}

Config.Body = {
    green = 800,
    yellow = 400
}

-- Tank / brandstof
Config.Fuel = {
    -- true = brandstof laden/opslaan via SQL (sql/install.sql + owned_vehicles.fuel)
    UseDatabase = true,

    -- Optioneel extern fuel-script (heeft voorrang op SQL/native)
    -- Voorbeelden: 'LegacyFuel', 'ox_fuel', 'cdn-fuel'
    Resource = '',
    Export = 'GetFuel',

    -- Verbruik per seconde bij stilstand / rijden (alleen als UseDatabase of native, zonder extern script)
    Consume = true,
    IdleDrain = 0.01,     -- % / sec stilstaand met motor aan
    DriveDrain = 0.035,   -- % / sec basis terwijl je rijdt
    SpeedDrain = 0.00025, -- extra % / sec per km/h

    -- Hoe vaak opslaan naar SQL (ms)
    SaveMs = 15000,

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
