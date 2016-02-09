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
        setInterval("refreshImage()", FrameInterval); 
      }
      
			function refreshImage() 
			{
   				if (!document.images) 
   					return;
   				
          var asrc = "./grab.svg?"+Math.random();
          if (HttpBase != "<?httpbase?>") {
            asrc = HttpBase + 'http/' + Authority + asrc;
          }

          document.getElementById("basesvg").data = asrc;
			}

		</script>
	</head>

	<body style="margin:0px">
    <object id="basesvg" data="grab.svg" type = "image/svg+xml" width="100%" height="100%"></object>
  </body>
</html>
]]
