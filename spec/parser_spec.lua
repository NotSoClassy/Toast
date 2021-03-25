local parser = toast.parser
local types = toast.types

local function parse(str, flags, args, r)
    local args, flags = parser(str, {}, {flags = flags or {}, args = args or {}, _requiredArgs = r or 0})
    return flags, args
end

types.custom = function(arg)
    return arg:sub(1, 1) .. ' custom'
end

describe('Parser tests', function()
    it('should parse flags', function()
    
        assert.are.same(parse('--flag value --flagw "value 2"'), {flag = 'value', flagw = 'value 2'}) -- no types

        assert.are.same(parse('--flag 37 --flagw true',
            {{ name = 'flag', value = 'number' }, { name = 'flagw', value = 'boolean' }} -- built-in types
        ), {flag = 37, flagw = true})

        assert.are.same(parse('--flag a --flagw ea',
            {{ name = 'flag', value = 'custom' }, { name = 'flagw', value = 'custom'}} -- custom types
        ), {flag = 'a custom', flagw = 'e custom'})

    end)

    it('should parse args', function()
        assert.are.same(parse('a " b c d " \'e d f\''), {}, {'a', ' b c d ', 'e d f'}) -- no types

        assert.are.same(parse('37 true abc', nil, 
            {{ name = 'n', value = 'number' }, { name = 'bool', value = 'boolean' }} -- built-in types
        ), {}, {n = 37, bool = true, ungrouped = {'abc'}})

        assert.are.same(parse('a ea', nil,
            {{ name = 'first', value = 'custom' }, { name = 'second', value = 'custom'}} -- custom types
        ), {}, {first = 'a custom', second = 'e custom'})
    end)

    it('should parse flags and args', function()
        assert.are.same(parse('" arg arg" --flag value nice --flagw value2'), {flag = 'value', flagw = 'value2'}, {ungrouped = {' arg arg', 'nice'}}) -- no types

        assert.are.same(parse('12 --flag, true -a be',
            {{ name = 'flag', value = 'boolean' }, { name = 'a', value = 'string' }}, -- build-in types
            {{ name = 'n', value = 'number', max = 12, min = 11 }, { name = 'bool', value = 'boolean' }}
        ), { flag = true, a = 'be' }, { n = 12, bool = true })

        assert.are.same(parse('a ea --flag a --flagw ea',
            {{ name = 'flag', value = 'custom' }, { name = 'flagw', value = 'custom'}}, -- custom types
            {{ name = 'first', value = 'custom' }, { name = 'second', value = 'custom'}}
        ), {flag = 'a custom', flagw = 'e custom'}, {first = 'a custom', second = 'e custom'})
    end)

    it('should parse quoted args and ignore flags parsing after --', function()
        assert.are.same(parse('hello -- --c 37 \'quote arg\' "quote arg arg arg" no quote', {}, {}), {},
        {'--c', '37', 'quote arg', 'quote arg arg arg', 'no', 'quote'})
    end)
end)