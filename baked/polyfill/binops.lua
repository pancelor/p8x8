--[[pod_format="raw",created="2024-03-19 22:36:09",modified="2024-03-19 22:42:00",revision=6]]
-- despite this polyfill, things will still be awkward
--   because p8 uses 16.16 fixed-point 
--   but p64 uses floating point
-- cart authors will need to manually fix this

function band(x,y)
	if (type(x) != "number") x = 0
	if (type(y) != "number") y = 0
	return x&y
end
function bor(x,y)
	if (type(x) != "number") x = 0
	if (type(y) != "number") y = 0
	return x|y
end
function bxor(x,y)
	if (type(x) != "number") x = 0
	if (type(y) != "number") y = 0
	return x^^y
end
function bnot(x)
	if (type(x) != "number") x = 0
	return ~x
end

function shl(x,n)
	if (type(x) != "number") x = 0
	if (type(n) != "number") n = 0
	return x<<n
end
function shr(x,n)
	if (type(x) != "number") x = 0
	if (type(n) != "number") n = 0
	return x>>n
end

-- these operators don't exist (yet?)

--function lshr(x,n)
--	if (type(x) != "number") x = 0
--	if (type(n) != "number") n = 0
--	return x>>>n
--end
--function rotl(x,n)
--	if (type(x) != "number") x = 0
--	if (type(n) != "number") n = 0
--	return x<<>n
--end
--function rotr(x,n)
--	if (type(x) != "number") x = 0
--	if (type(n) != "number") n = 0
--	return x>><n
--end
