--[[pod_format="raw",created="2024-03-19 02:49:51",modified="2024-03-19 05:50:51",revision=240]]
function import_p8(fullpath)
	cart=parse_p8(fullpath)
	set_img_from_ud(cart.gfx)
end

function parse_p8(fullpath)
	local filestr = fetch(fullpath)
	assert(filestr)
	
	local cart={}
	cart.lua=parse_p8_lua(filestr)
	cart.gfx=parse_p8_gfx(filestr)
	cart.gff=parse_p8_gff(filestr)
	cart.map=parse_p8_map(filestr)
--	__label__
--	cart.sfx=parse_p8_sfx(filestr)
--	cart.music=parse_p8_music(filestr)
	return cart
end

-- returns a list of strings (tab contents)
function parse_p8_lua(filestr)
	local luastr = p8_section_extract(filestr,"__lua__")
	if not luastr then
		notify("* error: no __lua__ section found")
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

-- returns a userdata holding the graphics
function parse_p8_gfx(filestr)
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
	return userdata("[gfx]"..sizestr..hexdata.."[/gfx]")
end

-- returns a userdata holding the sprite flags
function parse_p8_gff(filestr)
	local hexdata = p8_section_extract(filestr,"__gff__")
	if not hexdata then
		notify("* error: no __gff__ section found")
		return
	end
	hexdata = hexdata:gsub("\n", "")
	return userdata("u8",256,hexdata)
end

-- returns a userdata holding the map
function parse_p8_map(filestr)
	local hexdata = p8_section_extract(filestr,"__map__")
	if not hexdata then
		notify("* error: no __map__ section found")
		return
	end
	hexdata = hexdata:gsub("\n", "")
	return build_map_ud_from_hexdata(hexdata)
end

function build_map_ud_from_hexdata(hexdata)
	-- bmp holds i16s: ?({fetch("/ram/cart/map/0.map")[1].bmp:attribs()})[3]
	-- they're more than just u8 b/c tile flipping is supported (what else?)
	local w,h = 128,64
	local ud = userdata("i16",w,h)
	for i=0,#hexdata/2-1 do
		local x,y = i%w,i\w
		if x<w and y<h then
			local n1 = num_from_hex(sub(hexdata,i*2+1,i*2+1))
			local n2 = num_from_hex(sub(hexdata,i*2+2,i*2+2))
			ud:set(x,y,n1*16+n2)
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
	local a0,a1 = string.find(filestr,header.."\n") -- TODO CRLF?
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
