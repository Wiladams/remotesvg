--test_patterns.lua
package.path = "../?.lua;"..package.path

local sattr = require("remotesvg.SVGAttributes")
local parse = sattr.parseAttribute;

local str = "10, 20.3, 42 375.67"
local patt1 = "(%S+)"
local patt2 = "(%d+%.?%d+)"

local style = 'stop-color:#191b21;stop-opacity:0.34437087;'
local stylepatt = "([^;]+)"

local function printItems(patt, str)
	print("printItems: ", patt, str)

	for item in str:gmatch(patt) do
		print(item)
	end
end

printItems(patt1, str)
printItems(patt2, str)

local function parseStyle(patt, str)
	print("parseStyle: ", patt, str)

	local tbl = {}

	for item in str:gmatch(patt) do
		local name, value = item:match("(%g+):(%g+)")
		print("item:match: ", name, value)
		name, value = parse(name, value)
		print("parse result: ", name, value)
		tbl[name] = value;
	end

	for k,v in pairs(tbl) do
		print(k,v)
	end
end
parseStyle(stylepatt, style)
