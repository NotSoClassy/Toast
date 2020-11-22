# Toast

A Framework for [Discordia](https://github.com/SinisterRectus/Discordia)

# Example

```lua
local toast = require('toast')
local client = toast.Client {
    prefix = '!'
}

client:addCommand {
  name = 'ping',
  execute = function(msg, args)
    return msg:reply('Pong!')
  end
}

client:login('TOKEN')
```

# Bots that use Toast

If your bot uses Toast and you want it to be on the list, then make an issue with the bot info.
* [Invicta](https://github.com/NotSoClassy/Invicta)

# How to install

Do `lit install NotSoClassy/Toast` in your console, and it should add all the stuff you need!