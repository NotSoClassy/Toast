local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n' .. tostring(err))

return {
    package = require('./package'),
    util = require('./util'),
    argparser = require('./argparser'),
    Client = require('./structures/Client'),
    Embed = require('./structures/Embed'),
    Command = require('./structures/Command')
}
