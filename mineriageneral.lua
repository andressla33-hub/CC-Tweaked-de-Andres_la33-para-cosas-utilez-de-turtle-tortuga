
-- ==========================================
-- MINADOR AUTOMATICO PRO
-- CC: Tweaked - Minecraft 1.21.1
-- ==========================================

-- CONFIGURACION
local LARGO_TUNEL = 50
local CANTIDAD_TUNELES = 5

local SLOT_ANTORCHAS = 15
local SLOT_COMBUSTIBLE = 16

local INTERVALO_ANTORCHAS = 10
local SEPARACION_TUNELES = 2

-- ==========================================
-- MINERALES VALIOSOS
-- ==========================================

local MINERALES = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,

    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,

    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,

    ["minecraft:iron_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,

    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,

    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,

    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,

    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,

    ["minecraft:nether_gold_ore"] = true,
    ["minecraft:nether_quartz_ore"] = true,

    ["minecraft:ancient_debris"] = true
}

-- ==========================================
-- COMBUSTIBLE
-- ==========================================

local function verificarCombustible(minimo)
    if turtle.getFuelLevel() == "unlimited" then
        return true
    end

    while turtle.getFuelLevel() < minimo do
        turtle.select(SLOT_COMBUSTIBLE)

        if not turtle.refuel(1) then
            print("ERROR: Falta combustible en slot 16")
            return false
        end
    end

    return true
end

-- ==========================================
-- DETECTAR MINERALES
-- ==========================================

local function esMineral(exito, info)
    return exito and info and MINERALES[info.name] == true
end

local function revisarYMinar(direccion)
    local exito, info

    if direccion == "arriba" then
        exito, info = turtle.inspectUp()

        if esMineral(exito, info) then
            turtle.digUp()
        end

    elseif direccion == "abajo" then
        exito, info = turtle.inspectDown()

        if esMineral(exito, info) then
            turtle.digDown()
        end

    elseif direccion == "frente" then
        exito, info = turtle.inspect()

        if esMineral(exito, info) then
            turtle.dig()
        end
    end
end

-- ==========================================
-- ESCANEAR PAREDES LATERALES
-- ==========================================

local function escanearLados()
    turtle.turnLeft()
    revisarYMinar("frente")
    turtle.turnRight()

    turtle.turnRight()
    revisarYMinar("frente")
    turtle.turnLeft()
end

-- ==========================================
-- COLOCAR ANTORCHAS
-- ==========================================

local function colocarAntorcha()
    turtle.select(SLOT_ANTORCHAS)

    turtle.turnRight()

    -- Intentar colocar antorcha en la pared
    local colocado = turtle.place()

    turtle.turnLeft()

    if colocado then
        print("Antorcha colocada.")
    else
        print("No se pudo colocar antorcha.")
    end
end

-- ==========================================
-- AVANZAR
-- ==========================================

local function avanzarLibre()
    while turtle.detect() do
        turtle.dig()
        os.sleep(0.4)
    end

    return turtle.forward()
end

-- ==========================================
-- REGRESAR AL INICIO DEL TUNEL
-- ==========================================

local function regresar(avanzados)
    print("Regresando al inicio...")

    turtle.turnRight()
    turtle.turnRight()

    for i = 1, avanzados do
        while not turtle.forward() do
            if turtle.detect() then
                turtle.dig()
                os.sleep(0.4)
            else
                os.sleep(0.5)
            end
        end
    end

    turtle.turnRight()
    turtle.turnRight()
end

-- ==========================================
-- MINAR UN TUNEL
-- ==========================================

local function minarTunel(numero)

    print("Iniciando tunel " .. numero)

    local avanzados = 0

    for i = 1, LARGO_TUNEL do

        if not verificarCombustible(1) then
            break
        end

        if avanzarLibre() then

            avanzados = avanzados + 1

            -- Abrir techo
            if turtle.detectUp() then
                turtle.digUp()
            end

            -- Buscar minerales
            revisarYMinar("arriba")
            revisarYMinar("abajo")
            escanearLados()

            -- Antorchas cada 10 bloques
            if avanzados % INTERVALO_ANTORCHAS == 0 then
                colocarAntorcha()
            end

        else
            print("No se pudo avanzar.")
            break
        end
    end

    print("Tunel terminado: " .. avanzados .. " bloques")

    -- Volver al inicio
    regresar(avanzados)

    return avanzados
end

-- ==========================================
-- PROGRAMA PRINCIPAL
-- ==========================================

print("================================")
print("     MINADOR AUTOMATICO PRO")
print("================================")

print("Longitud: " .. LARGO_TUNEL)
print("Tuneles: " .. CANTIDAD_TUNELES)

local desplazamientos = 0

for tunel = 1, CANTIDAD_TUNELES do

    -- Reservar combustible para ida y vuelta
    local combustibleNecesario =
        (LARGO_TUNEL * 2) + (SEPARACION_TUNELES * 2) + 10

    if not verificarCombustible(combustibleNecesario) then
        print("Mineria detenida por combustible.")
        break
    end

    -- Minar
    local bloques = minarTunel(tunel)

    if bloques < LARGO_TUNEL then
        print("Tunel incompleto. Deteniendo.")
        break
    end

    -- Preparar siguiente tunel
    if tunel < CANTIDAD_TUNELES then

        print("Desplazandose al siguiente tunel...")

        turtle.turnRight()

        local desplazamientoCorrecto = true

        for i = 1, SEPARACION_TUNELES do
            if not avanzarLibre() then
                desplazamientoCorrecto = false
                break
            end
        end

        turtle.turnLeft()

        if not desplazamientoCorrecto then
            print("Error al cambiar de tunel.")
            break
        end

        desplazamientos = desplazamientos + 1
    end
end

-- ==========================================
-- REGRESAR AL PUNTO LATERAL INICIAL
-- ==========================================

if desplazamientos > 0 then

    print("Regresando al punto inicial...")

    turtle.turnLeft()

    for i = 1, desplazamientos * SEPARACION_TUNELES do
        while not turtle.forward() do
            if turtle.detect() then
                turtle.dig()
                os.sleep(0.4)
            else
                os.sleep(0.5)
            end
        end
    end

    turtle.turnRight()
end

-- ==========================================
-- FINALIZADO
-- ==========================================

print("================================")
print("       MINERIA FINALIZADA")
print("================================")

print("Revisa el inventario.")
print("Gracias por usar Minador PRO.")
