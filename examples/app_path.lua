#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
require("remotesvg.SVGElements")()

local ImageStream = size()


function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

--[[

--]]
local function draw(ImageStream)
	ImageStream:reset();

	local p1 = path {
		fill="red", 
		stroke="blue", 
		["stroke-width"]=3
	};
	
	p1:moveTo(100, 100);
	p1:lineTo(300, 100);
	p1:lineTo(200, 300);
	p1:close();

	local doc = svg {
		width="4cm", 
		height="4cm", 
		viewBox="0 0 400 400",
		--onload="alert('svg loaded');";
		
		rect {
			x="1", y="1", 
			width="398", height="398",
        	fill="none", stroke="blue"};
	
		p1;
	}

	doc:write(ImageStream);
end

draw(ImageStream);
run();

--[[
function frame()
	draw(ImageStream);
end

frameInterval(3000);
run()
--]]
