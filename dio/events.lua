local Events = {}
Events.__index = Events

function Events.new(world)
  local events = setmetatable({}, Events)
  events.world = world
  events.queues = {}
  events.listeners = {}

  if world then
    world.events = events
  end

  return events
end

function Events:emit(eventType, data)
  if not self.queues[eventType] then
    self.queues[eventType] = {}
  end
  local queue = self.queues[eventType]
  queue[#queue + 1] = data or {}

  local listeners = self.listeners[eventType]
  if listeners then
    for _, callback in ipairs(listeners) do
      callback(data)
    end
  end
end

function Events:poll(eventType)
  local queue = self.queues[eventType]
  if not queue then
    return function() return nil end
  end

  local i = 0
  local count = #queue

  return function()
    i = i + 1
    if i <= count then
      return queue[i]
    end
    return nil
  end
end

function Events:getAll(eventType)
  return self.queues[eventType] or {}
end

function Events:has(eventType)
  return self.queues[eventType] and #self.queues[eventType] > 0
end

function Events:count(eventType)
  local queue = self.queues[eventType]
  return queue and #queue or 0
end

function Events:clearType(eventType)
  self.queues[eventType] = {}
end

function Events:clear()
  for eventType in pairs(self.queues) do
    self:clearType(eventType)
  end
end

function Events:on(eventType, callback)
  if not self.listeners[eventType] then
    self.listeners[eventType] = {}
  end

  local listeners = self.listeners[eventType]
  listeners[#listeners + 1] = callback

  -- return unsubscribe function
  return function()
    for i, cb in ipairs(listeners) do
      if cb == callback then
        table.remove(listeners, i)
        return
      end
    end
  end
end

function Events:off(eventType, callback)
  local listeners = self.listeners[eventType]
  if not listeners then
    return
  end

  for i, cb in ipairs(listeners) do
    if cb == callback then
      table.remove(listeners, i)
      return
    end
  end
end

function Events:offAll(eventType)

  self.listeners[eventType] = {}
end

function Events:getEventTypes()
  local types = {}
  for eventType, queue in pairs(self.queues) do
    if #queue > 0 then
      types[#types + 1] = eventType
    end
  end
  return types
end

return Events
