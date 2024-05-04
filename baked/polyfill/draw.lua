--[[pod_format="raw",created="2024-03-19 23:27:45",modified="2024-03-22 13:58:18",revision=468]]
--COMPAT: p8scii is not supported. other differences?
function p8env.print(...)
	if select("#",...)==2 then
		compat("print(msg,col) is not supported")
	end
	return print(...)
end

-- to read the i-th pal(0) entry, use `p64env.peek(0x8000+i*0x40)&0xf` instead of `peek(0x5f00+i)`
-- to read the i-th pal(1) entry, use `p64env.peek(0x5480+i)` instead of `peek(0x5f10+i)`
function p8env.pal(...)
	--COMPAT: not well-tested yet. pal()/pal(0)/pal(1) in particular
	local c0,c1,p
	local nargs = select("#",...)
	if nargs==0 then
		-- reset palettes
		pal(0)
		pal(1)
		return
	elseif nargs==1 then
		-- reset palette
		return pal(...)
	elseif nargs==2 then
		c0,c1 = select(1,...)
		if type(c0)=="table" then
			p = c1
			c1 = nil
			for k,v in pairs(c0) do
				if v&0xf~=v then
					c0[k] = (v&0xf)|48 --rebase secret colors to 48
				end
			end
			if p==2 then compat("pal(2) is not supported") end
			return pal(c0,p)
		else
			p = 0
			-- fallthrough
		end
	elseif nargs>=3 then
		c0, c1, p = select(1,...)
		-- fallthrough
	end

	if c1==nil then
		c1 = 0
	elseif c1&0xf~=c1 then
		c1 = (c1&0xf)|48 --rebase secret colors to 48
	end
	if p==2 then compat("pal(2) is not supported") end
	return pal(c0,c1,p)
	--COMPAT: p8's pal returns the old value, but picotron's (and p8x8's) does not.
end
function p8env.palt(...)
	if select("#",...)==0 then
		-- no args = reset
		palt(0)
		palt(0,true)
	else
		palt(...) -- COMPAT: surely the alt pal stuff is different now
	end
end

p8env.camera=camera

--[[
local p8camx,p8camy = 0,0
function p8env.camera(x,y)
	-- cam_x,cam_y=peek4(0x5510,2) --camera
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

-- COMPAT: color no longer returns old value, and
-- @0x5f25 doesn't find the pen color. I'm not sure how to access it
p8env.color=color

-- COMPAT: cursor no longer returns the old values, and
-- @0x5f26/@0x5f27 returns 0. I'm not sure how to access it
p8env.cursor=cursor

p8env.fillp=fillp
p8env.circ=circ
p8env.circfill=circfill
p8env.clip=clip
p8env.line=line
p8env.oval=oval
p8env.ovalfill=ovalfill
p8env.pget=pget
p8env.rect=rect
p8env.rectfill=rectfill
p8env.pset=pset --COMPAT: negative colors may act strangely
--[[ this version avoids some bugs, but I don't want to make pset slow
function p8env.pset(x,y,...)
	if select("#",...)>0 then
		pset(x,y,select(1,...)%16) --negative colors act strangely, in picotron terminal at least
	else
		pset(x,y)
	end
end
--]]

p8env.flip=flip -- single flip is correct
--[[
function p8env.flip()
	if p8env._update then
		flip() -- double at 30fps
	end
	flip()
end
--]]

-- NOTE: sspr() uses _gfx_all, spr() uses _gfx_sheet (unless w/h are >1).
-- this means if you edit your sprites in the picotron editor, you
-- need to edit both .gfx files. this is unfortunate! you should remove
-- _gfx_sheet entirely and only use _gfx_all.
-- note the individual sprites can be arbitrarily sized in picotron -- you
-- can stuff a full 128x128 image into a single sprite if you want
local _gfx_all,_gfx_sheet
function reload_sprites()
	local full = fetch("gfx/full.gfx")
	_gfx_all = full[1].bmp
	_gfx_sheet = fetch("gfx/0.gfx")
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
		--fset(n,[f],val)
		val,f=f,val
	end
	if f then
		local mask=1<<f
		fset(n,(fget(n)&~mask) | (val and mask or 0))
	else
		val = (tonumber(val) or 0)&255 --I didn't test to see if this is necessary
		fset(n,val)
	end
end
