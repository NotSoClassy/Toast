-- type stuff
local clamp = require 'discordia' .extensions.math.clamp
local remove, concat, unpack = table.remove, table.concat, table.unpack
local match, f = string.match, string.format

local example do
    local util = require '../userUtil'
    example = util.example
end

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
        if not isSnowflake(id) then
            return
        end
        return msg:getUser(id)
    end,

    member = function(arg, msg)
        if not msg.guild then
            return
        end
        local id = match(arg, '<@!(%d+)>') or match(arg, '%d+')
        if not isSnowflake(id) then
            return
        end
        return msg.guild:getMember(id)
    end,

    role = function(arg, msg)
        if not msg.guild then
            return
        end
        local id = match(arg, '<@&(%d+)>') or match(arg, '%d+')
        if not isSnowflake(id) then
            return
        end
        return msg.guild:getRole(id)
    end
}

local errors = {
    missing_value = 'Argument #%d should be a %s',
    out_of_range = 'Argument #%d should be a number inbetween %d-%d',
    missing_depends = 'Argument #%d depends on the argument named "%s"'
}

local ferrors = {
    missing_value = 'Flag %s should be a %s',
    out_of_range = 'Flag %s should be a number inbetween %d-%d',
    missing_depends = 'Flag %s depends on the argument named "%s"'
}

local function check_types(msg, input, command, what)
    what = what or 'args'
    local msgs = what == 'args' and errors or what == 'flags' and ferrors

	if what == 'flags' then
		for _, opt in ipairs(command.flags) do
			if opt.required and not input[opt.name] then
				return nil, example(command)
			end
		end
	elseif what == 'args' then
		if #input < command._requiredArgs then
			return nil, example(command)
		end
	end

    local vals = {}

    -- parse

    for i, opt in ipairs(command[what]) do
        local arg = input[what == 'args' and 1 or opt.name]

        local name = opt.name
        local min, max = opt.min, opt.max
        local default = opt.default

        if arg then
            local type = opt.value or opt.type

            assert(name ~= 'ungrouped' or name ~= 'flags', 'Name "' .. name .. '" is reserved')
            assert(vals[name] == nil, name .. ' name is already in use')

            if type == '...' then
                vals[name] = {arg, unpack(input, i+1, #input)}
                input = {}
                break
            end

            if what == 'args' then remove(input, i) else input[opt.name] = nil end

            local check = assert(types[type], 'No type found for ' .. type)
            local value = check(arg, msg)

            if value == nil then
                return nil, opt.error or f(msgs.missing_value, i, type)
            end

            if value and type == 'number' and max then
                if clamp(value, min or 1, max) ~= value then
                    return nil, f(errors.out_of_range, i, min, max)
                end
            end

            vals[name] = value
        elseif default then
            vals[name] = type(default) == 'function' and default(msg) or default
        end
    end

    -- check depends
    for i, opt in ipairs(command[what]) do
        local depends = opt.depend or opt.depends
        if depends and vals[opt.name] and not vals[depends] then
            return nil, f(msgs.missing_depends, i, depends)
        end
    end

    if what == 'flags' then
        for i, v in pairs(input) do
            vals[i] = v
        end
    elseif what == 'args' then
		vals.ungrouped = input
	end

    return vals
end

-- parser stuff

local lpeg = require 'lpeg'

local P, C, S, R, Cp = lpeg.P, lpeg.C, lpeg.S, lpeg.R, lpeg.Cp
local lmatch = lpeg.match
local sub, find = string.sub, string.find

local char = R('az', 'AZ', '09')
local escape = P '\\'
local apoArg = P"'" * C((1 - P"'")^0) * P"'"
local quoArg = P'"' * C((1 - P'"')^0) * P'"'

local key do
	local dash = P '-' - escape
	key = (dash * dash^-1) * C(char^1)
end

local value = (quoArg + apoArg + C((1 - (S'=, ' + '-'))^1))
local quote = P' '^0 * (quoArg + apoArg + C((1 - (S' ' + '-'))^1)) * Cp()

local function parse(str, msg, command)
	local flags = {}
	local out = ''
	local last = 0
	-- flags
	while true do
		local s, e, escaped = find(str, '(\\?)%-%-?', last)
		if not s then break end

		if escaped ~= '\\' then
			local index = lmatch(key, sub(str, s))
			local val = lmatch(value, sub(str, e+#index+2)) or 'true'
			local isQuote = sub(str, e+#index+2, e+#index+2)

			out = out .. sub(str, last, s-1)
			last = #index + #val + (e-s) + e + ((isQuote == '"' or isQuote == "'") and 2 or 0) + 2
			flags[index] = val
		end
	end

	out = out .. sub(str, last)
	last = 0
	local args = {}
	-- args
	while true do
		local v, pos = lmatch(quote, sub(out, last))
		local isQuote = sub(out, last+1, last+1)

		if not v or #v == 0 then break end

		last = last + #v + 1 + ((isQuote == '"' or isQuote == "'") and 2 or 0)
		last = pos == last and last + 1 or last

		args[#args+1] = v
	end

	local pflags, ferr = check_types(msg, flags, command, 'flags')
	local pargs, err = check_types(msg, args, command, 'args')

	if ferr then
		return nil, nil, ferr
	elseif err then
		return nil, nil, err
	end

	return pflags, pargs
end

return {
	parse = parse,
	types = types
}