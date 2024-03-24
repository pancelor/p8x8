--[[pod_format="raw",created="2024-03-15 21:08:04",modified="2024-03-17 12:50:20",revision=202]]
include "src/pq.lua"
include "src/gui.lua"

function _init()
	window{
		width  = 128,
		height = 128,
		title  = "Sprite import",
	}

	generate_gui()
end


function _update()
	if key"ctrl" then
		if keyp"v" then
			set_img_from_clipboard()
		end
	end
	gui:update_all()
end

function set_img_from_clipboard()
	local cdat = get_clipboard() --"[gfx]...[/gfx]"
--	local c,m = unpod(cdat)
	img = userdata(cdat)
	if not img then
		notify(string.format("* error: want '[gfx]...[/gfx]', got '%s...'",sub(cdat,0,4)))
		return
	end
	
	window{
		width  = img:width(),
		height = img:height()+gui_extra_h,
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
	create_process("/system/apps/filenav.p64", {
		path="/ram/cart/gfx",
		intention="save_file_as",
		window_attribs={workspace = "current", autoclose=true},
	})
end
-- invoked by filenav intention
on_event("save_file_as", function(msg)
	if not img then
		notify("* error: image lost")
		return
	end

	local item = {}
	for i=0,255 do
		local bmp = userdata("u8", CELW, CELH)
		local x,y = i%16*8,i\16*8
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
	store(msg.filename,item)
	notify("saved as "..msg.filename)
	
--	local CELW,CELH = 8,8
--	local width_cels = img:width()\CELW
--	local height_cels = img:height()\CELW
--	for cy=0,height_cels do
--		for cx=0,width_cels do
--			local ud = userdata("u8", CELW, CELH)
--			blit(img,ud,cx*CELW,cy*CELH,0,0) --from,to, fromx,y, tox,y
--		end
--	end
end)
-- convert spr number si from img into userdata
function ud_from_spr(si)

end

