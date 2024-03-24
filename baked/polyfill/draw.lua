--[[pod_format="raw",created="2024-03-19 23:27:45",modified="2024-03-20 02:22:31",revision=161]]
--swap fonts (see /system/lib/head.lua)
poke(0x5f56, 0x56) -- primary font
poke(0x5f57, 0x40) -- secondary font

p8env.print=print --COMPAT: p8scii is not supported. other differences?
p8env.pal=pal --COMPAT: needs work
p8env.palt=palt --COMPAT: needs work
function p8env.tline()
	compat("TODO: tline support")
end

p8env.fillp=fillp
p8env.camera=camera
p8env.circ=circ
p8env.circfill=circfill
p8env.clip=clip
p8env.cls=cls
p8env.color=color
p8env.cursor=cursor
p8env.line=line
p8env.oval=oval
p8env.ovalfill=ovalfill
p8env.pget=pget
p8env.pset=pset
p8env.reset=reset
p8env.rect=rect
p8env.rectfill=rectfill
p8env.flip=flip

-- thanks NuSan! https://www.lexaloffle.com/bbs/?pid=143658#p
function p8env.spr(_s,_x,_y,_w,_h,_mx,_my)
	_w=_w or 1
	_h=_h or 1
	for i=0,_w-1 do
		local _i=_mx and _w-i-1 or i
		for j=0,_h-1 do
			local _j=_my and _h-j-1 or j
			--spr(_s+_i+_j*16,_x+i*8,_y+j*8,1,1,_mx,_my)
			spr(_s+_i+_j*16,_x+i*8,_y+j*8,_mx,_my)
		end
	end
end

local _sspr_full = fetch "gfx/full.gfx"
function p8env.sset(x,y,val)
	_sspr_full:set(x,y,val&15)
end
function p8env.sget(x,y)
	return _sspr_full:get(x,y)&15
end
function p8env.sspr(sx,sy,sw,sh,dx,dy, dw,dh, flip_x, flip_y)
	if flip_x or flip_y then
		compat("sspr flipx/flipy are not supported")
	end
	sspr(_sspr_full,sx,sy,sw,sh,dx,dy, dw,dh)
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
