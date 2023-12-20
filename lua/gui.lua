local host_joined = false;
local hover

--- @param event EventData.on_player_created
local function show_gui(event)
	if host_joined then
		return
	end

	host_joined = true


	local screen = game.get_player(event.player_index).gui.screen

	hover = screen.add{
		type = "frame",
		name = "arson_hover",
		direction = "vertical"
	}
	hover.visible = false

	local frame = screen.add{	
		type = "frame",
		name = "arson_settings", 
        direction = "vertical"
	}
	frame.style.size = {800, 600}
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
		caption = "Arson"
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


	local content = frame.add{
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
		if global.flammable[fluid.name] then
			local prox = global.proximity_cache[fluid.name] + 1

			if not flammables_sorted[prox] then
				flammables_sorted[prox] = {}
			end

			flammables_sorted[prox][fluid.name] = "fluid"
		end
	end

	for prox, items in ipairs(flammables_sorted) do
		content.add{
			type = "label",
			caption = "Depth: " .. prox,
			name = "arson_depth_label_" .. prox
		}

		for item_name, kind in pairs(items) do
			local sprite = kind .. "/" .. item_name
			if not game.is_valid_sprite_path(sprite) then
				error(sprite .. " invalid sprite path")
			end
			
			--- @type LuaGuiElement
			local icon = content.add{ -- TODO, put icons in a neat grid
				type = "sprite",
				name = "arson_sprite_" .. item_name,
				sprite = sprite
			}
			icon.raise_hover_events = true
			
			
		end
	end
end

script.on_event(defines.events.on_gui_hover, -- TODO: Finish hover window
	--- @param event EventData.on_gui_hover
	function (event)
		if string.find(event.element.name, "^arson_sprite_") then
			hover.position = event.element.position
			hover.visible = true
		else	
			hover.visible = false
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
