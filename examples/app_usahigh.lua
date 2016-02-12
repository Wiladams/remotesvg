#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
require("remotesvg.SVGElements")()


local ImageStream = size()


function mouseDown(activity)
	print("activity: ", activity.action, activity.id, activity.which, activity.x, activity.y)
end

--function mouseMove(activity)
--	print("activity: ", activity.action, activity.x, activity.y)
--end

local doc = require("usaHigh_svg")

doc:write(ImageStream);

run()
