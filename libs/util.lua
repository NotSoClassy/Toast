local argparse = require '../argparser'
local util = require '../userUtil'

local concat = table.concat

local validOptions = {
	prefix = {'string', 'table'},
	owners = {'string', 'table'},
	defaultHelp = 'boolean',
	advancedArgs = 'boolean',
	mentionPrefix = 'boolean',
	commandHandler = 'function'
}

local function parseOptions(options)
	local discordiaOptions = {}
	local toastOptions = {}

	for i, v in pairs(options) do
		if validOptions[i] then
			local optionType = validOptions[i]
			if type(optionType) == 'table' then

				for count, optType in ipairs(optionType) do
					if type(v) == optType then
						break
					elseif count == #optionType then
						error('The ' .. i .. ' option should be a (' .. concat(optionType, ' | ') .. ')')
					end
				end
			else
				assert(type(v) == optionType, 'The ' .. i .. ' option should be a (' .. optionType .. ')')
			end
			toastOptions[i] = v
		else
			discordiaOptions[i] = v
		end
	end

	return toastOptions, discordiaOptions
end

local function search(tbl, v)
	v = v:lower()
	for _, k in ipairs(tbl) do
		if k == v or k.name == v or search(k.aliases or {}, v) then
			return k
		end
	end
end

return {
	search = search,
	parseOptions = parseOptions,

	-- parsing
	argparse = argparse.parse,

	-- other utils
	time = util.formatLong,
	owner = util.isOwner,
	error = util.errorEmbed,
	prefix = util.getPrefix,
	example = util.example,
}