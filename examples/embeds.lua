local toast = require('toast')
local client = toast.Client()

local command = toast.Command('embed', {
    execute = function(msg)
        local embed = toast.Embed()
            :setTitle('title')
            :setDescription('description')
            :addField('name', 'value', true)
            :setColor('Random')
        return embed:send(msg.channel)
    end
})

client:addCommand(command)

client:login('token')
