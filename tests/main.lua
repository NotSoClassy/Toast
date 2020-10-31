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

local embed = toast.Command('embed')

embed.execute = function(msg, args)
    local embed = toast.Embed()
        :setColor('random')
        :addField('NAME', 'VALUE', true)
        :setTitle('TITLE')
        :setDescription(string.rep('a', 2050))
    print(msg:reply(embed))
end
client:addCommand(embed)

client:login(config.token)