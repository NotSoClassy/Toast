local toast = require('toast')
local timer = require('timer')
local client = toast.Client {
    prefix = '!'
}

client:addCommand {
    name = 'hook',
    execute = function(msg)
        return msg:reply('This command uses hooks!')
    end,
    hooks = {
        check = function(msg) -- This should return a boolean of whether or not the user can use this command
            return msg and true
        end,
        preCommand = function(msg) -- This runs before the command function is called
            msg.channel:broadcastTyping()
            timer.sleep(1000) -- Wait 1000ms to make it look like the bot is actually typing something out
        end,
        postCommand = function(cmdMsg, botMsg) -- This is after the command is called (cmdMsg is the original message and botMsg is the message the bot sent)
            if not botMsg then return end -- This will be nil if the command errored or the command doesn't return the message it sends
            print(cmdMsg.author.name .. ' said: [' .. cmdMsg.content .. '] and the bot said: [' .. botMsg.content .. ']')
        end
    }
}

client:run('TOKEN')