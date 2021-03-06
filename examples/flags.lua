local toast = require('toast')
local client = toast.Client()

local command = toast.Command('flags', {
	flags = { { name = 'test', value = 'string', required = true} }, -- The parser options
    execute = function(msg, args) -- example msg = !flags --test "fun times"
		if args.flags.test then 
			return msg:reply('We are having ' .. args.flags.test .. '!') --> "We are having fun times!"
		end
    end
})

client:addCommand(command)

client:login('token')