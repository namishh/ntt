local Assets = {}
Assets.__index = Assets

function Assets.new()
  local assets = setmetatable({}, Assets)

  assets.images = {}
  assets.sounds = {}
  assets.fonts = {}
  assets.shaders = {}
  assets.data = {}

  assets._pending = {
    images = {},
    sounds = {},
    fonts = {},
    shaders = {},
    data = {},
  }

  return assets
end

function Assets:addImage(id, path, immediate)
  self._pending.images[id] = { path = path }
  if immediate then self:loadImage(id) end
  return self
end

function Assets:addSound(id, path, soundType, immediate)
  self._pending.sounds[id] = { path = path, type = soundType or "static" }
  if immediate then self:loadSound(id) end
  return self
end

function Assets:addFont(id, path, size, immediate)
  self._pending.fonts[id] = { path = path, size = size or 12 }
  if immediate then self:loadFont(id) end
  return self
end

function Assets:addShader(id, pathOrCode, immediate)
  self._pending.shaders[id] = { path = pathOrCode }
  if immediate then self:loadShader(id) end
  return self
end

function Assets:addData(id, path, parser, immediate)
  self._pending.data[id] = { path = path, parser = parser }
  if immediate then self:loadData(id) end
  return self
end

function Assets:loadImage(id)
  local meta = self._pending.images[id]
  if not meta then return nil end
  if self.images[id] then return self.images[id] end

  self.images[id] = love.graphics.newImage(meta.path)
  return self.images[id]
end

function Assets:loadSound(id)
  local meta = self._pending.sounds[id]
  if not meta then return nil end
  if self.sounds[id] then return self.sounds[id] end

  self.sounds[id] = love.audio.newSource(meta.path, meta.type)
  return self.sounds[id]
end

function Assets:loadFont(id)
  local meta = self._pending.fonts[id]
  if not meta then return nil end
  if self.fonts[id] then return self.fonts[id] end

  self.fonts[id] = love.graphics.newFont(meta.path, meta.size)
  return self.fonts[id]
end

function Assets:loadShader(id)
  local meta = self._pending.shaders[id]
  if not meta then return nil end
  if self.shaders[id] then return self.shaders[id] end

  self.shaders[id] = love.graphics.newShader(meta.path)
  return self.shaders[id]
end

function Assets:loadData(id)
  local meta = self._pending.data[id]
  if not meta then return nil end
  if self.data[id] then return self.data[id] end

  local content = love.filesystem.read(meta.path)
  if meta.parser then
    self.data[id] = meta.parser(content)
  else
    self.data[id] = content
  end
  return self.data[id]
end

function Assets:loadAll(assetType)
  local pending = self._pending[assetType]
  if not pending then return end

  for id in pairs(pending) do
    if assetType == "images" then self:loadImage(id)
    elseif assetType == "sounds" then self:loadSound(id)
    elseif assetType == "fonts" then self:loadFont(id)
    elseif assetType == "shaders" then self:loadShader(id)
    elseif assetType == "data" then self:loadData(id)
    end
  end
end

function Assets:loadEverything()
  self:loadAll("images")
  self:loadAll("sounds")
  self:loadAll("fonts")
  self:loadAll("shaders")
  self:loadAll("data")
end


function Assets:image(id)
  return self.images[id] or self:loadImage(id)
end

function Assets:sound(id)
  return self.sounds[id] or self:loadSound(id)
end

function Assets:font(id)
  return self.fonts[id] or self:loadFont(id)
end

function Assets:shader(id)
  return self.shaders[id] or self:loadShader(id)
end

function Assets:get(id)
  return self.data[id] or self:loadData(id)
end


function Assets:unload(assetType, id)
  if self[assetType] then
    self[assetType][id] = nil
  end
end

function Assets:unloadAll(assetType)
  self[assetType] = {}
end

function Assets:clear()
  self.images = {}
  self.sounds = {}
  self.fonts = {}
  self.shaders = {}
  self.data = {}
end

function Assets:isLoaded(assetType, id)
  return self[assetType] and self[assetType][id] ~= nil
end

--[[
assets:load({
  images = {
    player = "sprites/player.png",
    enemy = "sprites/enemy.png",
  },
  sounds = {
    shoot = { path = "sounds/shoot.wav", type = "static" },
    music = { path = "sounds/music.ogg", type = "stream" },
  },
  fonts = {
    main = { path = "fonts/main.ttf", size = 16 },
  },
})
]]
function Assets:load(manifest)
  if manifest.images then
    for id, v in pairs(manifest.images) do
      if type(v) == "string" then
        self:addImage(id, v, true)
      else
        self:addImage(id, v.path, true)
      end
    end
  end

  if manifest.sounds then
    for id, v in pairs(manifest.sounds) do
      if type(v) == "string" then
        self:addSound(id, v, "static", true)
      else
        self:addSound(id, v.path, v.type, true)
      end
    end
  end

  if manifest.fonts then
    for id, v in pairs(manifest.fonts) do
      self:addFont(id, v.path, v.size, true)
    end
  end

  if manifest.shaders then
    for id, v in pairs(manifest.shaders) do
      if type(v) == "string" then
        self:addShader(id, v, true)
      else
        self:addShader(id, v.path, true)
      end
    end
  end

  if manifest.data then
    for id, v in pairs(manifest.data) do
      if type(v) == "string" then
        self:addData(id, v, nil, true)
      else
        self:addData(id, v.path, v.parser, true)
      end
    end
  end

  return self
end

return Assets

