local dio = {}

dio.EntityPool = require("dio.entity")
dio.ComponentStore = require("dio.component")
dio.World = require("dio.world")
dio.Events = require("dio.events")
dio.Scheduler = require("dio.scheduler")
dio.Time = require("dio.time")
dio.Commands = require("dio.commands")
dio.Debug = require("dio.debug")
dio.Serialize = require("dio.serialize")
local prefabModule = require("dio.prefab")
dio.Prefab = prefabModule.Prefab
dio.PrefabRegistry = prefabModule.PrefabRegistry
local sceneModule = require("dio.scene")
dio.Scene = sceneModule.Scene
dio.SceneManager = sceneModule.SceneManager

function dio.createWorld(options)
  options = options or {}
  local world = dio.World.new(options)
  return world
end

return dio
