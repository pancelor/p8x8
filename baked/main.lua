--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-03-22 14:26:42",revision=580]]
function compat(msg)
	-- this function runs every time the translation layer notices possible compatibility issues
	-- currently, it prints to the host console, but you could do something else here if you want
	printh("COMPAT: "..msg)
--	notify(msg)
--	assert(false,msg)
end

--swap fonts (see /system/lib/head.lua)
poke(0x5f56, 0x56) -- primary font - p8.font
poke(0x5f57, 0x40) -- secondary font - lil.font

p8env = {
	p64env=_ENV, --upgrade path to picotron api
}
--the global enviroment the pico8 code will have access to
-- members are set by these polyfills:
for name in all(ls("./polyfill")) do
	include("./polyfill/"..name)
end

-- load tabs from p8code. the tabs are loaded one at a time, which
--   gets you nice error messages (e.g. "tab3.lua:82"). however,
--   you cannot access local variables from other tabs this way.
-- you should either not use top-level locals, or rewrite the following
--   code to concatenate the tabs together and then load them in a single
--   call, with `load(table.concat(all_tabs,"\n"), "", "t", p8env)`
for name in all(ls("./p8code")) do
	local filename = fullpath("./p8code/"..name)
	local src = fetch(filename)
	-- @ is a special character that tells debugger the string is a filename
	local func,err = load(src, "@"..filename, "t", p8env)
	if err then
		-- syntax error while loading
		send_message(3, {event="report_error", content = "*syntax error"})
		send_message(3, {event="report_error", content = tostr(err)})
	
		stop()
		return
	end
	func()
end



-- init/update/draw
local p8x8_draw
if false then
	-- fullscreen
	local p8canvas = userdata("u8",128,128)
		
	vid(0)  local winw,winh = 480,270
	--vid(3)  local winw,winh = 240,135 -- ok size but very bad flashing...
	
	local first_draw=true
	p8x8_draw = function()
		local x,y = winw/2-64,winh/2-64
		if first_draw then
			first_draw=false
			fillp(20927.5)
			rectfill(x-8,y-8,x+127+8,y+127+8,14)
			fillp()
			rectfill(x+116,y+129,x+134,y+127+8,14)
			print("p8x8",x+118,y+130,0x17)
	--		rectfill(x,y,x+127,y+127,0)
		end
		set_draw_target(p8canvas)
		if p8env._draw then p8env._draw() end
		set_draw_target()
		blit(p8canvas,get_draw_target(),0,0,x,y)
--[[
		local a,b=camera()
		palt(0,false)
		spr(p8canvas,0,0)
		camera(a,b)
--]]
	end
else
	-- windowed
	local title = fetch("./window_title.txt")
	window {
		title = title,
		width = 128,
		height = 128,
		resizeable = false,
	}
	has_focus = true --used by btn/btnp
	on_event("gained_focus", function() has_focus = true end)
	on_event("lost_focus", function() has_focus = false end) --comment out for global controls (multiple games at once!)
	function p8x8_draw()
		-- can't set directly b/c cart might overwrite it
		if p8env._draw then p8env._draw() end
	end
end

saved_btnp=0 --used by p8env.btnp. to deal with 30fps
if p8env._update then
	--30fps
	--[[
	p8env._init()
	while 1 do
		p8env._update()
		p8x8_draw()
		flip()
		flip()
	end
	-- this crashes picotron, oops
	--]]

	_init=p8env._init
	local showframe=false
	function _update()
		showframe=not showframe
		if showframe then
			p8env._update()
		else
			saved_btnp=0
			saved_btnp=p8env.btnp()
		end
	end
	function _draw()
		if showframe then
			p8x8_draw()
		end
	end
else
	_init=p8env._init
	function _update()
		-- can't set directly b/c cart might overwrite it
		if p8env._update60 then p8env._update60() end
	end
	_draw=p8x8_draw
end
