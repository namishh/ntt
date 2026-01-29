local Time = {}
Time.__index = Time

function Time.new(world)
  local t = setmetatable({}, Time)
  t.world = world
  t.scale = 1.0
  t.paused = false
  t.delta = 0
  t.rawDelta = 0
  t.elapsed = 0
  t.rawElapsed = 0
  t.frameCount = 0

  if world then
    world.time = t
  end

  return t
end

function Time:update(rawDT)
  self.rawDelta = rawDT
  self.rawElapsed = self.rawElapsed + rawDT
  self.frameCount = self.frameCount + 1

  if self.paused then
    self.delta = 0
  else
    self.delta = rawDT * self.scale
    self.elapsed = self.elapsed + self.delta
  end
end

function Time:pause()
  self.paused = true
end

function Time:resume()
  self.paused = false
end

function Time:isPaused()
  return self.paused
end

function Time:setScale(scale)
  self.scale = math.max(0, scale)
end

function Time:getScale()
  return self.scale
end

function Time:getDelta()
  return self.delta
end

function Time:getRawDelta()
  return self.rawDelta
end

function Time:getElapsed()
  return self.elapsed
end

function Time:getRawElapsed()
  return self.rawElapsed
end

function Time:getFrameCount()
  return self.frameCount
end

function Time:getFPS()
  if self.rawDelta > 0 then
    return 1 / self.rawDelta
  end
  return 0
end

function Time:reset()
  self.elapsed = 0
  self.rawElapsed = 0
  self.frameCount = 0
end

function Time:createTimer(duration, callback, repeating)
  return {
    duration = duration,
    remaining = duration,
    callback = callback,
    repeating = repeating or false,
    paused = false,
    finished = false,

    update = function(timer, dt)
      if timer.paused or timer.finished then
        return
      end

      timer.remaining = timer.remaining - dt

      if timer.remaining <= 0 then
        if timer.callback then
          timer.callback()
        end

        if timer.repeating then
          timer.remaining = timer.duration + timer.remaining
        else
          timer.finished = true
        end
      end
    end,
    reset = function(timer)
      timer.remaining = timer.duration
      timer.finished = false
    end,

    pause = function(timer)
      timer.paused = true
    end,

    resume = function(timer)
      timer.paused = false
    end
  }
end

return Time
