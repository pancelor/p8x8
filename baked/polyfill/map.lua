--[[pod_format="raw",created="2024-03-19 22:11:50",modified="2024-03-20 02:06:01",revision=136]]
-- make maps pico8-like

--this is a userdata object: https://www.lexaloffle.com/dl/docs/picotron_userdata.html
local _map -- = userdata("i16",128,64)
do
	local map64 = fetch("map/0.map") 
	if map64 then
		_map = map64[1].bmp --first layer
	end
end

if not _map then
	printh "no map found"
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
	local cx0 = celx
	local cy0 = cely
	local cx1 = cx0+celw-1
	local cy1 = cy0+celh-1
	local _mget = p8env.mget
	if flags and flags!=0 then
		for cy=cy0,cy1 do
			for cx=cx0,cx1 do
				local tile = _mget(cx,cy)
				if tile>0 and fget(tile)&flags==flags then
					spr(tile,sx+(cx-cx0)*8,sy+(cy-cy0)*8)
				end
			end
		end
	else
		for cy=cy0,cy1 do
			for cx=cx0,cx1 do
				local tile = _mget(cx,cy)
				if tile>0 then
					spr(tile,sx+(cx-cx0)*8,sy+(cy-cy0)*8)
				end
			end
		end
	end
end
p8env.mapdraw = p8env.map
