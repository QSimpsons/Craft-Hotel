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
if "stage = 'Q'" not in cfg or "siren = 'G'" not in cfg:
    errors.append('config keys must be Q (lights) and G (siren)')

manifest = (ROOT / 'fxmanifest.lua').read_text(encoding='utf-8')
for needle in ("ui_page 'html/index.html'", 'client/main.lua', 'server/main.lua', 'config.lua'):
    if needle not in manifest:
        errors.append(f'manifest missing {needle}')

lua = (ROOT / 'client/main.lua').read_text(encoding='utf-8')
for needle in (
    'local function extraExists',
    'cycleStage',
    'toggleSiren',
    'SetVehicleSiren',
    'DoesExtraExist',
    'mallorca_els_stage',
    'mallorca_els_siren',
    'fmltow',
    'dlbrickade',
):
    if needle not in lua:
        errors.append('client missing ' + needle)
if 'IsThisModelATowTruck' in lua:
    errors.append('client must not call IsThisModelATowTruck')
if lua.find('local function extraExists') > lua.find('local function extraIsOn'):
    errors.append('extraExists must be defined before extraIsOn')

server = (ROOT / 'server/main.lua').read_text(encoding='utf-8')
for needle in ('mallorca-els:update', 'mallorca-els:apply', 'fmltow', 'dlbrickade'):
    if needle not in server:
        errors.append('server missing ' + needle)

html = (ROOT / 'html/index.html').read_text(encoding='utf-8')
for needle in ('Wegenwacht ELS', 'data-stage', 'siren', 'fmltow'):
    if needle not in html:
        errors.append(f'html missing {needle}')

js = (ROOT / 'html/app.js').read_text(encoding='utf-8')
for needle in ('stageName', 'siren', 'GetParentResourceName'):
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
