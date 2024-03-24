--[[pod_format="raw",created="2024-03-16 08:58:31",modified="2024-03-18 02:14:56",revision=3]]
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
function pqn(...) local s=qq(...) notify(s) pq(s) end
