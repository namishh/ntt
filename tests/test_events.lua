package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local World = require("world")

testing:test("Events.new creates events attached to world", function()
  local world = World.new()
  testing.assertNotNil(world.events)
  testing.assertEqual(world, world.events.world)
end)

testing:test("emit() queues events and calls listeners immediately", function()
  local world = World.new()
  local callCount = 0
  local receivedData = nil
  
  world.events:on("test", function(data)
    callCount = callCount + 1
    receivedData = data
  end)
  
  world.events:emit("test", { value = 42 })
  
  testing.assertEqual(1, callCount, "Listener should be called")
  testing.assertEqual(42, receivedData.value)
  testing.assertEqual(1, world.events:count("test"))
end)

testing:test("poll() iterates over queued events", function()
  local world = World.new()
  
  world.events:emit("test", { x = 1 })
  world.events:emit("test", { x = 2 })
  world.events:emit("test", { x = 3 })
  
  local count = 0
  local sum = 0
  for event in world.events:poll("test") do
    count = count + 1
    sum = sum + event.x
  end
  
  testing.assertEqual(3, count)
  testing.assertEqual(6, sum)
end)

testing:test("getAll() and has() check event queues", function()
  local world = World.new()
  
  local hasBefore = world.events:has("test")
  testing.assertEqual(false, hasBefore == true, "Should not have events initially")
  testing.assertEqual(0, #world.events:getAll("test"))
  
  world.events:emit("test", { a = 1 })
  world.events:emit("test", { a = 2 })
  
  testing.assertEqual(true, world.events:has("test"))
  testing.assertEqual(2, #world.events:getAll("test"))
  testing.assertEqual(2, world.events:count("test"))
end)

testing:test("clearType() and clear() remove events", function()
  local world = World.new()
  
  world.events:emit("test1", {})
  world.events:emit("test2", {})
  
  world.events:clearType("test1")
  testing.assertEqual(0, world.events:count("test1"))
  testing.assertEqual(1, world.events:count("test2"))
  
  world.events:emit("test1", {})
  world.events:clear()
  testing.assertEqual(0, world.events:count("test1"))
  testing.assertEqual(0, world.events:count("test2"))
end)

testing:test("on() and off() manage listeners with unsubscribe", function()
  local world = World.new()
  local count1 = 0
  local count2 = 0
  
  local callback1 = function() count1 = count1 + 1 end
  local callback2 = function() count2 = count2 + 1 end
  
  local unsubscribe = world.events:on("test", callback1)
  world.events:on("test", callback2)
  
  world.events:emit("test")
  testing.assertEqual(1, count1)
  testing.assertEqual(1, count2)
  
  unsubscribe()
  world.events:emit("test")
  testing.assertEqual(1, count1, "Should not increment after unsubscribe")
  testing.assertEqual(2, count2)
  
  world.events:off("test", callback2)
  world.events:emit("test")
  testing.assertEqual(2, count2, "Should not increment after off")
end)

testing:test("offAll() removes all listeners for event type", function()
  local world = World.new()
  local count = 0
  
  world.events:on("test", function() count = count + 1 end)
  world.events:on("test", function() count = count + 1 end)
  
  world.events:emit("test")
  testing.assertEqual(2, count)
  
  world.events:offAll("test")
  world.events:emit("test")
  testing.assertEqual(2, count, "Should not increment after offAll")
end)

testing:test("getEventTypes() returns types with queued events", function()
  local world = World.new()
  
  world.events:emit("type1", {})
  world.events:emit("type2", {})
  
  local types = world.events:getEventTypes()
  testing.assertEqual(2, #types)
end)

testing:report()

