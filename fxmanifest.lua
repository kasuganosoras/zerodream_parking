fx_version  'cerulean'
games       { 'gta5' }

name        'zerodream_parking'
author      'Akkariin'
description 'ZeroDream Parking Script'
version     '1.0.1'
url         'https://www.zerodream.net/'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    '@es_extended/imports.lua',
}

client_scripts {
    'client/utils.lua',
    'client/api.lua',
    'client/main.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/api.lua',
    'server/main.lua',
}
