# Mallorca Speedometer

Complete FiveM voertuig-HUD.

## Snelle installatie

1. Map `mallorca-speedometer` in `resources` zetten  
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

## Config brandstof

```lua
Config.Fuel.UseDatabase = true
Config.Fuel.Consume = true
Config.Fuel.Resource = ''          -- of 'LegacyFuel' / 'ox_fuel'
Config.Fuel.Export = 'GetFuel'
```

## Preview

Open `html/index.html` in een browser.
