--[[pod_format="raw",created="2024-03-15 21:08:04",modified="2024-03-18 02:34:47",revision=474]]
include "src/pq.lua"
include "src/gui.lua"

function _init()
	window{
		width  = 140,
		height = 110,
		title  = "p8 sprite import",
	}
	
	menuitem{
		id = "open_file",
		label = "\^:7f4141417f616500 Import .p8 file",
		shortcut = "CTRL-O",
		action = function()
			real_intention="import"
			create_process("/system/apps/filenav.p64", {
				path="/desktop",
				intention="save_file_as", --"open_file" doesn't let me open it myself
				window_attribs={workspace = "current", autoclose=true},
			})
		end
	}
	
	generate_gui()
	-- checkboard colors
	pal(0x20,0x1a1520,2)
	pal(0x21,0x0f0415,2)
end

--on_event("open_file",function(...)
--	pqn(...)
--end)

function _update()
	if key"ctrl" then
		if keyp"v" then
			set_img_from_clipboard()
		end
	end
	gui:update_all()
end

function clear_img()
	img=nil
end

function set_img_from_clipboard()
	return set_img_from_gfx(get_clipboard())
end
function set_img_from_gfx(str)
	local cdat = str --"[gfx]...[/gfx]"
	local newimg = userdata(cdat)
	if not newimg then
		notify(string.format("* error: want '[gfx]...[/gfx]', got '%s...'",sub(cdat,0,4)))
		return
	end
	img=newimg
	
	window{
		width = max(get_display():width(), img:width()),
		height = max(get_display():height(), img:height()+gui_extra_h),
	}
	generate_gui()
end

function _draw()
	cls(key"alt" and 6 or 5)
	gui:draw_all()
end

on_event("resize", function(msg)
	generate_gui(msg.width,msg.height)
end)

function on_click_save(self)
	if not img then
		notify("* error: import an image first")
		return
	end
	real_intention="export"
	create_process("/system/apps/filenav.p64", {
		path="/ram/cart/gfx",
		intention="save_file_as",
		window_attribs={workspace = "current", autoclose=true},
	})
end
-- invoked by filenav intention
on_event("save_file_as", function(msg)
	if real_intention=="import" then
		intent_import(msg)
	elseif real_intention=="export" then
		intent_export(msg)
	end
end)

function intent_export(msg)
	if not img then
		notify("* error: image lost")
		return
	end
	if not msg or not msg.filename then
		notify("* error: filename not given")
		return
	end
	
	local iw,ih=img:attribs()

	local item = {}
	for i=0,255 do
		local bmp = userdata("u8",8,8)
		local x,y = i%16*8,i\16*8
		if x+8<=iw and y+8<=ih then
			pq("blit",x,y)
			blit(img,bmp,x,y,0,0) --from,to, fromx,y, tox,y
			item[i] = {
				bmp = bmp,
				flags = 0,
				pan_x = 0,
				pan_y = 0,
				zoom = 8,
			}
		end
	end	
	store(msg.filename,item)
--	notify("saved as "..msg.filename)

	-- open gfx editor
	create_process("/system/util/open.lua",
		{
			argv = {msg.filename},
			pwd = "/ram/cart",
		}
	)
end

on_event("drop_items",function(msg)
	for item in all(msg.items) do
		if item.pod_type == "file_reference" then
			if item.attrib == "file" and item.fullpath:ext()=="p8" then
				set_img_from_p8(item.fullpath)
			end
		end
	end
end)

function intent_import(msg)
	set_img_from_p8(msg.filename)
end

-- thanks Krystman!! https://www.youtube.com/@LazyDevs
-- https://www.lexaloffle.com/bbs/?pid=143596#p
function set_img_from_p8(fullpath)
	local myFile = fetch(fullpath)
	assert(myFile)

	local i0,i1 = p8_section_find(myFile, "__gfx__")
	if not i0 then
		notify("* error: no __gfx__ section found")
		return
	end
	local hexdata = myFile:sub(i0,i1):gsub("\n", "")
	local w,h = 128,128
	local sizestr = string.format("%02x%02x",mid(0,128,w),mid(0,128,h))
	set_img_from_gfx("[gfx]"..sizestr..hexdata.."[/gfx]")
end


-- e.g. p8_section_find(myFile,"__gfx__")
-- returns indices for use with str:sub()
-- example: local gfx = filestr:sub(p8_section_find(filestr,"__gfx__"))
function p8_section_find(str,header)
	local a0,a1 = string.find(str,header)
	if not a0 then
		return
	end
	local b0 = string.find(str, "__", a1+1) or #str+1
	return a1+1, b0-1
end


