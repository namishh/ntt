local Serialize = {}

local function valueToString(value, indent)
  indent = indent or 0
  local spaces = string.rep("  ", indent)
  local t = type(value)

  if t == "nil" then
    return "nil"
  elseif t == "boolean" then
    return value and "true" or "false"
  elseif t == "number" then
    if value ~= value then return "0/0" end  -- NaN
    if value == math.huge then return "math.huge" end
    if value == -math.huge then return "-math.huge" end
    return tostring(value)
  elseif t == "string" then
    return string.format("%q", value)
  elseif t == "table" then
    local parts = {}
    local isArray = true
    local maxIdx = 0

    for k in pairs(value) do
      if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
        isArray = false
        break
      end
      maxIdx = math.max(maxIdx, k)
    end
    if isArray and maxIdx > 0 then
      for i = 1, maxIdx do
        if value[i] == nil then isArray = false break end
      end
    end

    if isArray and maxIdx > 0 then
      for i = 1, maxIdx do
        parts[#parts + 1] = valueToString(value[i], indent + 1)
      end
      return "{" .. table.concat(parts, ", ") .. "}"
    else
      for k, v in pairs(value) do
        local key = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or ("[" .. valueToString(k) .. "]")
        parts[#parts + 1] = key .. " = " .. valueToString(v, indent + 1)
      end
      if #parts == 0 then return "{}" end
      return "{\n" .. spaces .. "  " .. table.concat(parts, ",\n" .. spaces .. "  ") .. "\n" .. spaces .. "}"
    end
  else
    return "nil --[[" .. t .. "]]"
  end
end


function Serialize.saveWorld(world, options)
  options = options or {}
  local skipComponents = options.skipComponents or {}

  local data = {
    entities = {}
  }

  for entity in world.entities:iterate() do
    local entityData = { components = {} }

    for name, store in pairs(world.components) do
      if not skipComponents[name] and store.serialize ~= false and store:has(entity) then
        local compData = store:get(entity)

        if type(compData) == "table" then
          local clean = {}
          local hasData = false
          for k, v in pairs(compData) do
            local vt = type(v)
            if vt ~= "function" and vt ~= "userdata" and vt ~= "thread" then
              clean[k] = v
              hasData = true
            end
          end
          if hasData or store.isTag then
            entityData.components[name] = clean
          end
        elseif compData == true then
          entityData.components[name] = {}
        end
      end
    end

    if next(entityData.components) then
      data.entities[#data.entities + 1] = entityData
    end
  end

  return data
end

function Serialize.saveWorldToString(world, options)
  local data = Serialize.saveWorld(world, options)
  return "return " .. valueToString(data)
end

function Serialize.saveWorldToFile(world, path, options)
  local str = Serialize.saveWorldToString(world, options)
  return love.filesystem.write(path, str)
end

function Serialize.loadWorld(world, data, options)
  options = options or {}

  if data.version ~= 1 then
    error("Unsupported save version: " .. tostring(data.version))
  end

  if options.clear then
    for entity in world.entities:iterate() do
      world.commands:despawn(entity)
    end
    world.commands:execute()
  end

  local entities = {}

  for _, entityData in ipairs(data.entities) do
    local entity = world:spawn()
    entities[#entities + 1] = entity

    for compName, compData in pairs(entityData.components) do
      local store = world.components[compName]
      if store then
        local copy = {}
        for k, v in pairs(compData) do
          copy[k] = v
        end
        store:add(entity, copy)
      end
    end
  end

  return entities
end

function Serialize.loadWorldFromString(world, str, options)
  local chunk, err = load(str, "save", "t", {})
  if not chunk then
    error("Parse error: " .. tostring(err))
  end

  local ok, data = pcall(chunk)
  if not ok then
    error("Execute error: " .. tostring(data))
  end

  return Serialize.loadWorld(world, data, options)
end

function Serialize.loadWorldFromFile(world, path, options)
  local content, err = love.filesystem.read(path)
  if not content then
    error("Read error: " .. tostring(err))
  end
  return Serialize.loadWorldFromString(world, content, options)
end

function Serialize.loadEntity(world, data)
  local entity = world:spawn()

  for compName, compData in pairs(data.components) do
    local store = world.components[compName]
    if store then
      local copy = {}
      for k, v in pairs(compData) do
        copy[k] = v
      end
      store:add(entity, copy)
    end
  end

  return entity
end

return Serialize
