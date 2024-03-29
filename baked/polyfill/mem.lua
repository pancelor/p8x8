--[[pod_format="raw",created="2024-03-20 01:20:21",modified="2024-03-22 13:58:18",revision=60]]
-- COMPAT: these will work, but probably won't do what you expect
--   (b/c picotron memory is laid out differently from pico8 memory)
-- To avoid compat() spam, edit your exported cart to use p64env.poke() etc,
--   if you know that the address you're poking is still correct in Picotron
local function mem_warn(name,func)
	return function(...)
		compat(name.."() might not work due to memory layout changes")
		return func(...)
	end
end
p8env.memcpy=mem_warn("memcpy",memcpy)
p8env.memset=mem_warn("memset",memset)
p8env.peek=mem_warn("peek",peek)
p8env.peek2=mem_warn("peek2",peek2)
p8env.peek4=mem_warn("peek4",peek4)
p8env.poke=mem_warn("poke",poke)
p8env.poke2=mem_warn("poke2",poke2)
p8env.poke4=mem_warn("poke4",poke4)

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

	local dat = fetch("/appdata/".._cartdata.."/cartdata.pod")
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

	local dat = fetch("/appdata/".._cartdata.."/cartdata.pod")
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
			reload_sprites()
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


