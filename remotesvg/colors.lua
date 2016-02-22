local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local maths = require("remotesvg.maths");
local clamp = maths.clamp

-- The actual layout in memory is:
-- Little Endian - BGRA
-- Big Endian - ARGB
-- For things that actually depend on this memory ordering
-- they should take care of this difference
local function RGBA(r, g, b, a)
	a = a or 255;
	local num = tonumber(bor(lshift(tonumber(a),24), lshift(tonumber(r),16), lshift(tonumber(g),8), tonumber(b)))

	return num;
end

local function colorComponents(c)
	local b = band(c, 0xff);
	local g = band(rshift(c,8), 0xff);
	local r = band(rshift(c,16), 0xff);
	local a = band(rshift(c,24), 0xff);

	return r, g, b, a
end

--[[
c - unsigned int
	a color value, including r,g,b,a components
u - float
	should be a value between 0.0 and 1.0
--]]
local function applyOpacity(c, u)

	local iu = clamp(u, 0.0, 1.0) * 256.0;
	local r, g, b, a = colorComponents(c);
	a = rshift(a*iu, 8);
	
	return RGBA(r, g, b, a);
end

--[[
	linear interpolation of value from color c0 to 
	color c1
--]]
local function lerpRGBA(c0, c1, u)

	local iu = clamp(u, 0.0, 1.0) * 256.0;
	local c0r, c0g, c0b, c0a = colorComponents(c0);
	local c1r, c1g, c1b, c1a = colorComponents(c1);

	local r = rshift(c0r*(256-iu) + (c1r*iu), 8);
	local g = rshift(c0g*(256-iu) + (c1g*iu), 8);
	local b = rshift(c0b*(256-iu) + (c1b*iu), 8);
	local a = rshift(c0a*(256-iu) + (c1a*iu), 8);
	
	return RGBA(r, g, b, a);
end

--[[
local function SVG_RGB(r, g, b) 
	return bor(lshift(b,16), lshift(g,8), r)
end
--]]

