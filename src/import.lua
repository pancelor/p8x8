--[[pod_format="raw",created="2024-03-19 02:49:51",modified="2024-04-03 21:56:10",revision=858]]
function import_p8(path)
	local ext = path:ext()
	if fstat(path)~="file" then
		notify_printh(string.format("*error: can't find file '.%s'",path))
		return
	end
	if ext~="p8" then
		notify_printh(string.format("*error: want a '.p8' file, got '.%s'",ext))
		return
	end
	notify_printh "importing..."
	export_path = sub(path,1,-#ext-2)..".p64"
	active_cart = parse_p8(path)
	gui_set_preview_image(active_cart.gfx)
	if process_code(active_cart) then
		notify_printh "imported!"
	end
end



function parse_p8(path)
	local filestr = fetch(path)
	assert(filestr)
	filestr = filestr:gsub("\r\n","\n") -- normalize line endings
	
	local cart = {}
	cart.lua = parse_p8_lua(filestr)
	cart.gfx = parse_p8_gfx(filestr)
	cart.gff = parse_p8_gff(filestr)
	cart.map = parse_p8_map(filestr)
	cart.lua_warn = nil
--	__label__
--	cart.sfx = parse_p8_sfx(filestr)
--	cart.music = parse_p8_music(filestr)
	return cart
end

-- returns a list of strings (tab contents)
function parse_p8_lua(filestr)
	local tabs = {}

	local luastr = p8_section_extract(filestr,"__lua__")
	if not luastr then
		printh "parse_p8_lua: skipping missing section: __lua__"
	else
		local ri = 1 --read index
		for _=0,100 do --should be 16 tabs max? 100 to be safe
			local i0,i1 = luastr:find("\n-->8\n",ri,true) --true=exact match (don't activate "a-" lua pattern)
			if i0 then
				add(tabs,luastr:sub(ri,i0-1)) --found a tab, extract it
				ri = i1+1
			else
				add(tabs,luastr:sub(ri)) --extract last tab
				break
			end
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
		return userdata("u8",128,128)
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
	-- bmp holds i16s: ?({fetch("/ram/cart/map/0.map")[1].bmp:attribs()})[3]
	-- they're more than just u8 b/c tile flipping is supported (what else?)
	local w,h = 128,64
	local ud = userdata("i16",w,h)

	local mapdata = p8_section_extract(filestr,"__map__")
	if not mapdata then
		printh "parse_p8_map: skipping missing section: __map__"
	else
		mapdata = mapdata:gsub("\n", "")

		for i=0,#mapdata/2-1 do
			local x,y = i%w,i\w
			if x<w and y<h then
				local n1 = num_from_hex(mapdata,i*2+1)
				local n2 = num_from_hex(mapdata,i*2+2)
				ud:set(x,y,n1*16+n2)
			end
		end
	end

	local gfxdata = p8_section_extract(filestr,"__gfx__")
	if not gfxdata then
		printh "parse_p8_map: skipping missing section: __gfx__"
	else
		gfxdata = split(gfxdata,"\n",false) -- NOTE: array of lines
		
		-- extract rest of map from sprites
		for i=65,#gfxdata do
			local ln = gfxdata[i]
			for j=0,#ln/2-1 do
				local n1 = num_from_hex(ln,j*2+1)
				local n2 = num_from_hex(ln,j*2+2)
				local tile = n2*16+n1
				local x,y = j + (i&1==1 and 0 or 64), (i-1)\2
				ud:set(x,y,tile)
			end
		end
	end

	return ud
end

-- untested
function parse_p8_sfx(filestr)
	local sfxdata = p8_section_extract(filestr,"__sfx__")
	local ud = userdata("u8",0x30000)
 
	if not sfxdata then
		printh "parse_p8_sfx: skipping missing section: __sfx__"
	else
		sfxdata = split(sfxdata,"\n",false) -- NOTE: array of lines

		for i,ln in ipairs(sfxdata) do
			assert(#ln==168,"sfx line in p8 file has wrong character length: "..#ln)
			for x=1,8 do
				-- TODO: ????AABB A/B are the loop params. view is set in there I think - tracker v. drawmode
				-- num_from_hex(ln,x)
			end
			for ni=0,31 do --note index
				local aa,bb,cc,dd,ee = num_from_hex(ln,9+ni*5),num_from_hex(ln,9+ni*5+1),num_from_hex(ln,9+ni*5+2),num_from_hex(ln,9+ni*5+3),num_from_hex(ln,9+ni*5+4)
				local pitch = (aa&0x3)<<4 | bb
				local waveform = cc&0x7 -- drop custom_wv data
				local custom_wv = cc>>3 -- 0 or 1
				local volume = dd
				local effect = ee

				-- TODO https://github.com/pancelor/p8x8/issues/5

				-- > volume: 1-7 in pico-8 correspond to 8,10,18,20,28,30,38 in picotron
				-- > pitch: octaves 0-5 in pico-8 seem to correspond to 2-7 in picotron

				-- effects: https://www.lexaloffle.com/dl/docs/picotron_synth.html#Effect_Commands

				--[[
					-- picotron .sfx format:
					mysfx=fetch"/ram/cart/sfx/0.sfx"
					?type(mysfx)
					--userdata
					?qq(mysfx:attribs())
					--196608 1 u8 1
					--196608==0x30000
					--https://www.lexaloffle.com/dl/docs/picotron_synth.html#Memory_Layout

					-- see sfx.p64/data.lua -- layout looks straightforward/documented enough to be usable
					-- https://www.lexaloffle.com/bbs/?pid=visitrack#p might also have insights
				--]]
			end
		end
	end

	return ud
end

--[[
x = 0
for b in bytes(clean[:8]):
    cart.rom.set8(mem_sfx_info_addr(y, x), b)
    x += 1
x = 0
for bph, bpl, bw, bv, be in nybble_groups(clean[8:], 5):
    if x < 0x20:
        value = bpl | ((bph & 0x3) << 4) | ((bw & 0x7) << 6) | ((bv & 0x7) << 9) | ((be & 0x7) << 12) | ((bw & 0x8) << 12) 
        cart.rom.set16(mem_sfx_addr(y, x), value)
        x += 1
y += 1
--]]



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
