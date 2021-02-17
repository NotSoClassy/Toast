-- just a warning you shouldn't try to read this
local clamp = require 'discordia' .extensions.math.clamp
local example = require '../userUtil' .example
local types = require 'argparser' .types
local sub, f = string.sub, string.format

local gsub, newPatt do
	local rex = require 'rex'
	newPatt = rex.new
	gsub = rex.gsub
end

local removeFlags = newPatt [[((?<!\\)\-(?<!\\)\-?\S+\s?)(?|"(.*?[^\\])"|'(.*?[^\\])'|(\S+))?(\s*)]]

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

--------------------------------------

local function eatUntil(str, d)
	local ret = ''

	for i = 1, #str do
		local s = sub(str, i, i)
		local b = sub(str, i-1, i-1)

		if s == d and (b ~= '\\' or s == ' ') then break end

		s = s == '\\' and b ~= '\\' and '' or s -- remove \ unless there's two

		ret = ret .. s
	end

	return ret
end

local function getQuotedValue(str)
	local s = sub(str, 1, 1)
	local a = sub(str, 2, 2)

	local isQuote = s == "'" and "'" or s == '"' and '"'

	if isQuote then
		return eatUntil(sub(str, 2), isQuote)
	else
		local value -- if no value is provided it defaults to 'true'
		if s == '' or (s == '-' or (a == '-' and s ~= '\\')) then
			value = 'true'
		else
			value = eatUntil(str, ' ')
		end
		return value
	end
end

--------------------------------------

local function parse(str, msg, cmd)
	local flags = {}

	for i = 1, #str do

		local b = sub(str, i-1, i-1)
		local s = sub(str, i, i)
		local a = sub(str, i+1, i+1)
		local a2 = sub(str, i+2, i+2)

		if b ~= '\\' and s == '-' and a == '-' then
			local key = eatUntil(sub(str, i+2), ' ')
			local value = getQuotedValue(sub(str, i+3+#key))

			flags[key] = value
		elseif b ~= '\\' and s == '-' and (a2 == ' ' or a2 == '') then
			local key = a
			local value = getQuotedValue(sub(str, i+3))

			flags[key] = value
		end
	end

	local parsed, err = parseTypes(msg, flags, cmd)

	if err then
		return nil, err
	end

	local noFlags = gsub(str, removeFlags, '') -- because gsub returns 3 values

	return parsed, noFlags
end

return {
	parse = parse,
	getQuotedValue = getQuotedValue
}