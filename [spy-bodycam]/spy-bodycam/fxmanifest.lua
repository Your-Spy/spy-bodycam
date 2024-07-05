fx_version 'cerulean'

game "gta5"

author "Spy-Script"
version '2.0.0'

lua54 'yes'

ui_page 'web/index.html'

shared_script {
  "config.lua",
  '@ox_lib/init.lua',

}

server_script {
  "server/**",
  '@oxmysql/lib/MySQL.lua',
}

client_script {
  'client/**',
}

files {
  'web/**',
  "node_modules/fivem-game-view/**/*",
}
