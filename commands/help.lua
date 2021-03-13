local toast = require '../init'
local util = require 'util'

local function embedGen(self, usage, pre)
	local aliases = table.concat(self.aliases, ', ')
	local perms = table.concat(self.userPerms, ', ')
	local other = self.nsfw and 'NSFW only'
	local sub = ''

	for _, cmd in ipairs(self.subCommands) do
		sub = sub .. cmd.name .. ' - ' .. cmd.description .. '\n'
	end

	if self._example == '' and #self._args > 0 then
		usage = pre .. util.example(self)
	end

	return toast.Embed()
	   :setColor('GREEN')
	   :setTitle(self.name:gsub('^(.)', string.upper))
	   :setDescription(self.description)
	   :addField('Usage:', usage .. ' ' .. self.example, true)
	   :addField('Aliases:', #aliases == 0 and 'None' or aliases, true)
	   :addField('Permissions:', #perms == 0 and 'None' or perms, true)
	   :addField('Sub Commands:', #sub == 0 and 'None' or sub, true)
	   :addField('Other:', other and other or 'None', true)
	   :setFooter(self.cooldown ~= 0 and 'This command has a ' .. math.floor(self.cooldown / 1000)  .. ' second cooldown' or 'This command has no cooldown')
end

return toast.Command('help', {
	description = 'This command!',
	example = '[name | alias]',
	execute = function(msg, args)
		local cmd = table.remove(args, 1)

		if cmd and #cmd ~= 0 then
			local command = util.search(msg.client.commands, cmd)

			if not command then
				return msg:reply('No command or alias found for `' .. cmd .. '`')
			end

			local prefix = util.prefix(msg)
			local usage = prefix .. command.name

			for _, sub in ipairs(args) do
				local temp = util.search(command.subCommands, sub)
				if not temp then
					break
				end
				usage = usage .. ' ' .. temp.name
				command = temp or command
			end

			return embedGen(command, usage, prefix):send(msg.channel)
		else
			local description = ''

			for _, command in ipairs(msg.client.commands) do
				if command.hidden == false then
					description = description .. command.name .. ' - ' .. command.description .. '\n'
				end
			end

			return toast.Embed()
				:setColor('GREEN')
				:setTitle('Commands')
				:setDescription(description)
				:setFooter('You can do `help [command]` for alias, usage, permission and sub command info')
				:send(msg.channel)
		end
	end
})
