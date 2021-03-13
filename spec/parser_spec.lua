local parser = toast.parser

local function parse(str, flags, args, r)
    return parser.parse(str, {}, {flags = flags or {}, args = args or {}, _requiredArgs = r or 0})
end

parser.types.custom = function(arg)
    return arg:sub(1, 1) .. ' custom'
end

describe('Parser tests', function()
    it('should parse flags', function()
    
        assert.are.same(parse('--flag value --flag2 "value 2"'), {flag = 'value', flag2 = 'value 2'}) -- no types

        assert.are.same(parse('--flag 37 --flag2 true',
            {{ name = 'flag', value = 'number' }, { name = 'flag2', value = 'boolean' }} -- built-in types
        ), {flag = 37, flag2 = true})

        assert.are.same(parse('--flag a --flag2 ea', 
            {{ name = 'flag', value = 'custom' }, { name = 'flag2', value = 'custom'}} -- custom types
        ), {flag = 'a custom', flag2 = 'e custom'})

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
        assert.are.same(parse('" arg arg" --flag value nice --flag2 value2'), {flag = 'value', flag2 = 'value2'}, {ungrouped = {' arg arg', 'nice'}}) -- no types

        assert.are.same(parse('12 --flag, true -a be',
            {{ name = 'flag', value = 'boolean' }, { name = 'a', value = 'string' }}, -- build-in types
            {{ name = 'n', value = 'number', max = 12, min = 11 }, { name = 'bool', value = 'boolean' }}
        ), {flag = true, a = 'be'}, { n = 12, bool = true })

        assert.are.same(parse('a ea --flag a --flag2 ea',
            {{ name = 'flag', value = 'custom' }, { name = 'flag2', value = 'custom'}}, -- custom types
            {{ name = 'first', value = 'custom' }, { name = 'second', value = 'custom'}}
        ), {flag = 'a custom', flag2 = 'e custom'}, {first = 'a custom', second = 'e custom'})
    end)

    it('should parse quoted args and ignore flags parsing after --', function()
        assert.are.same(parse('hello -- --c 37 \'quote arg\' "quote arg arg arg" no quote', {}, {}), {},
        {'--c', '37', 'quote arg', 'quote arg arg arg', 'no', 'quote'})
    end)
end)