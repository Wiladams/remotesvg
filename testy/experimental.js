// For loading an image
// without flicker
          var downloadingImage = new Image();
          downloadingImage.onload = function(){
            document.images['myScreen'].src = this.src;
          }

          downloadingImage.src = asrc;
