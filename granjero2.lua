
-- ==========================================
-- GRANJERO AUTOMATICO 5x5
-- CC: Tweaked - Minecraft 1.21.1
-- ==========================================

-- CONFIGURACION
local ANCHO = 5
local LARGO = 5
local PAUSA = 15

local SLOT_SEMILLAS = 1
local SLOT_CARBON = 2

local SEMILLAS = "minecraft:wheat_seeds"

-- ==========================================
-- SISTEMA DE COMBUSTIBLE
-- ==========================================

local function verificarCombustible(minimo)
    local fuel = turtle.getFuelLevel()

    if fuel == "unlimited" then
        return true
    end

    while fuel < minimo do
        local slotAnterior = turtle.getSelectedSlot()

        turtle.select(SLOT_CARBON)

        if not turtle.refuel(1) then
            turtle.select(slotAnterior)
            print("SIN CARBON EN EL SLOT 2!")
            return false
        end

        turtle.select(slotAnterior)
        fuel = turtle.getFuelLevel()

        print("Combustible actual: " .. fuel)
    end

    return true
end

-- ==========================================
-- BUSCAR SEMILLAS
-- ==========================================

local function buscarSemillas()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)

        if item and item.name == SEMILLAS then
            return slot
        end
    end

    return nil
end

-- ==========================================
-- COSECHAR Y REPLANTAR
-- ==========================================

local function revisarCultivo()

    local detectado, bloque = turtle.inspectDown()

    if detectado and bloque.name == "minecraft:wheat" then

        local edad = bloque.state.age

        if edad == 7 then

            print("Trigo maduro! Cosechando...")

            if turtle.digDown() then

                local semillas = buscarSemillas()

                if semillas then
                    turtle.select(semillas)

                    if turtle.placeDown() then
                        print("Trigo replantado!")
                    else
                        print("No se pudo plantar.")
                    end
                else
                    print("ADVERTENCIA: SIN SEMILLAS!")
                end
            end
        end

    elseif detectado and bloque.name == "minecraft:farmland" then

        -- Plantar si la parcela esta vacia
        local semillas = buscarSemillas()

        if semillas then
            turtle.select(semillas)
            turtle.placeDown()
            print("Semilla plantada.")
        end

    end
end

-- ==========================================
-- REGISTRO DE MOVIMIENTOS
-- ==========================================

local movimientos = {}

local function girarIzquierda()
    turtle.turnLeft()
    table.insert(movimientos, "L")
end

local function girarDerecha()
    turtle.turnRight()
    table.insert(movimientos, "R")
end

local function avanzar()
    if not verificarCombustible(1) then
        return false
    end

    if turtle.forward() then
        table.insert(movimientos, "F")
        return true
    end

    print("OBSTACULO DELANTE!")
    return false
end

-- ==========================================
-- REGRESAR AL PUNTO INICIAL
-- ==========================================

local function regresarInicio()

    print("Regresando al inicio...")

    for i = #movimientos, 1, -1 do

        local movimiento = movimientos[i]

        if movimiento == "F" then

            turtle.turnRight()
            turtle.turnRight()

            if not verificarCombustible(1) then
                print("No hay combustible para regresar!")
                return false
            end

            if not turtle.forward() then
                print("Camino bloqueado al regresar!")
                return false
            end

            turtle.turnRight()
            turtle.turnRight()

        elseif movimiento == "L" then

            turtle.turnRight()

        elseif movimiento == "R" then

            turtle.turnLeft()

        end
    end

    movimientos = {}

    print("Regreso completado!")
    return true
end

-- ==========================================
-- RECORRER LA PARCELA
-- ==========================================

local function recorrerParcela()

    movimientos = {}

    print("==============================")
    print("REVISANDO PARCELA 5x5")
    print("==============================")

    for fila = 1, ANCHO do

        print("Revisando fila " .. fila)

        for columna = 1, LARGO do

            revisarCultivo()

            if columna < LARGO then
                if not avanzar() then
                    print("Recorrido interrumpido!")
                    regresarInicio()
                    return false
                end
            end

        end

        -- Cambiar a la siguiente fila
        if fila < ANCHO then

            if fila % 2 == 1 then

                girarDerecha()

                if not avanzar() then
                    regresarInicio()
                    return false
                end

                girarDerecha()

            else

                girarIzquierda()

                if not avanzar() then
                    regresarInicio()
                    return false
                end

                girarIzquierda()

            end
        end
    end

    print("Parcela revisada!")

    regresarInicio()

    return true
end

-- ==========================================
-- INICIO
-- ==========================================

print("==============================")
print("    GRANJERO AUTOMATICO PRO")
print("==============================")

print("Parcela: " .. ANCHO .. "x" .. LARGO)
print("Carbon: Slot " .. SLOT_CARBON)
print("Semillas: Slot " .. SLOT_SEMILLAS)

-- Comprobar combustible inicial
if not verificarCombustible(10) then
    print("Carga carbon en el slot 2.")
    return
end

-- BUCLE INFINITO
while true do

    recorrerParcela()

    print("==============================")
    print("RECORRIDO FINALIZADO")
    print("Esperando crecimiento...")
    print("==============================")

    os.sleep(PAUSA)

end
