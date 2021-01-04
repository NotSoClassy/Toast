--[=[
@c Toast
@t ui
@op options table
@d The class that does the important things like handling events and commands.
]=]

local discordia = require('discordia')
local argParse = require('../argparser')
local util = require('../util')
local Command = require('./Command')

local class, enums, Client = discordia.class, discordia.enums, discordia.Client
local Toast, get = class('Toast', Client)

local match, gmatch = string.match, string.gmatch
local insert, concat, unpack = table.insert, table.concat, table.unpack

local validOptions = {
   prefix = {'string', 'table'},
   owners = {'string', 'table'},
   commandHandler = 'function',
   defaultHelp = 'boolean',
   advancedArgs = 'boolean'
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
   for i, k in pairs(tbl) do
      if v == k then
         return i
      end
   end
end

local function findSub(tbl, q)
   if not q then return end
	for _, v in ipairs(tbl) do
		if v.name == q or search(v.aliases, q) then
			return v
		end
	end
end

function Toast:__init(allOptions)
   local options, discordiaOptions = parseOptions(allOptions or {})
   Client.__init(self, discordiaOptions)

   self._owners = type(options.owners) == 'table' and options.owners or {options.owners}
   self._prefix = type(options.prefix) == 'table' and options.prefix or {options.prefix or '!'}
   self._commands = {options.defaultHelp and require('../commands/help')}
   self._uptime = discordia.Stopwatch()
   self._toastEvents = {}
   self._toastOptions = options

   self._toastEvents.commandHandler = self:on('messageCreate', options.commandHandler or function(msg)
      if msg.author.bot then return end

      if msg.guild and not msg.guild:getMember(msg.client.user.id):hasPermission(enums.permission.sendMessages) then
         return
      end

      local prefix = util.getPrefix(msg)

      if not prefix then return end

      local cmd, msgArg = match(msg.content:sub(#prefix + 1), '^(%S+)%s*(.*)')

      if not cmd then return end

      cmd = cmd:lower()

      local args = {}
      for arg in gmatch(msgArg, '%S+') do
         args[#args + 1] = arg
      end

      local command

      for _, v in pairs(self._commands) do
         if v.name == cmd or search(v.aliases, cmd) then
            command = v
            break
         end
      end

      if not command then return end

      for i = 1, #args + 1 do
         local sub = findSub(command._subCommands, args[i])
         if not sub then args = {unpack(args, i, #args)}; break end
         command = sub
      end

      local check, content = command:check(msg)
      if not check then return msg:reply(util.errorEmbed(nil, content)) end

      local onCooldown, time = command:onCooldown(msg.author.id)
      if onCooldown then
         return msg:reply(util.errorEmbed('Slow down, you\'re on cooldown', 'Please wait ' .. util.formatLongfunction(time)))
      end

      if options.advancedArgs and #command.args > 0 then
         local parsed, err = argParse.parse(msg, args, command)

         if err then
            return msg:reply(util.errorEmbed('Error with arguments', err))
         end

         args = parsed
      end

      command.hooks.preCommand(msg)

      local success, err = pcall(command.execute, msg, args, command)

      command.hooks.postCommand(msg, class.type(err) == 'Message' and err or nil)

      if not success then
         self:error('ERROR WITH ' .. command.name .. ': ' .. err)
         msg:reply(util.errorEmbed(nil, 'Please try this command later'))
      else
         command:startCooldown(msg.author.id)
      end
   end)
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

local function loopSubCommands(tbl)
   if not tbl then return end
   for i, v in pairs(tbl._subCommands) do
      tbl.subCommands[i] = class.type(v) == 'Command' and v or Command(v.name, v)
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

   command = loopSubCommands(command) or command

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

   if not command then return end

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
