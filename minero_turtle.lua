-- Minero inteligente para CC:Tweaked.
-- Requiere un modem; la ranura 16 queda reservada para carbon.

local CONFIG = {
    PROTOCOL = "minero_inteligente_v1",
    TARGET_BLOCKS = 640,
    FUEL_SLOT = 16,
    STATUS_INTERVAL = 5,
    MAX_VEIN_DEPTH = 64,
    DROP_INVENTORY_AT_HOME = true,
    SCAN_UP = true,
    SCAN_DOWN = true,
    SCAN_LEFT = true,
    SCAN_RIGHT = true,
    SCAN_BEHIND = true,
    DIG_CEILING_FOR_TUNNEL = true,
    RETURN_ON_FULL_INVENTORY = true,
}

local modem = peripheral.find("modem")
if not modem then
    error("No se encontro un modem. Instala y activa un modem para usar la PC.")
end
rednet.open(peripheral.getName(modem))

settings.define("miner.targetBlocks", {
    description = "Bloques objetivo por trabajo de mineria",
    type = "number",
    default = CONFIG.TARGET_BLOCKS,
})
settings.define("miner.totalBlocks", {
    description = "Bloques minados acumulados",
    type = "number",
    default = 0,
})
settings.define("miner.totalOres", {
    description = "Minerales minados acumulados",
    type = "number",
    default = 0,
})
settings.load()

local computerId = os.getComputerID()
local state = "idle"
local targetBlocks = math.max(1, math.floor(settings.get("miner.targetBlocks") or CONFIG.TARGET_BLOCKS))
local jobBlocks = 0
local jobOres = 0
local totalBlocks = settings.get("miner.totalBlocks") or 0
local totalOres = settings.get("miner.totalOres") or 0
local message = "Esperando orden de la PC"
local stopRequested = false
local pathIntegrity = true
local lastStatus = 0
local movedFromHome = 0

local function countItems()
    local count = 0
    for slot = 1, 15 do
        count = count + turtle.getItemCount(slot)
    end
    return count
end

local function inventoryFull()
    for slot = 1, 15 do
        if turtle.getItemSpace(slot) > 0 then
            return false
        end
    end
    return true
end

local function isOre(block)
    if not block or type(block.name) ~= "string" then
        return false
    end
    return block.name:match("_ore$") ~= nil or block.name == "minecraft:ancient_debris"
end

local function fuelLevel()
    return turtle.getFuelLevel()
end

local function ensureFuel(required)
    local fuel = fuelLevel()
    if fuel == "unlimited" then
        return true
    end

    local selected = turtle.getSelectedSlot()
    while fuel < required do
        turtle.select(CONFIG.FUEL_SLOT)
        if turtle.getItemCount(CONFIG.FUEL_SLOT) == 0 or not turtle.refuel(1) then
            turtle.select(selected)
            message = "Combustible insuficiente en la ranura " .. CONFIG.FUEL_SLOT
            return false
        end
        fuel = fuelLevel()
    end
    turtle.select(selected)
    return true
end

local function sendStatus()
    settings.set("miner.targetBlocks", targetBlocks)
    settings.set("miner.totalBlocks", totalBlocks)
    settings.set("miner.totalOres", totalOres)
    local saved, saveError = settings.save()
    if not saved then
        message = "No se pudo guardar la configuracion: " .. tostring(saveError)
    end

    local fuelSlotCount = turtle.getItemCount(CONFIG.FUEL_SLOT)
    local fuel = fuelLevel()
    rednet.broadcast({
        type = "status",
        id = computerId,
        label = os.getComputerLabel() or ("Turtle " .. computerId),
        state = state,
        target = targetBlocks,
        jobBlocks = jobBlocks,
        jobOres = jobOres,
        totalBlocks = totalBlocks,
        totalOres = totalOres,
        fuel = fuel,
        fuelSlot = fuelSlotCount,
        items = countItems(),
        message = message,
    }, CONFIG.PROTOCOL)
    lastStatus = os.clock()
end

local function updateStatusIfDue()
    if os.clock() - lastStatus >= CONFIG.STATUS_INTERVAL then
        sendStatus()
    end
end

local function receiveCommand()
    local _, command = rednet.receive(CONFIG.PROTOCOL, 0)
    if type(command) ~= "table" then
        return
    end

    if command.type == "stop" then
        stopRequested = true
        message = "Detencion solicitada; regresando al inicio"
    elseif command.type == "config" then
        local newTarget = tonumber(command.target)
        if newTarget and newTarget >= 1 then
            targetBlocks = math.floor(newTarget)
            message = "Objetivo actualizado: " .. targetBlocks .. " bloques"
        else
            message = "Configuracion rechazada: objetivo invalido"
        end
        sendStatus()
    elseif command.type == "status" then
        sendStatus()
    end
