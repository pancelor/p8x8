--[[pod_format="raw",created="2024-03-20 01:20:21",modified="2024-03-22 13:58:18",revision=60]]
--COMPAT: mem layout is certainly different. what else is going to break here?
--TODO: translation layer for the internal API stuff? e.g. video modes etc
--  the stuff from http://pico8wiki.com/index.php?title=Memory

p8env.memcpy=memcpy
p8env.memset=memset
p8env.peek=peek
p8env.peek2=peek2
p8env.peek4=peek4
p8env.poke=poke
p8env.poke2=poke2
p8env.poke4=poke4

local _cartdata
function p8env.cartdata(name)
	assert(not _cartdata,"cartdata() can only be called once")
	_cartdata = name:gsub("[^%w]","_")
	if #_cartdata==0 then
		_cartdata = nil
		return
	end
	mkdir("/appdata/".._cartdata)
	if not fstat("/appdata/".._cartdata.."/cartdata.pod") then
		local dat = userdata("i32",64) --initialized to 0
		store("/appdata/".._cartdata.."/cartdata.pod",dat)
	end
end
function p8env.dget(slot)
	if not _cartdata then return 0 end

	local dat = _fetch_local("/appdata/".._cartdata.."/cartdata.pod")
	local w,h,typ,dim = dat:attribs()
	assert(w==64 and h==1 and typ=="i32" and dim==1,qq(w,h,typ,dim))

	slot = ((tonumber(slot) or 0)\1)&63
	local bigval = dat[slot]
	if bigval&65535==0 then
		-- no decimals stored
		-- (string concat behaves differently depending on whether this division is \ or /,
		--   and bigval/65536\1 doesn't even force it back to intyness?? it's wild.
		--   this mainly matters for score display)
		return bigval\65536
	else
		return bigval/65536
	end
end
function p8env.dset(slot,val)
	if not _cartdata then return end

	local dat = _fetch_local("/appdata/".._cartdata.."/cartdata.pod")
	local w,h,typ,dim = dat:attribs()
	assert(w==64 and h==1 and typ=="i32" and dim==1)

	slot = ((tonumber(slot) or 0)\1)&63
	dat[slot] = (tonumber(val) or 0)*65536 --store val (float) as 32 bits of integer
	store("/appdata/".._cartdata.."/cartdata.pod",dat)
end

function p8env.reload(dest_addr,src_addr,len, filename)
	if filename then
		compat("reload from file is not supported")
		return
	end
	if dest_addr==src_addr then
		local addr0,addr1 = src_addr,src_addr+len
		if addr0==0x0000 and 0x1000<=addr1 then
			-- TODO reload all sprites in 0.gfx
			if addr0==0x0000 and 0x1000==addr1 then
				return
			end
		end
		if addr0<=0x2000 and 0x3000<=addr1 then
			reload_map()
			if addr0==0x2000 and 0x3000==addr1 then
				return
			end
		end
	end
	compat("reload is only partially supported")
end


