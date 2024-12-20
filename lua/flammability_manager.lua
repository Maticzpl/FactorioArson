local util = require("util")
local utility = require("utility")
--- bruh naming

local manager = {}

---@type { [string]: Flammability }
storage.flammable = storage.flammable or {}
---@type { [string]: Flammability }
storage.fluids = storage.fluids or {}

---@alias Flammability { name: string, fireball: boolean, cooldown: integer, strength: number, explosion: string?, explosion_radius: number?, root_element: boolean, calculated: boolean, dont_affect_products: boolean? }
---@alias FlammabilityEdit { fireball: boolean?, cooldown: integer?, strength: number?, explosion: string?, explosion_radius: number?, root_element: boolean?, dont_affect_products: boolean? }

---@type { [string]: FlammabilityEdit }
storage.edits = storage.edits or {}

--- Makes the item flammable
---@param identifier string
---@param fireball boolean
---@param cooldown integer
---@param strength number
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
---@param root_element boolean?
function manager.add_flammable_item(identifier, fireball, cooldown, strength, calculated, explosion_type, explosion_radius, root_element)
    storage.flammable[identifier] = {
        name = identifier,
        fireball = fireball or false,
        cooldown = cooldown or 30,
        strength = strength or 0,
        explosion = explosion_type or "maticzplars-damage-explosion",
        explosion_radius = explosion_radius or 0,
        calculated = calculated or false,
        root_element = root_element or false
    }
end

--- Makes the fluid flammable
---@param identifier string
---@param fireball boolean
---@param cooldown integer
---@param strength number
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
---@param root_element boolean?
function manager.add_flammable_fluid(identifier, fireball, cooldown, strength, calculated, explosion_type, explosion_radius, root_element)
    storage.fluids[identifier] = {
        name = identifier,
        fireball = fireball or false,
        cooldown = cooldown or 30,
        strength = strength or 0,
        explosion = explosion_type or "matizcplars-damage-explosion",
        explosion_radius = explosion_radius or 0,
        calculated = calculated or false,
        root_element = root_element or false
    }

    local barrel_identifier = identifier .. "-barrel"
    if storage.flammable[barrel_identifier] == nil then            
        manager.add_flammable_item(barrel_identifier, fireball, 60, strength, calculated, explosion_type, explosion_radius, false)
    end
end

-- TODO: does name have to be separate from flammability

---@param flammability Flammability
---@param type string? item or fluid
function manager.add_flammable(name, flammability, type)
    if not type then
        if prototypes.item[name] then
            type = "item"
        elseif prototypes.fluid[name] then
            type = "fluid"
        else
            error("Flammable isn't an item nor a fluid")
        end
    end

    if type == "item" then
        manager.add_flammable_item(
            name,
            flammability.fireball,
            flammability.cooldown,
            flammability.strength,
            flammability.calculated,
            flammability.explosion,
            flammability.explosion_radius
        )
    elseif type == "fluid" then
        manager.add_flammable_fluid(
            name,
            flammability.fireball,
            flammability.cooldown,
            flammability.strength,
            flammability.calculated,
            flammability.explosion,
            flammability.explosion_radius
        )
    end
end

function manager.add_root_element(identifier)
    manager.add_flammable(identifier, { name = identifier, strength = 0, cooldown = 10, calculated = false, fireball = false, root_element = true })
end

--- Gets flammability of item or fluid
---@param identifier string
---@return Flammability | nil
function manager.get_raw_flammability(identifier)
    ---@type Flammability
    local flammability = storage.flammable[identifier] or storage.fluids[identifier]  

    return flammability
end

--- Gets flammability of item or fluid including edits
---@param identifier string
---@return Flammability | nil
function manager.get_flammability(identifier)
    local flammability = {}

    local edit = manager.get_edit(identifier)
    
    for k, v in pairs(edit) do
        flammability[k] = v
    end

    for k, v in pairs(manager.get_raw_flammability(identifier) or {}) do
        flammability[k] = flammability[k] or v
    end

    if table.compare(flammability, {}) then
        return nil
    end

    -- If there are no edits and not flammable, ignore
    if table.compare(edit, {}) and
        (flammability.strength == nil or flammability.strength <= 0) and
        not flammability.root_element then
        return nil
    end

    return flammability
end

---@param identifier string
---@param new_values FlammabilityEdit
function manager.make_edit(identifier, new_values)
    storage.edits[identifier] = storage.edits[identifier] or {}
    for k, v in pairs(new_values) do
        storage.edits[identifier][k] = v
    end
end

---@param identifier string
---@returns FlammabilityEdit
function manager.get_edit(identifier)
    return storage.edits[identifier] or {}
end

---@param identifier string
---@param field string
function manager.clear_edit(identifier, field)
    storage.edits[identifier][field] = nil
end

---@return string[]
function manager.get_root_elements()
    local elements = {}
    for _, item in pairs(utility.mergeTables({prototypes.item, prototypes.fluid})) do
        local flammability = manager.get_flammability(item.name);
        if flammability and flammability.root_element then
            table.insert(elements, item.name)
        end
    end
    return elements
end

return manager
