Config = {}

-- Zelfde notify-resource als de JG jobs. Laat leeg om GTA feed te gebruiken.
Config.Notify = 'jg-notifications'

-- Toets om het dichtstbijzijnde voertuig (waar je sleutels van hebt) te vergrendelen.
Config.LockKey = 'U'
Config.LockDistance = 5.0

-- true = motor start niet zonder sleutel van dit script.
-- Zet dit op false als je al een ander keysysteem (qs/wasabi/qb/jg-carkeys) gebruikt.
Config.BlockEngineWithoutKeys = false

-- auto probeert bekende keys-scripts. 'standalone' deelt alleen sleutels in dit script.
-- Andere opties: qs-vehiclekeys, wasabi_carlock, qb-vehiclekeys, qbx_vehiclekeys, mk_vehiclekeys, cd_garage, okokGarage
Config.KeySystem = 'auto'
