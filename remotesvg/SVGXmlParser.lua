-- Simple XML parser
local ffi = require("ffi")

local ctypes = require("remotesvg.ctypes")

local isspace = ctypes.isspace;

local NSVG_XML_TAG = 1;
local NSVG_XML_CONTENT = 2;
local NSVG_XML_MAX_ATTRIBS = 256;

local function parseContent(s, markoffset, endoffset, contentCb, ud)
	-- Trim start white spaces
	local soffset = markoffset;

	-- skip leading whitespace
	while (soffset < endoffset and isspace(s[soffset])) do 
		soffset = soffset + 1;
	end

	if soffset == endoffset then
		return nil;
	end
	
	if (contentCb) then
		contentCb(ud, ffi.string(s+soffset, endoffset-soffset));
	end
end


-- void (startelCb)(any ud, string name, table attr)
-- void (endelCb)(any ud, string name)

-- void * ud
-- Some user supplied data that just gets passed along

local function parseElement(s, startoffset, endoffset, startelCb, endelCb, ud)
	local attr = {};
	local start = false;
	local ending = false;
	local quote = nil;
	local soffset = startoffset;

	-- Skip white space after the '<'
	while (soffset < endoffset and isspace(s[soffset])) do
		soffset = soffset + 1;
	end

	-- Check if the tag is end tag
	if s[soffset] == string.byte('/') then
		soffset = soffset + 1;
		ending = true;
	else 
		start = true;
	end

	-- Skip comments, data and preprocessor stuff.
	if soffset == endoffset or s[soffset] == string.byte('?') or s[soffset] == string.byte('!') then
		return;
	end


	-- Get tag name
	local nameoffset = soffset;
	local nameendoffset = nameoffset;

	while (soffset < endoffset) and (not isspace(s[soffset])) do
		soffset = soffset + 1;
	end

	nameendoffset = soffset;
	if (soffset < endoffset) then
		soffset = soffset + 1; 
	end
	
	-- turn it into a lua string
	local namelen = nameendoffset - nameoffset;
	--print("TAG name len: ", nameoffset, nameendoffset, namelen)
	local name = ffi.string(s+nameoffset, namelen)

	-- Get attribs
	while (not ending and (soffset < endoffset) ) do
		-- Skip white space before the attrib name
		while (soffset < endoffset and isspace(s[soffset])) do
			soffset = soffset + 1;
		end

		if (soffset == endoffset) then
			break;
		end

		if s[soffset] == string.byte('/') then
			ending = true;
			break;
		end

		local attrnamemark = soffset;
		local attrnameend = soffset;

		-- Find end of the attrib name.
		while soffset < endoffset and not isspace(s[soffset]) and s[soffset] ~= string.byte('=') do
			soffset = soffset + 1;
		end

		if (soffset < endoffset) then
			attrnameend = soffset;
			soffset = soffset + 1;
		end
		
		-- Skip until the beginning of the value.
		while soffset < endoffset and s[soffset] ~= string.byte('\"') and s[soffset] ~= string.byte('\'') do
			soffset = soffset + 1;
		end

		if (s[soffset] == 0) then
			break;
		end

		quote = s[soffset];
		soffset = soffset + 1;
		
		-- Store value and find the end of it.
		local attrvaluemark = soffset;
		local attrvaluemarkend = soffset;

		while (soffset < endoffset and s[soffset] ~= quote) do
			soffset = soffset + 1; 
		end

		attrvaluemarkend = soffset;
		if (soffset < endoffset) then 
			soffset = soffset + 1;
		end

		-- store attribute as a key value pair
		attr[ffi.string(s+attrnamemark, attrnameend-attrnamemark)] = ffi.string(s+attrvaluemark, attrvaluemarkend-attrvaluemark);
	end

	-- Call callbacks.
	if (start and startelCb) then
		startelCb(ud, name, attr);
	end

	if (ending and endelCb) then
		endelCb(ud, name);
	end
end


local function parseXML(input, startelCb, endelCb, contentCb, ud)
	local s = ffi.cast("const char *", input);
	local soffset = 0;
	local markoffset = soffset;
	local markoffsetend = soffset;

	local state = NSVG_XML_CONTENT;

	while s[soffset] ~= 0 do
		if (s[soffset] == string.byte('<')) and (state == NSVG_XML_CONTENT) then
			-- Start of a tag
			markoffsetend = soffset;
			soffset = soffset + 1;

			parseContent(s, markoffset, markoffsetend, contentCb, ud);
			markoffset = soffset;
			markoffsetend = markoffset;

			state = NSVG_XML_TAG;
		elseif (s[soffset] == string.byte('>')) and (state == NSVG_XML_TAG) then
			-- Start of a content or new tag.
			markoffsetend = soffset;

			soffset = soffset + 1;

			parseElement(s, markoffset, markoffsetend, startelCb, endelCb, ud);
			markoffset = soffset;
			markoffsetend = markoffset;

			state = NSVG_XML_CONTENT;
		else
			soffset = soffset + 1; 
		end
	end

	return true;
end


return {
	parseXML = parseXML;
}