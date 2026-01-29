local Spritesheet = {}
Spritesheet.__index = Spritesheet

--[[
Create a spritesheet:

Static image (single frame):
local sheet = Spritesheet.fromImage(image)

Multiple static images:
local sheet = Spritesheet.fromImages({ idle = img1, walk = img2 })

Grid-based (32x32 source frames):
local sheet = Spritesheet.fromGrid(image, 32, 32)

From Aseprite file:
local sheet = Spritesheet.fromAseprite("player.aseprite", image)

Display size (render 32x32 sprites at 64x64):
sheet:setDisplaySize(64, 64)
-- or use scale factor
sheet:setScale(2)

Origin/anchor (for positioning):
sheet:setOrigin(0.5, 0.5)     -- center
sheet:setOrigin(0.5, 1.0)     -- bottom-center (feet)
sheet:setOrigin("center")     -- shorthand
sheet:setOrigin("bottom")     -- shorthand for bottom-center

Define animations:
sheet:defineAnimation("idle", 1, 4)
sheet:defineAnimation("walk", 5, 12, { loop = true })
]]

local Aseprite = require("rohan.aseprite")
local Animation = require("rohan.animation").Animation

local ORIGIN_PRESETS = {
  topleft     = { 0.0, 0.0 },
  top         = { 0.5, 0.0 },
  topright    = { 1.0, 0.0 },
  left        = { 0.0, 0.5 },
  center      = { 0.5, 0.5 },
  right       = { 1.0, 0.5 },
  bottomleft  = { 0.0, 1.0 },
  bottom      = { 0.5, 1.0 },
  bottomright = { 1.0, 1.0 },
}

local function initDisplaySettings(sheet, srcW, srcH)
  sheet.frameWidth = srcW
  sheet.frameHeight = srcH
  sheet.displayWidth = nil   -- nil = use source size
  sheet.displayHeight = nil
  sheet.scaleX = 1
  sheet.scaleY = 1
  sheet.originX = 0          -- 0-1 ratio
  sheet.originY = 0
end

function Spritesheet.fromImage(image, name)
  local sheet = setmetatable({}, Spritesheet)
  sheet.image = image
  sheet.images = nil
  sheet.quads = {}
  sheet.frames = {}
  sheet.byName = {}
  sheet.animations = {}
  sheet.frameDurations = {}

  local w, h = image:getDimensions()
  initDisplaySettings(sheet, w, h)

  local quad = love.graphics.newQuad(0, 0, w, h, w, h)
  local frameName = name or 1

  sheet.quads[1] = quad
  sheet.quads[frameName] = quad
  sheet.frames[1] = { name = frameName, index = 1, x = 0, y = 0, w = w, h = h }
  sheet.frames[frameName] = sheet.frames[1]
  sheet.frameDurations[1] = 0.1
  if type(frameName) == "string" then
    sheet.byName[frameName] = 1
  end

  sheet.count = 1
  return sheet
end

function Spritesheet.fromImages(imageTable)
  local sheet = setmetatable({}, Spritesheet)
  sheet.image = nil
  sheet.images = {}
  sheet.quads = {}
  sheet.frames = {}
  sheet.byName = {}
  sheet.animations = {}
  sheet.frameDurations = {}

  local firstW, firstH = 0, 0
  for _, img in pairs(imageTable) do
    firstW, firstH = img:getDimensions()
    break
  end
  initDisplaySettings(sheet, firstW, firstH)

  local index = 1
  for name, img in pairs(imageTable) do
    local w, h = img:getDimensions()
    local quad = love.graphics.newQuad(0, 0, w, h, w, h)

    sheet.images[index] = img
    sheet.images[name] = img
    sheet.quads[index] = quad
    sheet.quads[name] = quad
    sheet.frameDurations[index] = 0.1

    local frameData = {
      name = name,
      index = index,
      x = 0, y = 0,
      w = w, h = h,
    }

    sheet.frames[index] = frameData
    sheet.frames[name] = frameData
    sheet.byName[name] = index

    index = index + 1
  end

  sheet.count = index - 1
  return sheet
end

