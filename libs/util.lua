local discordia = require 'discordia'
local Embed = require '../structures/Embed'

local concat = table.concat
local f = string.format

local validOptions = {
	sudo = 'boolean',
	prefix = {'string', 'table', 'function'},
	owners = {'string', 'table'},
	params = 'table',
	defaultHelp = 'boolean',
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
			elseif optType ~= 'any' then
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

local function error(content, title)
    title = title or 'An error has occured'
    return Embed():setTitle(title):setDescription(content):setTimestamp(discordia.Date():toISO()):setColor(16711731)
end

local function example(command)
    local example = command.name

	for _, arg in ipairs(command.args) do
		local name = arg.displayName or arg.name
		local v = arg.value or arg.type
		example = example .. ' ' .. (arg.required and f('<%s: %s>', name, v) or f('[%s: %s]', name, v))
	end


	for _, flg in ipairs(command.flags or {}) do
		local v = flg.value or flg.type
		local d = #flg.name == 1 and '-' or '--'
		example = example .. ' ' .. (flg.required and f('<%s%s: %s>', d, flg.name, v) or f('[%s%s: %s]', d, flg.name, v))
	end

    return example
end

local function plural(n, name)
    name = n == 1 and name or name .. 's'
    return n .. ' ' .. name
end

local d, h, m, s = 86400000, 3600000, 60000, 1000

local function format(milliseconds)
    local msAbs = math.abs(milliseconds)
    if msAbs >= d then
        return plural(milliseconds / d, 'day')
    end
    if msAbs >= h then
        return plural(milliseconds / h, 'hour')
    end
    if msAbs >= m then
        return plural(milliseconds / m, 'minute')
    end
    if msAbs >= s then
        return plural(milliseconds / s, 'second')
    end
    return tostring(milliseconds) .. ' ms'
end

local function prefix(msg)
    local prefix
    for _, pre in pairs(msg.client.prefix) do
        local p = type(pre) == 'function' and pre(msg) or tostring(pre)
        if string.find(msg.content, p, 1, true) == 1 then
            prefix = p
            break
        end
    end
    return prefix
end

local function compareRoles(role1, role2)
    if role1.position == role2.position then
        return role2.id - role1.id
    end
    return role1.position - role2.position
end

local function manageable(member)
    if member.user.id == member.guild.ownerId then
        return false
    end
    if member.user.id == member.client.user.id then
        return false
    end
    if member.client.user.id == member.guild.ownerId then
        return true
    end
    return compareRoles(member.guild.me.highestRole, member.highestRole) > 0
end

local function isOwner(msg)
    local id = msg.author.id
    for _, v in ipairs(msg.client.owners) do
        if id == v then
            return true
        end
    end
    return false
end

return {
	error = error,
	format = format,
	prefix = prefix,
	search = search,
	isOwner = isOwner,
	example = example,
	manageable = manageable,
	parseOptions = parseOptions
}