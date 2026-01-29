local rohan = {
  _VERSION = "1.0.0",
  _DESCRIPTION = "Asset, spritesheet, and animation utilities for Love2D",
}

rohan.Assets = require("rohan.assets")
rohan.Spritesheet = require("rohan.spritesheet")
rohan.Aseprite = require("rohan.aseprite")

local animModule = require("rohan.animation")
rohan.Animation = animModule.Animation
rohan.AnimPlayer = animModule.AnimPlayer

return rohan

