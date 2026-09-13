# Mallorca Takel

Volledig custom FiveM-takelscript voor **ESX Legacy 1.15**. Zelf geschreven: takelen, inbeslagname, oproepen, facturen en een Mallorca-tablet.

## Installatie

1. Unzip `mallorca-takel` in je `resources` folder.
2. Voer `sql/install.sql` uit (HeidiSQL / phpMyAdmin).
3. Zet in `server.cfg` **na** `es_extended` en `oxmysql`:

```cfg
ensure oxmysql
ensure es_extended
ensure ox_target
ensure mallorca-takel
```

4. Job `mechanic` of `takel` is genoeg (geen extra job nodig).

5. `ensure mallorca-takel` of herstart de server.

## Bediening

| Actie | Hoe |
|--------|-----|
| Tablet | **F1**, `/takel` of oogje op het depot |
| Takelen / loskoppelen | **Oogje** op het voertuig, of **O** |
| Takelwagen pakken | Oogje op de wagens bij het depot |
| Pechhulp vragen | Oogje op je auto, of `/takelhulp` |
| Depot | Marker bij Mallorca Takel, **E** |
| Inbeslagname | Met voertuig op de haak naar de rode marker, **E** |
| Ophalen | Gouden marker bij de pound, **E** |

Toetsen aanpassen: FiveM → Settings → Key Bindings → FiveM.

## Wat zit erin

- Werkt met job **mechanic / mecano / takel** en jouw eigen takelwagens
- Oogje (ox_target): vanuit de wagen een auto aankijken → takelen
- Dienst aan/uit
- SQL-inbeslagname (`mallorca_impound`)
- Spelersoproepen + optionele NPC-pechhulp
- Factuur (esx_billing-tabel of contant)
- Garage bij het depot
- Blips, markers, config in het Nederlands

## Config

Alles staat in `config.lua`: depot-coördinaten, prijzen, jobnaam, toegestane voertuigklassen en NPC-spots.

## Browserdemo

Open `html/index.html` of `html/auto-demo.html` in een browser om de tablet te zien zonder FiveM.
