fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'web/index.html'
ui_page_preload 'yes'

shared_script 'config.lua'
client_script 'client.lua'
server_scripts {
	-- '@oxmysql/lib/MySql.lua', -- oxmysql/mysql-async
	'server.lua'
}

files {
	'web/**/*',
}