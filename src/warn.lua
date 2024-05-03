--[[pod_format="raw",created="2024-03-20 01:24:07",modified="2024-04-03 21:56:20",revision=500]]
--[[
TODO:
- better font detection
	show replacement code in the warning itself?
	at least link to the font re-encoding snippet (https://github.com/pancelor/p8x8/blob/main/compat.md#custom-fonts)
- limit symbol warning spam; e.g. only show one symbol warning per line. or hard cap after 50?
	should maybe process each line in order, rather than each rules in order...
	would allow more smarts, e.g. "this looks like a font, please use this instead: <generated code>"
	would running a bunch of regexes per-line be slower? yes. hmm
]]

-- returns success
function process_code(cart)
	local tabs = cart.lua
	if not tabs then return true end

	local warns = {}
	local global_lno = 3 --skip p8 header
	for ti=1,#tabs do
		local lineno = lineno_build(tabs[ti])
		for warn in all(lint_all(tabs[ti])) do
			local lno = lineno_lookup(lineno,warn.index)
			local msg = string.format("WARN(%s): %d.lua#%d (p8:%d) %s",tostr(warn.lvl),ti-1,lno,global_lno+lno,warn.msg)
			printh(msg)
			add(warns,msg)
		end
		global_lno += #lineno+2
	end
	if #warns>0 then
		sort_shell(warns) --major will be first, nice
		cart.lua_warn = table.concat(warns,"\n")
		notify_printh(string.format("(%d more) %s",#warns,warns[1])) -- BUG: this is stomped on by "imported!" in import_p8()
	end
	return true
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

local function _lint_find(src,res,lvl,substr,plain,msg)
	local ri = 1
	for i=1,100 do --sentinel
		local i0,i1 = string.find(src,substr,ri,plain)
		if not i0 then
			break
		end
		add(res,{lvl=lvl,index=i0,msg=msg})
		ri = i1+1
	end
end
local function _lint_literal(src,res,lvl,substr,msg)
	_lint_find(src,res,lvl,substr,true,msg)
end
local function _lint_pattern(src,res,lvl,substr,msg)
	_lint_find(src,res,lvl,substr,false,msg)
end

-- takes a code string, and returns a list of warning strings
function lint_all(src)
	local res = {}
	_lint_pattern(src,res,1,"\n%s*#include",[['#include' is not supported -- re-export your cart from PICO-8 as a .p8.png and then back to .p8 to inline the includes`]])
	-- you could instead write `p64env.include(filename)`,
	--   but the nuances are complicated -- need to move that file manually to
	--   the correct path, p8x8 won't generate warnings for that file, and I'm
	--   not 100% sure whether `include`ing will stay within the p8env sandbox

	_lint_pattern(src,res,1,"[%d]do[^%w]",[[numbers into keywords need whitespace; e.g. "99do" => "99 do"]])
	_lint_pattern(src,res,1,"[%d]then[^%w]",[[numbers into keywords need whitespace; e.g. "99then" => "99 then"]])
	_lint_pattern(src,res,1,"[%d]and[^%w]",[[numbers into keywords need whitespace; e.g. "99and" => "99 and"]])
	_lint_pattern(src,res,1,"[%d]or[^%w]",[[numbers into keywords need whitespace; e.g. "99or" => "99 or"]])
	_lint_pattern(src,res,1,"[%d]if[^%w]",[[numbers into keywords need whitespace; e.g. "99if" => "99 if"]])
	_lint_pattern(src,res,1,"[^<>]>>>[^<>]",[[lshr (>>>) is not supported]])
	_lint_pattern(src,res,1,"[^<>]<<>[^<>]",[[rotl (>>>) is not supported]])
	_lint_pattern(src,res,1,"[^<>]>><[^<>]",[[rotr (>>>) is not supported]])
	_lint_pattern(src,res,1,"[^%w]load%s*%(",[[cart chaining (load()) is not supported]])
	_lint_pattern(src,res,2,"[^:]//",[['//' is not a valid comment (change to '--'?)]]) --avoid colons b/c of URL false-positives
	_lint_pattern(src,res,2,"[^%w]tline%s*%(",[[tline isn't supported yet - TODO]])
	_lint_pattern(src,res,2,"[^%w]cstore%s*%(",[[cstore isn't supported]])
	_lint_pattern(src,res,2,"[^%w]serial%s*%(",[[serial isn't supported]])
	_lint_pattern(src,res,2,"[^%w]reload%s*%(",[[reload only has partial support]])
	lint_memory(src,res,3)
	lint_symbols(src,res,3)
	return res
end

function lint_memory(src,res,lvl)
	for name in all{"poke","poke2","poke4","peek","peek2","peek4","memset","memcpy"} do
		_lint_pattern(src,res,lvl,"[^%w]"..name.."%s*%(",name..[[: PICO-8 memory layout is not emulated; this might not work]])
	end
end

--[[ generate this table in PICO-8 with this code + manual cleanup (\\ and \" need editing)
	s=""
	for i=1,255 do
		s..='"'..chr(i)..'", '
		if i%16==15 then s..="\n" end
	end
	printh(s,"@clip")
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
function lint_symbols(src,res,lvl)
	for ix,ch in ipairs(p8scii) do
		if (32<=ix and ix<=126) or ix==9 or ix==10 or ix==13 then
			-- no problem, move on
		elseif 128<=ix and ix<=127+26 then
			-- shift-letter
			local letter = ix-127 -- A=1
			local example = chr(0x7f+letter)
			_lint_literal(src,res,lvl,ch,string.format("special symbols (shift-%s / chr(%d)) are not supported. use this, for example: fillp(p8x8_symbol\"%s\") instead of fillp(%s)",chr(letter+0x40),ix,example,example))
			--todo: dont warn if they already added p8x8_symbol into their code
		else
			--katakana, low ascii
			_lint_literal(src,res,lvl,ch,string.format("special symbols (chr(%d)) are not supported",ix))
		end
	end
end
