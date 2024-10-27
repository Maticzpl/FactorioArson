local flammability_manager = require("flammability_manager")

---@param event EventData.on_entity_damaged
local function on_tank_fire(event)
    local ent = event.entity
    local id = ent.unit_number
    local health = ent.health
    local position = ent.position
    local surface = ent.surface

    if health > settings.global["maticzplars-container-leak-hp"].value + 30 then
        return
    end

    if not ent.valid then   
        return
    end

    for name, ammount in pairs(ent.get_fluid_contents()) do
        local fuel = flammability_manager.get_flammability(name)
        if not fuel or fuel.strength <= 0 then
            goto continue
        end

        if storage.cooldown == nil then
            storage.cooldown = {}
        end
        
        if storage.cooldown[id] == nil or type(storage.cooldown[id]) == "table" then
            storage.cooldown[id] = 8                  
        end       

        if storage.cooldown[id] <= 0 then    
            storage.cooldown[id] = 8   
            
            if ent.valid then                
                ent.remove_fluid({name=name, amount=math.min(ammount, 307)})     
            end

            surface.create_entity({
                name="fire-flame", 
                position=position, 
                initial_ground_flame_count=fuel.strength * math.min(ammount/12500, 2)
            })
        else
            storage.cooldown[id] = storage.cooldown[id] - 1
        end

        if fuel.explosion ~= nil and fuel.explosion_radius > 0 and health < 20 then
            local radius = math.min(fuel.explosion_radius * math.min(ammount/18000, 2), 6) * settings.global["maticzplars-explosion-size"].value
            local r = math.ceil(radius)
            for x = -r, r, 1 do
                for y = -r, r, 1 do
                    if math.sqrt(x*x + y*y) < radius then                                        
                        if x == 0 and y == 0 then
                            surface.create_entity({name=fuel.explosion, position=position})  
                        else
                            local pos = {x=0, y=0}
                            pos.x = position.x + x + 0.5
                            pos.y = position.y + y + 0.5
                            surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
                        end    
                    end                              
                end                                
            end

            if settings.global["maticzplars-fireball"].value and fuel.fireball then                    
                radius = radius * 3.5
                local r = math.ceil(radius) + 1                        
                for x = -r, r, 2 do
                    for y = -r, r, 2 do
                        if math.sqrt(x*x + y*y) < radius then    
                            local pos = {x=0, y=0}
                            pos.x = position.x + x + 0.5 + math.random(-3,3)
                            pos.y = position.y + y + 0.5 + math.random(-3,3)
                            surface.create_entity({name="fire-flame", position=pos, initial_ground_flame_count=fuel.strength * math.min(ammount/12500, 2) * 2})     
                        end                              
                    end                                
                end
            end
        end
        
        ::continue::
    end
end

return on_tank_fire