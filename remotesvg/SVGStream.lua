--SVGStream.lua

local SVGStream = {}
setmetatable(SVGStream, {
	__call = function(self, ...)
		return self:new(...)
	end,
	})
local SVGStream_mt = {
	__index = SVGStream;
}

function SVGStream.init(self, baseStream)
	local obj = {
		BaseStream = baseStream;
		TopElement = {};
		Elements = {};
	}
	setmetatable(obj, SVGStream_mt);

	return obj;
end

function SVGStream.new(self, baseStream)
	return self:init(baseStream);
end


function SVGStream.reset(self)
	--strm:write('<?xml version="1.0" standalone="no"?>\n');

	return self.BaseStream:reset();
end


function SVGStream.openElement(self, elName)
	self.CurrentOpenTag = elName;
	self.BaseStream:writeString("<"..elName)
end

function SVGStream.closeTag(self)
	self.BaseStream:writeString(">\n")
	self.CurrentOpenTag = nil;
end


function SVGStream.addAttribute(self, name, value)
	self.BaseStream:writeString(" "..name..' = "'..value..'"');
end

function SVGStream.closeElement(self, elName)
	if elName then
		self.BaseStream:writeString("</"..elName..">\n");
	else
		self.BaseStream:writeString(" />\n");
	end
end

function SVGStream.write(self, str)
	self.BaseStream:writeString(str);
end

return SVGStream
