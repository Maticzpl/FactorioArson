local util = require("util")
local utility = require("utility")
--- bruh naming

local manager = {}

---@type { [string]: Flammability }
storage.flammable = storage.flammable or {}
---@type { [string]: Flammability }
storage.fluids = storage.fluids or {}

---@alias Flammability { name: string, fireball: boolean, cooldown: integer?, strength: integer, explosion: string?, explosion_radius: number?, root_element: boolean, calculated: boolean }
---@alias FlammabilityEdit { fireball: boolean?, cooldown: integer?, strength: integer?, explosion: string?, explosion_radius: number?, root_element: boolean? }

---@type { [string]: FlammabilityEdit }
storage.edits = storage.edits or {}

--- Makes the item flammable
---@param identifier string
---@param fireball boolean
---@param cooldown integer
---@param strength integer
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
---@param root_element boolean?
function manager.add_flammable_item(identifier, fireball, cooldown, strength, calculated, explosion_type, explosion_radius, root_element)
    storage.flammable[identifier] = {
        name = identifier,
        fireball = fireball,
        cooldown = cooldown,
        strength = strength,
        explosion = explosion_type,
        explosion_radius = explosion_radius,
        calculated = calculated,
        root_element = root_element or false
    }
end

--- Makes the fluid flammable
---@param identifier string
---@param fireball boolean
---@param strength integer
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
---@param root_element boolean?
function manager.add_flammable_fluid(identifier, fireball, strength, calculated, explosion_type, explosion_radius, root_element)
    storage.fluids[identifier] = {
        name = identifier,
        fireball = fireball,
        strength = strength,
        explosion = explosion_type,
        explosion_radius = explosion_radius,
        calculated = calculated,
        root_element = root_element or false
    }

    local barrel_identifier = identifier .. "-barrel"
    if storage.flammable[barrel_identifier] == nil then            
        manager.add_flammable_item(barrel_identifier, fireball, 10, strength, calculated, explosion_type, explosion_radius, false)
    end
end

--- Gets flammability of item or fluid
---@param identifier string
---@return Flammability | nil
function manager.get_raw_flammability(identifier)
    ---@type Flammability
    local flammability = storage.flammable[identifier] or storage.fluids[identifier]  

    if flammability then
        flammability.name = flammability.name or identifier
        flammability.fireball = flammability.fireball or false
        flammability.cooldown = flammability.cooldown or 9999
        flammability.strength = flammability.strength or identifier
        flammability.explosion = flammability.explosion or identifier
        flammability.explosion_radius = flammability.explosion_radius or 0
        flammability.root_element = flammability.root_element or false
        flammability.calculated = flammability.calculated or false
    end

    return flammability
end

--- Gets flammability of item or fluid including edits
---@param identifier string
---@return Flammability | nil
function manager.get_flammability(identifier)
    local flammability = util.copy(manager.get_raw_flammability(identifier)) or {}

    for k, v in pairs(storage.edits[identifier] or {}) do
        flammability[k] = v
    end

    if table.compare(flammability, {}) then
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
function manager.clear_edit(identifier)
    storage.edits[identifier] = nil
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
