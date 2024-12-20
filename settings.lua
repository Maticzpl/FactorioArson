data:extend({
    {
        type = "double-setting",
        name = "maticzplars-belt-spread",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0.01,
        maximum_value = 10.0,
    },
    {
        type = "int-setting",
        name = "maticzplars-underground-max-length",
        setting_type = "runtime-global",
        default_value = 4,
        minimum_value = 0,
        maximum_value = 50,
    },
    {
        type = "double-setting",
        name = "maticzplars-explosion-size",
        setting_type = "runtime-global",
        default_value = 1.0,
        minimum_value = 0.0,
        maximum_value = 4.0,
    },
    {
        type = "int-setting",
        name = "maticzplars-explosion-damage",
        setting_type = "startup",
        default_value = 15,
        minimum_value = 0,
        maximum_value = 1000,
    },
    {
        type = "int-setting",
        name = "maticzplars-container-leak-hp",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 40,
        maximum_value = 1000,
    },
    {
        type = "bool-setting",
        name = "maticzplars-fireball",
        setting_type = "runtime-global",
        default_value = true,
    },
    {
        type = "double-setting",
        name = "maticzplars-pole-fire",
        setting_type = "runtime-global",
        default_value = 10.0,
        minimum_value = 0.0,
        maximum_value = 100.0,
    },
    {
        type = "bool-setting",
        name = "maticzplars-burn-ground-items",
        setting_type = "runtime-global",
        default_value = true,
    }
})