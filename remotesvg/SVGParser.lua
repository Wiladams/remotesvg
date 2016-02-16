--[[
	A simple SVG Parser which fills in a lua based object model
	for the image specified.
--]]

local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift, band, bor = bit.lshift, bit.rshift, bit.band, bit.bor

local XmlParser = require("remotesvg.SVGXmlParser")
local isspace = ctypes.isspace;
local isdigit = ctypes.isdigit;

local maths = require("remotesvg.maths")
local clamp = maths.clamp;
local sqr = maths.sqr;
local vecrat = maths.vecrat;
local vecang = maths.vecang;
local vmag = maths.vmag;


--local SVGPath = require("ljgraph2D.SVGPath")
--local SVGShape = require("ljgraph2D.SVGShape")
--local SVGImage = require("ljgraph2D.SVGImage")

local sqrt = math.sqrt;
local fabs = math.abs;
local abs = math.abs;
local sin = math.sin;
local cos = math.cos;

local RGB = colors.RGBA;

local svg = require("remotesvg.SVGElements")
--[[
local PaintType = SVGTypes.PaintType;
local FillRule = SVGTypes.FillRule;
local Flags = SVGTypes.Flags;
local LineCap = SVGTypes.LineCap;
local LineJoin = SVGTypes.LineJoin;
local SVGGradientStop = SVGTypes.SVGGradientStop;
local SVGGradient = SVGTypes.SVGGradient;
local SVGPaint = SVGTypes.SVGPaint;
--]]


local SVG_PI = math.pi;	-- (3.14159265358979323846264338327f)
local SVG_KAPPA90 = 0.5522847493	-- Length proportional to radius of a cubic bezier handle for 90-deg arcs.
local SVG_EPSILON = 1e-12;

local SVG_ALIGN_MIN = 0;
local SVG_ALIGN_MID = 1;
local SVG_ALIGN_MAX = 2;
local SVG_ALIGN_NONE = 0;
local SVG_ALIGN_MEET = 1;
local SVG_ALIGN_SLICE = 2;



local minf = math.min;
local maxf = math.max;

-- Simple SVG parser.
local SVG_MAX_ATTR = 128;

local SVGgradientUnits = {
	NSVG_USER_SPACE = 0;
	NSVG_OBJECT_SPACE = 1;
};


local SVGUnits = {
	USER = 0,
	PX = 1,
	PT = 2,
	PC = 3,
	MM = 4,
	CM = 5,
	IN = 6,
	PERCENT = 7,
	EM = 8,
	EX = 9,
};


ffi.cdef[[
typedef struct pt2D
{
	union {
		struct {
			double x, y;
		};
		double v[2];
	};
} pt2D_t;
]]



local pt2D = ffi.typeof("struct pt2D");

ffi.cdef[[
typedef struct SVGCoordinate {
	float value;
	int units;
} SVGCoordinate_t;
]]
local SVGCoordinate = ffi.typeof("struct SVGCoordinate");

ffi.cdef[[
typedef struct SVGLinearData {
	struct SVGCoordinate x1, y1, x2, y2;
} SVGLinearData_t;
]]
local SVGLinearData = ffi.typeof("struct SVGLinearData")


ffi.cdef[[
typedef struct SVGRadialData {
	struct SVGCoordinate cx, cy, r, fx, fy;
} SVGRadialData_t;
]]
local SVGRadialData = ffi.typeof("struct SVGRadialData")


ffi.cdef[[
typedef struct SVGGradientData
{
	char id[64];
	char ref[64];
	char type;
	union {
		struct SVGLinearData linear;
		struct SVGRadialData radial;
	};
	char spread;
	char units;
	double xform[6];
	int nstops;
	struct SVGGradientStop* stops;
	struct SVGGradientData* next;
} SVGGradientData_t;
]]
local SVGGradientData = ffi.typeof("struct SVGGradientData")

ffi.cdef[[
static const int SVG_MAX_DASHES = 8;

typedef struct SVGAttrib
{
	char id[64];
	double xform[6];
	uint32_t fillColor;
	uint32_t strokeColor;
	float opacity;
	float fillOpacity;
	float strokeOpacity;
	char fillGradient[64];
	char strokeGradient[64];
	float strokeWidth;
	float strokeDashOffset;
	float strokeDashArray[SVG_MAX_DASHES];
	int strokeDashCount;
	char strokeLineJoin;
	char strokeLineCap;
	char fillRule;
	float fontSize;
	unsigned int stopColor;
	float stopOpacity;
	float stopOffset;
	char hasFill;
	char hasStroke;
	char visible;
} SVGattrib_t;
]]
local SVGAttrib = ffi.typeof("struct SVGAttrib")


local function AttributeStack()
	local obj = {}
	setmetatable(obj, {
		__index = obj;
	})
	
	function obj.push(self, value)
		if not value then
			value = SVGAttrib();
			-- clone whatever is on the top of the stack
			-- right now
			local topper = self:top()
			if topper then
				ffi.copy(value, topper, ffi.sizeof(SVGAttrib))
			end
		end

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


local function strncpy(dst, value, limit)
	local s = ffi.cast("const char *", value)
	for i=0,limit-1 do
		if value[i] == 0 then
			break;
		end

		dst[i] = s[i];
	end

	return dst;
end

local function strncmp(str1, str2, num)
	local ptr1 = ffi.cast("const char*", str1)
	local ptr2 = ffi.cast("const char*", str2)

	for i=0,num-1 do
		if ptr1[i] == 0 or ptr2[i] == 0 then return 0 end

		if ptr1[i] > ptr2[i] then return 1 end
		if ptr1[i] < ptr2[i] then return -1 end
	end

	return 0
end

--[[
	bounds[0] == left
	bounds[1] == top
	bounds[2] == right
	bounds[3] == bottom
--]]
local function ptInBounds(pt, bounds)
	return pt.x >= bounds[0] and 
		pt.x <= bounds[2] and 
		pt.y >= bounds[1] and
		pt.y <= bounds[3];
end


local function curveBoundary(bounds, curve, idx)
print("curveBoundary: ", #curve, idx)
	local i, j, count = 0,0,0;
	local roots = ffi.new("double[2]");
	local a, b, c, b2ac, t, v = 0,0,0,0,0,0;


	local v0 = curve[idx];
	local v1 = curve[idx+1];
	local v2 = curve[idx+2];
	local v3 = curve[idx+3];

	-- Start the bounding box by end points
	bounds[0] = minf(v0.x, v3.x);
	bounds[1] = minf(v0.y, v3.y);
	bounds[2] = maxf(v0.x, v3.x);
	bounds[3] = maxf(v0.y, v3.y);


	-- Bezier curve fits inside the convex hull of it's control points.
	-- If control points are inside the bounds, we're done.
	if (ptInBounds(v1, bounds) and ptInBounds(v2, bounds)) then
		return;
	end

	-- Add bezier curve inflection points in X and Y.

	for i = 0, 1 do
		a = -3.0 * v0.v[i] + 9.0 * v1.v[i] - 9.0 * v2.v[i] + 3.0 * v3.v[i];
		b = 6.0 * v0.v[i] - 12.0 * v1.v[i] + 6.0 * v2.v[i];
		c = 3.0 * v1.v[i] - 3.0 * v0.v[i];

		local count = 0;
		if (abs(a) < SVG_EPSILON) then
			if (abs(b) > SVG_EPSILON) then
				t = -c / b;
				if (t > SVG_EPSILON and t < 1.0-SVG_EPSILON) then
					roots[count] = t;
					count = count + 1;
				end
			end
		else
			b2ac = b*b - 4.0*c*a;
			if (b2ac > SVG_EPSILON) then
				t = (-b + sqrt(b2ac)) / (2.0 * a);
				if (t > SVG_EPSILON and t < 1.0-SVG_EPSILON) then
					roots[count] = t;
					count = count + 1;
				end

				t = (-b - sqrt(b2ac)) / (2.0 * a);
				if (t > SVG_EPSILON and t < 1.0-SVG_EPSILON) then
					roots[count] = t;
					count = count + 1;
				end
			end
		end
--[[
		for (j = 0; j < count; j++) {
			v = Bezier.evalBezier(roots[j], v0[i], v1[i], v2[i], v3[i]);
			bounds[0+i] = minf(bounds[0+i], v);
			bounds[2+i] = maxf(bounds[2+i], v);
		}
--]]
	end

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
		attr = AttributeStack();
		pts = {};
		plist = {};
		image = SVGImage();
		gradients = {};
		
		viewMinx = 0;
		viewMiny = 0;
		viewWidth = 0;
		viewHeight = 0;

		-- alignment
		alignX = 0;
		alignY = 0;
		alignType = 0;

		dpi = 96;

		pathFlag = false;
		defsFlag = false;
	}
	
	setmetatable(obj, SVGParser_mt);




	-- Initialize style with first attribute
	local attrib = SVGAttrib();
	transform2D.xformIdentity(attrib.xform);
	attrib.fillColor = RGB(0,0,0);
	attrib.strokeColor = RGB(0,0,0);
	attrib.opacity = 1;
	attrib.fillOpacity = 1;
	attrib.strokeOpacity = 1;
	attrib.stopOpacity = 1;
	attrib.strokeWidth = 1;
	attrib.strokeLineJoin = LineJoin.MITER;
	attrib.strokeLineCap = LineCap.BUTT;
	attrib.fillRule = FillRule.NONZERO;
	attrib.hasFill = 1;
	attrib.visible = 1;
	obj.attr:push(attrib);
	
	return obj;
