--[[pod_format="raw",created="2024-03-19 04:26:19",modified="2024-03-22 13:54:46",revision=542]]
function test(want,got)
	if want!=got then
		assert(false,string.format("want: %s, got: %s.",tostr(want),tostr(got)))
	end
end

-- 0=>"0", ... 15=>"f", 16=>"g", ... 31=>"v"
function hex_from_num(val)
	if 0<=val and val<=9 then
		return string.char(0x30+val)
	elseif 10<=val and val<=31 then
		return string.char(97+val-10)
	else
		assert(nil,"hex_from_num bad input: "..tostr(val))
	end
end
--test("3",hex_from_num(3))
--test("f",hex_from_num(15))
--test("h",hex_from_num(17))

-- "0"=>0, ... "f"=>15, "g"=>16, ... "v"=>31
function num_from_hex(str, i)
	local val = string.byte(str,i)
	if 0<=val-0x30 and val-0x30<=9 then
		return val-0x30
	elseif 10<=val-97+10 and val-97+10<=31 then
		return val-97+10
	else
		assert(nil,"num_from_hex bad input: "..tostr(str).." "..tostr(i))
	end
end
--test(3,num_from_hex("3"))
--test(15,num_from_hex("f"))
--test(17,num_from_hex("h"))
--test(12,num_from_hex("abc",-1))

function rstrip(str,chars)
	local book = {}
	for i=1,#chars do
		book[string.byte(chars,i)] = true
	end
	
	for i=#str,1,-1 do
		if not book[string.byte(str,i)] then
			-- found a non-bad char
			return sub(str,1,i)
		end
	end	
	return ""
end
--test("ab",rstrip("abc","c"))
--test("a",rstrip("abc","bc"))
--test("abc",rstrip("abc","x"))
--test("",rstrip("abc","cab"))

-- like pqn(), but meant for long-term logging,
--   not short-term debugging. not too fancy,
--   just call both
function notify_printh(msg)
	printh(msg)
	notify(msg)
end

-- cp -r, copy recursive
-- I think vanilla cp() will overwrite the entire destination folder, yikes
function cpr(from,to)
	local fs = fstat(from) --could be nil
	if fs == "file" then
		cp(from,to)
	elseif fs == "folder" then
		mkdir(to)
		for name in all(ls(from)) do
			cpr(from.."/"..name, to.."/"..name)
		end
	end
end
