return [[
<!DOCTYPE html>
<html>
	<head>
		<title>Screen View</title>

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
        document.getElementById("screendiv").focus();
        

        // Capture the image once every few milliseconds
        setInterval("refreshImage()", FrameInterval); 

        setupWebsocket();
      }
      
      function setupWebsocket()
      {
        var uioUri = WebSocketBase + 'ws/uiosocket'
        
        this.uioSocket = new WebSocket(uioUri); 
        //this.uioSocket.onerror = ...;
        //this.uioSocket.onopen = ...;
        //this.uioSocket.onmessage = ...;
        
        // If the socket closes, try to reopen
        // it every second
        this.uioSocket.onclose = function(){
          setTimeout(setupWebSocket, 1000);
        };

        //document.getElementById("screendiv").addEventListener('onmousemove', HandleMouseMove, false);
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

      function HandleMouseMove(e)
      {      
        var x = map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
        var y = map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

        this.uioSocket.send("{action='mouseMove';x="+x+";y="+y+"}");
      }

		</script>
	</head>

	<body style="margin:0px">
    	<div id="screendiv" tabindex="-1" 
    		style="width:" + ImageWidth + "px; height:"+ImageHeight+"px; margin: 0px 0px 0px 0px; background:yellow; border:0px; groove;"
        onselectstart="return false">

			<img src="/grab.svg" name="myScreen">
		</div>
	</body>

	<script>
		function map(x, low, high, low2, high2)
		{
			return low2 + (x/(high-low) * (high2-low2));
		}
		
		$("#screendiv").keydown(function(e){
          uioSocket.send("{action='keyDown';keyCode="+e.keyCode+"}");
		});

		$("#screendiv").keyup(function(e){
      		uioSocket.send("{action='keyUp';keyCode="+e.keyCode+"}");
		});

    $("#screendiv").keypress(function(e){
          uioSocket.send("{action='keyPress';which="+e.which+"}");
    });

		$("#screendiv").mousedown(function(e){
			var x = map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
			var y = map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

      uioSocket.send("{action='mouseDown';which="+e.which+";x="+x+";y="+y+"}");
 		});

		$("#screendiv").mouseup(function(e){
			var x = map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
			var y = map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

      uioSocket.send("{action='mouseUp';which="+e.which+";x="+x+";y="+y+"}");
		});


 		$("#screendiv").mousemove(function(e){			
			var x = map(e.pageX, 0,ImageWidth, 0,CaptureWidth);
			var y = map(e.pageY, 0,ImageHeight, 0,CaptureHeight);

      uioSocket.send("{action='mouseMove';x="+x+";y="+y+"}");
 		});

	</script>
</html>
]]
