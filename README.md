<h1 align="center">Toast</h1>
<p align="center">
  <img alt="Lines" src="https://img.shields.io/tokei/lines/github/notsoclassy/toast?style=flat-square">
</p>

# About

A Framework for [Discordia](https://github.com/SinisterRectus/Discordia) <br>
You can find a comparison with other libraries [here](https://sovietkitsune.github.io/SuperToast/topics/comparison/)

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
* [Sweet Pie](https://github.com/CozzyBro2/sweetpie)

# How to install

Do `lit install NotSoClassy/toast` in your console, and it should add all the stuff you need!
