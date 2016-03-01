--test_patterns.lua
package.path = "../?.lua;"..package.path

local sattr = require("remotesvg.SVGAttributes")
local parse = sattr.parseAttribute;

local function test_numbers()
	local str = "10, 20.3, 42 375.67"
	local patt1 = "(%S+)"
	local patt2 = "(%d+%.?%d+)"


	local function printItems(patt, str)
		print("printItems: ", patt, str)

		for item in str:gmatch(patt) do
			print(item)
		end
	end

	printItems(patt1, str)
	printItems(patt2, str)
end

local function test_style()
	local str = 'stop-color:#191b21;stop-opacity:0.34437087;'
	local patt = "([^;]+)"
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

local function parsetransform(name, value, strict)

	local patt = "(%a+)(%b())"
	local numpatt = "([+-]?%d+%.?%d*)"

	local tbl = {}
	for kind, value in value:gmatch(patt) do
		--print (kind, value)
		local nums = {}
		-- get the list of numbers
		for num in value:gmatch(numpatt) do
			table.insert(nums, num)
		end

		if #nums > 0 then
			if kind == "translate" then
				local x = nums[1];
				local y = nums[2] or 0;
				local item = {name = 'translate', x = x, y = y}
				setmetatable(item, {
					__tostring = function(self)
						return string.format('translate(%f %f)', self.x, self.y);
					end,
				})
				table.insert(tbl, item)
			elseif kind == "rotate" then
				local angle = nums[1];
				local item = {name = "rotate", angle=angle, x = nums[2], y = nums[3]}
				setmetatable(item, {
					__tostring = function(self)
						if self.x and self.y then
						return string.format("%s(%f %f %f)", self.name, self.angle, self.x, self.y)
						elseif self.angle then
							return string.format("%s(%f)", self.name, self.angle);
						end
						return ""
					end,
					})				
				table.insert(tbl, item)
			elseif kind == "scale" then
				local x = nums[1]
				local y = nums[2] or x
				local item = {name="scale", x=x, y=y}
				setmetatable(item, {
					__tostring = function(self)
						if self.x and self.y then
							return string.format("%s(%f %f)", self.name, self.x, self.y)
						elseif self.x then
							return string.format("%s(%f)", self.name, self.x);
						else
							return ""
						end
					end
				})
				table.insert(tbl, item)
			elseif kind == "skewX" then
			elseif kind == "skewY" then
				-- get the numbers out
			elseif kind == "matrix" then
			end
		end
	end

	return name, tbl
end

local function test_transform()
	print("==== test_transform ====")
	local subject = "translate(20 10) rotate(30 10 10)"

	name, obj = parsetransform("transform", subject)

	print("== RESULTS ==")
	for idx, item in ipairs(obj) do
		print(item)
	end
end

--test_numbers();
--test_style();
test_transform()
