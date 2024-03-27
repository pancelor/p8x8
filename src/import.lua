--[[pod_format="raw",created="2024-03-19 02:49:51",modified="2024-03-22 14:26:42",revision=849]]
function import_p8(path)
	local ext = path:ext()
	if ext != "p8" then
		notify_printh(string.format("*error: want a '.p8' file, got '.%s'",ext))
		return
	end
	notify_printh "importing..."
	export_path = sub(path,1,-#ext-2)..".p64"
	active_cart=parse_p8(path)
	gui_set_preview_image(active_cart.gfx)
	if process_code(active_cart) then
		notify_printh "imported!"
	end
end



function parse_p8(path)
	local filestr = fetch(path)
	assert(filestr)
	filestr = filestr:gsub("\r\n","\n") -- normalize line endings
	
	local cart={}
	cart.lua=parse_p8_lua(filestr)
	cart.gfx=parse_p8_gfx(filestr)
	cart.gff=parse_p8_gff(filestr)
	cart.map=parse_p8_map(filestr)
	cart.lua_warn=nil
--	__label__
--	cart.sfx=parse_p8_sfx(filestr)
--	cart.music=parse_p8_music(filestr)
	return cart
end

-- returns a list of strings (tab contents)
function parse_p8_lua(filestr)
	local luastr = p8_section_extract(filestr,"__lua__")
	if not luastr then
		printh "missing section: __lua__"
		return
	end
	local tabs = {}
	local ri = 1 --read index
	for _=0,100 do -- should be 16 tabs max? 100 to be safe
		local i0,i1 = luastr:find("\n-->8\n",ri,true) -- true: don't activate "a-" pattern recognition -- TODO check for CRLF?
		if i0 then
			add(tabs,luastr:sub(ri,i0-1)) -- found a tab, extract it
			ri = i1+1
		else
			add(tabs,luastr:sub(ri)) -- extract last tab
			break
		end
	end
	return tabs
end

function rpad(str,pad,num)
	if #str>num then
		return str
	end
	assert(#pad==1)
	return str..string.rep(pad,num-#str)
end

-- returns a userdata holding the graphics
function parse_p8_gfx(filestr)
	-- thanks Krystman! https://www.youtube.com/@LazyDevs
	-- https://www.lexaloffle.com/bbs/?pid=143596#p
	local hexdata = p8_section_extract(filestr,"__gfx__")
	if not hexdata then
		printh "missing section: __gfx__"
		return
	end
	hexdata = hexdata:gsub("\n", "")
	hexdata = rpad(hexdata,"0",128*128)
	return userdata("[gfx]8080"..hexdata.."[/gfx]")
end

-- returns a userdata holding the sprite flags
function parse_p8_gff(filestr)
	local hexdata = p8_section_extract(filestr,"__gff__")
	if not hexdata then
		return userdata("u8",256)
	end
	hexdata = hexdata:gsub("\n", "")
	hexdata = rpad(hexdata,"0",256)
	return userdata("u8",256,hexdata)
end

-- returns a userdata holding the map
function parse_p8_map(filestr)
	local mapdata = p8_section_extract(filestr,"__map__")
	if not mapdata then
		printh "missing section: __map__"
		-- TODO techincally this is returning too early b/c map could be only on bottom half
		-- but no thanks, the code complexity is not worth it. that just wont work in this tool
		return
	end
	mapdata = mapdata:gsub("\n", "")

	local gfxdata = p8_section_extract(filestr,"__gfx__")
	if not gfxdata then
		printh "(parse_p8_map) missing section: __gfx__"
		return
	end
	gfxdata = split(gfxdata,"\n",false) -- NOTE: array of lines

	-- bmp holds i16s: ?({fetch("/ram/cart/map/0.map")[1].bmp:attribs()})[3]
	-- they're more than just u8 b/c tile flipping is supported (what else?)
	local w,h = 128,64
	local ud = userdata("i16",w,h)
	for i=0,#mapdata/2-1 do
		local x,y = i%w,i\w
		if x<w and y<h then
			local n1 = num_from_hex(sub(mapdata,i*2+1,i*2+1))
			local n2 = num_from_hex(sub(mapdata,i*2+2,i*2+2))
			ud:set(x,y,n1*16+n2)
		end
	end
	
	-- extract rest of map from sprites
	for i=65,#gfxdata do
		local ln = gfxdata[i]
		for j=0,#ln/2-1 do
			local n1 = num_from_hex(sub(ln,j*2+1,j*2+1))
			local n2 = num_from_hex(sub(ln,j*2+2,j*2+2))
			local tile = n2*16+n1
			local x,y = j + (i&1==1 and 0 or 64), (i-1)\2
			ud:set(x,y,tile)
		end
	end
	
	return ud
end

-- returns the contents of a pico8 file section (e.g. __gfx__)
-- returns the entire string, with newlines and all
-- returns nil if the section can't be found
-- usage: local gfxstr = p8_section_extract(filestr,"__gfx__"):gsub("\n", "")
function p8_section_extract(filestr,header)
	local i0,i1 = p8_section_find(filestr,header)
	if not i0 then
		return
	end
	return filestr:sub(i0,i1)
end

-- e.g. p8_section_find(myFile,"__gfx__")
-- returns indices for use with str:sub()
-- usage: local gfx = filestr:sub(p8_section_find(filestr,"__gfx__"))
function p8_section_find(filestr,header)
	local a0,a1 = string.find(filestr,header.."\n")
	if not a0 then
		return
	end
	-- find next section, or EOF
	local b0 = string.find(filestr, "\n__", a1+1)
	if b0 then
		return a1+1, b0-1
	else
		return a1+1, #filestr
	end
end
