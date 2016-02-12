--[[
    This brief html is the most minimal necessary to display 
    svg graphics oming from the server.  There is no interaction
    back to the server, other than whatever the svg itself sets up.
--]]
return [[
<!DOCTYPE html>
<html>
	<head>
		<title>SVG View</title>
	</head>

	<body style="margin:0px">
    <object id="basesvg" data="grab.svg" type = "image/svg+xml" width="100%" height="100%"></object>
  </body>
</html>
]]
