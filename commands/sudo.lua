local toast = require '../init'
local util = require 'util'

local function trim(str)
    local ret = {}
    for v in string.gmatch(str, '%S+') do
        table.insert(ret, v) 
    end
    return table.concat(ret, ' ')
end

return toast.Command('sudo', {
    hooks = { check = util.isOwner },
    hidden = true,
    description = 'This command runs a command even if the user doesn\'t meet the permissions requirement',
    execute = function(msg, args)
        local prefix = util.prefix(msg)
        local content = prefix .. trim(msg.content):sub(#prefix+6) -- remove {prefix}sudo and replace it with {prefix}command ...
        
        rawset(msg, 'isSudo', true)
        rawset(msg, 'content', content)
 
        msg.client:emit('messageCreate', msg)
    end
})