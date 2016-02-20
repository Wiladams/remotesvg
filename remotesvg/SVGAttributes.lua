
-- References
-- https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute
--
local colors = require("remotesvg.colors")
local RGB = colors.RGBA;

local tonumber = tonumber;
local tostring = tostring;


local function paint(name, value, strict)
	local function parseColorName(name)
		return colors.svg[name] or RGB(128, 128, 128);
	end
	
	local function parseColorHex(self, s)
		--print(".parseColorHex: ", s)

		local rgb = s:match("#(%g+)")
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

	local str = value:match("%s*(.*)")
	local len = #str;
	
	--	print("SVGParser.parseColor: ", str, len)
	if len >= 1 and str:sub(1,1) == '#' then
		value = parseColorHex(str);
	elseif (len >= 4 and str:match("rgb%(")) then
		value = parseColorRGB(str);
	else
		value = parseColorName(str);
	end

	return name, value
end

local function coord(name, value, strict)
	if type(value) ~= "string" then
		return name, value;
	end
	
	local num, units = value:match("(%d*%.?%d*)(.*)")

	num = tonumber(num);

	return name, num, units
end

-- Individual functions which deal with specific
-- attributes
local attrs = {}

-- This is the function to be used when we don't have 
-- any specific specialization for an attribute
function attrs._default(name, value, strict)
print("attrs._default: ", name, value);

	return name, value
end


attrs.accent_height = coord
attrs.accumulate = attrs._default;
attrs.additive = attrs._default;
attrs.alignment_baseline = attrs._default;
attrs.allowReorder = attrs._default;
attrs.alphabetic = attrs._default;
attrs.amplitude = attrs._default;
attrs.arabic_form = attrs._default;
attrs.ascent = attrs._default;
attrs.attributeName = attrs._default;
attrs.attributeType = attrs._default;
attrs.autoReverse = attrs._default;
attrs.azimuth = attrs._default;

attrs.baseFrequency = attrs._default;
attrs.baseline_shift = attrs._default;
attrs.baseProfile = attrs._default;
attrs.bbox = attrs._default;
attrs.begin = attrs._default;
attrs.bias = attrs._default;
attrs.by = attrs._default;

attrs.calcMode = attrs._default;
attrs.class = attrs._default;
attrs.clip = attrs._default;
attrs.clipPathUnits = attrs._default;
attrs.clip_path = attrs._default;
attrs.clip_rule = attrs._default;
attrs.color = attrs._default;
attrs.color_interpolation = attrs._default;
attrs.color_interpolation_filters = attrs._default;
attrs.color_profile = attrs._default;
attrs.color_rendering = attrs._default;
attrs.contentScriptType = attrs._default;
attrs.contentStyleType = attrs._default;
attrs.cursor = attrs._default;
attrs.cx = coord;
attrs.cy = coord;

attrs.d = attrs._default;
attrs.decelerate = attrs._default;
attrs.descent = attrs._default;
attrs.diffuseConstant = attrs._default;
attrs.direction = attrs._default;
attrs.display = attrs._default;
attrs.divisor = attrs._default;
attrs.dominant_baseline = attrs._default;
attrs.dur = attrs._default;
attrs.dx = coord;
attrs.dy = coord;

attrs.edgeMode = attrs._default;
attrs.elevation = attrs._default;
attrs.enable_background = attrs._default;
attrs['enable-background'] = attrs._default;
attrs['end'] = attrs._default;
attrs.exponent = attrs._default;
attrs.externalResourcesRequired = attrs._default;

attrs.fill = paint;
attrs.fill_opacity = attrs._default;
attrs['fill-opacity'] = attrs._default;
attrs.fill_rule = attrs._default;
attrs.filter = attrs._default;
attrs.filterRes = attrs._default;
attrs.filterUnits = attrs._default;
attrs.flood_color = attrs._default;
attrs.flood_opacity = attrs._default;
attrs.font_family = attrs._default;
attrs.font_size = attrs._default;
attrs.font_size_adjust = attrs._default;
attrs.font_stretch = attrs._default;
attrs.font_style = attrs._default;
attrs.font_variant = attrs._default;
attrs.font_weight = attrs._default;
attrs.format = attrs._default;
attrs.from = attrs._default;
attrs.fx = attrs._default;
attrs.fy = attrs._default;

attrs.g1 = attrs._default;
attrs.g2 = attrs._default;
attrs.glyph_name = attrs._default;
attrs.glyph_orientation_horizontal = attrs._default;
attrs.glyph_orientation_vertical = attrs._default;
attrs.glyphRef = attrs._default;
attrs.gradientTransform = attrs._default;
attrs.gradientUnits = attrs._default;

attrs.hanging = attrs._default;
attrs.height = coord;
attrs.horiz_adv_x = attrs._default;
attrs.horiz_origin_x = attrs._default;
attrs['horiz-origin-x'] = attrs._default;

