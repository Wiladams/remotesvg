local function isspace(c)
	return c == string.byte(' ') or
		c == string.byte('\t') or 
		c == string.byte('\n') or
		c == string.byte('\v') or
		c == string.byte('\f') or
		c == string.byte('\r')
end


local function isdigit(c)
	return c >= string.byte('0') and
		c <= string.byte('9')
end

local function isnum(c)
	return isdigit(c) or
		c == string.byte('+') or
		c == string.byte('-') or
		c == string.byte('e') or
		c == string.byte('E')
end

return {
	isspace = isspace;
	isdigit = isdigit;
	isnum = isnum;
}