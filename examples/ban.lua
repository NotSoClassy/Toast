local toast = require('toast')
local client = toast.Client {
    prefix = '!'
}

client:addCommand {
    name = 'ban',
    description = 'Ban a user from this guild',
    example = 'ban <mention>',
    userPerms = {'banMembers'}, -- Make sure the user is allowed to ban people
    botPerms = {'banMembers'}, -- Make sure the bot can ban people
    hooks = {check = function(msg)
        if not msg.guild or not msg.mentionedUsers.first then return false, 'Couldn\'t find a user' end

        local member = msg.guild:getMember(msg.mentionedUsers.first.id)

        if not member then return true end

        return
            toast.util.compareRoles(msg.member.highestRole, member.highestRole) < 0 and toast.util.manageable(member),  -- compare there roles and my roles
            'You cannot ban this member because they have a higher role than you or me' -- Fail message
    end},
    execute = function(msg)
        local user = msg.mentionedUsers.first
        local success = msg.guild:banUser(user.id)

        if success then
            return msg:reply(user.tag .. ' has been banned!')
        else
            return msg:reply('An error has occured while trying to ban this user')
        end
    end
}

client:login('TOKEN')