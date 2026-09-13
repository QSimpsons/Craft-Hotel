# Mallorca FPS

FiveM performance panel in het **Mallorca Roleplay** thema, met SQL-opslag van je FPS-instellingen.

## Installatie

1. Download `mallorca-fps.zip` en pak uit in `resources`
2. Voer `mallorca-fps/sql/install.sql` eenmalig uit in HeidiSQL / phpMyAdmin
3. In `server.cfg`:

```cfg
ensure oxmysql
ensure mallorca-fps
```

Open in-game met `/fps` of `/fpspanel`.

Zie ook `mallorca-fps/INSTALL.txt`.

## SQL

Tabel `mallorca_fps_settings` bewaart per speler welke knoppen aan staan. Na een reconnect blijven LAAG, SCHADUWEN UIT, enzovoort actief.

- `oxmysql` of `mysql-async`
- Identifier: ESX (`Config.Identifier = 'esx'`) of FiveM license
- De resource maakt de tabel zelf aan bij start als de database-connector draait
