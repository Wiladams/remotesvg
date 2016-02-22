--test_patterns.lua

local str = "10, 20.3, 42 375.67"

local patt1 = "(%S+)"
local patt2 = "(%x+%.?%x+)"

local function printNumbers(patt)
	print("printNumbers: ", patt, str)

	for num in str:gmatch(patt) do
		print(num)
	end
end

printNumbers(patt1)
printNumbers(patt2)
