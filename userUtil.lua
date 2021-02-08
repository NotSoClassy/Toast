local discordia = require 'discordia'
local Embed = require './structures/Embed'

local enums = discordia.enums.permission
local extensions = discordia.extensions

local f = string.format

local util = {}
local roles = {
    administrator = {'administrator'},
    moderator = {'kickMembers', 'banMembers', 'manageMessages', 'manageNicknames', 'mentionEveryone'},
    ['bot manager'] = {'manageGuild', 'manageRoles'}
}

local s = 1000
local m = s * 60
local h = m * 60
local d = h * 24
local w = d * 7
local y = d * 365.25

function util.years(years)
    return years * y
end

function util.weeks(weeks)
    return weeks * w
end

function util.days(days)
    return days * d
end

function util.hours(hours)
    return hours * h
end

function util.minutes(minutes)
    return minutes * m
end

function util.seconds(seconds)
    return seconds * s
end

function util.formatLong(milliseconds)
    local msAbs = math.abs(milliseconds)
    if msAbs >= d then
        return util.plural(milliseconds / d, 'day')
    end
    if msAbs >= h then
        return util.plural(milliseconds / h, 'hour')
    end
    if msAbs >= m then
        return util.plural(milliseconds / m, 'minute')
    end
    if msAbs >= s then
        return util.plural(milliseconds / s, 'second')
    end
    return tostring(milliseconds) .. ' ms'
end

function util.plural(n, name)
    name = n == 1 and name or name .. 's'
    return n .. ' ' .. name
end

function util.bulkDelete(msg, messages)
    if type(messages) == 'table' then
        local messageIDs = {}
        for _, message in pairs(messages) do
            table.insert(messageIDs, message.id or message)
        end
        if #messageIDs == 0 then
            return {}
        end
        if #messageIDs == 1 then
            msg.channel:getMessage(messageIDs[1]):delete()
            return {messageIDs[1]}
        end
        msg.channel:bulkDelete(messageIDs)
        return messageIDs
    elseif type(messages) == 'number' then
        return util.bulkDelete(msg, msg.channel:getMessages(messages))
    end
end

function util.compareRoles(role1, role2)
    if role1.position == role2.position then
        return role2.id - role1.id
    end
    return role1.position - role2.position
end

function util.manageable(member)
    if member.user.id == member.guild.ownerId then
        return false
    end
    if member.user.id == member.client.user.id then
        return false
    end
    if member.client.user.id == member.guild.ownerId then
        return true
    end
    return util.compareRoles(member.guild.me.highestRole, member.highestRole) > 0
end

function util.checkPerm(member, channel, permissions)
    if not (type(permissions) == 'table') then
        permissions = {permissions}
    end
    if #permissions == 0 then
        return true
    end
    local hasRole
    hasRole = function(mem, role)
        local has = nil
        mem.roles:forEach(function(role2)
            if role2.name:lower() == role:lower() then
                has = true
            end
        end)
        return has
    end
    if not (member) then
        return false
    end
    local perms = member:getPermissions(channel)
    local permCodes = {}
    for _, perm in pairs(permissions) do
        table.insert(permCodes, enums[perm])
    end
    if perms:has(unpack(permCodes)) then
        return true
    else
        if hasRole(member, 'administrator') then
            return true
        else
            local needed = {}
            for roleName, permis in pairs(roles) do
                for _, perm in pairs(permis) do
                    if extensions.table.search(perm, permissions) then
                        table.insert(needed, roleName)
                    end
                end
            end
            local has = true
            if #needed > 0 then
                for _, role in pairs(needed) do
                    if not (hasRole(member, role)) then
                        has = false
                    end
                end
                return has
            else
                return false
            end
        end
    end
end

function util.getPrefix(msg)
    local prefix
    for _, pre in pairs(msg.client._prefix) do
        local p = type(pre) == 'function' and pre(msg) or tostring(pre)
        if string.find(msg.content, p) == 1 then
            prefix = p
            break
        end
    end
    return prefix
end

function util.isOwner(user)
    for _, owner in pairs(user.client.owners) do
        if owner == user.id then
            return true
        end
    end
    return false
end

function util.errorEmbed(title, content)
    title = title or 'An error has occured'
    return Embed():setTitle(title):setDescription(content):setTimestamp(discordia.Date():toISO()):setColor(16711731)
end

function util.example(command)
    local example = command.name

    for _, arg in ipairs(command.args) do
        local name = arg.displayName or arg.name
        local v = arg.value or arg.type
        example = example .. ' ' .. (arg.required and f('<%s: %s>', name, v) or f('[%s: %s]', name, v))
    end

    for _, flg in ipairs(command.flags) do
        local v = flg.value or flg.type
        example = example .. ' ' .. (flg.required and f('<%s%s: %s>', #flg.name == 1 and '-' or '--', flg.name, v) or f('[--%s: %s]', flg.name, v))
    end

    return example
end

return util
