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

local bgInit, bgIndex = gfx.getBackground()
local fgInit, fgIndex = gfx.getForeground()

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
    gfx.setResolution(resWMax,resWMax/2)
  elseif scrAR > maxAR then
    gfx.setResolution(resWMax,resWMax/(2*scrAR))
  else
    gfx.setResolution(resHMax*2*scrAR,resHMax)
  end
end

function libmach.err(msg)
  term.clear()
  gfx.setBackground(0xFFFFFF)
  --todo: finish
end

return libmach
