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


local function printElement(elem)
    if type(elem) == "string" then
        --print(elem)
        return 
    end
    

    print(string.format("==== %s ====", elem._kind))

    -- print the attributes
    for name, value in elem:attributes() do
        print(name,value)
    end

    -- print the content
end

local function test_selectAll()
    -- iterate through all the nodes in 
    -- document order, printing something interesting along
    -- the way

    for child in doc:selectAll() do
	   printElement(child)
    end
end

local function test_selectAttribute()
    -- select the elements that have an attribute
    -- with the name 'sodipodi' in them
    local function hasSodipodiAttribute(entry)
        if type(entry) ~= "table" then
            return false;
        end

        for name, value in entry:attributes() do
            --print("hasSodipodi: ", entry._kind, name, value, type(name))
            if name:find("sodipodi") then
                return true;
            end
        end

        return false
    end

    for child in doc:selectElementMatches(hasSodipodiAttribute) do
        if type(child) == "table" then
            printElement(child)
        end
    end
end

local function test_selectElementMatches()
    print("<==== selectElementMatches: entry._kind == 'g' ====>")
	for child in doc:selectElementMatches(function(entry) if entry._kind == "g" then return true end end) do
		print(child._kind)
	end
end




local function test_getelementbyid()
    local elem = doc:getElementById("radialGradient10091")

    printElement(elem)
end

--test_selectAll();
test_selectAttribute()
--test_selectElementMatches()
--test_getelementbyid()
