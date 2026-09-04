fx_version 'cerulean'
game 'gta5'
lua54 'yes'
legacyversion '1.15.0'

author 'ESX-Framework / Vex Shop'
description 'Handles hunger, thirst and other player statuses for ESX 1.15.0'
version '1.1'

shared_script '@es_extended/imports.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    'config.lua',
    'client/classes/status.lua',
    'client/main.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/app.css',
    'html/scripts/app.js'
}

dependency 'es_extended'
