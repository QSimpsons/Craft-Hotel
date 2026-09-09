# Mallorca Speedometer

FiveM voertuig-HUD met snelheid, motorstatus, carrosserieschade, knipperlichten, noodknippers en handrem.

## Installatie

1. Kopieer de map `mallorca-speedometer` naar je `resources` folder.
2. Voeg toe aan `server.cfg`:

```cfg
ensure mallorca-speedometer
```

3. Herstart de resource of de server.

## Wat zie je

| Indicator | Betekenis |
|-----------|-----------|
| **Snelheid** | Huidige snelheid in km/h |
| **Motor** | Groen / geel / rood op basis van engine health |
| **Schade** | Groen / geel / rood op basis van body health |
| **Links / Rechts** | Knipperlichten (knipperen oranje) |
| **Noodknippers** | Beide richtingaanwijzers (rood/oranje) |
| **Handrem** | Wordt rood als de handrem erop staat |

## Bediening (standaard)

- **Pijl links** — knipperlicht links
- **Pijl rechts** — knipperlicht rechts
- **Pijl omlaag** — noodknippers aan/uit

Toetsen aanpassen via FiveM instellingen (Key Bindings → FiveM) of in `config.lua`.

## Config

Zie `config.lua` voor eenheden (km/h of mph), max snelheid op de meter, drempels voor groen/geel/rood en refresh-snelheid.

## Browser demo

Open `html/index.html` in een browser om de UI te testen zonder FiveM.
