local MAIN_GRID_COLUMNS = 18
local DESC_INGREDIANT_GRID_COLUMNS = 4
local DESC_SECTION_WIDTH = 51 * DESC_INGREDIANT_GRID_COLUMNS
local MAIN_SECTION_WIDTH = 49 * MAIN_GRID_COLUMNS
local WIDTH = MAIN_SECTION_WIDTH + DESC_SECTION_WIDTH
local HEIGHT = 600
local DRAGGABLE_HEIGHT = 24

local util = require("./utility")
local flammability_manager = require("flammability_manager")
local item_graph           = require("item_graph")
local mod_gui = require("mod-gui")
local calc_flammability = require("calc_flammability")

--- @type LuaGuiElement
local description_frame

--- @param content LuaGuiElement
local function fill_flammables_icons(content)
    content.clear()

	---@type { [string]: "item"|"fluid" }[]
    local graph_layers = {}

    -- TODO: Dont use raw storage. stuff for this
    for _, item in pairs(prototypes.item) do
        local flammability = flammability_manager.get_flammability(item.name)  
        if flammability then
            local prox = item_graph.get_depth_from_cache(item.name)
            if not prox then
                goto continue
            end
            prox = prox + 1 -- cause ipairs later

            if not graph_layers[prox] then
                graph_layers[prox] = {}
            end

            graph_layers[prox][item.name] = "item"
        end
        ::continue::
    end

    for _, fluid in pairs(prototypes.fluid) do
        local flammability = flammability_manager.get_flammability(fluid.name)  
        if flammability then
            local prox = item_graph.get_depth_from_cache(fluid.name)
            if not prox then
                goto continue
            end
            prox = prox + 1 

            if not graph_layers[prox] then
                graph_layers[prox] = {}
            end

            graph_layers[prox][fluid.name] = "fluid"
        end
        ::continue::
    end

    for prox, items in ipairs(graph_layers) do
        if prox ~= 1 then
            content.add({
                type = "line",
                style = "tooltip_horizontal_line",
                -- caption = "Depth: " .. prox,
                name = "maticzplars-depth-divider" .. prox
            })
        end

        local i = 0
        local row
        for item_name, kind in pairs(items) do
            if i % MAIN_GRID_COLUMNS == 0 then
                row = content.add({
                    type = "flow",
                    name = "maticzplars-icon-row-" .. prox .. "-" .. (i / MAIN_GRID_COLUMNS),
                    direction = "horizontal"
                })
            end
            i = i + 1

            local sprite = kind .. "/" .. item_name
            if not helpers.is_valid_sprite_path(sprite) then
                error(sprite .. " invalid sprite path")
            end

            --- @type LuaGuiElement
            local button_background = row.add({
                type = "button",
                name = "maticzplars-flammable-button-" .. item_name,
                style = "slot_button",
                sprite = sprite
            })
            button_background.style.margin = 1

            local edit = flammability_manager.get_edit(item_name)
            if edit.strength and edit.strength <= 0 then             
                button_background.style = "red_slot_button" -- TODO More colors for different stuff like "flammable but values changed"
            elseif edit.dont_affect_products then
                button_background.style = "yellow_slot_button"
            end

            --- @type LuaGuiElement
            local icon = button_background.add({ 
                type = "sprite",
                name = "maticzplars-sprite-" .. item_name,
                sprite = sprite
            })
            icon.raise_hover_events = false
            icon.ignored_by_interaction = true
            icon.resize_to_sprite = false
            icon.style.width = 32
            icon.style.height = 32
        end
    end
end

-- Calling this twice crashes TODO
--- @param event EventData.on_gui_click
local function show_gui(event)
    local screen = game.get_player(event.player_index).gui.screen

    local frame = screen.add({	
        type = "frame",
        name = "maticzplars-settings", 
        direction = "vertical"
    })
    frame.style.size = {WIDTH, HEIGHT}
    frame.auto_center = true

    local title_bar = frame.add({
        type = "flow",
        name = "maticzplars-title-bar",
        direction = "horizontal",
    })
    title_bar.drag_target = frame

    local title = title_bar.add({
        type = "label",
        name = "maticzplars-title-label",
        style = "frame_title",
        caption = "Arson - Edit flammables"
    })
    title.drag_target = frame

    local draggable = title_bar.add({
        type = "empty-widget",
        name = "maticzplars-drag",
        style = "draggable_space_header",
    })
    draggable.drag_target = frame
    draggable.style.horizontally_stretchable = true
    draggable.style.height = DRAGGABLE_HEIGHT

    title_bar.add({
        type = "sprite-button",
        name = "maticzplars-button-close",
        sprite = "utility/close",
        style = "frame_action_button"
    })

    local hcont = frame.add({
        type = "flow",
        name = "maticzplars-horizontal-container",
        direction = "horizontal"
    })
    hcont.style.horizontally_stretchable = true

    local content = hcont.add({
        type = "scroll-pane",
        name = "maticzplars-content-scroll",
        direction = "vertical"
    })
    content.style.vertically_stretchable = true
    content.vertical_scroll_policy = "auto-and-reserve-space"

    fill_flammables_icons(content)

    description_frame = hcont.add({
        type = "frame",
        name = "maticzplars-description-frame",
        direction = "vertical"
    })
    description_frame.style.vertically_stretchable = true
    description_frame.style.width = DESC_SECTION_WIDTH
end

