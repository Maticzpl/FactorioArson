local calculate_flammabilities = require("lua/calc_flammability")
local flammability_manager = require("lua/flammability_manager")
local on_belt_fire = require("lua/belt_fire")
local on_container_fire = require("lua/container_fire")
local on_tank_fire = require("lua/fluid_tank_fire")
local init_ground_item_fire_events = require("lua/ground_item_fire")
local gui = require("lua/gui")

local function load_flammables()    
    flammability_manager.add_root_element("water")
    flammability_manager.add_root_element("stone")
    flammability_manager.add_root_element("iron-ore")
    flammability_manager.add_root_element("copper-ore")
    flammability_manager.add_root_element("uranium-ore")

    flammability_manager.add_flammable_item("wood",       false, 15, 2,  false, nil, 0, true)
    flammability_manager.add_flammable_item("coal",       false, 7,  7,  false, nil, 0, true)
    flammability_manager.add_flammable_item("solid-fuel", false, 5,  10, false, nil, 0)

    flammability_manager.add_flammable_item("rocket-fuel",       true, 8,  15, false, "maticzplars-rocket-fuel-explosion", 1)
    flammability_manager.add_flammable_item("flamethrower-ammo", true, 10, 16, false, "maticzplars-rocket-fuel-explosion", 0.5)

    flammability_manager.add_flammable_item("grenade",         false, 15, 2, false, "grenade-explosion", 3)
    flammability_manager.add_flammable_item("cluster-grenade", false, 15, 2, false, "grenade-explosion", 3)

    flammability_manager.add_flammable_item("firearm-magazine",         false, 5, 2, false, "maticzplars-damage-explosion", 0.2)
    flammability_manager.add_flammable_item("piercing-rounds-magazine", false, 5, 3, false, "maticzplars-damage-explosion", 0.3)
    flammability_manager.add_flammable_item("uranium-rounds-magazine",  false, 5, 4, false, "maticzplars-damage-explosion", 0.4)
    
    flammability_manager.add_flammable_item("rocket",                         false, 10, 10, false,  "maticzplars-damage-explosion", 0.4)
    flammability_manager.add_flammable_item("explosive-rocket",               false, 10, 7,  false,  "maticzplars-damage-explosion", 0.7)
    flammability_manager.add_flammable_item("cannon-shell",                   false, 10, 7,  false,  "maticzplars-damage-explosion", 0.6)
    flammability_manager.add_flammable_item("explosive-cannon-shell",         false, 10, 7,  false,  "maticzplars-damage-explosion", 1)
    flammability_manager.add_flammable_item("uranium-cannon-shell",           false, 10, 7,  false,  "maticzplars-damage-explosion", 1)
    flammability_manager.add_flammable_item("explosive-uranium-cannon-shell", false, 10, 7,  false,  "maticzplars-damage-explosion", 1.4)

    flammability_manager.add_flammable_item("shotgun-shell",          false, 5, 2, false, "maticzplars-damage-explosion", 0.2)
    flammability_manager.add_flammable_item("piercing-shotgun-shell", false, 5, 3, false, "maticzplars-damage-explosion", 0.3)

    flammability_manager.add_flammable_item("explosives", false, 5, 20, false, "maticzplars-dynamite-explosion", 3)


    flammability_manager.add_flammable_fluid("crude-oil",     true, 15, 6,  false, "maticzplars-rocket-fuel-explosion", 0.5, true)
    flammability_manager.add_flammable_fluid("light-oil",     true, 1,  10, false, "maticzplars-rocket-fuel-explosion", 0.6)
    flammability_manager.add_flammable_fluid("heavy-oil",     true, 2,  10, false, "maticzplars-rocket-fuel-explosion", 0.6)
    flammability_manager.add_flammable_fluid("petroleum-gas", true, 2,  10, false, "maticzplars-rocket-fuel-explosion", 0.7)

    ---@type FlammabilityEdit
    local dont_burn = { strength = 0 }
    ---@type FlammabilityEdit
    local dont_burn_children = { dont_affect_products = true }
    
    flammability_manager.make_edit("plastic-bar",   dont_burn_children)
    flammability_manager.make_edit("lubricant",     dont_burn)
    flammability_manager.make_edit("sulfuric-acid", dont_burn)
    flammability_manager.make_edit("steel",         dont_burn)
    flammability_manager.make_edit("barrel",        dont_burn)
    flammability_manager.make_edit("rocket-part",   dont_burn)
    -- Space Age
    flammability_manager.make_edit("superconductor",    dont_burn)
    flammability_manager.make_edit("tungsten-carbide",  dont_burn)
    flammability_manager.make_edit("carbon-fiber",      dont_burn_children)
    flammability_manager.make_edit("fluoroketone-cold", dont_burn)
    flammability_manager.make_edit("electrolyte",       dont_burn)

    for name, _ in pairs(prototypes.get_item_filtered({{filter = "subgroup", subgroup = "science-pack" }})) do
        flammability_manager.make_edit(name, dont_burn)
    end


    calculate_flammabilities()
end

script.on_init(function ()
    load_flammables()
end)
script.on_configuration_changed(load_flammables)

script.on_event(
    defines.events.on_entity_damaged, 
	--- @param event EventData.on_entity_damaged
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
		--- @diagnostic disable-next-line missing-fields
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
	--- @param event EventData.on_entity_died
    function (event)
        if math.random(0, 100) < settings.global["maticzplars-pole-fire"].value then   
            local has_power = false
            for k, v in pairs(event.entity.electric_network_statistics.output_counts) do
                if v > 0.0 then
                    has_power = true
                end
            end

            if has_power then
				--- @diagnostic disable-next-line missing-fields
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

remote.add_interface("maticzplars-flammables", {
    ---@param name string
    ---@param fire_strength int
    ---@param fire_spread_cooldown int
    ---@param make_fireball boolean
    ---@param explosion_radius double
    ---@param explosion_prototype string?
    ---@param raw_resource boolean? Should be true if the item cannot be crafted from simpler items. This is used to prevent flammability calculations from using recipies for recyclers, crushers or anything else that might go from a more complex item to a less complex one.  
    add_item = function (name, fire_strength, fire_spread_cooldown, make_fireball, explosion_radius, explosion_prototype, raw_resource)
        flammability_manager.add_flammable_item(
            name, 
            make_fireball, 
            fire_spread_cooldown,
            fire_strength, 
            false, 
            explosion_prototype or "maticzplars-rocket-fuel-explosion", 
            explosion_radius,
            raw_resource or false
        )        
    end,

    ---@param name string
    ---@param fire_strength int
    ---@param fire_spread_cooldown int
    ---@param make_fireball boolean
    ---@param explosion_radius double
    ---@param explosion_prototype string?
    ---@param raw_resource boolean? 
    add_fluid = function (name, fire_strength, fire_spread_cooldown, make_fireball, explosion_radius, explosion_prototype, raw_resource)
        flammability_manager.add_flammable_fluid(
            name, 
            make_fireball, 
            fire_spread_cooldown,
            fire_strength, 
            false, 
            explosion_prototype or "maticzplars-rocket-fuel-explosion", 
            explosion_radius,
            raw_resource or false
        )        
    end,
        
    -- TODO: check this ignore param if needed and stuff
    ---@param ignore string?
    recalculate_flammables = function (ignore)
        calculate_flammabilities()
    end
})

init_ground_item_fire_events()