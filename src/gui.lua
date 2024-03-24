--[[pod_format="raw",created="2024-03-17 10:40:12",modified="2024-03-22 08:52:07",revision=1180]]
local footh = 21 --size of gray footer area
local preview_img
function generate_gui( w,h)
	local w = w or get_display():width()
	local h = h or get_display():height()
	
	gui = create_gui()
	
	gui:attach{
		x=0,y=0,width=w,height=h-footh,
		draw=function(self)
			for y=0,self.height,4 do
				for x=0,self.width,4 do
					local col = (x\4+y\4)&1==0 and 0x20 or 0x21
					rectfill(x,y,x+3,y+3,col)
				end
			end
			if preview_img then
				palt(0,false)
				local w,h = preview_img:attribs()
				spr(preview_img,self.width/2-w/2,self.height/2-h/2)
				palt()
			else
				print(table.concat({
					"   -==INSTRUCTIONS==-",
					"1. drag a .p8 file here",
					"2. export as .p64",
					"3. manually fix the code",
					"",
					" enjoy!          -pancelor",
					},"\n"),4,8,13)
			end
		end,
	}
	
	local footer = gui:attach{
		x=0,y=0,width=w,height=footh,vjustify="bottom",
		draw=function(self)
			rectfill(0,0,self.width-1,self.height-1,6)
		end,
	}
	
	footer:attach_button{
		label = "Export p64",
		x=4,y=4,
		bgcol=0x070d,
		click = action_export_p64,
	}
end

-- resize the window and set the image
function gui_set_preview_image(ud)
	preview_img = ud
	if not preview_img then return end
	
	-- resize window to fit spritesheet
	local w,h = ud:attribs()
	-- will only grow the window, will not shrink	
	w = max(get_display():width(), w)
	h = max(get_display():height(), h+footh)
	window{
		width = w,
		height = h,
	}

	generate_gui()
end


