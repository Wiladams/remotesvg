--[[
--]]

local Document = {}
setmetatable(Document, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Document_mt = {
	__index = Document;
}

function Document.init(self, params)
	local obj = params or {}
	--obj.Shapes = obj.Shapes or {}
	obj.xmlns = obj.xmlns or 'http://www.w3.org/2000/svg';

	setmetatable(obj, Document_mt);

	return obj;
end

function Document.new(self, ...)
	return self:init(...)
end

function Document.addShape(self, shape)
	table.insert(self, shape);
end

function Document.write(self, strm)
	strm:write('<?xml version="1.0" standalone="no"?>\n');

	strm:openElement("svg");
	for name, value in pairs(self) do
		if type(value) ~= "table" then
			strm:addAttribute(name, tostring(value));
		end
	end
	strm:closeTag();

	for _, value in pairs(self) do
		if type(value) == "table" then
			value:write(strm);
		end
	end

	strm:closeElement("svg");
end

--[[

--]]
local Definitions = {}
setmetatable(Definitions, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Definitions_mt = {
	__index = Definitions;
}

function Definitions.init(self, params)
	local obj = params or {}
	--obj.Shapes = obj.Shapes or {}

	setmetatable(obj, Definitions_mt);

	return obj;
end

function Definitions.new(self, ...)
	return self:init(...)
end

function Definitions.addShape(self, shape)
	table.insert(self, shape);
end

function Definitions.write(self, strm)
	strm:openElement("defs");

	-- write things as attributes of the opening tag
	for name, value in pairs(self) do
		if type(value) ~= "table" then
			strm:addAttribute(name, tostring(value));
		end
	end
	strm:closeTag();

	-- now go through looking for shapes
	for name, value in pairs(self) do
		if type(value) == "table" then
			value:write(strm);
		end
	end

	strm:closeElement("defs");
end

--[[
	Group

	A group is like a document in that it is a container, 
	but it is not the top level container.  Various 
	attributes, such as style and transform that are
	set at this level will be inherited by the various children.

	Children are specified by putting them in the "Shapes" table.
--]]

local Group = {}
setmetatable(Group, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Group_mt = {
	__index = Group;
}

function Group.init(self, params)
	local obj = params or {}
	--obj.Shapes = obj.Shapes or {}

	setmetatable(obj, Group_mt);

	return obj;
end

function Group.new(self, ...)
	return self:init(...)
end

function Group.addShape(self, shape)
	table.insert(self, shape);
end

function Group.write(self, strm)
	strm:openElement("g");

	-- write things as attributes of the opening tag
	for name, value in pairs(self) do
		if type(value) ~= "table" then
			strm:addAttribute(name, tostring(value));
		end
	end
	strm:closeTag();

	-- now go through looking for shapes
	for name, value in pairs(self) do
		if type(value) == "table" then
			value:write(strm);
		end
	end

	strm:closeElement("g");
end


--[[
	Style
--]]
local Style = {}
setmetatable(Style, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local Style_mt = {
	__index = Style;

	__tostring = function(self)
		return self:toString();
	end
}

function Style.init(self, params)
	local obj = params or {}
	setmetatable(obj, Style_mt);

	return obj;
end

function Style.new(self, params)
	return self:init(params);
end

function Style.toString(self)
	local res = {}
	
	for name, value in pairs(self) do
		table.insert(res, name..":"..value)
	end
	
	local ret = table.concat(res, ';');

	return ret;
end

function Style.addAttribute(self, name, value)
	self[name] = value;
end


--[[
	Actual Geometry Elements
--]]
--[[
	Circle
	cx - center x
	cy - center y
	r - radius
--]]
local Circle = {}
setmetatable(Circle, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})

local Circle_mt = {
	__index = Circle;
}

function Circle.init(self, params)
	local obj = params or {}
	setmetatable(obj, Circle_mt);

	return obj;
end

function Circle.new(self, params)
	return self:init(params);
end

-- write ourself out as an SVG string
function Circle.write(self, strm)
	strm:openElement("circle")
	for name, value in pairs(self) do
			strm:addAttribute(name, tostring(value));
	end

	strm:closeElement();
end

--[[
--]]
local Ellipse = {}
setmetatable(Ellipse, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})

local Ellipse_mt = {
	__index = Ellipse;
}

function Ellipse.init(self, params)
	local obj = params or {}
	setmetatable(obj, Ellipse_mt);

	return obj;
end

function Ellipse.new(self, params)
	return self:init(params);
end

-- write ourself out as an SVG string
function Ellipse.write(self, strm)
	strm:openElement("ellipse")
	for name, value in pairs(self) do
			strm:addAttribute(name, tostring(value));
	end

	strm:closeElement();
end


--[[
	Line

	x1
	y1
	x2
	y2

--]]
local Line = {}
setmetatable(Line, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})

local Line_mt = {
	__index = Line;
}

function Line.init(self, params)
	local obj = params or {}
	setmetatable(obj, Line_mt);

	return obj;
end

function Line.new(self, params)
	return self:init(params);
end

-- write ourself out as an SVG string
function Line.write(self, strm)
	strm:openElement("line")
	for name, value in pairs(self) do
			strm:addAttribute(name, tostring(value));
	end

	strm:closeElement();
end

--[[
	Polygon

	points - table of points, each point represented by a table
--]]
local Polygon = {}
setmetatable(Polygon, {
	__call = function (self, ...)
		return self:new(...);
	end,
})
local Polygon_mt = {
	__index = Polygon;
}

function Polygon.init(self, params)
	local obj = params or {}
	setmetatable(obj, Polygon_mt);

	obj.points = obj.points or {};

	return obj;
end

function Polygon.new(self, params)
	return self:init(params);
end

function Polygon.write(self, strm)
	strm:openElement("polygon")
	for name, value in pairs(self) do
		if type(value) == "string" or
			type(value) == "number" then
			strm:addAttribute(name, tostring(value));
		end
	end

	-- write out the points
	if #self.points > 0 then
		local tbl = {};
		for _, pt in ipairs(self.points) do
			table.insert(tbl, string.format(" %d,%d", pt[1], pt[2]))
		end
		local pointsValue = table.concat(tbl, ' ');
--print("pointsValue: ", pointsValue)
		strm:addAttribute("points", pointsValue);
	end

	strm:closeElement();
end


--[[
	PolyLine

	points - table of points, each point represented by a table
--]]
local PolyLine = {}
setmetatable(PolyLine, {
	__call = function (self, ...)
		return self:new(...);
	end,
})
local PolyLine_mt = {
	__index = PolyLine;
}

function PolyLine.init(self, params)
	local obj = params or {}
	setmetatable(obj, PolyLine_mt);

	obj.points = obj.points or {};

	return obj;
end

function PolyLine.new(self, params)
	return self:init(params);
end

function PolyLine.write(self, strm)
	strm:openElement("polyline")
	for name, value in pairs(self) do
		if type(value) == "string" or
			type(value) == "number" then
			strm:addAttribute(name, tostring(value));
		end
	end

	-- write out the points
	if #self.points > 0 then
		local tbl = {};
		for _, pt in ipairs(self.points) do
			table.insert(tbl, string.format(" %d,%d", pt[1], pt[2]))
		end
		local pointsValue = table.concat(tbl, ' ');
--print("pointsValue: ", pointsValue)
		strm:addAttribute("points", pointsValue);
	end

	strm:closeElement();
end

--[[
	Rect
	x - left
	y - top
	width - how wide
	height - how tall
--]]
local Rect={}
setmetatable(Rect, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local Rect_mt = {
	__index = Rect;
}

function Rect.init(self, params)
	local obj = params or {}
	setmetatable(obj, Rect_mt)

	obj.x = obj.x or 0;
	obj.y = obj.y or 0;
	obj.width = obj.width or 0;
	obj.height = obj.height or 0;
	obj.rx = obj.rx or 0;
	obj.ry = obj.rx or obj.rx;

	return obj
end

function Rect.new(self, params)
	return self:init(params)
end

-- write ourself out as an SVG string
function Rect.write(self, strm)
	strm:openElement("rect")
	for name, value in pairs(self) do
		--if type(value) == "string" or
		--	type(value) == "number" then
			strm:addAttribute(name, tostring(value));
		--end
	end

	strm:closeElement();
end


--[[
	Text
--]]
local Text = {}
setmetatable(Text, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Text_mt = {
	__index = Text;
}

function Text.init(self, params, text)
	local obj = params or {}
	setmetatable(obj, Text_mt)

	obj.Text = obj.Text or text;

	return obj;
end

function Text.new(self, params, text)
	return self:init(params, text);
end

function Text.write(self, strm)
	strm:openElement("text")

	for name, value in pairs(self) do
		if name ~= "Text" then
			strm:addAttribute(name, tostring(value));
		end
	end
	strm:closeTag();

	-- write out the text context
	if self.Text then
		strm:write(self.Text)
	end

	strm:closeElement("text");
end


--[[
--]]
local Use = {}
setmetatable(Use, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})

local Use_mt = {
	__index = Use;
}

function Use.init(self, params)
	local obj = params or {}
	setmetatable(obj, Use_mt);

	return obj;
end

function Use.new(self, params)
	return self:init(params);
end

-- write ourself out as an SVG string
function Use.write(self, strm)
	strm:openElement("use")
	for name, value in pairs(self) do
			strm:addAttribute(name, tostring(value));
	end

	strm:closeElement();
end



--[[
	Interface exposed to outside world
--]]
return {
	Document = Document;		-- check
	Definitions = Definitions;	-- check
	Group = Group;				-- check
	Stroke = Stroke;
	Fill = Fill;

	Circle = Circle;			-- check
	Ellipse = Ellipse;			-- check
	Image = Image;
	Line = Line;				-- check
	Marker = Marker;
	Polygon = Polygon;			-- check
	PolyLine = PolyLine;		-- check
	Path = Path;
	Rect = Rect;				-- check
	Style = Style;				-- initial
	Text = Text;				-- check
	TextPath = TextPath;
	TRef = TRef;
	TSpan = TSpan;
	Use = Use;
}