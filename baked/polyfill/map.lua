--[[pod_format="raw",created="2024-03-19 22:11:50",modified="2024-03-22 08:52:07",revision=282]]
-- make maps pico8-like

--_map is a userdata("i16",128,64)
--  https://www.lexaloffle.com/dl/docs/picotron_userdata.html
local _map 

function load_map(path)
	local map64 = _fetch_local(path) 
	if map64 then
		return map64[1].bmp --first layer
	end
end
function reload_map() --also called externally, from mem.lua
	_map = load_map"map/0.map"
end
reload_map()

if not _map then
	function p8env.mget() end
	function p8env.mset() end
	function p8env.map() end
	p8env.mapdraw = p8env.map

	return
end


function p8env.mget(x,y)
	return _map:get(x,y)&255
end

function p8env.mset(x,y,val)
	-- &255: tested in p8 with: mset(0,0,700)?mget(0,0)
	_map:set(x,y,val&255)
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
	local _mget = p8env.mget
	if flags and flags!=0 then
		for dy=0,celh-1 do
			for dx=0,celw-1 do
				local tile = _mget(celx+dx,cely+dy)
				if tile!=0 and fget(tile)&flags==flags then
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
end
p8env.mapdraw = p8env.map
	