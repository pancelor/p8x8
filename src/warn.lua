--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-03-20 02:22:31",revision=92]]
function check_code_warnings(tabs)
	for i=1,#tabs do
		for warning in all(lint_all(tabs[i])) do
			local msg = string.format("CODE WARNING: tab%d: %s",i-1,warning)
			printh(msg)
			notify(msg)
		end
	end
end

-- takes a code string, and returns a list of warning strings
function lint_all(src)
	local res = {}
	if src:find("//",1,true) then
		add(res,[['//' is not a valid comment (change to '--'?)]])
	end
	if src:find("goto",1,true) then
		add(res,[['goto' found; custom main loops are not supported]])
	end
	return res
end




