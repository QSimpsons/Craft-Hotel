fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'jg-anwb'
description 'ANWB / mechanic job'
version '1.1.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'client/keys.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'es_extended',
    'ox_lib'
}

escrow_ignore = {
    'config/config.lua',
    'config/outfits.lua',
    'config/fines.lua',
    'client/keys.lua'
}
