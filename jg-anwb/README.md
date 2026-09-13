# jg-anwb

ANWB / mechanic job. Garage-spawn crasht niet meer op een ontbrekende `giveCarKeys` export.

## Fix

Oud (crash):

```lua
exports['jg-carkeys']:giveCarKeys(plate, props)
```

Nieuw: `client/keys.lua` geeft sleutels via `jg-givekey` (of een andere gestarte key-resource) en vangt ontbrekende exports af met `pcall`.

## Vereisten

- `es_extended`
- `ox_lib`
- `oxmysql`
- `qtarget`
- `jg-givekey` (meegeleverd) **of** een keysysteem met `giveCarKeys` / `GiveKeys`

In `server.cfg`:

```cfg
ensure jg-givekey
ensure jg-anwb
```

Zet in `config/config.lua` de resource-namen gelijk aan jouw server (`Config.Notify`, `Config.Jobsmenu`, enz.).

`Config.Carkeys = 'jg-givekey'` is de standaard na deze fix.
