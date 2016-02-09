return [[
<!DOCTYPE html>
<html>
	<head>
		<title>SVG View</title>

		<script language="javascript" type="text/javascript">
			window.addEventListener('load', eventWindowLoaded, false);

      FrameInterval = <?frameinterval?>

      // image used to handle async downloads
      var downloadingImage = new Image();
      downloadingImage.onload = function(){
        document.getElementById("basesvg").data = this.src;
      }

      function eventWindowLoaded()
      {
        // Capture the image once every few milliseconds
        setInterval("refreshImage()", FrameInterval); 
      }
      
			function refreshImage() 
			{
          downloadingImage.src = "./grab.svg?"+Math.random();
			}

		</script>
	</head>

	<body style="margin:0px">
    <object id="basesvg" data="grab.svg" type = "image/svg+xml" width="100%" height="100%"></object>
  </body>
</html>
]]
