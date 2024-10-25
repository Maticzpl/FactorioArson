local Queue = require("utility").Queue

local graph = {}
storage.graph = {};

function graph.update_recipie_map()
    --- @type { [string]: LuaRecipePrototype[] }
    storage.graph.recipies_by_product = {}
    --- @type { [string]: LuaRecipePrototype[] }
    storage.graph.recipies_by_ingredient = {}

    for _, recipe in pairs(prototypes.recipe) do
        for _, product in ipairs(recipe.products) do
            if storage.graph.recipies_by_product[product.name] == nil then
                storage.graph.recipies_by_product[product.name] = {}
            end
            table.insert(storage.graph.recipies_by_product[product.name], recipe)
        end  
        for _, ingredient in ipairs(recipe.ingredients) do
            if storage.graph.recipies_by_ingredient[ingredient.name] == nil then
                storage.graph.recipies_by_ingredient[ingredient.name] = {}
            end
            table.insert(storage.graph.recipies_by_ingredient[ingredient.name], recipe)
        end  
    end
end

--- @param identifier string
function graph.get_child_items(identifier)
    --- @type Product[]
    local children = {}

    for _, recipie in pairs(storage.graph.recipies_by_ingredient[identifier] or {}) do
        for _, product in ipairs(recipie.products) do
            if children[product.name] then
                children[product.name].amount = (children[product.name].amount or 1) + (product.amount or 1)
            else
                children[product.name] = product
            end
        end
    end

    return children
end

--- @param identifier string
--- @param check_depth boolean? Make sure the depth cache is populated before using
function graph.get_parent_items(identifier, check_depth)
    check_depth = check_depth or false


    --- @type Ingredient[]
    local parents = {}

    for _, recipie in pairs(storage.graph.recipies_by_product[identifier]) do
        for _, ingredient in ipairs(recipie.ingredients) do
            if not check_depth or 
                (graph.get_depth_from_cache(identifier) or 0) >             -- child
                (graph.get_depth_from_cache(ingredient.name) or 9999) then  -- parent             
                if parents[ingredient.name] then
                    parents[ingredient.name].amount = parents[ingredient.name].amount + ingredient.amount
                else
                    parents[ingredient.name] = ingredient
                end
            end
        end
    end

    return parents
end

--- Fills depth cache 
--- Root elemnts are depth 0
--- @param root_elements string[]
function graph.calculate_depths_from(root_elements)
    -- Previously global.proximity_cache
    --- @type { [string]: integer }
    storage.graph.depth_cache = {}

    local queue = Queue:new()
    local explored = {}
    
    for _, element in ipairs(root_elements) do
        storage.graph.depth_cache[element] = 0
        queue:enqueue(element)
        explored[element] = true
    end

    while #queue > 0 do
        local val = queue:dequeue()

        for _, child in pairs(graph.get_child_items(val)) do
            storage.graph.depth_cache[child.name] = math.min(storage.graph.depth_cache[val] + 1, storage.graph.depth_cache[child.name] or 9999999)
            if explored[child.name] == nil then
                queue:enqueue(child.name)
                explored[child.name] = true
            end
        end
    end
end

---@return integer|nil
function graph.get_depth_from_cache(identifier)
    return storage.graph.depth_cache[identifier]
end

return graph
