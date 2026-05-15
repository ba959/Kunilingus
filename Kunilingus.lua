-- kunilingus v5.2 | Brookhaven | 1100+ lines | Clean version

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local replicated = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local debris = game:GetService("Debris")
local http = game:GetService("HttpService")

-- ========================== ПЕРЕМЕННЫЕ ==========================

local speedActive = false
local jumpActive = false
local invisibleActive = false
local espActive = false
local noclipActive = false
local selectedPlayer = nil
local currentPage = 1
local frozenPlayer = nil
local currentSpeed = 16
local currentJump = 50
local followingPlayer = nil
local followConnection = nil
local flyScriptLoaded = false

-- ========================== УВЕДОМЛЕНИЯ ==========================

local function notify(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 2
    })
end

-- ========================== БЕЗОПАСНАЯ ЗАГРУЗКА ==========================

local function safeLoadstring(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then
        notify("Ошибка HTTP", "Не удалось загрузить скрипт: " .. tostring(result), 3)
        return nil
    end
    local loadSuccess, loadResult = pcall(function()
        return loadstring(result)
    end)
    if not loadSuccess then
        notify("Ошибка", "Ошибка компиляции скрипта", 2)
        return nil
    end
    return loadResult
end

-- ========================== ВНЕШНИЙ ПОЛЁТ ==========================

local function loadExternalFlyScript()
    if flyScriptLoaded then
        if _G.FlyScriptStop then _G.FlyScriptStop()
        elseif _G.FlyEnabled then _G.FlyEnabled = false
        elseif _G.StopFly then _G.StopFly()
        end
        flyScriptLoaded = false
        notify("Полёт", "Внешний скрипт ВЫКЛЮЧЕН", 2)
        return
    end
    local flyScriptURL = "https://rawscripts.net/raw/Universal-Script-Fly-gui-v3-30439"
    notify("Полёт", "Загрузка внешнего скрипта...", 2)
    local flyScript = safeLoadstring(flyScriptURL)
    if flyScript then
        local execSuccess, execResult = pcall(function()
            flyScript()
        end)
        if execSuccess then
            flyScriptLoaded = true
            notify("Полёт", "Внешний скрипт ЗАГРУЖЕН", 2)
        else
            notify("Ошибка", "Ошибка выполнения: " .. tostring(execResult), 3)
        end
    else
        notify("Ошибка", "Не удалось загрузить скрипт полёта", 3)
    end
end

-- ========================== НЕВИДИМОСТЬ И NOCLIP ==========================

local function setInvisible(bool)
    invisibleActive = bool
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = bool and 1 or 0
            part.CanCollide = not bool
        end
    end
    notify("Невидимость", bool and "ВКЛЮЧЕНА" or "ВЫКЛЮЧЕНА", 1)
end

local function setNoclip(bool)
    noclipActive = bool
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not bool
        end
    end
    notify("Noclip", bool and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН", 1)
end

-- ========================== СКОРОСТЬ И ПРЫЖОК ==========================

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

-- ========================== ESP ==========================

local function toggleESP()
    espActive = not espActive
    local count = 0
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if espActive then
                local h = Instance.new("Highlight", plr.Character)
                h.FillColor = Color3.fromRGB(255, 0, 0)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                count = count + 1
            else
                local h = plr.Character:FindFirstChild("Highlight")
                if h then h:Destroy() end
            end
        end
    end
    notify("ESP", espActive and ("ВКЛЮЧЕН (" .. count .. ")") or "ВЫКЛЮЧЕН", 1)
end

-- ========================== ДАТА АККАУНТА ==========================

local function getAccountAge(plr)
    local days = (os.time() - plr.AccountAge) / 86400
    return math.floor(days)
end

-- ========================== ВВОД ЧИСЛА ==========================

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

-- ========================== УПРАВЛЕНИЕ ИГРОКАМИ ==========================

local function tpToPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
    notify("Телепорт", "К игроку " .. p.Name, 1)
end

local function freezePlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if frozenPlayer then
        if frozenPlayer.Character and frozenPlayer.Character:FindFirstChild("Humanoid") then
            frozenPlayer.Character.Humanoid.WalkSpeed = frozenPlayer.Character.Humanoid:GetAttribute("oldSpeed") or 16
        end
        frozenPlayer = nil
        notify("Заморозка", "Игрок разморожен", 1)
        return
    end
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        frozenPlayer = p
        local hum = p.Character.Humanoid
        hum:SetAttribute("oldSpeed", hum.WalkSpeed)
        hum.WalkSpeed = 0
        notify("Заморозка", p.Name .. " заморожен", 1)
    end
end

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

local function launchPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    local vel = Instance.new("BodyVelocity", p.Character.HumanoidRootPart)
    vel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    vel.Velocity = Vector3.new(0, 200, 0)
    debris:AddItem(vel, 1)
    notify("Подкинут", p.Name .. " улетел", 1)
end

local function explodePlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    local exp = Instance.new("Explosion", workspace)
    exp.Position = p.Character.HumanoidRootPart.Position
    exp.BlastRadius = 10
    exp.BlastPressure = 100000
    notify("Взрыв", p.Name .. " взорван", 1)
end

local function followPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if followingPlayer then
        if followConnection then followConnection:Disconnect() end
        followingPlayer = nil
        camera.CameraSubject = hrp
        camera.CameraType = Enum.CameraType.Custom
        notify("Слежка", "Выключена", 1)
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

local function ejectFromMap(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    p.Character.HumanoidRootPart.CFrame = CFrame.new(0, -500, 0)
    notify("Выброшен", p.Name .. " выброшен с карты", 1)
end

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

-- ========================== ВЗЛОМ ==========================

local function unlockBattlePass()
    local remote = replicated:FindFirstChild("ClaimReward") or replicated:FindFirstChild("BattlePassClaim") or replicated:FindFirstChild("ClaimBattlePass")
    if remote then
        for i = 1, 50 do pcall(function() remote:FireServer(i) end) end
        notify("Battle Pass", "Попытка разблокировать", 2)
    else
        notify("Battle Pass", "Ремоут не найден", 2)
    end
end

local function unlockAllCars()
    local carRemote = replicated:FindFirstChild("BuyCar") or replicated:FindFirstChild("PurchaseCar") or replicated:FindFirstChild("SpawnVehicle")
    if carRemote then
        local cars = {"Police","SportsCar","SUV","Truck","Motorcycle","Limo","Ambulance","FireTruck","Taxi","IceCreamTruck"}
        for _, car in pairs(cars) do pcall(function() carRemote:FireServer(car, 0) end) end
        notify("Машины", "Попытка открыть все", 2)
    else
        notify("Машины", "Ремоут не найден", 2)
    end
end

local function unlockAllHouses()
    local houseRemote = replicated:FindFirstChild("BuyHouse") or replicated:FindFirstChild("PurchaseHouse")
    if houseRemote then
        local houses = {"ModernMansion","BeachHouse","Villa","Apartment","Penthouse","Cabin","Castle","Farmhouse","LuxuryMansion"}
        for _, house in pairs(houses) do pcall(function() houseRemote:FireServer(house, 0) end) end
        notify("Дома", "Попытка открыть все", 2)
    else
        notify("Дома", "Ремоут не найден", 2)
    end
end

local function setInfiniteMoney()
    local moneyRemote = replicated:FindFirstChild("SetMoney") or replicated:FindFirstChild("UpdateCash") or replicated:FindFirstChild("AddMoney")
    if moneyRemote then
        pcall(function() moneyRemote:FireServer(999999) end)
        notify("Деньги", "Попытка установить 999999$", 2)
    else
        local playerGui = player:WaitForChild("PlayerGui")
        local moneyLabel = playerGui:FindFirstChild("MoneyLabel") or playerGui:FindFirstChild("CashDisplay") or playerGui:FindFirstChild("Balance")
        if moneyLabel then
            moneyLabel.Text = "$999999"
            notify("Деньги", "Визуально 999999$ (локально)", 2)
        else
            notify("Деньги", "Ремоут или GUI не найдены", 2)
        end
    end
end

-- ========================== ВЫБОР ИГРОКА ==========================

local selectGui = nil
local function showPlayerSelect()
    if selectGui then selectGui:Destroy() end
    selectGui = Instance.new("ScreenGui", game.CoreGui)
    selectGui.Name = "PlayerSelect"
    local frame = Instance.new("Frame", selectGui)
    frame.Size = UDim2.new(0, 260, 0, 380)
    frame.Position = UDim2.new(0.5, -130, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "ВЫБЕРИ ИГРОКА"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    closeBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.MouseButton1Click:Connect(function() selectGui:Destroy() end)
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(0.9, 0, 1, -55)
    scroll.Position = UDim2.new(0.05, 0, 0.12, 0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local y = 0
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton", scroll)
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(255, 0, 0)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                selectGui:Destroy()
                notify("Выбран", plr.Name, 1)
            end)
            y = y + 40
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- ========================== GUI ==========================

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "kunilingus"

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 370, 0, 500)
mainFrame.Position = UDim2.new(0.02, 0, 0.05, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
mainFrame.Active = true
mainFrame.Draggable = true

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.Text = "kunilingus v6.2 | Стр. 1/3"
titleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 35, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.Text = "❌"
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)

local openBtn = Instance.new("TextButton", game.CoreGui)
openBtn.Size = UDim2.new(0, 80, 0, 35)
openBtn.Position = UDim2.new(0.02, 0, 0.02, 0)
openBtn.Text = "OPEN"
openBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
openBtn.BorderSizePixel = 2
openBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
openBtn.Visible = false

local leftArrow = Instance.new("TextButton", mainFrame)
leftArrow.Size = UDim2.new(0, 45, 0, 35)
leftArrow.Position = UDim2.new(0.02, 0, 0.92, 0)
leftArrow.Text = "◀"
leftArrow.TextSize = 20
leftArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
leftArrow.BorderSizePixel = 1
leftArrow.BorderColor3 = Color3.fromRGB(255, 0, 0)

local rightArrow = Instance.new("TextButton", mainFrame)
rightArrow.Size = UDim2.new(0, 45, 0, 35)
rightArrow.Position = UDim2.new(0.85, 0, 0.92, 0)
rightArrow.Text = "▶"
rightArrow.TextSize = 20
rightArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
rightArrow.BorderSizePixel = 1
rightArrow.BorderColor3 = Color3.fromRGB(255, 0, 0)

local page1 = Instance.new("Frame", mainFrame)
page1.Size = UDim2.new(1, 0, 1, -85)
page1.Position = UDim2.new(0, 0, 0.12, 0)
page1.BackgroundTransparency = 1

local page2 = Instance.new("Frame", mainFrame)
page2.Size = UDim2.new(1, 0, 1, -85)
page2.Position = UDim2.new(0, 0, 0.12, 0)
page2.BackgroundTransparency = 1
page2.Visible = false

local page3 = Instance.new("Frame", mainFrame)
page3.Size = UDim2.new(1, 0, 1, -85)
page3.Position = UDim2.new(0, 0, 0.12, 0)
page3.BackgroundTransparency = 1
page3.Visible = false

local function createButton(parent, x, y, w, h, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Position = UDim2.new(x, 0, y, 0)
    btn.Size = UDim2.new(w, 0, h, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB
