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

		<script language="javascript" type="text/javascript">
		  PageInterval = <?pageinterval?>;
      WebSocketBase = '<?websocketbase?>';

		

		  function init()
		  {
        //alert("body onload init()")

        // get at the svgObject, document, and window
        var svgObject = document.getElementById('svgObject');
        if (svgObject && svgObject.contentDocument)
          svgdoc = svgObject.contentDocument;
        else try {
          svgdoc = svgObject.getSVGDocument();
        }
        catch(exception) {
          alert('Neither the HTMLObjectElement nor the getSVGDocument interface are implemented.');
        }


        if (svgdoc && svgdoc.defaultView)
    			svgwin = svgdoc.defaultView;
  			else if (object.window)
    			svgwin = object.window;
  			else try {
    			svgwin = object.getWindow();
  			}
  			catch(exception) {
    			alert('The DocumentView interface is not supported\r\n' +
          			'Non-W3C methods of obtaining "window" also failed');
  			}

        //setInterval("refreshImage()", PageInterval); 
        setupWebsocket();
		  }
      

      function setupWebsocket()
      {
        	var uioUri = WebSocketBase + 'ws/uiosocket'
        
        	uioSocket = new WebSocket(uioUri); 
        	//this.uioSocket.onerror = ...;
        	//this.uioSocket.onopen = ...;
        	//this.uioSocket.onmessage = ...;
        
        	// If the socket closes, try to reopen
        	// it every second
        	uioSocket.onclose = function(){
          		setTimeout(setupWebSocket, 5000);
        	};

        	// set the socket as a var in the 
        	// svg DOM
        	if (svgwin) {
        		svgwin.uioSocket = uioSocket;

            // set the functions so they can be accessed
            // from within SVG script blocks
            svgwin.HandleMouseMove = HandleMouseMove;
            svgwin.HandleMouseDown = HandleMouseDown;
            svgwin.HandleMouseUp = HandleMouseUp;
            svgwin.HandleMouseClick = HandleMouseClick;

            svgwin.HandleKeyDown = HandleKeyDown;
        	}
      }

      function map(x, low, high, low2, high2)
      {
        return low2 + ((x-low)/(high-low) * (high2-low2));
      }

      // Keyboard Events
      function HandleKeyDown(e)
      {
        //var msg = "{action='keyDown'; json='"+JSON.stringify(e)+"'}";
        var msg = "{action='keyDown'}";

        uioSocket.send(msg);
      }

      // Mouse Movement
      function HandleMouseMove(e)
      {      
          var x = e.pageX;  // map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
          var y = e.pageY;  // map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

          uioSocket.send("{action='mouseMove';x="+x+";y="+y+"}");
      }

      function HandleMouseDown(e)
      {      
          var x = e.pageX;  // map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
          var y = e.pageY;  // map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

          uioSocket.send("{action='mouseDown';which="+e.which+";x="+x+";y="+y+"; id='"+e.target.id+"'}");
      }

      function HandleMouseUp(e)
      {      
          var x = e.pageX;  // map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
          var y = e.pageY;  // map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

          uioSocket.send("{action='mouseUp';which="+e.which+";x="+x+";y="+y+"}");
      }

      function HandleMouseClick()
      {      
          var x = e.pageX;  // map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
          var y = e.pageY;  // map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

          uioSocket.send("{action='mouseClick';which="+e.which+";x="+x+";y="+y+"}");
      }

		</script>
	</head>

	<body onload="init()" style="margin:0px">
    	<object id="svgObject" data="grab.svg" type = "image/svg+xml" width="100%" height="100%"></object>
  	</body>
</html>
]]
