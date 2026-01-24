package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local EntityPool = require("entity")

testing:test("create a valid pool", function ()
  local pool = EntityPool.new()
  testing.assertNotNil(pool, "pool should not be nil")
end)

testing:test("creating a new entity", function ()
  local pool = EntityPool.new()
  local ent = pool:create()
  testing.assertNotNil(ent, "entity should not be nil")

  local entt = pool:create()
  testing.assertNotNil(entt, "entity 2 should also not be nil")

  testing.assertEqual(pool:getCount(), 2, "there are 2 entities")
end)

testing:test("extracts correct index", function()
  local pool = EntityPool.new()
  local e1 = pool:create()
  local e2 = pool:create()
  local e3 = pool:create()

  testing.assertEqual(0, pool:getIndex(e1), "entity index should be 0")
  testing.assertEqual(1, pool:getIndex(e2), "entity index should be 1")
  testing.assertEqual(2, pool:getIndex(e3), "entity index should be 2")
end)

testing:test("isvalid tests", function()
  local pool = EntityPool.new()
  local e1 = pool:create()
  local e2 = pool:create()

  testing.assertEqual(true, pool:isValid(e1))
  testing.assertEqual(true, pool:isValid(e2))
  testing.assertEqual(false, pool:isValid(1000))
  testing.assertEqual(false, pool:isValid(nil))
end)

testing:report()
