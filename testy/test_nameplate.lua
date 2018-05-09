package.path = "../?.lua;"..package.path;

require("remotesvg.SVGElements")()

local doc = svg {
    ['xmlns:xlink']="http://www.w3.org/1999/xlink",
    width="7.50in", 
    height="2.00in", 
    viewBox="0 0 540 144",
--[[
    defs {
        radialGradient {id="MyGradient",
            stop {offset="10%", ['stop-color']="gold"},
            stop {offset="95%", ['stop-color']="green"},
        },
    },

    circle {fill="url(#MyGradient)",
            cx="60", cy="60", r="50"
    },
--]]
    -- The outline to be cut out
    rect {
        --fill="url(#MyGradient)",
        fill="none",
        stroke="black",
        x=0, y=0, width="7.5in", height="2in",
    },

    image {
        stroke = "red",
        id = "faceimage",
        viewBox = "0 0 240 320",
        x = "0.75in",
        y = "0",
        width = "1.0in",
        height = "2.0in",
        ["xlink:href"] = "images/charicature_small.jpg",
    },

    -- shaded rectangle left side
    --[[
    rect {
        fill="gray",
        ["fill-opacity"] = "0.4",
        stroke="black",
        x=0, y=0, width="1.5in", height="2in",
    },
    --]]

    ellipse {
        fill = "none",
        stroke = "black",
        cx = "0.5in",
        cy = "1.25in",
        rx = "0.188in",
        ry = "0.188in"
    };

    ellipse {
        fill = "none",
        stroke = "black",
        cx = "7in",
        cy = "1.25in",
        rx = "0.188in",
        ry = "0.188in"
    };
}

local FileStream = require("remotesvg.filestream")
local SVGStream = require("remotesvg.SVGStream")
local ImageStream = SVGStream(FileStream.open("test_nameplate.svg"))

doc:write(ImageStream);
