package.path = package.path .. ";../?.lua;../dio/?.lua"
local testing = require("t").new()
local World = require("world")
local Debug = require("dio.debug")

testing:test("inspectEntity() returns entity info with components", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  
  local entity = world:spawn()
  posStore:add(entity, { x = 10, y = 20 })
  
  local info = Debug.inspectEntity(world, entity)
  testing.assertNotNil(info)
  testing.assertEqual(info.entity, entity)
  testing.assertNotNil(info.components.Position)
  testing.assertEqual(info.components.Position.data.x, 10)
end)

testing:test("inspectEntity() returns nil for invalid entity", function()
  local world = World.new()
  local info, err = Debug.inspectEntity(world, 99999)
  testing.assertEqual(info, nil)
  testing.assertNotNil(err)
end)

testing:test("componentStats() returns component statistics", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  
  world:spawn()
  posStore:add(world:spawn(), { x = 1 })
  
  local stats = Debug.componentStats(world, "Position")
  testing.assertNotNil(stats)
  testing.assertEqual(stats.count, 1)
end)

testing:test("allStats() returns world statistics", function()
  local world = World.new()
  world:registerComponent("Position")
  
  world:spawn()
  
  local stats = Debug.allStats(world)
  testing.assertNotNil(stats)
  testing.assertEqual(stats.entityCount, 1)
end)

testing:report()