function Spritesheet.fromGrid(image, frameWidth, frameHeight, options)
  options = options or {}

  local sheet = setmetatable({}, Spritesheet)
  sheet.image = image
  sheet.images = nil
  sheet.quads = {}
  sheet.frames = {}
  sheet.byName = {}
  sheet.animations = {}
  sheet.frameDurations = {}
  initDisplaySettings(sheet, frameWidth, frameHeight)

  local imgW, imgH = image:getDimensions()
  local spacing = options.spacing or 0
  local margin = options.margin or 0
  local offsetX = options.offsetX or 0
  local offsetY = options.offsetY or 0

  local cols = math.floor((imgW - margin * 2 + spacing) / (frameWidth + spacing))
  local rows = math.floor((imgH - margin * 2 + spacing) / (frameHeight + spacing))

  sheet.cols = cols
  sheet.rows = rows

  local index = 1
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      local x = margin + col * (frameWidth + spacing) + offsetX
      local y = margin + row * (frameHeight + spacing) + offsetY

      sheet.quads[index] = love.graphics.newQuad(x, y, frameWidth, frameHeight, imgW, imgH)
      sheet.frames[index] = {
        index = index,
        x = x, y = y,
        w = frameWidth, h = frameHeight,
        row = row, col = col,
      }
      sheet.frameDurations[index] = 0.1
      index = index + 1
    end
  end

  sheet.count = index - 1
  return sheet
end

