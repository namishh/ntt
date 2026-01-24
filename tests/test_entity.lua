package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local EntityPool = require("entity")

testing:test("create a valid pool", function ()
  local pool = EntityPool:new()
  testing.assertNotNil(pool, "pool should not be nil")
end)

testing:test("creating a new entity", function ()
  local pool = EntityPool:new()
  local ent = pool:create()
  testing.assertNotNil(ent, "entity should not be nil")

  local entt = pool:create()
  testing.assertNotNil(entt, "entity 2 should also not be nil")

  testing.assertEqual(pool:getCount(), 2, "there are 2 entities")
end)

testing:report()
