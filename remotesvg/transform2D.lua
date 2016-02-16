local ffi = require ("ffi")

local tan, cos, sin = math.tan, math.cos, math.sin

local xform = {}

function xform.xformIdentity(t)
	t[0] = 1.0; t[1] = 0.0;
	t[2] = 0.0; t[3] = 1.0;
	t[4] = 0.0; t[5] = 0.0;
end

function xform.xformSetTranslation(t, tx, ty)

	t[0] = 1.0; t[1] = 0.0;
	t[2] = 0.0; t[3] = 1.0;
	t[4] = tx; t[5] = ty;
end

function xform.xformSetScale(t, sx, sy)
	t[0] = sx; t[1] = 0.0;
	t[2] = 0.0; t[3] = sy;
	t[4] = 0.0; t[5] = 0.0;
end

function xform.xformSetSkewX(t, a)

	t[0] = 1.0; t[1] = 0.0;
	t[2] = tan(a); t[3] = 1.0;
	t[4] = 0.0; t[5] = 0.0;
end

function xform.xformSetSkewY(t, a)

	t[0] = 1.0; t[1] = tan(a);
	t[2] = 0.0; t[3] = 1.0;
	t[4] = 0.0; t[5] = 0.0;
end

function xform.xformSetRotation(t, a)

	local cs = cos(a);
	local sn = sin(a);
	t[0] = cs; t[1] = sn;
	t[2] = -sn; t[3] = cs;
	t[4] = 0.0; t[5] = 0.0;
end

function xform.xformMultiply(t, s)

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

function xform.xformInverse(inv, t)

	local invdet = 0; 
	local det = t[0] * t[3] - t[2] * t[1];
	if (det > -1e-6 and det < 1e-6) then
		xform.xformIdentity(t);
		return;
	end

	invdet = 1.0 / det;
	inv[0] = (t[3] * invdet);
	inv[2] = (-t[2] * invdet);
	inv[4] = ((t[2] * t[5] - t[3] * t[4]) * invdet);
	inv[1] = (-t[1] * invdet);
	inv[3] = (t[0] * invdet);
	inv[5] = ((t[1] * t[4] - t[0] * t[5]) * invdet);
end

function xform.xformPremultiply(t, s)

	local s2 = ffi.new("double[6]");
	ffi.copy(s2, s, ffi.sizeof("double")*6);
	xform.xformMultiply(s2, t);
	ffi.copy(t, s2, ffi.sizeof("double")*6);
end

function xform.xformPoint(x, y, t)
	local dx = x*t[0] + y*t[2] + t[4];
	local dy = x*t[1] + y*t[3] + t[5];


	return dx, dy;
end

function xform.xformVec(x, y, t)

	local dx = x*t[0] + y*t[2];
	local dy = x*t[1] + y*t[3];

	return dx, dy
end

return xform
