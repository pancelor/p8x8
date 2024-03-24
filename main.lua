--[[pod_format="raw",created="2024-03-15 21:08:04",modified="2024-03-19 05:50:51",revision=804]]
printh"---"
include "src/pq.lua"
include "src/gui.lua"
include "src/import.lua"
include "src/tool.lua"

function _init()
	reset_sprimp() --set up the window

	menuitem{
		id = "clear",
		label = "\^:0f19392121213f00 Clear",
		shortcut = "CTRL-N",
		action = reset_sprimp,
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
			})
		end,
	}
	menuitem{
		id = "export_p64",
		label = "\^:7f4141417f616500 Export .p64",
		shortcut = "CTRL-E",
		action = function()
			real_intention="export_p64"
			create_process("/system/apps/filenav.p64", {
				path="/desktop",
				intention="save_file_as",
				window_attribs={workspace="current", autoclose=true},
			})
		end,
	}

	-- edit palette (bg checkboard)
	pal(0x20,0x1a1520,2)
	pal(0x21,0x0f0415,2)
end

function _update()
	if key"ctrl" and keyp"v" then
		set_img_from_clipboard()
	end
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
	elseif real_intention=="export_gfx" then
		export_gfx(msg.filename)
	elseif real_intention=="export_map" then
		export_map(msg.filename)
	elseif real_intention=="export_p64" then
		export_p64(msg.filename)
	end
end)


----------
-- DATA --
----------


function reset_sprimp()
	cart = nil  --HACK: awkward that both this and img exist(?)
	img = nil
	
	window{
		width  = 140,
		height = 120,
		title  = "p8 spr/map import",
	}
	generate_gui()
end

-- pass a string like "[gfx]...[/gfx]" to load it into the `img` global
function set_img_from_clipboard()
	local str = get_clipboard()
	local ud = userdata(str)
	if not ud then
		notify(string.format("* error: want '[gfx]...[/gfx]', got '%s...'",sub(str,0,4)))
		return
	end
	set_img_from_ud(ud)
end

function set_img_from_ud(ud)
	if not ud then return end
	img = ud
	
	-- resize window to fit spritesheet
	local w,h = img:attribs()
	gui_resize_to_fit(w,h)
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
					err = string.format("* error: want a '.p8' file, got '%s'",ext)
				end
			else
				err = "* error: want a '.p8' file, got a folder"
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
-- EXPORTING --
---------------


function on_click_savegfx()
	if not img then
		notify("* error: no image data")
		return
	end
	real_intention="export_gfx"
	create_process("/system/apps/filenav.p64", {
		path="/ram/cart/gfx",
		intention="save_file_as",
		window_attribs={workspace = "current", autoclose=true},
	})
end
function on_click_savemap()
	if not mapdat then
		notify("* error: no map data")
		return
	end
	real_intention="export_map"
	create_process("/system/apps/filenav.p64", {
		path="/ram/cart/map",
		intention="save_file_as",
		window_attribs={workspace = "current", autoclose=true},
	})
end

function export_map(fullpath)
	if not cart or not cart.map then
		notify("* error: no map data")
		return
	end
	assert(fullpath,"no filename?")

	-- view expected structure with: podtree /ram/cart/map/0.map
	local mapdat = {
		{ -- first map layer
			bmp = cart.map,
			tile_w = 8,
			tile_h = 8,
			-- start view in top-left
			pan_x = -188,
			pan_y = -10,
			zoom = 0.5,
		},
	}
	store(fullpath, mapdat) --save
	notify("exported "..fullpath)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {fullpath},
--			pwd = "/ram/cart",
--		}
--	)
end

function export_gfx(fullpath)
	if not img then
		notify("* error: no image data")
		return
	end
	assert(fullpath,"no filename?")
	
	local gff = cart and cart.gff
	local iw,ih = img:attribs()

	local sprites = {}
	for i=0,255 do
		local bmp = userdata("u8",8,8)
		local x,y = i%16*8,i\16*8
		if x+8<=iw and y+8<=ih then
			--pq("blit",x,y)
			blit(img,bmp,x,y,0,0) --from,to, fromx,y, tox,y, w,h
			-- see /system/apps/gfx.p64
			sprites[i] = {
				bmp = bmp,
				flags = gff and gff[i] or 0,
				zoom = 8,
				pan_x = 0,
				pan_y = 0,
			}
		end
	end
	store(fullpath, sprites) --save
	notify("exported "..fullpath)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {fullpath},
--			pwd = "/ram/cart",
--		}
--	)
end

function export_p64(fullpath)
	if not cart then
		notify("* error: must import a .p8 first")
		return
	end
	assert(fullpath,"no filename?")

	if fullpath:ext() != "p64" then
		notify("* error: must export as a .p64")
		return
	end
	if fstat(fullpath) then
		notify("* error: must export a new file, cannot overwrite one")
		return
	end

	-- ensure trailing slash
	if sub(fullpath,#fullpath)!="/" then
		fullpath ..="/"
	end	

	mkdir(fullpath)
	mkdir(fullpath.."gfx")
	mkdir(fullpath.."map")
	mkdir(fullpath.."src")
	mkdir(fullpath.."sfx") -- probably not necessary? but startup.lua makes it by default

	export_gfx(fullpath.."gfx/0.gfx")
	export_map(fullpath.."map/0.map")
	-- export code tabs
	for ti=1,#cart.lua do
		local fname = string.format("%ssrc/%d.lua",fullpath,ti-1)
		store(fname,cart.lua[ti])
	end
	
	-- store open file metadata
	-- see /system/wm/wm.lua:save_open_locations_metadata or new.lua (bbs util)
	-- TODO maybe export into /ram/cart ? don't want to overwrite without warning tho..

	--pq(fetch_metadata("/desktop/03mar/sprimp.p64"))
	local meta = {}
	meta.workspaces = {}
	add(meta.workspaces, {location = "map/0.map", workspace_index=3})
	add(meta.workspaces, {location = "gfx/0.gfx", workspace_index=2})
	for ti=1,#cart.lua do
		local fname = string.format("src/%d.lua#1",ti-1)
		add(meta.workspaces, {location = fname, workspace_index=1})
	end	
	store_metadata(fullpath,meta)

	notify("exported "..fullpath)
end





