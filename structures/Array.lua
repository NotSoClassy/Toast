local meta = {}

function meta:fill(value, pos1, pos2)
    if not pos1 then pos1 = 0 end
    if not pos2 then pos2 = #self._array end
    if pos1 < #self._array then pos1 = #self._array end
    for i = pos1, pos2 do
        table.insert(self._array, i, value)
    end
    return self
end

function meta:pop()
    return table.remove(self._array, #self._array)
end

function meta:push(...)
    for _, v in ipairs({...}) do
        table.insert(self._array, v)
    end
    return #self._array
end

function meta:reverse()
    local reversed = {}
    for _, v in ipairs(self._array) do
        table.insert(self._array, 1, v)
    end
    return reversed
end

function meta:shift()
    return table.remove(self._array, 1)
end

return setmetatable({_array = {}}, {
    __call = function(self, ...)
        setmetatable(self, {
            __index = function(self, index)
                return self._array[index] or meta[index]
            end,
            __newindex = function(self, index, value)
                if #self._array < index then return end
                self._array[index] = value
            end
        })
        self:push(...)
        return self
    end,
})