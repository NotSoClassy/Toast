local discordia = require('discordia')

local class = discordia.class
local Command, get, set = class('Command')

function Command:__init(name)
    self._name = name
    self._example = name..' [any]'
    self._description = 'The '..name..' command'
    self._execute = function() end
    self._aliases = {}
end

function set.example(self, str) self._example = str end
function set.description(self, str) self._example = str end
function set.execute(self, fn) self._execute = fn end
function set.aliases(self, tbl) self._aliases = tbl end

function get.name(self) return self._name end
function get.example(self) return self._example end
function get.description(self) return self._description end
function get.execute(self) return self._execute end
function get.aliases(self) return self._aliases end

return Command