end

local function checkControl()
    receiveCommand()
    updateStatusIfDue()
    if not pathIntegrity then
        return false
    end
    if stopRequested then
        return false
    end
    if CONFIG.RETURN_ON_FULL_INVENTORY and inventoryFull() then
        message = "Inventario lleno; regresando al inicio"
        return false
    end
    return true
end

local function turnFor(direction)
    local turned
    if direction == "left" then
        turned = turtle.turnLeft()
    elseif direction == "right" then
        turned = turtle.turnRight()
    elseif direction == "back" then
        turned = turtle.turnRight()
        if turned then
            turned = turtle.turnRight()
        end
    else
        return true
    end
    if not turned then
        pathIntegrity = false
        message = "No se pudo girar; posicion de la turtle incierta"
    end
    return turned
end

local function restoreTurn(direction)
    local turned
    if direction == "left" then
        turned = turtle.turnRight()
    elseif direction == "right" then
        turned = turtle.turnLeft()
    elseif direction == "back" then
        turned = turtle.turnRight()
        if turned then
            turned = turtle.turnRight()
        end
    else
        return true
    end
    if not turned then
        pathIntegrity = false
        message = "No se pudo restaurar la orientacion de la turtle"
    end
    return turned
end

local function inspectDirection(direction)
    if direction == "up" then
        return turtle.inspectUp()
    elseif direction == "down" then
        return turtle.inspectDown()
    end

    if direction == "left" or direction == "right" or direction == "back" then
        if not turnFor(direction) then
            return false, nil
        end
    end
    local found, block = turtle.inspect()
    if direction == "left" or direction == "right" or direction == "back" then
        restoreTurn(direction)
    end
    return found, block
end

local function moveInto(direction)
    if direction == "up" then
        return turtle.up()
    elseif direction == "down" then
        return turtle.down()
    elseif direction == "back" then
        return turtle.back()
    elseif direction == "left" or direction == "right" then
        if not turnFor(direction) then
            return false
        end
        local moved = turtle.forward()
        if not moved then
            restoreTurn(direction)
        end
        return moved
    end
    return turtle.forward()
end

local function moveBackFrom(direction)
    if direction == "up" then
        return turtle.down()
    elseif direction == "down" then
        return turtle.up()
    elseif direction == "left" or direction == "right" then
        local moved = turtle.back()
        restoreTurn(direction)
        return moved
    end
    return turtle.back()
end

local mineVein
mineVein = function(depth)
    if depth >= CONFIG.MAX_VEIN_DEPTH or not checkControl() then
        return
    end

    local directions = { "front" }
    if CONFIG.SCAN_UP then table.insert(directions, "up") end
    if CONFIG.SCAN_DOWN then table.insert(directions, "down") end
    if CONFIG.SCAN_LEFT then table.insert(directions, "left") end
    if CONFIG.SCAN_RIGHT then table.insert(directions, "right") end
    if CONFIG.SCAN_BEHIND then table.insert(directions, "back") end

    for _, direction in ipairs(directions) do
        if not checkControl() then
            return
        end

        local found, block = inspectDirection(direction)
        if not pathIntegrity then
            return
        end
        if found and isOre(block) then
            if not ensureFuel(movedFromHome + depth + 2) then
                stopRequested = true
                return
            end
            local dug
            if direction == "up" then
                dug = turtle.digUp()
            elseif direction == "down" then
                dug = turtle.digDown()
            else
                local needsTurn = direction == "left" or direction == "right" or direction == "back"
                if needsTurn and not turnFor(direction) then
                    stopRequested = true
                    message = "No se pudo girar para inspeccionar una veta"
                    return
                end
                dug = turtle.dig()
                if needsTurn then
                    restoreTurn(direction)
                end
            end
            if not pathIntegrity then
                return
            end

            if dug then
                jobBlocks = jobBlocks + 1
                totalBlocks = totalBlocks + 1
                jobOres = jobOres + 1
                totalOres = totalOres + 1

                if moveInto(direction) then
                    mineVein(depth + 1)
                    if not moveBackFrom(direction) then
                        pathIntegrity = false
                        stopRequested = true
                        message = "No se pudo regresar de una veta; revisa la turtle"
                    end
                    if not pathIntegrity then
                        return
                    end
                end
            end
        end
    end
