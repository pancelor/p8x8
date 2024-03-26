--[[pod_format="raw",created="2024-03-19 22:23:15",modified="2024-03-22 14:04:27",revision=521]]
--[[
the goal is to make major things work.
  but the goal is NOT to be a 1:1 pico8 emulator.
  cart authors will need to hand-edit their converted picotron carts.
]]

local function planned(name, basic)
	if basic then
		return function()
			compat("todo: basic support for "..name)
		end
	else
		return function()
			compat("todo: support for "..name)
		end
	end
end

p8env.run=planned("run",true)
p8env.extcmd=planned("extcmd",true)



-- do not port these
-- cart authors must manually decide how to implement what they want inside picotron

local function rejected(name)
	return function()
		compat(name.." is not supported by p8x8")
	end
end

p8env.serial=rejected"serial"
p8env.load=rejected"load"
p8env.cstore=rejected"cstore"

p8env.holdframe=rejected"holdframe"
p8env._set_fps=rejected"_set_fps"
p8env._update_buttons=rejected"_update_buttons"
p8env._mark_cpu=rejected"_mark_cpu"

p8env._startframe=rejected"_startframe"
p8env._update_framerate=rejected"_update_framerate"
p8env._set_mainloop_exists=rejected"_set_mainloop_exists"

p8env._map_display=rejected"_map_display"
p8env._get_menu_item_selected=rejected"_get_menu_item_selected"
p8env._pausemenu=rejected"_pausemenu"

p8env.set_draw_slice=rejected"set_draw_slice"
