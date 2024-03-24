--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-03-22 14:26:42",revision=580]]
function compat(msg)
	printh("COMPAT: "..msg)
	-- comment this assert() out if you want to run despite compatibility issues:
--	assert(false,msg)
end

-- COMPAT: you can only draw inside _draw
-- COMPAT: numeric types are completely different
-- COMPAT: p8scii is not supported

-- handled by warnings:
-- COMPAT: 3//2 is now floor division, not a comment
-- COMPAT: carts with custom mainloops (goto) are not supported. they'll probably crash
	
p8env = {
	p64env=_ENV, --upgrade path to picotron api
}
--the global enviroment the pico8 code will have access to
-- members are set by these polyfills:
for name in all(ls("./polyfill")) do
	include("./polyfill/"..name)
end

-- load tabs from p8code
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
		p8env._draw()
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
	window {
		title = env().path,
		width = 128,
		height = 128,
		resizeable = false,
	}
	function p8x8_draw()
		-- can't set directly b/c cart might overwrite it
		p8env._draw()
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
		p8env._update60()
	end
	_draw=p8x8_draw
end
