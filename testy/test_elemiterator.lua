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
    -- iterate through all the nodes in 
    -- document order, printing something interesting along
    -- the way

    for idx, child in doc:selectAll() do
	   print(idx, child._kind);
    end
end

local function test_selectmatches()
	for child in doc:selectMatches(function(entry) if entry._kind == "g" then return true end end) do
		print(child._kind)
	end
end

local function getElementById(id)
    local function filterById(entry)
        print(entry.id, id)
        if entry.id == id then
            return true;
        end
    end

    for child in doc:selectMatches(filterById(id)) do
        return child;
    end
end

local function printElement(elem)
    -- print the attributes
    for k,v in pairs(elem) do
        if type(k) ~= "number" and k ~= "_kind" then
            print(k,v)
        end
    end

    -- print the content
end

local function test_getelementbyid()
    local elem = getElementById("radialGradient10091")

    printElement(elem)
end

--test_selectAll();
--test_selectmatches()
test_getelementbyid()
