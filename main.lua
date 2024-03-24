--[[pod_format="raw",created="2024-03-15 21:08:04",modified="2024-03-18 07:44:15",revision=616]]
include "src/pq.lua"
include "src/gui.lua"

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
		label = "\^:7f4141417f616500 Import .p8 File",
		shortcut = "CTRL-O",
		action = function()
			real_intention="import_p8"
			create_process("/system/apps/filenav.p64", {
				path="/desktop",
				intention="save_file_as", -- TODO: I'd rather use "open_file" but the filesystem doesn't let me process the file -- it tries to literally open it (and fails b/c it doesn't know how to open a .p8)
				window_attribs={workspace = "current", autoclose=true},
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
	end
end)


---------------
-- IMPORTING --
---------------


function reset_sprimp()
	img=nil
	mapdat=nil
	window{
		width  = 140,
		height = 120,
		title  = "p8 spr/map import",
	}
	generate_gui()
end

function set_img_from_clipboard()
	return set_img_from_gfx(get_clipboard())
end

-- pass a "[gfx]...[/gfx]" string to load it into the `img` global
function set_img_from_gfx(str)
	local newimg = userdata(str)
	if not newimg then
		notify(string.format("* error: want '[gfx]...[/gfx]', got '%s...'",sub(str,0,4)))
		return
	end
	img=newimg
	
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

function import_p8(fullpath)
	local filestr = fetch(fullpath)
	assert(filestr)
	
	do
		-- __gfx__
		-- thanks Krystman! https://www.youtube.com/@LazyDevs
		-- https://www.lexaloffle.com/bbs/?pid=143596#p
		local hexdata = p8_section_extract(filestr,"__gfx__")
		if not hexdata then
			notify("* error: no __gfx__ section found")
			return
		end
		hexdata = hexdata:gsub("\n", "")
		local w,h = 128,128
		local sizestr = string.format("%02x%02x",mid(0,255,w),mid(0,255,h))
		set_img_from_gfx("[gfx]"..sizestr..hexdata.."[/gfx]")
	end
	
	do
		-- __map__
		local hexdata = p8_section_extract(filestr,"__map__")
		if not hexdata then
			notify("* error: no __map__ section found")
			return
		end
		hexdata = hexdata:gsub("\n", "")
		set_map_from_hexdata(hexdata)
	end
end

function set_map_from_hexdata(hexdata)
	-- bmp holds i16s: ?({fetch("/ram/cart/map/0.map")[1].bmp:attribs()})[3]
	-- they're more than just u8 b/c tile flipping is supported (what else?)
	local w,h = 128,64
	local bmp = userdata("i16",w,h)
	for i=0,#hexdata/2-1 do
		local x,y = i%w,i\w
		if x<w and y<h then
			local byte = tonumber("0x"..sub(hexdata,i*2+1,i*2+2))
			bmp:set(x,y,byte)
		end
	end
	-- view expected structure with: podtree /ram/cart/map/0.map
	mapdat = {
		{ -- just one layer
			bmp = bmp,
			tile_w = 8,
			tile_h = 8,
			-- start view in top-left
			pan_x = -188,
			pan_y = -10,
			zoom = 0.5,
		},
	}
end

-- returns the contents of a pico8 file section (e.g. __gfx__)
-- returns the entire string, with newlines and all
-- returns nil if the section can't be found
-- usage: local gfxstr = p8_section_extract(filestr,"__gfx__"):gsub("\n", "")
function p8_section_extract(filestr,header)
	local i0,i1 = p8_section_find(filestr, header)
	if not i0 then
		return
	end
	return filestr:sub(i0,i1)
end

-- e.g. p8_section_find(myFile,"__gfx__")
-- returns indices for use with str:sub()
-- usage: local gfx = filestr:sub(p8_section_find(filestr,"__gfx__"))
function p8_section_find(filestr,header)
	local a0,a1 = string.find(filestr,header)
	if not a0 then
		return
	end
	-- find next section, or EOF
	local b0 = string.find(filestr, "__", a1+1)
	if b0 then
		return a1+1, b0-1
	else
		return a1+1, #filestr
	end
end

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
	if not mapdat then
		notify("* error: no map data")
		return
	end
	assert(fullpath,"no filename?")

	store(fullpath, mapdat) --save

	-- open gfx editor
	create_process("/system/util/open.lua",
		{
			argv = {fullpath},
			pwd = "/ram/cart",
		}
	)
end

function export_gfx(fullpath)
	if not img then
		notify("* error: no image data")
		return
	end
	assert(fullpath,"no filename?")
	
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
				flags = 0,
				zoom = 8,
				pan_x = 0,
				pan_y = 0,
			}
		end
	end
	store(fullpath, sprites) --save

	-- open gfx editor
	create_process("/system/util/open.lua",
		{
			argv = {fullpath},
			pwd = "/ram/cart",
		}
	)
end


