fx_version 'cerulean'
game 'gta5'

author 'Adaptado para ESX-Legacy'
description 'Sistema de Suspensão a AR - ESX-Legacy'
version '2.0.0'

-- Dependência obrigatória do ESX-Legacy
dependency 'es_extended'

-- Scripts compartilhados (executam em client e server)
shared_scripts {
    'config.lua'
}

-- Scripts do cliente
client_scripts {
    'client/vehicle.lua',
    'client/ui.lua',
    'client.lua'
}

-- Scripts do servidor
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Suporte ao oxmysql
    'server/database.lua',
    'server/callbacks.lua',
    'server.lua'
}

-- Interface NUI (React)
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*.js',
    'ui/assets/*.css',
    'ui/*.svg',
    'ui/*.png',
    'ui/sounds/*.ogg'
}

-- Configurações Lua 5.4
lua54 'yes'

-- Configurações ESX
escrow_ignore {
    'config.lua',
    'client/**/*.lua',
    'server/**/*.lua'
}