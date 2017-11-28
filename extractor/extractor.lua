local cp = require("component")
local sides = require("sides")
local evt = require("event")
local gfx = require("libmachgfx")
local term = require("term")
local powerTable = require("engine")

local running = true --if I ever figure out how event handlers work this will be useful

--blatantly copied from http://lua-users.org/wiki/SimpleRound don't kill me
local function round(num)
  under = math.floor(num)
  upper = math.floor(num) + 1
  underV = -(under - num)
  upperV = upper - num
  if (upperV > underV) then
    return under
  else
    return upper
  end
end

--find an extractor
print("Searching for Extractor")
if not cp.list("Extractor")() then --nil and false == false, anything else is true (except maybe 0 i forget)
  error("No Extractor detected!",0) --this shouldn't happen but if it does you messed up
end
local extrc = cp.proxy(cp.list("Extractor")())
local x,y,z = extrc.getCoords()
print("Found extractor at ",x," ",y," ",z) --useless code

print("Detecting power source") 
--====Valid engines====--
--Consumes fuel
--Microturbine
--GasEngine
 
--Consume fuel, temperature monitoring
--JetEngine
 
--Consumes fuel with additive
--PerformanceEngine
 
--Consumes electricity
--Motor
 
--Uses an item over time
--ACEngine

--Power converters, require coolant or lubricant
--HydroEngine - falling water to shaft
--Magnetic - RF to shaft
--ElectricMotor - EU to shaft
--TurbineCore - steam to shaft
--HiPTurbine - steam to shaft

local engines = {}
local electric = false

