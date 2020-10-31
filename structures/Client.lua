local discordia = require('discordia')

local class, Client = discordia.class, discordia.enums, discordia.Client
local Toast, get = class('Toast', Client)

local validOptions = {
    prefix = 'string',
    allowDMs = 'boolean'
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
    self._commands = {}
    self._aliases = {}
    self._uptime = discordia.Stopwatch()
    self:on('messageCreate', function(msg)
        if not msg.guild and options.allowDMs == false then return end
        if msg.author.bot then return end
        local prefix
        for _, pre in pairs(self._prefix) do
            if string.match(msg.content, '^'..pre) then
                prefix = pre
                break
            end
        end
        if not prefix then return end
        local command, arg = string.match(msg.cleanContent, '^'..prefix..'(%S+)%s*(.*)')
        if not command then return end
        local args = {}
        for arg in string.gmatch(arg, '%S+') do
            table.insert(args, arg)
        end
        command = self._commands[string.lower(command)] or self._aliases[string.lower(command)]
        if not command then return end
        local success, err = pcall(command.execute, msg, args)
        if not success then
            self:error('ERROR WITH '..command.name..': '..err)
        end
    end)
end

function Toast:login(token, status)
    self:run('Bot '..token)
    return status and self:setStatus(status) or self._commands['help'] and self:setStatus(self._prefix[1]..'help')
end

function Toast:addCommand(command)
    self._commands[command.name] = command
    for _, alias in pairs(command.aliases) do
        self._aliases[alias] = setmetatable({}, {__index = command})
    end
    self:debug('Command '..command.name..' has been added')
end

function Toast:removeCommand(name)
    local command = self._commands[name]
    if not command then return end
    for _, alias in pairs(command.aliases) do
        self._aliases[alias] = nil
    end
    self._commands[name] = nil
    self:debug('Command '..name..' has been removed')
end

function get.prefix(self) return self._prefix end
function get.commands(self) return self._commands end
function get.uptime(self) return self._uptime end

return Toast