local trim = require 'discordia' .extensions.string.trim
local match, gsub do
	local rex = require 'rex'
	match = rex.match
	gsub = rex.gsub
end

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
	return match(str, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) or true
end

local function getAfter(tbl, i, j)
	local ret = ''
	for k = i, j do
		ret = ret .. tbl[k]
	end
	return ret
end

local function parse(str)

	local flags = {}
	local last = -1

	for s, a, b, i in iter(str) do
		if s == '-' and a[1] == '-' and b[1] ~= '\\' then -- multi-letter
			a._str = string.sub(a._str, 2, #a._str) -- remove second -

			local key = getKey(a, ' ', #str)
			local after = getAfter(a, #key+1, #str)
			local value = getValue(after)

			flags[key] = value

			last = i
		elseif s == '-' and (i ~= last + 1) and b[1] ~= '\\' then -- single letter
			if a[2] ~= ' ' and a[2] ~= '' then goto continue end

			local key = a[1]
			local after = getAfter(a, 2, #str)
			local value = getValue(after)

			flags[key] = value
		end

		::continue::
	end

	local finish = trim(gsub(str, [[((?<!\\)\-(?<!\\)\-?\S+\s?)(?|"(.+?)"|'(.+?)'|(\S+))?(\s*)]], '')) -- this removed flags for the arg parser

	return flags, finish
end

return {
	parse = parse
}