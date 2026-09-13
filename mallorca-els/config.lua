Config = {}

-- Alleen deze pechhulp-voertuigen (spawncodes)
Config.Vehicles = {
    [`fmltow`] = {
        label = 'FML Tow',
        extras = { 1, 2 },
        left = { 1 },
        right = { 2 }
    },
    [`dlbrickade`] = {
        label = 'DL Brickade',
        extras = { 1, 2 },
        left = { 1 },
        right = { 2 }
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

-- Pinkers, achterlichten en remlichten: nooit aanraken
Config.UseIndicators = false
Config.IndicatorExtras = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
Config.LightExtras = { 1, 2 }

-- Koplampen, achterlichten en remlichten nooit meenemen met ELS
Config.HeadlightWigwag = false
Config.ShowPanel = true

-- Geen stille sirene: die laat achterlichten/remlichten vaak meeflikkeren
Config.MutedSirenLights = false

-- Paneel verschijnt bij instappen, lampen blijven uit tot 1/2/3
Config.StartStageOnEnter = 0

Config.Locale = {
    stage = 'Lichten',
    scene_on = 'Werklicht aan',
    scene_off = 'Werklicht uit'
}
