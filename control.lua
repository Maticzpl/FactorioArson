local calculate_flammabilities = require("lua/calc_flammability")
local flammability_manager = require("lua/flammability_manager")
local on_belt_fire = require("lua/belt_fire")
local on_container_fire = require("lua/container_fire")
local on_tank_fire = require("lua/fluid_tank_fire")
local init_ground_item_fire_events = require("lua/ground_item_fire")
local show_gui = require("lua/gui")
local mod_gui = require("mod-gui")

local function generate_barrels()    
    for _, fluid in pairs(storage.fluids) do
        local name = fluid.name.."-barrel"
        if storage.flammable[name] == nil then            
            storage.flammable[name] = {
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
    storage.edits = storage.edits or {}

    flammability_manager.add_flammable_item("wood",       false, 3, 2, false)
    flammability_manager.add_flammable_item("coal",       false, 2, 7, false)
    flammability_manager.add_flammable_item("solid-fuel", false, 1, 10, false)

    flammability_manager.add_flammable_item("rocket-fuel",       true, 8,  15, false, "maticzplars-rocket-fuel-explosion", 1)
    flammability_manager.add_flammable_item("flamethrower-ammo", true, 10, 16, false, "maticzplars-rocket-fuel-explosion", 0.5)

    flammability_manager.add_flammable_item("grenade",         false, 15, 2, false, "grenade-explosion", 3)
    flammability_manager.add_flammable_item("cluster-grenade", false, 15, 2, false, "grenade-explosion", 3)

    flammability_manager.add_flammable_item("firearm-magazine",         false, 5, 2, false, "maticzplars-damage-explosion", 0.2)
    flammability_manager.add_flammable_item("piercing-rounds-magazine", false, 5, 3, false, "maticzplars-damage-explosion", 0.3)
    flammability_manager.add_flammable_item("uranium-rounds-magazine",  false, 5, 4, false, "maticzplars-damage-explosion", 0.4)
    
    flammability_manager.add_flammable_item("rocket",                         false, 10, 10, false, "maticzplars-damage-explosion", 0.4)
    flammability_manager.add_flammable_item("explosive-rocket",               false, 10, 7, false,  "maticzplars-damage-explosion", 0.7)
    flammability_manager.add_flammable_item("cannon-shell",                   false, 10, 7, false,  "maticzplars-damage-explosion", 0.6)
    flammability_manager.add_flammable_item("explosive-cannon-shell",         false, 10, 7, false,  "maticzplars-damage-explosion", 1)
    flammability_manager.add_flammable_item("uranium-cannon-shell",           false, 10, 7, false,  "maticzplars-damage-explosion", 1)
    flammability_manager.add_flammable_item("explosive-uranium-cannon-shell", false, 10, 7, false,  "maticzplars-damage-explosion", 1.4)

    flammability_manager.add_flammable_item("shotgun-shell",          false, 5, 2, false, "maticzplars-damage-explosion", 0.2)
    flammability_manager.add_flammable_item("piercing-shotgun-shell", false, 5, 3, false, "maticzplars-damage-explosion", 0.3)

    flammability_manager.add_flammable_item("explosives", false, 5, 20, false, "maticzplars-dynamite-explosion", 3)


    flammability_manager.add_flammable_fluid("crude-oil",     true, 6, false,  "maticzplars-rocket-fuel-explosion", 0.5)
    flammability_manager.add_flammable_fluid("light-oil",     true, 10, false, "maticzplars-rocket-fuel-explosion", 0.6)
    flammability_manager.add_flammable_fluid("heavy-oil",     true, 10, false, "maticzplars-rocket-fuel-explosion", 0.6)
    flammability_manager.add_flammable_fluid("petroleum-gas", true, 10, false, "maticzplars-rocket-fuel-explosion", 0.7)

    calculate_flammabilities()
end

script.on_init(load_flammables)
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

storage.host_joined = false
script.on_event( -- TODO: Dont show on startup
	defines.events.on_player_created,
    --- @param event EventData.on_player_created
    function (event)
        if storage.host_joined then
            return
        end
        storage.host_joined = true
        
        mod_gui.get_button_flow(game.players[event.player_index]).add{
            type="sprite-button", 
            name="maticzplars-mod-button", 
            sprite="utility/refresh", 
            style=mod_gui.button_style
        }

        script.on_event(defines.events.on_gui_click, 
            --- @param click_event EventData.on_gui_click
            function (click_event)
                if click_event.element.name == "maticzplars-mod-button" then
                   show_gui(event) -- closures my beloved 
                end
            end
        )
    end
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
        storage.flammable[name] = {                
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
        storage.fluids[name] = {                
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
        
        for key, value in pairs(storage.flammable) do
            if value.calculated then
                storage.flammable[key] = nil
            end
        end
        for key, value in pairs(storage.fluids) do
            if value.calculated then
                storage.fluids[key] = nil
            end
        end
        items_from_recipes(to_ignore)
    end
})

init_ground_item_fire_events()