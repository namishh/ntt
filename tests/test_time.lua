package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local World = require("world")

testing:test("Time.new creates time attached to world", function()
  local world = World.new()
  testing.assertNotNil(world.time)
  testing.assertEqual(world, world.time.world)
  testing.assertEqual(1.0, world.time.scale)
  testing.assertEqual(false, world.time.paused)
end)

testing:test("update() tracks delta and elapsed time", function()
  local world = World.new()
  
  world.time:update(0.016)
  testing.assertEqual(0.016, world.time:getRawDelta())
  testing.assertEqual(0.016, world.time:getDelta())
  testing.assertEqual(0.016, world.time:getElapsed())
  testing.assertEqual(1, world.time:getFrameCount())
  
  world.time:update(0.032)
  testing.assertEqual(0.032, world.time:getRawDelta())
  testing.assertEqual(0.048, world.time:getElapsed())
  testing.assertEqual(2, world.time:getFrameCount())
end)

testing:test("pause() and resume() control time flow", function()
  local world = World.new()
  
  world.time:pause()
  testing.assertEqual(true, world.time:isPaused())
  
  world.time:update(0.016)
  testing.assertEqual(0, world.time:getDelta(), "Delta should be 0 when paused")
  testing.assertEqual(0, world.time:getElapsed(), "Elapsed should not increase when paused")
  
  world.time:resume()
  testing.assertEqual(false, world.time:isPaused())
  
  world.time:update(0.016)
  testing.assertEqual(0.016, world.time:getDelta())
end)

testing:test("setScale() affects delta time", function()
  local world = World.new()
  
  world.time:setScale(2.0)
  testing.assertEqual(2.0, world.time:getScale())
  
  world.time:update(0.016)
  testing.assertEqual(0.032, world.time:getDelta(), "Delta should be scaled")
  
  world.time:setScale(0.5)
  world.time:update(0.016)
  testing.assertEqual(0.008, world.time:getDelta(), "Delta should be scaled down")
  
  world.time:setScale(-1)
  testing.assertEqual(0, world.time:getScale(), "Should clamp to 0")
end)

testing:test("getFPS() calculates from rawDelta", function()
  local world = World.new()
  
  world.time:update(0.016)
  local fps = world.time:getFPS()
  testing.assertEqual(true, fps > 60 and fps < 63, "Should be ~62.5 FPS for 0.016s")
  
  world.time:update(0)
  testing.assertEqual(0, world.time:getFPS())
end)

testing:test("reset() clears elapsed and frame count", function()
  local world = World.new()
  
  world.time:update(0.016)
  world.time:update(0.016)
  
  world.time:reset()
  testing.assertEqual(0, world.time:getElapsed())
  testing.assertEqual(0, world.time:getRawElapsed())
  testing.assertEqual(0, world.time:getFrameCount())
end)

testing:test("createTimer() creates timer with callbacks", function()
  local world = World.new()
  local callbackCount = 0
  
  local timer = world.time:createTimer(1.0, function()
    callbackCount = callbackCount + 1
  end)
  
  testing.assertEqual(1.0, timer.duration)
  testing.assertEqual(1.0, timer.remaining)
  testing.assertEqual(false, timer.finished)
  
  timer:update(0.5)
  testing.assertEqual(0.5, timer.remaining)
  testing.assertEqual(0, callbackCount)
  
  timer:update(0.5)
  testing.assertEqual(1, callbackCount)
  testing.assertEqual(true, timer.finished)
end)

testing:test("timer with repeating resets automatically", function()
  local world = World.new()
  local count = 0
  
  local timer = world.time:createTimer(1.0, function()
    count = count + 1
  end, true)
  
  timer:update(1.0)
  testing.assertEqual(1, count)
  testing.assertEqual(false, timer.finished)
  
  timer:update(1.0)
  testing.assertEqual(2, count)
end)

testing:test("timer pause() and reset() work correctly", function()
  local world = World.new()
  local count = 0
  
  local timer = world.time:createTimer(1.0, function()
    count = count + 1
  end)
  
  timer:pause()
  timer:update(1.0)
  testing.assertEqual(0, count, "Should not fire when paused")
  
  timer:resume()
  timer:update(1.0)
  testing.assertEqual(1, count)
  
  timer:reset()
  testing.assertEqual(1.0, timer.remaining)
  testing.assertEqual(false, timer.finished)
end)

testing:report()

