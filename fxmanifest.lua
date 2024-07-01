fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
games {"rdr3"}

shared_scripts {
    'config.lua',
    'shared/*.lua',
}

client_scripts {
    'client/natives.lua',
    'client/cl_main.lua',
}

server_scripts {
    'server/*.lua'
}
