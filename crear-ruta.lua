local t=turtle
local DIR="rutas"
local ruta,d={}, 0
fs.makeDir(DIR)

local function fuel()
  local l=t.getFuelLevel()
  if l~="unlimited" and l<100 then t.select(16) t.refuel(1) end
end

local function girar(der)
  if der then t.turnRight() d=(d+1)%4 else t.turnLeft() d=(d+3)%4 end
end

local function ir(k)
  fuel()
  local det,dig,mv,att
  if k==4 then det,dig,mv,att=t.detectUp,t.digUp,t.up,t.attackUp
  elseif k==5 then det,dig,mv,att=t.detectDown,t.digDown,t.down,t.attackDown
  else det,dig,mv,att=t.detect,t.dig,t.forward,t.attack end
  local n=0
  while not mv() do
    if det() then dig() else att() end
    n=n+1
    if n>30 then return false end
  end
  ruta[#ruta+1]=k
  return true
end

local function cabecera(msg)
  term.clear() term.setCursorPos(1,1)
  print("=== GRABAR RUTA ===")
  print("W avanzar  A/D girar")
  print("Espacio subir  Shift bajar")
  print("Enter terminar")
  print("Pasos: "..#ruta)
  if msg then print(msg) end
end

local function crear()
  ruta,d={},0
  cabecera()
  while true do
    local _,k=os.pullEvent("key")
    local msg
    if k==keys.w then if not ir(d) then msg="Bloqueado" end
    elseif k==keys.a then girar(false)
    elseif k==keys.d then girar(true)
    elseif k==keys.space then if not ir(4) then msg="Bloqueado" end
    elseif k==keys.leftShift then if not ir(5) then msg="Bloqueado" end
    elseif k==keys.enter then break end
    cabecera(msg)
  end
end

local function guardar()
  if #ruta==0 then print("No hay ruta creada") sleep(1.5) return end
  write("Nombre de la ruta: ")
  local n=read()
  if n=="" then return end
  local f=fs.open(DIR.."/"..n..".ruta","w")
  f.write(textutils.serialise(ruta))
  f.close()
  print("Guardada: "..n.." ("..#ruta.." pasos)")
  sleep(1.5)
end

local function listar()
  print("Rutas guardadas:")
  for _,f in ipairs(fs.list(DIR)) do print(" - "..f:gsub("%.ruta$","")) end
  print("Presiona una tecla")
  os.pullEvent("key")
end

while true do
  term.clear() term.setCursorPos(1,1)
  print("=== MENU DE RUTAS ===")
  print("1. Crear ruta")
  print("2. Guardar ruta")
  print("3. Ver rutas guardadas")
  print("4. Salir")
  local _,c=os.pullEvent("char")
  if c=="1" then crear()
  elseif c=="2" then guardar()
  elseif c=="3" then term.clear() term.setCursorPos(1,1) listar()
  elseif c=="4" then break end
end
term.clear() term.setCursorPos(1,1)
