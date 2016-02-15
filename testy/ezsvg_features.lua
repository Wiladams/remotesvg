-- A translation of the example embedded here
-- https://github.com/cappelnord/EzSVG

--require("remotesvg.SVGElements")()
-- Assuming this will be read into a context where SVGElements
-- has already been read, and exposed in global namespace.

 -- create a document
local doc = svg {
    ['xmlns:xlink'] = "http://www.w3.org/1999/xlink",
    width = 1000,
    height = 1000,

    stroke_width = 2,
    stroke = "black"
}


for d=0,1000,100 do
    -- create a circle
    local circ = circle {
        cx = d, cy = d, r = d/10,
        fill = string.format("rgb(%d, 0, 0)", d/4);
    }

    -- add the circle to the doc
    doc:append(circ)
end


-- you can also set a single style
-- create a group (very handy, also stays a group in Inkscape/Illustrator)
local group = g {
    stroke = "green"
}


for r=0,360, 10 do
    -- create a line and add a transform (rotation with r degrees, centered on 500/500)
    local l = line{x1 = 100, y1=500, x2=900, y2=500,
        transform = string.format("rotate(%d, 500, 500)", r),
    }

    -- add it to the group
    group:append(l)     
end

-- add the group to the document
doc:append(group)


-- create a path object and set its styling
local path1 = path {
    id = "TextPath",
}

path1:moveBy(500, 500)
    :sqCurveBy(300,300)
    :sqCurveBy(-200, 0)
    :sqCurveBy(-200, -400)
    :sqCurveTo(500, 500)

doc:append (
    defs {
        radialGradient {id="PathGradient",
            stop {offset="0%", ['stop-color']="black"},
            stop {offset="100%", ['stop-color']="yellow"},
        },
    
        path1,
    })



-- draw the path
doc:append(use {
    ['xlink:href'] = "#TextPath",
    stroke = "blue",
    ['stroke-width'] = 2,
    fill = "url(#PathGradient)",
    ['fill-opacity'] = "0.8"
})

-- add text to doc, add a path and style it
doc:append(text {
    font_size = 60,
    font_family = "Arial",
    fill = "#CCCCCC",
    stroke = "black",
    
    textPath {
        ['xlink:href'] ="#TextPath",
        
        [[
It's so ez to draw some lines, it's so easy to draw some lines ...
]]
    }
})

return doc
