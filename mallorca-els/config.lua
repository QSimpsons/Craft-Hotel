Config = {}

-- Alleen deze pechhulp-voertuigen (spawncodes)
Config.Vehicles = {
    [`fmltow`] = {
        label = 'FML Tow',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
        left = { 1, 3, 5, 7, 9, 11, 13 },
        right = { 2, 4, 6, 8, 10, 12, 14 }
    },
    [`dlbrickade`] = {
        label = 'DL Brickade',
        extras = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
        left = { 1, 3, 5, 7, 9, 11, 13 },
        right = { 2, 4, 6, 8, 10, 12, 14 }
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
    scene = 'R'
}

Config.FlashMs = {
    [2] = 160,
    [3] = 80
}

-- Noodknippers alleen op zwaai (2), niet op vol
Config.UseHazardsFromStage = 2

-- Koplampen nooit meenemen met ELS
Config.HeadlightWigwag = false
Config.ShowPanel = true

-- Balk-emissives zonder geluid (veel addons zetten de 2e kant op de sirene-mesh)
Config.MutedSirenLights = true

-- Paneel verschijnt bij instappen, lampen blijven uit tot 1/2/3
Config.StartStageOnEnter = 0

Config.Locale = {
    stage = 'Lichten',
    scene_on = 'Werklicht aan',
    scene_off = 'Werklicht uit'
}
