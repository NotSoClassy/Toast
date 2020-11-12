local discordia = require('discordia')

local class = discordia.class
local Command, get, set = class('Command')
local cooldowns = {}

function Command:__init(name)
   self._name = name
   self._example = name .. ' [any]'
   self._description = 'The ' .. name .. ' command'
   self._execute = function()
   end
   self._aliases = {}
   self._cooldown = 0
end

function Command.startCooldown(id)
   cooldowns[id] = os.time() * 1000
end

function Command:onCooldown(id)
   local start = cooldowns[id]
   if not start then
      return false
   end
   local now = os.time() * 1000
   if (start + self._cooldown) <= now then
      cooldowns[id] = nil
      return false
   else
      return true, (start - (now - self._cooldown))
   end
end

function set.example(self, str)
   self._example = str
end
function set.description(self, str)
   self._description = str
end
function set.execute(self, fn)
   self._execute = fn
end
function set.aliases(self, tbl)
   self._aliases = tbl
end

function set.cooldown(self, cd)
   self._cooldown = cd
end

function get.name(self)
   return self._name
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

return Command
