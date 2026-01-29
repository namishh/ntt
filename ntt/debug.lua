local Debug = {}

function Debug.listEntities(world)
    local entities = {}
    for entity in world.entities:iterate() do
        entities[#entities + 1] = entity
    end
    return entities
end

function Debug.inspectEntity(world, entity)
    if not world.entities:isValid(entity) then
        return nil, "Entity is not valid"
    end

    local result = {
        enttiy = entity,
        index = world.entites,
        generation = world.entities:getGeneration(entity),
        components = {}
    }

    for name, store in pairs(world.components) do
        if store:has(entity) then
            result.components[name] = {
                data = store:get(entity),
                enabled = store:isEnabled(entity)
            }
        end
    end

    return result
end

function Debug.componentStats(world, name)
    local store = world.components[name]
    if not store then return nil end
end

function Debug.allStats(world, name)
    local stats = {
        entityCount = world.entities:getCount(),
        components = {}
    }
    for name in pairs(world.components) do
        stats.components[name] = Debug.componentStats(world, name)
    end
    
    return stats
end

function Debug.printEntity(world, entity)
    local info = Debug.inspectEntity(world, entity)
    if not info then
        print("Invalid entity")
        return
    end
    
    print(string.format("Entity %d (idx=%d, gen=%d)", info.entity, info.index, info.generation))
    for name, comp in pairs(info.components) do
        local status = comp.enabled and "" or " [DISABLED]"
        print("  " .. name .. status .. ":")
        if type(comp.data) == "table" then
            for k, v in pairs(comp.data) do
                if type(v) ~= "function" then
                    print("    " .. tostring(k) .. " = " .. tostring(v))
                end
            end
        else
            print("    " .. tostring(comp.data))
        end
    end
end

function Debug.printSummary(world)
    print("[World Summary]")
    print("Entities: " .. world.entities:getCount())
    print("Components:")
    
    for name, store in pairs(world.components) do
        local tag = store.isTag and " [TAG]" or ""
        print("  " .. name .. ": " .. store:getCount() .. tag)
    end
    
    if world.scheduler then
        print("Systems:")
        for _, phase in ipairs(world.scheduler.PHASES) do
            local systems = world.scheduler:getSystemsInPhase(phase)
            if #systems > 0 then
                print("  " .. phase .. ":")
                for _, sys in ipairs(systems) do
                    local status = sys.enabled and "" or " [DISABLED]"
                    print("    " .. sys.name .. status)
                end
            end
        end
    end
end

function Debug.drawOverlay(world, x, y)
    x = x or 10
    y = y or 10
    local lineHeight = 16
    local line = 0
    
    local r, g, b, a = love.graphics.getColor()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 5, y - 5, 180, 120)
    
    love.graphics.setColor(1, 1, 1, 1)
    
    love.graphics.print(string.format("FPS: %.0f", love.timer.getFPS()), x, y + line * lineHeight)
    line = line + 1
    
    love.graphics.print("Entities: " .. world.entities:getCount(), x, y + line * lineHeight)
    line = line + 1

    if world.time then
        local status = world.time:isPaused() and " PAUSED" or ""
        love.graphics.print(string.format("Time: %.1fs (x%.1f)%s", 
            world.time:getElapsed(), world.time:getScale(), status), x, y + line * lineHeight)
        line = line + 1
    end
    
    love.graphics.print("Components:", x, y + line * lineHeight)
    line = line + 1
    
    local counts = {}
    for name, store in pairs(world.components) do
        if store:getCount() > 0 then
            counts[#counts + 1] = { name = name, count = store:getCount() }
        end
    end
    table.sort(counts, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(4, #counts) do
        love.graphics.print("  " .. counts[i].name .. ": " .. counts[i].count, x, y + line * lineHeight)
        line = line + 1
    end
    
    love.graphics.setColor(r, g, b, a)
end

return Debug
