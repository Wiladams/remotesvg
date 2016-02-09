#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGStream = require("remotesvg.SVGStream")
local SVGGeometry = require("remotesvg.SVGGeometry")
local svg = SVGGeometry.SVG;
local rect = SVGGeometry.Rect;
local line = SVGGeometry.Line;


local width = 640;
local height = 480;
local mstream = size(width, height)
local ImageStream = SVGStream(mstream);


function mouseDown(activity)
	print("mouseDown: ", activity.which)
end

function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

local function draw(strm)
	strm:reset();

	local doc = svg({width = "12cm", height= "4cm", viewBox="0 0 1200 400"})

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


	doc:addShape(r1);
	doc:addShape(l1);
	doc:addShape(l2);
	doc:addShape(l3);
	doc:addShape(l4);
	doc:addShape(l5);


	doc:write(strm);
end



function frame()
	draw(ImageStream);
end

run()
