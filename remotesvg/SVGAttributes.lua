
local attrNames = {
	['accent-height'] = 'accent_height',
	['alignment-baseline'] = 'alignment_baseline',
	['arabic-form'] = 'arabic_form',

	['baseline-shift'] = 'baseline_shift',
	['cap-height'] = 'cap_height',
	['clip-path'] = 'clip_path',
	['clip-rule'] = 'clip_rule',
	['color-interpolation'] = 'color_interpolation',
	['color-profile'] = 'color_profile',
	['color-rendering'] = 'color_rendering',

}

-- Individual functions which deal with specific
-- attributes
local attrs = {}

function attrs._default(param)
	return param
end

attrs.accent_height = attrs._default;
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
attrs.cx = attrs._default;
attrs.cy = attrs._default;

attrs.d = attrs._default;
attrs.decelerate = attrs._default;
attrs.descent = attrs._default;
attrs.diffuseConstant = attrs._default;
attrs.direction = attrs._default;
attrs.display = attrs._default;
attrs.divisor = attrs._default;
attrs.dominant_baseline = attrs._default;
attrs.dur = attrs._default;
attrs.dx = attrs._default;
attrs.dy = attrs._default;

attrs.edgeMode = attrs._default;
attrs.elevation = attrs._default;
attrs.enable_background = attrs._default;
attrs['end'] = attrs._default;
attrs.exponent = attrs._default;
attrs.externalResourcesRequired = attrs._default;

attrs.fill = attrs._default;
attrs.fill_opacity = attrs._default;
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
attrs.height = attrs._default;
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
