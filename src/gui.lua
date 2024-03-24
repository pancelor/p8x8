--[[pod_format="raw",created="2024-03-17 10:40:12",modified="2024-03-18 07:44:15",revision=535]]
local footh = 21 --size of gray footer area
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
			if img then
				palt(0,false)
				spr(img,self.width/2-img:width()/2,self.height/2-img:height()/2)
				palt()
			else
				print(table.concat({
					"   -==INSTRUCTIONS==-",
					"1. drag a .p8 file here",
					"  (or copypaste sprites)",
					"2. save",
					"3. close&reopen editors",
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
	
--	footer:attach_button{
--		label = "Clear",
--		x=4,y=4,
--		bgcol=0x070d,
--		click = reset_sprimp,
--	}
	
	footer:attach_button{
		label = "Save gfx..",
		x=4,y=4,
		bgcol=0x070d,
		click = on_click_savegfx,
	}
--	footer:attach_button{
--		label = "Paste",
--		x=-48,y=4,justify="right",
--		bgcol=0x070d,
--		click = set_img_from_clipboard,
--	}
	
	footer:attach_button{
		label = "Save map..",
		x=-4,y=4,justify="right",
		bgcol=0x070d,
		click = on_click_savemap,
	}
end

-- resize the window so that the main area will fit a w,h image
-- will only grow the window, will not shrink
function gui_resize_to_fit(w,h)
	w = max(get_display():width(), w)
	h = max(get_display():height(), h+footh)
	window{
		width = w,
		height = h,
	}

	generate_gui()
end


