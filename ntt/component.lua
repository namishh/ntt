local EntityPool = require("ntt.entity")

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

return ComponentStore
