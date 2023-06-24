local items_from_recipes = require("lua/calc_flammability")
local on_belt_fire = require("lua/belt_fire")
local on_container_fire = require("lua/container_fire")
local on_tank_fire = require("lua/fluid_tank_fire")
local init_ground_item_fire_events = require("lua/ground_item_fire")


local function generate_barrels()    
    for _, fluid in pairs(global.fluids) do
        local name = fluid.name.."-barrel"
        if global.flammable[name] == nil then            
            global.flammable[name] = {
                fireball=fluid.fireball,
                cooldown=10,
                strength=fluid.strength,
                name=name,
                explosion_radius=fluid.explosion_radius,
                explosion=fluid.explosion
            }
        end
    end
end

local function load_flammables()    
    global.flammable = {
        ["wood"] = {fireball=false, cooldown=3, strength=3, name="wood"},
        ["coal"] = {fireball=false, cooldown=2, strength=7, name="coal"},
        ["solid-fuel"] = {fireball=false, cooldown=1, strength=10, name="solid-fuel"},
    
        -- ["crude-oil-barrel"] = {fireball=true, cooldown=10, strength=6, name="crude-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.3},
        -- ["heavy-oil-barrel"] = {fireball=true, cooldown=10, strength=10, name="heavy-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
        -- ["light-oil-barrel"] = {fireball=true, cooldown=10, strength=10, name="light-oil-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
        -- ["petroleum-gas-barrel"] = {fireball=true, cooldown=10, strength=10, name="petroleum-gas-barrel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.8},
    
        ["rocket-fuel"] = {fireball=true, cooldown=8, strength=15, name="rocket-fuel", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=1},
        ["flamethrower-ammo"] = {fireball=true, cooldown=10, strength=16, name="flamethrower-ammo", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.5},
    
        ["grenade"] = {fireball=false, cooldown=15, strength=2, name="grenade", explosion="grenade-explosion", explosion_radius=3},
        ["cluster-grenade"] = {fireball=false, cooldown=15, strength=2, name="cluster-grenade", explosion="grenade-explosion", explosion_radius=3},
    
        ["firearm-magazine"] = {fireball=false, cooldown=5, strength=2, name="firearm-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.2},
        ["piercing-rounds-magazine"] = {fireball=false, cooldown=5, strength=3, name="piercing-rounds-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.3},
        ["uranium-rounds-magazine"] = {fireball=false, cooldown=5, strength=4, name="uranium-rounds-magazine", explosion="maticzplars-damage-explosion", explosion_radius=0.4},
        
        ["rocket"] = {fireball=false, cooldown=10, strength=10, name="rocket", explosion="maticzplars-damage-explosion", explosion_radius=0.4},
        ["explosive-rocket"] = {fireball=false, cooldown=10, strength=7, name="explosive-rocket", explosion="maticzplars-damage-explosion", explosion_radius=0.7},
        ["cannon-shell"] = {fireball=false, cooldown=10, strength=7, name="cannon-shell", explosion="maticzplars-damage-explosion", explosion_radius=0.6},
        ["explosive-cannon-shell"] = {fireball=false, cooldown=10, strength=7, name="explosive-cannon-shell", explosion="maticzplars-damage-explosion", explosion_radius=1},
        ["uranium-cannon-shell"] = {fireball=false, cooldown=10, strength=7, name="uranium-cannon-shell", explosion="maticzplars-damage-explosion", explosion_radius=1},
        ["explosive-uranium-cannon-shell"] = {fireball=false, cooldown=10, strength=7, name="explosive-uranium-cannon-shell", explosion="maticzplars-damage-explosion", explosion_radius=1.4},
    
        ["shotgun-shell"] = {fireball=false, cooldown=5, strength=2, name="shotgun-shell", explosion="maticzplars-damage-explosion", explosion_radius=0.2},
        ["piercing-shotgun-shell"] = {fireball=false, cooldown=5, strength=3, name="piercing-shotgun-shell", explosion="maticzplars-damage-explosion", explosion_radius=0.3},
    
        ["explosives"] = {fireball=false, cooldown=5, strength=20, name="explosives", explosion="maticzplars-dynamite-explosion", explosion_radius=3},
    }
    
    global.fluids =   
    {
        ["crude-oil"] = {fireball=true, strength=6, name="crude-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.5},
        ["light-oil"] = {fireball=true, strength=10, name="light-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.6},
        ["heavy-oil"] = {fireball=true, strength=10, name="heavy-oil", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.6},    
        ["petroleum-gas"] = {fireball=true, strength=10, name="petroleum-gas", explosion="maticzplars-rocket-fuel-explosion", explosion_radius=0.7}, -- not even a fluid lol
    }

    generate_barrels()
    items_from_recipes()
end

script.on_init(load_flammables)
script.on_configuration_changed(load_flammables)

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
        {filter = "type", type = "electric-pole"},
    }
)

local to_ignore = {}
remote.add_interface("maticzplars-flammables", {
    ---@param name string
    ---@param fire_strength int
    ---@param fire_spread_cooldown int
    ---@param make_fireball boolean
    ---@param explosion_radius double
    ---@param explosion_prototype string?
    add_item = function (name, fire_strength, fire_spread_cooldown, make_fireball, explosion_radius, explosion_prototype)
        global.flammable[name] = {                
            fireball=make_fireball,
            cooldown=fire_spread_cooldown,
            strength=fire_strength,
            name=name,
            explosion_radius=explosion_radius,
            explosion=explosion_prototype or "maticzplars-rocket-fuel-explosion"
        }
    end,

    ---@param name string
    ---@param fire_strength int
    ---@param make_fireball boolean
    ---@param explosion_radius double
    ---@param explosion_prototype string?
    add_fluid = function (name, fire_strength, make_fireball, explosion_radius, explosion_prototype)
        global.fluids[name] = {                
            fireball=make_fireball,
            strength=fire_strength,
            name=name,
            explosion_radius=explosion_radius,
            explosion=explosion_prototype or "maticzplars-rocket-fuel-explosion"
        }
        generate_barrels()
    end,
        
    ---@param ignore string?
    recalculate_flammables = function (ignore)
        if ignore then
            table.insert(to_ignore, ignore)            
        end
        
        for key, value in pairs(global.flammable) do
            if value.calculated then
                global.flammable[key] = nil
            end
        end
        for key, value in pairs(global.fluids) do
            if value.calculated then
                global.fluids[key] = nil
            end
        end
        items_from_recipes(to_ignore)
    end
})

init_ground_item_fire_events()