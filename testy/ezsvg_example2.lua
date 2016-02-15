#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

-- A translation of this
-- https://github.com/cappelnord/EzSVG/blob/master/example2.lua

local abs = math.abs
local cos = math.cos
local sin = math.sin


require("remotesvg.SVGElements")()

local dim = 500

local doc = svg {
    width = dim, height = dim,

    rect {
        x = 0, y = 0,
        width = dim, height = dim,
        stroke = "none",
        fill = "rgbcolor(40,40,40)"
    },

    stroke_linecap= "round",
    fill= "white",
    stroke= "white",

}


local group = g {}
local circles = g{}

doc:append(group)
doc:append(circles)


local num = 800
for i=0,num do
    local norm = i / num
    
    local length = dim/2.1 * (0.5 + abs(sin(norm * 80)) * 0.5)
    local lw = abs(sin(norm*200)) * 1
        
    local x = dim/2 + sin(norm * 50) * length
    local y = dim/2 + cos(norm * 50) * length
    
    local line = line {
        x1 = dim/2, 
        y1 = dim/2, 
        x2 = x, y2=y, 
        
        stroke_width= lw + 0.3
    }
    
    group:append(line)
    
    local circ = circle {
        cx = x, cy = y, 
        r = lw * 15, 
        
        fill= "#000000",
        stroke_width = 1
    }
    
    circles:append(circ)
    
end


doc:append(circle {
    cx=dim/2, cy=dim/2, r=60, 
    fill= "black",
    stroke= "white",
    stroke_width = 5
})

local FileStream = require("remotesvg.filestream")
local SVGStream = require("remotesvg.SVGStream")
local ImageStream = SVGStream(FileStream.open("ezsvg_example2.svg"))

doc:write(ImageStream)
