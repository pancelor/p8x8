--[[pod_format="raw",created="2024-03-19 21:22:22",modified="2024-03-20 02:22:31",revision=205]]
function export_p64(path)
	if not cartdata then
		notify("* error: must import a .p8 first")
		return
	end
	assert(path,"no filename?")

	if not path:ext() then
		path ..= ".p64"
	end
	if path:ext() != "p64" then
		notify("* error: must export as a .p64")
		return
	end
	if fstat(path) then
		notify("* error: must export a new file, cannot overwrite one")
		return
	end

	-- ensure no trailing slash
	path = rstrip(path,"/")

	mkdir(path)
	mkdir(path.."/gfx")
	mkdir(path.."/map")
	mkdir(path.."/p8code")
	mkdir(path.."/sfx") -- probably not necessary? but startup.lua makes it by default
	
	export_baked(path)

	export_gfx(path.."/gfx/0.gfx")
	export_gfxfull(path.."/gfx/full.gfx")
	export_map(path.."/map/0.map")
	-- export code tabs
	for ti=1,#cartdata.lua do
		local fname = string.format("%s/p8code/%d.lua",path,ti-1)
		store(fname,cartdata.lua[ti])
	end
	
	-- store open file metadata
	-- see /system/wm/wm.lua:save_open_locations_metadata or new.lua (bbs util)
	-- TODO maybe export into /ram/cart ? don't want to overwrite without warning tho..

	--pq(fetch_metadata("/desktop/03mar/p8x8.p64"))
	local meta = {}
	meta.workspaces = {}
	add(meta.workspaces, {location = "map/0.map", workspace_index=3})
	add(meta.workspaces, {location = "gfx/0.gfx", workspace_index=2})
	add(meta.workspaces, {location = "gfx/full.gfx", workspace_index=2})
	add(meta.workspaces, {location = "main.lua", workspace_index=1})
	for ti=1,#cartdata.lua do
		local fname = string.format("p8code/%d.lua#1",ti-1)
		add(meta.workspaces, {location = fname, workspace_index=1})
	end	
	store_metadata(path,meta)

	notify("exported "..path)
end

function export_map(path)
	if not cartdata or not cartdata.map then
		notify("* error: no map data")
		return
	end
	assert(path,"no filename?")

	-- view expected structure with: podtree /ram/cart/map/0.map
	local mapdat = {
		{ -- first map layer
			bmp = cartdata.map,
			tile_w = 8,
			tile_h = 8,
			-- start view in top-left
			pan_x = -188,
			pan_y = -10,
			zoom = 0.5,
		},
	}
	store(path, mapdat) --save
	notify("exported "..path)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {path},
--			pwd = "/ram/cart",
--		}
--	)
end

function export_gfxfull(path)
	if not cartdata or not cartdata.gfx then
		notify("* error: no image data")
		return
	end
	
	local sprites = {}
	sprites[1] = {
		bmp = cartdata.gfx,
		flags = 0,
		zoom = 1,
		pan_x = 0,
		pan_y = 0,
	}
	store(path, sprites) --save
	notify("exported "..path)
end

function export_gfx(path)
	if not cartdata or not cartdata.gfx then
		notify("* error: no image data")
		return
	end
	assert(path,"no filename?")
	
	local gfx = cartdata.gfx
	local gff = cartdata and cartdata.gff
	local iw,ih = gfx:attribs()

	local sprites = {}
	for i=0,255 do
		local bmp = userdata("u8",8,8)
		local x,y = i%16*8,i\16*8
		if x+8<=iw and y+8<=ih then
			--pq("blit",x,y)
			blit(gfx,bmp,x,y,0,0) --from,to, fromx,y, tox,y, w,h
			-- see /system/apps/gfx.p64
			sprites[i] = {
				bmp = bmp,
				flags = gff and gff[i] or 0,
				zoom = 8,
				pan_x = 0,
				pan_y = 0,
			}
		end
	end
	store(path, sprites) --save
	notify("exported "..path)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {path},
--			pwd = "/ram/cart",
--		}
--	)
end

function export_baked(folder)
	assert(sub(folder,-1) != "/")
	
	local p8x8_path = env().prog_name
	if sub(p8x8_path,1,8)=="/system/" then -- e.g. running from terminal
		local main = env().corun_program
		local segs = split(main,"/")
		deli(segs) -- pop filename
		p8x8_path = table.concat(segs,"/")
	end
	local baked = p8x8_path.."/baked"
	if not fstat(baked) then
		printh("could not find baked folder: "..baked)
		notify("missing baked/, continuing...")
		return
	end
	cpr(baked,folder)
end

-- cp -r, copy recursive
-- vanilla cp() will overwrite the entire destination folder
function cpr(from,to)
	local fs = fstat(from) --could be nil
	if fs == "file" then
		cp(from,to)
	elseif fs == "folder" then
		mkdir(to)
		for name in all(ls(from)) do
			cpr(from.."/"..name, to.."/"..name)
		end
	end
end


