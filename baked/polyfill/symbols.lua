--[[
	For an explanation of this file, read:
	https://github.com/pancelor/p8x8/blob/main/doc/symbols.md
--]]

local p8scii_value_from_string = {
	["█"]=0.5, ["▒"]=23130.5, ["🐱"]=20767.5, ["⬇️"]=3, ["░"]=32125.5, ["✽"]=-18402.5, ["●"]=-1632.5, ["♥"]=20927.5, ["☉"]=-19008.5, ["웃"]=-26208.5, ["⌂"]=-20192.5, ["⬅️"]=0, ["😐"]=-24351.5, ["♪"]=-25792.5, ["🅾️"]=4, ["◆"]=-20032.5,
	["…"]=-2560.5, ["➡️"]=1, ["★"]=-20128.5, ["⧗"]=6943.5, ["⬆️"]=2, ["ˇ"]=-2624.5, ["∧"]=31455.5, ["❎"]=5, ["▤"]=3855.5, ["▥"]=21845.5,
}

local function invert(tab)
	local res = {}
	for k,v in pairs(tab) do
		res[v] = k
	end
	return res
end

local p8scii_ord_from_string = invert{[0]="\0",
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



-- make it easy to replace `btn(⬆️)` with `btn(p8x8_symbol"⬆️")`
function p8env.p8x8_symbol(sym)
	return p8scii_value_from_string[sym]
end

function p8env.p8x8_symbol_visual(str)
	return chr(p8scii_ord_from_string[str])
end

-- make it easy to replace `myfont="あつてと⬆️エ..."` with `myfont=p8x8_datastring"あつてと⬆️エ..."`
local _datastring_cache = {}
function p8env.p8x8_datastring(str)
	-- instead of calling this, you could convert the data once and replace the code
	local res = _datastring_cache[str]
	if res then
		return res
	end

	local strlist = {} -- the replacement string
	local numlist = {} -- the suggested number replacement list
	local i0,i1 = 1,0
	while i1<#str do
		i1 += 1
		local substr = sub(str,i0,i1)
		local num = p8scii_ord_from_string[substr]
		if num then
			add(numlist,string.format("0x%02x",num))
			add(strlist,string.char(num))
			i0 = i1+1
		end
	end
	res = table.concat(strlist,"")
	printh(string.format("p8x8_datastring(\"%s ...\"): consider writing your data directly as numbers: {%s}",sub(str,1,16*3),table.concat(numlist,",")))
	_datastring_cache[str] = res

	return res
end
-- p8env.p8x8_datastring = function(...) return p64env.p8x8_datastring(...) end

