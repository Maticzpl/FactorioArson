local flammability_manager = require("flammability_manager")
-- TODO: Fix bug https://mods.factorio.com/mod/Arson/discussion/66f9196ad24a3f213f62ff9f

---@param item LuaEntity
local function on_item_fire(item)
    local name = item.stack.name
    local fuel = flammability_manager.get_flammability(name)
    if not fuel or fuel.strength <= 0 then
        return
    end

    if storage.cooldown == nil then
        storage.cooldown = {}
    end
    local id = item.position.x.." "..item.position.y
    if storage.cooldown[id] == nil or type(storage.cooldown[id]) == "table" then
        storage.cooldown[id] = ( fuel.cooldown * (fuel.strength / 10)  ) / settings.global["maticzplars-belt-spread"].value                       
    end          

    if storage.cooldown[id] <= 0 then    
        item.surface.create_entity({
            name="fire-flame", 
            position=item.position, 
            initial_ground_flame_count=math.max(fuel.strength / 9, 1)
        })

        if fuel.explosion ~= nil and fuel.explosion_radius > 0 then
            local radius = fuel.explosion_radius * 0.8 * settings.global["maticzplars-explosion-size"].value
            local r = math.ceil(radius)
            for x = -r, r, 1 do
                for y = -r, r, 1 do
                    if math.sqrt(x*x + y*y) < radius then                                        
                        if x == 0 and y == 0 then
                            item.surface.create_entity({name=fuel.explosion, position=item.position})  
                        else
                            local pos = {x=0, y=0}
                            pos.x = item.position.x + x + 0.5
                            pos.y = item.position.y + y + 0.5
                            item.surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
                        end    
                    end                              
                end                                
            end
        end
        item.destroy()
        storage.cooldown[id] = nil
    end

    if storage.cooldown[id] ~= nil then
        storage.cooldown[id] = storage.cooldown[id] - 1
    end
end

local function init()    
    script.on_event(
        defines.events.on_script_trigger_effect, 
        function (event)
            if event.effect_id ~= "maticzplars-fire-created" then
                return
            end

            local entity = event.source_entity
            if entity == nil or entity.type ~= "fire" then
                return
            end

            storage.ground_fires = storage.ground_fires or {}
            

            local surf = entity.surface.name        
            if storage.ground_fires[surf] == nil then
                storage.ground_fires[surf] = {}
            end
            table.insert(storage.ground_fires[surf], entity)            
        end
    )

    script.on_nth_tick(20, function (tick_data)
        if settings.global["maticzplars-burn-ground-items"].value then 
            for _, surface in pairs(game.surfaces) do            

                storage.ground_fires = storage.ground_fires or {}

                local f = storage.ground_fires[surface.name]
                if f and #f > 0 then              
                    for i = 1, math.max(#f/4, 1), 1 do                    
                        local i = math.random(1, #f)
                        --- @type LuaEntity
                        local entity = f[i]

                        if entity.valid then      
                            local items = surface.find_entities_filtered({
                                type = "item-entity",
                                position = entity.position,
                                radius = 2.5
                            })

                            for _, item in pairs(items) do
                                on_item_fire(item)   
                            end
                        end
                    end 
                end
            end
        end
    end)

    script.on_nth_tick(450, function (tick_data)
        -- since a fire entity exists until the black sooth on the ground dissapears it would be considered a fire for too long for ground items
        -- so this is a really bad way to fix that
        storage.ground_fires = {}
    end)
end

return init