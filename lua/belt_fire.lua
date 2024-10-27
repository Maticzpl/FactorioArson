local flammability_manager = require("flammability_manager")

---@param event EventData.on_entity_damaged
local function on_belt_fire(event)
    local ent = event.entity    

    local id = ent.unit_number
    local surface = ent.surface
    local position = ent.position
    local ent_type = ent.type
    local neighbours

    if string.match(ent_type, "underground") ~= nil then
        neighbours = ent.neighbours
    end

    ---@type uint 
    for i = 1, ent.get_max_transport_line_index() do
        if not ent.valid then
            return
        end
        local line = ent.get_transport_line(i)

        for _, item in ipairs(line.get_contents()) do
            local fuel = flammability_manager.get_flammability(item.name)
            if not fuel or fuel.strength <= 0 then
                goto continue
            end
            
            local amount = line.get_item_count(fuel.name)            
            -- TODO: Fix this cooldown stuff and refactor things
            local cooldown_val = fuel.cooldown / settings.global["maticzplars-belt-spread"].value

            storage.cooldown = storage.cooldown or {}                
            
            if storage.cooldown[id] == nil or type(storage.cooldown[id]) == "number" then
                storage.cooldown[id] = {}                        
            end                  
            
            if storage.cooldown[id][i] == nil then
                storage.cooldown[id][i] = 0
            end   

            if storage.cooldown[id][i] <= 0 then
                storage.cooldown[id][i] = cooldown_val

                line.remove_item({name = fuel.name, count = amount})
                
                surface.create_entity({
                    name="fire-flame", 
                    position=position, 
                    initial_ground_flame_count=fuel.strength * (amount/5)
                })

                if neighbours ~= nil then
                    local dist = math.max(
                        math.abs(position.x - neighbours.position.x),
                        math.abs(position.y - neighbours.position.y)
                    )

                    if dist <= settings.global["maticzplars-underground-max-length"].value then     
                        surface.create_entity({
                            name="fire-flame", 
                            position=neighbours.position, 
                            initial_ground_flame_count=1
                        })      
                    end                  
                end

                if fuel.explosion ~= nil and fuel.explosion_radius > 0 then
                    local radius = fuel.explosion_radius * math.min(amount/5, 2) * settings.global["maticzplars-explosion-size"].value
                    local r = math.ceil(radius)
                    for x = -r, r, 1 do
                        for y = -r, r, 1 do
                            if math.sqrt(x*x + y*y) < radius then                                        
                                if x == 0 and y == 0 then
                                    surface.create_entity({name=fuel.explosion, position=position})  
                                elseif math.random(0,1) == 0 then
                                    local pos = {x=0, y=0}
                                    pos.x = position.x + x + 0.5
                                    pos.y = position.y + y + 0.5
                                    surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
                                end    
                            end                              
                        end                                
                    end
                end
            end

            storage.cooldown[id][i] = storage.cooldown[id][i] - 1  
        
            ::continue::
        end
    end
end

return on_belt_fire