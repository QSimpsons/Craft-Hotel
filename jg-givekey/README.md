# jg-givekey

Vervangt de ontbrekende export `giveCarKeys` van `jg-carkeys`.

JG jobs zoals `jg-anwb` doen dit bij het spawnen van een dienstvoertuig:

```lua
exports['jg-carkeys']:giveCarKeys(plate, props)
```

Als `jg-carkeys` die export niet heeft, crasht de client:

`No such export giveCarKeys in resource jg-carkeys`

## Installatie

1. Zet de map `jg-givekey` in `resources`
2. In `server.cfg`, **vóór** de jobs:

```cfg
ensure jg-givekey
ensure jg-anwb
```

3. In `jg-anwb/config/config.lua`:

```lua
Config.Carkeys = 'jg-givekey'
```

## Gebruik in andere scripts

Client:

```lua
exports['jg-givekey']:giveCarKeys(plate, props, vehicle)
```

Server:

```lua
exports['jg-givekey']:giveCarKeys(source, plate, props)
```

Aliases: `GiveCarKeys`, `GiveKeys`, `GiveKey`.

## Bestaande jg-carkeys houden

Heb je al `jg-carkeys` maar zonder deze export? Kopieer
`compat/jg-carkeys-export.lua` naar die resource en zet het in de `fxmanifest.lua`
bij `client_scripts`. Daarna werkt `exports['jg-carkeys']:giveCarKeys(...)` weer.

Heb je **geen** `jg-carkeys`? Dan kun je deze map hernoemen naar `jg-carkeys`
en `Config.Carkeys = 'jg-carkeys'` laten staan.

## Config

| Optie | Uitleg |
| --- | --- |
| `Config.KeySystem` | `auto` koppelt door naar qs/wasabi/qb als die draaien |
| `Config.BlockEngineWithoutKeys` | Alleen aanzetten als dit je enige keysysteem is |
| `Config.LockKey` | Standaard `U` om te vergrendelen/ontgrendelen |
