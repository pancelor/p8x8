--[[pod_format="raw",created="2024-03-16 08:58:31",modified="2024-03-16 08:58:31",revision=0]]
-- quote a single thing
-- like tostr, but for tables
function quote(t, sep)
	if type(t)~="table" then return tostr(t) end

	local s="{"
	for k,v in pairs(t) do
		-- if k=="base" then v="<"..tostr(v.name)..">" end
		s..=tostr(k).."="..quote(v)..(sep or ",")
	end
	return s.."}"
end

-- quotes all arguments
-- usage:
--   ?qq("p.x=",x,"p.y=",y)
function qq(...)
	local args=table.pack(...)
	local s=""
	for i=1,args.n do
		s..=quote(args[i]).." "
	end
	return s
end
function pq(...) printh(qq(...)) end

-- like sprintf (from c)
-- usage:
--   ?qf("%/% is %%",3,8,3/8*100,"%")
function qf(fmt,...)
	local parts,args=split(fmt,"%"),table.pack(...)
	local str=deli(parts,1)
	for ix,pt in ipairs(parts) do
		str..=quote(args[ix])..pt
	end
	if args.n~=#parts then
		str..="(extraqf:"..(args.n-#parts)..")"
	end
	return str
end
function pqf(...) printh(qf(...)) end
