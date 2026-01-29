package.path = package.path .. ";../?.lua;../dio/?.lua"
local testing = require("t").new()
local World = require("world")

testing:test("Query.new creates query with empty withTable/withoutTable", function()
  local world = World.new()
  local query = world:query()
  testing.assertNotNil(query, "Query should not be nil")
  testing.assertEqual(world, query.world, "Query should reference the world")
  testing.assertEqual(0, #query.withTable, "withTable should be empty")
  testing.assertEqual(0, #query.withoutTable, "withoutTable should be empty")
end)

testing:test("with() and without() add components and support chaining", function()
  local world = World.new()
  local query = world:query()
    :with("Position", "Velocity")
    :without("Dead", "Disabled")
  
  testing.assertEqual(2, #query.withTable, "withTable should have 2 elements")
  testing.assertEqual("Position", query.withTable[1])
  testing.assertEqual("Velocity", query.withTable[2])
  testing.assertEqual(2, #query.withoutTable, "withoutTable should have 2 elements")
  testing.assertEqual("Dead", query.withoutTable[1])
end)

testing:test("iter() iterates over matching entities with component data", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  local velStore = world:registerComponent("Velocity")
  
  local e1 = world:spawn()
  local e2 = world:spawn()
  posStore:add(e1, { x = 10, y = 20 })
  velStore:add(e1, { dx = 1, dy = 2 })
  posStore:add(e2, { x = 30, y = 40 })
  velStore:add(e2, { dx = 3, dy = 4 })
  
  local count = 0
  local sumX = 0
  for entity, pos, vel in world:query():with("Position", "Velocity"):iter() do
    testing.assertNotNil(entity)
    testing.assertNotNil(pos)
    testing.assertNotNil(vel)
    sumX = sumX + pos.x
    count = count + 1
  end
  testing.assertEqual(2, count, "Should iterate over 2 entities")
  testing.assertEqual(40, sumX, "Sum of x should be 40")
end)

testing:test("iter() filters by without and disabled components", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  local deadStore = world:registerComponent("Dead", { isTag = true })
  
  local alive = world:spawn()
  local dead = world:spawn()
  local disabled = world:spawn()
  
  posStore:add(alive, { x = 1 })
  posStore:add(dead, { x = 2 })
  posStore:add(disabled, { x = 3 })
  deadStore:add(dead)
  posStore:disable(disabled)
  
  local count = 0
  for entity in world:query():with("Position"):without("Dead"):iter() do
    count = count + 1
    testing.assertEqual(alive, entity, "Should only find alive entity")
  end
  testing.assertEqual(1, count, "Should find only 1 entity")
end)

testing:test("iter() errors when no with components", function()
  local world = World.new()
  local ok = pcall(function() world:query():iter() end)
  testing.assertEqual(false, ok, "Should error without with components")
end)

testing:test("first() returns first match or nil", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  
  local result = world:query():with("Position"):first()
  testing.assertEqual(nil, result, "Should return nil when empty")
  
  local entity = world:spawn()
  posStore:add(entity, { x = 42, y = 99 })
  
  local e, pos = world:query():with("Position"):first()
  testing.assertEqual(entity, e)
  testing.assertEqual(42, pos.x)
end)

testing:test("count() and collect() aggregate results", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  local deadStore = world:registerComponent("Dead", { isTag = true })
  
  for i = 1, 5 do
    local e = world:spawn()
    posStore:add(e, { x = i })
    if i > 3 then deadStore:add(e) end
  end
  
  local aliveQuery = world:query():with("Position"):without("Dead")
  testing.assertEqual(3, aliveQuery:count(), "Should count 3 alive")
  testing.assertEqual(3, #aliveQuery:collect(), "Should collect 3 alive")
  
  local allQuery = world:query():with("Position")
  testing.assertEqual(5, allQuery:count(), "Should count all 5")
end)

testing:test("any() returns true/falsy based on matches", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  
  local emptyQuery = world:query():with("Position")
  testing.assertEqual(true, not emptyQuery:any(), "Should be falsy when empty")
  
  posStore:add(world:spawn(), { x = 1 })
  local hasQuery = world:query():with("Position")
  testing.assertEqual(true, hasQuery:any(), "Should be true with entities")
end)

testing:test("each() calls callback for each match", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  local velStore = world:registerComponent("Velocity")
  
  local e1 = world:spawn()
  local e2 = world:spawn()
  posStore:add(e1, { x = 10 })
  velStore:add(e1, { dx = 5 })
  posStore:add(e2, { x = 20 })
  velStore:add(e2, { dx = 10 })
  
  local sum = 0
  world:query():with("Position", "Velocity"):each(function(entity, pos, vel)
    sum = sum + pos.x + vel.dx
  end)
  testing.assertEqual(45, sum, "Sum should be 10+5+20+10=45")
end)

testing:test("query with tag components", function()
  local world = World.new()
  local posStore = world:registerComponent("Position")
  local playerStore = world:registerComponent("Player", { isTag = true })
  
  local player = world:spawn()
  local npc = world:spawn()
  posStore:add(player, { x = 1 })
  posStore:add(npc, { x = 2 })
  playerStore:add(player)
  
  local e, pos, isPlayer = world:query():with("Position", "Player"):first()
  testing.assertEqual(player, e)
  testing.assertEqual(1, pos.x)
  testing.assertEqual(true, isPlayer, "Tag should return true")
  testing.assertEqual(1, world:query():with("Position", "Player"):count())
end)

testing:report()