local exports = {
	applyOpacity = applyOpacity;
	colorComponents = colorComponents;
	lerpRGBA = lerpRGBA;
	RGBA = RGBA;

	white = RGBA(255, 255, 255);
	black = RGBA(0,0,0);
	blue = RGBA(0,0,255);
	green = RGBA(0,255,0);
	red = RGBA(255, 0, 0);

	yellow = RGBA(255, 255, 0);
	darkyellow = RGBA(127, 127, 0);

	-- grays
	lightgray = RGBA(235, 235, 235);

	-- SVG color values
	svg = {
	["red"] = RGBA(255, 0, 0) ;
	["green"] = RGBA( 0, 128, 0) ;
	["blue"] = RGBA( 0, 0, 255) ;
	["yellow"] = RGBA(255, 255, 0) ;
	["cyan"] = RGBA( 0, 255, 255) ;
	["magenta"] = RGBA(255, 0, 255) ;
	["black"] = RGBA( 0, 0, 0) ;
	["grey"] = RGBA(128, 128, 128) ;
	["gray"] = RGBA(128, 128, 128) ;
	["white"] = RGBA(255, 255, 255) ;

	["aliceblue"] = RGBA(240, 248, 255) ;
	["antiquewhite"] = RGBA(250, 235, 215) ;
	["aqua"] = RGBA( 0, 255, 255) ;
	["aquamarine"] = RGBA(127, 255, 212) ;
	["azure"] = RGBA(240, 255, 255) ;
	["beige"] = RGBA(245, 245, 220) ;
	["bisque"] = RGBA(255, 228, 196) ;
	["blanchedalmond"] = RGBA(255, 235, 205) ;
	["blueviolet"] = RGBA(138, 43, 226) ;
	["brown"] = RGBA(165, 42, 42) ;
	["burlywood"] = RGBA(222, 184, 135) ;
	["cadetblue"] = RGBA( 95, 158, 160) ;
	["chartreuse"] = RGBA(127, 255, 0) ;
	["chocolate"] = RGBA(210, 105, 30) ;
	["coral"] = RGBA(255, 127, 80) ;
	["cornflowerblue"] = RGBA(100, 149, 237) ;
	["cornsilk"] = RGBA(255, 248, 220) ;
	["crimson"] = RGBA(220, 20, 60) ;
	["darkblue"] = RGBA( 0, 0, 139) ;
	["darkcyan"] = RGBA( 0, 139, 139) ;
	["darkgoldenrod"] = RGBA(184, 134, 11) ;
	["darkgray"] = RGBA(169, 169, 169) ;
	["darkgreen"] = RGBA( 0, 100, 0) ;
	["darkgrey"] = RGBA(169, 169, 169) ;
	["darkkhaki"] = RGBA(189, 183, 107) ;
	["darkmagenta"] = RGBA(139, 0, 139) ;
	["darkolivegreen"] = RGBA( 85, 107, 47) ;
	["darkorange"] = RGBA(255, 140, 0) ;
	["darkorchid"] = RGBA(153, 50, 204) ;
	["darkred"] = RGBA(139, 0, 0) ;
	["darksalmon"] = RGBA(233, 150, 122) ;
	["darkseagreen"] = RGBA(143, 188, 143) ;
	["darkslateblue"] = RGBA( 72, 61, 139) ;
	["darkslategray"] = RGBA( 47, 79, 79) ;
	["darkslategrey"] = RGBA( 47, 79, 79) ;
	["darkturquoise"] = RGBA( 0, 206, 209) ;
	["darkviolet"] = RGBA(148, 0, 211) ;
	["deeppink"] = RGBA(255, 20, 147) ;
	["deepskyblue"] = RGBA( 0, 191, 255) ;
	["dimgray"] = RGBA(105, 105, 105) ;
	["dimgrey"] = RGBA(105, 105, 105) ;
	["dodgerblue"] = RGBA( 30, 144, 255) ;
	["firebrick"] = RGBA(178, 34, 34) ;
	["floralwhite"] = RGBA(255, 250, 240) ;
	["forestgreen"] = RGBA( 34, 139, 34) ;
	["fuchsia"] = RGBA(255, 0, 255) ;
	["gainsboro"] = RGBA(220, 220, 220) ;
	["ghostwhite"] = RGBA(248, 248, 255) ;
	["gold"] = RGBA(255, 215, 0) ;
	["goldenrod"] = RGBA(218, 165, 32) ;
	["greenyellow"] = RGBA(173, 255, 47) ;
	["honeydew"] = RGBA(240, 255, 240) ;
	["hotpink"] = RGBA(255, 105, 180) ;
	["indianred"] = RGBA(205, 92, 92) ;
	["indigo"] = RGBA( 75, 0, 130) ;
	["ivory"] = RGBA(255, 255, 240) ;
	["khaki"] = RGBA(240, 230, 140) ;
	["lavender"] = RGBA(230, 230, 250) ;
	["lavenderblush"] = RGBA(255, 240, 245) ;
	["lawngreen"] = RGBA(124, 252, 0) ;
	["lemonchiffon"] = RGBA(255, 250, 205) ;
	["lightblue"] = RGBA(173, 216, 230) ;
	["lightcoral"] = RGBA(240, 128, 128) ;
	["lightcyan"] = RGBA(224, 255, 255) ;
	["lightgoldenrodyellow"] = RGBA(250, 250, 210) ;
	["lightgray"] = RGBA(211, 211, 211) ;
	["lightgreen"] = RGBA(144, 238, 144) ;
	["lightgrey"] = RGBA(211, 211, 211) ;
	["lightpink"] = RGBA(255, 182, 193) ;
	["lightsalmon"] = RGBA(255, 160, 122) ;
	["lightseagreen"] = RGBA( 32, 178, 170) ;
	["lightskyblue"] = RGBA(135, 206, 250) ;
	["lightslategray"] = RGBA(119, 136, 153) ;
	["lightslategrey"] = RGBA(119, 136, 153) ;
	["lightsteelblue"] = RGBA(176, 196, 222) ;
	["lightyellow"] = RGBA(255, 255, 224) ;
	["lime"] = RGBA( 0, 255, 0) ;
	["limegreen"] = RGBA( 50, 205, 50) ;
	["linen"] = RGBA(250, 240, 230) ;
	["maroon"] = RGBA(128, 0, 0) ;
	["mediumaquamarine"] = RGBA(102, 205, 170) ;
	["mediumblue"] = RGBA( 0, 0, 205) ;
	["mediumorchid"] = RGBA(186, 85, 211) ;
	["mediumpurple"] = RGBA(147, 112, 219) ;
	["mediumseagreen"] = RGBA( 60, 179, 113) ;
	["mediumslateblue"] = RGBA(123, 104, 238) ;
	["mediumspringgreen"] = RGBA( 0, 250, 154) ;
	["mediumturquoise"] = RGBA( 72, 209, 204) ;
	["mediumvioletred"] = RGBA(199, 21, 133) ;
	["midnightblue"] = RGBA( 25, 25, 112) ;
	["mintcream"] = RGBA(245, 255, 250) ;
	["mistyrose"] = RGBA(255, 228, 225) ;
	["moccasin"] = RGBA(255, 228, 181) ;
	["navajowhite"] = RGBA(255, 222, 173) ;
	["navy"] = RGBA( 0, 0, 128) ;
	["oldlace"] = RGBA(253, 245, 230) ;
	["olive"] = RGBA(128, 128, 0) ;
	["olivedrab"] = RGBA(107, 142, 35) ;
	["orange"] = RGBA(255, 165, 0) ;
	["orangered"] = RGBA(255, 69, 0) ;
	["orchid"] = RGBA(218, 112, 214) ;
	["palegoldenrod"] = RGBA(238, 232, 170) ;
	["palegreen"] = RGBA(152, 251, 152) ;
	["paleturquoise"] = RGBA(175, 238, 238) ;
	["palevioletred"] = RGBA(219, 112, 147) ;
	["papayawhip"] = RGBA(255, 239, 213) ;
	["peachpuff"] = RGBA(255, 218, 185) ;
	["peru"] = RGBA(205, 133, 63) ;
	["pink"] = RGBA(255, 192, 203) ;
	["plum"] = RGBA(221, 160, 221) ;
	["powderblue"] = RGBA(176, 224, 230) ;
	["purple"] = RGBA(128, 0, 128) ;
	["rosybrown"] = RGBA(188, 143, 143) ;
	["royalblue"] = RGBA( 65, 105, 225) ;
	["saddlebrown"] = RGBA(139, 69, 19) ;
	["salmon"] = RGBA(250, 128, 114) ;
	["sandybrown"] = RGBA(244, 164, 96) ;
	["seagreen"] = RGBA( 46, 139, 87) ;
	["seashell"] = RGBA(255, 245, 238) ;
	["sienna"] = RGBA(160, 82, 45) ;
	["silver"] = RGBA(192, 192, 192) ;
	["skyblue"] = RGBA(135, 206, 235) ;
	["slateblue"] = RGBA(106, 90, 205) ;
	["slategray"] = RGBA(112, 128, 144) ;
	["slategrey"] = RGBA(112, 128, 144) ;
	["snow"] = RGBA(255, 250, 250) ;
	["springgreen"] = RGBA( 0, 255, 127) ;
	["steelblue"] = RGBA( 70, 130, 180) ;
	["tan"] = RGBA(210, 180, 140) ;
	["teal"] = RGBA( 0, 128, 128) ;
	["thistle"] = RGBA(216, 191, 216) ;
	["tomato"] = RGBA(255, 99, 71) ;
	["turquoise"] = RGBA( 64, 224, 208) ;
	["violet"] = RGBA(238, 130, 238) ;
	["wheat"] = RGBA(245, 222, 179) ;
	["whitesmoke"] = RGBA(245, 245, 245) ;
	["yellowgreen"] = RGBA(154, 205, 50) ;
	};	-- svg
}

return exports
