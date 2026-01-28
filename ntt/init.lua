local ntt = {}

ntt.EntityPool = require("ntt.entity")
ntt.ComponentStore = require("ntt.component")
ntt.World = require("ntt.world")
ntt.Events = require("ntt.events")
ntt.Scheduler = require("ntt.scheduler")
ntt.Time = require("ntt.time")
ntt.Commands = require("ntt.commands")

function ntt.createWorld(options)
  options = options or {}
  local world = ntt.World.new(options)
  return world
end

return ntt
