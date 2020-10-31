local discordia = require('discordia')

local class, Client = discordia.class, discordia.Client
local Toast, get, set = class('Toast', Client)

local validOptions = {
    prefix = 'string'
}

local function parseOptions(options)
    local discordiaOptions = {}
    local toastOptions = {}

    for i, v in pairs(options) do
        if validOptions[i] then
            toastOptions[i] = v
        else
            discordiaOptions[i] = v
        end
    end

    return toastOptions, discordiaOptions
end

function Toast:__init(options)
    local options, discordiaOptions = parseOptions(options)
    Client.__init(self, discordiaOptions)
    self._prefix = type(options.prefix) == 'table' and options.prefix or {options.prefix or '!'} 
    self:on('messageCreate', function(msg)
        print(msg.content)
    end)
end

function Toast:login(token)
    return self:run('Bot '..token)
end

return Toast