--[[pod_format="raw",created="2024-03-19 22:11:50",modified="2024-03-22 08:52:07",revision=282]]
-- _map is a userdata("i16",128,64)
--   https://www.lexaloffle.com/dl/docs/picotron_userdata.html
local _map

function reload_map() --also called externally, from mem.lua
	_map = fetch"map/0.map"
	if _map and _map[1] and _map[1].bmp then
		memmap(0x100000, _map[1].bmp)
	end
end
reload_map()
-- poke(0x5f36,@0x5f36 & ~0x8) -- don't draw sprite 0

function p8env.mget(x,y)
	return (mget(x,y) or 0)&255
end

function p8env.mset(x,y,val)
	-- &255: tested in p8 with: mset(0,0,700)?mget(0,0)
	mset(x,y,(tonum(val) or 0)&255)
end

p8env.map=map
p8env.mapdraw=map

function p8env.tline(x0,y0,x1,y1,mx,my, mdx,mdy)
	compat("TODO: tline() support. currently implementation is likely wrong and will change") --https://github.com/pancelor/p8x8/issues/8

	-- this is untested and probably wrong
	local u0,v0,u1,v1 = mx,my,mdx,mdy
	return tline3d(_map, x0, y0, x1, y1, u0, v0, u1, v1)

	--[[
	http://pico8wiki.com/index.php?title=Tline
	https://www.lexaloffle.com/dl/docs/picotron_gfx_pipeline.html#tline3d
		tline3d(src, x0, y0, x1, y1, u0, v0, u1, v1, [w0, w1])
		
		src can be either a bitmap or a map
		x,y are screen pixels (ints)
		u,v are texture coordinates in pixels
		w is 1/z, useful for perspective-correct texture mapping
		u,v should be given as u/z and v/z
		when w0 and w1 are both 1 (the default), tline3d is linear
	]]
end
