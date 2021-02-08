local types = require 'argparser' .types

local f, sub, lower, gmatch = string.format, string.sub, string.lower, string.gmatch

local example, removeBackslash do
    local util = require '../userUtil'
    example = util.example
    removeBackslash = util.removeBackslash
end

local trim, clamp do
		local ext = require 'discordia' .extensions
		trim = ext.string.trim
		clamp = ext.math.clamp
end

local gsub, newPatt do
	local rex = require 'rex'
	newPatt = rex.new
	gsub = rex.gsub
end

local matchValue = newPatt [[(?|"(.*?[^\\])"|'(.*?[^\\])'|(\S+))]]
local removeFlags = newPatt [[((?<!\\)\-(?<!\\)\-?\S+\s?)(?|"(.*?[^\\])"|'(.*?[^\\])'|(\S+))?(\s*)]]

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
		flags[name] = nil

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

	for i, v in pairs(flags) do
		ret[i] = v
	end

    return ret
end

-----------------------------------

local function iter(str)
	local i = 0

	return function()
		i = i + 1
		local s = sub(str, i, i)
		if i <= #str then
			return s, i
		end
	end
end

local function getKey(str)
	local ret = ''
	for c in gmatch(str, '.') do
		if c == ' ' then break end
		ret = ret .. c
	end
	return ret
end

local function getValue(str)
	local v = matchValue:match(str)
	return v and removeBackslash(v) or 'true'
end

-----------------------------------

local function parse(msg, str, cmd)
	local flags = {}
	local last = -1

	local x

	local function a(n)
		n = x+n
		return sub(str, n, n)
	end

	local function b(n)
		n = x-n
		return sub(str, n, n)
	end

	for s, i in iter(str) do
		x = i
		if s == '-' and a(1) == '-' and b(1) ~= '\\' then -- multi-letter
			local after = sub(str, i+2)
			local key = lower(getKey(after))
			local value = getValue(sub(after, #key+2))

			flags[key] = value

			last = i
		elseif s == '-' and (i ~= last + 1) and b(1) ~= '\\' then -- single letter
			if a(2) ~= ' ' and a(2) ~= '' then goto continue end
			local key = lower(a(1))
			local after = sub(str, i+2, #str)
			local value = getValue(after)

			flags[key] = value
		end

		::continue::
	end

	local parsed, err = parseTypes(msg, flags, cmd)

	if err then
		return nil, err
	end

	local finish = trim(gsub(str, removeFlags, '')) -- this removes flags for the arg parser

	return parsed, finish
end

return {
	parse = parse
}