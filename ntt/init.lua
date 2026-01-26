local ntt = {}

ntt.EntityPool = require("ntt.entity")
ntt.ComponentStore = require("ntt.component")
ntt.World = require("ntt.world")

function ntt.createWorld(options)
  options = options or {}
  local world = ntt.World.new(options)
  return world
end

return ntt
