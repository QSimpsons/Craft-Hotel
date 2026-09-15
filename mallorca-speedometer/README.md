# Mallorca Speedometer

Complete FiveM voertuig-HUD.

## Snelle installatie

1. Zip uitpakken en map `mallorca-speedometer` in `resources` zetten  
2. `sql/install.sql` uitvoeren in je database  
3. In `server.cfg`:

```cfg
ensure oxmysql
ensure mallorca-speedometer
```

Zie ook `INSTALL.txt`.

## Functies

| Onderdeel | Status |
|-----------|--------|
| Snelheid (fluo oranje) | ✅ |
| Tankmeter + % | ✅ |
| Tank opslaan in SQL | ✅ `owned_vehicles.fuel` |
| Motor groen/geel/rood | ✅ |
| Schade | ✅ |
| Links / rechts pinker | ✅ |
| Noodknippers | ✅ |
| Handrem (rood) | ✅ |
| Lichten | ✅ |

## Toetsen

- **← / →** pinkers  
- **↓** noodknippers  

## Snelheid

De boog en het getal lopen tot **1300 km/h** (`Config.MaxSpeed` in `config.lua`).
Hoger dan dat wordt afgekapt in de HUD; de echte voertuigsnelheid blijft ongewijzigd.

## Config brandstof

```lua
Config.Fuel.UseDatabase = true
Config.Fuel.Consume = true
Config.Fuel.Resource = ''          -- of 'LegacyFuel' / 'ox_fuel'
Config.Fuel.Export = 'GetFuel'
```

## Preview

Open `html/index.html` in een browser.
