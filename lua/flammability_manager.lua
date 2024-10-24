local manager = {}

-- TODO: Functions for edits

storage.flammable = storage.flammable or {}
storage.fluids = storage.fluids or {}

---@type { [string]: { fireball: boolean?, cooldown: integer?, strenght: integer?, explosion: string?, explosion_radius: number?, nonflammable: boolean }}
storage.edits = storage.edits or {}

--- Makes the item flammable
---@param identifier string
---@param fireball boolean
---@param cooldown integer
---@param strenght integer
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
function manager.add_flammable_item(identifier, fireball, cooldown, strenght, calculated, explosion_type, explosion_radius)
    storage.flammable[identifier] = {
        name = identifier,
        fireball = fireball,
        cooldown = cooldown,
        strenght = strenght,
        explosion = explosion_type,
        explosion_radius = explosion_radius,
        calculated = calculated
    }
end

--- Makes the fluid flammable
---@param identifier string
---@param fireball boolean
---@param strenght integer
---@param calculated boolean
---@param explosion_type string?
---@param explosion_radius number?
function manager.add_flammable_fluid(identifier, fireball, strenght, calculated, explosion_type, explosion_radius)
    storage.fluids[identifier] = {
        name = identifier,
        fireball = fireball,
        strenght = strenght,
        explosion = explosion_type,
        explosion_radius = explosion_radius,
        calculated = calculated
    }

    local barrel_identifier = identifier .. "-barrel"
    if storage.flammable[barrel_identifier] == nil then            
        manager.add_flammable_item(barrel_identifier, fireball, 10, strenght, calculated, explosion_type, explosion_radius)
    end
end

---@alias Flammability { name: string, fireball: boolean, cooldown: integer?, strenght: integer, explosion: string?, explosion_radius: number? }
--- Gets flammability of item or fluid
---@param identifier string
---@return Flammability | nil
function manager.get_flammability(identifier)
    return storage.flammable[identifier] or storage.fluids[identifier]  
end

---@param new_values { fireball: boolean?, cooldown: integer?, strenght: integer?, explosion: string?, explosion_radius: number? }
function manager.make_edit(new_values)
    storage.edits
end

return manager
