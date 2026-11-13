-- Función para verificar y recargar combustible desde el slot 16
local function verificarCombustible()
    if turtle.getFuelLevel() < 15 then
        turtle.select(16)
        if not turtle.refuel(1) then
            print("¡Sin carbón en el slot 16! Esperando combustible...")
            while not turtle.refuel(1) do
                os.sleep(5)
            end
            print("Combustible recargado. Continuando...")
        end
    end
end

-- Función para minar y avanzar un bloque (maneja grava/arena y enemigos)
local function avanzarMinando()
    verificarCombustible()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            -- Por si un mob bloquea el camino
            turtle.attack()
        end
        os.sleep(0.2)
    end
end

-- Función para girar 180 grados
local function girar180()
    turtle.turnRight()
    turtle.turnRight()
end

-- Función para soltar los ítems recolectados (slots 1 al 15)
local function soltarItems()
    -- Empezamos desde el slot 1 hasta el 15 (el 16 se reserva para el carbón)
    for slot = 1, 15 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            -- Suelta hacia adelante (puedes cambiarlo por dropDown() si el cofre está abajo)
            turtle.drop() 
        end
    end
    -- Deja seleccionado el slot 1 al terminar
    turtle.select(1)
end

-- Bucle principal infinito
print("Iniciando minería automática...")
while true do
    -- 1. Minar 5 bloques hacia adelante
    for i = 1, 5 do
        avanzarMinando()
    end

    -- 2. Girar 180 grados
    girar180()

    -- 3. Minar de vuelta 5 bloques
    for i = 1, 5 do
        avanzarMinando()
    end

    -- 4. Soltar lo recolectado (dejando el slot 1 seleccionado)
    soltarItems()

    -- 5. Girar 180 grados para quedar mirando al túnel otra vez
    girar180()
end
