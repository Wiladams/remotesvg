return [[
<!DOCTYPE html>
<html>
	<head>
		<title>SVG View</title>

		<script type="text/javascript" src="jquery.js"></script>
		<script language="javascript" type="text/javascript">
			window.addEventListener('load', eventWindowLoaded, false);

      		ScreenWidth = <?screenwidth?>
      		ScreenHeight = <?screenheight?>
      		CaptureWidth = <?capturewidth?>
      		CaptureHeight = <?captureheight?>
      		FrameInterval = <?frameinterval?>
      		ImageWidth = <?imagewidth?>
      		ImageHeight = <?imageheight?>

          Authority = '<?authority?>'
          HttpBase = '<?httpbase?>'
          WebSocketBase = '<?websocketbase?>'


      function eventWindowLoaded()
      {
        //alert("svg window loaded!!");
        
        //document.getElementById("screendiv").focus();
        

        // Capture the image once every few milliseconds
        //setInterval("refreshImage()", FrameInterval); 

        //setupWebsocket();
      }
      
      function setupWebsocket()
      {
        var uioUri = WebSocketBase + 'ws/uiosocket'
        
        this.uioSocket = new WebSocket(uioUri); 
        
        // If the socket closes, try to reopen
        // it every few seconds
        this.uioSocket.onclose = function(){
          setTimeout(setupWebSocket, 5000);
        };
      }

			function refreshImage() 
			{
   				if (!document.images) 
   					return;
   				
          var asrc = "./grab.svg?"+Math.random();
          if (HttpBase != "<?httpbase?>") {
            asrc = HttpBase + 'http/' + Authority + asrc;
          }

   				document.images['myScreen'].src = asrc;
			}

		</script>
	</head>

	<body style="margin:0px">
    <object onload="HandleImageLoad()" id="basesvg" data="grab.svg" type = "image/svg+xml" width="100%" height="100%"></object>
	
    <script>
      function HandleImageLoad()
      {
        alert("svg loaded!");
      }

      //var a = document.getElementById("basesvg")
      //a.addEventListener("load", function(){alert("svg loaded!!");}, false);

      function map(x, low, high, low2, high2)
      {
        return low2 + (x/(high-low) * (high2-low2));
      }

      function HandleMouseMove(e)
      {      
        var x = map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
        var y = map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

        uioSocket.send("{action='mouseMove';x="+x+";y="+y+"}");
      });

    </script>
  </body>
</html>
]]
