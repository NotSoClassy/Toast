local discordia = require 'discordia'
local util = require 'util'

local class = discordia.class

local match, gmatch = string.match, string.gmatch
local concat, insert = table.concat, table.insert
local f = string.format

local function parserErr(err)
    return util.error('Error while parsing, Error message:', f('`%s`', err))
end

local function findSub(tbl, q)
    if not q then
        return
    end
    for _, v in ipairs(tbl) do
        if v.name == q or util.search(v.aliases, q) then
            return v
        end
    end
end

return function(msg)
    local self = msg.client

    if msg.author.bot then
        return
    end

    if msg.guild and not msg.guild:getMember(msg.client.user.id):hasPermission('sendMessages') then
        return
    end

    local prefix = util.prefix(msg)

    if not prefix then
        return
    end

    local cmd, msgArg = match(msg.content:sub(#prefix + 1), '^(%S+)%s*(.*)')

    if not cmd then
        return
    end

    cmd = cmd:lower()

    local args = {}
    for arg in gmatch(msgArg, '%S+') do
        insert(args, arg)
    end

    local command

    for _, v in ipairs(self._commands) do
        if v.name == cmd or util.search(v.aliases, cmd) then
            command = v
            break
        end
    end

    if not command then
        return
    end

    for i = 1, #args + 1 do
        local sub = findSub(command._subCommands, args[i])
        if not sub then
            args = {unpack(args, i, #args)};
            break
        end
        command = sub
    end

    local check, content = command:check(msg)
    if not check then
        return msg:reply(util.error(nil, content))
    end

    local onCooldown, time = command:onCooldown(msg.author.id)
    if onCooldown then
        return msg:reply(util.error('Slow down, you\'re on cooldown', 'Please wait ' .. util.time(time)))
    end

    -- flag parser
    local flags
    if command._flags then
        local flgs, str = util.flagparser(concat(args, ' '), msg, command)

        if flgs == nil then
            return msg:reply(parserErr(str))
        end

        flags = flgs
        args = { flags = flgs }
        for s in gmatch(str, '%S+') do
            insert(args, s)
        end
    end

    -- arg parser
    if #command._args > 0 then
        local parsed, err = util.argparser(msg, args, command)

        if err then
            return msg:reply(parserErr(err))
        end

        args = parsed
        args.flags = flags
    end

    local customParams = self._toastOptions.customParams
    local params = {}

    if customParams then
        for _, v in ipairs(customParams) do
            local value = type(v) == 'function' and v(msg) or v
            insert(params, value)
        end
        insert(params, command)
    else
        params = { command }
    end

    command.hooks.preCommand(msg)

    local success, err = pcall(command.execute, msg, args, unpack(params))

    command.hooks.postCommand(msg, class.type(err) == 'Message' and err or nil)

    if not success then
        self:error('ERROR WITH ' .. command.name .. ': ' .. err)
        msg:reply(util.error(nil, 'Please try this command later'))
    else
        command:startCooldown(msg.author.id)
    end
end