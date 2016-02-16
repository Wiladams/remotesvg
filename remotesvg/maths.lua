local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local acos = math.acos;
local sqrt = math.sqrt;
local floor = math.floor;
local ceil = math.ceil;



local function curveDivs(r, arc, tol)
	local da = acos(r / (r + tol)) * 2.0;
	local divs = ceil(arc / da);
	if (divs < 2) then
		divs = 2;
	end

	return divs;
end

-- fairly efficient division by 255
local function div255(x)
    return rshift(((x+1) * 257), 16);
end

local function GetAlignedByteCount(width, bitsPerPixel, byteAlignment)
    local nbytes = width * (bitsPerPixel/8);
    return nbytes + (byteAlignment - (nbytes % byteAlignment)) % 4
end

-- determine where a point (p3) intersects the
-- line determined by points p1 and p2
	-- Points on line defined by
	-- P = P1 + u*(P2 - P1)
local function lineMag(x1, y1, x2, y2)
	local x = x2 - x1;
	local y = y2 - y1;

	return sqrt(x*x+y*y);
end

local function vmag(x, y)  return sqrt(x*x + y*y); end

local function normalize(x, y)
	local d = sqrt(x*x + y*y);
	if (d > 1e-6) then
		local id = 1.0 / d;
		x = x * id;
		y = y * id;
	end

	return d, x, y;
end

local function vecrat(ux, uy, vx, vy)
	return (ux*vx + uy*vy) / (vmag(ux,uy) * vmag(vx,vy));
end



local function vecang(ux, uy, vx, vy)

	local r = vecrat(ux,uy, vx,vy);
	if (r < -1.0) then
		r = -1.0;
	end

	if (r > 1.0) then
		r = 1.0;
	end

	local acs = acos(r);
	if (ux*vy < uy*vx) then 
		return -1.0 * acs;
	end

	return acs;
end

local function pointLineIntersection(x1, y1, x2, y2, x3, y3)
	local mag = lineMag(x1, y1, x2, y2)
	local u = ((x3 - x1)*(x2-x1) + (y3-y1)*(y2-y1))/(mag*mag)
	local x = x1 + u * (x2 - x1);
	local y = y1 + u * (y2 - y1);

	return x, y
end

local function pointLineDistance(x1, y1, x2, y2, x3, y3)
	local x, y = pointLineIntersection(x1, y1, x2, y2, x3, y3)

	return lineMag(x3, y3, x, y)
end

-- determine if two points are equal, within a specified tolerance
local function pointEquals(x1, y1, x2, y2, tol)
	local dx = x2 - x1;
	local dy = y2 - y1;
	
	return dx*dx + dy*dy < tol*tol;
end

function RANGEMAP(x, a, b, c, d)
	return c + ((x-a)/(b-a)*(d-c))
end

local function round(n)
	if n >= 0 then
		return floor(n+0.5)
	end

	return ceil(n-0.5)
end

local function clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end

	return x;
end

local function sgn(x)
	if x < 0 then return -1 end
	if x > 0 then return 1 end

	return 0
end

local function sqr(x)  return x*x; end





return {
	clamp = clamp;
	curveDivs = curveDivs;
	div255 = div255;
	GetAlignedByteCount = GetAlignedByteCount;

	lineMag = lineMag;

	pointEquals = pointEquals;
	pointLineIntersection = pointLineIntersection;
	pointLineDistance = pointLineDistance;
	
	RANGEMAP = RANGEMAP;
	round = round;
	sgn = sgn;
	sqr = sqr;

	vecang = vecang;
	vecrat = vecrat;
	vmag = vmag;
}