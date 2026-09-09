Config = {}

-- km/h of mph
Config.UseKmh = true

-- Max waarde op de wijzerplaat (schaal)
Config.MaxSpeed = 280

-- Motorstatus drempels (engine health 0–1000)
Config.Engine = {
    green = 700,   -- >= groen
    yellow = 300   -- >= geel, daaronder rood
}

-- Carrosserieschade drempels (body health 0–1000)
Config.Body = {
    green = 800,
    yellow = 400
}

-- Update-interval in ms terwijl je in een voertuig zit
Config.TickMs = 50

-- Verberg bij pauzemenu
Config.HideInPauseMenu = true

-- Toetsen voor knipperlichten (optioneel; werkt ook met andere scripts die indicators zetten)
Config.EnableIndicatorKeys = true
Config.Keys = {
    left = 'LEFT',       -- pijl links
    right = 'RIGHT',     -- pijl rechts
    hazard = 'DOWN'      -- pijl omlaag = noodknippers
}
