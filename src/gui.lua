--[[pod_format="raw",created="2024-03-17 10:40:12",modified="2024-03-17 12:50:20",revision=183]]
function generate_gui( w,h)
	local w = w or get_display():width()
	local h = h or get_display():height()
	local footh = 21
	gui_extra_h = footh
	
	gui = create_gui()
	
	gui:attach{
		x=0,y=0,width=w,height=h-footh,
		draw=function(self)
			rectfill(0,0,self.width-1,self.height-1,0)
			if img then
				spr(img,0,0)
			else
				print("copy from pico8,\nthen paste here",10,10,13)
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
		label = "Paste",
		x=-40,y=4,justify="right",
		bgcol=0x070d,
		click = set_img_from_clipboard,
	}
	
	footer:attach_button{
		label = "Save",
		x=-4,y=4,justify="right",
		bgcol=0x070d,
		click = on_click_save,
	}
end
