--[=[
@c Toast
@t ui
@op options table
@d The class that does the important things like handling events and commands.
]=]
local discordia = require 'discordia'
local Command = require './Command'
local Array = require './Array'

local util = require 'util'

local class, Client = discordia.class, discordia.Client
local Toast, get = class('Toast', Client)

local match = string.match
local insert = table.insert

function Toast:__init(opt)
    local options, discordiaOptions = util.parseOptions(opt or {})
    Client.__init(self, discordiaOptions)

    self._owners = type(options.owners) == 'table' and options.owners or {options.owners}
    self._prefix = type(options.prefix) == 'table' and options.prefix or {options.prefix or '!'}
    self._commands = Array(options.defaultHelp and require '../commands/help', options.sudo and require '../commands/sudo')
    self._uptime = discordia.Stopwatch()
    self._toastEvents = {}
    self._toastOptions = options
    
    local ready = self:on('ready', function()
        if options.mentionPrefix then
            table.insert(self._prefix, '<@!' .. self.user.id .. '> ')
        end
        table.insert(self._owners, self.owner.id)
        self:removeListener(ready)
    end)

    self._toastEvents.commandHandler = self:on('messageCreate', options.commandHandler or require 'commandHandler')
end

--[=[
@m login
@p token string
@op presence table
@r nil
@d It's just this [this](https://github.com/SinisterRectus/Discordia/wiki/Client#runtoken-presence),
   but it adds "Bot" to the beginning if it isn't already there.
]=]
function Toast:login(token, status)
    token = match(token, '^Bot') and token or 'Bot ' .. token
    self:run(token, status)
end

local function loopSubCommands(tbl, inh)
    if not tbl then
        return
    end
    for i, v in ipairs(tbl._subCommands) do
        tbl.subCommands[i] = class.type(v) == 'Command' and v or Command(v.name)
        tbl.subCommands[i] = loopSubCommands(tbl.subCommands[i])
    end
    return tbl
end

--[=[
@m addCommand
@p command Command/table
@r nil
@d Adds a command to the command handler.
]=]
function Toast:addCommand(command)
    command = class.type(command) == 'Command' and command or Command(command.name, command)
    command = loopSubCommands(command, command.inherit) or command

    insert(self._commands, command)
    self:debug('Command ' .. command.name .. ' has been added')
end

--[=[
@m removeCommand
@p name string
@r nil
@d Removes a command from the command handler.
]=]
function Toast:removeCommand(name)
    local command

    for i, v in ipairs(self._commands) do
        if v.name == name then
            command = v
            self._commands[i] = nil
            break
        end
    end

    if not command then
        return
    end

    self:debug('Command ' .. name .. ' has been removed')
end

--[=[@p prefix table The prefix(es) the bot uses.]=]
function get:prefix()
    return self._prefix
end

--[=[@p commands table All the commands in a table.]=]
function get:commands()
    return self._commands
end

--[=[@p owners table The owners of the bot.]=]
function get:owners()
    return self._owners
end

--[=[@p uptime Stopwatch The uptime of the bot.]=]
function get:uptime()
    return self._uptime
end

return Toast
