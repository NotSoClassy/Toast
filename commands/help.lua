local toast = require('../init')

local function embedGen(self)
    local aliases = table.concat(self._aliases, '\n')
    local perms = table.concat(self._userPerms, '\n')
    return toast.Embed()
       :setColor('random')
       :setTitle(self._name:gsub('^(.)', string.upper))
       :setDescription(self._description)
       :addField('Usage:', self._example)
       :addField('Aliases:', #aliases == 0 and 'None' or aliases)
       :addField('Perms:', #perms == 0 and 'None' or perms)
       :setFooter('This command has a ' .. math.floor(self._cooldown / 1000)  .. ' second cooldown')
 end

local function search(tbl, q, where)
    if not tbl then return end
    for _, v in pairs(tbl) do
        if v[where] == q or search(v.aliases, v, 'aliases') then
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
            local command = search(msg.client.commands, query, 'name')

            if not command then return msg:reply('No command or alias found for `' .. query .. '`') end

            return msg:reply(embedGen(command))
        else
            local description = ''

            for _, cmd in pairs(msg.client.commands) do
                if cmd.hidden == false then
                    description = description .. cmd.name .. ' - ' .. cmd.description .. '\n'
                end
            end

            return msg:reply(toast.Embed()
                :setColor('random')
                :setTitle('Commands')
                :setDescription(description)
            )
        end
    end
})