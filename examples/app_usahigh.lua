#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
require("remotesvg.SVGElements")()


local ImageStream = size()

--[[
-- BUGBUG
-- need to set focus on element
function keyDown(activity)
	print(activity.action, activity.json);
end
--]]

function mouseDown(activity)
	print("activity: ", activity.action, activity.id, activity.which, activity.x, activity.y)
end

function mouseMove(activity)
	print("activity: ", activity.action, activity.x, activity.y)
end

local doc = require("usaHigh_svg")

doc:write(ImageStream);

run()
