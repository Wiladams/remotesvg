
-- References
-- https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute
--
local colors = require("remotesvg.colors")
local RGB = colors.RGBA;
local maths = require("remotesvg.maths")
local clamp = maths.clamp;
local bit = require("bit")
local lshift, rshift, band, bor = bit.lshift, bit.rshift, bit.band, bit.bor

local tonumber = tonumber;
local tostring = tostring;

-- These functions convert from SVG Attribute string values
-- to lua specific types
local function color(name, value, strict)
	local function parseColorName(name)
		return colors.svg[name] or RGB(128, 128, 128);
	end
	
	local function parseColorHex(s)
		--print(".parseColorHex: ", s)

		local rgb = s:match("#(%x+)")
		--print("rgb: ", rgb)
		local r,g,b = 0,0,0;
		local c = 0;
		--rgb = "0x"..rgb;

		if #rgb == 6 then
			c = tonumber("0x"..rgb)
		elseif #rgb == 3 then
			c = tonumber("0x"..rgb);
			c = bor(band(c,0xf), lshift(band(c,0xf0), 4), lshift(band(c,0xf00), 8));
			c = bor(c, lshift(c,4));
		end
		b = band(rshift(c, 16), 0xff);
		g = band(rshift(c, 8), 0xff);
		r = band(c, 0xff);

		return RGB(r,g,b);
	end

	local function parseColorRGB(str)
		-- if numberpatt uses %x instead of %d, then do the following
		-- to get past the 'b' in 'rgb('
		--local loc = str:find("%(")
		--str = str:sub(loc+1,#str)
		local numberpatt = "(%d+)"
		local usePercent = str:find("%%")

		--print("parseColorRGB: ", str, usePercent)

		local tbl = {}
		for num in str:gmatch(numberpatt) do
			if usePercent then
				table.insert(tbl, tonumber(num)*255/100)
			else
				table.insert(tbl, tonumber(num))
			end
		end

		return RGB(tbl[1], tbl[2], tbl[3])
	end

	local str = value:match("%s*(.*)")
	local len = #str;
	
	--print("parseColor: ", str)
	if len >= 1 and str:sub(1,1) == '#' then
		value = parseColorHex(str);
	elseif (len >= 4 and str:match("rgb%(")) then
		value = parseColorRGB(str);
	else
		value = parseColorName(str);
	end

	local r, g, b, a = colors.colorComponents(value)
	--print("COLOR: ", r,g,b,a)
	local obj = {r=r, g = g, b = b, a = a};
	setmetatable(obj, {
		__tostring = function(self)
			return string.format("rgb(%d, %d, %d)", self.r, self.g, self.b)
		end
	})
	
	return name, obj
end
local paint = color;


local function coord(name, value, strict)
	if type(value) ~= "string" then
		return name, value;
	end

	local num, units = value:match("(%d*%.?%d*)(.*)")

	if not num then return nil; end

	local obj = {value = tonumber(num), units = units}
	setmetatable(obj,{
		__tostring = function(self)
			return string.format("%d%s",self.value, self.units or "")
		end,
	})

	return name, obj;
end
-- The specification for length is the same as for
-- coordinates
local length = coord

local function number(name, value, strict)
	if type(value) ~= "string" then
		return name, value;
	end

	return name, tonumber(value)
end

-- strictly, the SVG spec say opacity is simply 
-- a number between 0..1
-- but, we'll allow specifying a '%' value as well...

function opacity(name, value, strict)
	if type(value) ~= "string" then
		return name, value;
	end

	local usePercent = value:find("%%")
	local num = 1.0
	tonumber(value)
	if usePercent then
		local str = value:match("(%d+)")
		num = tonumber(str) / 100;
	else
		num = tonumber(value);
	end

	local val = clamp(tonumber(value), 0, 1);

	return val;
end

local function viewBox(name, value, strict)
	if type(value) ~= "string" then
		return name, value
	end
	local numpatt = "(%d*%.?%d*)"
	local nums = {}
	for num in value:gmatch(numpatt) do
		--print("NUM: ", num, type(num))
		if num ~= "" then
			table.insert(nums, tonumber(num))
		end
	end

	local obj = {
		min_x = nums[1], 
		min_y = nums[2], 
		width = nums[3], 
		height= nums[4]
	}
	
	setmetatable(obj, {
		__tostring = function(self)
			return string.format("%d %d %d %d", 
				self.min_x, self.min_y, self.width, self.height);
		end,
	})
	
	return obj;
end







-- Individual functions which deal with specific
-- attributes
local attrs = {}

-- This is the function to be used when we don't have 
-- any specific specialization for an attribute
function default(name, value, strict)
--print("{name = '', parser = default}: ", name, value);

	return name, value
end


attrs.accent_height = {name = 'accent-height', parser = number};
attrs.accumulate = {name = 'accumulate', pardser = default};	-- 'none' | 'sum'
attrs.additive = {name = 'additive', parser = default};	-- 'replace' | 'sum'
attrs.alignment_baseline = {name = 'alignment-baseline', parser = default};
attrs.allowReorder = {name = 'allowReorder', parser = default};
attrs.alphabetic = {name = 'alphabetic', parser = number};
attrs.amplitude = {name = 'amplitude', parser = default};
attrs.arabic_form = {name = 'arabic-form', parser = default};
attrs.ascent = {name = 'ascent', parser = number};
attrs.attributeName = {name = 'attributeName', parser = default};
attrs.attributeType = {name = 'attributeType', parser = default};
attrs.autoReverse = {name = 'autoReverse', parser = default};
attrs.azimuth = {name = 'azimuth', parser = default};

attrs.baseFrequency = {name = 'baseFrequency', parser = default};
attrs.baseline_shift = {name = 'baseline-shift', parser = default};
attrs.baseProfile = {name = 'baseProfile', parser = default};
attrs.bbox = {name = 'bbox', parser = default};
attrs.begin = {name = 'begin', parser = default};
attrs.bias = {name = 'bias', parser = default};
attrs.by = {name = 'by', parser = default};

attrs.calcMode = {name = 'calcMode', parser = default};
attrs.cap_height = {name = 'cap-height', parser = number};
attrs['cap-height'] = attrs.cap_height;
attrs.class = {name = 'class', parser = default};
attrs.clip = {name = 'clip', parser = default};
attrs.clipPathUnits = {name = 'clipPathUnits', parser = default};
attrs.clip_path = {name = 'clip-path', parser = default};
attrs.clip_rule = {name = 'clip-rule', parser = default};
attrs.color = {name = 'color', parser = color};
attrs.color_interpolation = {name = 'color-interpolation', parser = default};
attrs.color_interpolation_filters = {name = 'color-interpolation-filters', parser = default};
attrs.color_profile = {name = 'profile', parser = default};
attrs.color_rendering = {name = 'color-rendering', parser = default};
attrs.contentScriptType = {name = 'contentScriptType', parser = default};
attrs.contentStyleType = {name = 'contentStyleType', parser = default};
attrs.cursor = {name = 'cursor', parser = default};
attrs.cx = {name='cx', parser = coord};
attrs.cy = {name = 'cy', parser = coord};

attrs.d = {name = 'd', parser = default};
attrs.decelerate = {name = 'decelerate', parser = default};
attrs.descent = {name = 'descent', parser = number};
attrs.diffuseConstant = {name = 'diffuseConstant', parser = default};
attrs.direction = {name = 'direction', parser = default};
attrs.display = {name = 'display', parser = default};
attrs.divisor = {name = 'divisor', parser = default};
attrs.dominant_baseline = {name = 'dominant-baseline', parser = default};
attrs.dur = {name = 'dur', parser = default};
attrs.dx = {name='dx', parser = number};
attrs.dy = {name = 'dy', parser = number};

attrs.edgeMode = {name = 'edgeMode', parser = default};
attrs.elevation = {name = 'elevation', parser = default};
attrs.enable_background = {name = 'enable-background', parser = default};
attrs['enable-background'] = attrs.enable_background;
attrs['end'] = {name = 'end', parser = default};
attrs.exponent = {name = 'exponent', parser = default};
attrs.externalResourcesRequired = {name = 'externalResourcesRequired', parser = default};

attrs.fill = {name='fill', parser = paint};
attrs.fill_opacity = {name = 'fill-opacity', parser = opacity};
attrs['fill-opacity'] = attrs.fill_opacity;
attrs.fill_rule = {name = 'fill-rule', parser = default};
attrs['fill-rule'] = attrs.fill_rule;
attrs.filter = {name = 'filter', parser = default};
attrs.filterRes = {name = 'filterRes', parser = default};
attrs.filterUnits = {name = 'filterUnits', parser = default};
attrs.flood_color = {name='flood-color', parser =color};
attrs['flood-color'] = attrs.flood_color;
attrs.flood_opacity = {name = 'flood-opacity', parser = opacity};
attrs.font_family = {name = 'font-family', parser = default};
attrs.font_size = {name = 'font-size', parser = default};
attrs['font-size'] = attrs.font_size;
attrs.font_size_adjust = {name = 'font-size-adjust', parser = default};
attrs.font_stretch = {name = 'font-stretch', parser = default};
attrs.font_style = {name = 'font-style', parser = default};
attrs.font_variant = {name = 'font-variant', parser = default};
attrs.font_weight = {name = 'font-weight', parser = default};
attrs.format = {name = 'format', parser = default};
attrs.from = {name = 'from', parser = default};
attrs.fx = {name='fx', parser=coord};
attrs.fy = {name='fy', parser=coord};

attrs.g1 = {name = 'g1', parser = default};
attrs.g2 = {name = 'g2', parser = default};
attrs.glyph_name = {name = 'glyph-name', parser = default};
attrs.glyph_orientation_horizontal = {name = 'glyph-orinentation-horizontal', parser = default};
attrs.glyph_orientation_vertical = {name = 'glyph-orientation-vertical', parser = default};
attrs.glyphRef = {name = 'glyphRef', parser = default};
attrs.gradientTransform = {name = 'gradientTransform', parser = default};
attrs.gradientUnits = {name = 'gradientUnits', parser = default};

attrs.hanging = {name ='hanging', parser=number};
attrs.height = {name = 'height', parser=length};
attrs.horiz_adv_x = {name = 'horiz-adv-x', parser = default};
attrs.horiz_origin_x = {name = 'horiz-origin-x', parser = default};
attrs['horiz-origin-x'] = attrs.horiz_origin_x;

attrs.id = {name = 'id', parser = default};
attrs.ideographic = {name = 'ideographic', parser = default};
attrs.image_rendering = {name = 'image-rendering', parser = default};
attrs['in'] = {name = 'in', parser = default};
attrs.in2 = {name = 'in2', parser = default};
attrs.intercept = {name = 'intercept', parser = default};

attrs.k = {name = 'k', parser = number};
attrs.k1 = {name = 'k1', parser = number};
attrs.k2 = {name = 'k2', parser = number};
attrs.k3 = {name = 'k3', parser = number};
attrs.k4 = {name = 'k4', parser = number};
attrs.kernelMatrix = {name = 'kernelMatrix', parser = default};
attrs.kernelUnitLength = {name = 'kernelUnitLength', parser = default};
attrs.kerning = {name = 'kerning', parser = default};
attrs.keyPoints = {name = 'keyPoints', parser = default};
attrs.keySplines = {name = 'keySplines', parser = default};
attrs.keyTimes = {name = 'keyTimes', parser = default};

attrs.lang = {name = 'lang', parser = default};
attrs.lengthAdjust = {name = 'lengthAdjust', parser = default};
attrs.letter_spacing = {name = 'letter-spacing', parser = default};
attrs.lighting_color = {name = 'lighting-color', parser = color};
attrs['lighting-color'] = attrs.lighting_color;
attrs.limitingConeAngle = {name = 'limitingConeAngle', parser = default};
attrs['local'] = {name = 'local', parser = default};

attrs.marker_end = {name = 'marker-end', parser = default};
attrs['marker-end'] = attrs.marker_end;
attrs.marker_mid = {name = 'marker_mid', parser = default};
attrs['marker-mid'] = attrs.marker_mid;
attrs.marker_start = {name = 'marker_start', parser = default};
attrs['marker-start'] = attrs.marker_start;
attrs.markerHeight = {name = 'markerHeight', parser = default};
attrs.markerUnits = {name = 'markerUnits', parser = default};
attrs.markerWidth = {name = 'markerWidth', parser = default};
attrs.mask = {name = 'mask', parser = default};
attrs.maskContentUnits = {name = 'maskContentUnits', parser = default};
attrs.maskUnits = {name = 'maskUnits', parser = default};
attrs.mathematical = {name='mathematical', parser=number};
attrs.max = {name = 'max', parser = default};
attrs.media = {name = 'media', parser = default};
attrs.method = {name = 'method', parser = default};
attrs.min = {name = 'min', parser = default};
attrs.mode = {name = 'mode', parser = default};

attrs.name = {name = 'name', parser = default};
attrs.numOctaves = {name = 'numOctaves', parser = default};

attrs.offset = {name = 'offset', parser = default};
attrs.onabort = {name = 'onabort', parser = default};
attrs.onactivate = {name = 'onactivate', parser = default};
attrs.onbegin = {name = 'onbegin', parser = default};
attrs.onclick = {name = 'onclick', parser = default};
attrs.onend = {name = 'onend', parser = default};
attrs.onerror = {name = 'onerror', parser = default};
attrs.onfocusin = {name = 'onfocusin', parser = default};
attrs.onfocusout = {name = 'onfocusout', parser = default};
attrs.onload = {name = 'onload', parser = default};
attrs.onmousedown = {name = 'onmousedown', parser = default};
attrs.onmousemove = {name = 'onmousemove', parser = default};
attrs.onmouseout = {name = 'onmouseout', parser = default};
attrs.onmouseover = {name = 'onmouseover', parser = default};
attrs.onmouseup = {name = 'onmouseup', parser = default};
attrs.onrepeat = {name = 'onrepeat', parser = default};
attrs.onresize = {name = 'onresize', parser = default};
attrs.onscroll = {name = 'onscroll', parser = default};
attrs.onunload = {name = 'onunload', parser = default};
attrs.onzoom = {name = 'onzoom', parser = default};
attrs.opacity = {name = 'opacity', parser = opacity};
attrs.operator = {name = 'operator', parser = default};
attrs.order = {name = 'order', parser = default};
attrs.orient = {name = 'orient', parser = default};
attrs.orientation = {name = 'orientation', parser = default};
attrs.origin = {name = 'origin', parser = default};
attrs.overflow = {name = 'overflow', parser = default};
attrs.overline_position = {name = 'overline-position', parser = number};
attrs['overline-position'] = attrs.overline_position;
attrs.overline_thickness = {name = 'overline-thickness', parser = number};
attrs['overline-thickness'] = attrs.overline_thickness;

attrs.panose_1 = {name = 'panose-1', parser = default};
attrs['panose-1'] = attrs.panose_1;
attrs.paint_order = {name = 'paint-order', parser = default};
attrs['paint-order'] = attrs.paint_order;
attrs.pathLength = {name = 'pathLength', parser = default};
attrs.patternContentUnits = {name = 'patternContentUnits', parser = default};
attrs.patternTransform = {name = 'patternTransform', parser = default};
attrs.patternUnits = {name = 'patternUnits', parser = default};
attrs.pointer_events = {name = 'pointer-events', parser = default};
attrs['pointer-events'] = attrs.pointer_events;
attrs.points = {name = 'points', parser = default};
attrs.pointsAtX = {name = 'pointsAtX', parser = default};
attrs.pointsAtY = {name = 'pointsAtY', parser = default};
attrs.pointsAtZ = {name = 'pointsAtZ', parser = default};
attrs.preserveAlpha = {name = 'preserveAlpha', parser = default};
attrs.preserveAspectRatio = {name = 'preserveAspectRatio', parser = default};
attrs.primitiveUnits = {name = 'primitiveUnits', parser = default};

attrs.r = {name = 'r', parser = default};
attrs.radius = {name = 'radius', parser = default};
attrs.refX = {name = 'refX', parser = default};
attrs.refY = {name = 'refY', parser = default};
attrs.rendering_intent = {name = 'rendering-intent', parser = default};
attrs['rendering-intent'] = attrs.rendering_intent;
attrs.repeatCount = {name = 'repeatCount', parser = default};
attrs.repeatDur = {name = 'repeatDur', parser = default};
attrs.requiredExtensions = {name = 'requiredExtensions', parser = default};
attrs.requiredFeatures = {name = 'requiredFeatures', parser = default};
attrs.restart = {name = 'restart', parser = default};
attrs.result = {name = 'result', parser = default};
attrs.rotate = {name = 'rotate', parser = default};
attrs.rx = {name='rx', parser=length};
attrs.ry = {name='ry', parser=length};

attrs.scale = {name = 'scale', parser = number};
attrs.seed = {name = 'seed', parser = number};
attrs.shape_rendering = {name = 'shape-rendering', parser = default};
attrs['shape-rendering'] = attrs.shape_rendering;
attrs.slope = {name='slope', parser=number};
attrs.spacing = {name = 'spacing', parser = default};
attrs.specularConstant = {name = 'specularConstant', parser = default};
attrs.specularExponent = {name = 'specularExponent', parser = default};
attrs.speed = {name = 'speed', parser = default};
attrs.spreadMethod = {name = 'spreadMethod', parser = default};
attrs.startOffset = {name = 'startOffset', parser = default};
attrs.stdDeviation = {name = 'stdDeviation', parser = default};
attrs.stemh = {name='stemh', parser = number};
attrs.stemv = {name = 'stemv', parser=number};
attrs.stitchTiles = {name = 'stitchTiles', parser = default};
attrs.stop_color = {name='stop-color', parser=color};
attrs['stop-color'] = color;
attrs.stop_opacity = {name = 'stop-opacity', parser = opacity};
attrs['stop-opacity'] = attrs.stop_opacity;
attrs.strikethrough_position = {name = 'strikethrough-position', parser = number};
attrs['strikethrough-position'] = attrs.strikethrough_position;
attrs.strikethrough_thickness = {name = 'strikethrough-thickness', parser = number};
attrs['strikethrough-thickness'] = attrs.strikethrough_thickness;
attrs.string = {name = 'string', parser = default};
attrs.stroke = {name='stroke', parser=paint};
attrs.stroke_dasharray = {name = 'stroke-dasharray', parser = default};
attrs['stroke-dasharray'] = attrs.stroke_dasharray;
attrs.stroke_dashoffset = {name = 'stroke-dashoffset', parser = default};
attrs['stroke-dashoffset'] = attrs.stroke_dashoffset;
attrs.stroke_linecap = {name = 'stroke-linecap', parser = default};
attrs['stroke-linecap'] = attrs.stroke_linecap;
attrs.stroke_miterlimit = {name = 'stroke-miterlimit', parser = default};
attrs['stroke-miterlimit'] = attrs.stroke_miterlimit;
attrs.stroke_opacity = {name = 'stroke-opacity', parser = opacity};
attrs['stroke-opacity'] = attrs.stroke_opacity;
attrs.stroke_width = {name = 'stroke-width', parser = length};
attrs['stroke-width'] = attrs.stroke_width;
attrs.style = {name = 'style', parser = default};
attrs.surfaceScale = {name = 'surfaceScale', parser = default};
attrs.systemLanguage = {name = 'systemLanguage', parser = default};

attrs.tableValues = {name = 'tableValues', parser = default};
attrs.target = {name = 'target', parser = default};
attrs.targetX = {name = 'targetX', parser = default};
attrs.targetY = {name = 'targetY', parser = default};
attrs.text_anchor = {name = 'text-anchor', parser = default};
attrs['text-anchor'] = attrs.text_anchor;
attrs.text_decoration = {name = 'text-decoration', parser = default};
attrs['text-decoration'] = attrs.text_decoration;
attrs.text_rendering = {name = 'text-rendering', parser = default};
attrs['text-rendering'] = attrs.text_rendering;
attrs.textLength = {name = 'textLength', parser = default};
attrs.to = {name = 'to', parser = default};
attrs.transform = {name = 'transform', parser = default};
attrs['type'] = {name = 'type', parser = default};

attrs.u1 = {name = '', parser = default};
attrs.u2 = {name = '', parser = default};
attrs.underline_position = {name = 'underline-position', parser = number};
attrs['underline-position'] = attrs.underline_position;
attrs.underline_thickness = {name = 'underline-thickness', parser = number};
attrs['underline-thickness'] = attrs.underline_thickness;
attrs.unicode = {name = 'unicode', parser = default};
attrs.unicode_bidi = {name = 'unicode-bidi', parser = default};
attrs['unicode-bidi'] = attrs.unicode_bidi;
attrs.unicode_range = {name = 'unicode-range', parser = default};
attrs['unicode-range'] = attrs.unicode_range;
attrs.units_per_em = {name = 'units-per-em', parser = number};
attrs['units-per-em'] = attrs.units_per_em;

attrs.v_alphabetic = {name = 'v-alphabetic', parser = number};
attrs['v-alphabetic'] = attrs.v_alphabetic;
attrs.v_hanging = {name = 'v-hanging', parser = number};
attrs['v-hanging'] = attrs.v_hanging;
attrs.v_ideographic = {name = 'v-ideographic', parser = number};
attrs['v-ideographic'] = attrs.v_ideographic;
attrs.v_mathematical = {name = 'v-mathematical', parser = default};
attrs['v-mathematical'] = attrs.v_mathematical;
attrs.values = {name = 'values', parser = default};
attrs.version = {name = 'version', parser = default};
attrs.vert_adv_y = {name = 'v-adv-y', parser = default};
attrs['vert-adv-y'] = attrs.vert_adv_y;
attrs.vert_origin_x = {name = 'v-origin-x', parser = default};
attrs['vert-origin-x'] = attrs.v_origin_x;
attrs.vert_origin_y = {name = 'vert-origin-y', parser = default};
attrs['vert-origin-y'] = attrs.vert_origin_y;
attrs.viewBox = {name = 'viewBox', parser = viewBox};
attrs.visibility = {name = 'visibility', parser = default};

attrs.width = {name = 'width', parser = length};
attrs.widths = {name = 'widths', parser = default};
attrs.word_spacing = {name = 'word-spacing', parser = default};
attrs['word-spacing'] = attrs.word_spacing;
attrs.writing_mode = {name = 'writing-mode', parser = default};
attrs['writing-mode'] = attrs.writing_mode;

attrs.x = {name='x', parser=coord};
attrs.x_height = {name='x-height', parser=number};
attrs['x-height'] = attrs.x_height;
attrs.x1 = {name='x1', parser=coord};
attrs.x2 = {name='x2', parser=coord};
attrs.xChannelSelector = {name = 'xChannelSelector', parser = default};
attrs.xlink_actuate = {name = 'xlink:actuate', parser = default};
attrs['xlink:actuate'] = attrs.xlink_actuate;
attrs.xlink_arcrole = {name = 'xlink:arcrole', parser = default};
attrs['xlink:arcrole'] = attrs.xlink_arcrole;
attrs.xlink_href = {name='xlink:href', parser=default};
attrs['xlink:href'] = attrs.xlink_href;
attrs.xlink_role = {name = 'xlink:role', parser = default};
attrs['xlink:role'] = attrs.xlink_role;
attrs.xlink_show = {name = 'xlink:show', parser = default};
attrs['xlink:show'] = attrs.xlink_show;
attrs.xlink_title = {name = 'xlink:title', parser = default};
attrs['xlink:title'] = attrs.xlink_title;
attrs.xlink_type = {name = 'xlink:type', parser = default};
attrs['xlink:type'] = attrs.xlink_type;
attrs.xml_base = {name = 'xml:base', parser = default};
attrs['xml:base'] = attrs.xml_base;
attrs.xml_lang = {name = 'xml:lang', parser = default};
attrs['xml:lang'] = attrs.xml_lang;
attrs.xml_space = {name = 'xml:space', parser = default};
attrs['xml:space'] = attrs.xml_space;

attrs.y = {name = 'y', parser = coord};
attrs.y1 = {name = 'y1', parser = coord};
attrs.y2 = {name = 'y2', parser = coord};
attrs.yChannelSelector = {name = 'yChannelSelector', parser = default};

attrs.z = {name = 'z', parser = coord};
attrs.zoomAndPan = {name = 'zoomAndPan', parser = default};


function attrs.parseAttribute(name, value, strict)
	--print("parseAttribute: ", name, value)
	local func = attrs[name];

	if not func then
		if not strict then
			-- Be permissive, if the name is not found,
			-- just return what was passed in
			return name, value;
		else
			-- If we're being strict, then we don't 
			-- return anything if it's not a valid attribute name
			return nil
		end
	end

--print("parseAttribute (func.name, func.parser): ", func.name, func.parser)
	return func.parser(func.name, value, strict)
end

return attrs;
