local Commands = {}
Commands.__index = Commands

function Commands.new(world)
  local cmd = setmetatable({}, Commands)
  cmd.world = world
  cmd.spawns = {}
  cmd.despawns = {}
  cmd.sets = {}
  cmd.removes = {}
  cmd.enables = {}
  cmd.disables = {}

  world.commands = cmd
  return cmd
end

function Commands:clear()
  self.spawns = {}
  self.despawns = {}
  self.sets = {}
  self.removes = {}
  self.enables = {}
  self.disables = {}
end

function Commands:hasPending()
  return #self.spawns > 0 or #self.despawns > 0 or #self.sets > 0 or #self.removes > 0 or #self.enables > 0 or #self.disables > 0
end

function Commands:spawn()
  local entity = self.world.entities:create()
  local spawnData = {
    entity = entity,
    components = {}
  }

  self.spawns[#self.spawns + 1] = spawnData
  local builder = {
    _cmd = self,
    _entity = entity,
    _spawnData = spawnData
  }
  function builder:set(componentName, data)
    self._spawnData.components[componentName] = data or {}
    return self
  end
  function builder:getEntity()
    return self._entity
  end

  setmetatable(builder, {
    __tostring = function() return tostring(entity) end,
    __eq = function(a, b)
      if type(b) == "table" and b._entity then
        return a._entity == b._entity
      end
      return a._entity == b
    end
  })
  return builder
end


function Commands:despawn(entity)
  if type(entity) == "table" and entity._entity then
    entity = entity._entity
  end
  self.despawns[#self.despawns + 1] = entity
end

function Commands:set(entity, componentName, data)
  if type(entity) == "table" and entity._entity then
    entity = entity._entity
  end
  self.sets[#self.sets + 1] = {
    entity = entity,
    component = componentName,
    data = data or {}
  }
end

function Commands:enable(entity, componentName)
  if type(entity) == "table" and entity._entity then
    entity = entity._entity
  end
  self.enables[#self.enables + 1] = {
    entity = entity,
    component = componentName
  }
end

function Commands:disable(entity, componentName)
  if type(entity) == "table" and entity._entity then
    entity = entity._entity
  end
  self.disables[#self.disables + 1] = {
    entity = entity,
    component = componentName
  }
end

function Commands:execute()
  local world = self.world
  for _, spawn in ipairs(self.spawns) do
    local entity = spawn.entity
    if world.entities:isValid(entity) then
      for compName, compData in pairs(spawn.components) do
        local store = world.components[compName]
        if store then
          store:add(entity, compData)
        end
      end
    end
  end

  for _, cmd in ipairs(self.sets) do
    if world.entities:isValid(cmd.entity) then
      local store = world.components[cmd.component]
      if store then
        store:add(cmd.entity, cmd.data)
      end
    end
  end
  for _, cmd in ipairs(self.removes) do
    if world.entities:isValid(cmd.entity) then
      local store = world.components[cmd.component]
      if store then
        store:remove(cmd.entity)
      end
    end
  end

  for _, cmd in ipairs(self.enables) do
    if world.entities:isValid(cmd.entity) then
      local store = world.components[cmd.component]
      if store then
        store:enable(cmd.entity)
      end
    end
  end

  for _, cmd in ipairs(self.disables) do
    if world.entities:isValid(cmd.entity) then
      local store = world.components[cmd.component]
      if store then
        store:disable(cmd.entity)
      end
    end
  end

  for _, entity in ipairs(self.despawns) do
    if world.entities:isValid(entity) then
      for _, store in pairs(world.components) do
        store:remove(entity)
      end
      world.entities:destroy(entity)
    end
  end

  self:clear()
end

return Commands
