local flammability_manager = require("flammability_manager")

---@param event EventData.on_entity_damaged
local function on_container_fire(event)
    local ent = event.entity
    local id = ent.unit_number
    local health = ent.health
    local position = ent.position
    local surface = ent.surface

    if health > settings.global["maticzplars-container-leak-hp"].value then
        return
    end

    local contents = ent.get_inventory(defines.inventory.chest) or ent.get_inventory(defines.inventory.cargo_wagon)
  
    if contents == nil or not contents.valid then
        return
    end

    --- TODO: Include every item in calculations before applying cooldown, same for other fires like belt
    for _, item in pairs(contents.get_contents()) do
        local fuel = flammability_manager.get_flammability(item.name)
        if not fuel or fuel.strength <= 0 then
            goto continue
        end      

        if not contents.valid then
            return
        end

        local amount = contents.get_item_count(fuel.name)

        if storage.cooldown == nil then
            storage.cooldown = {}
        end
        
        if storage.cooldown[id] == nil or type(storage.cooldown[id]) == "table" then
            storage.cooldown[id] = 4                   
        end       

        if storage.cooldown[id] <= 0 then      
            if contents.valid then              
                contents.remove({name=  fuel.name, count = math.min(amount, 5)})
            end

            surface.create_entity({
                name="fire-flame", 
                position=position, 
                initial_ground_flame_count=fuel.strength * math.min(amount/5, fuel.strength / 4) * 2
            })
            storage.cooldown[id] = 4

            if fuel.explosion ~= nil and fuel.explosion_radius > 0 and health < 30 then
                local radius = math.min(fuel.explosion_radius * math.min(amount/40, 6), 10) * settings.global["maticzplars-explosion-size"].value
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

                radius = radius * 1.5
                local r = math.ceil(radius) + 1
                if fuel.fireball and settings.global["maticzplars-fireball"].value then                                
                    for x = -r, r, 2 do
                        for y = -r, r, 2 do
                            if math.sqrt(x*x + y*y) < radius then    
                                local pos = {x=0, y=0}
                                pos.x = position.x + x + 0.5 + math.random(-2,2)
                                pos.y = position.y + y + 0.5 + math.random(-2,2)
                                surface.create_entity({name="fire-flame", position=pos, initial_ground_flame_count=fuel.strength*3})     
                            end                              
                        end                                
                    end
                end
                storage.cooldown[id] = (math.random(1000, 6000) / amount) * 30
            end
        else
            storage.cooldown[id] = storage.cooldown[id] - 1
        end
        
        ::continue::
    end
end

return on_container_fire