attrs.id = attrs._default;
attrs.ideographic = attrs._default;
attrs.image_rendering = attrs._default;
attrs['in'] = attrs._default;
attrs.in2 = attrs._default;
attrs.intercept = attrs._default;

attrs.k = attrs._default;
attrs.k1 = attrs._default;
attrs.k2 = attrs._default;
attrs.k3 = attrs._default;
attrs.k4 = attrs._default;
attrs.kernelMatrix = attrs._default;
attrs.kernelUnitLength = attrs._default;
attrs.kerning = attrs._default;
attrs.keyPoints = attrs._default;
attrs.keySplines = attrs._default;
attrs.keyTimes = attrs._default;

attrs.lang = attrs._default;
attrs.lengthAdjust = attrs._default;
attrs.letter_spacing = attrs._default;
attrs.lighting_color = attrs._default;
attrs.limitingConeAngle = attrs._default;
attrs['local'] = attrs._default;

attrs.marker_end = attrs._default;
attrs['marker-end'] = attrs._default;
attrs.marker_mid = attrs._default;
attrs['marker-mid'] = attrs._default;
attrs.marker_start = attrs._default;
attrs['marker-start'] = attrs._default;
attrs.markerHeight = attrs._default;
attrs.markerUnits = attrs._default;
attrs.markerWidth = attrs._default;
attrs.mask = attrs._default;
attrs.maskContentUnits = attrs._default;
attrs.maskUnits = attrs._default;
attrs.mathematical = attrs._default;
attrs.max = attrs._default;
attrs.media = attrs._default;
attrs.method = attrs._default;
attrs.min = attrs._default;
attrs.mode = attrs._default;

attrs.name = attrs._default;
attrs.numOctaves = attrs._default;

attrs.offset = attrs._default;
attrs.onabort = attrs._default;
attrs.onactivate = attrs._default;
attrs.onbegin = attrs._default;
attrs.onclick = attrs._default;
attrs.onend = attrs._default;
attrs.onerror = attrs._default;
attrs.onfocusin = attrs._default;
attrs.onfocusout = attrs._default;
attrs.onload = attrs._default;
attrs.onmousedown = attrs._default;
attrs.onmousemove = attrs._default;
attrs.onmouseout = attrs._default;
attrs.onmouseover = attrs._default;
attrs.onmouseup = attrs._default;
attrs.onrepeat = attrs._default;
attrs.onresize = attrs._default;
attrs.onscroll = attrs._default;
attrs.onunload = attrs._default;
attrs.onzoom = attrs._default;
attrs.opacity = attrs._default;
attrs.operator = attrs._default;
attrs.order = attrs._default;
attrs.orient = attrs._default;
attrs.orientation = attrs._default;
attrs.origin = attrs._default;
attrs.overflow = attrs._default;
attrs.overline_position = attrs._default;
attrs['overline-position'] = attrs._default;
attrs.overline_thickness = attrs._default;
attrs['overline-thickness'] = attrs._default;

attrs.panose_1 = attrs._default;
attrs['panose-1'] = attrs._default;
attrs.paint_order = attrs._default;
attrs['paint-order'] = attrs._default;
attrs.pathLength = attrs._default;
attrs.patternContentUnits = attrs._default;
attrs.patternTransform = attrs._default;
attrs.patternUnits = attrs._default;
attrs.pointer_events = attrs._default;
attrs['pointer-events'] = attrs._default;
attrs.points = attrs._default;
attrs.pointsAtX = attrs._default;
attrs.pointsAtY = attrs._default;
attrs.pointsAtZ = attrs._default;
attrs.preserveAlpha = attrs._default;
attrs.preserveAspectRatio = attrs._default;
attrs.primitiveUnits = attrs._default;

attrs.r = attrs._default;
attrs.radius = attrs._default;
attrs.refX = attrs._default;
attrs.refY = attrs._default;
attrs.rendering_intent = attrs._default;
attrs['rendering-intent'] = attrs._default;
attrs.repeatCount = attrs._default;
attrs.repeatDur = attrs._default;
attrs.requiredExtensions = attrs._default;
attrs.requiredFeatures = attrs._default;
attrs.restart = attrs._default;
attrs.result = attrs._default;
attrs.rotate = attrs._default;
attrs.rx = coord;
attrs.ry = coord;

