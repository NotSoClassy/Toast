local config = require('./config')
local toast = require('../init')
local client = toast.Client {
    prefix = {'!', '?', 'space '}
}
local ping = toast.Command('ping')

ping.execute = function(msg)
    msg:reply('Pong!')
end
ping.aliases = {'pong', 'pping'}

client:addCommand(ping)

local embed = toast.Command('embed')

embed.execute = function(msg)
    local msgEmbed = toast.Embed()
        :setColor('random')
        :addField('NAME', 'VALUE', true)
        :setTitle('TITLE')
        :setDescription(string.rep('a', 2050))
    msgEmbed:send(msg.channel)
end
client:addCommand(embed)

client:login(config.token)