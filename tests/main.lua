local config = require('./config')
local toast = require('../init')
local client = toast.Client{
    prefix = 'test '
}

client:addCommand{
    name = 'ping',
    execute = function(msg, args)
        msg:reply('Pong!')
    end
}

client:login(config.token)