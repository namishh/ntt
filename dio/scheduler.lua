local Scheduler = {}
Scheduler.__index = Scheduler

Scheduler.PHASES = {
    "preUpdate",
    "update",
    "postUpdate",
    "preDraw",
    "draw"
}

function Scheduler.new(world)
    local scheduler = setmetatable({}, Scheduler)
    scheduler.world = world
    scheduler.systems = {}
    scheduler.systemsByName = {}
    scheduler.dirty = {}

    for _, phase in ipairs(Scheduler.PHASES) do
        scheduler.systems[phase] = {}
        scheduler.dirty[phase] = false
    end

    world.scheduler = scheduler
    return scheduler
end

function Scheduler:addSystem(system, phase, priority)
    phase = phase or system.phase or "update"
    local validPhase = false

    for _, p in ipairs(Scheduler.PHASES) do
        if p == phase then
            validPhase = true
            break
        end
    end

    if not validPhase then
        error("Invalid phase: " .. phase)
    end

    system.phase = phase
    system.priority = priority or system.priority or 0
    if system.enabled == nil then
      system.enabled = true
    end

    if not system.name then
        system.name = "System_" .. tostring(#self.systems[phase] + 1)
    end

    -- check duplicate names
    if self.systemsByName[system.name] then
        error("System name already exists: " .. system.name)
    end

    local phaseSystems = self.systems[phase]
    phaseSystems[#phaseSystems + 1] = system
    self.systemsByName[system.name] = system
    self.dirty[phase] = true
    return system
end

function Scheduler:removeSystem(system)
    local name = type(system) == "string" and system or system.name
    local sys =  self.systemsByName[name]

    if not sys then
        return false
    end

    local phaseSystems = self.systems[sys.phase]
    for i, s in ipairs(phaseSystems) do
        if s == sys then
            table.remove(phaseSystems, i)
            break
        end
    end
    self.systemsByName[name] = nil
    return true
end

-- enable and disable system
function Scheduler:enableSystem(system)
    local name = type(system) == "string" and system or system.name
    local sys =  self.systemsByName[name]

    if not sys then
        return false
    end

    sys.enabled = true
end

function Scheduler:disableSystem(system)
    local name = type(system) == "string" and system or system.name
    local sys =  self.systemsByName[name]

    if not sys then
        return false
    end

    sys.enabled = false
end

function Scheduler:isSystemEnabled(system)
    local name = type(system) == "string" and system or system.name
    local sys = self.systemsByName[name]

    return sys and sys.enabled
end

function Scheduler:getSystem(name)
    return self.systemsByName[name]
end

function Scheduler:_sortPhase(phase)
    if not self.dirty[phase] then
        return
    end
    
    table.sort(self.systems[phase], function(a, b)
        return a.priority < b.priority
    end)
    
    self.dirty[phase] = false
end

function Scheduler:run(phase, dt)
    self:_sortPhase(phase)
    local phaseSystems = self.systems[phase]
    local world = self.world

    for _, system in ipairs(phaseSystems) do
        if system.enabled and system.run then
            system:run(world, dt)
        end
    end
end


function Scheduler:runAll(dt)
    for _, phase in ipairs(Scheduler.PHASES) do
        self:run(phase, dt)
    end
end

function Scheduler:runUpdate(dt)
    self:run("preUpdate", dt)
    self:run("update", dt)
    self:run("postUpdate", dt)
end

function Scheduler:runDraw(dt)
    self:run("preDraw", dt)
    self:run("draw", dt)
end

function Scheduler:getSystemsInPhase(phase)
    self:_sortPhase(phase)
    return self.systems[phase]
end

function Scheduler:getSystemNames()
    local names = {}
    for name in pairs(self.systemsByName) do
        names[#names + 1] = name
    end
    return names
end

return Scheduler