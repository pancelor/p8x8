--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-03-21 13:06:39",revision=320]]
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

--vid(0) local winw,winh = 480,270
vid(3) local winw,winh = 240,135
p8x8camx,p8x8camy = 64-winw/2,64-winh/2
camera(p8x8camx,p8x8camy)

local first_draw=true
function p8x8_draw()
	if first_draw then
		first_draw=false
		fillp(20927.5)
		rectfill(x-8,y-8,x+127+8,y+127+8,14)
		fillp()
		rectfill(x+116,y+129,x+134,y+127+8,14)
		print("p8x8",x+118,y+130,0x17)
		rectfill(x,y,x+127,y+127,0)
	end
	clip(x,y,128,128)
	p8env._draw()
end

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
		end
	end
	function _draw()
		if showframe then
			p8x8_draw()
		end
	end
else
	_init=p8env._init
	_update=p8env._update
	_draw=p8x8_draw
end
