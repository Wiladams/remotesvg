#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGStream = require("remotesvg.SVGStream")
local SVGGeometry = require("remotesvg.SVGGeometry")

local svg = SVGGeometry.SVG;
local rect = SVGGeometry.Rect;
local path = SVGGeometry.Path;


local keycodes = require("remotesvg.jskeycodes")


local width = 640;
local height = 480;

local mstream = size(width, height)
local ImageStream = SVGStream(mstream);



function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

--[[

--]]
local function draw(ImageStream)
	ImageStream:reset();

	local doc = svg({
		version = "1.1",
		width="4cm", 
		height="4cm", 
		viewBox="0 0 400 400",
		
		rect({x="1", y="1", width="398", height="398",
        	fill="none", stroke="blue"});
		path({d="M 100 100 L 300 100 L 200 300 z",
        	fill="red", stroke="blue", ["stroke-width"]="3"});
		});

	doc:write(ImageStream);
end


function frame()
	draw(ImageStream);
end

loopInterval(1000);
run()
