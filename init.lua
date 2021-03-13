local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n' .. tostring(err))

return {
    util = require 'util',
    package = require './package',
    Embed = require './structures/Embed',
    Array = require './structures/Array',
    Client = require './structures/Client',
    Command = require './structures/Command',
    parser = require 'parser'
}
