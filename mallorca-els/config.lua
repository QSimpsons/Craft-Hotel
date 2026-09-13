Config = {}

-- Alleen deze pechhulp-voertuigen (spawncodes)
Config.Vehicles = {
    [`fmltow`] = {
        label = 'FML Tow',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
        groupA = { 1, 3, 5, 7, 9, 11 },
        groupB = { 2, 4, 6, 8, 10, 12 }
    },
    [`dlbrickade`] = {
        label = 'DL Brickade',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
        groupA = { 1, 3, 5, 7, 9, 11 },
        groupB = { 2, 4, 6, 8, 10, 12 }
    }
}

-- 0 = uit, 1 = cruise, 2 = waarschuwing, 3 = vol
Config.StageNames = {
    [0] = 'UIT',
    [1] = 'CRUISE',
    [2] = 'WAARSCHUWING',
    [3] = 'VOL'
}

Config.Keys = {
    stage = 'Q', -- zwaailichten cyclen
    siren = 'G'  -- sirene aan/uit (vanaf stage 2)
}

Config.FlashMs = {
    [2] = 180,
    [3] = 110
}

-- Noodknippers erbij vanaf stage 2
Config.UseHazardsFromStage = 2

-- Koplampen knipperen op stage 3
Config.HeadlightWigwag = true

-- Sirene mag alleen met zwaailichten (stage 2 of 3)
Config.SirenNeedsLights = true

-- Claxon (E / hoorn) = korte sirene zolang je indrukt, als de sirene zelf uit staat
Config.HornOverride = true

-- HUD-paneel alleen tonen als je in de wagen zit
Config.ShowPanel = true

-- ELS gaat aan bij instappen (1 = cruise). 0 = paneel wel, lampen nog uit
Config.StartStageOnEnter = 1

Config.Locale = {
    no_vehicle = 'ELS werkt alleen in de fmltow of dlbrickade.',
    siren_on = 'Sirene aan',
    siren_off = 'Sirene uit',
    need_lights = 'Zet eerst de zwaailichten aan (Q).'
}
