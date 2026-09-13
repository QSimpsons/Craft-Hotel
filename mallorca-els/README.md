# Mallorca ELS — pechhulp

Volledig ELS **alleen** voor **fmltow** en **dlbrickade**. Andere voertuigen doen niets.

## Installatie

1. Unzip `mallorca-els` in `resources` (los van je voertuig-pack).
2. Zet in `server.cfg` **na** de voertuig-resources:

```cfg
ensure fmltow
ensure dlbrickade
ensure mallorca-els
```

3. `ensure mallorca-els` of herstart de server.

Geen SQL, geen job-check. ELS **gaat alleen aan als je instapt** als bestuurder van `fmltow` of `dlbrickade` (cruise-lichten + paneel). Te voet of in een andere auto gebeurt er niets. Stap je uit, dan gaat alles uit.

## Bediening

| Toets | Actie |
|--------|--------|
| **Q** | Zwaailichten: uit → cruise → waarschuwing → vol |
| **G** | Sirene (pas vanaf waarschuwing / vol) |
| Claxon | Korte sirene zolang je indrukt (als G uit staat) |
| `/els` | Korte uitleg in chat |

Toetsen aanpassen: FiveM → Settings → Key Bindings → FiveM → Pechhulp ELS.

## Stages

1. **Cruise** — lampen (extras) vast aan  
2. **Waarschuwing** — A/B knipperen + noodknippers  
3. **Vol** — snel knipperen + koplampen + sirene mogelijk  

Heeft de wagen geen extras, dan vallen noodknippers en koplampen in. Extra’s 1–14 worden automatisch herkend.

## Bestanden

- `config.lua` — alleen `fmltow` en `dlbrickade`
- `client/main.lua` — toetsen, extras, HUD
- `server/main.lua` — sync naar andere spelers
- `html/` — Wegenwacht-paneel linksonder

## Browserdemo

Open `html/index.html` in een browser om het paneel te zien zonder FiveM.
