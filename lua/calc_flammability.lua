local function populate_recipe_table(items, fluids)    
    for name, recipe in pairs(game.recipe_prototypes) do
        for _, product in ipairs(recipe.products) do
            if product.type == "item" then                    
                if items[product.name] == nil then
                    items[product.name] = {}
                end
                table.insert(items[product.name], recipe)
            else
                if fluids[product.name] == nil then
                    fluids[product.name] = {}
                end
                table.insert(fluids[product.name], recipe)
            end
        end  
    end
end

local function calculate_proximity(items, fluids)
    local proximity = { -- just vanilla
        ["stone"] = 0,
        ["iron-ore"] = 0,
        ["copper-ore"] = 0,
        ["uranium-ore"] = 0,
        ["coal"] = 0,
        ["wood"] = 0,
    }

    for name, item in pairs(game.item_prototypes) do
        if items[name] == nil then
            proximity[name] = 0
        end
    end

    for name, fluid in pairs(game.fluid_prototypes) do
        if fluids[name] == nil then
            proximity[name] = 0
        end        
    end

    local itterated = {}
    local function calculate_proximity_recursively(name)
        if itterated[name] ~= nil then
            return
        end
        itterated[name] = true

        local recipes = items[name]
        if recipes == nil then
            recipes = fluids[name]
        end
        if recipes == nil then
            return
        end

        local lowest = 999999999
        for i, recipe in ipairs(recipes) do
            for _, ingredient in ipairs(recipe.ingredients) do
                if proximity[ingredient.name] ~= nil then
                    lowest = math.min(proximity[ingredient.name] + 1, lowest)
                else
                    local result = calculate_proximity_recursively(ingredient.name)
                    if result then
                        lowest = math.min(result + 1, lowest)                        
                    end
                end
            end
        end
        return lowest
    end

    for name, item in pairs(game.item_prototypes) do
        itterated = {}
        local res = calculate_proximity_recursively(name)
        if proximity[name] == nil and res then
            proximity[name] = res
        --elseif not res then
            --log("Cant get proximity of "..name)
        end
    end
    for name, fluid in pairs(game.fluid_prototypes) do
        itterated = {}
        local res = calculate_proximity_recursively(name)
        if proximity[name] == nil and res then
            proximity[name] = res
        -- elseif not res then
        --     log("Cant get proximity of "..name)
        end
    end
    return proximity
end

-- This is gonna cause some lag on save init / config change
---@param ignore string[]?
local function items_from_recipes(ignore)    
    local recipes_by_items = {}
    local recipes_by_fluids = {}

    populate_recipe_table(recipes_by_items, recipes_by_fluids)

    local proximity = calculate_proximity(recipes_by_items, recipes_by_fluids)

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

        for _, skip in ipairs(dont_calculate) do            
            if string.match(name, skip) or string.match(name, "science%-pack") then
                if debug then log("skipped "..name) end
                return {items=0, fluids=0, total_count=1, recursive=0}            
            end
        end

        if global.flammable[name] ~= nil then
            if debug then log("base "..name) end
            return {items=global.flammable[name].strength, fluids=0, total_count=1, recursive=0}
        end
        if global.fluids[name] ~= nil then
            if debug then log("base "..name) end
            return {items=0, fluids=global.fluids[name].strength, total_count=1, recursive=0}            
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
    for name, item in pairs(game.item_prototypes) do
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
    for name, fluid in pairs(game.fluid_prototypes) do
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
        global.flammable[name] = {
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
        global.fluids[name] = {
            fireball=fluid.fireball,
            strength=fluid.strength,
            name=fluid.name,
            explosion_radius=fluid.explosion_radius,
            explosion=fluid.explosion,
            calculated=true
        }
    end

end

return items_from_recipes