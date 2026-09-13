fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mallorca Roleplay'
description 'Mallorca FPS - Performance panel met SQL-opslag'
version '1.2.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png'
}
