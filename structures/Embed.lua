local discordia = require('discordia')
local constants = require('../constants')

local class, enums = discordia.class, discordia.enums
local Embed, get = class('Embed')

local limits = {
   title = 256,
   description = 2048,
   fields = 25,
   field = {name = 256, value = 1024},
   footer = {text = 2048},
   author = {name = 256}
}

local function shrink(str, pos)
   if #str <= pos then
      return str
   end
   return string.sub(str, 0, pos - 3) .. '...'
end

function Embed:__init()
   self._embed = {footer = {}, image = {}, thumbnail = {}, video = {}, provider = {}, author = {}, fields = {}}
end

function Embed:send(chnl)
   if not chnl then
      return
   end
   if not chnl.guild then
      return chnl:send(self)
   end
   if not chnl.guild.me:hasPermission(enums.permission.embedLinks) then
      return chnl:send('I am missing permissions to send embeds')
   end
   return chnl:send(self)
end

function Embed:setTitle(str)
   str = shrink(str, limits.title)
   self._embed.title = str
   return self
end

function Embed:setDescription(str)
   str = shrink(str, limits.description)
   self._embed.description = str
   return self
end

function Embed:setType(type)
   self._embed.type = type
   return self
end

function Embed:setColor(color)
   color = string.lower(tostring(color)) == 'random' and math.floor(math.random(16777)) * 1000 or color
   self._embed.color = color
   return self
end

function Embed:setTimestamp(iso)
   self._embed.timestamp = iso
   return self
end

function Embed:setUrl(url)
   self._embed.url = url
   return self
end

function Embed:setFooter(text, icon_url, proxy_icon_url)
   text = text or constants.ZWSP
   text = shrink(text, limits.footer.text)
   self._embed.footer.text = text
   self._embed.footer.icon_url = icon_url
   self._embed.footer.proxy_icon_url = proxy_icon_url
   return self
end

function Embed:setImage(url, proxy_url, height, width)
   self._embed.image.url = url
   self._embed.image.proxy_url = proxy_url
   self._embed.image.height = height
   self._embed.image.width = width
   return self
end

function Embed:setThumbnail(url, proxy_url, height, width)
   self._embed.thumbnail.url = url
   self._embed.thumbnail.proxy_url = proxy_url
   self._embed.thumbnail.height = height
   self._embed.thumbnail.width = width
   return self
end

function Embed:setVideo(url, height, width)
   self._embed.video.url = url
   self._embed.video.height = height
   self._embed.video = width
   return self
end

function Embed:setProvider(name, url)
   self._embed.provider.name = name
   self._embed.provider.url = url
   return self
end

function Embed:setAuthor(name, url, icon_url, proxy_icon_url)
   name = name or constants.ZWSP
   name = shrink(name, limits.author.name)
   self._embed.author.name = name
   self._embed.author.url = url
   self._embed.author.icon_url = icon_url
   self._embed.author.proxy_icon_url = proxy_icon_url
   return self
end

function Embed:addField(name, value, inline)
   if #self._embed.fields <= limits.fields then
      return self
   end
   name = name or constants.ZWSP
   value = value or constants.ZWSP
   name = shrink(name, limits.field.name)
   value = shrink(value, limits.field.value)
   table.insert(self._embed.fields, {name = name, value = value, inline = inline})
   return self
end

function get.embed(self)
   return self._embed
end

return Embed
