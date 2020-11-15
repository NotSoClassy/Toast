local discordia = require('discordia')
local Embed = require('./Embed')

local class, Date = discordia.class, discordia.Date
local Command, get, set = class('Command')

local function hookInit(hooks)
   hooks = hooks or {}
   local emptyFunction = function() end

   for i, v in pairs(hooks) do
      assert(type(v) == 'function', 'All hooks must be a function (You set ' .. i .. ' to a ' .. type(v) .. ')')
   end

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
   self._description = options.description or 'The ' .. name .. ' command'
   self._cooldown = options.cooldown or 0
   self._execute = options.execute or function() end
   self._aliases = options.aliases or {}
   self._allowDMS = not not options.allowDMS
   self._hooks = hookInit(options.hooks)
   self._helpEmbed = embedGen(self)
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

function set.example(self, str)
   self._example = str
   self._helpEmbed = embedGen(self)
end

function set.description(self, str)
   self._description = str
   self._helpEmbed = embedGen(self)
end

function set.execute(self, fn)
   self._execute = fn
end

function set.aliases(self, tbl)
   self._aliases = tbl
   self._helpEmbed = embedGen(self)
end

function set.cooldown(self, cd)
   self._cooldown = cd
   self._helpEmbed = embedGen(self)
end

function set.allowDMS(self, bool)
   self._allowDMS = bool
end

-- Getters

function get.name(self)
   return self._name
end

function get.helpEmbed(self)
   return self._helpEmbed
end

function get.example(self)
   return self._example
end

function get.description(self)
   return self._description
end

function get.execute(self)
   return self._execute
end

function get.aliases(self)
   return self._aliases
end

function get.cooldown(self)
   return self._cooldown
end

function get.allowDMS(self)
   return self._allowDMS
end

function get.hooks(self)
   return self._hooks
end

return Command
