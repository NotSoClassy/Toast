local toast = require('toast')
local client = toast.Client()

local command = toast.Command('flags', {
	args = { { name = 'test', value = 'string', required = true} }, -- The parser options
    execute = function(msg, args) -- example msg = !flags "fun times"
		if args.test then
			return msg:reply('We are having ' .. args.flags.test .. '!') --> "We are having fun times!"
		end
    end
})

client:addCommand(command)

client:login('token')