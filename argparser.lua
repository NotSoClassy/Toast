local rex = require 'rex'

local concat, unpack = table.concat, table.unpack
local match, f = string.match, string.format

local function isSnowflake(id)
	return type(id) == 'string' and #id >= 17 and #id <= 64 and not match(id, '%D')
end

local types = {

	any = function(arg)
		return arg
	end,

	number = function(arg)
		return tonumber(arg)
	end,

	boolean = function(arg)
		arg = arg:lower()
		return (arg == 'true' and true) or (arg == 'false' and false) or nil
	end,

	string = function(arg)
		return not tonumber(arg) and arg or nil
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
	end
}

local function split(content)
	local args = {}
	for arg in rex.gmatch(content, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) do
		 args[#args + 1] = arg
	end
	return args
end

local function parse(msg, cmdArgs, command)
	if #cmdArgs < command._requiredArgs then
		return nil, 'Missing required arguments (see help command for more info)'
	end

	cmdArgs = split(concat(cmdArgs, ' '))

	local args = {ungrouped = {}}

	for i, arg in ipairs(cmdArgs) do
		local options = command.args[i] -- {name = string, value = type or nil, required = boolean}

		if not options then
			args.ungrouped[#args.ungrouped + 1] = arg
		else
			if options.name == 'ungrouped' then error('Name "ungrouped" is reserved') end
			if args[options.name] ~= nil then error(options.name .. ' name is already in use') end

			if options.value == '...' then
				args[options.name] = concat({ unpack(cmdArgs, i, #cmdArgs) }, ' ')
				break
			end

			local typeCheck = types[options.value] or error('No type found for ' .. options.value)
			local value = typeCheck(arg, msg)

			if value == nil then return nil, options.error or f('Argument #%d should be a %s', i, options.value) end

			local default = options.default
			args[options.name] = (value ~= nil and value) or type(default) == 'function' and default(msg) or default
		end
	end

	return args
end

return {
	split = split,
	parse = parse
}