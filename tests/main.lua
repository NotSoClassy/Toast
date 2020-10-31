local config = require('./config')
local toast = require('../init')
local client = toast.Client{
    prefix = '!'
}

client:login(config.token)