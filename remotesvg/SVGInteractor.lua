_G.TURBO_SSL = true -- SSL must be enabled for WebSocket support!

local ffi = require("ffi")
local turbo = require("turbo")

--local DrawingContext = require("tflremote.DrawingContext")
local MemoryStream = require("remotesvg.memorystream")

--[[
  Application Variables
--]]
local serviceport = tonumber(arg[1]) or 8080
local ioinstance = nil;
local LoopInterval = 1000 / 4;
local LoopIntervalRef = nil;


local FrameInterval = 1000;
local ImageBitCount = 32;
local ScreenWidth = nil;
local ScreenHeight = nil;
local captureWidth = nil;
local captureHeight = nil;

local mstream = nil;

--[[
    From within your application, call 'loopInterval(frameTime)'
    to specify the interval between frames.  You can call this 
    at any time.

    It governs how often your 'frame()' function will be called.
--]]
function loopInterval(newInterval)

  -- cancel the last interval
  if ioinstance then
    ioinstance:clear_interval(LoopIntervalRef);
  end

  LoopInterval = newInterval;
  
  if ioinstance then
    LoopIntervalRef = ioinstance:set_interval(LoopInterval, onInterval, ioinstance)
  end
end


function size(width, height)
  ScreenWidth = width;
  ScreenHeight = height;

  captureWidth = ScreenWidth;
  captureHeight = ScreenHeight;

  ImageWidth = captureWidth * 1.0;
  ImageHeight = captureHeight * 1.0;


  -- 1Mb should be good enough for most
  -- images
  mstream = MemoryStream:new(1024*1024);

  return mstream;
end


local DefaultHandler = class("DefaultHandler", turbo.web.RequestHandler)
function DefaultHandler:get(...)
  self:write("Example Handler: Hello world!")
end


-- Request handler for /grab%.svg(.*)$
local GrabHandler = class("GrabHandler", turbo.web.RequestHandler)

function GrabHandler:get(...)
  --turbo.log.devel("ScreenHandler: "..self.request.host)
  local bytesWritten = mstream.BytesWritten;

  self:set_status(200)
  self:add_header("Content-Type", "image/svg+xml")
  self:add_header("Content-Length", tostring(bytesWritten))
  --self:add_header("Content-Encoding", "gzip")
  self:add_header("Connection", "Keep-Alive")
  
--print("=== SVG - BEGIN ===")
  local str = ffi.string(mstream.Buffer, bytesWritten)
--  print(str);

  self:write(str);
  self:flush();
end

-- Default request handler
local StartupHandler = class("StartupHandler", turbo.web.RequestHandler)

local startupContent = nil;

local function loadStartupContent(self)

    -- load the file into memory
    local content = require("remotesvg.viewsvg_htm")

    -- perform the substitution of values
    -- assume content looks like this:
    -- <?hostip?>:<?serviceport?>
    local subs = {
      ["authority"]     = self.request.host;
      --["hostip"]      = net:GetLocalAddress(),
      --["httpbase"]      = self:get_header("x-rmt-http-url-base"),
      --["websocketbase"] = self:get_header("x-rmt-ws-url-base"),
      ["websocketbase"] = "ws://"..self.request.host..'/',
      ["serviceport"]   = serviceport,

      ["frameinterval"] = FrameInterval,
      ["capturewidth"]  = captureWidth,
      ["captureheight"] = captureHeight,
      ["imagewidth"]    = ImageWidth,
      ["imageheight"]   = ImageHeight,
      ["screenwidth"]   = ScreenWidth,
      ["screenheight"]  = ScreenHeight,
    }

    startupContent = string.gsub(content, "%<%?(%a+)%?%>", subs)
    
    --print(startupContent)
    return startupContent
end

function StartupHandler:get(...)

  if not startupContent then
    loadStartupContent(self)
  end

  -- send the content back to the requester
  self:set_status(200)
  self:add_header("Content-Type", "text/html")
  self:add_header("Connection", "Keep-Alive")
  self:write(startupContent);
  self:flush();

  return true
end

local WSExHandler = class("WSExHandler", turbo.websocket.WebSocketHandler)

function WSExHandler:on_message(msg)
  --print("WSExHandler:on_message: ", msg)
  -- assume the msg is a lua string, so parse it
  -- BUGBUG - This should be changed, as it's an easy injection vector
  local f = loadstring("return "..msg)
  if not f then return end

  local tbl = f();

  if type(tbl) ~= "table" then
    return;
  end

  self:handleIOActivity(tbl)
end


function WSExHandler:handleIOActivity(activity)
  --print("IO: ", activity.action)
  
  local handler = _G[activity.action];

  if not handler then return end

  handler(activity)
end

--[[
    There are two ways to handle iteration
    Either by idle time (every time through event loop)
    or by time interval.

    You can change which way is utilized by using the
    appropriate mechanism in the run() function.

    You can even setup to use both. 
--]]
local function onLoop(ioinstance)
  if loop then
    loop()
  end
  ioinstance:add_callback(onLoop, ioinstance)
end

local function onInterval(ioinstance)
  if frame then
    frame()
  end
end


-- uncomment if you want to turn off success messages
--turbo.log.categories.success = false;


local app = nil;

function run()
  app = turbo.web.Application({
  {"/(jquery%.js)", turbo.web.StaticFileHandler, "./jquery.js"},
  {"/(favicon%.ico)", turbo.web.StaticFileHandler, "./favicon.ico"},
  {"/grab%.svg(.*)$", GrabHandler},
  {"/screen", StartupHandler},
  {"/ws/uiosocket", WSExHandler}
})

  app:listen(serviceport)
  ioinstance = turbo.ioloop.instance()
  
  loopIntervalRef = ioinstance:set_interval(LoopInterval, onInterval, ioinstance)
  --ioinstance:add_callback(onLoop, ioinstance)

  ioinstance:start()
end
