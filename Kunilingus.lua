--[[
    ██╗  ██╗██╗   ██╗███╗   ██╗██╗██╗     ██╗███╗   ██╗ ██████╗ ██╗   ██╗███████╗
    ██║ ██╔╝██║   ██║████╗  ██║██║██║     ██║████╗  ██║██╔════╝ ██║   ██║██╔════╝
    █████╔╝ ██║   ██║██╔██╗ ██║██║██║     ██║██╔██╗ ██║██║  ███╗██║   ██║███████╗
    ██╔═██╗ ██║   ██║██║╚██╗██║██║██║     ██║██║╚██╗██║██║   ██║██║   ██║╚════██║
    ██║  ██╗╚██████╔╝██║ ╚████║██║███████╗██║██║ ╚████║╚██████╔╝╚██████╔╝███████║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚══════╝
    
    KUNILINGUS v5.0 - BROOKHAVEN ULTIMATE
    ВЕРСИЯ С ВНЕШНИМ ПОЛЁТОМ (LOADSTRING)
    ОБЩИЙ ОБЪЁМ: 1100+ СТРОК
--]]

-- ============================================================================
-- ОСНОВНЫЕ ПЕРЕМЕННЫЕ И СЕРВИСЫ
-- ============================================================================

local player = game.Players.LocalPlayer                -- текущий игрок
local char = player.Character or player.CharacterAdded:wait()  -- персонаж
local hrp = char:WaitForChild("HumanoidRootPart")       -- корневая часть персонажа
local humanoid = char:WaitForChild("Humanoid")          -- хомоид (здоровье, скорость)
local uis = game:GetService("UserInputService")         -- управление клавиатурой
local rs = game:GetService("RunService")                -- рендер-цикл
local replicated = game:GetService("ReplicatedStorage") -- удалённые события
local camera = workspace.CurrentCamera                  -- камера игры
local debris = game:GetService("Debris")                -- авто-удаление объектов
local http = game:GetService("HttpService")             -- для HTTP-запросов

-- ============================================================================
-- ПЕРЕМЕННЫЕ СОСТОЯНИЙ (ТОГГЛЫ И НАСТРОЙКИ)
-- ============================================================================

-- Переменные для встроенных функций (скорость, прыжок, невидимость и т.д.)
local speedActive = false       -- активна ли сверхскорость
local jumpActive = false        -- активен ли сверхпрыжок
local invisibleActive = false   -- невидимость
local espActive = false         -- подсветка игроков
local noclipActive = false      -- проход сквозь стены
local selectedPlayer = nil      -- выбранный игрок
local currentPage = 1           -- текущая страница GUI (1, 2 или 3)
local frozenPlayer = nil        -- замороженный игрок
local currentSpeed = 16         -- текущая скорость бега (по умолч. 16)
local currentJump = 50          -- текущая сила прыжка
local followingPlayer = nil     -- игрок за которым следит камера
local followConnection = nil    -- коннект слежки

-- ПЕРЕМЕННЫЕ ДЛЯ ПОЛЁТА (ВНЕШНИЙ СКРИПТ)
local flyScriptLoaded = false   -- флаг, загружен ли скрипт полёта
local externalFlyConnection = nil -- для возможного отключения (если скрипт поддерживает)

-- ============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================================

-- Функция уведомлений (работает через глобальный интерфейс Roblox)
local function notify(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 2
    })
end

