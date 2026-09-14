fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'jg-anwb'
description 'ANWB / mechanic job'
version '1.3.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'client/*.lua'
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
    'client/keys.lua',
    'client/clothing.lua',
    'client/client.lua'
}
