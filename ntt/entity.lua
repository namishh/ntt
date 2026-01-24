-- local bit is required for luajit
local bit = require("bit")

-- the base entitypool. tracks generation.
-- entity_id = (generation << 20) | index
-- max_entities = 1,048,576
-- max_gens before wrapping = 4096

local EntityPool = {}
EntityPool.__index = EntityPool

local INDEX_BITS = 20
-- 0xFFFF = 0000 1111 1111 1111 1111 1111
-- keeps lower 20 bits.
local INDEX_MASK = bit.lshift(1, INDEX_BITS) - 1  -- 0xFFFFF 
local GENERATION_MASK = 0xFFF             -- 12 bits
--local MAX_GENERATION = 4096

function EntityPool:new()
    local pool = setmetatable({}, EntityPool)
    pool.generations = {}
    pool.alive = {}
    pool.freeList = {}
    pool.nextIndex = 0
    pool.count = 0
    return pool
end

function EntityPool:getIndex(entity)
  -- entity & index_mask
  return bit.band(entity, INDEX_MASK)
end

function EntityPool:getGeneration(entity)
  -- (entity >> index_bits) & generation_mask
  return bit.band(bit.rshift(entity, INDEX_BITS), GENERATION_MASK)
end

function EntityPool:create()
  local index
  local freecount = #self.freeList

  if freecount > 0 then
    index = self.freeList[freecount]
    self.freeList[freecount] = nil
  else
    index = self.nextIndex
    self.nextIndex = self.nextIndex + 1
    self.generations[index] = 0
  end

  self.alive[index] = true
  self.count = self.count + 1
  return bit.bor(bit.lshift(self.generations[index], INDEX_BITS), index)
end

function EntityPool:getCount()
    return self.count
end

-- does this entity id still refer to an id which is currently alive
function EntityPool:isValid(ent)
  if ent == nil then
    return false
  end

  local index = self:getIndex(ent)
  local generation = self:getGeneration(ent)

  if index >= self.nextIndex then
    return false
  end

  return self.generations[index] == generation and self.alive[index] == true
end

return EntityPool
