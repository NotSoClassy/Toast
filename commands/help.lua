local toast = require('../init')

local function embedGen(self)
    local aliases = table.concat(self._aliases, ', ')
    local perms = table.concat(self._userPerms, ', ')
    local other = self._nsfw and 'NSFW only'
    local sub = ''

    for _, cmd in pairs(self._subCommands) do
        sub = cmd.name .. ' - ' .. cmd.description .. '\n'
    end

    return toast.Embed()
       :setColor('random')
       :setTitle(self._name:gsub('^(.)', string.upper))
       :setDescription(self._description)
       :addField('Usage:', self._example, true)
       :addField('Aliases:', #aliases == 0 and 'None' or aliases, true)
       :addField('Permissions:', #perms == 0 and 'None' or perms, true)
       :addField('Sub Commands:', #sub == 0 and 'None' or sub, true)
       :addField('Other:', other and other or 'None', true)
       :setFooter(self._cooldown ~= 0 and 'This command has a ' .. math.floor(self._cooldown / 1000)  .. ' second cooldown' or 'This command has no cooldown')
 end

local function findCommand(cmds, q)
    if not cmds then return end
    for _, v in pairs(cmds) do
        if v.name == q or v == q or findCommand(v.aliases, q) then
            return v
        end
    end
end

return toast.Command('help', {
    description = 'This command!',
    example = 'help [name | alias]',
    execute = function(msg, args)
        local query = table.concat(args, ' ')

        if query and #query ~= 0 then
            local command = findCommand(msg.client.commands, query)

            if not command then return msg:reply('No command or alias found for `' .. query .. '`') end

            return embedGen(command):send(msg.channel)
        else
            local description = ''

            for _, cmd in pairs(msg.client.commands) do
                if cmd.hidden == false then
                    description = description .. cmd.name .. ' - ' .. cmd.description .. '\n'
                end
            end

            return toast.Embed()
                :setColor('random')
                :setTitle('Commands')
                :setDescription(description)
                :send(msg.channel)
        end
    end
})