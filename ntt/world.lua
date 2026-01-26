local EntityPool = require("ntt.entity")
local ComponentStore = require("ntt.component")

local World = {}
World.__index = World

function World.new(options)
  options = options or {}

  local world = setmetatable({}, World)
  world.entities = EntityPool:new()
  world.components = {}
  return world
end

function World:registerComponent(name, options)
  if self.components[name] then
    error("component " .. name .. " already registered")
  end

  local store = ComponentStore:new(name, options)
  self.components[name] = store
  self.componentList[#self.componentList + 1] = name
  return store
end

function World:getComponentStore(name)
  return self.components[name]
end

function World:spawn()
  return self.entities:create()
end

function World:despawn(entt)
  if not self.entities:isValid(entt) then
    return false
  end

  for _, store in ipairs(self.components) do
    store:remove(entt)
  end

  return self.entities:destroy(entt)
end

function World:enable(entity,component)
  local store = self.components[component]

  if store then
    store:enable(entity)
  end
end

function World:disable(entity,component)
  local store = self.components[component]

  if store then
    store:disable(entity)
  end
end

return World
