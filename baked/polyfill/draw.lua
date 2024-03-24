--[[pod_format="raw",created="2024-03-19 23:27:45",modified="2024-03-21 13:06:39",revision=281]]
--swap fonts (see /system/lib/head.lua)
poke(0x5f56, 0x56) -- primary font
poke(0x5f57, 0x40) -- secondary font

p8env.print=print --COMPAT: p8scii is not supported. other differences?
p8env.pal=pal --COMPAT: not quite the same. might need some checks for pal({},1) etc
p8env.palt=palt --COMPAT: is this the same still?
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

local p8camx,p8camy = 0,0
function p8env.camera(x,y)
	local oldx,old = p8camx,p8camy
	p8camx,p8camy = ((x or 0)\1)&65535,((y or 0)\1)&65535
	camera(p8x8camx+p8camx,p8x8camy+p8camy)
	return oldx,oldy
end
function p8env.reset()
	p8env.camera()
	reset()
end

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

local _sspr_full = fetch("gfx/full.gfx")[1].bmp
function p8env.sset(x,y,val)
	_sspr_full:set(x,y,val&15)
end
function p8env.sget(x,y)
	return _sspr_full:get(x,y)&15
end
function p8env.sspr(...)
	sspr(_sspr_full,...)
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
