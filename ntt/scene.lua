local Scene = {}
Scene.__index = Scene

function Scene.new(name)
  local scene = setmetatable({}, Scene)
  scene.name = name
  scene.world = nil -- part of this module, can technically just be copy pasted into another project just for scene management
  scene.active = false
  scene.loaded = false
  scene.data = {}
  return scene
end

function Scene.define(name, def)
  local scene = Scene.new(name)
  for k, v in pairs(def) do
    scene[k] = v
  end
  return scene
end


-- methods to overriden by the developer
function Scene:load() end
function Scene:enter(...) end
function Scene:update(dt) end
function Scene:draw() end
function Scene:exit() end
function Scene:unload() end

function Scene:_load()
  if not self.loaded then
    self:load()
    self.loaded = true
  end
end

function Scene:_enter(...)
  self.active = true
  self:enter(...)
end

function Scene:_exit()
  self.active = false
  self:exit()
end

function Scene:_unload()
  if self.loaded then
    self:unload()
    self.loaded = false
  end
end


local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
  local manager = setmetatable({}, SceneManager)
  manager.scenes = {}
  manager.current = nil
  manager.previous = nil
  manager.stack = {}
  manager.transitioning = false
  manager.transitionData = nil
  return manager
end

function SceneManager:add(scene)
  self.scenes[scene.name] = scene
  return self
end

function SceneManager:create(name, def)
  local scene = Scene.define(name, def)
  self:add(scene)
  return scene
end

function SceneManager:get(name)
  return self.scenes[name]
end

function SceneManager:switch(name, ...)
  local scene = self.scenes[name]
  if not scene then
    error("Scene not found: " .. tostring(name))
  end

  if self.current then
    self.current:_exit()
  end

  self.previous = self.current
  self.current = scene

  scene:_load()
  scene:_enter(...)

  return self
end

function SceneManager:push(name, ...)
  if self.current then
    self.stack[#self.stack + 1] = self.current
    self.current:_exit()
  end

  local scene = self.scenes[name]
  if not scene then
    error("Scene not found: " .. tostring(name))
  end

  self.current = scene
  scene:_load()
  scene:_enter(...)

  return self
end

function SceneManager:pop(...)
  if #self.stack == 0 then
    return self
  end

  if self.current then
    self.current:_exit()
  end

  self.current = self.stack[#self.stack]
  self.stack[#self.stack] = nil

  if self.current then
    self.current:_enter(...)
  end
end

function SceneManager:update(dt)
  if self.current then
    self.current:update(dt)
  end
end

function SceneManager:draw()
  if self.current then
    self.current:draw()
  end
end

function SceneManager:clear()
  for _, scene in pairs(self.scenes) do
    scene:_unload()
  end
  self.scenes = {}
  self.current = nil
  self.stack = {}
end

function SceneManager:currentName()
  return self.current and self.current.name
end

function SceneManager:keypressed(key, scancode, isrepeat)
  if self.current and self.current.keypressed then
    self.current:keypressed(key, scancode, isrepeat)
  end
end

function SceneManager:keyreleased(key, scancode)
  if self.current and self.current.keyreleased then
    self.current:keyreleased(key, scancode)
  end
end

function SceneManager:mousepressed(x, y, button)
  if self.current and self.current.mousepressed then
    self.current:mousepressed(x, y, button)
  end
end

function SceneManager:mousereleased(x, y, button)
  if self.current and self.current.mousereleased then
    self.current:mousereleased(x, y, button)
  end
end

function SceneManager:mousemoved(x, y, dx, dy)
  if self.current and self.current.mousemoved then
    self.current:mousemoved(x, y, dx, dy)
  end
end

function SceneManager:textinput(text)
  if self.current and self.current.textinput then
    self.current:textinput(text)
  end
end

return {
  Scene = Scene,
  SceneManager = SceneManager
}
