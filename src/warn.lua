--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-03-22 14:26:42",revision=490]]
function process_code(cart)
	local tabs = cart.lua
	local warns = {}
	for ti=1,#tabs do
		local lineno = lineno_build(tabs[ti])
		for warn in all(lint_all(tabs[ti])) do
			local lno = lineno_lookup(lineno,warn.index)
			local msg = string.format("WARN: %d.lua#%d %s",ti-1,lno,warn.msg)
			printh(msg)
			add_sorted(warns,msg)
		end
	end
	if #warns>0 then
		cart.lua_warn = table.concat(warns,"\n")
		notify(string.format("(%d more) %s",#warns,warns[1]))
	end
end

function lineno_build(src)
	local book = {}
	local ri = 1
	for i=1,10000 do
		local ni = src:find("\n",ri)
		if not ni then
			break
		end
		add(book,ni)
		ri = ni+1
	end
	return book
end
function lineno_lookup(lineno,index)
	for li,charcount in ipairs(lineno) do
		if index<charcount then
			--finally found a line that hasn't passed index yet
			return li
		end
	end
	return #lineno
end

local function _lint_find(src,res,substr,plain,msg)
	local ri=1
	for i=1,100 do
		local i0,i1 = src:find(substr,ri,plain)
		if not i0 then
			break
		end
		add(res,{index=i0,msg=msg})
		ri = i1+1
	end
end
local function _lint_literal(src,res,substr,msg)
	_lint_find(src,res,substr,true,msg)
end
local function _lint_pattern(src,res,substr,msg)
	_lint_find(src,res,substr,false,msg)
end

-- takes a code string, and returns a list of warning strings
function lint_all(src)
	local res = {}
	_lint_literal(src,res,"//",[['//' is not a valid comment (change to '--'?)]])
	_lint_pattern(src,res,"[^%w]goto[^%w]",[['goto' found; custom main loops are not supported]])
	_lint_pattern(src,res,"\n%s*#include",[['#include' is not supported]])
	_lint_pattern(src,res,"[%d]do[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[%d]then[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[%d]and[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[%d]or[^%w]",[[numbers into keywords need a space in between]])
	lint_specials(src,res)
	return res
end

local _specials = {
	["█"]=0.5, ["▒"]=23130.5, ["🐱"]=20767.5, ["⬇️"]=3, ["░"]=32125.5, ["✽"]=-18402.5, ["●"]=-1632.5, ["♥"]=20927.5, ["☉"]=-19008.5, ["웃"]=-26208.5, ["⌂"]=-20192.5, ["⬅️"]=0, ["😐"]=-24351.5, ["♪"]=-25792.5, ["🅾️"]=4, ["◆"]=-20032.5,
	["…"]=-2560.5, ["➡️"]=1, ["★"]=-20128.5, ["⧗"]=6943.5, ["⬆️"]=2, ["ˇ"]=-2624.5, ["∧"]=31455.5, ["❎"]=5, ["▤"]=3855.5, ["▥"]=21845.5,
}
local _katakana = {
	["あ"]=154, ["い"]=155, ["う"]=156, ["え"]=157, ["お"]=158, ["か"]=159,
	["き"]=160, ["く"]=161, ["け"]=162, ["こ"]=163, ["さ"]=164, ["し"]=165, ["す"]=166, ["せ"]=167, ["そ"]=168, ["た"]=169, ["ち"]=170, ["つ"]=171, ["て"]=172, ["と"]=173, ["な"]=174, ["に"]=175,
	["ぬ"]=176, ["ね"]=177, ["の"]=178, ["は"]=179, ["ひ"]=180, ["ふ"]=181, ["へ"]=182, ["ほ"]=183, ["ま"]=184, ["み"]=185, ["む"]=186, ["め"]=187, ["も"]=188, ["や"]=189, ["ゆ"]=190, ["よ"]=191,
	["ら"]=192, ["り"]=193, ["る"]=194, ["れ"]=195, ["ろ"]=196, ["わ"]=197, ["を"]=198, ["ん"]=199, ["っ"]=200, ["ゃ"]=201, ["ゅ"]=202, ["ょ"]=203, ["ア"]=204, ["イ"]=205, ["ウ"]=206, ["エ"]=207,
	["オ"]=208, ["カ"]=209, ["キ"]=210, ["ク"]=211, ["ケ"]=212, ["コ"]=213, ["サ"]=214, ["シ"]=215, ["ス"]=216, ["セ"]=217, ["ソ"]=218, ["タ"]=219, ["チ"]=220, ["ツ"]=221, ["テ"]=222, ["ト"]=223,
	["ナ"]=224, ["ニ"]=225, ["ヌ"]=226, ["ネ"]=227, ["ノ"]=228, ["ハ"]=229, ["ヒ"]=230, ["フ"]=231, ["ヘ"]=232, ["ホ"]=233, ["マ"]=234, ["ミ"]=235, ["ム"]=236, ["メ"]=237, ["モ"]=238, ["ヤ"]=239,
	["ユ"]=240, ["ヨ"]=241, ["ラ"]=242, ["リ"]=243, ["ル"]=244, ["レ"]=245, ["ロ"]=246, ["ワ"]=247, ["ヲ"]=248, ["ン"]=249, ["ッ"]=250, ["ャ"]=251, ["ュ"]=252, ["ョ"]=253, ["◜"]=254, ["◝"]=255,
}
function lint_specials(src,res)
	-- not perfect but good enough
	for ch,val in pairs(_specials) do
		_lint_literal(src,res,ch,string.format("special chars (%.1f) are not supported",val))
	end
	for ch,val in pairs(_katakana) do
		_lint_literal(src,res,ch,string.format("katakana chars (chr(%d)) are not supported",val))
	end
end

