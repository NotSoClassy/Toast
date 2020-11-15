# Toast

A Framework for [Discordia](https://github.com/SinisterRectus/Discordia)

# Example

```lua
local toast = require('toast')

client:addCommand({
  name = 'ping',
  execute = function(msg, args)
    return msg:reply('Pong!')
  end
})

client:login('TOKEN')
```

# How to install

Do `lit install NotSoClassy/Toast` in your console, and it should add all the stuff you need!