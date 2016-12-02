--DaMachinator's libraries
--For OpenOS

local cp = require("component")
local event = require("event")
local term = require("term")

if not cp.isAvailable("gpu") then
  error("NO GPU",0)
end
local gfx = cp.getPrimary("gpu")
local disp = cp.proxy(gfx.getScreen())

local cdInit = gfx.getDepth()
local cdMax = gfx.maxDepth()

local bgInit, bgIndex = gfx.getBackground()
local bg = bgInit
local fgInit, fgIndex = gfx.getForeground()
local fg = fgInit

local resWInit, resHInit = gfx.getResolution()

local width = resWInit
local heigth = resHInit

--=======================--

local libmach = {}

function libmach.autoRes()
  local scrW, scrH = disp.getAspectRatio()
  local scrAR = scrW/scrH
  local resWMax, resHMax = gfx.maxResolution()
  local maxAR = resWMax/(resHMax*2) --correct for characters being twice as tall as they are wide
  if scrAR == 1 then
    gfx.setResolution(resWMax,math.floor(resWMax/2))
  elseif scrAR > maxAR then
    gfx.setResolution(resWMax,math.floor(resWMax/(2*scrAR)))
  else
    gfx.setResolution(math.floor(resHMax*2*scrAR),resHMax)
  end
  width, heigth = gfx.getResolution()
end

function libmach.fatal(msg)
  term.clear()
  gfx.setBackground(0xFFFFFF)
  gfx.setForeground(0x000000)
  if string.len(msg) > (width-6) then
    msg = string.sub(msg,1,width-6)
  end
  local boxX = math.floor(width/2)-math.floor(string.len(msg)/2)-2
  local boxWide = string.len(msg)+4
  local boxY = math.ceil(heigth/2)-3
  local boxHigh = 5
  gfx.fill(boxX,boxY,boxWide,boxHigh," ")
  gfx.set(boxX+2,boxY+2,msg)
  gfx.set(math.floor(width/2)-7,boxY+3,"Press any key.")
  event.pull("key_down")
end

function libmach.cleanDisp()
  gfx.setDepth(cdInit)
  gfx.setForeground(fgInit,fgIndex)
  gfx.setBackground(bgInit,bgIndex)
  gfx.setResolution(resWInit,resHInit)
  gfx.set(1,1,resWInit,resHInit," ")
  term.clear()
end

return libmach
