
-- Attribute names that have the '-' or ':' characters in them
-- https://www.w3.org/TR/SVG/attindex.html
-- we want to allow the user to specify lua friendly names as
-- table indices, without having to quote them.  So, we have
-- this alias table. 

local attrNameAlias = {
	accent_height = "accent-height",
	arabic_form = "arabic-form",

	cap_height = "cap-height",

	fill_opacity = "fill-opacity",

	font_face = "font-face",
	font_face_format = "font-face-format",
	font_face_src = "font-face-src",
	font_face_name = "font-face-name",
	font_family = "font-family",
	font_size = "font-size",
	font_stretch = "font-stretch",
	font_style = "font-style",
	font_variant = "font-variant",
	font_weight = "font-weight",

	glyph_name = "glyph-name",

	horiz_adv_x = "horiz-adv-x",
	horiz_origin_x = "horiz-origin-x",
	horiz_origin_y = "horiz-origin-y",

	overline_position = "overline-position",
	overline_thickness = "overline-thickness",

	panose_1 = "panose-1",

	rendering_intent = "rendering-intent",

	stop_color = "stop-color",
	strikethrough_position = "strikethrough-position",
	strikethrough_thickness = "strikethrough-thickness",
	stroke_linecap = "stroke-linecap",
	stroke_linejoin = "stroke-linejoin",
	stroke_width = "stroke-width",

	underline_position = "underline-position",
	underline_thickness = "underline-thickness",
	unicode_range = "unicode-range",
	units_per_em = "units-per-em",

	v_alphabetic = "v-alphabetic",
	v_hanging = "v-hanging",
	v_ideographic = "v-ideographic",
	v_mathematical = "v-mathematical",
	vert_adv_y = "vert-adv-y",
	vert_origin_x = "vert-origin-x",
	vert_origin_y = "vert-origin-y",

	x_height = "x-height",
	xlink_actuate = "xlink:actuate",
	xlink_arcrole = "xlink:arcrole",
	xlink_href = "xlink:href",
	xlink_role = "xlink:role",
	xlink_show = "xlink:show",
	xlink_title = "xlink:title",
	xlink_type = "xlink:type",
	xml_base = "xml:base",
	xml_lang = "xml:lang",
	xml_space = "xml:space",
}

local SVGAttributes = require("remotesvg.SVGAttributes")

-- Given an attribute name, return the SVG name
-- by looking up in alias table.
local function realAttrName(name)
	return attrNameAlias[name] or name;
end

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
function BasicElem.appendLiteral(self, literal)
	table.insert(self, literal)
	return self;
end

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

function BasicElem.attributes(self)
	local function yieldAttributes(parent)
		for name, value in pairs(parent) do
			if type(name) ~= "number" and name ~= "_kind" then
				coroutine.yield(name, value)
			end
		end
	end

  	return coroutine.wrap(function() yieldAttributes(self) end)	
end

-- go through each attribute parsing it
-- to get a native lua form
function BasicElem.parseAttributes(self, strict)
	local newVals = {}
	--for name, value in pairs(self) do
	for name, value in self:attributes() do
		--print("BasicElem.parseAttributes: ", name, type(name), value)
		local n, val = SVGAttributes.parseAttribute(name, value, strict)
		if n ~= name then
			self[name] = nil;
		end
			
		if n then
			self[n] = val;
		end
	end

	-- tell our children to parse their
	-- attributes
	for idx, value in ipairs(self) do
		if type(value) == "table" then
			value:parseAttributes(strict);
		end
	end
end


--[[
	Traverse the elements in document order, returning
	the ones that match a given predicate.
	If no predicate is supplied, then return all the
	elements.
--]]
function BasicElem.selectElementMatches(self, pred)
	local function yieldMatches(parent, predicate)
		for idx, value in ipairs(parent) do
			if predicate then
				if predicate(value) then
					coroutine.yield(value)
				end
			else
				coroutine.yield(value)
			end

			if type(value) == "table" then
				yieldMatches(value, predicate)
			end
		end
	end

  	return coroutine.wrap(function() yieldMatches(self, pred) end)	
end

