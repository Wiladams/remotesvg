#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;



require("remotesvg.SVGElements")()
local FileStream = require("remotesvg.filestream")
local SVGStream = require("remotesvg.SVGStream")
local ImageStream = SVGStream(FileStream.open("ezsvg_example1.svg"))


-- A Translation of this:
-- https://github.com/cappelnord/EzSVG/blob/master/example1.lua

local width = 350
local height = 370

local doc = svg {
    width = width, height = height,

    rect {
        x = 0, y = 0,
        width = width, height = height,
        stroke = "none",
        fill = "rgbcolor(50,50,50)"
    }
}

local lines = g{
    stroke = "white",
    stroke_linecap = "round",
}


for x=0, width,width/80 do
    lines:append (line ({
        stroke_width = x/150,
        x1 = x, y1 = 0,
        x2 = x, y2 = math.abs(math.sin(x/30) * 250)
        }));
end


doc:append(lines);


for i=0,9 do
    local x = i%3 * 70 + 100
    local y = math.floor(i/3) * 70 + 100
    
    local group = g {
        transform = string.format("translate(%d, %d)", x, y)
    }

    local t1 = nil
    for r=-90,0,0.5 do
        local rotation = string.format('rotate (%f)', r)
        local filler = string.format("rgb(0, %d, %d", 255-(r*-3), r+90)

        t1 = text {
            x = 0,
            y = 0,
            fill = filler,
            font_family = "Arial Rounded MT Bold",
            font_size = "40px",
            transform = rotation,

            -- The actual text
            tostring(i);
        }

        group:append(t1)
    end
    
    t1:attr("stroke", "#FFFFFF");
    t1:attr("fill", "#AAFF00");
    group:append(t1)

    doc:append(group)
end



doc:write(ImageStream)
