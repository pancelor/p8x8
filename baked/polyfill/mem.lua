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



-- TODO: 0x5e00 claims its still "persistent cart data":
-- https://www.lexaloffle.com/dl/docs/picotron_gfx_pipeline.html
-- A basic check shows no magic persistence, but that memory might be unused and available
-- Maybe use that as backing store, instead of cartdata_cache? wish I could memmap() it

local cartdata_path -- file path where cartdata is stored
local cartdata_cache -- cached data in RAM, for speed. flushed once a frame
local cartdata_dirty = false -- did the cache change in the last frame?
function p8env.cartdata(name)
	assert(not cartdata_path,"cartdata() can only be called once")
	name = name:gsub("[^%w]","_")
	if #name==0 then
		name = nil
		return
	end

	--[[
	-- If you're growing your p8x8 cart into a full picotron program,
	-- make your own folder and store whatever you want there! like this:
	mkdir("/appdata/"..name)
	cartdata_path = "/appdata/p8x8/"..name.."/cartdata.pod"
	--]]

	-- [[
	--make sure folder exists
	mkdir("/appdata/p8x8/")
	mkdir("/appdata/p8x8/cartdata")
	cartdata_path = "/appdata/p8x8/cartdata/"..name..".pod"
	--]]

	cartdata_cache = fetch(cartdata_path) --maybe nil
	if cartdata_cache then
		local w,h,typ,dim = cartdata_cache:attribs()
		if not (w==64 and h==1 and typ=="i32" and dim==1) then
			cartdata_cache = nil
			printh"bad cartdata stored on disk; clearing to 0"
		end
	end
	if not cartdata_cache then
		cartdata_cache = userdata("i32",64) --initialized to 0
		cartdata_dirty = true
	end
end
function p8env.dget(slot)
	if not cartdata_path then return 0 end

	slot = ((tonumber(slot) or 0)\1)&63
	local bigval = cartdata_cache[slot]
	-- bigval is an i32 (0xAAAABBBB); now convert it to a pico-8-like decimal (0xAAAA.BBBB)
	-- this is good enough
	if bigval&0xffff==0 then
		-- no decimals stored
		-- (string concat behaves differently depending on whether this division is \ or /,
		--   I guess lua keeps tracks of numbers as being either ints or floats.
		--   and bigval/0x10000\1 doesn't force a float back into intyness?? wild.
		--   this mainly matters for score display -- see cherrybomb)
		return bigval\0x10000
	else
		return bigval/0x10000
	end
end
function p8env.dset(slot,val)
	if not cartdata_path then return end

	slot = ((tonumber(slot) or 0)\1)&63
	cartdata_cache[slot] = (tonumber(val) or 0)*0x10000 --store val (float) as 32 bits of integer
	cartdata_dirty = true
end
--called at the end of each frame
function cartdata_flush()
	if not cartdata_path then return end
	
	if cartdata_dirty then
		-- local a = stat(1)
		store(cartdata_path,cartdata_cache)
		cartdata_dirty = false
		-- pqn(stat(1)-a) -- takes about 0.005
	end
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


