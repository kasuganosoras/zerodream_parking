fx_version  'cerulean'
games       { 'gta5' }
author      'Akkariin'
description 'ZeroDream Parking Script'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua',
}

client_scripts {
    'client/utils.lua',
    'client/api.lua',
    'client/main.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/utils.lua',
    'server/api.lua',
    'server/main.lua',
}
