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

-- This one will print all the things in the table
-- with the literals having a key type that is numeric
for name, value in pairs(tbl) do
	print(name, value);
end

-- This one will only print the literals, starting
-- from an index of '1'
for idx, value in ipairs(tbl) do
	print(idx, value);
end