local function show_description(identifier)
    -- TODO: List edits as in is no longer flammable, has explosion size changed etc

    --- @type any
    local prototype = prototypes.item[identifier]
    local flammability = flammability_manager.get_flammability(identifier)
    if not prototype then
        prototype = prototypes.fluid[identifier]
    end

    description_frame.clear()

    if not flammability then
        return
    end

    local title = description_frame.add({
        type = "label",
        caption = prototype.localised_name,
        name = "maticzplars-desc-title",
        style = "orange_label",
    })
    title.style.single_line = false
    title.style.maximal_width = DESC_SECTION_WIDTH - 20

    local burn_rate = ""
    if flammability.cooldown then
        burn_rate = "\nBurn Rate: " .. string.format("%.2f", (100 / flammability.cooldown))
    end
    flammability.explosion_radius = flammability.explosion_radius or 0

    local desc_label = description_frame.add({
        type = "label",
        name = "maticzplars-desc",
        caption = "Flammability: " ..  string.format("%.2f", flammability.strength) ..
            "\nExplosion Size: " .. string.format("%.2f", flammability.explosion_radius) ..
            "\nFireball: " .. tostring(flammability.fireball) ..
        burn_rate
    })
    desc_label.style.single_line = false

    description_frame.add({
        type = "label",
        caption = "Flammable Ingredients",
        name = "maticzplars-desc-ingredients",
        style = "orange_label",
    })


    --- @type {[string]: Ingredient}
    local ingredients = {}

    for _, item in pairs(item_graph.get_parent_items(identifier, true)) do
        local flammability = flammability_manager.get_flammability(item.name)
        if flammability and flammability.strength > 0 then
            ingredients[item.name] = item
        end
    end

    local i = 0
    local row
    for name, _ in pairs(ingredients) do
        if i % 4 == 0 then
            row = description_frame.add({
                type = "flow",
                direction = "horizontal"
            })
        end
        i = i + 1

        local sprite = "item/" .. name

        if not prototypes.item[name] then
            sprite = "fluid/" .. name					
        end

        --- @type LuaGuiElement
        local button_background = row.add({
            type = "button",
            name = "maticzplars-desc-button-" .. name,
            style = "slot_button",
            sprite = sprite
        })
        button_background.style.margin = 1

        local icon = button_background.add({
            type = "sprite",
            name = "maticzplars-desc-sprite",
            sprite = sprite
        })
        icon.resize_to_sprite = false
        icon.ignored_by_interaction = true
        icon.resize_to_sprite = false
        icon.style.width = 32
        icon.style.height = 32
    end

    description_frame.add({
        type = "empty-widget"
    }).style.vertically_stretchable = true

    local button_frame = description_frame.add({
        type = "flow",
        direction = "vertical"
    })
    button_frame.style.horizontal_align = "center"
    button_frame.style.natural_width = DESC_SECTION_WIDTH

    local caption = "Don't affect products"
    if flammability.dont_affect_products then 
        caption = "Affect products" 
    end
    local affect_button = button_frame.add({
        type = "button",
        name = "maticzplars-affect-products-button",
        caption = caption
    })

    caption = "Make flammable"
    if (flammability.strength or 0) > 0 then 
        caption = "Make nonflammable" 
    end
    local flammable_button = button_frame.add({
        type = "button",
        name = "maticzplars-toggle-flammable-button",
        caption = caption,
    })

end


script.on_event(
    defines.events.on_player_created,
    --- @param player_created_event EventData.on_player_created
    function (player_created_event)
        -- TODO Check how this is supposed to work in multiplayer
        
        mod_gui.get_button_flow(game.players[player_created_event.player_index]).add{
            type="sprite-button", 
            name="maticzplars-mod-button", 
            sprite="utility/refresh", -- TODO: a nice sprite for the button
            style=mod_gui.button_style
        }        
    end
)

local selected_flammable = ""

script.on_event(defines.events.on_gui_click, 
    --- @param event EventData.on_gui_click
    function (event)
        if event.element.name == "maticzplars-mod-button" then
            show_gui(event)
            return
        end

        if event.element.name == "maticzplars-button-close" then
            event.element.parent.parent.destroy()
            return
        end

        local refresh = false

        -- TODO: obv more settings for edits
        if event.element.name == "maticzplars-toggle-flammable-button" then        
            local current = flammability_manager.get_edit(selected_flammable)
            if current.strength and current.strength == 0 then
                flammability_manager.clear_edit(selected_flammable)
            else
                flammability_manager.make_edit(selected_flammable, {strength = 0})
            end

            refresh = true
        end

        if event.element.name == "maticzplars-affect-products-button" then
            local current = flammability_manager.get_edit(selected_flammable)
            if current.dont_affect_products then
                flammability_manager.clear_edit(selected_flammable)
            else
                flammability_manager.make_edit(selected_flammable, {dont_affect_products = true})
            end

            refresh = true
        end

        if string.find(event.element.name, "^maticzplars%-flammable%-button%-") or 
            (string.find(event.element.name, "^maticzplars%-desc%-button%-")) then
            local name_split = {}
            local identifier = ""
            for fragment in string.gmatch(event.element.name, '([^%-]+)') do
                if #name_split >= 3 then
                    identifier = identifier .. "-" .. fragment
                end
                table.insert(name_split, fragment)
            end
            identifier = identifier:sub(2)
            show_description(identifier)

            selected_flammable = identifier
        end

        if refresh then            
            calc_flammability({selected_flammable})

            local screen = game.get_player(event.player_index).gui.screen
            fill_flammables_icons(screen["maticzplars-settings"]["maticzplars-horizontal-container"]["maticzplars-content-scroll"])
            show_description(selected_flammable)
        end

    end
)

return {show_gui = show_gui}
