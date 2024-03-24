--[[pod_format="raw",created="2024-03-19 22:54:36",modified="2024-03-21 13:06:39",revision=119]]
----------------
-- MATH
----------------

p8env.abs=abs
p8env.sgn=sgn
p8env.flr=flr
p8env.ceil=ceil
p8env.min=min
p8env.max=max
p8env.mid=mid
p8env.sqrt=sqrt

p8env.cos=cos
p8env.sin=sin
p8env.atan2=atan2

-- COMPAT: p8 and p64 have different PRNG algorithmgs
-- we choose speed here over emulation accuracy;
--   rnd will return different results in p64
p8env.srand=srand
p8env.rnd=rnd

----------------
-- STRINGS
----------------

p8env.chr=chr
p8env.ord=ord
p8env.split=split --confirmed: ?(split("123",1))[1]==1
p8env.sub=sub
p8env.tostring=tostring

function p8env.tostr(val, as_hex)
	if as_hex then
		if as_hex==1 or (type(as_hex)!="number" and as_hex) then
			-- COMPAT: these are floats, not 16.16 fixed point! but we'll try
			return string.format("0x%04x.%04x", val, val<<16)
		else
			compat("tostr flags are not supported (except tostr(x,1))")
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

p8env.pairs=pairs
p8env.add=add
p8env.all=all
p8env.count=count
p8env.del=del
p8env.deli=deli
p8env.foreach=foreach
p8env.ipairs=ipairs
p8env.inext=inext
p8env.next=next

----------------
-- MISC
----------------

function _btn_help(fn,b, p)
	-- picotron btn() returns either false or axis strength (0-255)
	p=(p or 0)*8
	if b then
		return fn(b+p)!=false
	else
		return (fn(p) and 1 or 0)
			|(fn(1+p) and 2 or 0)
			|(fn(2+p) and 4 or 0)
			|(fn(3+p) and 8 or 0)
			|(fn(4+p) and 16 or 0)
			|(fn(5+p) and 32 or 0)
	end
end
function p8env.btn(...)
	return _btn_help(btn,...)
end
function p8env.btnp(...)
	return _btn_help(btnp,...)
end

p8env.assert=assert
p8env.trace=debug.traceback
p8env.stop=stop
p8env.time=time
p8env.t=time
p8env.type=type
p8env.select=select
p8env.pack=pack
p8env.unpack=unpack
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