for addr, label in cp.list() do --lets just iterate over every single component without any filtering
  if (label == "Microturbine") or (label == "GasEngine") then --yay string comparisons i'm sure this performs well
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=true,addt=false,coolant=false,temp=false,output=true}
  elseif label == "JetEngine" then
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=true,addt=false,coolant=false,temp=true,output=true}
  elseif label == "Magnetic" or label == "ElectricMotor" then
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=false,addt=false,coolant=true,temp=false,output=false}
  elseif label == "PerformanceEngine" then
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=true,addt=true,coolant=true,temp=true,output=true}
  elseif label == "Motor" then
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=false,addt=false,coolant=false,temp=false,output=false}
    electric = true
  elseif (string.match(label,"Engine") and label ~= "EngineController") or string.match(label, "Turbine") or label == "ReactorFlywheel" then --add regex for more horrors
    engines[#engines+1] = {proxy=cp.proxy(addr),name=label,fuel=false,addt=false,coolant=false,temp=false,output=false}
  end
end

if #engines == 0 then -- wat r u doing
  print("Engine monitoring disabled!") --just in case you have an engine and I forgot to implement it
elseif electric then
  for i,proxy,name in ipairs(engines) do --because I'm pretty sure electricraft wires act as cables I don't want to pick up the source engines
    if name ~= "Motor" then
      table.remove(engines,i)
    end
  end
end

local canControl = true

local rs = nil
if not cp.isAvailable("redstone") then 
  canControl = false
  print("No redstone component available!\nMonitoring mode enabled!")
else
  rs = cp.redstone
end

local doGraphics = cp.isAvailable("gpu") --i dunno why you would use this without a screen but whatever

if not doGraphics and not canControl then
  error("What exactly are you trying to accomplish here?")
end

if doGraphics then
  term.clear()
  gfx.autoRes(50,16)
  gfx.gpu.set(30,1,"Water: ")
  gfx.gpu.set(1,12,"Engine")
  gfx.gpu.set(20,12,"Output")
  gfx.gpu.set(28,12,"Fuel")
  gfx.gpu.set(39,12,"Status")
  gfx.gpu.set(17,1,"Torque Mode")
  local j = math.min(#engines,4)
  for i=1,j do
    gfx.gpu.set(1,12+i,engines[i].name)
  end
end

local mode = false          --false for torque true for speed
local isProcessing = false  --false for idle, true for processing
local powerSave = false     --true if idle more than ~1min
local idleCycles = 0        --number of cycles we have been idle

while running do
  local items = {}
  local counts = {}
  for i=0,7 do
    local slot = {extrc.getSlot(i)}
    if slot[4] then items[i+1] = slot[4] else items[i+1] = "" end
    if slot[3] then counts[i+1] = slot[3] else counts[i+1] = 0 end
    if i ~= 7 and counts[i+1] > 0 then isProcessing = true end
  end
  
  if (extrc.getPower()) < 65536 then isProcessing = false end
  
  if not isProcessing then idleCycles = idleCycles+1 end
  if isProcessing and idleCycles > 0 then idleCycles = 0 end
  
  if idleCycles > 6 and not powerSave then
    screen = cp.proxy(gfx.gpu.getScreen())
    screen.turnOff()
    powerSave = true
  end
  if powerSave and isProcessing then 
    screen = cp.proxy(gfx.gpu.getScreen())
    screen.turnOn()
    powerSave = false
  end

  if canControl and isProcessing then
    local change1 = false
    local change2 = false
    if not mode then
      if counts[4] == 0 or counts[8] > 62 then change2 = true end
      if counts[1] == 0 or counts[5] > 62 then change1 = true end
      if counts[1] ~= 0 and counts[5] ~= 0 and string.sub(items[1],1,4) ~= string.sub(items[5],1,4) then change1 = true end
      if change1 and change2 then mode = true end
      if mode then --lazy me
        rs.setOutput(sides.north,15)
        rs.setOutput(sides.south,15)
        rs.setOutput(sides.east,15)
        rs.setOutput(sides.west,15)
        if doGraphics then gfx.gpu.set(17,1,"Speed Mode ") end
      end
    else
      if counts[2] == 0 or counts[6] > 62 then change1 = true end
      if counts[3] == 0 or counts[7] > 62 then change2 = true end
      if counts[2] ~= 0 and counts[6] ~= 0 and string.sub(items[2],1,4) ~= string.sub(items[6],1,4) then change1 = true end
      if counts[3] ~= 0 and counts[7] ~= 0 and string.sub(items[3],1,4) ~= string.sub(items[7],1,4) then change2 = true end
      if change1 and change2 then mode = false end
      if not mode then --lazy me
        rs.setOutput(sides.north,0)
        rs.setOutput(sides.south,0)
        rs.setOutput(sides.east,0)
        rs.setOutput(sides.west,0)
        if doGraphics then gfx.gpu.set(17,1,"Torque Mode") end
      end
    end
  end
  
  if doGraphics and not powerSave then --all the following code is pointless without a screen
    if gfx.color then gfx.writeColored(39,1,rawget({extrc.readTank(0)},2).." mB",0x0049ff,0x000000)
    else gfx.gpu.set(39,1,rawget({extrc.readTank(0)},2).." mB") end

    local numEngines = math.min(#engines,4)
    for i=1,numEngines do
      gfx.gpu.fill(20,12+i,32,1," ") --clear the output

      local engine = engines[i]             --get that specific engine
      local power = engine.proxy.getPower() --get the engine's power output
      engine.message = "OK"                 --default message
      engine.status = 0                     --Effectively a format code for the message status.
      
      --I should probably be using string.format and exponents here.
      if power > 1000000000 then
        gfx.gpu.set(20,12+i,math.floor(power/1000000000).." GW")
      elseif power > 1000000 then 
        gfx.gpu.set(20,12+i,math.floor(power/1000000).." MW")
      else
        gfx.gpu.set(20,12+i,math.floor(power/1000).." kW")
      end

      --check each conditional for "what is monitored"
      
      if engine.fuel then
        local fuelData = rawget({engine.proxy.readTank(1)},2)
        gfx.gpu.set(28,12+i,fuelData.." mB")
        if fuelData < 5000 then engine.message = "Low Fuel"; engine.status = 2 end
      end
      --if engine.addt then
        --reika pls fix getNBTTag() kthxbye
      --end
      if engine.coolant then
        local coolantData = rawget({engine.proxy.readTank(0)},2)
        if coolantData < 1000 then engine.message = "Low Coolant"; engine.status = 2 end
      end
      --if engine.temp then
        --also needs fix getNBTTag()
      --end
      if engine.output then
        if power < powerTable[engine.name] and engine.status < 2 then engine.message = "Low Power"; engine.status = 1 end
      end
      
      if gfx.color then --color handling should really just be native to the graphics library
        local fgcolor = 0x00ff00
        local bgcolor = 0x000000
        
        if engine.status == 1 then fgcolor = 0xff6d00 
        elseif engine.status == 2 then fgcolor = 0xFFFFFF; bgcolor = 0xff0000 end
        
        gfx.writeColored(39,12+i,engine.message,fgcolor,bgcolor)
      else
        gfx.gpu.set(39,12+i,string.upper(engine.message))
      end
    end
    
    if gfx.color then 
      if isProcessing then gfx.writeColored(1,1,"Processing",0x00ff00,0x000000)
      else gfx.gpu.fill(1,1,27,1," "); gfx.writeColored(1,1,"Idle",0xff0000,0x000000) end
    else
      if isProcessing then gfx.set(1,1,"Processing")
      else gfx.gpu.fill(1,1,27,1," "); gfx.set(1,1,"Idle") end
    end
    gfx.gpu.fill(1,2,52,8," ")
    for i,name in ipairs(items) do gfx.gpu.set(1,1+i,name) end
  end
  local sleepTime = 1
  
  if not isProcessing then sleepTime = 10 end
    
  os.sleep(sleepTime)
end
gfx.reset()
