#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGGeometry = require("remotesvg.SVGGeometry")()


local ImageStream = size()


function mouseDown(activity)
	print("mouseDown: ", activity.which)
end

function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

local function draw(strm)
	strm:reset();

	local doc = svg {
		width = "12cm", 
		height= "4cm", 
		viewBox="0 0 1200 400",
	}

	local r1 = rect({
		x = 1;
		y = 1;
		width = 1198;
		height = 398;
		fill = "none";
		stroke = "blue";
		["stroke-width"] = 2;
	});

   local l1 = line({x1=100, y1=300, x2=300, y2=100, stroke = "green", ["stroke-width"]=5});
   local l2 = line({x1=300, y1=300, x2=500, y2=100, stroke = "green", ["stroke-width"]=20});
   local l3 = line({x1=500, y1=300, x2=700, y2=100, stroke = "green", ["stroke-width"]=25});
   local l4 = line({x1=700, y1=300, x2=900, y2=100, stroke = "green", ["stroke-width"]=20});
   local l5 = line({x1=900, y1=300, x2=1100, y2=100, stroke = "green", ["stroke-width"]=25});


	doc:append(r1);
	doc:append(l1);
	doc:append(l2);
	doc:append(l3);
	doc:append(l4);
	doc:append(l5);


	doc:write(strm);
end


draw(ImageStream);

run()
