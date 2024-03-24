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

--[[
no, nevermind. this is too far towards emulation.
if you want dget/dset to work, call p64env.mkdir("/appdata/mygame")
and then store/fetch your save data from there

local _cartdata
function p8env.cartdata(name)
	assert(not _cartdata,"cartdata() can only be called once")
	_cartdata = name:gsub("[^%w]","_")
	mkdir("/appdata/".._cartdata)
	local dat = userdata("u8",256) --initialized to 0
	store("/appdata/".._cartdata.."/cartdata.pod",dat)
end
function p8env.dget(slot)
	if not _cartdata then return 0 end --maybe this should error, eh
	local dat = _fetch_local("/appdata/".._cartdata.."/cartdata.pod")
	local subslot = (((slot or 0)\1)&63)*4
	-- COMPAT: this might not preserve the data properly. oh well
	return dat[subslot+3]*256 + dat[subslot+2] + dat[subslot+1]/256 + dat[subslot]/65536
end
function p8env.dset(slot,val)
	if not _cartdata then return 0 end --maybe this should error, eh
	local dat = _fetch_local("/appdata/".._cartdata.."/cartdata.pod")
	local subslot = (((slot or 0)\1)&63)*4
	val = val or 0
	-- COMPAT: this might not preserve the data properly. oh well
	dat[subslot+3] = (val\256)&255
	dat[subslot+2] = (val\1)&255
	dat[subslot+1] = (val*256\1)&255
	dat[subslot]   = (val*65536\1)&255
	store("/appdata/".._cartdata.."/cartdata.pod",dat)
end
]]
function p8env.cartdata() end
function p8env.dset() end
function p8env.dget() return 0 end

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


