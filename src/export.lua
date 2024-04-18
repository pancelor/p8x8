--[[pod_format="raw",created="2024-03-19 21:22:22",modified="2024-04-03 21:56:11",revision=592]]
function export_p64(path)
	if not active_cart then
		notify_printh "*error: must import a .p8 first"
		return
	end
	assert(path,"no filename?")

	if not path:ext() then
		path ..= ".p64"
	end
	if path:ext() != "p64" then
		notify_printh "*error: must export as a .p64"
		return
	end
	-- ensure no trailing slash
	path = rstrip(path,"/")

	if fstat(path) then
		-- overwriting, make a backup
		mkdir "/ram/temp/"
		local timestamp = split(date()," ",false)[2]
		timestamp = string.gsub(timestamp,"[^%w]","")
		mv(path,string.format("/ram/temp/p8x8-%s-%s",timestamp,path:basename()))
	end
	cp("baked",path)

	store(path.."/window_title.txt",path:basename())

	export_gfxfull(path.."/gfx/full.gfx")
	export_gfx(path.."/gfx/0.gfx")
	export_map(path.."/map/0.map")
	export_tabs(path.."/p8code")

	-- store open file metadata
	-- see /system/wm/wm.lua:save_open_locations_metadata or new.lua (bbs util)
	local meta = {}
	meta.workspaces = {}
	add(meta.workspaces, {location = "map/0.map", workspace_index=3})
	add(meta.workspaces, {location = "gfx/full.gfx", workspace_index=2})
	add(meta.workspaces, {location = "gfx/0.gfx", workspace_index=2}) --after full.gfx so it's focused by default
	add(meta.workspaces, {location = "main.lua", workspace_index=1})
	if active_cart.lua then
		for ti=1,#active_cart.lua do
			local fname = string.format("p8code/%d.lua#1",ti-1)
			add(meta.workspaces, {location = fname, workspace_index=1})
		end
	end

	if active_cart.lua_warn then
		store(path.."/warning.txt",active_cart.lua_warn)
		add(meta.workspaces, {location = "warning.txt", workspace_index=1})
		create_process("/system/util/open.lua", {argv = {path.."/warning.txt"}})
	end
	
	store_metadata(path,meta)
	notify_printh("exported "..path)
end

function export_tabs(path)
	if not active_cart or not active_cart.lua then
		printh("export_tabs: no lua data")
		return
	end
	-- export code tabs
	for ti=1,#active_cart.lua do
		local fname = string.format("%s/%d.lua",path,ti-1)
		store(fname,active_cart.lua[ti])
	end
end

function export_map(path)
	assert(active_cart.map)
	assert(path,"no filename?")

	-- view expected structure with: podtree /ram/cart/map/0.map
	local mapdat = {
		{ -- first map layer
			bmp = active_cart.map,
			tile_w = 8,
			tile_h = 8,
			-- start view in top-left
			pan_x = -188,
			pan_y = -10,
			zoom = 0.5,
		},
	}
	store(path, mapdat) --save
	notify_printh("exported "..path)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {path},
--			pwd = "/ram/cart",
--		}
--	)
end

function export_gfxfull(path)
	if not active_cart or not active_cart.gfx then
		notify_printh "*error: no image data"
		return
	end
	
	local sprites = {}
	-- NOTE: "1" here is synced with sspr polyfill (draw.lua)
	sprites[1] = {
		bmp = active_cart.gfx,
		flags = 0,
		zoom = 1,
		pan_x = 0,
		pan_y = 0,
	}
	store(path, sprites) --save
	notify_printh("exported "..path)
end

function export_gfx(path)
	if not active_cart or not active_cart.gfx then
		notify_printh "*error: no image data"
		return
	end
	assert(path,"no filename?")
	
	local gfx = active_cart.gfx
	local gff = active_cart and active_cart.gff
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
	notify_printh("exported "..path)
	-- open gfx editor
--	create_process("/system/util/open.lua",
--		{
--			argv = {path},
--			pwd = "/ram/cart",
--		}
--	)
end

