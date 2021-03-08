local Array = toast.Array

describe('Array tests', function()
    it('should return the value of the first element in the provided array that satisfies the provided testing function', function()
        assert.are.equal(Array(1, 2, 3):find(function(v) return v % 2 == 0 end), 2)
        assert.are.equal(Array('a', 'bb', 'ccc'):find(function(v) return #v == 3 end), 'ccc')
    end)

    it('should return all elements that pass the test implemented by the provided function', function()
        assert.are.same(Array(1, 'a', 3, 'b', {}):filter(function(v) return type(v) ~= 'number' end), {'a', 'b', {}})
        assert.are.same(Array('aaa', 1, -3, {}):filter(function(v) return type(v) == 'number' end), {1, -3})
    end)

    it('should return the results of calling a provided function on every element in the calling array', function()
        assert.are.same(Array('abc', 1, 3):map(function(v) return tostring(v) .. 'de' end), {'abcde', '1de', '3de'})
        assert.are.same(Array(36, 1, 3):map(function(v) return v * v end), {1296, 1, 9})
    end)

    it('should add one or more elements to the end of an array and returns the new length of the array', function()
        local arr = Array(13)
        arr:push(12)

        assert.are.same(arr, {13, 12})

        arr = Array({}, 2, 'a')
        arr:push(77, 'a')

        assert.are.same(arr, {{}, 2, 'a', 77, 'a'})
    end)

    it('should remove the last element from an array and returns that element', function()
        assert.are.equal(Array('a', 3):pop(), 3)
        assert.are.equal(Array('a', 'cdef'):pop(), 'cdef')
    end)
end)