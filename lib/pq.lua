--[[pod_format="raw",created="2024-03-21 09:14:17",modified="2024-03-22 03:04:46",revision=2]]
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
	local s=qq(...)
	notify(s)
	printh(s)
	return s
end

-- quotes all arguments into a string
-- usage:
--   ?qq("p.x=",x,"p.y=",y)
function qq(...)
	local s={}
	for i=1,select("#",...) do
		local arg=select(i,...) --NOTE: select is multi-return
		add(s,quote(arg))
	end
	return table.concat(s," ")
end

-- quote a single thing
-- like tostr() but for tables
-- don't call this directly; call pq or qq instead
function quote(t, depth)
	depth=depth or 4 --avoid inf loop
	if type(t)~="table" or depth<=0 then return tostr(t) end

	local s={}
	for k,v in pairs(t) do
		add(s,tostr(k).."="..quote(v,depth-1))
	end
	return "{"..table.concat(s,",").."}"
end