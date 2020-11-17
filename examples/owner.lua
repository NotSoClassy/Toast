local toast = require('toast')
local client = toast.Client {
    prefix = '!',
    owners = {'ID'}
}

client:addCommand {
    name = 'owner',
    description = 'This command can only be ran by owners',
    execute = function(msg)
        return msg:reply('You are a owner!')
    end,
    hooks = {
        check = function(msg)
            return toast.util.isOwner(msg.author) -- check if they're an owner
        end
    },
}

client:run('TOKEN')