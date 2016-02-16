-- Bezier.lua
-- Evaluate a single dimension along a bezier curve
-- call multiple times with components of each dimension
local function eval(t, p0, p1, p2, p3)
	local it = 1.0-t;
	return it*it*it*p0 + 3.0*it*it*t*p1 + 3.0*it*t*t*p2 + t*t*t*p3;
end

return {
	eval = eval;
}