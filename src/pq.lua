--[[pod_format="raw",created="2024-03-16 08:58:31",modified="2024-03-19 04:32:49",revision=149]]
-- pq-debugging, by @pancelor
-- quotes all args and prints to host console
-- usage:
--   pq("handles nils", many_vars, {tables=1, work=11, too=111})
function pq(...)
	local s=qq(...)
	printh(s)
	return s
end

-- pq(), and also notify()
function pqn(...)
	notify(pq(...))
end

-- quotes all arguments into a string
-- usage:
--   ?qq("p.x=",x,"p.y=",y)
function qq(...)
	local s=""
	for i=1,select("#",...) do
		--need parens to only pass one arg to quote
		s..=quote( (select(i,...)) ).." "
	end
	return s
end

-- quote a single thing
-- like tostr() but for tables
-- don't call this directly; call pq or qq instead
function quote(t, depth)
	depth=depth or 4 --avoid inf loop
	if type(t)~="table" or depth<=0 then return tostr(t) end

	local s="{"
	for k,v in pairs(t) do
		s..=tostr(k).."="..quote(v,depth-1)..","
	end
	return s.."}"
end
