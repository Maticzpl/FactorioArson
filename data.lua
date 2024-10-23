local strenght = settings.startup["maticzplars-explosion-damage"].value

-- TODO, fix and redo EVERYTHING
local explosion = util.copy(data.raw["explosion"]["medium-explosion"])
explosion.name = "maticzplars-rocket-fuel-explosion"

local dynamite_explosion = util.copy(data.raw["explosion"]["medium-explosion"])
dynamite_explosion.name = "maticzplars-dynamite-explosion"

local dmg_explosion = util.copy(data.raw["explosion"]["medium-explosion"])
dmg_explosion.name = "maticzplars-damage-explosion"

dmg_explosion.type = "explosion"
dmg_explosion.name = "maticzplars-damage-explosion"
dmg_explosion.damage = {amount = strenght, type = "explosion"}


local fire_mod = util.copy(data.raw["fire"]["fire-flame"])
fire_mod.created_effect = 
{
    type = "direct",
    action_delivery = {
        type = "instant",
        source_effects = {
            {
                type = "script",
                effect_id = "maticzplars-fire-created",
            },
        }
    }
}


data:extend({
    explosion,
    dynamite_explosion,
    dmg_explosion,
    fire_mod
})