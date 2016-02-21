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
	local function printcoord(str)
		local name, v = parse('cx', str)
		print(name, str, v.value, v.units, v)
	end

	printcoord('100%')
	printcoord('75')
	printcoord('12cm')

end

function test_viewbox()
	local vbox = parse("viewBox", "0 50 10 100")
	print(vbox)

	local vbox = parse("viewBox", "20, 30, 100, 200")
	print(vbox)

end

--test_coord()
--test_rect();
test_viewbox();
