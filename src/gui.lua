--[[pod_format="raw",created="2024-03-17 10:40:12",modified="2024-03-18 02:34:47",revision=438]]
function generate_gui( w,h)
	local w = w or get_display():width()
	local h = h or get_display():height()
	local footh = 21
	gui_extra_h = footh
	
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
					"1. copy sprites from pico8",
					"2. paste here",
					"3. save",
					"4. close&reopen gfx editor",
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
		label = "Clear",
		x=4,y=4,
		bgcol=0x070d,
		click = clear_img,
	}
	
	footer:attach_button{
		label = "Save..",
		x=-4,y=4,justify="right",
		bgcol=0x070d,
		click = on_click_save,
	}
	footer:attach_button{
		label = "Paste",
		x=-48,y=4,justify="right",
		bgcol=0x070d,
		click = set_img_from_clipboard,
	}
	
--	footer:attach_button{
--		label = "Clear",
--		x=-90,y=4,justify="right",
--		bgcol=0x070d,
--		click = function(self)
--			rm("/ram/cart/gfx/0.gfx")
--			create_process("/system/apps/gfx.p64", {argv={"/ram/cart/gfx/0.gfx"}})
--		end,
--	}

end
