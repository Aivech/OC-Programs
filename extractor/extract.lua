local comp = require("component")
local side = require("sides")
local term = require("term")
local mach = require("libmach")

term.clear()
print("Extractor Monitor v0.1")
print("----------------------")

print("Detecting Extractor")
if not comp.list("Extractor")() then
  mach.fatal("No Extractor detected!")
  mach.cleanDisp()
  os.exit()
end
local extrc = comp.proxy(comp.list("Extractor")())
 
print("Detecting power source")
--====Valid engines====
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
--TurbineCore - steam to shaft
--HiPTurbine - steam to shaft
 
local engines = {}
for addr, name in comp.list() do
  if string.match(name,"Engine$") then
    engines[#engines+1] = {comp.proxy(addr),name}
  elseif string.match(name,"[Tt]urbine") then
    engines[#engines+1] = {comp.proxy(addr),name}
  elseif string.match(name,"Motor") then
    engines[#engines+1] = {comp.proxy(addr),name}
  elseif string.match(name,"Magnetic") then
    engines[#engines+1] = {comp.proxy(addr),name}
  end
end

if #engines == 0 then
  mach.fatal("No engines found!")
  mach.cleanDisp()
  os.exit()
end

print("Detecting control method")
local control = {}
local cLevel = 0
if comp.list("redstone")() then
  control = comp.proxy(comp.list("redstone")())
  print("DEBUG: RS component found")
  cLevel = 1
else
  print("No transmission control!")
end

local ecu = {}
local hasECU = false
for addr, name in comp.list("EngineControl") do
  ecu[#ecu+1]=comp.proxy(addr)
end
print(#ecu)

if #ecu ~= 0 and #ecu ~= #engines then
  mach.fatal("Number of ECU's must match number of engines!")
  mach.cleanDisp
  os.exit()
end

if #ecu ~= 0 then
  hasECU = true
end

