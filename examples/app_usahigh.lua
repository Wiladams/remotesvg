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

-- This is a one off
-- we won't be refreshing the image, so just draw
-- into the image stream once, and do NOT implement
-- the 'frame()' function.
doc:write(ImageStream);

run()
