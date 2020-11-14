local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n' .. tostring(err))

return {
   package = require('./package'),
   utils = require('./util'),
   Client = require('./structures/Client'),
   Embed = require('./structures/Embed'),
   Command = require('./structures/Command'),
   Array = require('./structures/Array')
}
