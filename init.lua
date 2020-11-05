local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n' .. tostring(err))

return {
   package = require('./package'),
   utils = require('./util'),
   Client = require('./structures/Client'),
   Command = require('./structures/Command'),
   Embed = require('./structures/Embed'),
   Array = require('./structures/Array')
}
