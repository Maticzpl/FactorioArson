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

    local parents, child_ammounts = item_graph.get_parent_items(identifier, true)
    for key, parent in pairs(parents) do
        local parent_flammability = flammability_manager.get_flammability(parent.name)

        if parent_flammability then            
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
    
    flammability.strength = (flammability.strength / (nonflammable_ammount + 1)) * PARENT_STRENGTH_PRESERVED        
    
    if flammability.strength > 5 then
        flammability.explosion_radius = flammability.strength / 14
        flammability.explosion = "maticzplars-damage-explosion"
    end

    flammability.fireball = total_fluid_strength > total_item_strength - 1

    if flammability.strength ~= 0 then
        flammability.cooldown = math.max(5 / flammability.strength, 8) -- TODO: Better equation for that
    end

    return flammability
end

-- TODO make this better, check parents explosion radius, cooldown and take that into account!!!!!
---@param recalculate_identifiers string[]?
local function calculate_flammabilities(recalculate_identifiers)    
    item_graph.update_recipie_map()

    local roots
    if not recalculate_identifiers then
        roots = flammability_manager.get_root_elements()
        --- Traverses the graph once and caches the minimum distance to root elements
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

            local flammability = flammability_from_parents(child.name)

            flammability_manager.add_flammable(child.name, flammability, child.type)

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
