--[[pod_format="raw",created="2024-03-15 21:08:04",modified="2024-04-03 21:55:58",revision=1412]]
printh"---"


dev = fstat"/ram/devmode.txt" and env().corun_program
-- dev_export_filename = dev and "/desktop/temp.p64"


local function _include_lib(name,cond)
	if (cond) cp("/appdata/system/"..name,"/ram/cart/"..name)
	include(name)
end
local function include_lib(name) _include_lib(name,dev and not fstat(name)) end
local function include_libf(name) _include_lib(name,dev) end --force


include_lib "lib/pq.lua"
include_lib "lib/sort.lua"
include "src/tool.lua"

include "src/gui.lua"
include "src/import.lua"
include "src/warn.lua"
include "src/export.lua"


function _init()
	reset_state() --set up the window
	pqn("hello!")
	menuitem{
		id = "clear",
		label = "\^:0f19392121213f00 Clear",
		shortcut = "CTRL-N",
		action = reset_state,
	}
	menuitem{
		id = "open_file",
		label = "\^:00387f7f7f7f7f00 Import .p8",
		shortcut = "CTRL-O",
		action = function()
			real_intention="import_p8"
			create_process("/system/apps/filenav.p64", {
				path="/desktop",
				intention="save_file_as", -- TODO: I'd rather use "open_file" but the filesystem doesn't let me process the file -- it tries to literally open it (and fails b/c it doesn't know how to open a .p8)
				window_attribs={workspace="current", autoclose=true},
				--use_ext="p8",
			})
		end,
	}
	menuitem{
		id = "export_p64",
		label = "\^:7f4141417f616500 Export .p64",
		shortcut = "CTRL-E",
		action = action_export_p64,
	}

	-- edit palette (bg checkboard)
	pal(0x20,0x1a1520,2)
	pal(0x21,0x0f0415,2)
end

function _update()
	if has_focus then
		gui:update_all()
	end
end

function _draw()
	gui:draw_all()
end

has_focus=true
on_event("lost_focus",function() has_focus=false end)
on_event("gained_focus",function() has_focus=true end)

on_event("resize", function(msg)
	generate_gui(msg.width,msg.height)
end)

-- invoked by filenav intention
on_event("save_file_as", function(msg)
	-- HACK: open_file doesn't work nicely, so I run multiple actions pretending to be "save as", because they let me give the user a file chooser without taking any automatic action
	if real_intention=="import_p8" then
		import_p8(msg.filename)
	elseif real_intention=="export_p64" then
		export_p64(msg.filename)
	end
end)


----------
-- DATA --
----------


function reset_state()
	active_cart = nil
	gui_set_preview_image(nil)
	export_path = nil

	window{
		width  = 140,
		height = 104,
		title  = "p8x8 converter",
		autoclose = true, -- esc=quit
	}
	generate_gui()
end

-- drag-and-drop .p8 files from the desktop
on_event("drop_items",function(msg)
	local err
	for item in all(msg.items) do
		if item.pod_type == "file_reference" then
			if item.attrib == "file" then
				local ext = item.fullpath:ext()
				if ext == "p8" then
					import_p8(item.fullpath)
					return
				else
					err = string.format("*error: want a '.p8' file, got '%s'",ext)
				end
			else
				err = "*error: want a '.p8' file, got a folder"
			end
		end
	end
	if err then
		notify(err)
	end
end)

--on_event("open_file",function(...)
--	pqn(...)
--end)

---------------

function action_export_p64()
	if dev_export_filename then
		export_p64(dev_export_filename)
	else
		export_p64(export_path)
		--[[
		-- TODO: open filepicker with default file of export_path
		-- I'm not sure how to set the default name (is it possible?)
		real_intention="export_p64"
		create_process("/system/apps/filenav.p64", {
			path="/desktop",
			intention="save_file_as",
			window_attribs={workspace="current", autoclose=true},
		})
		--]]
	end
end




