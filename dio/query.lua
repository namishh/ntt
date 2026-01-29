local bit = require("bit")

local Query = {}
Query.__index = Query

local INDEX_MASK = bit.lshift(1, 20) - 1

function Query.new(world)
  local query = setmetatable({}, Query)
  query.world = world
  query.withTable = {}
  query.withoutTable = {}
  return query
end

function Query:with(...)
  local args = {...}
  for _, name in ipairs(args) do
    self.withTable[#self.withTable + 1] = name
  end

  return self
end

function Query:without(...)
  local args = {...}
  for _, name in ipairs(args) do
    self.withoutTable[#self.withoutTable + 1] = name
  end

  return self
end

function Query:_findSmallestStore()
  local smallest = nil
  local smallestCount = math.huge

  for _, name in ipairs(self.withTable) do
    local store = self.world.components[name]
    if not store then
      error("Component '" .. name .. "' not registered")
    end
    local count = store:getCount()
    if count < smallestCount then
      smallest = store
      smallestCount = count
    end
  end

  return smallest
end

function Query:_passesFilters(entity, entityIndex)
  for _, name in ipairs(self.withTable) do
    local store = self.world.components[name]
    if not store:has(entity) then
      return false
    end
    if store:isDisabledByIndex(entityIndex) then
      return false
    end
  end
  for _, name in ipairs(self.withoutTable) do
    local store = self.world.components[name]
    if store and store:has(entity) then
      return false
    end
  end
  return true
end

function Query:iter()
  local world = self.world
  local withComponents = self.withTable
  local withoutComponents = self.withoutTable
  if #withComponents == 0 then
    error("Query must have at least one 'with' component")
  end
  local baseStore = self:_findSmallestStore()
  if not baseStore then
    return
  end
  local dense, count = baseStore:getDenseArray()
  local stores = {}
  for i, name in ipairs(withComponents) do
    stores[i] = world.components[name]
  end
  local excludeStores = {}
  for i, name in ipairs(withoutComponents) do
    excludeStores[i] = world.components[name]
  end
  local i = 0
  local numWith = #withComponents
  local numWithout = #withoutComponents


  return function()
    while true do
      i = i + 1
      if i > count then
        return nil
      end

      local entity = dense[i]
      if not entity then
        return nil
      end

      local entityIndex = bit.band(entity, INDEX_MASK)

      if world.entities:isValid(entity) then
        local valid = true

        for j = 1, numWith do
          local store = stores[j]
          if not store:has(entity) or store:isDisabledByIndex(entityIndex) then
            valid = false
            break
          end
        end

        if valid then
          for j = 1, numWithout do
            local store = excludeStores[j]
            if store and store:has(entity) then
              valid = false
              break
            end
          end
        end

        if valid then
          local results = { entity }
          for j = 1, numWith do
            results[j + 1] = stores[j]:get(entity)
          end

          return unpack(results)
        end
      end
    end
  end
end

function Query:first()
  local next = self:iter()
  if not next then
    return
  end
  return next()
end


function Query:count()
    local count = 0
    for _ in self:iter() do
        count = count + 1
    end
    return count
end

function Query:collect()
    local results = {}
    for entity in self:iter() do
        results[#results + 1] = entity
    end
    return results
end


function Query:any()
  local next = self:iter()
  if not next then
    return
  end
  return next() ~= nil
end


function Query:each(fn)
    local next = self:iter()
    if not next then
      return
    end
    while true do
        local results = { next() }
        if results[1] == nil then
            return
        end
        fn(unpack(results))
    end
end

return Query
