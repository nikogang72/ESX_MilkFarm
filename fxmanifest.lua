fx_version 'cerulean'
games {'gta5'}

description 'ESX Farm'

version '1.0.0'


client_script {
    'client/client.lua',
	'@es_extended/locale.lua',
	'locales/es.lua',
    'config.lua'
}

server_script {
    'server/server.lua',
	'@es_extended/locale.lua',
	'locales/es.lua',
    'config.lua'
}