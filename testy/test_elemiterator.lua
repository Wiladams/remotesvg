--test_elemiterator.lua
-- load svg
package.path = "../?.lua;"..package.path;
local parser = require("remotesvg.parsesvg")

-- read the source file
-- pass in the name of your SVG document.lua file, without 
-- the '.lua' extension.
local filename = arg[1]
if not filename then return end

local doc = parser:parseFile(filename);

local function test_selectall()
-- iterate through all the nodes in document
-- order, printing something interesting along
-- the way

for idx, child in doc:selectAll() do
	print(idx, child._kind);
end
end

local function test_selectmatches()
	local function filter(entry)
		if entry._kind == "g" then 
			return true
		end
	end

	for child in doc:selectMatches(function(entry) if entry._kind == "g" then return true end end) do
		print(child._kind)
	end
end

--test_selectAll();
test_selectmatches()
