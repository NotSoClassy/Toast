local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n' .. tostring(err))

return {
    util = require './userUtil',
    package = require './package',
    Embed = require './structures/Embed',
    Client = require './structures/Client',
    Command = require './structures/Command',
    argparser = require 'argparser',
    flagparser = require 'flagparser'
}
