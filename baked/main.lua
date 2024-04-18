--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-04-03 21:56:20",revision=590]]
function compat(msg)
	-- this function runs every time the translation layer notices possible compatibility issues
	-- currently, it prints to the host console, but you could do something else here if you want
	msg = "COMPAT: "..msg
	printh(msg)
--	notify(msg)
--	assert(false,msg)
end



-- to run fullscreen with a border, change to true.
-- to draw a border image, use this tool to create a new
--   spritesheet saved at gfx/border.gfx,
--   where sprite 0 is a 480x270 sprite:
--   https://www.lexaloffle.com/bbs/?pid=importpng#p
local fullscreen = false

local pause_when_unfocused = true



has_focus = true --used by p8env.btn/btnp
if pause_when_unfocused then
	on_event("lost_focus", function() has_focus = false end)
	on_event("gained_focus", function() has_focus = true end)
end

-- set pico8 font as default
-- the alternate font is already set to p8.font (see /system/lib/head.lua)
poke(0x4000,get(fetch"/system/fonts/p8.font"))



--------------------------------
-- load p8code in a sandbox
--------------------------------

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



--------------------------------
-- init/update/draw
--------------------------------

local p8x8_draw
if fullscreen then
	local p8canvas = userdata("u8",128,128)
	
	vid(0)  local winw,winh = 480,270
	--vid(3)  local winw,winh = 240,135
	
	function draw_border()
		draw_border = function() end -- only run once
		local spr_border = fetch "gfx/border.gfx"
		palt(0,false)
		spr(spr_border[1].bmp) --draw sprite 1 from border.gfx
		palt(0,true)
		--[[
		cls()
		local x,y = winw/2-64,winh/2-64
		rectfill(x-8,y-8,x+127+8,y+127+8,1)
		print("\#1p8x8",x+118,y+130,0x12)
		--]]
	end
	
	p8x8_draw = function()
		if not has_focus then return end
		
		draw_border()
		
		set_draw_target(p8canvas)
		if p8env._draw then p8env._draw() end
		set_draw_target()
		
		local x,y = winw/2-64,winh/2-64
		blit(p8canvas,get_draw_target(),0,0,x,y)
	end
else
	-- windowed
	local title = fetch("./window_title.txt")
	window {
		title = title,
		width = 128,
		height = 128,
		resizeable = false,
		autoclose = true, -- esc=quit
	}

	function p8x8_draw()
		if not has_focus then return end
		
		-- can't set directly b/c cart might change _draw midgame
		if p8env._draw then p8env._draw() end
	end
end

saved_btnp=0 --used by p8env.btnp (to deal with 30fps)
if p8env._update then
	--30fps
	--[[
	--this crashes picotron, oops
	p8env._init()
	while 1 do
		p8env._update()
		p8x8_draw()
		flip()
		flip()
	end
	--]]

	_init=p8env._init
	local showframe=false
	function _update()
		if not has_focus then return end

		showframe=not showframe
		if showframe then
			p8env._update()
		else
			saved_btnp=0
			saved_btnp=p8env.btnp()
		end
	end
	function _draw()
		if not has_focus then return end

		if showframe then
			p8x8_draw()
		end
	end
else
	_init=p8env._init
	function _update()
		if not has_focus then return end

		-- can't set directly b/c cart might change _update60 midgame
		if p8env._update60 then p8env._update60() end
	end
	_draw=p8x8_draw
end
