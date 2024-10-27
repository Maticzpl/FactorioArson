---@type integer
local strength = settings.startup["maticzplars-explosion-damage"].value

local explode_effect = {    
    type = "area",
    radius = 3,
    action_delivery =
    {
        type = "instant",
        target_effects =
        {
            {
                type = "damage",
                damage = {amount = strength, type = "explosion"}
            },
            {
                type = "create-entity",
                entity_name = "explosion"
            }
        }
    }      
}

-- TODO, fix and redo EVERYTHING
local explosion = util.copy(data.raw["explosion"]["medium-explosion"])
explosion.created_effect = explode_effect
explosion.name = "maticzplars-rocket-fuel-explosion"

local dynamite_explosion = util.copy(data.raw["explosion"]["medium-explosion"])
dynamite_explosion.created_effect = explode_effect
dynamite_explosion.name = "maticzplars-dynamite-explosion"

local dmg_explosion = util.copy(data.raw["explosion"]["medium-explosion"])
dmg_explosion.created_effect = explode_effect
dmg_explosion.name = "maticzplars-damage-explosion"

-- dmg_explosion.type = "explosion"
-- dmg_explosion.name = "maticzplars-damage-explosion"
-- dmg_explosion.damage = {amount = strength, type = "explosion"}


for _, fire_name in ipairs({"fire-flame", "fire-flame-on-tree"}) do
    local fire_mod = util.copy(data.raw["fire"][fire_name])
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
    data:extend({fire_mod})
end

--


data:extend({
    explosion,
    dynamite_explosion,
    dmg_explosion,
})