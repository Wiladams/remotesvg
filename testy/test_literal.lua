#!/usr/bin/env luajit 

package.path = "../?.lua;"..package.path;

--[[
    the 'literal' element is the way in which a chunk of text
    can be injected into the SVG directly.  This is useful
    in a couple of cases.

    You might want to include an XML comment block.  There
    is no comment block element, so you enclose it in 
    a literal element.

    You may have some css style sheet embedded.  There
    is no CSS specific element type, so you just include
    it with a literal.

    You might be converting a large chunk of svg by hand
    and you haven't tackled a section yet.  you can just
    include that section in a literal block, until you 
    get around to dealing with it.

    The disadvantage of literal blocks is that the content
    is not parsed, so it's just an opaque chunk of text.
    All the other elements give you access to the various
    attributes as lua values, that can be queried and
    modified.
--]]

local SVGInteractor = require("remotesvg.SVGInteractor")
require("remotesvg.SVGElements")()


local ImageStream = size()


local doc = svg{
  version="1.2", 
  baseProfile="tiny", 
  ['xml:id']="svg-root", 
  ['xmlns:xlink']="http://www.w3.org/1999/xlink",  
  ['xmlns:xe']="http://www.w3.org/2001/xml-events",
  width="100%", 
  height="100%",
  viewBox="0 0 480 360", 

  [[
  <!--======================================================================-->
  <!--=  Copyright 2008 World Wide Web Consortium, (Massachusetts          =-->
  <!--=  Institute of Technology, European Research Consortium for         =-->
  <!--=  Informatics and Mathematics (ERCIM), Keio University).            =-->
  <!--=  All Rights Reserved.                                              =-->
  <!--=  See http://www.w3.org/Consortium/Legal/.                          =-->
  <!--======================================================================-->
  ]];

  [[
  <SVGTestCase xmlns="http://www.w3.org/2000/02/svg/testsuite/description/"
    reviewer="AE" owner="JF" desc="Test different ways of defining a motion path." status="accepted"
    approved="yes"
    version="$Revision: 1.9 $" testname="$RCSfile: animate-elem-05-t.svg,v $"> 
    <d:OperatorScript xmlns:d="http://www.w3.org/2000/02/svg/testsuite/description/" xmlns="http://www.w3.org/1999/xhtml">
      <p>Test different ways of defining a motion path.</p>
      <p>
        An animation moves a triangle along a path. Reference rectangles, lines and text are provided to help show what
        the correct behavior is. The red text shows the way that the motion path is specified.
      </p>
      <p>This animation uses the 'values' attribute to define the motion path, with a linear calcMode.</p>
    </d:OperatorScript> 
  </SVGTestCase>
  ]];

  [[ 
  <title xml:id="test-title">$RCSfile: animate-elem-05-t.svg,v $</title> 
  ]];

  defs{
    [[
    <font-face font-family="SVGFreeSansASCII" unicode-range="U+0-7F"> 
      <font-face-src> 
        <font-face-uri xlink:href="../images/SVGFreeSans.svg#ascii" /> 
      </font-face-src> 
    </font-face>
    ]]; 
  }; 
  

  g {
    ['xml:id']="test-body-content", 
    ['font-family']="SVGFreeSansASCII,sans-serif", 
    ['font-size']="18",

    g {
      ['font-family']="Arial",
      ['font-size']="36",

      [[
      <text x="48" y="48">Test a motion path</text> 
      <text x="48" y="95" fill="red">'values' attribute.</text> 
      <path d="M90,258 L240,180 L390,180" fill="none" stroke="black" stroke-width="6" /> 
      <rect x="60" y="198" width="60" height="60" fill="#FFCCCC" stroke="black" stroke-width="6" /> 
      <text x="90" y="300" text-anchor="middle">0 sec.</text> 
      <rect x="210" y="120" width="60" height="60" fill="#FFCCCC" stroke="black" stroke-width="6" /> 
      <text x="240" y="222" text-anchor="middle">3+</text> 
      <rect x="360" y="120" width="60" height="60" fill="#FFCCCC" stroke="black" stroke-width="6" /> 
      <text x="390" y="222" text-anchor="middle">6+</text> 
      ]];

      path {
        d="M-30,0 L0,-60 L30,0 z", 
        fill="blue", 
        stroke="red", 
        ['stroke-width']=6, 
        
        animateMotion {values="90,258;240,180;390,180", begin="0s", dur="6s", calcMode="linear", fill="freeze"} 
      } 
    }
  };

   
  g {
    ['font-family']="SVGFreeSansASCII,sans-serif", 
    ['font-size']="32", 
    text ({['xml:id']="revision", x="10", y="340", stroke="none", fill="black"}, "$Revision: 1.9 $"), 
  };

  [[ 
  <rect xml:id="test-frame" x="1" y="1" width="478" height="358" fill="none" stroke="#000" /> 
  <!-- comment out this watermark once the test is approved -->
  <!--<g xml:id="draft-watermark">
    <rect x="1" y="1" width="478" height="20" fill="red" stroke="black" stroke-width="1"/>
    <text font-family="SVGFreeSansASCII,sans-serif" font-weight="bold" font-size="20" x="240" 
      text-anchor="middle" y="18" stroke-width="0.5" stroke="black" fill="white">DRAFT</text>
  </g>-->
]]
}

doc:write(ImageStream)

run();
