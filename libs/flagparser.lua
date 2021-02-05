local example = require '../userUtil' .example
local types = require 'argparser' .types

local f = string.format

local trim, clamp do
		local ext = require 'discordia' .extensions
		trim = ext.string.trim
		clamp = ext.math.clamp
end

local match, gsub do
	local rex = require 'rex'
	match = rex.match
	gsub = rex.gsub
end

-----------------------------------

local function make(str, i, j, rev)
	str = string.sub(str, i, j)
	str = rev and string.reverse(str) or str

	return setmetatable({ _str = str}, { __index = function(tbl, k)
		return string.sub(tbl._str, k, k)
	end })
end

local function iter(str)
	local i = 0
	return function()
		i = i + 1
		local s = string.sub(str, i, i)
		if i <= #str then
			return s, make(str, i+1, #str), make(str, 0, i-1, true), i
		end
	end
end

local function getKey(tbl, c, j)
	local ret = ''
	for k = 1, j do
		if tbl[k] == c then
			break
		end
		ret = ret .. tbl[k]
	end
	return ret
end

local function getValue(str)
	return match(str, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) or 'true'
end

local function getAfter(tbl, i, j)
	local ret = ''
	for k = i, j do
		ret = ret .. tbl[k]
	end
	return ret
end

-----------------------------------

local function parseTypes(msg, flags, command)
	for _, opt in ipairs(command.flags) do
		if opt.required and not flags[opt.name] then
			return nil, example(command)
		end
	end

    local ret = {}

    -- parse
    for _, opt in ipairs(command.flags) do
        local name = opt.name
        local min, max = opt.min, opt.max
        local default = opt.default

		local flg = flags[name]

        if flg then
            local type = opt.value or opt.type

            assert(flags[flg] == nil, name .. ' name is already in use')

            local typeCheck = assert(types[type], 'No type found for ' .. type)
            local value = typeCheck(flg, msg)

            if value == nil then
                return nil, opt.error or f('Flag "%s" should be a %s', name, type)
            end

            if value and type == 'number' and max then
                if clamp(value, min or 1, max) ~= value then
                    return nil, f('Flag "%s" should be a number inbetween %d-%d', name, min, max)
                end
            end

            ret[name] = value
        elseif default then
            ret[name] = type(default) == 'function' and default(msg) or default
        end
    end

    -- check depends
    for _, opt in ipairs(command.flags) do
        local depends = opt.depend or opt.depends
        if depends and ret[opt.name] and not ret[depends] then
            return nil, f('Flag "%s" depends on the flag named "%s"', opt.name, depends)
        end
    end

    return ret
end

local function parse(msg, str, cmd)
	local flags = {}
	local last = -1

	for s, a, b, i in iter(str) do
		if s == '-' and a[1] == '-' and b[1] ~= '\\' then -- multi-letter
			a._str = string.sub(a._str, 2, #a._str) -- remove second -

			local key = getKey(a, ' ', #str)
			local after = getAfter(a, #key+1, #str)
			local value = getValue(after)

			flags[string.lower(key)] = value

			last = i
		elseif s == '-' and (i ~= last + 1) and b[1] ~= '\\' then -- single letter
			if a[2] ~= ' ' and a[2] ~= '' then goto continue end

			local key = a[1]
			local after = getAfter(a, 2, #str)
			local value = getValue(after)

			flags[string.lower(key)] = value
		end

		::continue::
	end

	local parsed, err = parseTypes(msg, flags, cmd)

	if err then
		return nil, err
	end

	local finish = trim(gsub(str, [[((?<!\\)\-(?<!\\)\-?\S+\s?)(?|"(.+?)"|'(.+?)'|(\S+))?(\s*)]], '')) -- this removed flags for the arg parser

	return parsed, finish
end

return {
	parse = parse
}