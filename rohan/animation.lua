local Animation = {}
Animation.__index = Animation

--[[
Create an animation definition:

local idle = Animation.new({
  frames = {1, 2, 3, 2},
  frameDuration = 0.15,
  loop = true,
})

local attack = Animation.new({
  frames = {5, 6, 7, 8},
  durations = {0.1, 0.05, 0.2, 0.1},
  loop = false,
})

local walk = Animation.fromTag(spritesheet, "walk", 0.1)
]]

function Animation.new(def)
  local anim = setmetatable({}, Animation)
  anim.frames = def.frames or {1}
  anim.loop = def.loop ~= false
  anim.pingPong = def.pingPong or false

  anim.durations = {}
  local count = #anim.frames

  if def.durations then
    for i, d in ipairs(def.durations) do
      anim.durations[i] = d
    end
    local last = def.durations[#def.durations] or 0.1
    for i = #def.durations + 1, count do
      anim.durations[i] = last
    end
  else
    local d = def.frameDuration or 0.1
    for i = 1, count do
      anim.durations[i] = d
    end
  end

  anim.totalDuration = 0
  for _, d in ipairs(anim.durations) do
    anim.totalDuration = anim.totalDuration + d
  end

  return anim
end

function Animation.fromTag(spritesheet, tagName, frameDuration, options)
  options = options or {}
  local frames = spritesheet:getTagFrames(tagName)
  if not frames then
    error("Tag not found: " .. tostring(tagName))
  end

  return Animation.new({
    frames = frames,
    frameDuration = frameDuration or 0.1,
    loop = options.loop,
    pingPong = options.pingPong,
  })
end

function Animation.fromRange(startFrame, endFrame, frameDuration, options)
  options = options or {}
  local frames = {}
  for i = startFrame, endFrame do
    frames[#frames + 1] = i
  end

  return Animation.new({
    frames = frames,
    frameDuration = frameDuration or 0.1,
    loop = options.loop,
    pingPong = options.pingPong,
  })
end

function Animation:frameCount()
  return #self.frames
end

function Animation:frameAt(index)
  return self.frames[index]
end

function Animation:durationAt(index)
  return self.durations[index] or 0.1
end

local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer

--[[
Create an animation player:

local player = AnimPlayer.new({
  idle = idleAnimation,
  walk = walkAnimation,
  attack = attackAnimation,
}, "idle")

-- In update:
player:update(dt)

-- Get current frame to draw:
local frameId = player:frame()
spritesheet:draw(frameId, x, y)

-- Switch animation:
player:play("walk")
]]

function AnimPlayer.new(animations, initial)
  local player = setmetatable({}, AnimPlayer)
  player.animations = animations or {}
  player.current = initial
  player.frameIndex = 1
  player.elapsed = 0
  player.speed = 1.0
  player.paused = false
  player.finished = false
  player.direction = 1
  player.onFinish = nil
  player.onFrame = nil
  return player
end

function AnimPlayer:play(name, restart)
  if self.current == name and not restart then
    return self
  end

  self.current = name
  self.frameIndex = 1
  self.elapsed = 0
  self.finished = false
  self.direction = 1
  return self
end

function AnimPlayer:playIfNot(name)
  if self.current ~= name then
    self:play(name)
  end
  return self
end

function AnimPlayer:stop()
  self.paused = true
  return self
end

function AnimPlayer:resume()
  self.paused = false
  return self
end

function AnimPlayer:reset()
  self.frameIndex = 1
  self.elapsed = 0
  self.finished = false
  self.direction = 1
  return self
end

function AnimPlayer:setSpeed(s)
  self.speed = s
  return self
end

function AnimPlayer:update(dt)
  if self.paused or self.finished then
    return
  end

  local anim = self.animations[self.current]
  if not anim then
    return
  end

  self.elapsed = self.elapsed + dt * self.speed
  local dur = anim:durationAt(self.frameIndex)

  while self.elapsed >= dur do
    self.elapsed = self.elapsed - dur

    local oldFrame = self.frameIndex
    local count = anim:frameCount()

    if anim.pingPong then
      self.frameIndex = self.frameIndex + self.direction
      if self.frameIndex > count then
        self.direction = -1
        self.frameIndex = count - 1
      elseif self.frameIndex < 1 then
        if anim.loop then
          self.direction = 1
          self.frameIndex = 2
        else
          self.frameIndex = 1
          self.finished = true
        end
      end
    else
      self.frameIndex = self.frameIndex + 1
      if self.frameIndex > count then
        if anim.loop then
          self.frameIndex = 1
        else
          self.frameIndex = count
          self.finished = true
        end
      end
    end

    if self.onFrame and self.frameIndex ~= oldFrame then
      self.onFrame(self.frameIndex, oldFrame)
    end

    if self.finished then
      if self.onFinish then
        self.onFinish()
      end
      break
    end

    dur = anim:durationAt(self.frameIndex)
  end
end

function AnimPlayer:frame()
  local anim = self.animations[self.current]
  if not anim then return nil end
  return anim:frameAt(self.frameIndex)
end

function AnimPlayer:animation()
  return self.current
end

function AnimPlayer:is(name)
  return self.current == name
end

function AnimPlayer:isFinished()
  return self.finished
end

function AnimPlayer:progress()
  local anim = self.animations[self.current]
  if not anim or anim.totalDuration == 0 then return 0 end

  local elapsed = 0
  for i = 1, self.frameIndex - 1 do
    elapsed = elapsed + anim:durationAt(i)
  end
  elapsed = elapsed + self.elapsed

  return elapsed / anim.totalDuration
end

function AnimPlayer:isOnFrame(index)
  return self.frameIndex == index
end

function AnimPlayer:addAnimation(name, animation)
  self.animations[name] = animation
  return self
end

function AnimPlayer:clone()
  local clone = AnimPlayer.new(self.animations, self.current)
  clone.speed = self.speed
  return clone
end

return {
  Animation = Animation,
  AnimPlayer = AnimPlayer,
}

