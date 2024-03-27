--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-03-22 14:26:42",revision=490]]
function process_code(cart)
	local tabs = cart.lua
	if not tabs then return end

	local warns = {}
	local global_lno = 3
	for ti=1,#tabs do
		local lineno = lineno_build(tabs[ti])
		for warn in all(lint_all(tabs[ti])) do
			local lno = lineno_lookup(lineno,warn.index)
			local msg = string.format("WARN: %d.lua#%d (p8:%d) %s",ti-1,lno,global_lno+lno,warn.msg)
			printh(msg)
			add_sorted(warns,msg)
		end
		global_lno += #lineno+2
	end
	if #warns>0 then
		cart.lua_warn = table.concat(warns,"\n")
		notify_printh(string.format("(%d more) %s",#warns,warns[1]))
	end
end

function lineno_build(src)
	local book = {}
	local ri = 1
	for i=1,10000 do --sentinel
		local ni = string.find(src,"\n",ri,true)
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
		local i0,i1 = string.find(src,substr,ri,plain)
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
	_lint_literal(src,res,"[^:]//",[['//' is not a valid comment (change to '--'?)]]) --avoid colons b/c of URL false-positives
	-- _lint_pattern(src,res,"[^%w]goto[^%w]",[['goto' found; custom main loops are not supported]])
	_lint_pattern(src,res,"\n%s*#include",[['#include' is not supported]])
	_lint_pattern(src,res,"[%d]do[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[%d]then[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[%d]and[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"[^<>]>>>[^<>]",[[lshr (>>>) is not supported]])
	_lint_pattern(src,res,"[^<>]<<>[^<>]",[[rotl (>>>) is not supported]])
	_lint_pattern(src,res,"[^<>]>><[^<>]",[[rotr (>>>) is not supported]])
	_lint_pattern(src,res,"[%d]or[^%w]",[[numbers into keywords need a space in between]])
	lint_symbols(src,res)
	return res
end

-- local _symbols = {
-- 	["█"]=128, ["▒"]=129, ["🐱"]=130, ["⬇️"]=131, ["░"]=132, ["✽"]=133, ["●"]=134, ["♥"]=135, ["☉"]=136, ["웃"]=137, ["⌂"]=138, ["⬅️"]=139, ["😐"]=140, ["♪"]=141, ["🅾️"]=142, ["◆"]=143,
-- 	["…"]=144, ["➡️"]=145, ["★"]=146, ["⧗"]=147, ["⬆️"]=148, ["ˇ"]=149, ["∧"]=150, ["❎"]=151, ["▤"]=152, ["▥"]=153, ["あ"]=154, ["い"]=155, ["う"]=156, ["え"]=157, ["お"]=158, ["か"]=159,
-- 	["き"]=160, ["く"]=161, ["け"]=162, ["こ"]=163, ["さ"]=164, ["し"]=165, ["す"]=166, ["せ"]=167, ["そ"]=168, ["た"]=169, ["ち"]=170, ["つ"]=171, ["て"]=172, ["と"]=173, ["な"]=174, ["に"]=175,
-- 	["ぬ"]=176, ["ね"]=177, ["の"]=178, ["は"]=179, ["ひ"]=180, ["ふ"]=181, ["へ"]=182, ["ほ"]=183, ["ま"]=184, ["み"]=185, ["む"]=186, ["め"]=187, ["も"]=188, ["や"]=189, ["ゆ"]=190, ["よ"]=191,
-- 	["ら"]=192, ["り"]=193, ["る"]=194, ["れ"]=195, ["ろ"]=196, ["わ"]=197, ["を"]=198, ["ん"]=199, ["っ"]=200, ["ゃ"]=201, ["ゅ"]=202, ["ょ"]=203, ["ア"]=204, ["イ"]=205, ["ウ"]=206, ["エ"]=207,
-- 	["オ"]=208, ["カ"]=209, ["キ"]=210, ["ク"]=211, ["ケ"]=212, ["コ"]=213, ["サ"]=214, ["シ"]=215, ["ス"]=216, ["セ"]=217, ["ソ"]=218, ["タ"]=219, ["チ"]=220, ["ツ"]=221, ["テ"]=222, ["ト"]=223,
-- 	["ナ"]=224, ["ニ"]=225, ["ヌ"]=226, ["ネ"]=227, ["ノ"]=228, ["ハ"]=229, ["ヒ"]=230, ["フ"]=231, ["ヘ"]=232, ["ホ"]=233, ["マ"]=234, ["ミ"]=235, ["ム"]=236, ["メ"]=237, ["モ"]=238, ["ヤ"]=239,
-- 	["ユ"]=240, ["ヨ"]=241, ["ラ"]=242, ["リ"]=243, ["ル"]=244, ["レ"]=245, ["ロ"]=246, ["ワ"]=247, ["ヲ"]=248, ["ン"]=249, ["ッ"]=250, ["ャ"]=251, ["ュ"]=252, ["ョ"]=253, ["◜"]=254, ["◝"]=255,
-- }
-- function lint_symbols(src,res)
-- 	-- not perfect but good enough
-- 	for ch,val in pairs(_symbols) do
-- 		local letter=val-127 -- 1-26
-- 		if letter<=26 then
-- 			-- shift-letter
-- 			local example = chr(0x82)
-- 			_lint_literal(src,res,ch,string.format("special chars (shift-%s) are not supported. use this, for example: btn(p8x8_symbol\"%s\") instead of btn(%s)",chr(letter+0x40),example,example))
-- 		else
-- 			_lint_literal(src,res,ch,string.format("katakana chars (chr(%d)) are not supported",val))
-- 		end
-- 	end
-- end

--[[
	s=""
	for i=1,255 do
		s..='"'..chr(i)..'", '
		if i%16==15 then s..="\n" end
	end
	printh(s,"@clip") --\\ and \" need editing
]]
local p8scii = {
		"¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "\t", "\n", "ᵇ", "ᶜ", "\r", "ᵉ", "ᶠ",
	"▮", "■", "□", "⁙", "⁘", "‖", "◀", "▶", "「", "」", "¥", "•", "、", "。", "゛", "゜",
	" ", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?",
	"@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
	"P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_",
	"`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
	"p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "○",
	"█", "▒", "🐱", "⬇️", "░", "✽", "●", "♥", "☉", "웃", "⌂", "⬅️", "😐", "♪", "🅾️", "◆",
	"…", "➡️", "★", "⧗", "⬆️", "ˇ", "∧", "❎", "▤", "▥", "あ", "い", "う", "え", "お", "か",
	"き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と", "な", "に",
	"ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め", "も", "や", "ゆ", "よ",
	"ら", "り", "る", "れ", "ろ", "わ", "を", "ん", "っ", "ゃ", "ゅ", "ょ", "ア", "イ", "ウ", "エ",
	"オ", "カ", "キ", "ク", "ケ", "コ", "サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト",
	"ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "マ", "ミ", "ム", "メ", "モ", "ヤ",
	"ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン", "ッ", "ャ", "ュ", "ョ", "◜", "◝",
}
function lint_symbols(src,res)
	-- not perfect but good enough
	-- for ch,val in pairs(_symbols) do
	-- 	local letter=val-127 -- 1-26
	-- 	if letter<=26 then
	-- 	end
	-- end

	for ix,ch in ipairs(p8scii) do
		if (32<=ix and ix<=126) or ix==9 or ix==10 or ix==13 then
			-- no problem, move on
		elseif 128<=ix and ix<=127+26 then
			-- shift-letter
			local example = chr(0x82)
			_lint_literal(src,res,ch,string.format("special chars (shift-%s) are not supported. use this, for example: btn(p8x8_symbol\"%s\") instead of btn(%s)",chr(ix-127+0x40),example,example))
			--todo: dont warn if they already added p8x8_symbol into their code
		else
			--katakana, low ascii
			_lint_literal(src,res,ch,string.format("special chars (chr(%d)) are not supported",ix))
		end
	end
end
