local item_graph = require("item_graph")
local flammability_manager = require("flammability_manager")
local Queue = require("utility").Queue

local PARENT_STRENGTH_PRESERVED = 0.9

---@param identifier string item / fluid to calculate
local function flammability_from_parents(identifier)
    local from_manager = flammability_manager.get_flammability(identifier)

    ---@type Flammability
    local flammability = {
        calculated = true,
        name = identifier,
        root_element = (from_manager and from_manager.root_element) or false,
        strength = 0,
        fireball = false,
        cooldown = 30
    }
    local nonflammable_ammount = 0
    local total_item_strength = 0
    local total_fluid_strength = 0

    local parent_count = 0
    local average_parent_strength = 0
    local average_parent_explosion = 0
    local average_parent_cooldown = 0
    local fireball_parents = 0

    local parents, child_ammounts = item_graph.get_parent_items(identifier, true)
    for key, parent in pairs(parents) do
        local parent_flammability = flammability_manager.get_flammability(parent.name)

        if parent_flammability and (parent_flammability.strength or 0) > 0 and not parent_flammability.dont_affect_products then            
            average_parent_strength = average_parent_strength + parent_flammability.strength
            average_parent_explosion = average_parent_explosion + parent_flammability.explosion_radius
            average_parent_cooldown = average_parent_cooldown + parent_flammability.cooldown
            parent_count = parent_count + 1
            
            if parent_flammability.fireball then
                fireball_parents = fireball_parents + 1
            end

            flammability.strength = flammability.strength + ((parent_flammability.strength * parent.amount) / child_ammounts[key])
            if parent.type == "item" then
                total_item_strength = total_item_strength + parent_flammability.strength * parent.amount
            else
                total_fluid_strength = total_fluid_strength + parent_flammability.strength * parent.amount
            end
        else
            nonflammable_ammount = nonflammable_ammount + parent.amount
        end
    end

    average_parent_strength  = average_parent_strength  / parent_count
    average_parent_explosion = average_parent_explosion / parent_count
    average_parent_cooldown  = average_parent_cooldown  / parent_count
    
    flammability.strength = (flammability.strength / (nonflammable_ammount + 1)) * PARENT_STRENGTH_PRESERVED        
    
    flammability.explosion_radius = average_parent_explosion
    if flammability.strength - average_parent_strength > 5 then
        flammability.explosion_radius = flammability.explosion_radius + ((flammability.strength - average_parent_strength) / 10)
    end

    if flammability.explosion_radius and flammability.explosion_radius > 0 then        
        flammability.explosion = "maticzplars-damage-explosion"
    end

    flammability.fireball = (total_fluid_strength > total_item_strength - 1) or (fireball_parents / parent_count >= 0.5)

    flammability.cooldown = average_parent_cooldown -- TODO: Better equation for that    

    return flammability
end

---@param recalculate_identifiers string[]?
local function calculate_flammabilities(recalculate_identifiers)    

    local roots
    if not recalculate_identifiers then
        item_graph.update_recipie_map()
        roots = flammability_manager.get_root_elements()
        item_graph.calculate_depths_from(roots)
    else
        roots = recalculate_identifiers
    end

    ---@alias TraversalData {name: string}
    ---@type Queue
    local queue = Queue:new()
    local explored = {}
    
    for _, root in ipairs(roots) do
        if recalculate_identifiers then
            flammability_manager.add_flammable(root, flammability_from_parents(root))
        end

        ---@type TraversalData
        local data = {
            name  = root
        }

        queue:enqueue(data)
        explored[root] = true
    end

    while #queue > 0 do
        ---@type TraversalData
        local parent = queue:dequeue()
        for _, child in pairs(item_graph.get_child_items(parent.name, true)) do
            local default_flammability = flammability_manager.get_flammability(child.name) 
            local flammability = flammability_from_parents(child.name)

            if not default_flammability or not default_flammability.strength or default_flammability.calculated then
                flammability_manager.add_flammable(child.name, flammability, child.type)                
            end

            if explored[child.name] == nil then
                queue:enqueue({
                    name = child.name
                })
                explored[child.name] = true
            end
        end
    end
end

return calculate_flammabilities
