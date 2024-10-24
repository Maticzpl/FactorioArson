local flammability_manager = require("flammability_manager")

---@param event EventData.on_entity_damaged
local function on_belt_fire(event)
    local ent = event.entity     

    ---@type uint 
    for i = 1, ent.get_max_transport_line_index() do
        local line = ent.get_transport_line(i)

        for _, item in ipairs(line.get_contents()) do
            local fuel = flammability_manager.get_flammability(item.name)
            if not fuel or fuel.strength <= 0 then
                goto continue
            end
            
            local amount = line.get_item_count(fuel.name)            
            -- TODO: Fix this cooldown stuff and refactor things
            local cooldown_val = (fuel.cooldown * (math.max(fuel.strength,3) / 10) * 3 ) / settings.global["maticzplars-belt-spread"].value

            storage.cooldown = storage.cooldown or {}                
            
            if storage.cooldown[ent.unit_number] == nil or type(storage.cooldown[ent.unit_number]) == "number" then
                storage.cooldown[ent.unit_number] = {}                        
            end                  
            
            if storage.cooldown[ent.unit_number][i] == nil then
                storage.cooldown[ent.unit_number][i] = 0
            end   

            if storage.cooldown[ent.unit_number][i] <= 0 then
                storage.cooldown[ent.unit_number][i] = cooldown_val

                line.remove_item({name = fuel.name, count = amount})
                
                ent.surface.create_entity({
                    name="fire-flame", 
                    position=ent.position, 
                    initial_ground_flame_count=fuel.strength * (amount/5)
                })

                if string.match(ent.type, "underground") ~= nil and ent.neighbours ~= nil then
                    local dist = math.max(
                        math.abs(ent.position.x - ent.neighbours.position.x),
                        math.abs(ent.position.y - ent.neighbours.position.y)
                    )

                    if dist <= settings.global["maticzplars-underground-max-length"].value then     
                        ent.surface.create_entity({
                            name="fire-flame", 
                            position=ent.neighbours.position, 
                            initial_ground_flame_count=1
                        })      
                    end                  
                end

                if fuel.explosion ~= nil then
                    local radius = fuel.explosion_radius * math.min(amount/5, 2) * settings.global["maticzplars-explosion-size"].value
                    local r = math.ceil(radius)
                    for x = -r, r, 1 do
                        for y = -r, r, 1 do
                            if math.sqrt(x*x + y*y) < radius then                                        
                                if x == 0 and y == 0 then
                                    ent.surface.create_entity({name=fuel.explosion, position=ent.position})  
                                else
                                    local pos = {x=0, y=0}
                                    pos.x = ent.position.x + x + 0.5
                                    pos.y = ent.position.y + y + 0.5
                                    ent.surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
                                end    
                            end                              
                        end                                
                    end
                end
            end

            storage.cooldown[ent.unit_number][i] = storage.cooldown[ent.unit_number][i] - 1  
        
            ::continue::
        end
    end
end

return on_belt_fire