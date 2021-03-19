local Array = {}

local function new(...)
    local arg = { ... }
    local out = { }
    for i = 1, select('#', ...) do -- filter nil values
        if arg[i] ~= nil then
            table.insert(out, arg[i])
        end
    end 
    return setmetatable(out, { __index = Array, __newindex = function(self, i, v)
        assert(type(i) == 'number', 'The index must be a number')
        rawset(self, i, v)
    end})
end

function Array:find(fn)
    for i, v in ipairs(self) do
        if fn(v, i) then
            return v, i
        end
    end
end

function Array:filter(fn)
    local arr = new()
    for i, v in ipairs(self) do
        if fn(v, i) then
            arr:push(v)
        end
    end
    return arr
end

function Array:map(fn)
    local map = new()
    for i, v in ipairs(self) do
        map:push(fn(v, i))
    end
    return map
end

function Array:push(...)
    for _, v in ipairs {...} do
        table.insert(self, v)
    end
end

function Array:pop()
    return table.remove(self)
end

return new