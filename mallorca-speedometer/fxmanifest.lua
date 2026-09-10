fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mallorca-speedometer'
author 'Mallorca'
description 'Volledige voertuig-HUD: snelheid (fluo oranje), tank, motor, schade, pinkers, noodknippers, handrem en lichten'
version '1.1.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/voorbeeld.html',
    'html/auto-demo.html'
}
