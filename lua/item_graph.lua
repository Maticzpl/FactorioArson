local Queue = require("utility").Queue

local graph = {}
storage.graph = {};

function graph.update_recipie_map()
    -- Factorio recipies by product name
    --- @type { [string]: LuaRecipePrototype[] }
    storage.graph.recipies = {}

    for _, recipe in pairs(prototypes.recipe) do
        for _, product in ipairs(recipe.products) do
            if storage.graph.recipies[product.name] == nil then
                storage.graph.recipies[product.name] = {}
            end
            table.insert(storage.graph.recipies[product.name], recipe)
        end  
    end
end

--- @param identifier string
function graph.get_child_items(identifier)
    --- @type Product[]
    local children = {}

    for _, recipie in pairs(storage.graph.recipies[identifier]) do
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
function graph.get_parent_items(identifier)
    --- @type Ingredient[]
    local parents = {}

    for _, recipie in pairs(storage.graph.recipies[identifier]) do
        for _, ingredient in ipairs(recipie.ingredients) do
            if parents[ingredient.name] then
                parents[ingredient.name].amount = parents[ingredient.name] + ingredient.amount
            else
                parents[ingredient.name] = ingredient
            end
        end
    end

    return parents
end

--- Fills graph.depth_cache 
--- Root elemnts are depth 0
--- @param root_elements string[]
function graph.calculate_depths_from(root_elements)
    -- Previously global.proximity_cache
    --- @type {[string]: integer }
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

        for _, child in ipairs(graph.get_child_items(val)) do
            storage.graph.depth_cache[child.name] = math.min(storage.graph.depth_cache[val] + 1, storage.graph.depth_cache[child.name] or 9999999)
            if explored[child.name] == nil then
                queue:enqueue(child.name)
                explored[child.name] = true
            end
        end
    end
end

return graph
