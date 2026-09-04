# Mallorca HUD voor ESX Legacy 1.15.0

Deze pack is de originele Mallorca HUD, aangepast zodat hij start en blijft werken op **ESX Legacy 1.15.0**.

## Wat er kapot ging op 1.15.0

- `esx_status` en `esx_basicneeds` startten niet zonder **Fiveguard**
- `esx_status` overschreef `ESX.Players` (dat zijn in 1.15 echte speler-objecten)
- De HUD crashte zonder `job2` (tweede baan bestaat niet in vanilla ESX)
- Geld/status-updates liepen niet meer betrouwbaar mee met `OnPlayerData` / `esx_status:onTick`
- ESX 1.15 heeft geen `status`-kolom in `users`, en `ESX.Streaming` is verhuisd naar `xLib`

## Inhoud

| Resource | Functie |
| --- | --- |
| `esx_status` | Honger/dorst-status, 1.15-safe opslag |
| `esx_basicneeds` | Eten/drinken + `/heal` |
| `mallorca-hud` | De visuele HUD |

## Installatie

1. Importeer de SQL:
   - `esx_status/status.sql` (verplicht)
   - `esx_basicneeds/items.sql` (alleen als je het standaard ESX-inventory gebruikt, niet ox_inventory)
2. Zet de drie mappen in je resources (deze `[hud]`-map mag je zo laten staan).
3. **Vervang** eventuele oude `esx_status` / `esx_basicneeds` (of stop die). Twee status-resources tegelijk conflicteren.
4. Zet in `server.cfg`, **na** `es_extended` / `esx_lib` / `oxmysql`:

```cfg
ensure oxmysql
ensure es_extended
ensure esx_lib
ensure esx_status
ensure esx_basicneeds
ensure mallorca-hud
```

5. Restart de server.

## Commands

- `/hud` — HUD aan/uit
- `/radar` of `/minimap` — minimap aan/uit
- `/heal [id]` — admin, herstelt HP + honger + dorst

## Opmerkingen

- Tweede baan (`job2`) is optioneel. Zonder dual-job script blijft alleen de hoofdbaan zichtbaar.
- Job-iconen staan in `mallorca-hud/html/img/jobs/`. Ontbreekt een icoon, dan valt de HUD terug op `unemployed.png`.
- Extra eten/drinken: voeg items toe in `esx_basicneeds/config.lua` onder `Config.Items`.
