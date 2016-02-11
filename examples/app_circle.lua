#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGGeometry = require("remotesvg.SVGGeometry")()


local keycodes = require("remotesvg.jskeycodes")


local ImageStream = size()


function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

local function drawCircle(filename)
	ImageStream:reset();

	local doc = svg {
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",

		-- Show outline of canvas using 'rect' element
		rect {x = 1, y = 1, width = 1198, height = 398,
			fill = "none",
			stroke = "blue",
			["stroke-width"] = 2
		},

		circle {
  			fill="red", 
  			stroke="blue", 
  			["stroke-width"]=10, 
        	cx =600,
        	cy = 200,
        	r = 100
        },
		
	}

	doc:write(ImageStream);
end


function frame()
	drawCircle();
end

run()
