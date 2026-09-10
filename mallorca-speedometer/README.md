# Mallorca Speedometer (compleet + SQL)

Complete FiveM-resource met **SQL brandstof-opslag**.

## Installatie

### 1. Resource
Pak `mallorca-speedometer.zip` uit in je `resources` map, of kopieer de map `mallorca-speedometer`.

### 2. SQL (eenmalig)
Voer uit in je database (HeidiSQL / phpMyAdmin):

`sql/install.sql`

```sql
ALTER TABLE `owned_vehicles`
    ADD COLUMN `fuel` FLOAT NOT NULL DEFAULT 100.0;
```

### 3. server.cfg
Zorg dat je database-connector draait (`oxmysql` of `mysql-async`), daarna:

```cfg
ensure oxmysql
ensure mallorca-speedometer
```

## Bestanden

```
mallorca-speedometer/
├── fxmanifest.lua
├── config.lua
├── README.md
├── sql/
│   └── install.sql          ← database
├── client/
│   └── main.lua
├── server/
│   └── main.lua             ← laden/opslaan fuel
└── html/
    ├── index.html
    ├── style.css
    ├── app.js
    ├── voorbeeld.html
    └── auto-demo.html
```

## Functies

| Onderdeel | Werking |
|-----------|---------|
| Snelheid | km/h in **fluo oranje** |
| Tank | Ring + % · groen/geel/rood · **opgeslagen in SQL** |
| Motor | Groen / geel / rood |
| Schade | Dim / geel / rood |
| Pinkers + noodknippers | Werken met pijltjestoetsen |
| Handrem | Rood als aan |
| Lichten | Groen als aan |

## Config brandstof

In `config.lua`:

```lua
Config.Fuel.UseDatabase = true   -- SQL aan/uit
Config.Fuel.Consume = true       -- tank leegrijden
Config.Fuel.Resource = ''        -- of 'LegacyFuel' / 'ox_fuel' (heeft voorrang)
```

## Toetsen

- Pijl links / rechts — pinkers  
- Pijl omlaag — noodknippers  
