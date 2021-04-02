local discordia = require 'discordia'
local parse = require 'parser'
local util = require 'util'

local class = discordia.class

local match, gmatch = string.match, string.gmatch
local concat, insert = table.concat, table.insert
local f = string.format

local function parserErr(err)
    return util.error(f('`%s`', err), 'Error while parsing, Error message:')
end

local function findSub(tbl, q)
    if not q then return end
    for _, v in ipairs(tbl) do
        if v.name == q or util.search(v.aliases, q) then
            return v
        end
    end
end

local function unpackOther(other, m)
    if not other then return end
    local ret = {}
    for i, v in ipairs(other) do
        v = type(v) == 'function' and v(m) or v
        ret[i] = v
    end
    return unpack(ret)
end

return function(msg)
    local self = msg.client

    if msg.author.bot then return end
    if msg.guild and not msg.guild:getMember(msg.client.user.id):hasPermission('sendMessages') then return end

    local prefix = util.prefix(msg)

    if not prefix then return end

    local cmd, msgArg = match(msg.content:sub(#prefix + 1), '^(%S+)%s*(.*)')

    if not cmd then return end

    cmd = cmd:lower()

    local args = {}
    for arg in gmatch(msgArg, '%S+') do
        insert(args, arg)
    end

    local command = self._commands:find(function(v)
        return v.name == cmd or util.search(v.aliases, cmd)
    end)

    if not command then return end

    for i = 1, #args + 1 do
        local sub = findSub(command._subCommands, args[i])
        if not sub then
            args = { unpack(args, i, #args) }
            break
        end
        command = sub
    end

    local check, content = command:check(msg)
    if not check then
        return msg:reply(util.error(content))
    end

    local onCooldown, time = command:onCooldown(msg.author.id)
    if onCooldown then
        return msg:reply(util.error('Please wait ' .. util.format(time), 'Slow down, you\'re on cooldown'))
    end

    -- parser
    if #command._args ~= 0 or #command._flags ~= 0 then
        local pargs, pflags = parse(concat(args, ' '), msg, command)

        if pargs == nil then
            return msg:reply(parserErr(pflags))
        end

        pargs.flags = pflags
        args = pargs
    end

    command.hooks.preCommand(msg)

    command:startCooldown(msg.author.id)
    local success, err = pcall(command.execute, msg, args, unpackOther(self._toastOptions.params, msg))

    command.hooks.postCommand(msg, class.type(err) == 'Message' and err or nil)

    if not success then
        self:error('ERROR WITH ' .. command.name .. ': ' .. err)
        msg:reply(util.error('Please try this command later'))
    end
end