--[[
	SVGElem

	A base type for all other SVG Elements.
	This can do the basic writing
--]]
local BasicElem = {}
setmetatable(BasicElem, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local BasicElem_mt = {
	__index = BasicElem;
}

function BasicElem.new(self, kind, params)
	local obj = params or {}
	obj._kind = kind;

	setmetatable(obj, BasicElem_mt);

	return obj;
end



-- Add an attribute to ourself
function BasicElem.attr(self, name, value)
	self[name] = value;
	return self;
end

-- Add a new child element
function BasicElem.append(self, name)
	-- based on the obj, find the right object
	-- to represent it.
	local child = nil;

	if type(name) == "table" then
		child = name;
	elseif type(name) == "string" then
		child = BasicElem(name);
	else
		return nil;
	end

	table.insert(self, child);

	return child;
end

function BasicElem.write(self, strm)
	strm:openElement(self._kind);

	local childcount = 0;

	for name, value in pairs(self) do
		if type(value) == "table" then
			childcount = childcount + 1;
		else
			if name ~= "_kind" then
				strm:writeAttribute(name, tostring(value));
			end
		end
	end

	if childcount > 0 then
		strm:closeTag();

		-- write out child nodes
		for _, value in pairs(self) do
			if type(value) == "table" then
				value:write(strm);
			end
		end
		
		strm:closeElement(self._kind);
	else
		strm:closeElement();
	end
end


--[[
	SVG
--]]
local function SVG(params)
	local elem = BasicElem('svg', params);
	elem.xmlns = elem.xmlns or "http://www.w3.org/2000/svg"
	elem.version = params.version or "1.1"

	return elem;
end

--[[
	Definitions
--]]
local function Definitions(params)
	return BasicElem('defs', params);
end


--[[
	Group

	A group is like a document in that it is a container, 
	but it is not the top level container.  Various 
	attributes, such as style and transform that are
	set at this level will be inherited by the various children.

	Children are specified by putting them in the "Shapes" table.
--]]
local Group = function(params)
	return BasicElem('g', params)
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

function Style.writeAttribute(self, name, value)
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
local function Circle(params)
	return BasicElem('circle', params)
end


local function Ellipse(params)
	return BasicElem('ellipse', params)
end


--[[
	Gradients
--]]
local function LinearGradient(params)
	return BasicElem('linearGradient', params)
end

local function RadialGradient(params)
	return BasicElem('radialGradient', params)
end

local function Stop(params)
	return BasicElem('stop', params)
end

--[[
	Literal

	Copies whatever is contained directory into the
	output stream.
--]]
local Literal = {}
setmetatable(Literal, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Literal_mt = {
	__index = Literal;
}

function Literal.new(self, text)
	local obj =  {
		Text = text;
	}
	setmetatable(obj, Literal_mt)

	return obj;
end

function Literal.write(self, strm)
	-- write out the text context
	if self.Text then
		strm:write(self.Text)
	end
end


--[[
	Line

	x1
	y1
	x2
	y2

--]]
local function Line(params)
	return BasicElem('line', params)
end

local function Marker(params)
	return BasicElem('marker', params)
end

--[[
--]]
local Path = {}
setmetatable(Path, {
    __call = function(self, ...)    -- functor
        return self:new(...);
    end,
})

function Path.new(self, params)
    local obj = params or {}
    obj._kind = "path";

    local meta = {
        __index = Path;
        Commands = {};
    }
    setmetatable(obj, meta);

    return obj;
end

function Path.addCommand(self, ins, ...)
    local tbl = getmetatable(self);
    local commands = tbl.Commands;

    -- construct the new instruction
    local res = {}
    table.insert(res,tostring(ins))
    local coords = {...};
    for _, value in ipairs(coords) do
        table.insert(res, string.format("%d",tonumber(value)))
    end

    table.insert(commands, table.concat(res, ' '));
end

function Path.pathToString(self)
    local tbl = getmetatable(self);
    local commands = tbl.Commands;

    return table.concat(commands);
end

-- Path construction commands
-- add a single arc segment
function Path.arcBy(self, rx, ry, rotation, large, sweep, x, y)
    self:addCommand('a', rx, ry, rotation, large, sweep, x, y)
    return self
end

function Path.arcTo(self, rx, ry, rotation, large, sweep, x, y)
    self:addCommand('A', rx, ry, rotation, large, sweep, x, y)
    return self
end

function Path.close(self)
    self:addCommand('z')
    return self;
end

function Path.cubicBezierTo(self, ...)
    self:addCommand('C', ...)
    return self
end

function Path.quadraticBezierTo(self, ...)
    self:addCommand('Q', ...)
    return self
end

function Path.hLineBy(self, x, y)
    self:addCommand('h', x, y)
    return self
end

function Path.hLineTo(self, x, y)
    self:addCommand('H', x, y)
    return self
end

function Path.lineBy(self, x,y)
    self:addCommand('l', x, y)
    return self
end

function Path.lineTo(self, x,y)
    self:addCommand('L', x, y)
    return self
end

function Path.moveBy(self, x, y)
    self:addCommand('m', x,y)
    return self
end
function Path.moveTo(self, x, y)
    self:addCommand('M', x,y)
    return self
end

function Path.vLineBy(self, x, y)
    self:addCommand('v', x, y)
    return self
end
function Path.vLineTo(self, x, y)
    self:addCommand('V', x, y)
    return self
end


function Path.write(self, strm)
	strm:openElement(self._kind);

	local childcount = 0;

	-- write out attributes first
	for name, value in pairs(self) do
		if type(value) == "table" then
			childcount = childcount + 1;
		else
			if name ~= "_kind" then
				strm:writeAttribute(name, tostring(value));
			end
		end
	end

	-- write out instructions attribute if it hasn't
	-- been written as an attribute already
	if not self.d then
		strm:writeAttribute("d", self:pathToString())
	end
	
	if childcount > 0 then
		strm:closeTag();

		-- write out child nodes
		for _, value in pairs(self) do
			if type(value) == "table" then
				value:write(strm);
			end
		end
		
		strm:closeElement(self._kind);
	else
		strm:closeElement();
	end
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
			strm:writeAttribute(name, tostring(value));
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
		strm:writeAttribute("points", pointsValue);
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
			strm:writeAttribute(name, tostring(value));
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
		strm:writeAttribute("points", pointsValue);
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
local function Rect(params)
	return BasicElem('rect', params)
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
			strm:writeAttribute(name, tostring(value));
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
local function Use(params)
	return BasicElem('use', params);
end



--[[
	Interface exposed to outside world
--]]
local exports = {
	svg = SVG;		-- check
	defs = Definitions;	-- check
	g = Group;				-- check
	stroke = Stroke;
	fill = Fill;

	circle = Circle;			-- check
	ellipse = Ellipse;			-- check
	image = Image;
	line = Line;				-- check
	linearGradient = LinearGradient;	-- check
	literal = Literal;			-- check
	marker = Marker;			-- check
	polygon = Polygon;			-- check
	polyLine = PolyLine;		-- check
	radialGradient = RadialGradient;	-- check
	path = Path;				-- check
	rect = Rect;				-- check
	stop = Stop;				-- check
	style = Style;				-- initial
	text = Text;				-- check
	textPath = TextPath;
	tRef = TRef;
	tSpan = TSpan;
	use = Use;					-- check
}
setmetatable(exports, {
	__call = function(self, tbl)
		tbl = tbl or _G;

		for k,v in pairs(exports) do
			tbl[k] = v;
		end

		return self;
	end,
})

return exports