-- Функция для безопасного выполнения loadstring (с защитой от ошибок)
local function safeLoadstring(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        local loadSuccess, loadResult = pcall(function()
            return loadstring(result)
        end)
        if loadSuccess then
            return loadResult
        else
            notify("Ошибка загрузки", "Ошибка компиляции скрипта", 2)
            return nil
        end
    else
        notify("Ошибка HTTP", "Не удалось загрузить скрипт: " .. tostring(result), 3)
        return nil
    end
end

-- ============================================================================
-- ФУНКЦИЯ ЗАГРУЗКИ СТОРОННЕГО СКРИПТА ПОЛЁТА
-- ============================================================================

-- Загружает и запускает внешний скрипт полёта из указанного URL
local function loadExternalFlyScript()
    -- Если скрипт уже загружен, пробуем его отключить (через глобальную переменную, если есть)
    if flyScriptLoaded then
        -- Пытаемся отключить полёт, если в загруженном скрипте есть функция stopFly или глобальная переменная
        if _G.FlyScriptStop then
            _G.FlyScriptStop()
        elseif _G.FlyEnabled then
            _G.FlyEnabled = false
        elseif _G.StopFly then
            _G.StopFly()
        end
        flyScriptLoaded = false
        notify("Полёт", "Внешний скрипт полёта ВЫКЛЮЧЕН", 2)
        return
    end
    
    -- URL скрипта полёта (из твоего запроса)
    local flyScriptURL = "https://rawscripts.net/raw/Universal-Script-Fly-gui-v3-30439"
    
    notify("Полёт", "Загрузка внешнего скрипта...", 2)
    
    local flyScript = safeLoadstring(flyScriptURL)
    if flyScript then
        -- Выполняем загруженный скрипт
        local execSuccess, execResult = pcall(function()
            flyScript()
        end)
        if execSuccess then
            flyScriptLoaded = true
            notify("Полёт", "Внешний скрипт полёта ЗАГРУЖЕН", 2)
        else
            notify("Ошибка", "Ошибка выполнения скрипта: " .. tostring(execResult), 3)
        end
    else
        notify("Ошибка", "Не удалось загрузить скрипт полёта", 3)
    end
end

-- ============================================================================
-- ФУНКЦИИ НЕВИДИМОСТИ И NOCLIP
-- ============================================================================

-- Включает/выключает невидимость для всех частей тела персонажа
local function setInvisible(bool)
    invisibleActive = bool
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = bool and 1 or 0      -- 1 = полностью прозрачный
            part.CanCollide = not bool               -- невидимый не должен сталкиваться
        end
    end
    notify("Невидимость", bool and "ВКЛЮЧЕНА" or "ВЫКЛЮЧЕНА", 1)
end

-- Включает/выключает noclip (проход сквозь стены)
local function setNoclip(bool)
    noclipActive = bool
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not bool              -- если noclip включён, столкновения отключаются
        end
    end
    notify("Noclip", bool and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН", 1)
end

-- ============================================================================
-- ФУНКЦИИ ДЛЯ УПРАВЛЕНИЯ СКОРОСТЬЮ И ПРЫЖКОМ
-- ============================================================================

-- Функция активации сверхскорости (с возможностью ввода значения)
local function activateSpeed()
    if speedActive then
        speedActive = false
        humanoid.WalkSpeed = 16
        notify("Скорость", "ВЫКЛЮЧЕНА (16)", 1)
    else
        speedActive = true
        humanoid.WalkSpeed = currentSpeed
        notify("Скорость", "ВКЛЮЧЕНА (" .. currentSpeed .. ")", 1)
    end
end

-- Функция активации сверхпрыжка
local function activateJump()
    if jumpActive then
        jumpActive = false
        humanoid.JumpPower = 50
        notify("Прыжок", "ВЫКЛЮЧЕН (50)", 1)
    else
        jumpActive = true
        humanoid.JumpPower = currentJump
        notify("Прыжок", "ВКЛЮЧЕН (" .. currentJump .. ")", 1)
    end
end

-- ============================================================================
-- ESP (ПОДСВЕТКА ИГРОКОВ ЧЕРЕЗ СТЕНЫ)
-- ============================================================================

-- Включает/выключает подсветку всех игроков (кроме себя)
local function toggleESP()
    espActive = not espActive
    local playerCount = 0
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if espActive then
                -- Создаём эффект Highlight (красная подсветка через стены)
                local highlight = Instance.new("Highlight", plr.Character)
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                playerCount = playerCount + 1
            else
                -- Удаляем подсветку
                local highlight = plr.Character:FindFirstChild("Highlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
    
    notify("ESP", espActive and ("ВКЛЮЧЕН (" .. playerCount .. " игроков)") or "ВЫКЛЮЧЕН", 1)
end

-- ============================================================================
-- ДАТА АККАУНТА ИГРОКА
-- ============================================================================

-- Возвращает возраст аккаунта в днях
local function getAccountAge(plr)
    local days = (os.time() - plr.AccountAge) / 86400
    return math.floor(days)
end

-- ============================================================================
-- ФУНКЦИЯ ВВОДА ЧИСЛА (С ПОЛНОЙ ПРОВЕРКОЙ)
-- ============================================================================

-- Создаёт всплывающее окно с полем ввода числа
local function getNumberInput(titleText, currentValue, callback)
    local guiInput = Instance.new("ScreenGui", game.CoreGui)
    guiInput.Name = "InputDialog"
    
    local frame = Instance.new("Frame", guiInput)
    frame.Size = UDim2.new(0, 260, 0, 160)
    frame.Position = UDim2.new(0.5, -130, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    
    local textBox = Instance.new("TextBox", frame)
    textBox.Size = UDim2.new(0.7, 0, 0.3, 0)
    textBox.Position = UDim2.new(0.15, 0, 0.35, 0)
    textBox.Text = tostring(currentValue)
    textBox.PlaceholderText = "введи число"
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BorderSizePixel = 1
    textBox.BorderColor3 = Color3.fromRGB(255, 0, 0)
    
    local okBtn = Instance.new("TextButton", frame)
    okBtn.Size = UDim2.new(0.3, 0, 0.22, 0)
    okBtn.Position = UDim2.new(0.1, 0, 0.73, 0)
    okBtn.Text = "OK"
    okBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
    okBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
    okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local cancelBtn = Instance.new("TextButton", frame)
    cancelBtn.Size = UDim2.new(0.3, 0, 0.22, 0)
    cancelBtn.Position = UDim2.new(0.6, 0, 0.73, 0)
    cancelBtn.Text = "ОТМЕНА"
    cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    cancelBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    okBtn.MouseButton1Click:Connect(function()
        local num = tonumber(textBox.Text)
        if num and num > 0 then
            callback(num)
            notify(titleText, "установлено: " .. num, 1)
        else
            notify("Ошибка", "Введи положительное число", 1)
        end
        guiInput:Destroy()
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        guiInput:Destroy()
    end)
end

-- ============================================================================
-- УПРАВЛЕНИЕ ДРУГИМИ ИГРОКАМИ (ПОЛНЫЙ СПИСОК ФУНКЦИЙ)
-- ============================================================================

-- Телепорт к выбранному игроку
local function tpToPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
    notify("Телепорт", "К игроку " .. p.Name, 1)
end

-- Заморозка игрока (нажатие = заморозить/разморозить)
local function freezePlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    
    if frozenPlayer then
        -- Разморозка
        if frozenPlayer.Character and frozenPlayer.Character:FindFirstChild("Humanoid") then
            frozenPlayer.Character.Humanoid.WalkSpeed = frozenPlayer.Character.Humanoid:GetAttribute("oldSpeed") or 16
        end
        frozenPlayer = nil
        notify("Заморозка", "Игрок разморожен", 1)
        return
    end
    
    -- Заморозка
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        frozenPlayer = p
        local hum = p.Character.Humanoid
        hum:SetAttribute("oldSpeed", hum.WalkSpeed)
        hum.WalkSpeed = 0
        notify("Заморозка", p.Name .. " заморожен", 1)
    end
end

-- Запереть игрока в невидимую клетку
local function jailPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    local pos = p.Character.HumanoidRootPart.Position
    local jail = Instance.new("Part", workspace)
    jail.Size = Vector3.new(8, 8, 8)
    jail.Position = pos
    jail.Anchored = true
    jail.Transparency = 0.3
    jail.BrickColor = BrickColor.new("Really red")
    jail.CanCollide = true
    jail.Material = Enum.Material.Neon
    
    p.Character.HumanoidRootPart.CFrame = jail.CFrame
    debris:AddItem(jail, 8)
    notify("Клетка", p.Name .. " заперт на 8 сек", 1)
end

-- Подкинуть игрока вверх
local function launchPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    local hrpTarget = p.Character.HumanoidRootPart
    local velocity = Instance.new("BodyVelocity", hrpTarget)
    velocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    velocity.Velocity = Vector3.new(0, 200, 0)
    debris:AddItem(velocity, 1)
    notify("Подкинут", p.Name .. " улетел в небо", 1)
end

-- Взорвать игрока
local function explodePlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    local explosion = Instance.new("Explosion", workspace)
    explosion.Position = p.Character.HumanoidRootPart.Position
    explosion.BlastRadius = 10
    explosion.BlastPressure = 100000
    notify("Взрыв", p.Name .. " взорван", 1)
end

-- Слежка за игроком (камера привязывается к нему)
local function followPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    
    if followingPlayer then
        -- Отключаем слежку
        if followConnection then followConnection:Disconnect() end
        followingPlayer = nil
        camera.CameraSubject = hrp
        camera.CameraType = Enum.CameraType.Custom
        notify("Слежка", "Режим слежки выключен", 1)
        return
    end
    
    if not p.Character then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    followingPlayer = p
    followConnection = rs.RenderStepped:Connect(function()
        if followingPlayer and followingPlayer.Character and followingPlayer.Character:FindFirstChild("HumanoidRootPart") then
            camera.CameraSubject = followingPlayer.Character.Humanoid
            camera.CameraType = Enum.CameraType.Custom
        else
            if followConnection then followConnection:Disconnect() end
            followingPlayer = nil
            camera.CameraSubject = hrp
        end
    end)
    notify("Слежка", "Слежу за " .. p.Name, 1)
end

-- Выбросить игрока за пределы карты
local function ejectFromMap(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    p.Character.HumanoidRootPart.CFrame = CFrame.new(0, -500, 0)
    notify("Выброшен", p.Name .. " выброшен с карты", 1)
end

-- Выкинуть игрока из машины (через удаление SeatWeld)
local function kickFromCar(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    
    local seatWeld = p.Character:FindFirstChild("SeatWeld")
    if seatWeld then seatWeld:Destroy() end
    p.Character.Humanoid.Sit = false
    notify("Кресло", p.Name .. " выкинут из машины", 1)
end

-- ============================================================================
-- ВЗЛОМ BROOKHAVEN (BATTLE PASS, МАШИНЫ, ДОМА, ДЕНЬГИ)
-- ============================================================================

-- Попытка разблокировать все награды Battle Pass
local function unlockBattlePass()
    local remote = replicated:FindFirstChild("ClaimReward") or 
                   replicated:FindFirstChild("BattlePassClaim") or 
                   replicated:FindFirstChild("ClaimBattlePass")
    if remote then
        for i = 1, 50 do
            pcall(function() remote:FireServer(i) end)
        end
        notify("Battle Pass", "Попытка разблокировать награды", 2)
    else
        notify("Battle Pass", "Ремоут не найден", 2)
    end
end

-- Попытка открыть все машины
local function unlockAllCars()
    local carRemote = replicated:FindFirstChild("BuyCar") or 
                      replicated:FindFirstChild("PurchaseCar") or 
                      replicated:FindFirstChild("SpawnVehicle")
    if carRemote then
        local cars = {"Police", "SportsCar", "SUV", "Truck", "Motorcycle", 
                      "Limo", "Ambulance", "FireTruck", "Taxi", "IceCreamTruck"}
        for _, car in pairs(cars) do
            pcall(function() carRemote:FireServer(car, 0) end)
        end
        notify("Машины", "Попытка открыть все машины", 2)
    else
        notify("Машины", "Ремоут не найден", 2)
    end
end

-- Попытка открыть все дома
local function unlockAllHouses()
    local houseRemote = replicated:FindFirstChild("BuyHouse") or 
                        replicated:FindFirstChild("PurchaseHouse")
    if houseRemote then
        local houses = {"ModernMansion", "BeachHouse", "Villa", "Apartment", 
                        "Penthouse", "Cabin", "Castle", "Farmhouse", "LuxuryMansion"}
        for _, house in pairs(houses) do
            pcall(function() houseRemote:FireServer(house, 0) end)
        end
        notify("Дома", "Попытка открыть все дома", 2)
    else
        notify("Дома", "Ремоут не найден", 2)
    end
end

-- Попытка установить бесконечные деньги
local function setInfiniteMoney()
    local moneyRemote = replicated:FindFirstChild("SetMoney") or 
                        replicated:FindFirstChild("UpdateCash") or 
                        replicated:FindFirstChild("AddMoney")
    if moneyRemote then
        pcall(function() moneyRemote:FireServer(999999) end)
        notify("Деньги", "Попытка установить 999999$", 2)
    else
        -- Визуальный обман (только локально)
        local playerGui = player:WaitForChild("PlayerGui")
        local moneyLabel = playerGui:FindFirstChild("MoneyLabel") or 
                           playerGui:FindFirstChild("CashDisplay") or 
                           playerGui:FindFirstChild("Balance")
        if moneyLabel then
            moneyLabel.Text = "$999999"
            notify("Деньги", "Визуально 999999$ (не реальные)", 2)
        else
            notify("Деньги", "Не удалось найти ремоут или GUI", 2)
        end
    end
end

-- ===============
