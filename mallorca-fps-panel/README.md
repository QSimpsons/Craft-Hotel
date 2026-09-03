# Mallorca FPS Panel

FiveM NUI-balk bovenin het scherm met **8 slots**. Het Mallorca-wapen zit **in het midden**, tussen de twee groepen. Er is **geen CPU-meter**.

## De 8 onderdelen

| Positie | Slot |
| --- | --- |
| Links | FPS |
| Links | Ping |
| Links | ID |
| Links | Spelers |
| **Midden** | **Mallorca-crest** |
| Rechts | Tijd |
| Rechts | Stem |
| Rechts | Discord |

## Installatie

1. Zet de map `mallorca-fps-panel` in `resources`.
2. Voeg toe aan `server.cfg`:

```
ensure mallorca-fps-panel
```

3. Pas namen en Discord aan in `config.lua`.

## Bediening

- `F7` of `/fps` zet het panel aan of uit.
- Stem volgt `pma-voice` of SaltyChat als die resource draait; anders blijft het op `Normaal`.

## Demo in de browser

Open `mallorca-fps-panel/html/index.html` in een browser. Buiten FiveM start automatisch een Mallorca-demo met live FPS/ping-schommeling.
