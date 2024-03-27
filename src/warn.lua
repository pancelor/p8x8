--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-03-22 14:26:42",revision=490]]
function process_code(cart)
	local tabs = cart.lua
	if not tabs then return end

	local warns = {major={},minor={}} -- major = cart will not run   minor = cart needs adjustments
	local global_lno = 3 --skip p8 header
	for ti=1,#tabs do
		local lineno = lineno_build(tabs[ti])
		for warn in all(lint_all(tabs[ti])) do
			local lno = lineno_lookup(lineno,warn.index)
			local msg = string.format("WARN(%s): %d.lua#%d (p8:%d) %s",warn.kind,ti-1,lno,global_lno+lno,warn.msg)
			printh(msg)
			assert(warns[warn.kind],warn.kind) -- major or minor
			add(warns[warn.kind],msg)
		end
		global_lno += #lineno+2
	end
	if #warns.major>0 then
		sort_shell(warns.major)
		cart.lua_warn = table.concat(warns.major,"\n")
		notify_printh(string.format("(%d more) %s",#warns.major,warns.major[1]))
	elseif #warns.minor>0 then
		sort_shell(warns.minor)
		cart.lua_warn = table.concat(warns.minor,"\n")
		notify_printh(string.format("(%d more) %s",#warns.minor,warns.minor[1]))
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

local function _lint_find(src,res,kind,substr,plain,msg)
	local ri=1
	for i=1,100 do --sentinel
		local i0,i1 = string.find(src,substr,ri,plain)
		if not i0 then
			break
		end
		add(res,{kind=kind,index=i0,msg=msg})
		ri = i1+1
	end
end
local function _lint_literal(src,res,kind,substr,msg)
	_lint_find(src,res,kind,substr,true,msg)
end
local function _lint_pattern(src,res,kind,substr,msg)
	_lint_find(src,res,kind,substr,false,msg)
end

-- takes a code string, and returns a list of warning strings
function lint_all(src)
	local res = {}
	_lint_literal(src,res,"minor","[^:]//",[['//' is not a valid comment (change to '--'?)]]) --avoid colons b/c of URL false-positives
	-- _lint_pattern(src,res,"[^%w]goto[^%w]",[['goto' found; custom main loops are not supported]])
	_lint_pattern(src,res,"minor","\n%s*#include",[['#include' is not supported]])
	_lint_pattern(src,res,"minor","[%d]do[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"minor","[%d]then[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"minor","[%d]and[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"minor","[%d]or[^%w]",[[numbers into keywords need a space in between]])
	_lint_pattern(src,res,"major","[^<>]>>>[^<>]",[[lshr (>>>) is not supported]])
	_lint_pattern(src,res,"major","[^<>]<<>[^<>]",[[rotl (>>>) is not supported]])
	_lint_pattern(src,res,"major","[^<>]>><[^<>]",[[rotr (>>>) is not supported]])
	_lint_pattern(src,res,"major","[^%w]load%s*%(",[[cart chaining (load()) is not supported]])
	lint_symbols(src,res)
	return res
end

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
			_lint_literal(src,res,"minor",ch,string.format("special chars (shift-%s) are not supported. use this, for example: btn(p8x8_symbol\"%s\") instead of btn(%s)",chr(ix-127+0x40),example,example))
			--todo: dont warn if they already added p8x8_symbol into their code
		else
			--katakana, low ascii
			_lint_literal(src,res,"minor",ch,string.format("special chars (chr(%d)) are not supported",ix))
		end
	end
end
