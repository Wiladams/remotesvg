#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
require("remotesvg.SVGElements")()


local ImageStream = size()

local doc = svg {
    ['xmlns:xlink']="http://www.w3.org/1999/xlink",
    width="120", 
    height="120", 
    viewBox="0 0 120 120",

    defs {
        radialGradient {id="MyGradient",
            stop {offset="10%", ['stop-color']="gold"},
            stop {offset="95%", ['stop-color']="green"},
        },
    },

    circle {fill="url(#MyGradient)",
            cx="60", cy="60", r="50"
    },
}


doc:write(ImageStream);

run()
