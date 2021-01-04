local rex = require 'rex'

local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack
local match, f = string.match, string.format

local function isSnowflake(id)
	return type(id) == 'string' and #id >= 17 and #id <= 64 and not match(id, '%D')
end

local types = {

	string = function(arg)
		return arg
	end,

	number = function(arg)
		return tonumber(arg)
	end,

	boolean = function(arg)
		arg = arg:lower()
		if arg == 'true' then
			return true
		elseif arg == 'false' then
			return false
		end
	end,

	user = function(arg, msg)
		local id = match(arg, '<@!(%d+)>') or match(arg, '%d+')
		if not isSnowflake(id) then return end
		return msg:getUser(id)
	end,

	member = function(arg, msg)
		if not msg.guild then return end
		local id = match(arg, '<@!(%d+)>') or match(arg, '%d+')
		if not isSnowflake(id) then return end
		return msg.guild:getMember(id)
	end,

	role = function(arg, msg)
		if not msg.guild then return end
		local id = match(arg, '<@&(%d+)>') or match(arg, '%d+')
		if not isSnowflake(id) then return end
		return msg.guild:getRole(id)
	end
}

local function split(content)
	local args = {}
	for arg in rex.gmatch(content, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) do
		 insert(args, arg)
	end
	return args
end

local function parse(msg, cmdArgs, command)
	if #cmdArgs < command._requiredArgs then
		local example = command.name

		for _, arg in ipairs(command.args) do
			example = example ..  ' ' .. (arg.required and f('<%s: %s>', arg.name, arg.value) or f('[%s: %s]', arg.name, arg.value))
		end

		return nil, f('Missing required arguments\n`%s`', example)
	end

	cmdArgs = split(concat(cmdArgs, ' '))

	local args = {}

	for i, options in ipairs(command.args) do
		local arg = cmdArgs[1]

		local name = options.name
		local min, max = options.min, options.max
		local default = options.default

		if arg then
			remove(cmdArgs, i)

			local type = options.value or options.type

			if name == 'ungrouped' then error('Name "ungrouped" is reserved') end
			if args[name] ~= nil then error(name .. ' name is already in use') end

			if type == '...' then
				args[name] = concat({unpack(cmdArgs, i, #cmdArgs)}, ' ')
				cmdArgs = {}
				break
			end

			local typeCheck = types[type] or error('No type found for ' .. type)
			local value = typeCheck(arg, msg)

			if value == nil then return nil, options.error or f('Argument #%d should be a %s', i, type) end

			if value and type == 'number' and max then
				if value > max or value < (min or 1) then
					return nil, f('Argument #%d should be a number inbetween %d-%d', i, min, max)
				end
			end

			args[name] = value
		elseif default then
			args[name] = type(default) == 'function' and default(msg) or default
		end
	end

	args.ungrouped = cmdArgs
	return args
end

return {
	split = split,
	parse = parse
}