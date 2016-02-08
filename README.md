# remotesvg
Remote interaction using SVG

This project presents a fairly straight forward interactive graphics environment
using SVG graphics.  The basic premise is that you will use a web browser to view
graphics on a client machine.  The rendering on the client is done using SVG
graphics.

On the server side, the SVG graphics can be built up using any mechanism desired.
Since this is in Lua, you are free to do whatever you want on the lua side, as 
long as by the end, you generate an SVG image that can be rendered on the client.

The SVGGeometry.lua file contains a lot of convenience classes that make building
up an SVG image relatively simple.  A typical example might look like this:

```lua

	local doc = svg({
		version="1.1", 
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",
		
		-- Show outline of canvas using 'rect' element
		rect({x = 1;y = 1;width = 1198; height = 398;
			fill = "none";
			stroke = "blue";
			["stroke-width"] = 2;
		});

		circle({
  			fill="red", 
  			stroke="blue", 
  			["stroke-width"]=10, 
        	cx =600;
        	cy = 200;
        	r = 100;
        });
		
	})

```

The style here is to essentially build up a document as a table of parameters.  The 'svg' object, for instance, has top level attributes, followed by graphic
elements, such as rect, and circle.  The graphic elements in term have the 
same hierarchy.

The entirety of the application may look like this:

```lua
#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

local SVGInteractor = require("remotesvg.SVGInteractor")
local SVGStream = require("remotesvg.SVGStream")
local SVGGeometry = require("remotesvg.SVGGeometry")
local svg = SVGGeometry.Document;
local rect = SVGGeometry.Rect;
local circle = SVGGeometry.Circle;

local keycodes = require("remotesvg.jskeycodes")

local width = 640;
local height = 480;
local mstream = size(width, height)
local ImageStream = SVGStream(mstream);



function mouseMove(activity)
	print("mouseMove: ", activity.x, activity.y)
end

local function drawCircle(filename)
	ImageStream:reset();

	local doc = svg({
		version="1.1", 
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",
		
		-- Show outline of canvas using 'rect' element
		rect({x = 1;y = 1;width = 1198; height = 398;
			fill = "none";
			stroke = "blue";
			["stroke-width"] = 2;
		});

		circle({
  			fill="red", 
  			stroke="blue", 
  			["stroke-width"]=10, 
        	cx =600;
        	cy = 200;
        	r = 100;
        });
		
	})

	doc:write(ImageStream);
end


function frame()
	drawCircle();
end

run()

```

Mouse and keyboard interaction can be achieved by simply implementing the various
mouse and keyboard event routines:

mouseDown, mouseUp, mouseMove
keyDown, keyUp, keyPress

These routines each receive an 'activity' argument, which contains the 
details of what the event was.

mouseDown
    Mouse Button Pressed, called whenever a button is pressed.

     {action='mouseDown', x, y, which};
     x - horizontal location of mouse
     y - vertical location of mouse
     which - which mouse button (1: left, 2:right, 3:middle)

mouseUp
	Mouse Button Released, called whenever a pressed button
	is released.

    {action='mouseUp', x, y, which};
    x - horizontal location of mouse
    y - vertical location of mouse
    which - which mouse button (1: left, 2:right, 3:middle)

mouseMove(activity)
	Mouse Movement, called any time the mouse moves

    {action='mouseMove', x, y};
    x - horizontal location of mouse
    y - vertical location of mouse


Installation
------------

remotesvg relies on turbo lua (https://turbo.readthedocs.org/en/latest/) as a web server.  You need to first install that before trying to run
your application:

luarocks install turbo

Then, assuming you're sitting in the 'examples' directory of remotesvg, 
you can simply execute your file:

luajit myapp.lua

