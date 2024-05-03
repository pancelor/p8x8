--[[pod_format="raw",created="2024-03-19 22:11:50",modified="2024-03-22 08:52:07",revision=282]]
-- make maps pico8-like

-- _map is a userdata("i16",128,64)
--   https://www.lexaloffle.com/dl/docs/picotron_userdata.html
local _map

function load_map(path)
	local map64 = fetch(path)
	if map64 then
		memmap(0x100000, map64[1].bmp)
		return map64[1].bmp --first layer
	end
end
function reload_map() --also called externally, from mem.lua
	_map = load_map"map/0.map"
end
reload_map()

if not _map then
	-- technically not quite right; some carts may entirely generate their own map
	function p8env.mget() end
	function p8env.mset() end
	function p8env.map() end
	p8env.mapdraw = p8env.map
	function p8env.tline() end

	return
end


function p8env.mget(x,y)
	return (mget(x,y) or 0)&255
end

function p8env.mset(x,y,val)
	-- &255: tested in p8 with: mset(0,0,700)?mget(0,0)
	mset(x,y,val&255)
end

-- initial concept by Oli414: https://www.lexaloffle.com/bbs/?pid=143207#p
function p8env.map(celx,cely, sx,sy, celw,celh, flags)
	celx = celx or 0
	cely = cely or 0
	sx = sx or 0
	sy = sy or 0
	celw = celw or 128
	celh = celh or 64
	
	-- TODO: speed: dont draw off-camera
	local cam_x,cam_y = peek4(0x5510,2)
	-- local tx0,ty0 = (camx-sx)\8,(camy-sy)\8
	-- camera(camx-sx,camy-sy)

	local _mget,fget,spr = p8env.mget,fget,spr
	if flags and flags!=0 then
		for dy=0,celh-1 do
			for dx=0,celw-1 do
				local tile = _mget(celx+dx,cely+dy)
				if tile!=0 and fget(tile)&flags>0 then --do any flags match?
					spr(tile,sx+dx*8,sy+dy*8)
				end
			end
		end
	else
		for dy=0,celh-1 do
			for dx=0,celw-1 do
				local tile = _mget(celx+dx,cely+dy)
				if tile!=0 then
					spr(tile,sx+dx*8,sy+dy*8)
				end
			end
		end
	end
	-- camera(camx,camy)
end
p8env.mapdraw = p8env.map

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
