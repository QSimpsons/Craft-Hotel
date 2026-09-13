#!/usr/bin/env python3
"""Lightweight checks for mallorca-els (no FiveM runtime)."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

required = [
    'fxmanifest.lua',
    'config.lua',
    'client/main.lua',
    'server/main.lua',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'README.md',
    'INSTALL.txt',
]
for rel in required:
    if not (ROOT / rel).exists():
        errors.append(f'missing {rel}')

cfg = (ROOT / 'config.lua').read_text(encoding='utf-8')
for name in ('fmltow', 'dlbrickade'):
    if name not in cfg:
        errors.append('config missing ' + name)
if re.search(r'\[`towtruck', cfg) or re.search(r'\[`flatbed', cfg):
    errors.append('vanilla tow vehicles should not be in ELS config')
if cfg.count('[`') != 2:
    errors.append('ELS config must whitelist exactly two vehicle models')
if "stage1 = '1'" not in cfg or "scene = 'R'" not in cfg:
    errors.append('config keys must be 1/2/3/0 and R')
if "siren = 'G'" in cfg:
    errors.append('siren key should be removed')

manifest = (ROOT / 'fxmanifest.lua').read_text(encoding='utf-8')
for needle in ("ui_page 'html/index.html'", 'client/main.lua', 'server/main.lua', 'config.lua'):
    if needle not in manifest:
        errors.append(f'manifest missing {needle}')

lua = (ROOT / 'client/main.lua').read_text(encoding='utf-8')
for needle in (
    'local function extraExists',
    'setStage',
    'toggleScene',
    'muteSiren',
    'DoesExtraExist',
    'mallorca_els_1',
    'mallorca_els_2',
    'mallorca_els_3',
    'mallorca_els_off',
    'mallorca_els_scene',
    'fmltow',
    'dlbrickade',
    'seatedDriver',
    'resetMine',
    'onClientResourceStart',
    'hideUi',
    'rearExtras',
    'flashGroups',
):
    if needle not in lua:
        errors.append('client missing ' + needle)
if 'IsThisModelATowTruck' in lua:
    errors.append('client must not call IsThisModelATowTruck')
if 'mallorca_els_siren' in lua or 'toggleSiren' in lua:
    errors.append('siren commands should be removed')
if 'SetVehicleSiren(veh, true)' in lua or 'SetVehicleSiren(veh, on' in lua:
    errors.append('client must not turn sirens on')
if 'SetVehicleLights(veh, flash and 2' in lua or 'SetVehicleLights(veh, 2)' in lua:
    errors.append('ELS must not flash or force headlights')
if 'HeadlightWigwag = true' in (ROOT / 'config.lua').read_text(encoding='utf-8'):
    errors.append('HeadlightWigwag must stay off')

server = (ROOT / 'server/main.lua').read_text(encoding='utf-8')
for needle in ('mallorca-els:update', 'mallorca-els:apply', 'fmltow', 'dlbrickade', 'scene'):
    if needle not in server:
        errors.append('server missing ' + needle)

html = (ROOT / 'html/index.html').read_text(encoding='utf-8')
for needle in ('PECHHULP', 'ACHTER', 'ZWAAI', 'WERK', 'Instappen', 'Uitstappen'):
    if needle not in html:
        errors.append(f'html missing {needle}')
if 'TOON' in html or 'siren' in html:
    errors.append('html still has siren/toon UI')

js = (ROOT / 'html/app.js').read_text(encoding='utf-8')
for needle in ('stageName', 'scene', 'GetParentResourceName', 'hidePanel', 'seated', 'sweep'):
    if needle not in js:
        errors.append(f'app.js missing {needle}')


def lua_balance(text, label):
    stripped = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.S)
    stripped = re.sub(r'--[^\n]*', '', stripped)
    stripped = re.sub(r"'[^']*'", "''", stripped)
    stripped = re.sub(r'"[^"]*"', '""', stripped)
    opens = len(re.findall(r'\b(function|then|do)\b', stripped))
    opens -= len(re.findall(r'\belseif\b', stripped))
    closes = len(re.findall(r'\bend\b', stripped))
    if opens != closes:
        errors.append(f'{label} function/then/do vs end imbalance ({opens} vs {closes})')
    if stripped.count('(') != stripped.count(')'):
        errors.append(f'{label} unmatched parentheses')


lua_balance(lua, 'client')
lua_balance(server, 'server')
lua_balance(cfg, 'config')

if errors:
    print('FAIL')
    for err in errors:
        print(' -', err)
    sys.exit(1)

print('OK mallorca-els')
