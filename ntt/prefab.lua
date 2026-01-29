local Prefab = {}
Prefab.__index = Prefab

function Prefab.new(def)
  local pref = setmetatable({}, Prefab)
  pref.components = def.components or {}
  pref.tags = def.tags or {}
  pref.name = def.name
  return pref
end

local function deepCopy(t)
  if type(t) ~= "table" then return t end
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = deepCopy(v)
  end
  return copy
end

local function merge(base, override)
  if not override then return deepCopy(base) end
  local result = deepCopy(base)
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      for k2, v2 in pairs(v) do
        result[k][k2] = v2
      end
    else
      result[k] = v
    end
  end
  return result
end

function Prefab:spawn(world, overrides)
  local entity = world:spawn()
  for comp, compdata in pairs(self.components) do
    local data = compdata
    if overrides and overrides[comp] then
      data = merge(compdata, overrides[comp])
    else
      data = deepCopy(compdata)
    end

    if data and type(data.clone) == "function" then
      data = data:clone()
    end

    local store = world.components[comp]
    if store then
      store:add(entity, data)
    end
  end

  if overrides then
    for compName, compData in pairs(overrides) do
      if not self.components[compName] then
        local store = world.components[compName]
        if store then
          store:add(entity, deepCopy(compData))
        end
      end
    end
  end

  if self.init then
    self.init(entity, world)
  end

  return entity
end

local PrefabRegistry = {}
PrefabRegistry.__index = PrefabRegistry

function PrefabRegistry.new()
  local registry = setmetatable({}, PrefabRegistry)
  registry.prefabs = {}
  return registry
end

function PrefabRegistry:add(name, prefab)
    if type(def.spawn) == "function" then
        self.prefabs[name] = def
    else
        self.prefabs[name] = Prefab.new(def)
    end

    return self
end

function PrefabRegistry:get(name)
    return self.prefabs[name]
end

function PrefabRegistry:spawn(name, world, overrides)
    local prefab = self.prefabs[name]
    if not prefab then
        error("Prefab not found: " .. tostring(name))
    end
    return prefab:spawn(world, overrides)
end

function PrefabRegistry:has(name)
    return self.prefabs[name] ~= nil
end

function PrefabRegistry:names()
    local names = {}
    for name in pairs(self.prefabs) do
        names[#names + 1] = name
    end
    return names
end

function PrefabRegistry:loadTable(t)
    for name, def in pairs(t) do
        self:register(name, def)
    end
    return self
end


return {
    Prefab = Prefab
    PrefabRegistry = PrefabRegistry
}