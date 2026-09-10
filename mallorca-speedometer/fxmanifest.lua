fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mallorca-speedometer'
author 'Mallorca'
description 'Volledige voertuig-HUD met SQL brandstof (tank, snelheid fluo oranje, motor, schade, pinkers, handrem)'
version '1.2.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/voorbeeld.html',
    'html/auto-demo.html'
}
