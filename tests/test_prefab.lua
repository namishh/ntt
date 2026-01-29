package.path = package.path .. ";../?.lua;../dio/?.lua"
local testing = require("t").new()
local World = require("world")
local prefabModule = require("dio.prefab")
local Prefab = prefabModule.Prefab
local PrefabRegistry = prefabModule.PrefabRegistry

testing:test("Prefab.new() creates prefab from definition", function()
  local def = {
    name = "Player",
    components = {
      Position = { x = 0, y = 0 }
    }
  }
  
  local prefab = Prefab.new(def)
  testing.assertNotNil(prefab)
  testing.assertEqual(prefab.name, "Player")
end)

testing:test("Prefab:spawn() creates entity with components", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local prefab = Prefab.new({
    components = { Position = { x = 10, y = 20 } }
  })
  
  local entity = prefab:spawn(world)
  testing.assertNotNil(entity)
  testing.assertEqual(world:get(entity, "Position").x, 10)
end)

testing:test("Prefab:spawn() applies overrides", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local prefab = Prefab.new({
    components = { Position = { x = 0, y = 0 } }
  })
  
  local entity = prefab:spawn(world, { Position = { x = 99 } })
  testing.assertEqual(world:get(entity, "Position").x, 99)
  testing.assertEqual(world:get(entity, "Position").y, 0)
end)

testing:test("PrefabRegistry manages prefabs", function()
  local registry = PrefabRegistry.new()
  
  registry:add("player", {
    components = { Position = { x = 0 } }
  })
  
  testing.assertEqual(true, registry:has("player"))
  testing.assertNotNil(registry:get("player"))
end)

testing:test("PrefabRegistry:spawn() creates entity from prefab", function()
  local world = World.new()
  world:registerComponent("Position")
  
  local registry = PrefabRegistry.new()
  registry:add("player", {
    components = { Position = { x = 5 } }
  })
  
  local entity = registry:spawn("player", world)
  testing.assertNotNil(entity)
  testing.assertEqual(world:get(entity, "Position").x, 5)
end)

testing:report()

