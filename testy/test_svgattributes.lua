package.path = "../?.lua;"..package.path

local sattr = require("remotesvg.SVGAttributes")
local parse = sattr.parseAttribute;

local svg = require("remotesvg.SVGElements")

local function test_rect()
	local r1 = svg.rect {
		x = "10",
		y = 10,
		width = "100",
		height = "200"
	}

	r1:parseAttributes();

	for k,v in pairs(r1) do
		print(k, v, type(v))
	end

end

function test_coord()
	local name, num, units = parse('cx', "100%")
	print("cx='100%' ",num, units)

	local name, num, units = parse('cx', "75")
	print("cx='75' ",num, units)

	local name, num, units = parse('cx', "12cm")
	print("cx='12cm' ",num, units)

end

test_coord()
--test_rect();