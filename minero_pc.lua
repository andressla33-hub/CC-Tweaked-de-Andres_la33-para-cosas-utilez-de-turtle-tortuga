-- Panel tactil para controlar varias turtles mineras por rednet.
local PROTOCOL = "minero_inteligente_v1"
local DEFAULT_TARGET = 640
local TARGET_STEP = 64
local REFRESH_SECONDS = 1

local modem = peripheral.find("modem")
if not modem then
    error("No se encontro un modem. Instala y activa un modem para usar la PC.")
end
rednet.open(peripheral.getName(modem))

local monitor = peripheral.find("monitor")
local screen = monitor or term
if monitor then
    monitor.setTextScale(0.5)
end

local turtles = {}
local selectedId
local page = 1
local notice = "Buscando turtles..."
local lastDraw = 0
local buttons = {}

local function sortedIds()
    local ids = {}
    for id in pairs(turtles) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

local function writeAt(x, y, text, foreground, background)
    if y < 1 then
        return
    end
    local width, height = screen.getSize()
    if y > height or x > width then
        return
    end
    if background then screen.setBackgroundColor(background) end
    if foreground then screen.setTextColor(foreground) end
    screen.setCursorPos(math.max(1, x), y)
    screen.write(text:sub(1, math.max(0, width - x + 1)))
end

local function drawButton(x, y, width, label, action)
    local text = "[" .. label .. "]"
    local rendered = text:sub(1, width)
    writeAt(x, y, rendered, colors.black, colors.lightBlue)
    buttons[#buttons + 1] = {
        x1 = x,
        x2 = x + #rendered - 1,
        y = y,
        action = action,
    }
end

