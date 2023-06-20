local explosion = util.copy(data.raw["explosion"]["pipe-explosion"])

local strenght = settings.startup["maticzplars-explosion-damage"].value

explosion.type = "flame-thrower-explosion"
explosion.name = "maticzplars-rocket-fuel-explosion"
explosion.damage = {amount = strenght, type = "explosion"}
explosion.slow_down_factor = 0.0


local dynamite_explosion = util.copy(data.raw["explosion"]["passive-provider-chest-explosion"])

dynamite_explosion.type = "flame-thrower-explosion"
dynamite_explosion.name = "maticzplars-dynamite-explosion"
dynamite_explosion.damage = {amount = strenght, type = "explosion"}
dynamite_explosion.slow_down_factor = 0.0


local dmg_explosion = util.copy(data.raw["explosion"]["explosion-hit"])

dmg_explosion.type = "flame-thrower-explosion"
dmg_explosion.name = "maticzplars-damage-explosion"
dmg_explosion.damage = {amount = strenght, type = "explosion"}
dmg_explosion.slow_down_factor = 0.0

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