end

local function digForwardBlock()
    while turtle.detect() do
        if not turtle.dig() then
            message = "No se pudo picar el bloque frente a la turtle"
            return false
        end
        jobBlocks = jobBlocks + 1
        totalBlocks = totalBlocks + 1
        sleep(0.25)
        if not checkControl() then
            return false
        end
    end
    return true
end

local function digCeiling()
    if not CONFIG.DIG_CEILING_FOR_TUNNEL then
        return true
    end
    while turtle.detectUp() do
        local found, block = turtle.inspectUp()
        if found and isOre(block) then
            return true
        end
        if not turtle.digUp() then
            message = "No se pudo despejar el techo del tunel"
            return false
        end
        jobBlocks = jobBlocks + 1
        totalBlocks = totalBlocks + 1
        sleep(0.25)
        if not checkControl() then
            return false
        end
    end
    return true
end

local function returnHome()
    state = "returning"
    message = "Regresando " .. movedFromHome .. " bloques al inicio"
    sendStatus()
    if not turnFor("back") then
        state = "error"
        sendStatus()
        return false
    end

    for _ = 1, movedFromHome do
        local attempts = 0
        while not turtle.forward() do
            attempts = attempts + 1
            if attempts > 20 then
                state = "error"
                message = "Retorno bloqueado; despeja el camino manualmente"
                sendStatus()
                return false
            end
            if turtle.detect() then
                if turtle.dig() then
                    jobBlocks = jobBlocks + 1
                    totalBlocks = totalBlocks + 1
                end
                sleep(0.25)
            else
                sleep(0.5)
            end
        end
    end
    return true
end

local function unloadInventory()
    if not CONFIG.DROP_INVENTORY_AT_HOME then
        return
    end
    local failed = false
    for slot = 1, 15 do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 and not turtle.drop() then
            failed = true
        end
    end
    turtle.select(1)
    if failed then
        message = "No hay cofre delante o quedaron objetos en el inventario"
    else
        message = "Inventario descargado en el cofre"
    end
    return not failed
end

local function runJob()
    stopRequested = false
    pathIntegrity = true
    jobBlocks = 0
    jobOres = 0
    movedFromHome = 0
    state = "mining"
    message = "Mineria iniciada"
    sendStatus()

    while jobBlocks < targetBlocks and checkControl() do
        if not ensureFuel(movedFromHome + 2) then
            break
        end

        mineVein(0)
        if jobBlocks >= targetBlocks or not checkControl() then
            break
        end

        if not digForwardBlock() or not digCeiling() then
            break
        end
        if not turtle.forward() then
            message = "Camino bloqueado; se detiene la mineria"
            break
        end
        movedFromHome = movedFromHome + 1

        mineVein(0)
        updateStatusIfDue()
    end

    if not pathIntegrity then
        state = "error"
        message = "No se pudo conservar la ruta de la veta; recuperacion manual necesaria"
        sendStatus()
        return
    end

    if returnHome() then
        local unloaded = true
        if CONFIG.DROP_INVENTORY_AT_HOME then
            state = "unloading"
            sendStatus()
            unloaded = unloadInventory()
        end
        sleep(5)
        if not turnFor("back") then
            state = "error"
            sendStatus()
            return
        end
        state = "idle"
        stopRequested = false
        if unloaded then
            if jobBlocks >= targetBlocks then
                message = "Objetivo alcanzado; lista para otra orden"
            elseif message == "Mineria iniciada" then
                message = "Trabajo terminado; lista para otra orden"
            end
        end
    end
    sendStatus()
end

sendStatus()
while true do
    local _, command = rednet.receive(CONFIG.PROTOCOL, CONFIG.STATUS_INTERVAL)
    if type(command) == "table" then
        if command.type == "start" and state == "idle" then
            runJob()
        elseif command.type == "config" then
            local newTarget = tonumber(command.target)
            if newTarget and newTarget >= 1 then
                targetBlocks = math.floor(newTarget)
                message = "Objetivo actualizado: " .. targetBlocks .. " bloques"
            else
                message = "Configuracion rechazada: objetivo invalido"
            end
            sendStatus()
        elseif command.type == "status" then
            sendStatus()
        elseif command.type == "stop" and state == "idle" then
            message = "La turtle ya esta en espera"
            sendStatus()
        end
    elseif os.clock() - lastStatus >= CONFIG.STATUS_INTERVAL then
        sendStatus()
    end
end