-- A convenient shorthand for selecting all the elements
-- in the document.  No predicate is specified.
function BasicElem.selectAll(self)
	return self:selectElementMatches()
end

function BasicElem.getElementById(self, id)
    local function filterById(entry)
        print("filterById: ", entry.id, id)
        if entry.id == id then
            return true;
        end
    end

    for child in self:selectMatches(filterById) do
        return child;
    end
end

function BasicElem.write(self, strm)
	strm:openElement(self._kind);

	local childcount = 0;

	for name, value in pairs(self) do
		--print("\nBasicElem.write (pairs): ", name, value)
		if type(name) == "number" then
			childcount = childcount + 1;
		else
			if name ~= "_kind" then
				name = realAttrName(name);
				strm:writeAttribute(name, tostring(value));
			end
		end
	end

	-- if we have some number of child nodes
	-- then write them out 
	if childcount > 0 then
		-- first close the starting tag
		strm:closeTag();

		-- write out child nodes
		for idx, value in ipairs(self) do
			if type(value) == "table" then
				value:write(strm);
			elseif type(value) == "function" then
			else
				-- write out pure text nodes
				strm:write(tostring(value));
			end
		end
		
		strm:closeElement(self._kind);
	else
		strm:closeElement();
	end
end


--[[
	SVG

	We specialize this one to ensure the xmlns and version
	attributes are there.  

	Without the xmlns attribute, some renderers will fail.
--]]
local function SVG(params)
	local elem = BasicElem('svg', params);
	elem.xmlns = elem.xmlns or "http://www.w3.org/2000/svg"
	elem.version = params.version or "1.1"

	return elem;
end


