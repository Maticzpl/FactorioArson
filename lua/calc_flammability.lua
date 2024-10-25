local item_graph = require("item_graph")
local flammability_manager = require("flammability_manager")
local Queue = require("utility").Queue


-- TODO make this better, allow for recalculating down from a single element
local function calculate_flammabilities()    
    item_graph.update_recipie_map()

    local roots = flammability_manager.get_root_elements()
    --- Traverses the graph once and caches the minimum distance to root elements
    item_graph.calculate_depths_from(roots)

    local queue = Queue:new()
    local explored = {}
    
    for _, root in ipairs(roots) do
        local root_flammability = flammability_manager.get_flammability(root)
        
        local depth_from_flammable = 9999
        if root_flammability then
            depth_from_flammable = 0
        end

        queue:enqueue({
            explore_children_of  = root,
            parent_item_strength = (root_flammability or {strength = 0}).strength,
            parent_fluids_strength = 0,
            total_count = 1,
            depth_from_flammable = depth_from_flammable
        })
        explored[root] = true
    end

    while #queue > 0 do
        local parent = queue:dequeue()
        for _, child in pairs(item_graph.get_child_items(parent.explore_children_of)) do
            ---@type Flammability
            local flammability = flammability_manager.get_flammability(child.name) or {
                name = child.name,
                fireball = false,
                strength = 0,
                calculated = true,
            }

            flammability.strength = ( 
                flammability.strength + 
                (parent.parent_item_strength + parent.parent_fluids_strength) / parent.total_count
            ) / 2

            if flammability.strength > 5 then
                flammability.explosion_radius = flammability.strength / 14
                flammability.explosion = "maticzplars-damage-explosion"
            end

            flammability.fireball = parent.parent_fluids_strength > parent.parent_item_strength - 1

            flammability.cooldown = math.max(5 / flammability.strength, 8)
            -- flammability.times_calculated = flammability.times_calculated + 1

            -- TODO: Handle fluids
            storage.flammable[child.name] = flammability

            -- local parent_count = #item_graph.get_parent_items(child.name)
            if explored[child.name] == nil --[[and flammability.times_calculated == parent_count]] then
                queue:enqueue({ -- TODO: figure this out
                    explore_children_of = child,
                    parent_item_strength = 0,
                    parent_fluids_strength = 0,
                    total_count = 1,
                    depth_from_flammable = parent.depth_from_flammable + 1
                })
                explored[child.name] = true
            end
        end
    end
end

return calculate_flammabilities
