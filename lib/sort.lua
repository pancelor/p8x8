--[[pod_format="raw",created="2024-03-22 13:13:47",modified="2024-03-22 14:03:09",revision=12]]
-- shellsort; beefy insertion sort
-- local shell_gaps = {57,23,10,4,1}
local shell_gaps = {701,301,132,57,23,10,4,1}
function sort_shell(arr)
	for gap in all(shell_gaps) do
		for i=gap+1,#arr do
			local tomove,j = arr[i],i-gap
			while j>=1 and tomove<arr[j] do
				arr[j+gap] = arr[j]
				j -= gap
			end
			arr[j+gap] = tomove
		end
	end
end

function sort_insert(arr)
	for i=2,#arr do
		local tomove,j = arr[i],i-1
		while j>=1 and tomove<arr[j] do
			arr[j+1] = arr[j]
			j -= 1
		end
		arr[j+1] = tomove
	end
end



-- given a sorted array, add an element
-- and place it in sorted position
function add_sorted(arr,tomove)
	-- adding to the end, so i=#arr+1, essentially
	-- don't want shell sort -- we know arr is sorted already
	-- binary search would be less comparisons, but not much else (same number of shifts)
	local j = #arr
	while j>=1 and tomove<arr[j] do
		arr[j+1] = arr[j]
		j -= 1
	end
	arr[j+1] = tomove
end
function add_sorted_key(arr,tomove,key)
	local tomove_key = tomove[key]
	local j = #arr
	while j>=1 and tomove_key<arr[j][key] do
		arr[j+1] = arr[j]
		j -= 1
	end
	arr[j+1] = tomove
end
function add_sorted_by(arr,tomove,fn)
	local tomove_key = fn(tomove)
	local j = #arr
	while j>=1 and tomove_key<fn(arr[j]) do
		arr[j+1] = arr[j]
		j -= 1
	end
	arr[j+1] = tomove
end



