package.path = package.path .. ";../?.lua;../dio/?.lua"
local testing = require("t").new()
local World = require("world")
local Serialize = require("dio.serialize")

testing:test("saveWorld() serializes entities and components", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local e1 = world:spawn()
  world:set(e1, "Position", { x = 10, y = 20 })
  
  local data = Serialize.saveWorld(world)
  testing.assertNotNil(data.entities)
  testing.assertEqual(#data.entities, 1)
  testing.assertEqual(data.entities[1].components.Position.x, 10)
end)

testing:test("saveWorldToString() returns Lua code string", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local entity = world:spawn()
  world:set(entity, "Position", { x = 5 })
  
  local str = Serialize.saveWorldToString(world)
  testing.assertNotNil(str)
  testing.assertEqual(true, string.find(str, "return") ~= nil)
end)

testing:test("loadWorld() restores entities from data", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local data = {
    entities = {
      { components = { Position = { x = 100, y = 200 } } }
    }
  }
  
  local entities = Serialize.loadWorld(world, data)
  testing.assertEqual(#entities, 1)
  
  local pos = world:get(entities[1], "Position")
  testing.assertEqual(pos.x, 100)
  testing.assertEqual(pos.y, 200)
end)

testing:test("loadEntity() creates entity from component data", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local data = { components = { Position = { x = 42 } } }
  local entity = Serialize.loadEntity(world, data)
  
  testing.assertNotNil(entity)
  testing.assertEqual(world:get(entity, "Position").x, 42)
end)

testing:report()

