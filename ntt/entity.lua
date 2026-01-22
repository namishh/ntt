-- local bit is required for luajit
local bit = require("bit")

-- the base entitypool. tracks generation.
-- entity_id = (generation << 20) | index
-- max_entities = 1,048,576
-- max_gens before wrapping = 4096

local EntityPool = {}
EntityPool.__index = EntityPool

local INDEX_BITS = 20
local INDEX_MASK = bit.lshift(1, INDEX_BITS) - 1  -- 0xFFFFF
local GENERATION_MASK = 0xFFF             -- 12 bits
local MAX_GENERATION = 4096

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

return EntityPool
