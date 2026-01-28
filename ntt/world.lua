local EntityPool = require("ntt.entity")
local ComponentStore = require("ntt.component")
local Query = require("ntt.query")
local Events = require("ntt.events")
local Scheduler = require("ntt.scheduler")
local Time = require("ntt.time")
local Commands = require("ntt.commands")

local World = {}
World.__index = World

function World.new(options)
  options = options or {}

  local world = setmetatable({}, World)
  world.entities = EntityPool:new()
  world.components = {}
  world.componentList = {}
  world.commands = Commands.new(world)
  world.events = Events.new(world)
  world.scheduler = Scheduler.new(world)
  world.time = Time.new(world)
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
  if self.commands then
    self.commands:despawn(entt)
  else
    if not self.entities:isValid(entt) then
      return false
    end

    for _, store in ipairs(self.components) do
      store:remove(entt)
    end

    return self.entities:destroy(entt)
  end
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


function World:isEnabled(entity,component)
  local store = self.components[component]

  if store then
    return store:isEnabled(entity)
  end

  return false
end

function World:getEntityCount()
  return self.entities:getCount()
end

function World:query()
  return Query.new(self)
end

function World:addSystem(system, phase, priority)
  if self.scheduler then
    self.scheduler:addSystem(system, phase, priority)
  else
    error("Scheduler not initialized. Set world.scheduler first.")
  end
end

function World:removeSystem(system)
  if self.scheduler then
    self.scheduler:removeSystem(system)
  end
end

function World:update(dt)
  local scaledDt = dt
  if self.time then
    self.time:update(dt)
    scaledDt = self.time:getDelta()
  end
  if self.scheduler then
    self.scheduler:run("preUpdate", scaledDt)
    self.scheduler:run("update", scaledDt)
    self.scheduler:run("postUpdate", scaledDt)
  end
  self:flush()
  if self.events then
    self.events:clear()
  end
end

function World:draw()
  local dt = 0
  if self.time then
    dt = self.time:getDelta()
  end

  if self.scheduler then
    self.scheduler:run("preDraw", dt)
    self.scheduler:run("draw", dt)
  end
end

function World:iterateEntities()
  return self.entities:iterate()
end

function World:flush()
  if self.commands then
    self.commands:execute()
  end
end

function World:clearEntities()
  for entity in self.entities:iterate() do
    for _, store in pairs(self.components) do
      store:remove(entity)
    end
    self.entities:destroy(entity)
  end
  if self.commands then
    self.commands:clear()
  end
  if self.time then
    self.time:reset()
  end
end

function World:hasComponent(name)
  return self.components[name] ~= nil
end

function World:set(entity, componentName, data)
  local store = self.components[componentName]
  if store then
    store:add(entity, data)
  end
end

function World:get(entity, componentName)
  local store = self.components[componentName]
  if store then
    return store:get(entity)
  end
  return nil
end

function World:has(entity, componentName)
  local store = self.components[componentName]
  if store then
    return store:has(entity)
  end
  return false
end

function World:remove(entity, componentName)
  local store = self.components[componentName]
  if store then
    return store:remove(entity)
  end
  return false
end

return World