local function buttonRow(y, actions)
    local width = screen.getSize()
    local cellWidth = math.floor(width / #actions)
    for index, item in ipairs(actions) do
        local x = (index - 1) * cellWidth + 1
        drawButton(x, y, cellWidth, item.label, item.action)
    end
end

local function draw()
    local width, height = screen.getSize()
    local ids = sortedIds()
    if selectedId and not turtles[selectedId] then
        selectedId = nil
    end
    if not selectedId and #ids > 0 then
        selectedId = ids[1]
    end

    buttons = {}
    screen.setBackgroundColor(colors.black)
    screen.setTextColor(colors.white)
    screen.clear()
    writeAt(1, 1, string.rep(" ", width), colors.white, colors.blue)
    writeAt(2, 1, "TURTLE MINER  |  Control de flota", colors.white, colors.blue)

    local rowsPerPage = math.max(1, height - 11)
    local pageCount = math.max(1, math.ceil(#ids / rowsPerPage))
    page = math.min(page, pageCount)
    local onlineCount = 0
    for _, t in pairs(turtles) do
        if os.clock() - t.seen <= 15 then
            onlineCount = onlineCount + 1
        end
    end
    writeAt(2, 2, "En linea: " .. onlineCount .. "/" .. #ids .. "    Pagina " .. page .. "/" .. pageCount,
        colors.lightGray)

    writeAt(2, 3, "ID / estado       bloques  menas  carbon16  combustible  objetivo", colors.yellow)
    local first = (page - 1) * rowsPerPage + 1
    for row = 1, rowsPerPage do
        local id = ids[first + row - 1]
        if id then
            local t = turtles[id]
            local age = os.clock() - t.seen
            local stateName = age > 15 and "offline" or (t.state or "desconocido")
            local label = string.format(
                "%s#%-3d %-10s %7d %6d %9d %12s %8d",
                id == selectedId and ">" or " ",
                id,
                stateName,
                t.jobBlocks or 0,
                t.jobOres or 0,
                t.fuelSlot or 0,
                tostring(t.fuel or "?"),
                t.target or DEFAULT_TARGET
            )
            local bg = id == selectedId and colors.gray or colors.black
            writeAt(1, row + 3, string.rep(" ", width), colors.white, bg)
            writeAt(2, row + 3, label, colors.white, bg)
        end
    end

    local selected = selectedId and turtles[selectedId]
    local detailY = height - 7
    if selected then
        writeAt(2, detailY, "Turtle seleccionada: " .. (selected.label or ("Turtle " .. selectedId)))
        writeAt(2, detailY + 1, "Trabajo: " .. (selected.jobBlocks or 0) .. "/" .. (selected.target or DEFAULT_TARGET)
            .. " bloques | minerales: " .. (selected.jobOres or 0))
        writeAt(2, detailY + 2, "Acumulado: " .. (selected.totalBlocks or 0) .. " bloques | "
            .. (selected.totalOres or 0) .. " minerales")
        writeAt(2, detailY + 3, "Combustible: " .. tostring(selected.fuel or "?")
            .. " | carbon en slot 16: " .. (selected.fuelSlot or 0))
        writeAt(2, detailY + 4, "Estado: " .. (selected.message or selected.state or "sin datos"))
    else
        writeAt(2, detailY, "Enciende una turtle con modem y ejecuta minero_turtle.lua")
    end

    local row1 = height - 2
    local row2 = height
    buttonRow(row1, {
        { label = "-64", action = "minus64" },
        { label = "+64", action = "plus64" },
        { label = "Iniciar", action = "start" },
        { label = "Detener", action = "stop" },
        { label = "Pagina >", action = "next" },
    })
    buttonRow(row2, {
        { label = "-1", action = "minus1" },
        { label = "+1", action = "plus1" },
        { label = "Actualizar", action = "refresh" },
    })
    writeAt(1, height - 1, string.rep(" ", width), colors.white, colors.black)
    writeAt(2, height - 1, notice, colors.lightGray)
    lastDraw = os.clock()
end

local function sendToSelected(command)
    if not selectedId then
        notice = "Selecciona primero una turtle de la lista"
        return
    end
    rednet.send(selectedId, command, PROTOCOL)
end

local function adjustTarget(amount)
    if not selectedId then
        notice = "Selecciona primero una turtle"
        return
    end
    local t = turtles[selectedId]
    local target = math.max(1, (t.target or DEFAULT_TARGET) + amount)
    sendToSelected({ type = "config", target = target })
    t.target = target
    notice = "Objetivo de la turtle " .. selectedId .. ": " .. target .. " bloques"
end

local function handleAction(action)
    if action == "minus64" then
        adjustTarget(-TARGET_STEP)
    elseif action == "plus64" then
        adjustTarget(TARGET_STEP)
    elseif action == "minus1" then
        adjustTarget(-1)
    elseif action == "plus1" then
        adjustTarget(1)
    elseif action == "start" then
        sendToSelected({ type = "start" })
        notice = "Orden de inicio enviada"
    elseif action == "stop" then
        sendToSelected({ type = "stop" })
        notice = "Orden de detencion enviada"
    elseif action == "next" then
        local _, screenHeight = screen.getSize()
        local rowsPerPage = math.max(1, screenHeight - 11)
        local ids = sortedIds()
        local pageCount = math.max(1, math.ceil(#ids / rowsPerPage))
        page = page % pageCount + 1
        selectedId = ids[(page - 1) * rowsPerPage + 1] or selectedId
    elseif action == "refresh" then
        rednet.broadcast({ type = "status" }, PROTOCOL)
        notice = "Solicitando estados"
    end
    draw()
end

rednet.broadcast({ type = "status" }, PROTOCOL)
local refreshTimer = os.startTimer(REFRESH_SECONDS)
draw()

while true do
    local event, a, b, c = os.pullEvent()
    if event == "rednet_message" and c == PROTOCOL and type(b) == "table" and b.type == "status" then
        b.seen = os.clock()
        turtles[b.id] = b
        if not selectedId then selectedId = b.id end
        if os.clock() - lastDraw >= REFRESH_SECONDS then
            draw()
        end
    elseif event == "monitor_touch" and monitor and a == peripheral.getName(monitor) then
        local x, y = b, c
        local width, height = screen.getSize()
        local rowsPerPage = math.max(1, height - 11)
        local ids = sortedIds()
        if y >= 4 and y < 4 + rowsPerPage then
            local index = (page - 1) * rowsPerPage + y - 3
            if ids[index] then
                selectedId = ids[index]
                draw()
            end
        else
            for _, button in ipairs(buttons) do
                if y == button.y and x >= button.x1 and x <= button.x2 then
                    handleAction(button.action)
                    break
                end
            end
        end
    elseif event == "key" and not monitor then
        if a == keys.up or a == keys.down then
            local ids = sortedIds()
            for index, id in ipairs(ids) do
                if id == selectedId then
                    local offset = a == keys.up and -1 or 1
                    selectedId = ids[math.max(1, math.min(#ids, index + offset))]
                    break
                end
            end
            draw()
        elseif a == keys.enter then
            handleAction("start")
        elseif a == keys.left then
            handleAction("minus64")
        elseif a == keys.right then
            handleAction("plus64")
        end
    elseif event == "char" and not monitor then
        if a == "s" then handleAction("stop") end
        if a == "r" then handleAction("refresh") end
    elseif event == "timer" and a == refreshTimer then
        draw()
        refreshTimer = os.startTimer(REFRESH_SECONDS)
    end
    if os.clock() - lastDraw >= REFRESH_SECONDS then
        draw()
    end
end
