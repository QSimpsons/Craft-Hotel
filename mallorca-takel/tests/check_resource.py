#!/usr/bin/env python3
"""Lightweight checks for mallorca-takel (no FiveM runtime)."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

required = [
    'fxmanifest.lua',
    'config.lua',
    'client/main.lua',
    'client/tow.lua',
    'server/main.lua',
    'sql/install.sql',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'README.md',
    'INSTALL.txt',
]
for rel in required:
    if not (ROOT / rel).exists():
        errors.append(f'missing {rel}')

sql = (ROOT / 'sql/install.sql').read_text(encoding='utf-8')
for needle in ('jobs', 'job_grades', 'mallorca_impound', 'mallorca_takel_calls', 'takel'):
    if needle not in sql:
        errors.append(f'sql missing {needle}')

manifest = (ROOT / 'fxmanifest.lua').read_text(encoding='utf-8')
for needle in ("ui_page 'html/index.html'", 'client/tow.lua', 'server/main.lua', 'config.lua'):
    if needle not in manifest:
        errors.append(f'manifest missing {needle}')

html = (ROOT / 'html/index.html').read_text(encoding='utf-8')
for needle in ('btn-attach', 'btn-impound', 'page-calls', 'page-garage', 'Mallorca Takel'):
    if needle not in html:
        errors.append(f'html missing {needle}')

lua_files = list((ROOT / 'client').glob('*.lua')) + list((ROOT / 'server').glob('*.lua')) + [ROOT / 'config.lua']
for path in lua_files:
    text = path.read_text(encoding='utf-8')
    if text.count('function') == 0 and path.name != 'config.lua':
        errors.append(f'{path.name} has no functions')
    # unmatched then/end is hard; catch leftover debug
    if 'TODO' in text or 'FIXME' in text:
        errors.append(f'{path.name} still has TODO/FIXME')

js = (ROOT / 'html/app.js').read_text(encoding='utf-8')
for needle in ('toggleDuty', 'attach', 'impound', 'acceptCall', 'spawnTruck'):
    if needle not in js:
        errors.append(f'app.js missing {needle}')

if errors:
    print('FAIL')
    for err in errors:
        print(' -', err)
    sys.exit(1)

print('OK mallorca-takel files complete')
