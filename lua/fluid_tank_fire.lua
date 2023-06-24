---@param event EventData.on_entity_damaged
local function on_tank_fire(event)
    local ent = event.entity
    if ent.health > settings.global["maticzplars-container-leak-hp"].value + 30 then
        return
    end

    for _, fuel in pairs(global.fluids) do
        local fname = fuel.name;
        local contents = ent.get_fluid_contents()

        if contents ~= nil and contents[fname] ~= nil then
            local amount = contents[fname]

            if global.cooldown == nil then
                global.cooldown = {}
            end
            
            if global.cooldown[ent.unit_number] == nil or type(global.cooldown[ent.unit_number]) == "table" then
                global.cooldown[ent.unit_number] = 8                  
            end       

            if global.cooldown[ent.unit_number] <= 0 then    
                global.cooldown[ent.unit_number] = 8   
                
                ent.remove_fluid({name=fname, amount=math.min(amount, 307)})     

                ent.surface.create_entity({
                    name="fire-flame", 
                    position=ent.position, 
                    initial_ground_flame_count=fuel.strength * math.min(amount/12500, 2)
                })
            else
                global.cooldown[ent.unit_number] = global.cooldown[ent.unit_number] - 1
            end

            if fuel.explosion ~= nil and ent.health < 20 then
                local radius = math.min(fuel.explosion_radius * math.min(amount/18000, 2), 6) * settings.global["maticzplars-explosion-size"].value
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

                if settings.global["maticzplars-fireball"].value and fuel.fireball then                    
                    radius = radius * 3.5
                    local r = math.ceil(radius) + 1                        
                    for x = -r, r, 2 do
                        for y = -r, r, 2 do
                            if math.sqrt(x*x + y*y) < radius then    
                                local pos = {x=0, y=0};
                                pos.x = ent.position.x + x + 0.5 + math.random(-3,3)
                                pos.y = ent.position.y + y + 0.5 + math.random(-3,3)
                                ent.surface.create_entity({name="fire-flame", position=pos, initial_ground_flame_count=fuel.strength * math.min(amount/12500, 2)})     
                            end                              
                        end                                
                    end
                end
            end
            
        end
    end
end

return on_tank_fire