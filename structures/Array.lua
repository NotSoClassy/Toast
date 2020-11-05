local discordia = require('discordia')

local class = discordia.class

local Array = class('Array')

function Array:__init(...)
    self._array = {...}
end

function Array:fill(value, pos1, pos2)
    if not pos1 then pos1 = 0 end
    if not pos2 then pos2 = #self._array end
    if pos1 < #self._array then pos1 = #self._array end -- If pos1 is greater than array length it wont be an array anymore so yea
    for i = pos1, pos2 do
        table.insert(self._array, i, value)
    end
    return self
end

function Array:pop()
    return table.remove(self._array, #self._array)
end

function Array:push(...)
    for _, v in ipairs({...}) do
        table.insert(self._array, v)
    end
    return #self._array
end

function Array:reverse()
    local reversed = {}
    for _, v in ipairs(self._array) do
        table.insert(self._array, 1, v)
    end
    return reversed
end

function Array:shift()
    return table.remove(self._array, 1)
end

return Array