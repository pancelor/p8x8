--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-03-21 13:06:39",revision=209]]
function check_code_warnings(tabs)
	for i=1,#tabs do
		for warning in all(lint_all(tabs[i])) do
			local msg = string.format("CODE WARNING: tab%d: %s",i-1,warning)
			printh(msg)
			notify(msg)
		end
	end
end

function lint_literal(src,res,substr,msg)
	local i0 = src:find(substr,1,true)
	if i0 then
		add(res,i0..": "..msg) --TODO line:col
		return true
	end
end

-- takes a code string, and returns a list of warning strings
function lint_all(src)
	local res = {}
	lint_literal(src,res,"//",[['//' is not a valid comment (change to '--'?)]])
	lint_literal(src,res,"goto",[['goto' found; custom main loops are not supported]])
	-- TODO: check for "\n\s*#include\s" but using lua regex
	lint_literal(src,res,"\n#include",[['#include' is not supported]])
	return res
end




