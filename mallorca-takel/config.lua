Config = {}

-- esx | standalone (standalone = iedereen mag takelen, zonder job)
Config.Framework = 'esx'

-- ESX job
Config.JobName = 'takel'
Config.Society = 'society_takel'
Config.RequireJob = true
Config.RequireDuty = true

-- Toetsen (ook aanpasbaar in FiveM Key Bindings)
Config.Keys = {
    menu = 'F6',
    toggle = 'J' -- takelen / loskoppelen
}

Config.Command = 'takel'
Config.CallCommand = 'takelhulp'

-- Afstanden
Config.InteractDistance = 2.6
Config.TowSearchDistance = 9.0
Config.ImpoundDistance = 8.0
Config.BillDistance = 4.0

-- Bedragen
Config.Prices = {
    impound = 1500,
    minBill = 100,
    maxBill = 25000,
    callReward = 850,
    npcCallReward = 1200
}

-- Alleen deze voertuigklassen mogen getakeld worden
-- 0-12 auto/moto/van, 17 service, 18 emergency, 20 commercial
Config.AllowedClasses = {
    [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
    [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
    [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [20] = true
}

-- Takelwagens: hook = kraan, flatbed = laadbak
Config.TowVehicles = {
    [`towtruck`] = {
        type = 'hook',
        label = 'Takelwagen'
    },
    [`towtruck2`] = {
        type = 'hook',
        label = 'Takelwagen Tow'
    },
    [`flatbed`] = {
        type = 'flatbed',
        label = 'Flatbed',
        bone = 'bodyshell',
        offset = vector3(0.0, -2.2, 1.05),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    [`slamtruck`] = {
        type = 'flatbed',
        label = 'Slamtruck',
        bone = 'bodyshell',
        offset = vector3(0.0, -1.15, 0.55),
        rotation = vector3(0.0, 0.0, 0.0)
    }
}

-- Depot + inbeslagname (La Mesa / Davis – aanpassen naar jouw map)
Config.Depot = {
    label = 'Mallorca Takel',
    coords = vector3(491.19, -1314.78, 29.26),
    heading = 34.0,
    blip = { sprite = 68, color = 47, scale = 0.9 },
    spawn = vector4(479.48, -1326.41, 29.21, 5.0),
    store = vector3(479.48, -1326.41, 29.21)
}

Config.Impound = {
    label = 'Inbeslagname',
    coords = vector3(401.68, -1631.80, 29.29),
    heading = 230.0,
    blip = { sprite = 677, color = 1, scale = 0.75 },
    spawn = vector4(391.74, -1618.02, 29.29, 230.0),
    retrieve = vector3(409.24, -1623.08, 29.29)
}

Config.GarageVehicles = {
    { model = 'flatbed', label = 'Flatbed', minGrade = 0 },
    { model = 'towtruck', label = 'Takelwagen', minGrade = 0 },
    { model = 'towtruck2', label = 'Takelwagen Tow', minGrade = 1 },
    { model = 'slamtruck', label = 'Slamtruck', minGrade = 2 }
}

-- NPC-proefritten / pechhulp-oproepen (zet op false om alleen spelersoproepen te gebruiken)
Config.NpcCalls = {
    enabled = true,
    intervalMs = 180000,
    minOnDuty = 1,
    spots = {
        vector3(215.86, -810.12, 30.73),
        vector3(-303.41, -933.12, 31.08),
        vector3(1178.41, 2653.98, 37.81),
        vector3(-1603.21, -831.45, 10.07),
        vector3(1963.44, 3752.11, 32.21),
        vector3(-51.12, -1114.55, 26.44)
    },
    models = { 'sultan', 'banshee', 'asea', 'premier', 'oracle', 'buffalo' }
}

Config.Markers = {
    type = 1,
    scale = vector3(1.6, 1.6, 0.6),
    color = { r = 232, g = 93, b = 4, a = 140 }
}

Config.Locale = {
    duty_on = 'Je bent nu in dienst bij Mallorca Takel.',
    duty_off = 'Je bent uit dienst.',
    not_employee = 'Je werkt niet bij Mallorca Takel.',
    need_duty = 'Ga eerst in dienst bij het depot.',
    no_truck = 'Je hebt geen takelwagen in de buurt.',
    no_target = 'Geen voertuig om te takelen.',
    class_blocked = 'Dit voertuig mag niet getakeld worden.',
    attached = 'Voertuig is vastgemaakt.',
    detached = 'Voertuig is losgekoppeld.',
    already_towing = 'Je hebt al een voertuig op de haak.',
    not_towing = 'Er hangt geen voertuig aan je wagen.',
    impounded = 'Voertuig inbeslaggenomen.',
    need_attached = 'Takel eerst een voertuig en rijd naar de inbeslagname.',
    billed = 'Factuur verstuurd.',
    bill_received = 'Je hebt een takelfactuur ontvangen.',
    paid = 'Betaald. Je voertuig staat klaar.',
    cannot_pay = 'Niet genoeg contant geld.',
    call_sent = 'Takeldienst is gewaarschuwd.',
    call_taken = 'Oproep aangenomen. GPS gezet.',
    call_new = 'Nieuwe takeloproep binnengekomen.',
    truck_out = 'Takelwagen uitgehaald.',
    truck_in = 'Takelwagen weggezet.',
    spawn_blocked = 'Spawnplek is geblokkeerd.',
    released = 'Voertuig vrijgegeven.',
    no_vehicle = 'Geen voertuig gevonden.',
    occupied = 'Laat inzittenden eerst uitstappen.'
}
