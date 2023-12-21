local MAIN_GRID_COLUMNS = 18
local DESC_INGREDIANT_GRID_COLUMNS = 4
local DESC_SECTION_WIDTH = 51 * DESC_INGREDIANT_GRID_COLUMNS
local MAIN_SECTION_WIDTH = 39 * MAIN_GRID_COLUMNS
local WIDTH = MAIN_SECTION_WIDTH + DESC_SECTION_WIDTH
local HEIGHT = 600


local util = require("./utility")

local host_joined = false;
--- @type LuaGuiElement
local description_frame

--- @param event EventData.on_player_created
local function show_gui(event)
	if host_joined then
		return
	end

	host_joined = true


	local screen = game.get_player(event.player_index).gui.screen

	local frame = screen.add{	
		type = "frame",
		name = "arson_settings", 
        direction = "vertical"
	}
	frame.style.size = {WIDTH, HEIGHT}
	frame.auto_center = true

	local title_bar = frame.add{
        type = "flow",
        name = "arson_title_bar",
        direction = "horizontal",
    }
	title_bar.drag_target = frame

	local title = title_bar.add{
		type = "label",
		name = "arson_title_label",
		style = "frame_title",
		caption = "Arson Edit Flammables"
	}
	title.drag_target = frame

    local draggable = title_bar.add{
        type = "empty-widget",
        name = "arson_drag",
        style = "draggable_space_header",
    }
	draggable.drag_target = frame
    draggable.style.horizontally_stretchable = true
	draggable.style.height = 24

    title_bar.add{
        type = "sprite-button",
        name = "arson_button_close",
        sprite = "utility/close_white",
        style = "frame_action_button"
    }


	local hcont = frame.add{
		type = "flow",
		name = "arson_horizontal_container",
		direction = "horizontal"
	}

	local content = hcont.add{
		type = "scroll-pane",
		name = "arson_content_scroll",
		direction = "vertical"
	}
	content.style.horizontally_stretchable = true
	
	local flammables_sorted = {}

	for _, item in pairs(game.item_prototypes) do
		if global.flammable[item.name] then
			local prox = global.proximity_cache[item.name] + 1 -- cause ipairs later

			if not flammables_sorted[prox] then
				flammables_sorted[prox] = {}
			end

			flammables_sorted[prox][item.name] = "item"
		end
	end

	for _, fluid in pairs(game.fluid_prototypes) do
		if global.fluids[fluid.name] then
			local prox = global.proximity_cache[fluid.name] + 1

			if not flammables_sorted[prox] then
				flammables_sorted[prox] = {}
			end

			flammables_sorted[prox][fluid.name] = "fluid"
		end
	end

	for prox, items in ipairs(flammables_sorted) do
		if prox ~= 1 then
			content.add{
				type = "line",
				style = "tooltip_horizontal_line",
				-- caption = "Depth: " .. prox,
				name = "arson_depth_divider" .. prox
			}
		end

		local i = 0
		local row
		for item_name, kind in pairs(items) do
			if i % MAIN_GRID_COLUMNS == 0 then
				row = content.add{
					type = "flow",
					name = "arson_icon_row_" .. prox .. "_" .. (i / MAIN_GRID_COLUMNS),
					direction = "horizontal"
				}
			end
			i = i + 1

			local sprite = kind .. "/" .. item_name
			if not game.is_valid_sprite_path(sprite) then
				error(sprite .. " invalid sprite path")
			end
			
			--- @type LuaGuiElement
			local icon = row.add{ 
				type = "sprite",
				name = "arson_sprite_" .. item_name,
				sprite = sprite
			}
			icon.raise_hover_events = true
			icon.resize_to_sprite = false
			icon.style.width = 32
			icon.style.height = 32
			
			
		end
	end


	description_frame = hcont.add{
		type = "frame",
		name = "arson_description_frame",
		direction = "vertical"
	}
	description_frame.style.width = DESC_SECTION_WIDTH
end

local last_hover_tick = 0
script.on_event(defines.events.on_gui_hover, -- TODO: Finish hover window
	--- @param event EventData.on_gui_hover
	function (event)
		if string.find(event.element.name, "^arson_sprite_") or 
		   (string.find(event.element.name, "^arson_descsprite_") and event.tick - last_hover_tick > 10) then
			last_hover_tick = event.tick

			local itter = string.gmatch(event.element.name, '([^_]+)')
			itter()
			itter()
			local flammable = itter()


			--- @type any
			local prototype = game.item_prototypes[flammable]
			local flammability = global.flammable[flammable]
			if not prototype then
				prototype = game.fluid_prototypes[flammable]
				flammability = global.fluids[flammable]
			end


			description_frame.clear()

			local title = description_frame.add{
				type = "label",
				caption = prototype.localised_name,
				name = "arson_desc_title",
				style = "orange_label",
			}
			title.style.single_line = false
			title.style.maximal_width = DESC_SECTION_WIDTH - 20


			local burn_rate = ""
			if flammability.cooldown then
				burn_rate = "\nBurn Rate: " .. string.format("%.00f", (100 / flammability.cooldown))
			end
			flammability.explosion_radius = flammability.explosion_radius or 0

			local desc_label = description_frame.add{
				type = "label",
				name = "arson_desc",
				caption = "Flammability: " ..  string.format("%.00f", flammability.strength) ..
					"\nExplosion Size: " .. string.format("%.00f", flammability.explosion_radius) ..
					"\nFireball: " .. tostring(flammability.fireball) ..
					burn_rate
			}
			desc_label.style.single_line = false


			description_frame.add{
				type = "label",
				caption = "Flammable Ingredients",
				name = "arson_desc_ingredients",
				style = "orange_label",
			}

			
			--- @type {[string]: Ingredient}
			local ingredients = {}

			local recipie_tables = {global.recipies_item_cache, global.recipies_fluid_cache}
			local recipie_table = util.mergeTables(recipie_tables)
			for _, recipie in ipairs(recipie_table[flammable]) do
				for _, ingredient in pairs(recipie.ingredients or {}) do
					if (global.flammable[ingredient.name] or global.fluids[ingredient.name]) and 
						global.proximity_cache[ingredient.name] < global.proximity_cache[flammable] then
						ingredients[ingredient.name] = ingredient
					end
				end
			end

			local i = 0
			local row
			for name, _ in pairs(ingredients) do
				if i % 4 == 0 then
					row = description_frame.add{
						type = "flow",
						direction = "horizontal"
					}
				end
				i = i + 1

				local sprite = "item/" .. name

				if not game.item_prototypes[name] then
					sprite = "fluid/" .. name					
				end

				local icon = row.add{
					type = "sprite",
					name = "arson_descsprite_" .. name,
					sprite = sprite
				}
				icon.resize_to_sprite = false
				icon.raise_hover_events = true
				icon.style.width = 32
				icon.style.height = 32
			end
		end
		
	end
)

script.on_event(defines.events.on_gui_click, 
	--- @param event EventData.on_gui_click
	function(event)
		if event.element.name == "arson_button_close" then
			event.element.parent.parent.destroy()
		end
	end
)

return show_gui
