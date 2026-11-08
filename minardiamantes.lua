-- CONFIGURACIÓN INICIAL
local LARGO_TUNEL = 50 -- Cuántos bloques avanzará en línea recta
local SLOT_COMBUSTIBLE = 16 -- Ranura recomendada para dejar Carbón/Lava

-- Bloques objetivo a buscar
local DIAMANTES = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true
}

-- Función para recargar combustible de forma automática
local function verificarCombustible()
    if turtle.getFuelLevel() < 100 then
        turtle.select(SLOT_COMBUSTIBLE)
        if turtle.refuel(1) then
            print("Combustible recargado. Nivel actual: " .. turtle.getFuelLevel())
        else
            print("ADVERTENCIA: Sin combustible en el slot " .. SLOT_COMBUSTIBLE)
        end
    end
end

-- Función para verificar si un bloque es diamante
local function esDiamante(exito, info)
    if exito and info and DIAMANTES[info.name] then
        return true
    end
    return false
end

-- Función para picar venas adyacentes de diamante
local function revisarYMinar(direccion)
    local exito, info
    if direccion == "arriba" then
        exito, info = turtle.inspectUp()
        if esDiamante(exito, info) then turtle.digUp() end
    elseif direccion == "abajo" then
        exito, info = turtle.inspectDown()
        if esDiamante(exito, info) then turtle.digDown() end
    elseif direccion == "frente" then
        exito, info = turtle.inspect()
        if esDiamante(exito, info) then turtle.dig() end
    end
end

-- Escaneo lateral (izquierda y derecha) sin perder la orientación
local function escanearLados()
    -- Revisar izquierda
    turtle.turnLeft()
    revisarYMinar("frente")
    turtle.turnRight()
    
    -- Revisar derecha
    turtle.turnRight()
    revisarYMinar("frente")
    turtle.turnLeft()
end

-- Bucle principal de minería
print("Iniciando búsqueda de diamantes para " .. LARGO_TUNEL .. " bloques...")
for i = 1, LARGO_TUNEL do
    verificarCombustible()
    
    -- 1. Picar y avanzar (bloque inferior del túnel de 2 de alto)
    while turtle.detect() do
        turtle.dig()
        os.sleep(0.4) -- Pausa para caídas de gravedad (grava)
    end
    
    if turtle.forward() then
        -- 2. Picar el bloque superior para hacer el túnel transitable (2 de alto)
        if turtle.detectUp() then
            turtle.digUp()
        end
        
        -- 3. Escaneo inteligente a los bordes del túnel
        revisarYMinar("arriba") -- Bloque arriba del techo
        revisarYMinar("abajo")  -- Bloque abajo del suelo
        escanearLados()         -- Paredes izquierda y derecha
    end
end

print("Minería completada. ¡Revisa el inventario de la Turtle!")
