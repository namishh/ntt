local Commands = {}
Commands.__index = Commands

function Commands.new(world)
    local cmd = setmetatable({}, Commands)
    cmd.world = world
    cmd.spawns = {}
    cmd.despawns = {}
    cmd.sets = {}
    cmd.removes = {}
    cmd.enables = {}
    cmd.disables = {}

    world.commands = cmd
    return cmd
end

function Commands:clear()
    self.spawns = {}
    self.despawns = {}
    self.sets = {}
    self.removes = {}
    self.enables = {}
    self.disables = {}
end

function Commands:hasPending()
    return #self.spawns > 0 or #self.despawns > 0 or #self.sets > 0 or #self.removes > 0 or #self.enables > 0 or #self.disables > 0
end

return Commands