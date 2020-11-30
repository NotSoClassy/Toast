--[=[
@c Command
@t ui
@p name string
@op options table
@d The class that does the import things like handling events and commands.
]=]

local discordia = require('discordia')

local class, Date = discordia.class, discordia.Date
local Command, get, set = class('Command')

local emptyFunction = function() return true end

local function hookInit(hooks)
   hooks = hooks or {}

   for i, v in pairs(hooks) do
      assert(type(v) == 'function', 'All hooks must be a function (You set ' .. i .. ' to a ' .. type(v) .. ')')
   end
   hooks.check = hooks.check or emptyFunction
   hooks.preCommand = hooks.preCommand or emptyFunction
   hooks.postCommand = hooks.postCommand or emptyFunction

   return setmetatable(hooks, {__newindex = function(tbl, i, v)
      assert(type(v) == 'function', 'All hooks must be a function (You set ' .. i .. ' to a ' .. type(v) .. ')')
      tbl[i] = v
   end})
end

function Command:__init(name, options)
   options = options or {}
   self._cooldowns = {}
   self._name = name
   self._example = options.example or name .. ' [any]'
   self._description = options.description or 'The ' .. name .. ' command!'
   self._cooldown = options.cooldown or 0
   self._execute = options.execute or emptyFunction
   self._aliases = options.aliases or {}
   self._subCommands = options.subCommands or {}
   self._hidden = not not options.hidden
   self._allowDMS = not not options.allowDMS
   self._allowGuilds = not (options.allowGuilds == false)
   self._nsfw = not not options.nsfw
   self._userPerms = options.userPerms or {}
   self._botPerms = options.botPerms or {}
   self._hooks = hookInit(options.hooks)
end

local function hasPerms(member, channel, perms)
   if not member or not channel.guild then return true end
   local userPerms = member:getPermissions(channel)
   return userPerms:has(unpack(perms))
end

--[=[
@m check
@p msg Message
@r boolean
@r string/nil
@d Checks if the user can run the command.
]=]
function Command:check(msg)

   if not self._allowDMS and not msg.guild then return end
   if not self._allowGuilds and msg.guild then return end

   if self.nsfw and not msg.channel.nsfw then
      return false, 'This is a NSFW only command, please try in a NSFW channel'
   end

   local check, content = self._hooks.check(msg)
   if not check then return false, content end

   if not hasPerms(msg.guild and msg.guild:getMember(msg.client.user.id), msg.channel, self._botPerms) then
      return false, 'I am missing permission to run this command (' .. table.concat(self._botPerms, ', ') .. ')'
   end

   if not hasPerms(msg.member, msg.channel, self._userPerms) then
      return false, 'You are missing permission to run this command (' .. table.concat(self._userPerms, ', ') .. ')'
   end

   return true
end

--[=[
@m startCooldown
@p id string
@r nil
@d Starts a cooldown for the user provided.
]=]
function Command:startCooldown(id)
   self._cooldowns[id] = Date():toMilliseconds()
end

--[=[
@m onCooldown
@p id string
@r boolean
@r number/nil
@d Checks if the user is on a cooldown.
]=]
function Command:onCooldown(id)
   local start = self._cooldowns[id]
   if not start then
      return false
   end
   local now = Date():toMilliseconds()
   if (start + self._cooldown) <= now then
      self._cooldowns[id] = nil
      return false
   else
      return true, (start - (now - self._cooldown))
   end
end

-- Setters

function set:example(v)
   self._example = v
end

function set:subCommands(v)
   self._subCommands = v
end

function set:description(v)
   self._description = v
end

function set:execute(v)
   self._execute = v
end

function set:aliases(v)
   self._aliases = v
end

function set:cooldown(v)
   self._cooldown = v
end

function set:hidden(v)
   self._hidden = v
end

function set:allowDMS(v)
   self._allowDMS = v
end

function set:nsfw(v)
   self._nsfw = v
end

function set:userPerms(v)
   self._userPerms = v
end

function set:botPerms(v)
   self._botPerms = v
end

-- Getters

--[=[@p name string The commands name.]=]
function get:name()
   return self._name
end

--[=[@p example string The commands example.]=]
function get:example()
   return self._example
end

--[=[@p description string The commands description.]=]
function get:description()
   return self._description
end

--[=[@p execute function The function called when the command is ran.]=]
function get:execute()
   return self._execute
end

--[=[@p subCommands table Table with all the subcommands]=]
function get:subCommands()
   return self._subCommands
end

--[=[@p aliases table The command's alias(es).]=]
function get:aliases()
   return self._aliases
end

--[=[@p cooldown number The cooldown length.]=]
function get:cooldown()
   return self._cooldown
end

--[=[@p allowDMS boolean Whether or not the command can be ran in DMS.]=]
function get:allowDMS()
   return self._allowDMS
end

--[=[@p nsfw boolean If the command is only allowed in nsfw channels.]=]
function get:nsfw()
   return self._nsfw
end

--[=[@p userPerms table Table of permissions that the user needs to run the command.]=]
function get:userPerms()
   return self._userPerms
end

--[=[@p botPerms table Table of permissions that the bot needs to run the command.]=]
function get:botPerms()
   return self._botPerms
end

--[=[@p hidden boolean Whether or not the command will appear in the help list (Only if the default help option is enabled).]=]
function get:hidden()
   return self._hidden
end

--[=[@p hooks table The commands hooks.]=]
function get:hooks()
   return self._hooks
end



return Command
