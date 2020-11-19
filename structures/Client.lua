local discordia = require('discordia')
local util = require('../util')
local Command = require('./Command')

local class, enums, Client = discordia.class, discordia.enums, discordia.Client
local Toast, get = class('Toast', Client)

local validOptions = {
   prefix = {'string', 'table'},
   owners = {'string', 'table'},
   defaultHelp = 'boolean'
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
                  error('The ' .. i .. ' option should be a (' .. table.concat(optionType, ' | ') .. ')')
               end
            end

            toastOptions[i] = v
         else
            assert(type(v) == optionType, 'The ' .. i .. ' option should be a (' .. optionType .. ')')
            toastOptions[i] = v
         end
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

function Toast:__init(allOptions)
   local options, discordiaOptions = parseOptions(allOptions or {})
   Client.__init(self, discordiaOptions)

   self._owners = type(options.owners) == 'table' and options.owners or {options.owners or self.owner and self.owner.id}
   self._prefix = type(options.prefix) == 'table' and options.prefix or {options.prefix or '!'}
   self._commands = {options.defaultHelp and require('../commands/help')}
   self._uptime = discordia.Stopwatch()

   self:on('messageCreate', function(msg)

      if msg.author.bot then return end

      if msg.guild and not msg.guild:getMember(msg.client.user.id):hasPermission(enums.permission.sendMessages) then
         return
      end

      local prefix = util.getPrefix(msg)

      if not prefix then return end

      local cmd, msgArg = string.match(msg.cleanContent, '^' .. prefix .. '(%S+)%s*(.*)')

      if not cmd then return end

      cmd = cmd:lower()

      local args = {}
      for arg in string.gmatch(msgArg, '%S+') do
         table.insert(args, arg)
      end

      local command

      for _, v in pairs(self._commands) do
         if v.name == cmd or search(v.aliases, cmd) then
            command = v
         end
      end

      if not command then return end

      local check, content = command:check(msg)
      if not check then return msg:reply(util.errorEmbed(nil, content)) end

      if command:onCooldown(msg.author.id) then
         local _, time = command:onCooldown(msg.author.id)
         return msg:reply(util.errorEmbed('Slow down, you\'re on cooldown', 'Please wait ' .. util.formatLongfunction(time)))
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

function Toast:login(token, status)
   self:run('Bot ' .. token)
   return status and self:setStatus(status)
end

function Toast:addCommand(command)
   command = class.type(command) == 'Command' and command or Command(command.name, command)
   table.insert(self._commands, command)
   self:debug('Command ' .. command.name .. ' has been added')
end

function Toast:removeCommand(name)
   local command

   for _, v in pairs(self._commands) do
      if v.name == name then
         command = v
      end
   end

   if not command then return end

   self._commands[name] = nil

   self:debug('Command ' .. name .. ' has been removed')
end

function get:prefix()
   return self._prefix
end

function get:commands()
   return self._commands
end

function get:owners()
   return self._owners
end

function get:uptime()
   return self._uptime
end

return Toast
