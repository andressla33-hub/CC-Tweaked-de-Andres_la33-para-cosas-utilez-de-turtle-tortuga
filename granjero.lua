
-- ==========================================
-- GRANJERO AUTOMATICO 5x5
-- CC: Tweaked - Minecraft 1.21.1
-- ==========================================

-- CONFIGURACION
local ANCHO = 5
local LARGO = 5
local PAUSA = 15

local SEMILLAS = "minecraft:wheat_seeds"

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
-- COSECHAR Y PLANTAR
-- ==========================================

local function revisarCultivo()

    local detectado, bloque = turtle.inspectDown()

    if detectado and bloque.name == "minecraft:wheat" then

        local edad = bloque.state.age

        if edad == 7 then

            print("Cosechando trigo...")

            if turtle.digDown() then

                local semillas = buscarSemillas()

                if semillas then
                    turtle.select(semillas)

                    if turtle.placeDown() then
                        print("Trigo replantado.")
                    else
                        print("No se pudo plantar.")
                    end
                else
                    print("SIN SEMILLAS!")
                end

            end
        end

    elseif not detectado then

        -- Parcela vacia: intentar plantar
        local semillas = buscarSemillas()

        if semillas then
            turtle.select(semillas)
            turtle.placeDown()
        end

    end
end

-- ==========================================
-- AVANZAR
-- ==========================================

local function avanzar()

    if turtle.getFuelLevel() ~= "unlimited"
    and turtle.getFuelLevel() < 1 then

        print("SIN COMBUSTIBLE!")
        return false
    end

    while not turtle.forward() do

        if turtle.detect() then
            turtle.dig()
            os.sleep(0.4)
        else
            os.sleep(1)
        end

    end

    return true
end

-- ==========================================
-- RECORRER PARCELA EN ZIGZAG
-- ==========================================

local function recorrerParcela()

    print("Iniciando recorrido 5x5...")

    for fila = 1, ANCHO do

        print("Fila " .. fila)

        for columna = 1, LARGO do

            -- Revisar cultivo debajo
            revisarCultivo()

            if columna < LARGO then
                if not avanzar() then
                    return false
                end
            end

        end

        -- Cambiar de fila
        if fila < ANCHO then

            if fila % 2 == 1 then

                turtle.turnRight()

                if not avanzar() then return false end

                turtle.turnRight()

            else

                turtle.turnLeft()

                if not avanzar() then return false end

                turtle.turnLeft()

            end

        end
    end

    -- Regresar al punto inicial
    turtle.turnRight()
    turtle.turnRight()

    for i = 1, LARGO - 1 do
        if not avanzar() then return false end
    end

    turtle.turnLeft()

    for i = 1, ANCHO - 1 do
        if not avanzar() then return false end
    end

    turtle.turnRight()

    print("Parcela revisada!")

    return true
end

-- ==========================================
-- PROGRAMA PRINCIPAL
-- ==========================================

print("==============================")
print("     GRANJERO AUTOMATICO")
print("==============================")

print("Parcela: " .. ANCHO .. "x" .. LARGO)

if not buscarSemillas() then
    print("ADVERTENCIA: No tienes semillas.")
end

while true do

    recorrerParcela()

    print("Esperando crecimiento...")
    os.sleep(PAUSA)

end
