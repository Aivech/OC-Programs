local gfx = {}
local cp = require("component")

gfx.screen = nil
gfx.gpu = nil
gfx.available = false

if cp.isAvailable("screen") and cp.isAvailable("gpu") then
  gfx.screen = cp.screen
  gfx.gpu = cp.gpu
  gfx.color = false
  if gfx.gpu.maxDepth() > 1 then
    gfx.color = true
  end
  --used by gfx.reset
  gfx.resX,gfx.resY = cp.gpu.getResolution()
  gfx.bgcolor = {cp.gpu.getBackground()}
  gfx.fgcolor = {cp.gpu.getForeground()}
end

function gfx.autoMaxRes()
  local scrW, scrH = gfx.screen.getAspectRatio()
  local scrAR = scrW/scrH
  local resWMax, resHMax = gfx.gpu.maxResolution()
  local maxAR = resWMax/(resHMax*2) --correct for characters being twice as tall as they are wide
  if scrAR == 1 then
    gfx.gpu.setResolution(resWMax,resWMax/2)
  elseif scrAR > maxAR then
    gfx.gpu.setResolution(resWMax,resWMax/(2*scrAR))
  else
    gfx.gpu.setResolution(resHMax*2*scrAR,resHMax)
  end
end

function gfx.autoRes(minResW,minResH)
  local scrW, scrH = gfx.screen.getAspectRatio()
  local scrAR = scrW/scrH
  local resWMax, resHMax = gfx.gpu.maxResolution()
  local prefAR = minResW/(minResH*2) --correct for characters being twice as tall as they are wide
  local resW = 1
  local resH = 1
  if scrAR == 1 then --square screen special case
    resW = math.ceil(math.max(minResW,minResH*2))
    resH = math.ceil(resW/2)
  elseif scrAR > prefAR then --screen wider than pref. resolution, increase resolution width
    resW = math.ceil(scrAR/(minResH*2))
    resH = math.ceil(minResH)
  else -- screen taller than or equal to preferred resolution, increase resolution height
    resH = math.ceil(minResW/(scrAR*2))
    resW = math.ceil(minResW)
  end
  gfx.gpu.setResolution(math.min(resW,resWMax),math.min(resH,resHMax))
end

--clear the screen
function gfx.clear()
  local w,h = gfx.gpu.getResolution()
  gfx.gpu.fill(1,1,w,h," ")
end

--reset the screen
function gfx.reset()
  gfx.clear()
  gfx.gpu.setResolution(gfx.resX,gfx.resY)
  gfx.gpu.setBackground(gfx.bgcolor[1],gfx.bgcolor[2])
  gfx.gpu.setForeground(gfx.fgcolor[1],gfx.fgcolor[2])
end

--write a string to the screen with a specified foreground and background color
--x-coord, y-coord, string to write, foreground color (as RGB value), background color (as RGB value)
function gfx.writeColored(x,y,input,fghex,bghex)
  local bgcolor = {gfx.gpu.getBackground()}
  local fgcolor = {gfx.gpu.getForeground()}
  gfx.gpu.setBackground(bghex)
  gfx.gpu.setForeground(fghex)
  gfx.gpu.set(x,y,tostring(input))
  gfx.gpu.setBackground(bgcolor[1],bgcolor[2])
  gfx.gpu.setForeground(fgcolor[1],bgcolor[2])
end

return(gfx)
