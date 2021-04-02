local clamp = require 'discordia' .extensions.math.clamp
local remove, unpack = table.remove, table.unpack
local match, f = string.match, string.format

local example = require 'util' .example

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

local errors = { -- argument errors
    missing_value = 'Argument #%d should be a %s',
    out_of_range = 'Argument #%d should be a number inbetween %d-%d',
    missing_depends = 'Argument #%d depends on the argument named "%s"'
}

local ferrors = { -- flag errors
    missing_value = 'Flag "%s" should be a %s',
    out_of_range = 'Flag "%s" should be a number inbetween %d-%d',
    missing_depends = 'Flag "%s" depends on the argument named "%s"'
}

local function parse(input, msg, command, what)
    what = what or 'args'
    local msgs = (what == 'args' and errors) or (what == 'flags' and ferrors)

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
    command = command[what]

    -- parse

    for i, opt in ipairs(command) do
        local arg = input[what == 'args' and 1 or opt.name]

        local name = opt.name
        local ename = what == 'flags' and name or i
        local min, max = opt.min, opt.max
        local default = opt.default

        if arg then
            local type = opt.value or opt.type

            if name == 'ungrouped' or name == 'flags' then error('Name "' .. name .. '" is reserved') end
            if vals[name] ~= nil then error(name .. ' name is already in use') end

            if type == '...' then
                vals[name] = {arg, unpack(input, 1, #input)}
                input = {}
                break
            end

            if what == 'args' then remove(input, 1) else input[name] = nil end

            local check = assert(types[type], 'No type found for ' .. type)
            local value = check(arg, msg)

            if value == nil then
                return nil, opt.error or f(msgs.missing_value, ename, type)
            end

            if value and type == 'number' and max then
                if clamp(value, min or 1, max) ~= value then
                    return nil, f(msgs.out_of_range, ename, min, max)
                end
            end

            vals[name] = value
        elseif default then
            vals[name] = type(default) == 'function' and default(msg) or default
        end
    end

    -- check depends
    for i, opt in ipairs(command) do
        local depends = opt.depend or opt.depends
        if depends and vals[opt.name] and not vals[depends] then
            return nil, f(msgs.missing_depends, what == 'flags' and opt.name or i, depends)
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

return {
    parse = parse,
    types = types
}