function Spritesheet.fromAseprite(asePath, image)
  local aseData = Aseprite.load(asePath)

  local sheet = Spritesheet.fromGrid(image, aseData.width, aseData.height)
  sheet.aseData = aseData
  sheet.frameDurations = {}

  -- Copy frame durations from Aseprite data
  for i, frame in ipairs(aseData.frames) do
    sheet.frameDurations[i] = frame.duration
  end

  -- Auto-define animations from Aseprite tags
  for name, tag in pairs(aseData.tags) do
    local durations = {}
    for i = tag.from, tag.to do
      durations[#durations + 1] = sheet.frameDurations[i] or 0.1
    end

    sheet.animations[name] = {
      from = tag.from,
      to = tag.to,
      direction = tag.direction,
      durations = durations,
      loop = true,
      pingPong = tag.direction == 2,
    }
  end

  return sheet
end

function Spritesheet.fromAsepriteJson(image, jsonData)
  local data = jsonData
  if type(jsonData) == "string" then
    error("fromAsepriteJson expects parsed JSON table")
  end

  local sheet = setmetatable({}, Spritesheet)
  sheet.image = image
  sheet.images = nil
  sheet.quads = {}
  sheet.frames = {}
  sheet.byName = {}
  sheet.animations = {}
  sheet.frameDurations = {}

  local imgW, imgH = image:getDimensions()
  -- Will set proper dimensions after parsing first frame
  local index = 1

  -- Handle both array and hash format from Aseprite
  local frameList = data.frames
  if not frameList[1] then
    -- Hash format, convert to array
    local temp = {}
    for name, frame in pairs(frameList) do
      frame.name = name
      temp[#temp + 1] = frame
    end
    table.sort(temp, function(a, b) return a.name < b.name end)
    frameList = temp
  end

  for _, frameData in ipairs(frameList) do
    local f = frameData.frame
    local quad = love.graphics.newQuad(f.x, f.y, f.w, f.h, imgW, imgH)

    sheet.quads[index] = quad
    sheet.frames[index] = {
      index = index,
      x = f.x, y = f.y,
      w = f.w, h = f.h,
      name = frameData.name,
    }
    sheet.frameDurations[index] = (frameData.duration or 100) / 1000

    if frameData.name then
      sheet.quads[frameData.name] = quad
      sheet.frames[frameData.name] = sheet.frames[index]
      sheet.byName[frameData.name] = index
    end

    index = index + 1
  end

  sheet.count = index - 1
  local fw = sheet.frames[1] and sheet.frames[1].w or 0
  local fh = sheet.frames[1] and sheet.frames[1].h or 0
  initDisplaySettings(sheet, fw, fh)

  -- Auto-define animations from tags
  if data.meta and data.meta.frameTags then
    for _, tag in ipairs(data.meta.frameTags) do
      local from = tag.from + 1
      local to = tag.to + 1
      local durations = {}
      for i = from, to do
        durations[#durations + 1] = sheet.frameDurations[i] or 0.1
      end

      sheet.animations[tag.name] = {
        from = from,
        to = to,
        direction = tag.direction,
        durations = durations,
        loop = true,
        pingPong = tag.direction == "pingpong",
      }
    end
  end

  return sheet
end

-- Define an animation from frame range
function Spritesheet:defineAnimation(name, fromFrame, toFrame, options)
  options = options or {}

  local durations = options.durations
  if not durations then
    durations = {}
    local defaultDur = options.frameDuration or 0.1
    for i = fromFrame, toFrame do
      durations[#durations + 1] = self.frameDurations[i] or defaultDur
    end
  end

  self.animations[name] = {
    from = fromFrame,
    to = toFrame,
    durations = durations,
    loop = options.loop ~= false,
    pingPong = options.pingPong or false,
  }

  return self
end

function Spritesheet:defineAnimationFrames(name, frameIndices, options)
  options = options or {}

  local durations = options.durations
  if not durations then
    durations = {}
    local defaultDur = options.frameDuration or 0.1
    for i, idx in ipairs(frameIndices) do
      durations[i] = self.frameDurations[idx] or defaultDur
    end
  end

  self.animations[name] = {
    frames = frameIndices,
    durations = durations,
    loop = options.loop ~= false,
    pingPong = options.pingPong or false,
  }

  return self
end

function Spritesheet:getAnimation(name)
  local animData = self.animations[name]
  if not animData then
    return nil
  end

  local frames
  if animData.frames then
    frames = animData.frames
  else
    frames = {}
    for i = animData.from, animData.to do
      frames[#frames + 1] = i
    end
  end

  return Animation.new({
    frames = frames,
    durations = animData.durations,
    loop = animData.loop,
    pingPong = animData.pingPong,
  })
end

function Spritesheet:getAnimations()
  local anims = {}
  for name in pairs(self.animations) do
    anims[name] = self:getAnimation(name)
  end
  return anims
end

function Spritesheet:hasAnimation(name)
  return self.animations[name] ~= nil
end

function Spritesheet:listAnimations()
  local names = {}
  for name in pairs(self.animations) do
    names[#names + 1] = name
  end
  return names
end

-- Set display size (how big to render, independent of source size)
function Spritesheet:setDisplaySize(width, height)
  self.displayWidth = width
  self.displayHeight = height or width
  -- Calculate scale from display size
  if self.frameWidth > 0 and self.frameHeight > 0 then
    self.scaleX = self.displayWidth / self.frameWidth
    self.scaleY = self.displayHeight / self.frameHeight
  end
  return self
end

-- Set scale factor
function Spritesheet:setScale(sx, sy)
  self.scaleX = sx
  self.scaleY = sy or sx
  self.displayWidth = self.frameWidth * self.scaleX
  self.displayHeight = self.frameHeight * self.scaleY
  return self
end

-- Set origin/anchor point (0-1 ratio or preset name)
function Spritesheet:setOrigin(x, y)
  if type(x) == "string" then
    local preset = ORIGIN_PRESETS[x]
    if preset then
      self.originX = preset[1]
      self.originY = preset[2]
    end
  else
    self.originX = x
    self.originY = y or x
  end
  return self
end

-- Get current display dimensions
function Spritesheet:getDisplaySize()
  local w = self.displayWidth or self.frameWidth
  local h = self.displayHeight or self.frameHeight
  return w, h
end

-- Get current scale
function Spritesheet:getScale()
  return self.scaleX, self.scaleY
end

-- Get origin in pixels for a given frame
function Spritesheet:getOriginPixels(frameId)
  local f = self:frame(frameId or 1)
  local w = self.displayWidth or (f and f.w) or self.frameWidth
  local h = self.displayHeight or (f and f.h) or self.frameHeight
  return w * self.originX, h * self.originY
end

function Spritesheet:quad(frameId)
  return self.quads[frameId]
end

function Spritesheet:frame(frameId)
  return self.frames[frameId]
end

function Spritesheet:imageFor(frameId)
  if self.images then
    return self.images[frameId]
  end
  return self.image
end

function Spritesheet:dimensions(frameId)
  local f = self:frame(frameId or 1)
  if f then
    return f.w, f.h
  end
  return self.frameWidth, self.frameHeight
end

-- Draw with display settings applied
-- sx, sy multiply the sheet's scale (pass nil to use sheet scale only)
function Spritesheet:draw(frameId, x, y, r, sx, sy, ox, oy)
  local quad = self:quad(frameId)
  local img = self:imageFor(frameId)
  if not quad or not img then return end

  local finalSx = self.scaleX * (sx or 1)
  local finalSy = self.scaleY * (sy or 1)

  -- If no offset provided, use origin
  if not ox and not oy then
    ox = self.frameWidth * self.originX
    oy = self.frameHeight * self.originY
  end

  love.graphics.draw(img, quad, x, y, r or 0, finalSx, finalSy, ox or 0, oy or 0)
end

-- Draw centered (ignores origin setting, always centers)
function Spritesheet:drawCentered(frameId, x, y, r, sx, sy)
  local f = self:frame(frameId)
  if f then
    local ox = f.w / 2
    local oy = f.h / 2
    local finalSx = self.scaleX * (sx or 1)
    local finalSy = self.scaleY * (sy or 1)
    local quad = self:quad(frameId)
    local img = self:imageFor(frameId)
    if quad and img then
      love.graphics.draw(img, quad, x, y, r or 0, finalSx, finalSy, ox, oy)
    end
  end
end

-- Draw raw (no display settings, direct control)
function Spritesheet:drawRaw(frameId, x, y, r, sx, sy, ox, oy)
  local quad = self:quad(frameId)
  local img = self:imageFor(frameId)
  if quad and img then
    love.graphics.draw(img, quad, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0)
  end
end

return Spritesheet
