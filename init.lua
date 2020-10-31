local success, err = pcall(require, 'discordia')
assert(success, 'Toast requires Discordia to function\n'..tostring(err))

return {
    package = require('./package'),
    Client = require('./structures/Client')
}