Config = {}

Config.EnableESXService = false

Config.Setup = {
    ['ProgressBars'] = {
        ['ReceiveVehicle'] = 3500,
        ['RemoveVehicle'] = 3500,
        ['WashVehicle'] = 10000
    }
}


--------//////////Dit zijn de script namen die de anwbjob nodig heeft dus als je resource renamt dan moet je het ook hier veranderen\\\\\\\\\\--------
Config.Notify = 'jg-notifications'
Config.interaction = 'vex-interaction'
Config.Jobsmenu = 'jg-jobsmenu'
-- jg-givekey levert de ontbrekende giveCarKeys export. Zet dit op 'jg-carkeys'
-- als je compat/jg-carkeys-export.lua in je bestaande jg-carkeys hebt gezet.
Config.Carkeys = 'jg-givekey'
Config.Benzine = 'jg-benzine'
Config.Kleding = 'jg-clothingmenu'
Config.Progress = 'jg-progressbar'
--------//////////Dit zijn de script namen die de anwbjob nodig heeft dus als je resource renamt dan moet je het ook hier veranderen\\\\\\\\\\--------

Config.BlipSprite  = 446
Config.BlipDisplay = 4
Config.BlipScale   = 0.9
Config.BlipColour  = 47
Config.Blips = {}

Config.Timers = { -- Seconde * 1000
      TrailerSelectTimer = 5000,
      VehicleSelectTimer = 5000,
}

Config.Peds = {
	-- {
	-- 	model = 's_m_m_gaffer_01',
	-- 	coords = vector3(815.7990, -886.1822, 25.2508),
	-- 	heading = 110.9,
	-- 	scenario = 'WORLD_HUMAN_CLIPBOARD_FACILITY',
	-- },
}

Config.Gear = {
    {
        name = 'radio',
        count = 1,
    },
    {
        name = 'WEAPON_FIREEXTINGUISHER',
        count = 1,
    },
}


Config.Locations = {
	-- Weazel news
    {
        coords = vector3(-357.3671, -129.5489, 39.4307),
        drawText = 'Garage',
        functionDefine = OpenGarage,
        spawnPoints = {                   
            [1] = vector4(-369.2175, -122.8222, 38.6958, 21.6022),
        }
    },
    {
        coords = vector3(-367.4038, -113.1842, 38.6964),
        drawText = 'Voertuig wegzetten',
        functionDefine = DeleteVehicle,
        deleteType = 'any',
    },
    { -- Beneden
        coords = vector3(-341.4538, -162.1770, 44.5875),
        drawText = 'Omkleden',
        functionDefine = CloakroomMenu,
    },
    {
        coords = vector3(-331.4392, -156.8388, 39.0149),
        drawText = 'In-/uitklokken',
        functionDefine = OnOffDuty,
    },
    {
        coords = vector3(-351.53, -159.24, 39.02),
        drawText = 'Werkspullen pakken',
        functionDefine = GetGear
    },
    {
        coords = vector3(-339.6403, -157.4421, 44.5871),
        rank = 5,
        drawText = 'Baas acties',
        functionDefine = OpenManagement,
    },
	-- {
    --     drawText = 'Management openen',
    --     drawIcon = 'fas fa-database',
    --     target = true,
    --     coords = vector3(457.09, -993.33, 30.72),
    --     length = 0.4,
    --     width = 0.4,
    --     height = 0.4,
    --     heading = 0,
    --     functionDefine = ManagementMenu,
	-- 	rank = 6
    -- },
}

Config.Actions = {
    repairVehicle = {
        actions = {
            animation = {
                enabled = true,
                scenario = 'PROP_HUMAN_BUM_BIN',
                duration = 20000,
            }
        }
    },
    washVehicle = {
        actions = {
            animation = {
                enabled = true,
                scenario = 'WORLD_HUMAN_MAID_CLEAN',
                duration = 10000,
            }
        }
    },
}

Config.Vehicles = {
    cars = {
        {
            category = 'Dienstvoertuigen',
            description = 'Reguliere dienstvoertuigen',
            rank = 0,
            vehicles = {
                {
                    name = 'Speedopech',
                    spawnName = 'Speedopech'
                },
                {
                    name = 'fmltow',
                    spawnName = 'fmltow'
                },
                {
                    name = 'dlcontmec',
                    spawnName = 'dlcontmec'
                },
                {
                    name = 'dlbrickade',
                    spawnName = 'dlbrickade'
                },
            }
        },
        {
            category = 'Binnenkort..',
            description = 'Binnenkort..',
            rank = 0,
            vehicles = {
                {
                    name = 'Binnenkort..',
                    spawnName = 'Binnenkort..'
                },
                {
                    name = 'Binnenkort..',
                    spawnName = 'Binnenkort..'
                },
            }
        },
        {
            category = 'Binnenkort..',
            description = 'Binnenkort..',
            rank = 0,
            vehicles = {
                {
                    name = 'Binnenkort..',
                    spawnName = 'Binnenkort..'
                },
                {
                    name = 'Binnenkort..)',
                    spawnName = 'Binnenkort..'
                },
            }
        },
    }
}