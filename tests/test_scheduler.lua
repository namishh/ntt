package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local World = require("world")

testing:test("Scheduler.new creates scheduler attached to world", function()
  local world = World.new()
  testing.assertNotNil(world.scheduler)
  testing.assertEqual(world, world.scheduler.world)
end)

testing:test("addSystem() adds system to phase with priority", function()
  local world = World.new()
  
  local sys1 = { run = function() end, priority = 10 }
  local sys2 = { run = function() end, priority = 5 }
  
  world.scheduler:addSystem(sys1, "update")
  world.scheduler:addSystem(sys2, "update")
  
  local systems = world.scheduler:getSystemsInPhase("update")
  testing.assertEqual(2, #systems)
  testing.assertEqual(sys2, systems[1], "Lower priority should run first")
  testing.assertEqual(sys1, systems[2])
end)

testing:test("addSystem() errors on invalid phase and duplicate names", function()
  local world = World.new()
  
  local ok1 = pcall(function()
    world.scheduler:addSystem({ run = function() end }, "invalidPhase")
  end)
  testing.assertEqual(false, ok1, "Should error on invalid phase")
  
  local sys = { name = "TestSystem", run = function() end }
  world.scheduler:addSystem(sys)
  
  local ok2 = pcall(function()
    world.scheduler:addSystem({ name = "TestSystem", run = function() end })
  end)
  testing.assertEqual(false, ok2, "Should error on duplicate name")
end)

testing:test("removeSystem() removes by name or object", function()
  local world = World.new()
  
  local sys = { name = "TestSystem", run = function() end }
  world.scheduler:addSystem(sys, "update")
  
  testing.assertEqual(true, world.scheduler:removeSystem("TestSystem"))
  testing.assertEqual(false, world.scheduler:removeSystem("TestSystem"))
  testing.assertEqual(0, #world.scheduler:getSystemsInPhase("update"))
end)

testing:test("enableSystem() and disableSystem() toggle system state", function()
  local world = World.new()
  
  local sys = { name = "TestSystem", run = function() end }
  world.scheduler:addSystem(sys, "update")
  
  world.scheduler:disableSystem("TestSystem")
  testing.assertEqual(false, world.scheduler:isSystemEnabled("TestSystem"))
  
  world.scheduler:enableSystem("TestSystem")
  testing.assertEqual(true, world.scheduler:isSystemEnabled("TestSystem"))
end)

testing:test("run() executes enabled systems in priority order", function()
  local world = World.new()
  local order = {}
  
  local sys1 = { name = "sys1", priority = 20, run = function() table.insert(order, 1) end }
  local sys2 = { name = "sys2", priority = 10, run = function() table.insert(order, 2) end }
  local sys3 = { name = "sys3", priority = 15, enabled = false, run = function() table.insert(order, 3) end }
  
  world.scheduler:addSystem(sys1, "update")
  world.scheduler:addSystem(sys2, "update")
  world.scheduler:addSystem(sys3, "update")
  
  world.scheduler:run("update", 0.016)
  
  testing.assertEqual(2, #order, "Should run 2 enabled systems")
  testing.assertEqual(2, order[1], "Lower priority first")
  testing.assertEqual(1, order[2])
end)

testing:test("runAll() and runUpdate()/runDraw() execute phases", function()
  local world = World.new()
  local phases = {}
  
  world.scheduler:addSystem({ name = "PreUpdateSys", run = function() table.insert(phases, "preUpdate") end }, "preUpdate")
  world.scheduler:addSystem({ name = "UpdateSys", run = function() table.insert(phases, "update") end }, "update")
  world.scheduler:addSystem({ name = "PostUpdateSys", run = function() table.insert(phases, "postUpdate") end }, "postUpdate")
  
  world.scheduler:runUpdate(0.016)
  
  testing.assertEqual(3, #phases)
  testing.assertEqual("preUpdate", phases[1])
  testing.assertEqual("update", phases[2])
  testing.assertEqual("postUpdate", phases[3])
end)

testing:test("getSystem() and getSystemNames() retrieve systems", function()
  local world = World.new()
  
  local sys1 = { name = "System1", run = function() end }
  local sys2 = { name = "System2", run = function() end }
  
  world.scheduler:addSystem(sys1, "update")
  world.scheduler:addSystem(sys2, "preUpdate")
  
  testing.assertEqual(sys1, world.scheduler:getSystem("System1"))
  testing.assertEqual(sys2, world.scheduler:getSystem("System2"))
  
  local names = world.scheduler:getSystemNames()
  testing.assertEqual(2, #names)
end)

testing:report()

