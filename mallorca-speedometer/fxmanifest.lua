fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mallorca'
description 'Voertuig speedometer met motor, schade, pinkers en handrem'
version '1.0.0'

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
    'html/app.js'
}
