local config = require('./config')
local toast = require('../init')
local client = toast.Client {
    prefix = {'!', '?', 'space '}
}
local ping = toast.Command('ping')
ping.execute = function(msg, args)
    msg:reply('Pong!')
end
ping.aliases = {'pong', 'pping'}
client:addCommand(ping)

client:login(config.token)