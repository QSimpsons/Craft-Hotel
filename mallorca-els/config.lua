Config = {}

-- Alleen deze pechhulp-voertuigen (spawncodes)
Config.Vehicles = {
    [`fmltow`] = {
        label = 'FML Tow',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
    },
    [`dlbrickade`] = {
        label = 'DL Brickade',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
    }
}

-- 0 uit · 1 achter · 2 zwaai · 3 vol
Config.StageNames = {
    [0] = 'UIT',
    [1] = 'ACHTER',
    [2] = 'ZWAAI',
    [3] = 'VOL'
}

Config.Keys = {
    stage1 = '1',
    stage2 = '2',
    stage3 = '3',
    off = '0',
    siren = 'G',
    scene = 'R'
}

Config.FlashMs = {
    [2] = 140,
    [3] = 90
}

Config.UseHazardsFromStage = 2
Config.HeadlightWigwag = true
Config.SirenNeedsLights = true
Config.HornOverride = true
Config.ShowPanel = true

-- Paneel verschijnt bij instappen, lampen blijven uit tot 1/2/3
Config.StartStageOnEnter = 0

Config.Locale = {
    stage = 'Lichten',
    siren_on = 'Toon aan',
    siren_off = 'Toon uit',
    scene_on = 'Werklicht aan',
    scene_off = 'Werklicht uit',
    need_lights = 'Zet eerst de lichten aan (1, 2 of 3).'
}
