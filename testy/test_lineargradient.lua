#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGGeometry = require("remotesvg.SVGGeometry")()


local ImageStream = size()

local doc = svg {
	width = "120",
	height = "120",
	viewBox = "0 0 120 120",
    ['xmlns:xlink'] ="http://www.w3.org/1999/xlink",

    defs{
        linearGradient {id="MyGradient",
            stop {offset="5%",  ['stop-color']="green"};
            stop {offset="95%", ['stop-color']="gold"};
        }
    },

    rect {
    	fill="url(#MyGradient)",
        x=10, y=10, width=100, height=100,
    },
}

doc:write(ImageStream);

run()