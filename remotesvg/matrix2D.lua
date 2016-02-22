local ffi = require ("ffi")

local tan, cos, sin = math.tan, math.cos, math.sin

local matrix2D = {}
setmetatable(matrix2D, {
	__call = function (self, ...)
		return self:new(...);
	end,
})
local matrix2D_mt = {
	__index = matrix2D;

	__tostring = function(self)
		return string.format("matrix (%f %f %f %f %f %f)",
			self[1], self[2], self[3], self[4], self[5], self[6])
	end,
}

function matrix2D.new(self, a, b, c, d, e, f)
	a = a or 0
	b = b or 0
	c = c or 0
	d = d or 0
	e = e or 0
	f = f or 0

	local obj = {a, b, c, d, e, f}
	setmetatable(obj, matrix2D_mt)

	return obj;
end

--[[
	Instance Constructors
--]]

--[[
	Create a new identity matrix
--]]
function matrix2D.identity()
	return matrix2D(1, 0, 0, 1, 0, 0)
end

--[[
	Create a new matrix which represents the specified
	translation 
--]]
function matrix2D.translation(tx, ty)
	return matrix2D(1, 0, 0, 1, tx, ty)
end

--[[
	Create a new matrix which represents the specified scaling
--]]
function matrix2D.scale(sx, sy)
	sx = sx or 1
	sy = sy or sx

	return matrix2D(sx, 0, 0, sy, 0, 0)
end

function matrix2D.skewX(a)
	return matrix2D(1, 0, tan(a), 1, 0, 0)
end

function matrix2D.skewY(a)
	return matrix2D(1, tan(a), 0, 1, 0, 0)
end

--[[
	create a matrix which is a rotation
	around the given angle
--]]
function matrix2D.rotation(a, x, y)
	local cs = cos(a);
	local sn = sin(a);

	return matrix2D(cs, sn, -sn, cs, 0, 0)
end

function matrix2D.xformMultiply(t, s)

	local t0 = t[0] * s[0] + t[1] * s[2];
	local t2 = t[2] * s[0] + t[3] * s[2];
	local t4 = t[4] * s[0] + t[5] * s[2] + s[4];
	t[1] = t[0] * s[1] + t[1] * s[3];
	t[3] = t[2] * s[1] + t[3] * s[3];
	t[5] = t[4] * s[1] + t[5] * s[3] + s[5];
	t[0] = t0;
	t[2] = t2;
	t[4] = t4;
end

--[[
	Create a new matrix which is the inverse of the 
	current matrix.
--]]
function matrix2D.inverse(t)

	local invdet = 0; 

	local det = t[1] * t[4] - t[3] * t[2];
	if (det > -1e-6 and det < 1e-6) then
		return matrix2D.identity();
	end

	invdet = 1.0 / det;
	local inv = {}
	inv[1] = (t[4] * invdet);
	inv[3] = (-t[3] * invdet);
	inv[5] = ((t[3] * t[6] - t[4] * t[5]) * invdet);
	inv[2] = (-t[2] * invdet);
	inv[4] = (t[1] * invdet);
	inv[6] = ((t[2] * t[5] - t[1] * t[6]) * invdet);
end

function matrix2D.Premultiply(t, s)

	local s2 = ffi.new("double[6]");
	ffi.copy(s2, s, ffi.sizeof("double")*6);
	matrix2D.xformMultiply(s2, t);
	ffi.copy(t, s2, ffi.sizeof("double")*6);
end

--[[
	return two coordinates transformed
	by the current matrix
--]]
function matrix2D.xformPoint(t, x, y)
	local dx = x*t[1] + y*t[3] + t[5];
	local dy = x*t[2] + y*t[4] + t[6];


	return dx, dy;
end

--[[
	Return a transformed vector.
	Since vectors don't have position, 
	leave off the translation portion.
--]]
function matrix2D.xformVec(t, x, y)

	local dx = x*t[1] + y*t[3];
	local dy = x*t[2] + y*t[4];

	return dx, dy
end

return matrix2D
