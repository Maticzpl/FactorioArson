local item_graph = require("item_graph")
local flammability_manager = require("flammability_manager")
local Queue = require("utility").Queue

-- This is gonna cause some lag on save init / config change
---@param ignore string[]?
local function calculate_flammabilities(ignore)    
    item_graph.update_recipie_map()

    local roots = { 
        "stone",
        "iron-ore",
        "copper-ore",
        "uranium-ore",
        "coal",
        "wood",
    }
    item_graph.calculate_depths_from(roots)


    -- TODO: Merge with UI modification behaviour
    local dont_calculate = {
        "electronic%-circuit",
        "advanced%-circuit",
        "processing%-unit",
        "plastic%-bar",
        "electric%-engine%-unit",
        "battery",
        "steel",
        "module",
        "iron",
        "copper",
        "water" -- dont ask
    }
    if not settings.global["maticzplars-burn-lubricant"].value then
        table.insert(dont_calculate, "lubricant")
    end
    if ignore then        
        for _, name in ipairs(ignore) do
            table.insert(dont_calculate, name)
        end
    end

    -- replace with breadht first search

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
            parent_item_strenght = (root_flammability or {strength = 0}).strength,
            parent_fluids_strenght = 0,
            total_count = 1,
            depth_from_flammable = depth_from_flammable
        })
        explored[root] = true
    end

    while #queue > 0 do
        local parent = queue:dequeue()

        for _, child in ipairs(item_graph.get_child_items(parent.explore_children_of)) do
            ---@type Flammability
            local flammability = flammability_manager.get_flammability(child.name) or {
                name = child.name,
                fireball = false,
                strength = 0,
                calculated = true,
            }

            flammability.strenght = ( 
                flammability.strenght + 
                (parent.parent_item_strenght + parent.parent_fluids_strenght) / parent.total_count
            ) / 2

            if flammability.strenght > 5 then
                flammability.explosion_radius = flammability.strenght / 14
                flammability.explosion = "maticzplars-damage-explosion"
            end

            flammability.fireball = parent.parent_fluids_strenght > parent.parent_item_strenght - 1

            flammability.cooldown = math.max(5 / flammability.strenght, 8)
            flammability.times_calculated = flammability.times_calculated + 1

            storage.flammable[flammability.name] = flammability

            local parent_count = #item_graph.get_parent_items(child.name)
            if explored[child.name] == nil and flammability.times_calculated == parent_count then
                queue:enqueue({ -- TODO: figure this out
                    explore_children_of = child,
                    parent_item_strenght = 0,
                    parent_fluids_strenght = 0,
                    total_count = 1,
                    depth_from_flammable = parent.depth_from_flammable + 1
                })
                explored[child.name] = true
            end
        end
    end

    local itterated = {}
    -- total count is number of ingrediants
    ---@param name string
    ---@return {items: number, fluids: number, total_count: number, recursive: number}?
    local function calculate_flammability(name, debug)
        if itterated[name] ~= nil and itterated[name] > 0 then
            if debug then log("recursive limit "..name) end
            return nil
        end
        itterated[name] = (itterated[name] or 0) + 1

        -- TODO: Replace with storage.edits
        for _, skip in ipairs(dont_calculate) do            
            if string.match(name, skip) or string.match(name, "science%-pack") then
                if debug then log("skipped "..name) end
                return {items=0, fluids=0, total_count=1, recursive=0}            
            end
        end

        if storage.flammable[name] ~= nil then
            if debug then log("base "..name) end
            return {items=storage.flammable[name].strength, fluids=0, total_count=1, recursive=0}
        end
        if storage.fluids[name] ~= nil then
            if debug then log("base "..name) end
            return {items=0, fluids=storage.fluids[name].strength, total_count=1, recursive=0}            
        end

        ---@type LuaRecipePrototype[]
        local recipes = recipes_by_items[name]
        if recipes == nil then
            recipes = recipes_by_fluids[name]
        end

        if recipes == nil then
            return {items=0, fluids=0, total_count=1, recursive=0}
        end

        local this_prox = proximity[name]

        local flammability = {items=0, fluids=0, total_count=0, recursive=0}
        for i, recipe in ipairs(recipes) do
            for _, ingredient in ipairs(recipe.ingredients) do
                local ingredient_prox = proximity[ingredient.name]
                if this_prox and ingredient_prox and this_prox > ingredient_prox then
                    if not string.match(ingredient.name, "barrel") then    
                        if flammability.recursive < 3 then                    
                            if debug then log(name.." ingredient "..ingredient.name.." x"..ingredient.amount) end    
                            local res = calculate_flammability(ingredient.name, debug)
                            if res ~= nil then                    
                                flammability.items = flammability.items + res.items * ingredient.amount / math.max(flammability.recursive, 1)
                                flammability.fluids = flammability.fluids + res.fluids * ingredient.amount / math.max(flammability.recursive, 1)
                                flammability.total_count = flammability.total_count + res.total_count * ingredient.amount
                                flammability.recursive = res.recursive + 1
                            end
                        end
                    end

                end
            end
        end

        return flammability
    end

    -- local res = calculate_flammability("shotgun", true)

    -- if res then   
    --     local strength = (res.fluids + res.items) / res.total_count
    --     strength = math.floor(strength * 10) / 10

    --     log("DEBUG ITEM shotgun".." flammability "..strength.." = "..res.fluids.." + "..res.items.." / "..res.total_count.." cooldown: "..math.max(5/strength, 7))
    -- end

    local to_add_items = {}
    local to_add_fluids = {}

    log("CALCULATED FLAMMABILITY:")
    for name, item in pairs(prototypes.item) do
        itterated = {}
        local res = calculate_flammability(name)

        if res then   
            local strength = (res.fluids + res.items) / res.total_count
            strength = math.floor(strength * 10) / 10

            if res.total_count ~= 0 and strength > 0 and res.recursive > 0 then   
                log(strength.."\tITEM "..name)

                local explosion_radius = 0
                if strength > 5 then
                    explosion_radius = strength/14
                end

                to_add_items[name] = {
                    fireball=res.fluids > res.items - 1,
                    cooldown=math.max(5/strength, 8),
                    strength=strength,
                    name=name,
                    explosion_radius=explosion_radius,
                    explosion="maticzplars-damage-explosion"
                } 
            end
        end
    end
    for name, fluid in pairs(prototypes.fluid) do
        itterated = {}
        local res = calculate_flammability(name)
        if res then   
            local strength = (res.fluids + res.items) / res.total_count
            strength = math.floor(strength * 10) / 10

            if res.total_count ~= 0 and strength > 0 and res.recursive > 0 then            
                log(strength.."\tFLUID "..name)

                to_add_fluids[name] = {
                    fireball=true,
                    strength=strength,
                    name=name,
                    explosion_radius=strength/10,
                    explosion="maticzplars-damage-explosion"
                }
            end
        end
    end

    for name, item in pairs(to_add_items) do
        storage.flammable[name] = {
            fireball=item.fireball,
            cooldown=item.cooldown,
            strength=item.strength,
            name=item.name,
            explosion_radius=item.explosion_radius,
            explosion=item.explosion,
            calculated=true
        }
    end
    for name, fluid in pairs(to_add_fluids) do
        storage.fluids[name] = {
            fireball=fluid.fireball,
            strength=fluid.strength,
            name=fluid.name,
            explosion_radius=fluid.explosion_radius,
            explosion=fluid.explosion,
            calculated=true
        }
    end

end

return calculate_flammabilities
