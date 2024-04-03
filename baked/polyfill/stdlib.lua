--[[pod_format="raw",created="2024-03-19 22:54:36",modified="2024-03-22 14:26:42",revision=361]]
----------------
-- MATH
----------------

-- COMPAT: p8 has a custom PRNG,
--   p64 uses lua's math.random (I think)
-- we choose speed here over emulation accuracy;
--   rnd() will return different results in p64
function p8env.srand(seed)
	-- srand truncates its input to an int now,
	-- so... shift the seed 16 bits left
	return srand(seed*65536)
end
function p8env.rnd(mult)
	return rnd(tonum(mult)) --make rnd"100" work
end

p8env.abs=abs
p8env.sgn=sgn
p8env.flr=flr
p8env.ceil=ceil
p8env.min=min
p8env.max=max
p8env.mid=mid --COMPAT: mid() is an error now (but why would you do mid()?)

p8env.sqrt=sqrt
p8env.cos=cos
p8env.sin=sin
p8env.atan2=atan2

----------------
-- STRINGS
----------------

p8env.chr=chr
p8env.ord=ord
p8env.split=split --confirmed: picotron and pico8 both have ?(split("123",1))[3]==3
p8env.sub=sub
p8env.tostring=tostring

function p8env.tostr(val, as_hex)
	if as_hex then
		if type(val)=="number" and (as_hex==1 or (type(as_hex)!="number" and as_hex)) then
			-- COMPAT: these are floats, not 16.16 fixed point! but we'll try
			return string.format("0x%04x.%04x", val\1, val*65536\1)
		else
			compat("tostr flags are not supported (except tostr(num,1))")
			return tostring(val)
		end
	else
		return tostring(val)
	end
end

function p8env.tonum(x, flags)
	if flags then
		compat("tonum flags are not supported")
	end
	if x==true then return 1 end
	if x==false then return 0 end
	return tonumber(x)
end

----------------
-- METATABLES
----------------

p8env.getmetatable=getmetatable
p8env.setmetatable=setmetatable
p8env.rawequal=rawequal
p8env.rawget=rawget
p8env.rawlen=rawlen
p8env.rawset=rawset

----------------
-- TABLES
----------------

--COMPAT: add now behaves slightly differently with nil args:
--  add(nil) throws errors now
--  add(tab,elem,nil) throws errors now
--this may be a bit too far in terms of "emulation accuracy"...
function p8env.add(tab,elem,ix)
	if type(tab)!="table" then return end
	table.insert(tab,ix and tonumber(ix) or #tab+1,elem)
	return elem
end
-- p8env.add=add

p8env.pairs=pairs
p8env.all=all
p8env.count=count
p8env.del=del
p8env.deli=deli
p8env.foreach=foreach
p8env.ipairs=ipairs
p8env.next=next
function p8env.inext(a,i)
	i = (i or 0)+1
	local v = a[i]
	if v!=nil then
		return i, v
	end
end

----------------
-- MISC
----------------

function p8env.btn(b, p)
	-- picotron btn() returns either false or axis strength (0-255)
	local fn=btn
	p=(p or 0)*8
	if b then
		return has_focus and fn(b+p)!=false
	else
		if has_focus then
			return (fn(p) and 1 or 0)
				|(fn(1+p) and 2 or 0)
				|(fn(2+p) and 4 or 0)
				|(fn(3+p) and 8 or 0)
				|(fn(4+p) and 16 or 0)
				|(fn(5+p) and 32 or 0)
		else
			return 0
		end
	end
end
function p8env.btnp(b, p)
	local fn=btnp
	p=(p or 0)*8
	if b then
		return has_focus and fn(b+p)!=false or (saved_btnp>>(b+p))&1==1 --see main.lua
	else
		if has_focus then
			return (fn(p) and 1 or 0)
				|(fn(1+p) and 2 or 0)
				|(fn(2+p) and 4 or 0)
				|(fn(3+p) and 8 or 0)
				|(fn(4+p) and 16 or 0)
				|(fn(5+p) and 32 or 0)|saved_btnp
		else
			return 0
		end
	end
end

function p8env.menuitem(id,label,action)
	menuitem{
		id = id,
		label = label,
		action = action,
	}
end

function p8env.printh(str, filename, overwrite, save_to_desktop)
	if filename then
		if filename=="@clip" then
			set_clipboard_text(str)
		else
			compat("printh() extra args are not supported")
		end
	else
		printh(str)
	end
end

p8env.assert=assert
p8env.trace=debug.traceback
p8env.stop=stop
p8env.time=time --COMPAT: time keeps running when the game is paused due to pause_when_unfocused
p8env.t=time
p8env.type=type
p8env.select=select
p8env.pack=pack
p8env.unpack=unpack

p8env.ls=ls
p8env.dir=ls

p8env.cocreate=cocreate
p8env.coresume=coresume
p8env.costatus=costatus
p8env.yield=yield

--https://www.lexaloffle.com/dl/docs/pico-8_manual.html#STAT
local _stat_switch={
	[1]=stat, --cpu (total)
	[2]=stat, --cpu (sys) --will always report 0, but that's fine
	[4]=get_clipboard,
	[7]=stat, --framerate

	--COMPAT: p8 requires a poke before mouse/keyboard will work, but we ignore that
	[30]=function() return peektext()!=nil end,
	[31]=function() return readtext(),0 end,
	[32]=function() return select(1,mouse()) end, --mouse_x
	[33]=function() return select(2,mouse()) end, --mouse_y
	[34]=function() return select(3,mouse()) end, --mouse_b
	[35]=function() return select(4,mouse()) end, --wheel_x
	[36]=function() return select(5,mouse()) end, --wheel_y
	-- for time/day/year stats, see https://www.lexaloffle.com/bbs/?pid=145425#p
}
function p8env.stat(id)
	local fn = _stat_switch[id]
	if fn then
		return fn(id)
	else
		compat(string.format("stat(%s) is not supported",tostr(id)))
		return 0
	end
end




