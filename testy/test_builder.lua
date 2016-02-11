#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGGeometry = require("remotesvg.SVGGeometry")

local svg = SVGGeometry.SVG;
local rect = SVGGeometry.Rect;
local circle = SVGGeometry.Circle;

local ImageStream = size()


local function draw(ImageStream)
	ImageStream:reset();

		-- Show outline of canvas using 'rect' element

	-- demonstrate document format API
	local doc = svg {
		version="1.1", 
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",
		

		circle {
  			fill="red", 
  			stroke="blue", 
  			["stroke-width"]=10, 
        	cx =600,
        	cy = 200,
        	r = 100
        },
		
	}

	-- Demonstrate programmatic builder API
	doc:append('rect')
		:attr('x', 1)
		:attr('y', 1)
		:attr('width', 1198)
		:attr('height', 398)
		:attr('fill', "none")
		:attr('stroke', "blue")
		:attr('stroke-width', 2);

	doc:write(ImageStream);
end

draw(ImageStream);

run()
