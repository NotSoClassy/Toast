local typeCheck = require 'typechecker' .parse

local function quotes(str)
	local c = str:sub(0, 1)

	if c == '"' or c == "'" then
		local pos = 0
		local stop
		str = str:sub(2)

		while true do
			local quote = str:find(c, pos, true)

			if not quote then
				return nil, 'Unfinished quote'
			end

			if str:sub(quote - 1, quote - 1) == '\\' then
				pos = quote + 1
			else
				stop = quote
				break
			end
		end

		return str:sub(1, stop - 1), stop + 1
	else
		local space = str:find(' ', 1, true)

		if not space then
			return str, #str
		end

		return str:sub(0, space - 1), space
	end
end

local function flag(str, short, flags)
	local _, e, key = str:find('([%a%-]*)')

	if not e then return end
	if key == '' then return end

	local nc = str:sub(e+1, e+1)
	local isFlag = str:sub(e+2, e+3) == '--'

	if nc == '=' or nc == ' ' and not isFlag then
		if short then
			local sum = e + 2
			local pos = sum
			for i = 1, #key do
				local n = str:find('%S', pos)
				local val = n and quotes(str:sub(n)) or 'true'
				pos = #val + (n or 0)
				sum = n + #val

				flags[key:sub(i, i)] = val
			end
			return sum
		else
			local val, pos = quotes(str:sub(e+2))
			return key, val, #key + pos + 1
		end
	elseif nc == ',' or nc == ';'  or nc == '' or isFlag then
		if short then
			for i = 1, #key do
				flags[key:sub(i, i)] = 'true'
			end
			return e + 1
		else
			return key:sub(0, e+1), 'true', e + 1
		end
	end
end

local function parse(str)
	local pos = 1
	local args, flags = {}, {}
	local parseFlags = true

	while true do
		local s = str:find('%S', pos)

		if not s then break end

		local _, e
		if parseFlags then _, e = str:find('^%-%-?', s) end

		if e then
			local short = e - s == 0
			local key, val, at = flag(str:sub(e + 1), short, flags)

			if short then
				pos = e + key + 1
			else
				if key then
					flags[key] = val
					pos = e + at + 1
				else
					parseFlags = false
				end
			end
		else
			local val, at = quotes(str:sub(s))
			if type(at) == 'string' then return nil, at end
			args[#args + 1] = val
			pos = s + at
		end
	end

	return args, flags
end

local function typedParse(str, msg, command)
	local args, flags = parse(str)

	if args == nil then
		return nil, flags
	end

	local parsed, err = typeCheck(args, msg, command, 'args')

	if parsed == nil then
		return nil, err
	end

	args = parsed

	parsed, err = typeCheck(flags, msg, command, 'flags')

	if parsed == nil then
		return nil, err
	end

	flags = parsed

	return args, flags
end

return typedParse