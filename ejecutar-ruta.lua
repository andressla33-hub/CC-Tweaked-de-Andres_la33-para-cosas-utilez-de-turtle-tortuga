local t=turtle
local a={...}
local nombre=a[1]
local DIR="rutas"

if not nombre then
  print("Rutas:")
  for _,f in ipairs(fs.list(DIR)) do print(" - "..f:gsub("%.ruta$","")) end
  write("Ruta a ejecutar: ")
  nombre=read()
end

local f=fs.open(DIR.."/"..nombre..".ruta","r")
if not f then print("No existe esa ruta") return end
local ruta=textutils.unserialise(f.readAll())
f.close()

local d=0
local I={t.inspect,t.inspect,t.inspect,t.inspect,t.inspectUp,t.inspectDown}
local K={t.suck,t.suck,t.suck,t.suck,t.suckUp,t.suckDown}
local O={t.drop,t.drop,t.drop,t.drop,t.dropUp,t.dropDown}

local function fuel()
  local l=t.getFuelLevel()
  if l~="unlimited" and l<100 then t.select(16) t.refuel(1) end
end

local function tn(k)
  if k>3 then return end
  local diff=(k-d)%4
  if diff==3 then t.turnLeft()
  else for _=1,diff do t.turnRight() end end
  d=k
end

local function mover(k)
  fuel()
  tn(k)
  local det,dig,mv,att
  if k==4 then det,dig,mv,att=t.detectUp,t.digUp,t.up,t.attackUp
  elseif k==5 then det,dig,mv,att=t.detectDown,t.digDown,t.down,t.attackDown
  else det,dig,mv,att=t.detect,t.dig,t.forward,t.attack end
  while not mv() do
    if det() then dig() else att() end
    sleep(.2)
  end
end

local function opuesto(k)
  if k<4 then return (k+2)%4 end
  return k==4 and 5 or 4
end

local function esCofre(k)
  local ok,b=I[k+1]()
  return ok and (b.name:find("chest") or b.name:find("barrel"))
end

local function recoger()
  for k=0,5 do
    tn(k)
    if esCofre(k) then
      t.select(1)
      while K[k+1]() do end
    end
  end
end

local function entregar()
  for k=0,5 do
    tn(k)
    if esCofre(k) then
      for i=1,15 do
        if t.getItemCount(i)>0 then
          t.select(i)
          if not O[k+1]() then break end
        end
      end
    end
  end
end

print("Ejecutando '"..nombre.."' (Ctrl+T para parar)")
while true do
  recoger()
  for i=1,#ruta do mover(ruta[i]) end
  entregar()
  for i=#ruta,1,-1 do mover(opuesto(ruta[i])) end
end