--[[
	Path

	A specialization so that path construction can happen 'on the fly'.
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

-- Line to relative position
function Path.lineBy(self, x,y)
    self:addCommand('l', x, y)
    return self
end

-- Line to absolute position
function Path.lineTo(self, x,y)
    self:addCommand('L', x, y)
    return self
end

-- Move to position
function Path.moveBy(self, x, y)
    self:addCommand('m', x,y)
    return self
end
function Path.moveTo(self, x, y)
    self:addCommand('M', x,y)
    return self
end

function Path.sqCurveBy(self, ...)
	self:addCommand('t', ...)
	return self;
end

function Path.sqCurveTo(self, ...)
	self:addCommand('T', ...)
	return self;
end

-- Vertical Line
function Path.vLineBy(self, x, y)
    self:addCommand('v', x, y)
    return self
end
function Path.vLineTo(self, x, y)
    self:addCommand('V', x, y)
    return self
end

-- Write out the thing to a stream
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
	Interface exposed to outside world

	Reference of SVG Elements
	https://developer.mozilla.org/en-US/docs/Web/SVG/Element
--]]
local exports = {
	BasicElem = BasicElem;

	-- Animation Elements
	animate = function(params) return BasicElem('animate', params) end;
	animateColor = function(params) return BasicElem('animateColor', params) end;
	animateMotion = function(params) return BasicElem('animateMotion', params) end;
	animateTransform = function(params) return BasicElem('animateTransform', params) end;
	mpath = function(params) return BasicElem('mpath', params) end;
	set = function(params) return BasicElem('set', params) end;

	-- Container elements
	a = function(params) return BasicElem('a', params) end;
	defs = function(params) return BasicElem('defs', params) end;
	glyph = function(params) return BasicElem('glyph', params) end;
	g = function(params) return BasicElem('g', params) end;
	marker = function(params) return BasicElem('marker', params) end;
	mask = function(params) return BasicElem('mask', params) end;
	missing_glyph = function(params) return BasicElem('missing-glyph', params) end;
	pattern = function(params) return BasicElem('pattern', params) end;
	svg = SVG;
	switch = function(params) return BasicElem('switch', params) end;
	symbol = function(params) return BasicElem('symbol', params) end;
	use = function(params) return BasicElem('use', params) end;

	-- Descriptive elements
	desc = function(params) return BasicElem('desc', params) end;
	metadata = function(params) return BasicElem('metadata', params) end;
	title = function(params) return BasicElem('title', params) end;

	-- Filter primitive elements
	feBlend = function(params) return BasicElem('feBlend', params) end;
	feColorMatrix = function(params) return BasicElem('feColorMatrix', params) end;
	feComponentTransfer = function(params) return BasicElem('feComponentTransfer', params) end;
	feComposite = function(params) return BasicElem('feComposite', params) end;
	feConvolveMatrix = function(params) return BasicElem('feConvolveMatrix', params) end;
	feDiffuseLighting = function(params) return BasicElem('feDiffuseLighting', params) end;
	feDisplacementMap = function(params) return BasicElem('feDisplacementMap', params) end;
	feFlood = function(params) return BasicElem('feFlood', params) end;
	feFuncA = function(params) return BasicElem('feFuncA', params) end;
	feFuncB = function(params) return BasicElem('feFuncB', params) end;
	feFuncR = function(params) return BasicElem('feFuncR', params) end;
	feGaussianBlur = function(params) return BasicElem('feGaussianBlur', params) end;
	feImage = function(params) return BasicElem('feImage', params) end;
	feMerge = function(params) return BasicElem('feMerge', params) end;
	feMergeNode = function(params) return BasicElem('feMergeNode', params) end;
	feOffset = function(params) return BasicElem('feOffset', params) end;
	feSpecularLighting = function(params) return BasicElem('feSpecularLighting', params) end;
	feTile = function(params) return BasicElem('feTile', params) end;
	feTurbulance = function(params) return BasicElem('feTurbulance', params) end;

	-- Font elements
	font = function(params) return BasicElem('font', params) end;
	font_face = function(params) return BasicElem('font-face', params) end;
	font_face_format = function(params) return BasicElem('font-face-format', params) end;
	font_face_name = function(params) return BasicElem('font-face-name', params) end;
	font_face_src = function(params) return BasicElem('font-face-src', params) end;
	font_face_uri = function(params) return BasicElem('font-face-uri', params) end;
	hkern = function(params) return BasicElem('hkern', params) end;
	vkern = function(params) return BasicElem('vkern', params) end;

	-- Graphics elements
	circle = function(params) return BasicElem('circle', params) end;
	ellipse = function(params) return BasicElem('ellipse', params) end;
	image = function(params) return BasicElem('image', params) end;
	line = function(params) return BasicElem('line', params) end;
	path = Path;				-- check
	polygon = Polygon;			-- check
	polyline = PolyLine;		-- check
	rect = function(params) return BasicElem('rect', params) end;

	-- Gradient Elements
	linearGradient = function(params) return BasicElem('linearGradient', params) end;
	radialGradient = function(params) return BasicElem('radialGradient', params) end;
	stop = function(params) return BasicElem('stop', params) end;

	-- Light Source elements
	feDistantLight = function(params) return BasicElem('feDistantLight', params) end;
	fePointLight = function(params) return BasicElem('fePointLight', params) end;
	feSpotLight = function(params) return BasicElem('feSpotLight', params) end;

	-- Text Content elements
	altGlyph = function(params) return BasicElem('altGlyph', params) end;
	altGlyphDef = function(params) return BasicElem('altGlyphDef', params) end;
	altGlyphItem = function(params) return BasicElem('altGlyphItem', params) end;
	glyph = function(params) return BasicElem('glyph', params) end;
	glyphRef = function(params) return BasicElem('glyphRef', params) end;
	text = function(params) return BasicElem('text', params) end;
	textPath = function(params) return BasicElem('textPath', params) end;
	tref = function(params) return BasicElem('tref', params) end;
	tspan = function(params) return BasicElem('tspan', params) end;

	-- Uncategorized elements
	clipPath = function(params) return BasicElem('clipPath', params) end;
	color_profile = function(params) return BasicElem('color-profile', params) end;
	cursor = function(params) return BasicElem('cursor', params) end;
	filter = function(params) return BasicElem('filter', params) end;
	foreignObject = function(params) return BasicElem('foreignObject', params) end;
	script = function(params) return BasicElem('script', params) end;
	style = function(params) return BasicElem('style', params) end;
	view = function(params) return BasicElem('view', params) end;

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
