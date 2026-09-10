# Mallorca Speedometer (compleet)

Complete FiveM-resource. Klaar om in `resources` te zetten.

## Inhoud

```
mallorca-speedometer/
├── fxmanifest.lua
├── config.lua
├── README.md
├── client/
│   └── main.lua
└── html/
    ├── index.html
    ├── style.css
    ├── app.js
    ├── voorbeeld.html
    └── auto-demo.html
```

## Installatie

1. Pak `mallorca-speedometer.zip` uit in je server-`resources` map  
   (of kopieer de map `mallorca-speedometer` daarheen).
2. Zet in `server.cfg`:

```cfg
ensure mallorca-speedometer
```

3. Herstart de resource of de server:
```
ensure mallorca-speedometer
```

## Functies

| Onderdeel | Werking |
|-----------|---------|
| Snelheid | km/h in **fluo oranje** met boog |
| Tank | Ronde meter + % (groen / geel / rood) |
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

- **Pijl links / rechts** — pinkers  
- **Pijl omlaag** — noodknippers  

(Aanpasbaar in FiveM Key Bindings of `config.lua`.)

## Preview (zonder FiveM)

Open in een browser:
- `html/index.html` — interactieve demo
- `html/voorbeeld.html` — auto-demo
