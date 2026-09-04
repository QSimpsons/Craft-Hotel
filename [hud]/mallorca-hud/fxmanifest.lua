fx_version 'cerulean'
game 'gta5'
lua54 'yes'
legacyversion '1.15.0'

author 'Vex Shop (ESX 1.15.0 compatible)'
description 'Mallorca HUD for ESX Legacy 1.15.0'

ui_page 'html/index.html'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/index.js',
    'html/style.css',
    'html/img/*.png',
    'html/fonts/*.ttf',
    'html/img/**/*.png'
}

dependencies {
    'es_extended',
    'esx_status'
}
