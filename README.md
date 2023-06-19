# Factorio arson mod
This mod will make a lot of things in your factory flammable and even explosive.  

![ohnodotgif](https://maticzpl.xyz/share/factorio/responsible%20storage.gif)
Damaged oil tanks are more likely to catch fire!
Be careful routing your belts, flammable items can cause a chain reaction.
Now that's an OSHA violation!

## Some details
Items like coal, wood, rocket fuel, flamethrower ammo, normal ammo, explosives, oil barrels etc. will spread fire on belts, some will cause small explosions.
Chests with flammable / explosive items can catch fire when their hp falls below 100 (configurable) and upon destruction can explode. Some items will cause a fireball upon explosion (mainly liquids like oils, rocket fuel etc.)
Fluid tanks as well as fluid wagons can catch fire when their hp falls down enough. If they contain crude/light/heavy oil or petroleum gas they will explode with a small fireball.
Cargo wagons carrying flammable/explosive items behave similarly to how chests do in a fire.
Since bitters can't really start fires, there is a small chance that destroying a power pole will start a fire :D
Explosion and fireball sizes all depend on the amount of items / fluid inside or on a belt.

PVP might be fun with this :P

## Modded items
Most modded things should work by default. This is not the case with item properties.
As of now each mod would have to add in their burnable/explosive items manually.
This may change in the future with items based on crafting recipe or fuel value.
To add your custom items/fluids do the following:
Add "Arson" as an optional dependency
`"dependencies": ["? Arson"]`
Inside control.lua call the proper functions of "maticzplars-flammables" interface
```lua
    local function add_flammables()
        if remote.interfaces["maticzplars-flammables"] and remote.interfaces["maticzplars-flammables"].add_item then
            remote.call("maticzplars-flammables", "add_item", 
                "iron-plate",  -- Item name
                5, -- Fire strength
                10, -- Fire spread cooldown
                true, -- Make fireball
                0.5 -- Explosion radius
            )    
            remote.call("maticzplars-flammables", "add_fluid", 
                "water", -- Fluid name
                5, -- Fire strength
                true, -- Make fireball
                0.5 -- Explosion radius
            )    
        end
    end
    script.on_init(add_flammables)
    script.on_configuration_changed(add_flammables)
```
The above example will make iron plates and water tanks flammable :P
