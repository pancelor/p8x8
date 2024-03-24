--[[pod_format="raw",created="2024-03-19 04:26:19",modified="2024-03-19 05:50:51",revision=84]]
-- 0=>"0", ... 15=>"f", 16=>"g", ... 31=>"v"
local function hex_from_num(val)
	if 0<=val and val<=9 then
		return string.char(0x30+val)
	elseif 10<=val and val<=31 then
		return string.char(97+val-10)
	else
		assert(nil,"hex_from_num bad input: "..tostr(val))
	end
end
assert(hex_from_num(3)=="3")
assert(hex_from_num(15)=="f")
assert(hex_from_num(17)=="h")

-- "0"=>0, ... "f"=>15, "g"=>16, ... "v"=>31
function num_from_hex(char)
	local val = string.byte(char)
	if 0<=val-0x30 and val-0x30<=9 then
		return val-0x30
	elseif 10<=val-97+10 and val-97+10<=31 then
		return val-97+10
	else
		assert(nil,"num_from_hex bad input: "..tostr(char))
	end
end
assert(num_from_hex("3")==3)
assert(num_from_hex("f")==15)
assert(num_from_hex("h")==17)
