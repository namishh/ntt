package.path = package.path .. ";../?.lua;../ntt/?.lua"
local testing = require("t").new()
local sceneModule = require("ntt.scene")
local Scene = sceneModule.Scene
local SceneManager = sceneModule.SceneManager

testing:test("Scene.new() creates scene with name", function()
  local scene = Scene.new("TestScene")
  testing.assertNotNil(scene)
  testing.assertEqual(scene.name, "TestScene")
  testing.assertEqual(scene.active, false)
end)

testing:test("Scene.define() creates scene from definition", function()
  local scene = Scene.define("TestScene", {
    data = { value = 42 }
  })
  testing.assertEqual(scene.name, "TestScene")
  testing.assertEqual(scene.data.value, 42)
end)

testing:test("Scene lifecycle methods work", function()
  local scene = Scene.new("Test")
  local loadCalled = false
  
  scene.load = function() loadCalled = true end
  
  scene:_load()
  testing.assertEqual(loadCalled, true)
  testing.assertEqual(scene.loaded, true)
  
  scene:_enter()
  testing.assertEqual(scene.active, true)
  
  scene:_exit()
  testing.assertEqual(scene.active, false)
end)

testing:test("SceneManager manages scenes", function()
  local manager = SceneManager.new()
  
  local scene1 = Scene.new("Scene1")
  manager:add(scene1)
  
  testing.assertEqual(manager:get("Scene1"), scene1)
end)

testing:test("SceneManager:switch() changes current scene", function()
  local manager = SceneManager.new()
  
  local scene1 = Scene.new("Scene1")
  local scene2 = Scene.new("Scene2")
  
  manager:add(scene1)
  manager:add(scene2)
  
  manager:switch("Scene1")
  testing.assertEqual(manager.current, scene1)
  
  manager:switch("Scene2")
  testing.assertEqual(manager.current, scene2)
  testing.assertEqual(manager.previous, scene1)
end)

testing:test("SceneManager:push() and pop() manage scene stack", function()
  local manager = SceneManager.new()
  
  local scene1 = Scene.new("Scene1")
  local scene2 = Scene.new("Scene2")
  
  manager:add(scene1)
  manager:add(scene2)
  
  manager:switch("Scene1")
  manager:push("Scene2")
  testing.assertEqual(manager.current, scene2)
  testing.assertEqual(#manager.stack, 1)
  
  manager:pop()
  testing.assertEqual(manager.current, scene1)
end)

testing:report()

