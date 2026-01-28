package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local EntityPool = require("entity")
local ComponentStore = require("component")
local Commands = require("commands")

local function createMockWorld()
  local world = {
    entities = EntityPool:new(),
    components = {}
  }
  
  function world:registerComponent(name, options)
    local store = ComponentStore:new(name, options)
    self.components[name] = store
    return store
  end
  
  function world:spawn()
    return self.entities:create()
  end 
  
  return world
end

testing:test("Commands.new creates command buffer attached to world", function()
  local world = createMockWorld()
  local cmd = Commands.new(world)
  testing.assertNotNil(cmd)
  testing.assertEqual(world, cmd.world)
  testing.assertEqual(cmd, world.commands)
  testing.assertEqual(0, #cmd.spawns)
  testing.assertEqual(0, #cmd.despawns)
end)

testing:test("hasPending() and clear() track command state", function()
  local world = createMockWorld()
  world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  testing.assertEqual(false, cmd:hasPending(), "Should start empty")
  
  cmd:spawn():set("Position", { x = 1 })
  testing.assertEqual(true, cmd:hasPending(), "Should have pending after spawn")
  
  cmd:clear()
  testing.assertEqual(false, cmd:hasPending(), "Should be empty after clear")
end)

testing:test("spawn() creates entity with builder pattern", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local velStore = world:registerComponent("Velocity")
  local cmd = Commands.new(world)
  
  local builder = cmd:spawn()
    :set("Position", { x = 10, y = 20 })
    :set("Velocity", { dx = 1, dy = 2 })
  
  testing.assertNotNil(builder:getEntity())
  testing.assertEqual(1, #cmd.spawns)
  
  cmd:execute()
  
  local entity = builder:getEntity()
  testing.assertEqual(true, world.entities:isValid(entity))
  testing.assertEqual(10, posStore:get(entity).x)
  testing.assertEqual(1, velStore:get(entity).dx)
end)

testing:test("despawn() queues and executes entity removal", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local entity = world:spawn()
  posStore:add(entity, { x = 1 })
  
  cmd:despawn(entity)
  testing.assertEqual(true, world.entities:isValid(entity), "Should still be valid before execute")
  
  cmd:execute()
  testing.assertEqual(false, world.entities:isValid(entity), "Should be invalid after execute")
  testing.assertEqual(false, posStore:has(entity), "Component should be removed")
end)

testing:test("set() adds or updates components on existing entities", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local entity = world:spawn()
  
  cmd:set(entity, "Position", { x = 50, y = 100 })
  testing.assertEqual(false, posStore:has(entity), "Should not have component before execute")
  
  cmd:execute()
  testing.assertEqual(true, posStore:has(entity))
  testing.assertEqual(50, posStore:get(entity).x)
  
  cmd:set(entity, "Position", { x = 999 })
  cmd:execute()
  testing.assertEqual(999, posStore:get(entity).x, "Should update existing")
end)

testing:test("enable() and disable() toggle component state", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local entity = world:spawn()
  posStore:add(entity, { x = 1 })
  
  cmd:disable(entity, "Position")
  cmd:execute()
  testing.assertEqual(false, posStore:isEnabled(entity), "Should be disabled")
  
  cmd:enable(entity, "Position")
  cmd:execute()
  testing.assertEqual(true, posStore:isEnabled(entity), "Should be enabled")
end)

testing:test("commands work with builder entity references", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local builder = cmd:spawn():set("Position", { x = 1 })
  cmd:execute()
  
  cmd:set(builder, "Position", { x = 999 })
  cmd:execute()
  testing.assertEqual(999, posStore:get(builder:getEntity()).x)
  
  cmd:despawn(builder)
  cmd:execute()
  testing.assertEqual(false, world.entities:isValid(builder:getEntity()))
end)

testing:test("execute() skips invalid entities", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local entity = world:spawn()
  world.entities:destroy(entity)
  
  cmd:set(entity, "Position", { x = 1 })
  cmd:execute()
  testing.assertEqual(false, posStore:has(entity), "Should not add to invalid entity")
end)

testing:test("multiple spawns and despawns in single execute", function()
  local world = createMockWorld()
  local posStore = world:registerComponent("Position")
  local cmd = Commands.new(world)
  
  local existing = world:spawn()
  posStore:add(existing, { x = 0 })
  
  local b1 = cmd:spawn():set("Position", { x = 1 })
  local b2 = cmd:spawn():set("Position", { x = 2 })
  cmd:despawn(existing)
  
  cmd:execute()
  
  testing.assertEqual(true, world.entities:isValid(b1:getEntity()))
  testing.assertEqual(true, world.entities:isValid(b2:getEntity()))
  testing.assertEqual(false, world.entities:isValid(existing))
  testing.assertEqual(2, world.entities:getCount())
end)

testing:report()

