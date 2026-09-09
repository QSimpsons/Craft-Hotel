# Mallorca Speedometer

FiveM HUD: snelheid, tank, motor, schade, pinkers, noodknippers, handrem en lichten.

## Installatie

```cfg
ensure mallorca-speedometer
```

## Functies

| Onderdeel | Werking |
|-----------|---------|
| Snelheid | km/h met boog |
| **Tank** | Ronde meter + % (groen / geel / rood) |
| Motor | Groen / geel / rood |
| Schade | Dim bij gezond, geel/rood bij schade |
| Links / rechts | Knipperlichten |
| Noodknippers | Beide pinkers |
| Handrem | Rood als die erop staat |
| Lichten | Groen als lampen aan staan |

## Brandstof-script

Standaard: `GetVehicleFuelLevel` (GTA native).

Gebruik je LegacyFuel / ox_fuel / cdn-fuel e.d., zet in `config.lua`:

```lua
Config.Fuel.Resource = 'LegacyFuel'  -- of 'ox_fuel', 'cdn-fuel', ...
Config.Fuel.Export = 'GetFuel'
```

Zonder config probeert de resource automatisch bekende fuel-scripts.

## Toetsen

- Pijl links / rechts — pinkers  
- Pijl omlaag — noodknippers  

## Preview

Open `html/index.html` of `html/voorbeeld.html` in een browser.
