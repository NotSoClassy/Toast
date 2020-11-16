local discordia = require('discordia')
local Embed = require('./Embed')

local class, Date = discordia.class, discordia.Date
local Command, get, set = class('Command')

local function hookInit(hooks)
   hooks = hooks or {}
   local emptyFunction = function() return true end

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

local function embedGen(self)
   local aliases = table.concat(self._aliases, '\n')
   return Embed()
      :setColor('random')
      :setTitle(self._name:gsub('^(.)', string.upper))
      :setDescription(self._description)
      :addField('Usage:', self._usage)
      :addField('Aliases:', #aliases == 0 and 'None' or aliases)
      :setFooter('This command has a ' .. self._cooldown  .. ' second cooldown')
end

function Command:__init(name, options)
   options = options or {}
   self._cooldowns = {}
   self._name = name
   self._example = options.example or name .. ' [any]'
   self._description = options.description or 'The ' .. name .. ' command!'
   self._cooldown = options.cooldown or 0
   self._execute = options.execute or function() end
   self._aliases = options.aliases or {}
   self._allowDMS = not not options.allowDMS
   self._allowGuilds = not (options.allowGuilds == false)
   self._nsfw = not not options.nsfw
   self._perms = options.perms or {}
   self._hooks = hookInit(options.hooks)
   self._helpEmbed = embedGen(self)
end

function Command:hasPermission(member, channel)
   if not member or not channel.guild then return true end
   local perms = member:getPermissions(channel)
   return perms:has(unpack(self._perms))
end

function Command:check(msg)
   if not self._allowDMS and not msg.guild then return end
   if not self._allowGuilds and msg.guild then return end
   if self.nsfw and not msg.channel.nsfw then return end
   if not self._hooks.check(msg) then return end
   if not self:hasPermission(msg.member, msg.channel) then return end
   return true
end

function Command:startCooldown(id)
   self._cooldowns[id] = Date():toMilliseconds()
end

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
   self._helpEmbed = embedGen(self)
end

function set:description(v)
   self._description = v
   self._helpEmbed = embedGen(self)
end

function set:execute(v)
   self._execute = v
end

function set:aliases(v)
   self._aliases = v
   self._helpEmbed = embedGen(self)
end

function set:cooldown(v)
   self._cooldown = v
   self._helpEmbed = embedGen(self)
end

function set:allowDMS(v)
   self._allowDMS = v
end

function set:nsfw(v)
   self._nsfw = v
end

function set:perms(v)
   self._perms = v
end

-- Getters

function get:name()
   return self._name
end

function get:helpEmbed()
   return self._helpEmbed
end

function get:example()
   return self._example
end

function get:description()
   return self._description
end

function get:execute()
   return self._execute
end

function get:aliases()
   return self._aliases
end

function get:cooldown()
   return self._cooldown
end

function get:allowDMS()
   return self._allowDMS
end

function get:nsfw()
   return self._nsfw
end

function get:perms()
   return self._perms
end

function get:hooks()
   return self._hooks
end



return Command