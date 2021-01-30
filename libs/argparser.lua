local util = require 'utils'
local rex = require 'rex'

local clamp = require 'discordia' .extensions.math.clamp
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack
local match, f = string.match, string.format

local function isSnowflake(id)
    return type(id) == 'string' and #id >= 17 and #id <= 64 and not match(id, '%D')
end

local types = {

    string = function(arg)
        return arg
    end,

    number = function(arg)
        return tonumber(arg)
    end,

    boolean = function(arg)
        arg = arg:lower()
        if arg == 'true' then
            return true
        elseif arg == 'false' then
            return false
        end
    end,

    user = function(arg, msg)
        local id = match(arg, '<@!(%d+)>') or match(arg, '%d+')
        if not isSnowflake(id) then
            return
        end
        return msg:getUser(id)
    end,

    member = function(arg, msg)
        if not msg.guild then
            return
        end
        local id = match(arg, '<@!(%d+)>') or match(arg, '%d+')
        if not isSnowflake(id) then
            return
        end
        return msg.guild:getMember(id)
    end,

    role = function(arg, msg)
        if not msg.guild then
            return
        end
        local id = match(arg, '<@&(%d+)>') or match(arg, '%d+')
        if not isSnowflake(id) then
            return
        end
        return msg.guild:getRole(id)
    end
}

local function split(content)
    local args = {}
    for arg in rex.gmatch(content, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) do
        insert(args, arg)
    end
    return args
end

local function parse(msg, cmdArgs, command)
    if #cmdArgs < command._requiredArgs then
        return nil, util.example(command)
    end

    cmdArgs = split(concat(cmdArgs, ' '))

    local args = {}

    -- parse
    for i, opt in ipairs(command.args) do
        local arg = cmdArgs[1]

        local name = opt.name
        local min, max = opt.min, opt.max
        local default = opt.default

        if arg then
            local type = opt.value or opt.type

            assert(name ~= 'ungrouped' or name ~= 'flags', 'Name "' .. name .. '" is reserved')
            assert(args[name] == nil, name .. ' name is already in use')

            if type == '...' then
                args[name] = concat({arg, unpack(cmdArgs, i, #cmdArgs)}, ' ')
                cmdArgs = {}
                break
            end

            remove(cmdArgs, i)

            local typeCheck = assert(types[type], 'No type found for ' .. type)
            local value = typeCheck(arg, msg)

            if value == nil then
                return nil, opt.error or f('Argument #%d should be a %s', i, type)
            end

            if value and type == 'number' and max then
                if clamp(value, min or 1, max) ~= value then
                    return nil, f('Argument #%d should be a number inbetween %d-%d', i, min, max)
                end
            end

            args[name] = value
        elseif default then
            args[name] = type(default) == 'function' and default(msg) or default
        end
    end

    -- check depends
    for i, opt in ipairs(command.args) do
        local depends = opt.depend or opt.depends
        if depends and args[opt.name] and not args[depends] then
            return nil, f('Argument #%d depends on the argument named "%s"', i, depends)
        end
    end

    args.ungrouped = cmdArgs
    return args
end

local function newType(name, fn)
    assert(types[name], 'Type "' .. name .. '" already exists')
    types[name] = fn
end

local function removeType(name)
    types[name] = nil
end

return {removeType = removeType, newType = newType, split = split, parse = parse}
