---@param event EventData.on_entity_damaged
local function on_container_fire(event)
    local ent = event.entity
    if ent.health > settings.global["maticzplars-container-leak-hp"].value then
        return
    end


    for _, fuel in pairs(global.flammable) do
        local fname = fuel.name;
        local contents = ent.get_inventory(defines.inventory.chest)
        if contents == nil then
            contents = ent.get_inventory(defines.inventory.cargo_wagon)
        end

        if contents ~= nil and contents.get_item_count(fname) > 0 then
            local amount = contents.get_item_count(fname)

            if global.cooldown == nil then
                global.cooldown = {}
            end
            
            if global.cooldown[ent.unit_number] == nil or type(global.cooldown[ent.unit_number]) == "table" then
                global.cooldown[ent.unit_number] = 4                   
            end       

            if global.cooldown[ent.unit_number] <= 0 then    
                global.cooldown[ent.unit_number] = 4   
                
                contents.remove({name=fname, count=math.min(amount, 5)})

                ent.surface.create_entity({
                    name="fire-flame", 
                    position=ent.position, 
                    initial_ground_flame_count=fuel.strength * math.min(amount/5, fuel.strength / 4)
                })
            else
                global.cooldown[ent.unit_number] = global.cooldown[ent.unit_number] - 1
            end

            if fuel.explosion ~= nil and ent.health < 30 then
                local radius = math.min(fuel.explosion_radius * math.min(amount/40, 6), 10) * settings.global["maticzplars-explosion-size"].value
                local r = math.ceil(radius)
                for x = -r, r, 1 do
                    for y = -r, r, 1 do
                        if math.sqrt(x*x + y*y) < radius then                                        
                            if x == 0 and y == 0 then
                                ent.surface.create_entity({name=fuel.explosion, position=ent.position})  
                            else
                                local pos = {x=0, y=0};
                                pos.x = ent.position.x + x + 0.5;
                                pos.y = ent.position.y + y + 0.5;
                                ent.surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
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
                                local pos = {x=0, y=0};
                                pos.x = ent.position.x + x + 0.5 + math.random(-2,2)
                                pos.y = ent.position.y + y + 0.5 + math.random(-2,2)
                                ent.surface.create_entity({name="fire-flame", position=pos})     
                            end                              
                        end                                
                    end
                end
            end
            
        end
    end
end

return on_container_fire