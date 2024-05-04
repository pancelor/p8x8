--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-04-03 21:56:20",revision=590]]
local _compat_seen = {}
function compat(msg)
	-- this function runs every time the translation layer notices possible compatibility issues
	-- currently, it prints to the host console, but you could do something else here if you want
	if not _compat_seen[msg] then
		_compat_seen[msg] = true --only show once
		msg = "COMPAT: "..msg
		printh(msg)
--		notify(msg)
	end
--	assert(false,msg)
end



-- to run fullscreen with a border, set "fullscreen = true" instead.
local fullscreen = false
-- to draw a border image, create a new spritesheet in the gfx editor,
--   save it as gfx/border.gfx, and store a 480x270 sprite in sprite 1
-- this tool can help you convert PNG files to picotron:
--   https://www.lexaloffle.com/bbs/?pid=importpng#p

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

-- the enviroment that the pico8 code will see as its "global" environment
p8env = {
	p64env=_ENV, --upgrade path to picotron api. e.g. a p8x8 cart can call `p64env.fetch()` to acess Picotron's fetch() function
}
-- these files set up the other members of p8env (pal(), spr(), tostr(), poke(), everything else):
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

function p8x8_init()
	-- https://lospec.com/palette-list/pico-8-secret-palette
	poke4(0x5000+48*4, --set pal 48-63 to the p8 "secret colors"
		0x291814, 0x111d35, 0x422136, 0x125359,
		0x742f29, 0x49333b, 0xa28879, 0xf3ef7d,
		0xbe1250, 0xff6c24, 0xa8e72e, 0x00b543,
		0x065ab5, 0x754665, 0xff6e59, 0xff9d81)

	if p8env._init then p8env._init() end
end

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
		
		cartdata_flush()
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

		cartdata_flush()
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

	_init=p8x8_init
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
	_init=p8x8_init
	function _update()
		if not has_focus then return end

		-- can't set directly b/c cart might change _update60 midgame
		if p8env._update60 then p8env._update60() end
	end
	_draw=p8x8_draw
end
