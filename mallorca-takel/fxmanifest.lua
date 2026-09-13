fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mallorca Roleplay'
description 'Volledig custom takelscript — takelen, inbeslagname, oproepen, facturen'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/tow.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'es_extended'
}