attrs.scale = attrs._default;
attrs.seed = attrs._default;
attrs.shape_rendering = attrs._default;
attrs['shape-rendering'] = attrs._default;
attrs.slope = attrs._default;
attrs.spacing = attrs._default;
attrs.specularConstant = attrs._default;
attrs.specularExponent = attrs._default;
attrs.speed = attrs._default;
attrs.spreadMethod = attrs._default;
attrs.startOffset = attrs._default;
attrs.stdDeviation = attrs._default;
attrs.stemh = attrs._default;
attrs.stemv = attrs._default;
attrs.stitchTiles = attrs._default;
attrs['stop-color'] = function(name, value, strict) return paint('stop-color', value, strict) end
attrs.stop_color = function(name, value, strict) return attrs['stop-color'](name, value, strict); end
attrs['stop-opacity'] = attrs._default;
attrs.stop_opacity = attrs._default;
attrs['strikethrough-position'] = attrs._default;
attrs.strikethrough_position = attrs._default;
attrs['strikethrough-thickness'] = attrs._default;
attrs.strikethrough_thickness = attrs._default;
attrs.string = attrs._default;
attrs.stroke = paint;
attrs.stroke_dasharray = attrs._default;
attrs['stroke-dasharray'] = attrs._default;
attrs.stroke_dashoffset = attrs._default;
attrs['stroke-dashoffset'] = attrs._default;
attrs.stroke_linecap = attrs._default;
attrs['stroke-linecap'] = attrs._default;
attrs.stroke_miterlimit = attrs._default;
attrs['stroke-miterlimit'] = attrs._default;
attrs.stroke_opacity = attrs._default;
attrs['stroke-opacity'] = attrs._default;
attrs.stroke_width = attrs._default;
attrs['stroke-width'] = attrs._default;
attrs.style = attrs._default;
attrs.surfaceScale = attrs._default;
attrs.systemLanguage = attrs._default;

attrs.tableValues = attrs._default;
attrs.target = attrs._default;
attrs.targetX = attrs._default;
attrs.targetY = attrs._default;
attrs.text_anchor = attrs._default;
attrs['text-anchor'] = attrs._default;
attrs.text_decoration = attrs._default;
attrs['text-decoration'] = attrs._default;
attrs.text_rendering = attrs._default;
attrs['text-rendering'] = attrs._default;
attrs.textLength = attrs._default;
attrs.to = attrs._default;
attrs.transform = attrs._default;
attrs['type'] = attrs._default;

attrs.u1 = attrs._default;
attrs.u2 = attrs._default;
attrs.underline_position = attrs._default;
attrs['underline-position'] = attrs._default;
attrs.underline_thickness = attrs._default;
attrs['underline-thickness'] = attrs._default;
attrs.unicode = attrs._default;
attrs.unicode_bidi = attrs._default;
attrs['unicode-bidi'] = attrs._default;
attrs.unicode_range = attrs._default;
attrs['unicode-range'] = attrs._default;
attrs.units_per_em = attrs._default;
attrs['units-per-em'] = attrs._default;

attrs.v_alphabetic = attrs._default;
attrs['v-alphabetic'] = attrs._default;
attrs.v_hanging = attrs._default;
attrs['v-hanging'] = attrs._default;
attrs.v_ideographic = attrs._default;
attrs['v-ideographic'] = attrs._default;
attrs.v_mathematical = attrs._default;
attrs['v-mathematical'] = attrs._default;
attrs.values = attrs._default;
attrs.version = attrs._default;
attrs.vert_adv_y = attrs._default;
attrs['vert-adv-y'] = attrs._default;
attrs.vert_origin_x = attrs._default;
attrs['vert-origin-x'] = attrs._default;
attrs.vert_origin_y = attrs._default;
attrs['vert-origin-y'] = attrs._default;
attrs.viewBox = attrs._default;
attrs.visibility = attrs._default;

attrs.width = coord;
attrs.widths = attrs._default;
attrs.word_spacing = attrs._default;
attrs['word-spacing'] = attrs._default;
attrs.writing_mode = attrs._default;
attrs['writing-mode'] = attrs._default;

attrs.x = coord;
attrs['x-height'] = attrs._default;
attrs.x_height = function(name, value, strict) return attrs['x-height'](name, value, strict); end
attrs.x1 = coord;
attrs.x2 = coord;
attrs.xChannelSelector = attrs._default;
attrs['xlink:actuate'] = attrs._default;
attrs.xlink_actuate = attrs._default;
attrs['xlink:arcrole'] = attrs._default;
attrs.xlink_arcrole = attrs._default;
attrs['xlink:href'] = attrs._default;
attrs.xlink_href = attrs._default;
attrs['xlink:role'] = attrs._default;
attrs.xlink_role = attrs._default;
attrs['xlink:show'] = attrs._default;
attrs.xlink_show = attrs._default;
attrs['xlink:title'] = attrs._default;
attrs.xlink_title = attrs._default;
attrs['xlink:type'] = attrs._default;
attrs.xlink_type = attrs._default;
attrs['xml:base'] = attrs._default;
attrs.xml_base = attrs._default;
attrs['xml:lang'] = attrs._default;
attrs.xml_lang = attrs._default;
attrs['xml:space'] = attrs._default;
attrs.xml_space = attrs._default;

attrs.y = coord;
attrs.y1 = coord;
attrs.y2 = coord;
attrs.yChannelSelector = attrs._default;

attrs.z = attrs._default;
attrs.zoomAndPan = attrs._default;


function attrs.parseAttribute(name, value, strict)
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

	return func(name, value, strict)
end

return attrs;
