fx_version 'cerulean'
game 'gta5'
lua54 'yes'
legacyversion '1.15.0'

author 'ESX-Framework / Vex Shop'
description 'Hunger and thirst for ESX Legacy 1.15.0'
version '1.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@esx_lib/imports.lua'
}

server_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'config.lua',
    'client/main.lua'
}

dependencies {
    'es_extended',
    'esx_lib',
    'esx_status'
}
