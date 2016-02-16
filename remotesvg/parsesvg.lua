--[[
	A simple SVG Parser which fills in a lua based object model
	for the image specified.
--]]

local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift, band, bor = bit.lshift, bit.rshift, bit.band, bit.bor

local XmlParser = require("remotesvg.SVGXmlParser")
local svg = require("remotesvg.SVGElements")


local function Stack()
	local obj = {}
	setmetatable(obj, {
		__index = obj;
	})
	
	function obj.push(self, value)
		table.insert(self, value);
		
		return value;
	end

	function obj.pop(self)
		return table.remove(self)
	end

	function obj.top(self)
		if #self < 1 then
			return nil;
		end

		return self[#self];
	end

	return obj;
end






local SVGParser = {}
setmetatable(SVGParser, {
	__call = function(self, ...)
		return self:new(...);
	end
})
local SVGParser_mt = {
	__index = SVGParser;
}

function SVGParser.init(self)
	local obj = {
		ElemStack = Stack();
	}
	
	setmetatable(obj, SVGParser_mt);

	return obj;
end

function SVGParser.new(self)
	local parser = self:init()

	return parser;
end

function SVGParser.parse(self, input)
	XmlParser.parseXML(input, SVGParser.startElement, SVGParser.endElement, SVGParser.content, self)


	return self.Top;
end

function SVGParser.parseFile(self, filename)
	local fp = io.open(filename, "rb")
	if not fp then 
		return 
	end

	local data = fp:read("*a");
	fp:close();

	local parser = SVGParser();
	local shape = parser:parse(data)

	return shape;
end



function SVGParser.startElement(self, el, attr)
	--print("SVGParser.startElement: ", el, attr)
	-- create new element
	local newElem = svg.BasicElem(el, attr)

	-- if there's already something on the stack,
	-- then add the current element as a child
	if self.ElemStack:top() then
		self.ElemStack:top():append(newElem)
	else
		self.Top = newElem;
	end

	-- push the new element onto the stack
	self.ElemStack:push(newElem);
end


function SVGParser.endElement(self, el)
	-- pop it off the top of the stack
	self.ElemStack:pop();
end

-- Content is called for things like 
-- text, comments, titles, descriptions and the like
function SVGParser.content(self, s)
	--print("CONTENT TYPE: ", type(s))
	--print(s)

	self.ElemStack:top():appendLiteral(s)
end

return SVGParser