end

function SVGParser.new(self)
	local parser = self:init()

	return parser;
end

function SVGParser.parse(self, input, units, dpi)
	self.dpi = dpi;

	--self:parseXML(input, SVGParser.startElement, SVGParser.endElement, SVGParser.content, self);
	XmlParser.parseXML(input, SVGParser.startElement, SVGParser.endElement, SVGParser.content, self)

	-- Scale to viewBox
	self:scaleToViewbox(units);

	local ret = self.image;
	self.image = NULL;

	return ret;
end

function SVGParser.parseFromFile(self, filename, units, dpi)
	local fp = io.open(filename, "rb")
	if not fp then 
		return 
	end

	local data = fp:read("*a");
	fp:close();

	local parser = SVGParser();
	local image = parser:parse(data, units, dpi)

	return image;
end



function SVGParser.resetPath(self)
	self.pts = {};
end

function SVGParser.addPoint(self, x, y)
	--print("addPoint: ", x, type(x), y, type(y))
	table.insert(self.pts, pt2D({tonumber(x),tonumber(y)}));
end

function SVGParser.moveTo(self, x, y)
	self:addPoint(x, y);
end

-- Add a line segment.  The must be at least
-- one starting point already
function SVGParser.lineTo(self, x, y)
	if #self.pts > 0 then
		local lastpt = self.pts[#self.pts];
		local px = lastpt.x;
		local py = lastpt.y;
		dx = x - px;
		dy = y - py;
		self:addPoint(px + dx/3.0, py + dy/3.0);
		self:addPoint(x - dx/3.0, y - dy/3.0);
		self:addPoint(x, y);
	end
end

function SVGParser.cubicBezTo(self, cpx1, cpy1, cpx2, cpy2, x, y)
	self:addPoint(cpx1, cpy1);
	self:addPoint(cpx2, cpy2);
	self:addPoint(x, y);
end

function SVGParser.getAttr(self)
	return self.attr:top();
end

function SVGParser.pushAttr(self)
	-- take the attribute currently on top 
	-- make a copy
	-- and push that copy on top of the stack
	self.attr:push();
end

function SVGParser.popAttr(self)
	return self.attr:pop();
end

function SVGParser.actualOrigX(self)
	return self.viewMinx;
end

function SVGParser.actualOrigY(self)
	return self.viewMiny;
end

function SVGParser.actualWidth(self)
	return self.viewWidth;
end

function SVGParser.actualHeight(self)
	return self.viewHeight;
end

function SVGParser.actualLength(self)
	local w = self:actualWidth();
	local h = self:actualHeight();

	return sqrt(w*w + h*h) / sqrt(2.0);
end


function SVGParser.convertToPixels(self, c, orig, length)
	--print("convertToPixels: ", self, c, orig, length)
	local attr = self:getAttr();
	
	if c.units == SVGUnits.USER then		
		return c.value;
	elseif c.units == SVGUnits.PX then			return c.value;
	elseif c.units == SVGUnits.PT then			return c.value / 72.0 * self.dpi;
	elseif c.units == SVGUnits.PC then			return c.value / 6.0 * self.dpi; 
	elseif c.units == SVGUnits.MM then			return c.value / 25.4 * self.dpi;
	elseif c.units == SVGUnits.CM then			return c.value / 2.54 * self.dpi;
	elseif c.units == SVGUnits.IN then			return c.value * self.dpi;
	elseif c.units == SVGUnits.EM then			return c.value * attr.fontSize;
	elseif c.units == SVGUnits.EX then			return c.value * attr.fontSize * 0.52; -- x-height of Helvetica.
	elseif c.units == SVGUnits.PERCENT then	
		return orig + c.value / 100.0 * length; 
	end

	return c.value;
end


function SVGParser.findGradientData(self, id)
	return self.gradients[id];
--[[	
	NSVGgradientData* grad = self.gradients;
	while (grad) {
		if (strcmp(grad.id, id) == 0)
			return grad;
		grad = grad.next;
	}
	return NULL;
--]]
end


function SVGParser.createGradient(self, id, localBounds, paintType)

	local attr = self:getAttr();
	--NSVGgradientData* data = NULL;
	--NSVGgradientData* ref = NULL;
	--NSVGgradientStop* stops = NULL;
	--NSVGgradient* grad;
	local ox, oy, sw, sh, sl= 0,0,0,0,0;
	local nstops = 0;

	local data = self:findGradientData(id);
	if data == nil then
		return nil;
	end

--[[
	-- TODO: use ref to fill in all unset values too.
	local ref = data;
	while (ref ~= NULL) do
		if (stops == NULL and ref.stops != NULL) {
			stops = ref.stops;
			nstops = ref.nstops;
			break;
		}
		ref = self:findGradientData(p, ref.ref);
	end

	if (stops == NULL) then
		return NULL;
	end

	--grad = (NSVGgradient*)malloc(sizeof(NSVGgradient) + sizeof(NSVGgradientStop)*(nstops-1));
	local grad = SVGGradient();

	--if (grad == NULL) return NULL;

	-- The shape width and height.
	if (data.units == NSVG_OBJECT_SPACE) {
		ox = localBounds[0];
		oy = localBounds[1];
		sw = localBounds[2] - localBounds[0];
		sh = localBounds[3] - localBounds[1];
	else
		ox = self:actualOrigX(p);
		oy = self:actualOrigY(p);
		sw = self:actualWidth(p);
		sh = self:actualHeight(p);
	}
	sl = sqrtf(sw*sw + sh*sh) / sqrt(2.0);

	if (data.type == SVGTypes.PaintType.LINEAR_GRADIENT) then
		--float x1, y1, x2, y2, dx, dy;
		local x1 = self:convertToPixels(data.linear.x1, ox, sw);
		local y1 = self:convertToPixels(data.linear.y1, oy, sh);
		local x2 = self:convertToPixels(data.linear.x2, ox, sw);
		local y2 = self:convertToPixels(data.linear.y2, oy, sh);
		-- Calculate transform aligned to the line
		local dx = x2 - x1;
		local dy = y2 - y1;
		grad.xform[0] = dy; grad.xform[1] = -dx;
		grad.xform[2] = dx; grad.xform[3] = dy;
		grad.xform[4] = x1; grad.xform[5] = y1;
	else
		--float cx, cy, fx, fy, r;
		local cx = self:convertToPixels(p, data.radial.cx, ox, sw);
		local cy = self:convertToPixels(p, data.radial.cy, oy, sh);
		local fx = self:convertToPixels(p, data.radial.fx, ox, sw);
		local fy = self:convertToPixels(p, data.radial.fy, oy, sh);
		local r = self:convertToPixels(p, data.radial.r, 0, sl);
		-- Calculate transform aligned to the circle
		grad.xform[0] = r; grad.xform[1] = 0;
		grad.xform[2] = 0; grad.xform[3] = r;
		grad.xform[4] = cx; grad.xform[5] = cy;
		grad.fx = fx / r;
		grad.fy = fy / r;
	end

	xform.xformMultiply(grad.xform, data.xform);
	xform.xformMultiply(grad.xform, attr.xform);

	grad.spread = data.spread;
	ffi.copy(grad.stops, stops, nstops*sizeof(NSVGgradientStop));
	grad.nstops = nstops;


	return grad, data.type;
--]]
end


function SVGParser.getAverageScale(self, t)

	local sx = sqrt(t[0]*t[0] + t[2]*t[2]);
	local sy = sqrt(t[1]*t[1] + t[3]*t[3]);
	
	return (sx + sy) * 0.5;
end

--[[
function NSVGParser.getLocalBounds(float* bounds, NSVGshape *shape, float* xform)

	NSVGpath* path;
	float curve[4*2], curveBounds[4];
	int i, 
	local first = true;

	for (path = shape.paths; path != NULL; path = path.next) do
		curve[0], curve[1] = xform.xformPoint(path.pts[0], path.pts[1], xform);
		for (i = 0; i < path.npts-1; i += 3) {
			curve[2], curve[3] = xform.xformPoint(path.pts[(i+1)*2], path.pts[(i+1)*2+1], xform);
			curve[4], curve[5] = xform.xformPoint(path.pts[(i+2)*2], path.pts[(i+2)*2+1], xform);
			curve[6], curve[7] = xform.xformPoint(path.pts[(i+3)*2], path.pts[(i+3)*2+1], xform);
			curveBoundary(curveBounds, curve);
			if (first) then
				bounds[0] = curveBounds[0];
				bounds[1] = curveBounds[1];
				bounds[2] = curveBounds[2];
				bounds[3] = curveBounds[3];
				first = false;
			else 
				bounds[0] = self:minf(bounds[0], curveBounds[0]);
				bounds[1] = self:minf(bounds[1], curveBounds[1]);
				bounds[2] = self:maxf(bounds[2], curveBounds[2]);
				bounds[3] = self:maxf(bounds[3], curveBounds[3]);
			end
			curve[0] = curve[6];
			curve[1] = curve[7];
		}
	end
end
--]]


function SVGParser.addShape(self)

	local attr = self:getAttr();
	local scale = 1.0;


	if (self.plist == NULL) then
		return;
	end

	local shape = SVGShape();

	shape.id = ffi.string(attr.id);
--print("addShape(), shape.id: ", shape.id)

	scale = self:getAverageScale(attr.xform);
	shape.strokeWidth = attr.strokeWidth * scale;
	shape.strokeDashOffset = attr.strokeDashOffset * scale;
	shape.strokeDashCount = attr.strokeDashCount;

	
	for i = 0, attr.strokeDashCount-1 do
		shape.strokeDashArray[i] = attr.strokeDashArray[i] * scale;
	end

	shape.strokeLineJoin = attr.strokeLineJoin;
	shape.strokeLineCap = attr.strokeLineCap;
	shape.fillRule = attr.fillRule;
	shape.opacity = attr.opacity;

	shape.paths = self.plist;
	self.plist = {};

	-- Calculate shape bounds
	for idx, path in ipairs(shape.paths) do 
		shape.bounds[0] = minf(shape.bounds[0], path.bounds[0]);
		shape.bounds[1] = minf(shape.bounds[1], path.bounds[1]);
		shape.bounds[2] = maxf(shape.bounds[2], path.bounds[2]);
		shape.bounds[3] = maxf(shape.bounds[3], path.bounds[3]);
	end


	-- Set fill
	if (attr.hasFill == 0) then
		shape.fill.type = PaintType.NONE;
	elseif (attr.hasFill == 1) then
		shape.fill.type = PaintType.COLOR;
		shape.fill.color = attr.fillColor;
		shape.fill.color = bor(shape.fill.color, lshift((attr.fillOpacity*255), 24));
	elseif attr.hasFill == 2 then
		local inv = ffi.new("double[6]");
		local localBounds ffi.new("double[4]");
		transform2D.xformInverse(inv, attr.xform);
		self:getLocalBounds(localBounds, shape, inv);
		shape.fill.gradient, shape.fill.type = self:createGradient(attr.fillGradient, localBounds);
		if (shape.fill.gradient == nil) then
			shape.fill.type = PaintType.NONE;
		end
	end



	-- Set stroke
	if (attr.hasStroke == 0) then
		shape.stroke.type = PaintType.NONE;
	elseif (attr.hasStroke == 1) then
		shape.stroke.type = PaintType.COLOR;
		shape.stroke.color = attr.strokeColor;
		shape.stroke.color = bor(shape.stroke.color, lshift((attr.strokeOpacity*255), 24));
	elseif (attr.hasStroke == 2) then
		local inv = ffi.new("double[6]")
		local localBounds = ffi.new("double[4]");

		transform2D.xformInverse(inv, attr.xform);
		self:getLocalBounds(localBounds, shape, inv);
		shape.stroke.gradient, shape.stroke.type = self:createGradient(attr.strokeGradient, localBounds);
		if (shape.stroke.gradient == NULL) then
			shape.stroke.type = PaintType.NONE;
		end
	end


	-- Set flags
	if attr.visible ~= 0 then
		shape.flags = Flags.VISIBLE
	else
		shape.flags = 0;
	end

	-- Add to tail
	table.insert(self.image.shapes, shape);

	return;
end



function SVGParser.addPath(self, closed)
	local attr = self:getAttr();
	local  bounds = ffi.new("double[4]");
	--float* curve;
	--int i;

--print("addPath: ", #self.pts)

	if (#self.pts < 4) then
		return;
	end

	local path = SVGPath();

	path.closed = closed;

	-- Transform path.
	for i, pt in ipairs(self.pts) do
		pt.x, pt.y = transform2D.xformPoint(pt.x, pt.y, attr.xform);
		table.insert(path.pts, pt);
	end

	-- Find bounds
	for i = 1, #path.pts-1, 3 do
		--curve = &path.pts[i*2];
		curveBoundary(bounds, path.pts, i);
		if (i == 1) then
			path.bounds[0] = bounds[0];
			path.bounds[1] = bounds[1];
			path.bounds[2] = bounds[2];
			path.bounds[3] = bounds[3];
		else
			path.bounds[0] = minf(path.bounds[0], bounds[0]);
			path.bounds[1] = minf(path.bounds[1], bounds[1]);
			path.bounds[2] = maxf(path.bounds[2], bounds[2]);
			path.bounds[3] = maxf(path.bounds[3], bounds[3]);
		end
	end

	--path:dump();
	table.insert(self.plist, path);

	return;
end


-- parse a numeric value out of a string pointer
-- stuff it into the 'it' buffer, which is of size 'size'
-- and return the pointer one character past the last 
-- digit parsed.
function SVGParser.parseNumber(self, s, it, size)
	--print(".parseNumber: ", ffi.string(s), size)

	local last = size-1;
	local i = 0;

	-- sign
	if (s[0] == string.byte('-') or s[0] == string.byte('+')) then
		if i < last then
			it[i] = s[0];
			i = i + 1;
		end

		s = s + 1;
	end

	-- integer part
	while s[0]~= 0 and isdigit(s[0]) do
		if (i < last) then
			it[i] = s[0];
			i = i + 1;
		end

		s = s + 1;
	end

	if s[0] == string.byte('.') then
		-- decimal point
		if (i < last) then
			it[i] = s[0];
			i = i + 1;
		end

		s = s + 1;

		-- fraction part
		while s[0] ~= 0 and isdigit(s[0]) do
			if (i < last) then
				it[i] = s[0];
				i = i + 1;
			end
			s = s + 1;
		end
	end

	-- exponent
	if (s[0] == string.byte('e') or s[0] == string.byte('E')) then
		if (i < last) then
			it[i] = s[0];
			i = i + 1;
		end
		s = s + 1;

		if s[0] == string.byte('-') or s[0] == string.byte('+') then
			if (i < last) then
				it[i] = s[0];
				i = i + 1;
			end
			s = s + 1;
		end

		while s[0] and isdigit(s[0]) do
			if (i < last) then
				it[i] = s[0];
				i = i + 1;
			end
			s = s + 1;
		end
	end

	it[i] = 0;
--print(".parseNumber - END: ", ffi.string(it))

	return s, tonumber(ffi.string(it));
end


--[[
static const char* self:getNextPathItem(self, const char* s, char* it)

	it[0] = '\0';
	-- Skip white spaces and commas
	while (*s && (self:isspace(*s) || *s == ',')) s++;
	if (!*s) return s;
	if (*s == '-' || *s == '+' || *s == '.' || self:isdigit(*s)) {
		s = self:parseNumber(s, it, 64);
	} else {
		// Parse command
		it[0] = *s++;
		it[1] = '\0';
		return s;
	}

	return s;
end
--]]


function SVGParser.parseColorHex(self, s)
--print(".parseColorHex: ", s)

	local rgb = s:match("#(%g+)")
--print("rgb: ", rgb)
	local r,g,b = 0,0,0;
	local c = 0;
	rgb = "0x"..rgb;

	if #rgb == 6 then
		c = tonumber(rgb)
	elseif #rgb == 3 then
		c = tonumber(rgb);
		c = bor(band(c,0xf), lshift(band(c,0xf0), 4), lshift(band(c,0xf00), 8));
		c = bor(c, lshift(c,4));
	end
	b = band(rshift(c, 16), 0xff);
	g = band(rshift(c, 8), 0xff);
	r = band(c, 0xff);

	return RGB(r,g,b);
end



function SVGParser.parseColorRGB(self, str)
	local percentvaluepatt = "(%d+%%),(%d+%%),(%d+%%)"
	local valuepatt = "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"

	local r,g,b = str:match(valuepatt)
	r,g,b = tonumber(r), tonumber(g), tonumber(b)

--print("parseColorRGB: ", str, r, g, b)

--[[	
	char s1[32]="", s2[32]="";
	sscanf(str + 4, "%d%[%%, \t]%d%[%%, \t]%d", &r, s1, &g, s2, &b);
	if (strchr(s1, '%')) {
		return RGB((r*255)/100,(g*255)/100,(b*255)/100);
	else 
		return RGB(r,g,b);
	end
--]]

	return RGB(r,g,b)
end


function SVGParser.parseColorName(self, name)
	return colors.svg[name] or RGB(128, 128, 128);
end


function SVGParser.parseColor(self, s)
	local str = s:match("%s*(.*)")
	local len = #str;
	
--	print("SVGParser.parseColor: ", str, len)

	if len >= 1 and str:sub(1,1) == '#' then
		return self:parseColorHex(str);
	elseif (len >= 4 and str:match("rgb%(")) then
		return self:parseColorRGB(str);
	end

	return self:parseColorName(str);
end



function SVGParser.parseOpacity(self, str)
	local val = clamp(tonumber(str), 0, 1);

	return val;
end


function SVGParser.parseUnits(self, units)
--print(".parseUnits: ", units)

	local unitConverter = {
		px = SVGUnits.PX;
		pt = SVGUnits.PT;
		pc = SVGUnits.PC;
		mm = SVGUnits.MM;
		cm = SVGUnits.CM;
		["in"] = SVGUnits.IN;
		["%"] = SVGUnits.PERCENT;
		em = SVGUnits.EM;
		ex = SVGUnits.EX;
	}

	return unitConverter[units] or SVGUnits.USER;
end

function  SVGParser.parseCoordinateRaw(self, str)
	local coord = SVGCoordinate({0, SVGUnits.USER});
--print(".parseCoordinateRaw: ", str)

	--sscanf(str, "%f%s", &coord.value, units);
	local num, units = str:match("(%d*%.?%d*)(.*)")

	coord.value = tonumber(num);
	coord.units = self:parseUnits(units);
	
	return coord;
end

function SVGParser.coord(self, v, units)
	return SVGCoordinate({v, units});
end


function SVGParser.parseCoordinate(self, str, orig, length)
	--print(".parseCoordinate: ", str, orig, length)
	local coord = self:parseCoordinateRaw(str);
	return self:convertToPixels(coord, orig, length);
end


function SVGParser.parseTransformArgs(self, str, args, maxNa, na)

	local it = ffi.new("char [64]");

	na = 0;
	
	-- advance past the opening '('
	local ptr = str;
	while (ptr[0] ~= 0 and ptr[0] ~= string.byte('(')) do
		ptr = ptr + 1;
	end


	if ptr[0] == 0 then
		return 1, na;
	end

	-- find the right ')'
	local ending = ptr;
	while ending[0]~=0 and ending[0] ~= string.byte(')') do
		ending = ending + 1;
	end

	if ending[0] == 0 then
		return 1, na;
	end

	while (ptr < ending) do
		if (ptr[0] == string.byte('-') or 
			ptr[0] == string.byte('+') or 
			ptr[0] == string.byte('.') or 
			isdigit(ptr[0])) then

			if na >= maxNa then
				return 0;
			end

			ptr, num = self:parseNumber(ptr, it, 64);
--print('.printTransformArgs: ', na, num)
			args[na] = num;

			--print("IT: ", ffi.string(it));

			na = na + 1;
		else
			ptr = ptr + 1;
		end
	end

	return ending - str, na;
end



function SVGParser.parseMatrix(self, xform, str)
	print(".parseMatrix: ", ffi.string(str))

	local  t = ffi.new("double[6]");
	local na = 0;
	local len, na = self:parseTransformArgs(str, t, 6, na);
	print(".parseMatrix, len, na: ", len, na)

	if (na ~= 6) then
		return len;
	end

	ffi.copy(xform, t, ffi.sizeof("double")*6);

	for i=0,5 do
		print(xform[i])
	end

	print(".parseMatrix - END")

	return len;
end

--[[
static int self:parseTranslate(float* xform, const char* str)
{
	float args[2];
	float t[6];
	int na = 0;
	int len = self:parseTransformArgs(str, args, 2, &na);
	if (na == 1) args[1] = 0.0;

	xform.xformSetTranslation(t, args[0], args[1]);
	memcpy(xform, t, sizeof(float)*6);
	return len;
}

static int self:parseScale(float* xform, const char* str)
{
	float args[2];
	int na = 0;
	float t[6];
	int len = self:parseTransformArgs(str, args, 2, &na);
	if (na == 1) args[1] = args[0];
	xform.xformSetScale(t, args[0], args[1]);
	memcpy(xform, t, sizeof(float)*6);
	return len;
}

static int self:parseSkewX(float* xform, const char* str)
{
	float args[1];
	int na = 0;
	float t[6];
	int len = self:parseTransformArgs(str, args, 1, &na);
	xform.xformSetSkewX(t, args[0]/180.0f*NSVG_PI);
	memcpy(xform, t, sizeof(float)*6);
	return len;
}

static int self:parseSkewY(float* xform, const char* str)
{
	float args[1];
	int na = 0;
	float t[6];
	int len = self:parseTransformArgs(str, args, 1, &na);
	xform.xformSetSkewY(t, args[0]/180.0f*NSVG_PI);
	memcpy(xform, t, sizeof(float)*6);
	return len;
}

static int self:parseRotate(float* xform, const char* str)
{
	float args[3];
	int na = 0;
	float m[6];
	float t[6];
	int len = self:parseTransformArgs(str, args, 3, &na);
	if (na == 1)
		args[1] = args[2] = 0.0f;
	xform.xformIdentity(m);

	if (na > 1) {
		xform.xformSetTranslation(t, -args[1], -args[2]);
		xform.xformMultiply(m, t);
	}

	xform.xformSetRotation(t, args[0]/180.0f*NSVG_PI);
	xform.xformMultiply(m, t);

	if (na > 1) {
		xform.xformSetTranslation(t, args[1], args[2]);
		xform.xformMultiply(m, t);
	}

	memcpy(xform, m, sizeof(float)*6);

	return len;
}
--]]

function SVGParser.parseTransform(self, xform, s)
	--print(".parseTransform: ", s);

	local str = ffi.cast("const char *", s)
	local t=ffi.new("double[6]");
	transform2D.xformIdentity(xform);
	
	while (str[0] ~= 0) do
		local cont = false;

		if strncmp(str, "matrix", 6) == 0 then
			str = str + self:parseMatrix(t, str);
		elseif strncmp(str, "translate", 9) == 0 then
			str = str + self:parseTranslate(t, str);
		elseif strncmp(str, "scale", 5) == 0 then
			str = str + self:parseScale(t, str);
		elseif strncmp(str, "rotate", 6) == 0 then
			str = str + self:parseRotate(t, str);
		elseif strncmp(str, "skewX", 5) == 0 then
			str = str + self:parseSkewX(t, str);
		elseif strncmp(str, "skewY", 5) == 0 then
			str = str + self:parseSkewY(t, str);
		else
			str = str + 1;
			cont = true;
		end

		if not cont then
			transform2D.xformPremultiply(xform, t);
		end
	end
end


function SVGParser.parseUrl(self, id, str)
print("parseUrl - BEGIN: ", id, str)
--[[
	int i = 0;
	str += 4; -- "url(";
	if (*str == '#')
		str++;
	while (i < 63 && *str != ')') {
		id[i] = *str++;
		i++;
	}
	id[i] = '\0';
--]]
	return id;
end

function SVGParser.parseLineCap(self, str)
	print(".parseLineCap: ", str)
	--return LineCap[str:upper()] or LineCap.BUTT;
	
	if str == "butt" then
		return LineCap.BUTT;
	elseif str == "round" then
		return LineCap.ROUND;
	elseif str == "square" then
		return LineCap.SQUARE;
	end

	-- TODO: handle inherit.
	return LineCap.BUTT;
end

function SVGParser.parseLineJoin(self, str)
	if str == "miter" then
		return LineJoin.MITER;
	elseif str == "round" then
		return LineJoin.ROUND;
	elseif str == "bevel" then
		return LineJoin.BEVEL;
	end
	
	-- TODO: handle inherit.
	return LineCap.BUTT;
end

	local FillRuleConversion = {
		nonzero = FillRule.NONZERO;
		evenodd = FillRule.EVENODD;
	}

function SVGParser.parseFillRule(self, str)
	return FillRuleConversion[str] or FillRule.NONZERO;
end


--[[
static const char* self:getNextDashItem(const char* s, char* it)
{
	int n = 0;
	it[0] = '\0';
	// Skip white spaces and commas
	while (*s && (self:isspace(*s) || *s == ',')) s++;
	// Advance until whitespace, comma or end.
	while (*s && (!self:isspace(*s) && *s != ',')) {
		if (n < 63)
			it[n++] = *s;
		s++;
	}
	it[n++] = '\0';
	return s;
}
--]]

--[[
static int self:parseStrokeDashArray(self, const char* str, float* strokeDashArray)
{
	char item[64];
	int count = 0, i;
	float sum = 0.0f;

	// Handle "none"
	if (str[0] == 'n')
		return 0;

	// Parse dashes
	while (*str) {
		str = self:getNextDashItem(str, item);
		if (!*item) break;
		if (count < NSVG_MAX_DASHES)
			strokeDashArray[count++] = fabsf(self:parseCoordinate(p, item, 0.0f, self:actualLength(p)));
	}

	for (i = 0; i < count; i++)
		sum += strokeDashArray[i];
	if (sum <= 1e-6f)
		count = 0;

	return count;
}
--]]


function SVGParser.parseAttr(self, name, value)
	--print("parseAttr: ", name, value);

	local xform = ffi.new("double[6]");
	local attr = self:getAttr(p);
	
	assert(attr ~= nil)

	if name == "style" then
		self:parseStyle(value);
	elseif name == "display" then
		if value == "none" then
			attr.visible = 0;
			-- Don't reset .visible on display:inline, 
			-- one display:none hides the whole subtree
		end
	elseif name == "fill" then
		if value == "none" then
			attr.hasFill = 0;
		elseif value:sub(1,4) == "url(" then
			attr.hasFill = 2;
			self:parseUrl(attr.fillGradient, value);
		else
			attr.hasFill = 1;
			attr.fillColor = self:parseColor(value);
		end
	elseif name == "opacity" then
		attr.opacity = self:parseOpacity(value);
	elseif name == "fill-opacity" then
		attr.fillOpacity = self:parseOpacity(value);
	elseif name == "stroke" then
		if value == "none" then
			attr.hasStroke = 0;
		elseif value:sub(1,4) == "url(" then
			attr.hasStroke = 2;
			self:parseUrl(attr.strokeGradient, value);
		else
			attr.hasStroke = 1;
			attr.strokeColor = self:parseColor(value);
		end
	elseif name == "stroke-width" then
		attr.strokeWidth = self:parseCoordinate(value, 0.0, self:actualLength());
	elseif name == "stroke-dasharray" then
		attr.strokeDashCount = self:parseStrokeDashArray(value, attr.strokeDashArray);
	elseif name == "stroke-dashoffset" then
		attr.strokeDashOffset = self:parseCoordinate(value, 0.0, self:actualLength());
	elseif name == "stroke-opacity" then
		attr.strokeOpacity = self:parseOpacity(value);
	elseif name == "stroke-linecap" then
		attr.strokeLineCap = self:parseLineCap(value);
	elseif name == "stroke-linejoin" then
		attr.strokeLineJoin = self:parseLineJoin(value);
	elseif name == "fill-rule" then
		attr.fillRule = self:parseFillRule(value);
	elseif name == "font-size" then
		attr.fontSize = self:parseCoordinate(value, 0.0, self:actualLength());
	elseif name == "transform" then
		self:parseTransform(xform, value);
		print("transform: ", xform[0], xform[1], xform[2], xform[3], xform[4], xform[5])
		transform2D.xformPremultiply(attr.xform, xform);
	elseif name == "stop-color" then
		attr.stopColor = self:parseColor(value);
	elseif name == "stop-opacity" then
		attr.stopOpacity = self:parseOpacity(value);
	elseif name == "offset" then
		attr.stopOffset = self:parseCoordinate(value, 0.0, 1.0);
	elseif name == "id" then
		strncpy(attr.id, value, 63);
		attr.id[63] = 0;
	else
		return false;
	end

	return true;
end

function SVGParser.parseStyle(self, s)
	--print("parseStyle: ", s)

	-- match everything but the delimeter
	for word in string.gmatch(s, "([^;]+)") do
		name, value = word:match("([^:]+):(.*)")
		self:parseAttr(name, value)
	end
end

function SVGParser.parseAttribs(self, attr)
	for k,v in pairs(attr) do
		if k == "style" then
			self:parseStyle(v);
		else
			self:parseAttr(k, v);
		end
	end
end

function SVGParser.pathMoveTo(self, cpx, cpy, args, rel)
--print("pathMoveTo: ", rel, args[1], args[2])
	if rel then
		cpx = cpx + args[1];
		cpy = cpy + args[2];
	else
		cpx = args[1];
		cpy = args[2];
	end

	self:moveTo(cpx, cpy);

	return cpx, cpy;
end

function SVGParser.pathLineTo(self, cpx, cpy, args, rel)
--print(".pathLineTo: ", rel, cpx, cpy, args[1], args[2])
	if rel then
		cpx = cpx + args[1];
		cpy = cpy + args[2];
	else
		cpx = args[1];
		cpy = args[2];
	end

	self:lineTo(cpx, cpy);

	return cpx, cpy;
end


function SVGParser.pathHLineTo(self, cpx, cpy, args, rel)
	if rel then
		cpx = cpx + args[1];
	else
		cpx = args[1];
	end

	self:lineTo(cpx, cpy);

	return cpx, cpy;
end

function SVGParser.pathVLineTo(self, cpx, cpy, args, rel)
	if rel then
		cpy = cpy + args[1];
	else
		cpy = args[1];
	end

	self:lineTo(cpx, cpy);

	return cpx, cpy;
end

function SVGParser.pathCubicBezTo(self, cpx, cpy, cpx2, cpy2, args, rel)

	local x2, y2, cx1, cy1, cx2, cy2 =0,0,0,0,0,0;

	if (rel) then
		cx1 = cpx + args[1];
		cy1 = cpy + args[2];
		cx2 = cpx + args[3];
		cy2 = cpy + args[4];
		x2 = cpx + args[5];
		y2 = cpy + args[6];
	else
		cx1 = args[1];
		cy1 = args[2];
		cx2 = args[3];
		cy2 = args[4];
		x2 = args[5];
		y2 = args[6];
	end

	self:cubicBezTo(cx1,cy1, cx2,cy2, x2,y2);

	cpx2 = cx2;
	cpy2 = cy2;
	cpx = x2;
	cpy = y2;

	return cpx, cpy, cpx2, cpy2;
end


function SVGParser.pathCubicBezShortTo(self, cpx, cpy,cpx2, cpy2, args, rel)

	local x1 = cpx;
	local y1 = cpy;

	local cx2 = args[1];
	local cy2 = args[2];
	local x2 = args[3];
	local y2 = args[4];

	if rel then
		cx2 = cx2 + cpx;
		cy2 = cy2 + cpy;
		x2 = x2 + cpx;
		y2 = y2 + cpy;
	end

	local cx1 = 2*x1 - cpx2;
	local cy1 = 2*y1 - cpy2;

	self:cubicBezTo(cx1,cy1, cx2,cy2, x2,y2);

	cpx2 = cx2;
	cpy2 = cy2;
	cpx = x2;
	cpy = y2;

	return cpx, cpy, cpx2, cpy2;
end

function SVGParser.pathQuadBezTo(self, cpx, cpy, cpx2, cpy2, args, rel)
	local x1 = cpx;
	local y1 = cpy;

	local	cx = args[1];
	local	cy = args[2];
	local	x2 = args[3];
	local	y2 = args[4];

	if rel then
		cx = cx + cpx;
		cy = cy + cpy;
		x2 = x2 + cpx;
		y2 = y2 + cpy;
	end

	-- Convert to cubic bezier
	local cx1 = x1 + 2.0/3.0*(cx - x1);
	local cy1 = y1 + 2.0/3.0*(cy - y1);
	local cx2 = x2 + 2.0/3.0*(cx - x2);
	local cy2 = y2 + 2.0/3.0*(cy - y2);

	self:cubicBezTo(cx1,cy1, cx2,cy2, x2,y2);

	cpx2 = cx;
	cpy2 = cy;
	cpx = x2;
	cpy = y2;

	return cpx, cpy, cpx2, cpy2;
end

function SVGParser.pathQuadBezShortTo(self, cpx, cpy, cpx2, cpy2, args, rel)

	local x1 = cpx;
	local y1 = cpy;
	local x2 = args[1];
	local y2 = args[2];

	if rel then
		x2 = x2 + cpx;
		y2 = y2 + cpy;
	end

	local cx = 2*x1 - cpx2;
	local cy = 2*y1 - cpy2;

	-- Convert to cubix bezier
	local cx1 = x1 + 2.0/3.0*(cx - x1);
	local cy1 = y1 + 2.0/3.0*(cy - y1);
	local cx2 = x2 + 2.0/3.0*(cx - x2);
	local cy2 = y2 + 2.0/3.0*(cy - y2);

	self:cubicBezTo(cx1,cy1, cx2,cy2, x2,y2);

	cpx2 = cx;
	cpy2 = cy;
	cpx = x2;
	cpy = y2;

	return cpx, cpy, cpx2, cpy2;
end





function SVGParser.pathArcTo(self, cpx, cpy, args, rel)
	print(".pathArcTo: ", rel, cpx, cpy, unpack(args))

--[[
	-- Ported from canvg (https://code.google.com/p/canvg/)
	float x1p, y1p,
	float x, y 
--]]

	local rx = abs(args[1]);				-- y radius
	local ry = abs(args[2]);				-- x radius
	local rotx = args[3] / 180.0 * SVG_PI;		-- x rotation angle
	
	-- Large arc
	local fa = false;
	if abs(args[4]) > 1e-6 then
		fa = true;
	end

	-- Sweep direction
	local fs = false;
	if abs(args[5]) > 1e-6 then
		fs = true;
	end

	local x1 = cpx;					-- start point
	local y1 = cpy;
	local x2 = args[6];
	local y2 = args[7];

	if rel then						-- end point
		x2 = x2 + cpx;
		y2 = y2 + cpy;
	else
		x2 = args[6];
		y2 = args[7];
	end

	local dx = x1 - x2;
	local dy = y1 - y2;
	local d = sqrt(dx*dx + dy*dy);


	if (d < 1e-6 or rx < 1e-6 or ry < 1e-6) then
		-- The arc degenerates to a line
		self:lineTo(x2, y2);
		cpx = x2;
		cpy = y2;
		return cpx, cpy;
	end

	local sinrx = sin(rotx);
	local cosrx = cos(rotx);


	-- Convert to center point parameterization.
	-- http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
	-- 1) Compute x1', y1'
	local x1p = cosrx * dx / 2.0 + sinrx * dy / 2.0;
	local y1p = -sinrx * dx / 2.0 + cosrx * dy / 2.0;
	d = sqr(x1p)/sqr(rx) + sqr(y1p)/sqr(ry);
	if d > 1 then
		d = sqrt(d);
		rx = rx * d;
		ry = ry * d;
	end

	-- 2) Compute cx', cy'
	local s = 0.0;
	local sa = sqr(rx)*sqr(ry) - sqr(rx)*sqr(y1p) - sqr(ry)*sqr(x1p);
	local sb = sqr(rx)*sqr(y1p) + sqr(ry)*sqr(x1p);
	if (sa < 0.0) then
		sa = 0.0;
	end

	if (sb > 0.0) then
		s = sqrt(sa / sb);
	end

	if (fa == fs) then
		s = -s;
	end

	local cxp = s * rx * y1p / ry;
	local cyp = s * -ry * x1p / rx;


	-- 3) Compute cx,cy from cx',cy'
	local cx = (x1 + x2)/2.0 + cosrx*cxp - sinrx*cyp;
	local cy = (y1 + y2)/2.0 + sinrx*cxp + cosrx*cyp;

	-- 4) Calculate theta1, and delta theta.
	local ux = (x1p - cxp) / rx;
	local uy = (y1p - cyp) / ry;
	local vx = (-x1p - cxp) / rx;
	local vy = (-y1p - cyp) / ry;
	local a1 = vecang(1.0,0.0, ux,uy);	-- Initial angle
	local da = vecang(ux,uy, vx,vy);		-- Delta angle

--[[
//	if (vecrat(ux,uy,vx,vy) <= -1.0f) da = NSVG_PI;
//	if (vecrat(ux,uy,vx,vy) >= 1.0f) da = 0;
--]]

	if (fa) then
		-- Choose large arc
		if (da > 0.0) then
			da = da - 2*SVG_PI;
		else
			da = 2*SVG_PI + da;
		end
	end


	-- Approximate the arc using cubic spline segments.
	local t = ffi.new("double[6]");
	t[0] = cosrx; t[1] = sinrx;
	t[2] = -sinrx; t[3] = cosrx;
	t[4] = cx; t[5] = cy;


	-- Split arc into max 90 degree segments.
	-- The loop assumes an iteration per end point (including start and end), this +1.
	local ndivs = abs(da) / (SVG_PI*0.5) + 1.0;
	local hda = (da / ndivs) / 2.0;
	local kappa = abs(4.0 / 3.0 * (1.0 - cos(hda)) / sin(hda));
	
	if (da < 0.0) then
		kappa = -kappa;
	end
	
	local px, py, ptanx, ptany = 0,0,0,0;

	for i = 0, ndivs  do
		local a = a1 + da * (i/ndivs);
		local dx = cos(a);
		local dy = sin(a);
		local x, y = transform2D.xformPoint(dx*rx, dy*ry, t); -- position
		local tanx, tany = transform2D.xformVec(-dy*rx * kappa, dx*ry * kappa, t); -- tangent
		if i > 0 then
			self:cubicBezTo(px+ptanx,py+ptany, x-tanx, y-tany, x, y);
		end

		px = x;
		py = y;
		ptanx = tanx;
		ptany = tany;
	end

	cpx = x2;
	cpy = y2;


	return cpx, cpy;
end

--[[
	given a 'd' attribute of an svg path element
	turn that into a table with each command and
	its arguments represented by their own table.
	Each command entry has the command itself (a single character)
	followed by the arguments for that command in subsequent positions
--]]
function parseSVGPath(input)
    local out = {};

    for instr, vals in input:gmatch("([a-df-zA-DF-Z])([^a-df-zA-DF-Z]*)") do
        local line = { instr };
        for v in vals:gmatch("([+-]?[%deE.]+)") do
            line[#line+1] = v;
        end
        out[#out+1] = line;
    end
    return out;
end

function SVGParser.parsePath(self, attr)
--print("parsePath: ")

	local s = nil;
	for name,value in pairs(attr) do
		--print('  ',name, value)
		if name == "d" then
			s = value;
		else
			self:parseAttribs({[name] = value});
		end
	end

	if (s) then
		self:resetPath();
		local cpx = 0; 
		local cpy = 0;
		local cpx2 = 0; 
		local cpy2 = 0;
		local closedFlag = false;

		local instructions = parseSVGPath(s)

		-- what we have in commands is a table of instructions
		-- each line has
		-- instructions[1] == name of instructions
		-- instructions[2..n] == values for instructions
		for _, args in ipairs(instructions) do
			local cmd = args[1];
			table.remove(args,1);
--print("  CMD: ", cmd, #args)

			-- now, we have the instruction in the 'ins' value
			-- and the arguments in the cmd table
			if cmd == "m" or cmd == "M" then
				--print("MOVETO:", unpack(args))
				if #args == 0 then
					-- Commit path.
					if (#self.pts > 0) then
						self:addPath(closedFlag);
					end

					-- Start new subpath.
					self:resetPath();
					closedFlag = false;
				else
					-- The first set of arguments determine the new current
					-- location.  After we remove them, the remaining args
					-- are treated as lineTo
					cpx, cpy = self:pathMoveTo(cpx, cpy, args, cmd == 'm');
					table.remove(args)
					table.remove(args)
					
					if #args >=2 then

						while #args >= 2 do
							cpx, cpy = self:pathLineTo(cpx, cpy, args, cmd == 'm');
							cpx2 = cpx;
							cpy2 = cpy;
							table.remove(args)
							table.remove(args)
                		end
                	end
				end
			elseif cmd == "l" or cmd == "L" then
				--print("LINETO: ", unpack(args))
				cpx, cpy = self:pathLineTo(cpx, cpy, args, cmd == 'l');
                cpx2 = cpx; 
                cpy2 = cpy;
			elseif cmd == "h" or cmd == "H" then
				--print("HLINETO: ", unpack(args))
				cpx, cpy = self:pathHLineTo(cpx, cpy, args, cmd == 'h');
                cpx2 = cpx; 
                cpy2 = cpy;
			elseif cmd == "v" or cmd == "V" then
				--print("VLINETO: ", unpack(args))
				cpx, cpy = self:pathVLineTo(cpx, cpy, args, cmd == 'v');
                cpx2 = cpx; 
                cpy2 = cpy;
			elseif cmd == "c" or cmd == "C" then
				--print("CUBICBEZIERTO: ", unpack(args))
				cpx, cpy, cpx2, cpy2 = self:pathCubicBezTo(cpx, cpy, cpx2, cpy2, args, cmd == 'c');
			elseif cmd == "s" or cmd == "S" then
				--print("CUBICBEZIERSHORTTO: ", unpack(args))
				cpx, cpy, cpx2, cpy2 = self:pathCubicBezShortTo(cpx, cpy, cpx2, cpy2, args, cmd == 's');
			elseif cmd == "q" or cmd == "Q" then
				--print("QUADBEZIERTO: ", unpack(args))
				cpx, cpy, cpx2, cpy2 = self:pathQuadBezTo(cpx, cpy, cpx2, cpy2, args, cmd == 'q');
			elseif cmd == "t" or cmd == "T" then
				--print("QUADBEZIERSHORTTO: ", unpack(args))
				cpx, cpy, cpx2, cpy2 = self:pathQuadBezShortTo(cpx, cpy, cpx2, cpy2, args, cmd == 't');

			elseif cmd == "a" or cmd == "A" then
				cpx, cpy = self:pathArcTo(cpx, cpy, args, cmd == 'a');
                cpx2 = cpx; 
                cpy2 = cpy;
			elseif cmd == "z" or cmd == "Z" then
				closedFlag = true;
				-- Commit path.
				if (#self.pts > 0) then
				-- Move current point to first point
					cpx = self.pts[1].x;
					cpy = self.pts[1].y;
					cpx2 = cpx; 
					cpy2 = cpy;
					self:addPath(closedFlag);
				end

				-- Start new subpath.
				self:resetPath();
				self:moveTo(cpx, cpy);
				closedFlag = false;
			end
		end

		-- Commit path.
		--print("COMMIT: ", #self.pts)
		if (#self.pts > 0) then
			self:addPath(closedFlag);
		end
	end

	self:addShape();
end

function SVGParser.parseRect(self, attr)
	local x = 0.0;
	local y = 0.0;
	local w = 0.0;
	local h = 0.0;
	local rx = -1.0; -- marks not set
	local ry = -1.0;
	
	for k,v in pairs(attr) do
		if not self:parseAttr(k,v) then
		if k == "x" then
			x = self:parseCoordinate(v, self:actualOrigX(), self:actualWidth());
		elseif k == "y" then
			y = self:parseCoordinate(v, self:actualOrigY(), self:actualHeight());
		elseif k == "width" then
			w = self:parseCoordinate(v, 0.0, self:actualWidth());
		elseif k == "height" then
			h = self:parseCoordinate(v, 0.0, self:actualHeight());
		elseif k == "rx" then
			rx = math.fabs(self:parseCoordinate(v, 0.0, self:actualWidth()));
		elseif k == "ry" then
			ry = math.fabs(self:parseCoordinate(v, 0.0, self:actualHeight()));
		end
		end
	end


	if (rx < 0.0 and ry > 0.0) then rx = ry; end
	if (ry < 0.0 and rx > 0.0) then ry = rx; end
	if (rx < 0.0) then rx = 0.0; end
	if (ry < 0.0) then ry = 0.0; end
	if (rx > w/2.0) then rx = w/2.0; end
	if (ry > h/2.0) then ry = h/2.0; end

--print("RECT: ", x, y, w, h, rx, ry)

	if w ~= 0 and h ~= 0  then
		self:resetPath();

		if (rx < 0.00001 or ry < 0.0001) then
			self:moveTo(x, y);
			self:lineTo(x+w, y);
			self:lineTo(x+w, y+h);
			self:lineTo(x, y+h);
		else 
			--print("ROUNDED RECT")
--[[
			-- Rounded rectangle
			self:moveTo(x+rx, y);
			self:lineTo(x+w-rx, y);
			self:cubicBezTo(x+w-rx*(1-SVG_KAPPA90), y, x+w, y+ry*(1-SVG_KAPPA90), x+w, y+ry);
			self:lineTo(x+w, y+h-ry);
			self:cubicBezTo(x+w, y+h-ry*(1-SVG_KAPPA90), x+w-rx*(1-SVG_KAPPA90), y+h, x+w-rx, y+h);
			self:lineTo(x+rx, y+h);
			self:cubicBezTo(x+rx*(1-SVG_KAPPA90), y+h, x, y+h-ry*(1-SVG_KAPPA90), x, y+h-ry);
			self:lineTo(x, y+ry);
			self:cubicBezTo(x, y+ry*(1-SVG_KAPPA90), x+rx*(1-SVG_KAPPA90), y, x+rx, y);
--]]
		end

		self:addPath(true);
		self:addShape();
	end
end



function SVGParser.parseCircle(self, attr)

	local cx = 0.0;
	local cy = 0.0;
	local r = 0.0;

	for name, value in pairs(attr) do
		if (not self:parseAttr(name, value)) then
			if name == "cx" then
				cx = self:parseCoordinate(value, self:actualOrigX(), self:actualWidth());
			elseif name == "cy" then
				cy = self:parseCoordinate(value, self:actualOrigY(), self:actualHeight());
			elseif name == "r" then
				r = fabs(self:parseCoordinate(value, 0.0, self:actualLength()));
			end
		end
	end

	if (r > 0.0) then
		self:resetPath();

		self:moveTo(cx+r, cy);
		self:cubicBezTo(cx+r, cy+r*SVG_KAPPA90, cx+r*SVG_KAPPA90, cy+r, cx, cy+r);
		self:cubicBezTo(cx-r*SVG_KAPPA90, cy+r, cx-r, cy+r*SVG_KAPPA90, cx-r, cy);
		self:cubicBezTo(cx-r, cy-r*SVG_KAPPA90, cx-r*SVG_KAPPA90, cy-r, cx, cy-r);
		self:cubicBezTo(cx+r*SVG_KAPPA90, cy-r, cx+r, cy-r*SVG_KAPPA90, cx+r, cy);

		self:addPath(true);

		self:addShape();
	end
end



function SVGParser.parseEllipse(self, attr)

	local cx = 0.0;
	local cy = 0.0;
	local rx = 0.0;
	local ry = 0.0;

	for name, value in pairs(attr) do
		if (not self:parseAttr(name, value)) then
			if name == "cx" then cx = self:parseCoordinate(value, self:actualOrigX(), self:actualWidth());
			elseif name == "cy" then cy = self:parseCoordinate(value, self:actualOrigY(), self:actualHeight());
			elseif name == "rx" then rx = fabs(self:parseCoordinate(value, 0.0, self:actualWidth()));
			elseif name == "ry" then ry = fabs(self:parseCoordinate(value, 0.0, self:actualHeight()));
			end
		end
	end

	if (rx > 0.0 and ry > 0.0) then
		self:resetPath();

		self:moveTo(cx+rx, cy);
		self:cubicBezTo(cx+rx, cy+ry*SVG_KAPPA90, cx+rx*SVG_KAPPA90, cy+ry, cx, cy+ry);
		self:cubicBezTo(cx-rx*SVG_KAPPA90, cy+ry, cx-rx, cy+ry*SVG_KAPPA90, cx-rx, cy);
		self:cubicBezTo(cx-rx, cy-ry*SVG_KAPPA90, cx-rx*SVG_KAPPA90, cy-ry, cx, cy-ry);
		self:cubicBezTo(cx+rx*SVG_KAPPA90, cy-ry, cx+rx, cy-ry*SVG_KAPPA90, cx+rx, cy);

		self:addPath(true);

		self:addShape();
	end
end

function SVGParser.parseLine(self, attr)

	local x1, y1, x2, y2 = 0, 0, 0, 0;

	for name, value in pairs(attr) do
		if (not self:parseAttr(name, value)) then
			if name == "x1" then x1 = self:parseCoordinate(value, self:actualOrigX(), self:actualWidth());
				elseif name == "y1" then y1 = self:parseCoordinate(value, self:actualOrigY(), self:actualHeight());
				elseif name == "x2" then x2 = self:parseCoordinate(value, self:actualOrigX(), self:actualWidth());
				elseif name == "y2" then y2 = self:parseCoordinate(value, self:actualOrigY(), self:actualHeight());
			end
		end
	end

	self:resetPath();

	self:moveTo(x1, y1);
	self:lineTo(x2, y2);

	self:addPath(false);

	self:addShape();
end



function SVGParser.parsePoly(self, attr, closeFlag)
	--local coordspatt = "([^ ]+)";
	local coordspatt = "(%g+%s*,%s*%g+)";
	--local xypatt = "([^,]+),(.*)";
	local xypatt = "(%g+)%s*,%s*(%g+)";

	self:resetPath();

	for name, value in pairs(attr) do
		if (not self:parseAttr(name, value)) then
			if name == "points" then
				local firstone = true;
				for coords in string.gmatch(value, coordspatt) do
					--print(".parsePoly(): ",coords)
					x, y = coords:match(xypatt)
					if x and y then
						--print("  x,y: ", x, y)

						if firstone then
							self:moveTo(tonumber(x), tonumber(y));
							firstone = not firstone;
						else
							self:lineTo(tonumber(x), tonumber(y));
						end
					end
				end
			end
		end
	end

	self:addPath(closeFlag);

	self:addShape();
end

function SVGParser.parseSVG(self, attrs)
	--print("SVGParser.parseSVG - BEGIN")
	
	for name, value in pairs(attrs) do
		--print("SVGParser.parseSVG: ", name, value)

		if (not self:parseAttr(name, value)) then
			--print("  name, value: ", name, value)
			if name == "width" then
				self.image.width = self:parseCoordinate(value, 0.0, 1.0);
			elseif name == "height" then
				self.image.height = self:parseCoordinate(value, 0.0, 1.0);
			elseif name == "viewBox" then
				local minx, miny, width, height = value:match("(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
				self.viewMinx = tonumber(minx);
				self.viewMiny = tonumber(miny);
				self.viewWidth = tonumber(width);
				self.viewHeight = tonumber(height);
				--sscanf(value, "%f%*[%%, \t]%f%*[%%, \t]%f%*[%%, \t]%f", &self.viewMinx, &self.viewMiny, &self.viewWidth, &self.viewHeight);
			elseif name == "preserveAspectRatio" then
				if value:find("none") then
					-- No uniform scaling
					self.alignType = SVG_ALIGN_NONE;
				else
					-- Parse X align
					if value:find("xMin") then
						self.alignX = SVG_ALIGN_MIN;
					elseif value:find("xMid") then
						self.alignX = SVG_ALIGN_MID;
					elseif value:find("xMax") then
						self.alignX = SVG_ALIGN_MAX;
					end

					-- Parse Y align
					if value:find("yMin") then
						self.alignY = SVG_ALIGN_MIN;
					elseif value:find("yMid") then
						self.alignY = SVG_ALIGN_MID;
					elseif value:find("yMax") then
						self.alignY = SVG_ALIGN_MAX;
					end

					-- Parse meet/slice
					self.alignType = SVG_ALIGN_MEET;
					if value:find("slice") then
						self.alignType = SVG_ALIGN_SLICE;
					end
				end
			end
		end
	end
end


--[[
function NSVGParser.parseGradient(self, const char** attr, char type)
{
	int i;
	NSVGgradientData* grad = (NSVGgradientData*)malloc(sizeof(NSVGgradientData));
	if (grad == NULL) return;
	memset(grad, 0, sizeof(NSVGgradientData));
	grad.units = NSVG_OBJECT_SPACE;
	grad.type = type;
	if (grad.type == NSVG_PAINT_LINEAR_GRADIENT) {
		grad.linear.x1 = self:coord(0.0f, NSVG_UNITS_PERCENT);
		grad.linear.y1 = self:coord(0.0f, NSVG_UNITS_PERCENT);
		grad.linear.x2 = self:coord(100.0f, NSVG_UNITS_PERCENT);
		grad.linear.y2 = self:coord(0.0f, NSVG_UNITS_PERCENT);
	elseif (grad.type == NSVG_PAINT_RADIAL_GRADIENT) {
		grad.radial.cx = self:coord(50.0f, NSVG_UNITS_PERCENT);
		grad.radial.cy = self:coord(50.0f, NSVG_UNITS_PERCENT);
		grad.radial.r = self:coord(50.0f, NSVG_UNITS_PERCENT);
	}

	xform.xformIdentity(grad.xform);

	for (i = 0; attr[i]; i += 2) {
		if (strcmp(attr[i], "id") == 0) {
			strncpy(grad.id, attr[i+1], 63);
			grad.id[63] = '\0';
		elseif (!self:parseAttr(p, attr[i], attr[i + 1])) {
			if (strcmp(attr[i], "gradientUnits") == 0) {
				if (strcmp(attr[i+1], "objectBoundingBox") == 0)
					grad.units = NSVG_OBJECT_SPACE;
				else
					grad.units = NSVG_USER_SPACE;
			elseif (strcmp(attr[i], "gradientTransform") == 0) {
				self:parseTransform(grad.xform, attr[i + 1]);
			elseif (strcmp(attr[i], "cx") == 0) {
				grad.radial.cx = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "cy") == 0) {
				grad.radial.cy = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "r") == 0) {
				grad.radial.r = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "fx") == 0) {
				grad.radial.fx = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "fy") == 0) {
				grad.radial.fy = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "x1") == 0) {
				grad.linear.x1 = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "y1") == 0) {
				grad.linear.y1 = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "x2") == 0) {
				grad.linear.x2 = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "y2") == 0) {
				grad.linear.y2 = self:parseCoordinateRaw(attr[i + 1]);
			elseif (strcmp(attr[i], "spreadMethod") == 0) {
				if (strcmp(attr[i+1], "pad") == 0)
					grad.spread = NSVG_SPREAD_PAD;
				else if (strcmp(attr[i+1], "reflect") == 0)
					grad.spread = NSVG_SPREAD_REFLECT;
				else if (strcmp(attr[i+1], "repeat") == 0)
					grad.spread = NSVG_SPREAD_REPEAT;
			elseif (strcmp(attr[i], "xlink:href") == 0) {
				const char *href = attr[i+1];
				strncpy(grad.ref, href+1, 62);
				grad.ref[62] = '\0';
			}
		}
	}

	grad.next = self.gradients;
	self.gradients = grad;
}
--]]

--[[
function NSVGParser.parseGradientStop(self, const char** attr)
{
	NSVGattrib* curAttr = self:getAttr(p);
	NSVGgradientData* grad;
	NSVGgradientStop* stop;
	int i, idx;

	curAttr.stopOffset = 0;
	curAttr.stopColor = 0;
	curAttr.stopOpacity = 1.0f;

	for (i = 0; attr[i]; i += 2) {
		self:parseAttr(p, attr[i], attr[i + 1]);
	}

	// Add stop to the last gradient.
	grad = self.gradients;
	if (grad == NULL) return;

	grad.nstops++;
	grad.stops = (NSVGgradientStop*)realloc(grad.stops, sizeof(NSVGgradientStop)*grad.nstops);
	if (grad.stops == NULL) return;

	// Insert
	idx = grad.nstops-1;
	for (i = 0; i < grad.nstops-1; i++) {
		if (curAttr.stopOffset < grad.stops[i].offset) {
			idx = i;
			break;
		}
	}
	if (idx != grad.nstops-1) {
		for (i = grad.nstops-1; i > idx; i--)
			grad.stops[i] = grad.stops[i-1];
	}

	stop = &grad.stops[idx];
	stop.color = curAttr.stopColor;
	stop.color |= (unsigned int)(curAttr.stopOpacity*255) << 24;
	stop.offset = curAttr.stopOffset;
}
--]]


function SVGParser.startElement(self, el, attr)
	--print("SVGParser.startElement: ", el, attr)

	if (self.defsFlag) then
		-- Skip everything but gradients in defs
		if el == "linearGradient" then
			self:parseGradient(attr, SVGTypes.PaintType.LINEAR_GRADIENT);
		elseif el == "radialGradient" then
			self:parseGradient(attr, SVGTypes.PaintType.RADIAL_GRADIENT);
		elseif el == "stop" then
			self:parseGradientStop(attr);
		end

		return;
	end

	if el == "g" then
		self:pushAttr();
		self:parseAttribs(attr);
	elseif el == "path" then
		if self.pathFlag then	-- Do not allow nested paths.
			print("NESTED PATH")
			return;
		end

		self:pushAttr();
		self:parsePath(attr);
		self:popAttr();
	elseif el == "rect" then
		self:pushAttr();
		self:parseRect(attr);
		self:popAttr();
	elseif el == "circle" then
		self:pushAttr();
		self:parseCircle(attr);
		self:popAttr();
	elseif el == "ellipse" then
		self:pushAttr();
		self:parseEllipse(attr);
		self:popAttr();
	elseif el == "line" then
		self:pushAttr();
		self:parseLine(attr);
		self:popAttr();
	elseif el == "polyline" then
		self:pushAttr();
		self:parsePoly(attr, false);
		self:popAttr();
	elseif el == "polygon" then
		self:pushAttr();
		self:parsePoly(attr, true);
		self:popAttr();
	elseif el == "linearGradient" then
		self:parseGradient(attr, NSVG_PAINT_LINEAR_GRADIENT);
	elseif el == "radialGradient" then
		self:parseGradient(attr, NSVG_PAINT_RADIAL_GRADIENT);
	elseif el == "stop" then
		self:parseGradientStop(attr);
	elseif el == "defs" then
		self.defsFlag = true;
	elseif el == "svg" then
		self:parseSVG(attr);
	end
end


function SVGParser.endElement(self, el)
--print("SVGParser.endElement: ", el)
	if el == "g" then
		self:popAttr();
	elseif el == "path" then
		self.pathFlag = false;
	elseif el == "defs" then
		self.defsFlag = false;
	end
end


function SVGParser.content(self, s)
	-- empty
end


function SVGParser.imageBounds(self, bounds)
--print(".imageBounds: ", #self.image.shapes)

	if #self.image.shapes < 1 then
		bounds[0],bounds[1],bounds[2],bounds[3] = 0,0,0,0;
		return;
	end

	for _, shape in ipairs(self.image.shapes) do
		bounds[0] = minf(bounds[0], shape.bounds[0]);
		bounds[1] = minf(bounds[1], shape.bounds[1]);
		bounds[2] = maxf(bounds[2], shape.bounds[2]);
		bounds[3] = maxf(bounds[3], shape.bounds[3]);
	end

	print(".imageBounds - END: ", bounds[0], bounds[1], bounds[2], bounds[3])

	return bounds[0], bounds[1], bounds[2], bounds[3];
end

local function viewAlign(content, container, kind)

	if (kind == SVG_ALIGN_MIN) then
		return 0;
	elseif (kind == SVG_ALIGN_MAX) then
		return container - content;
	end

	-- mid
	return (container - content) * 0.5;
end

local function scaleGradient(grad, tx, ty, sx, sy)
	grad.xform[0] = grad.xform[0] *sx;
	grad.xform[1] = grad.xform[1] *sx;
	grad.xform[2] = grad.xform[2] *sy;
	grad.xform[3] = grad.xform[3] *sy;
	grad.xform[4] = grad.xform[4] + tx*sx;
	grad.xform[5] = grad.xform[2] + ty*sx;
end


function SVGParser.scaleToViewbox(self, units)
	print("SHAPE TO VIEW BOX: ", units)
	local bounds = ffi.new("double[4]");
	local t = ffi.new("double[6]");

	-- Guess image size if not set completely.
	self:imageBounds(bounds);
--print("image bounds: ", bounds[0], bounds[1], bounds[2], bounds[3])
	if (self.viewWidth == 0) then
		if self.image.width > 0 then
			self.viewWidth = self.image.width;
		else
			self.viewMinx = bounds[0];
			self.viewWidth = bounds[2] - bounds[0];
		end
	end
	
	if (self.viewHeight == 0) then
		if (self.image.height > 0) then
			self.viewHeight = self.image.height;
		else
			self.viewMiny = bounds[1];
			self.viewHeight = bounds[3] - bounds[1];
		end
	end

	if (self.image.width == 0) then
		self.image.width = self.viewWidth;
	end

	if (self.image.height == 0) then
		self.image.height = self.viewHeight;
	end

	local tx = -self.viewMinx;
	local ty = -self.viewMiny;
	local sx = 0;
	if self.viewWidth > 0 then
		sx = self.image.width / self.viewWidth
	end
	
	local sy = 0;
	if self.viewHeight > 0 then
		sy = self.image.height / self.viewHeight;
	end

	-- Unit scaling
	local us = 1.0 / self:convertToPixels(self:coord(1.0, self:parseUnits(units)), 0.0, 1.0);

	-- Fix aspect ratio
	if (self.alignType == SVG_ALIGN_MEET) then
		-- fit whole image into viewbox
		sx = minf(sx, sy);
		sy = sx;
		tx = tx + viewAlign(self.viewWidth*sx, self.image.width, self.alignX) / sx;
		ty = ty + viewAlign(self.viewHeight*sy, self.image.height, self.alignY) / sy;
	elseif (self.alignType == SVG_ALIGN_SLICE) then
		-- fill whole viewbox with image
		sx = maxf(sx, sy);
		sy = sx;
		tx = tx + viewAlign(self.viewWidth*sx, self.image.width, self.alignX) / sx;
		ty = ty + viewAlign(self.viewHeight*sy, self.image.height, self.alignY) / sy;
	end

	-- Transform
	sx = sx*us;
	sy = sy*us;
	local avgs = (sx+sy) / 2.0;

	-- BUGBUG  Something wrong with scaling 
	-- setting values to 0

	for _, shape in ipairs(self.image.shapes) do
		shape.bounds[0] = (shape.bounds[0] + tx) * sx;
		shape.bounds[1] = (shape.bounds[1] + ty) * sy;
		shape.bounds[2] = (shape.bounds[2] + tx) * sx;
		shape.bounds[3] = (shape.bounds[3] + ty) * sy;

		for _, path in ipairs(shape.paths) do
			--print("PATH, sx, sy: ", sx, sy)
			path.bounds[0] = (path.bounds[0] + tx) * sx;
			path.bounds[1] = (path.bounds[1] + ty) * sy;
			path.bounds[2] = (path.bounds[2] + tx) * sx;
			path.bounds[3] = (path.bounds[3] + ty) * sy;
			
			for _, pt in ipairs(path.pts) do
				pt.x = (pt.x + tx) * sx;
				pt.y = (pt.y + ty) * sy;
				--print(pt.x, pt.y)
			end
		end

		if (shape.fill.type == PaintType.LINEAR_GRADIENT or shape.fill.type == PaintType.RADIAL_GRADIENT) then
			scaleGradient(shape.fill.gradient, tx,ty, sx,sy);
			ffi.copy(t, shape.fill.gradient.xform, ffi.sizeof("double")*6);
			xform.xformInverse(shape.fill.gradient.xform, t);
		end

		if (shape.stroke.type == PaintType.LINEAR_GRADIENT or shape.stroke.type == PaintType.RADIAL_GRADIENT) then
			scaleGradient(shape.stroke.gradient, tx,ty, sx,sy);
			ffi.copy(t, shape.stroke.gradient.xform, ffi.sizeof("double")*6);
			xform.xformInverse(shape.stroke.gradient.xform, t);
		end

		shape.strokeWidth = shape.strokeWidth * avgs;
		shape.strokeDashOffset = shape.strokeDashOffset * avgs;
		for i = 0, shape.strokeDashCount-1 do
			shape.strokeDashArray[i] = shape.strokeDashArray[i] * avgs;
		end
	end

	print("SHAPE TO VIEW BOX - END")
end


return SVGParser
