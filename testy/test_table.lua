local tbl = {
	name1 = "value1";
	name2 = "value2";

	[[
		some text here
	]];

	name3 = "value3";

	[[
		followed by more text
	]];

	name4 = "value4";
}

for name, value in pairs(tbl) do
	print(name, value);
end

for idx, value in ipairs(tbl) do
	print(idx, value);
end

