--[[pod_format="raw",created="2024-03-19 23:27:45",modified="2024-03-22 13:58:18",revision=468]]
--swap fonts (see /system/lib/head.lua)
poke(0x5f56, 0x56) -- primary font
poke(0x5f57, 0x40) -- secondary font

p8env.print=print --COMPAT: p8scii is not supported. other differences?
p8env.pal=pal --COMPAT: not quite the same. might need some checks for pal({},1) etc
function p8env.palt(...)
	if select("#",...)==0 then
		-- no args = reset
		palt(0)
		palt(0,true)
	else
		palt(...) -- COMPAT: surely the alt pal stuff is different now
	end
end
function p8env.tline(x0,y0,x1,y1,mx,my, mdx,mdy)
	compat("TODO: tline support")
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

p8env.camera=camera

--[[
local p8camx,p8camy = 0,0
function p8env.camera(x,y)
	local oldx,old = p8camx,p8camy
	p8camx,p8camy = ((x or 0)\1)&65535,((y or 0)\1)&65535
	camera(p8camx,p8camy)
	return oldx,oldy
end

function p8env.reset()
	p8env.camera()
	reset()
end
--]]
p8env.reset=reset

-- COMPAT:
--  pico8's cls() resets the clip region, and not the camera
--  picotron's cls() resets neither
--  p8x8 wont fix this; you must manually change your cart!
--[[
function p8env.cls(...)
	clip()
	local a,b=camera()
	pqn(a,b,...)
	rectfill(0,0,127,127,...)
	camera(a,b)
end
--]]
p8env.cls=cls

p8env.fillp=fillp
p8env.circ=circ
p8env.circfill=circfill
p8env.clip=clip
p8env.color=color
p8env.cursor=cursor
p8env.line=line
p8env.oval=oval
p8env.ovalfill=ovalfill
p8env.pget=pget
p8env.pset=pset
p8env.rect=rect
p8env.rectfill=rectfill
p8env.flip=flip -- TODO: needs to be doubled at 30fps

-- NOTE: sspr() uses _gfx_all, spr() uses _gfx_sheet (unless w/h are >1).
-- this means if you edit your sprites in the picotron editor, you
-- need to edit both .gfx files. this is unfortunate! you could remove
-- _gfx_sheet entirely and only use _gfx_all
local _gfx_all,_gfx_sheet
function reload_sprites()
	_gfx_all = _fetch_local("gfx/full.gfx")[1].bmp
	_gfx_sheet = _fetch_local("gfx/0.gfx")
end
reload_sprites()
function p8env.sset(x,y,val)
	_gfx_bmp:set(x,y,val&15)
	local sx,sy = x\8,y\8
	if sx&15==sx and sy&15==sy then
		_gfx_sheet[sx+sy*16].bmp:set(x&7,y&7,val&15)
	end
	-- COMPAT: a more accurate emulator would edit the map here,
	--   but p8x8 does not support that
end
function p8env.sget(x,y)
	return _gfx_all:get(x,y)&15
end
function p8env.sspr(...)
	sspr(_gfx_all,...)
end
function p8env.spr(s,x,y,w,h,flpx,flpy)
	s=(s or 0)\1
	x=x or 0
	y=y or 0
	w=w or 1
	h=h or 1
	if w==1 and h==1 then
		spr(s,x,y,flpx,flpy) --this implicitly uses _gfx_sheet
	else
		sspr(_gfx_all,(s&15)*8,s\16*8,w*8,h*8,x,y,w*8,h*8,flpx,flpy)
	end
end

function p8env.fget(n, f)
	if f then
		return (fget(n)>>f)&1==1
	else
		return fget(n)
	end
end

function p8env.fset(n, f, val)
	if val==nil then
		val,f=f,val
	end
	if f then
		compat"todo: test fset f"
		local mask=1<<f
		fset(n,fget(n)&~mask|(val and mask or 0))
	else
		fset(n,val)
	end
end
