local function load_flammables()    
    global.flammable = {
        {fireball=false, cooldown=3, strength=3, name="wood"},
        {fireball=false, cooldown=2, strength=7, name="coal"},
        {fireball=false, cooldown=1, strength=10, name="solid-fuel"},
    
        {fireball=true, cooldown=10, strength=6, name="crude-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.3},
        {fireball=true, cooldown=10, strength=10, name="heavy-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
        {fireball=true, cooldown=10, strength=10, name="light-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
        {fireball=true, cooldown=10, strength=10, name="petroleum-gas-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
    
        {fireball=true, cooldown=8, strength=15, name="rocket-fuel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=1},
        {fireball=true, cooldown=10, strength=16, name="flamethrower-ammo", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.5},
    
        {fireball=false, cooldown=15, strength=2, name="grenade", explosion="grenade-explosion", explosion_radius=3},
        {fireball=false, cooldown=15, strength=2, name="cluster-grenade", explosion="grenade-explosion", explosion_radius=3},
    
        {fireball=false, cooldown=5, strength=2, name="firearm-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.2},
        {fireball=false, cooldown=5, strength=3, name="piercing-rounds-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.3},
        {fireball=false, cooldown=5, strength=4, name="uranium-rounds-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.4},
    
        {fireball=false, cooldown=5, strength=2, name="shotgun-shell", explosion="maticzplars-damage-explosion", explosion_radius=0.2},
        {fireball=false, cooldown=5, strength=3, name="piercing-shotgun-shell", explosion="maticzplars-damage-explosion", explosion_radius=0.3},
    
        {fireball=false, cooldown=5, strength=20, name="explosives", explosion="maticzplars-dynamite-explosion", explosion_radius=3},
    }
    
    global.fluids =   
    {
        {strength=6, name="crude-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.5},
        {strength=10, name="light-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.6},
        {strength=10, name="heavy-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.6},    
        {strength=10, name="petroleum-gas", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.7}, -- not even a fluid lol
    }
end

script.on_init(load_flammables)
script.on_configuration_changed(load_flammables)


---@param event EventData.on_entity_damaged
local function on_belt_fire(event)
    local ent = event.entity     

    ---@type uint 
    for i = 1, ent.get_max_transport_line_index() do
        local line = ent.get_transport_line(i)
        local contents = line.get_contents()

        for _, fuel in ipairs(global.flammable) do
            local fname = fuel.name;
            if contents[fname] ~= nil then
                local amount = contents[fname]

                if global.cooldown == nil then
                    global.cooldown = {}
                end
                
                if global.cooldown[ent.unit_number] == nil or type(global.cooldown[ent.unit_number]) == "number" then
                    global.cooldown[ent.unit_number] = {}                        
                end                  
                
                if global.cooldown[ent.unit_number][i] == nil then
                    global.cooldown[ent.unit_number][i] = ( fuel.cooldown * (fuel.strength / 10) * 3 ) / settings.global["maticzplars-belt-spread"].value
                end   

                if global.cooldown[ent.unit_number][i] <= 0 then
                    line.remove_item({name=fname, count=amount})
                    
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
                                        local pos = {x=0, y=0};
                                        pos.x = ent.position.x + x + 0.5;
                                        pos.y = ent.position.y + y + 0.5;
                                        ent.surface.create_entity({name="maticzplars-damage-explosion", position=pos})                                          
                                    end    
                                end                              
                            end                                
                        end
                    end
                end

                global.cooldown[ent.unit_number][i] = global.cooldown[ent.unit_number][i] - 1;     
            end
        end
    end
end

---@param event EventData.on_entity_damaged
local function on_container_fire(event)
    local ent = event.entity
    if ent.health > settings.global["maticzplars-container-leak-hp"].value then
        return
    end


    for _, fuel in ipairs(global.flammable) do
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

---@param event EventData.on_entity_damaged
local function on_tank_fire(event)
    local ent = event.entity
    if ent.health > settings.global["maticzplars-container-leak-hp"].value + 30 then
        return
    end

    for _, fuel in ipairs(global.fluids) do
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

                if settings.global["maticzplars-fireball"].value and (fuel.fireball or fuel.fireball == nil) then                    
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

script.on_event(
    defines.events.on_entity_damaged, 
    function (event)
        if event.entity.get_inventory(defines.inventory.chest) or 
            event.entity.get_inventory(defines.inventory.cargo_wagon) or 
            event.entity.get_inventory(defines.inventory.car_trunk) then
            on_container_fire(event)
        elseif event.entity.type == "fluid-wagon" or event.entity.type == "storage-tank" then
            on_tank_fire(event)
        else
            on_belt_fire(event)
        end
    end,
    {
        {filter = "damage-type", type = "fire"},
        {filter = "transport-belt-connectable", mode="and"},

        {filter = "damage-type", type = "fire"},
        {filter = "type", type="container", mode="and"},

        {filter = "damage-type", type = "fire"},
        {filter = "type", type="logistic-container", mode="and"},

        {filter = "damage-type", type = "fire"},
        {filter = "type", type="cargo-wagon", mode="and"},

        {filter = "damage-type", type = "fire"},
        {filter = "type", type="fluid-wagon", mode="and"},

        {filter = "damage-type", type = "fire"},
        {filter = "type", type="storage-tank", mode="and"},        
    }
)

script.on_event(
    defines.events.on_entity_died,
    function (event)
        if math.random(0, 100) < settings.global["maticzplars-pole-fire"].value then   
            local has_power = false
            for k, v in pairs(event.entity.electric_network_statistics.output_counts) do
                if v > 0.0 then
                    has_power = true
                end
            end

            if has_power then
                event.entity.surface.create_entity({
                    name="fire-flame", 
                    position=event.entity.position,
                    initial_ground_flame_count=5
                })                
            end
            
        end
    end,
    {
        {filter = "type", type = "electric-pole"}
    }
)



    remote.add_interface("maticzplars-flammables", {
        ---@param name string
        ---@param fire_strength int
        ---@param fire_spread_cooldown int
        ---@param make_fireball boolean
        ---@param explosion_radius double
        ---@param explosion_prototype string?
        add_item = function (name, fire_strength, fire_spread_cooldown, make_fireball, explosion_radius, explosion_prototype)
            table.insert(global.flammable, {                
                fireball=make_fireball,
                cooldown=fire_spread_cooldown,
                strength=fire_strength,
                name= name,
                explosion_radius=explosion_radius,
                explosion=explosion_prototype or "maticzplars-rocket-fuel-explosion"
            })
        end,

        ---@param name string
        ---@param fire_strength int
        ---@param make_fireball boolean
        ---@param explosion_radius double
        ---@param explosion_prototype string?
        add_fluid = function (name, fire_strength, make_fireball, explosion_radius, explosion_prototype)
            table.insert(global.fluids, {                
                fireball=make_fireball,
                strength=fire_strength,
                name= name,
                explosion_radius=explosion_radius,
                explosion=explosion_prototype or "maticzplars-rocket-fuel-explosion"
            })
        end
    })
