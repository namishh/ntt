local ComponentStore = {}
ComponentStore.__index = ComponentStore

function ComponentStore:new(name, options)
  options = options or {}
  local store = setmetatable({}, ComponentStore)
  store.name = name

  -- storing shi in sparse sets
  store.dense = {} -- dense[dataindex] = entityid
  store.sparse = {} -- sparse[entityindex] = denseindex
  store.count = 0
  store.data = {} -- data[denseindex] = componentData

  -- entity can have a compoenent which can be disabled, for example colliision component
  store.disabled = {} -- disabled[enetityindex] = bool

  store.isTag = options.isTag or false
  store.default = options.default
  store.serialize = options.serialize ~= false

  return store
end


local INDEX_MASK = bit.lshift(1, 20) - 1  -- 0xFFFFF 

function ComponentStore:add(entity, componentData)
  local index = bit.band(entity, INDEX_MASK)
  -- if comp alr there just update it 
  if self.sparse[index] then
    if not self.isTag then
      self.data[self.sparse[index]] = componentData
    end
    return
  end

  self.count = self.count + 1
  local denseIndex = self.count
  self.sparse[index] = denseIndex
  self.dense[denseIndex] = entity

  if not self.isTag then
    if componentData == nil and self.default then
      componentData = {}
      for k, v in pairs(self.default) do
          componentData[k] = v
      end
    end
    self.data[denseIndex] = componentData or {}
  end
end

function ComponentStore:get(entity)
  local index = bit.band(entity, INDEX_MASK)
  local denseIndex = self.sparse[index]
  if not denseIndex then
      return nil
  end
  if self.isTag then
      return true
  end
  return self.data[denseIndex]
end

function ComponentStore:has(entity)
  local index = bit.band(entity, INDEX_MASK)
  return self.sparse[index] ~= nil
end

function ComponentStore:remove(entity)
  local index = bit.band(entity, INDEX_MASK)
  local denseIndex = self.sparse[index]
  if not denseIndex then
    return false
  end
  local lastDenseIndex = self.count
  if denseIndex ~= lastDenseIndex then
    local lastEntity = self.dense[lastDenseIndex]
    local lastIndex = bit.band(lastEntity, INDEX_MASK)
    self.dense[denseIndex] = lastEntity
    self.sparse[lastIndex] = denseIndex
    if not self.isTag then
      self.data[denseIndex] = self.data[lastDenseIndex]
    end
  end

  self.dense[lastDenseIndex] = nil
  self.sparse[index] = nil
  self.disabled[index] = nil
  if not self.isTag then
    self.data[lastDenseIndex] = nil
  end
  self.count = self.count - 1
  return true
end

function ComponentStore:enable(entity)
  local index = bit.band(entity, INDEX_MASK)
  if self.sparse[index] then
    self.disabled[index] = nil
  end
end

function ComponentStore:disable(entity)
  local index = bit.band(entity, INDEX_MASK)
  if self.sparse[index] then
    self.disabled[index] = true
  end
end

function ComponentStore:isEnabled(entity)
  local index = bit.band(entity, INDEX_MASK)
  if not self.sparse[index] then
    return false
  end
  return not self.disabled[index]
end

return ComponentStore
