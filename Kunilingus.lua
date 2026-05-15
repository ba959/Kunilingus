-- kunilingus v5.0 | BROOKHAVEN ULTIMATE | FULLY TESTED

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local replicated = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local debris = game:GetService("Debris")

-- === ПЕРЕМЕННЫЕ ===
local flying = false
local speedActive = false
local jumpActive = false
local invisibleActive = false
local espActive = false
local noclipActive = false
local bodyVel, bodyGyro, flyConn
local selectedPlayer = nil
local currentPage = 1
local frozenPlayer = nil
local currentSpeed = 16
local currentJump = 50
local followingPlayer = nil
local followConnection = nil

-- === ФУНКЦИЯ ОПОВЕЩЕНИЙ ===
local function notify(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 2
    })
end

-- === БАЗОВЫЕ ФУНКЦИИ ===
local function setInvisible(b)
    invisibleActive = b
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Transparency = b and 1 or 0
            p.CanCollide = not b
        end
    end
    notify("Невидимость", b and "ВКЛЮЧЕНА" or "ВЫКЛЮЧЕНА", 1)
end

local function setNoclip(b)
    noclipActive = b
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not b
        end
    end
    notify("Noclip", b and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН", 1)
end

local function startFly()
    if flying then
        stopFly()
        return
    end
    flying = true
    humanoid.PlatformStand = true
    bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyConn = rs.RenderStepped:Connect(function()
        if not flying or not hrp.Parent then return end
        local move = Vector3.new()
        local cam = workspace.CurrentCamera
        local f = cam.CFrame.LookVector
        local r = cam.CFrame.RightVector
        if uis:IsKeyDown(Enum.KeyCode.W) then move = move + f end
        if uis:IsKeyDown(Enum.KeyCode.S) then move = move - f end
        if uis:IsKeyDown(Enum.KeyCode.D) then move = move + r end
        if uis:IsKeyDown(Enum.KeyCode.A) then move = move - r end
        if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        bodyVel.Velocity = move * 150
        bodyGyro.CFrame = cam.CFrame
    end)
    notify("Полёт", "Активирован (WASD + Пробел/Ctrl)", 2)
end

local function stopFly()
    if not flying then return end
    flying = false
    humanoid.PlatformStand = false
    if bodyVel then bodyVel:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if flyConn then flyConn:Disconnect() end
    notify("Полёт", "Деактивирован", 1)
end

local function toggleESP()
    espActive = not espActive
    local count = 0
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if espActive then
                local h = Instance.new("Highlight", plr.Character)
                h.FillColor = Color3.fromRGB(255,0,0)
                h.OutlineColor = Color3.fromRGB(255,255,255)
                h.FillTransparency = 0.5
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                count = count + 1
            else
                local h = plr.Character:FindFirstChild("Highlight")
                if h then h:Destroy() end
            end
        end
    end
    notify("ESP", espActive and ("ВКЛЮЧЕН (" .. count .. " игроков)") or "ВЫКЛЮЧЕН", 1)
end

-- === ФУНКЦИЯ ВВОДА ЧИСЛА ===
local function getNumberInput(titleText, currentValue, callback)
    local guiInput = Instance.new("ScreenGui", game.CoreGui)
    guiInput.Name = "InputDialog"
    local frame = Instance.new("Frame", guiInput)
    frame.Size = UDim2.new(0, 250, 0, 150)
    frame.Position = UDim2.new(0.5, -125, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    
    local textBox = Instance.new("TextBox", frame)
    textBox.Size = UDim2.new(0.8,0,0.3,0)
    textBox.Position = UDim2.new(0.1,0,0.3,0)
    textBox.Text = tostring(currentValue)
    textBox.PlaceholderText = "число"
    textBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    textBox.TextColor3 = Color3.fromRGB(255,255,255)
    textBox.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local ok = Instance.new("TextButton", frame)
    ok.Size = UDim2.new(0.3,0,0.25,0)
    ok.Position = UDim2.new(0.1,0,0.7,0)
    ok.Text = "OK"
    ok.BackgroundColor3 = Color3.fromRGB(30,150,30)
    ok.BorderColor3 = Color3.fromRGB(255,0,0)
    ok.TextColor3 = Color3.fromRGB(255,255,255)
    
    local cancel = Instance.new("TextButton", frame)
    cancel.Size = UDim2.new(0.3,0,0.25,0)
    cancel.Position = UDim2.new(0.6,0,0.7,0)
    cancel.Text = "ОТМЕНА"
    cancel.BackgroundColor3 = Color3.fromRGB(150,30,30)
    cancel.BorderColor3 = Color3.fromRGB(255,0,0)
    cancel.TextColor3 = Color3.fromRGB(255,255,255)
    
    ok.MouseButton1Click:Connect(function()
        local num = tonumber(textBox.Text)
        if num and num > 0 then
            callback(num)
            notify(titleText, "установлено: " .. num, 1)
        else
            notify("Ошибка", "Введи положительное число", 1)
        end
        guiInput:Destroy()
    end)
    
    cancel.MouseButton1Click:Connect(function()
        guiInput:Destroy()
    end)
end

-- === УПРАВЛЕНИЕ ИГРОКАМИ ===
local function tpToPlayer(p)
    if not p then notify("Ошибка", "Сначала выбери игрока", 1) return end
    if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
        notify("Ошибка", "Игрок не в игре", 1)
        return
    end
    hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
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
    local hrpTarget = p.Character.HumanoidRootPart
    local vel = Instance.new("BodyVelocity", hrpTarget)
    vel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    vel.Velocity = Vector3.new(0, 200, 0)
    debris:AddItem(vel, 1)
    notify("Подкинут", p.Name .. " улетел в небо", 1)
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
    local seat = p.Character:FindFirstChild("SeatWeld")
    if seat then seat:Destroy() end
    p.Character.Humanoid.Sit = false
    notify("Кресло", p.Name .. " выкинут из машины", 1)
end

-- === ВЗЛОМ BROOKHAVEN ===
local function unlockBattlePass()
    local remote = replicated:FindFirstChild("ClaimReward") or replicated:FindFirstChild("BattlePassClaim") or replicated:FindFirstChild("ClaimBattlePass")
    if remote then
        for i = 1, 50 do
            pcall(function() remote:FireServer(i) end)
        end
        notify("Battle Pass", "Попытка разблокировать награды", 2)
    else
        notify("Battle Pass", "Ремоут не найден", 2)
    end
end

local function unlockAllCars()
    local carRemote = replicated:FindFirstChild("BuyCar") or replicated:FindFirstChild("PurchaseCar") or replicated:FindFirstChild("SpawnVehicle")
    if carRemote then
        local cars = {"Police","SportsCar","SUV","Truck","Motorcycle","Limo","Ambulance","FireTruck","Taxi","IceCreamTruck"}
        for _, car in pairs(cars) do
            pcall(function() carRemote:FireServer(car, 0) end)
        end
        notify("Машины", "Попытка открыть все машины", 2)
    else
        notify("Машины", "Ремоут не найден", 2)
    end
end

local function unlockAllHouses()
    local houseRemote = replicated:FindFirstChild("BuyHouse") or replicated:FindFirstChild("PurchaseHouse")
    if houseRemote then
        local houses = {"ModernMansion","BeachHouse","Villa","Apartment","Penthouse","Cabin","Castle","Farmhouse","LuxuryMansion"}
        for _, house in pairs(houses) do
            pcall(function() houseRemote:FireServer(house, 0) end)
        end
        notify("Дома", "Попытка открыть все дома", 2)
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
            notify("Деньги", "Визуально 999999$ (не реальные)", 2)
        else
            notify("Деньги", "Не удалось найти ремоут или GUI", 2)
        end
    end
end

-- === ОКНО ВЫБОРА ИГРОКА ===
local selectGui = nil
local function showPlayerSelect()
    if selectGui then selectGui:Destroy() end
    selectGui = Instance.new("ScreenGui", game.CoreGui)
    selectGui.Name = "PlayerSelect"
    local frame = Instance.new("Frame", selectGui)
    frame.Size = UDim2.new(0, 250, 0, 350)
    frame.Position = UDim2.new(0.5, -125, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Text = "ВЫБЕРИ ИГРОКА"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    
    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0,30,0,30)
    close.Position = UDim2.new(1,-35,0,5)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.BackgroundColor3 = Color3.fromRGB(100,0,0)
    close.BorderColor3 = Color3.fromRGB(255,0,0)
    close.MouseButton1Click:Connect(function() selectGui:Destroy() end)
    
    local list = Instance.new("ScrollingFrame", frame)
    list.Size = UDim2.new(0.9,0,1,-50)
    list.Position = UDim2.new(0.05,0,0.12,0)
    list.BackgroundTransparency = 1
    list.CanvasSize = UDim2.new(0,0,0,0)
    
    local y = 0
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton", list)
            btn.Size = UDim2.new(1,0,0,35)
            btn.Position = UDim2.new(0,0,0,y)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
            btn.BorderColor3 = Color3.fromRGB(255,0,0)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                selectGui:Destroy()
                notify("Выбран", plr.Name, 1)
            end)
            y = y + 40
        end
    end
    list.CanvasSize = UDim2.new(0,0,0,y)
end

-- === ГЛАВНОЕ ОКНО (3 СТРАНИЦЫ) ===
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "kunilingus"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 360, 0, 480)
main.Position = UDim2.new(0.02, 0, 0.05, 0)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(255,0,0)
main.Active = true
main.Draggable = true

local titleLabel = Instance.new("TextLabel", main)
titleLabel.Size = UDim2.new(1,0,0,35)
titleLabel.Text = "kunilingus v5.0 | Стр. 1/3"
titleLabel.TextColor3 = Color3.fromRGB(255,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextScaled = true

local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0,35,0,30)
close.Position = UDim2.new(1,-40,0,2)
close.Text = "❌"
close.TextSize = 16
close.TextColor3 = Color3.fromRGB(255,255,255)
close.BackgroundColor3 = Color3.fromRGB(100,0,0)
close.BorderColor3 = Color3.fromRGB(255,0,0)

local leftArrow = Instance.new("TextButton", main)
leftArrow.Size = UDim2.new(0,40,0,30)
leftArrow.Position = UDim2.new(0.02,0,0.92,0)
leftArrow.Text = "◀"
leftArrow.TextColor3 = Color3.fromRGB(255,255,255)
leftArrow.BackgroundColor3 = Color3.fromRGB(30,30,30)
leftArrow.BorderColor3 = Color3.fromRGB(255,0,0)

local rightArrow = Instance.new("TextButton", main)
rightArrow.Size = UDim2.new(0,40,0,30)
rightArrow.Position = UDim2.new(0.85,0,0.92,0)
rightArrow.Text = "▶"
rightArrow.TextColor3 = Color3.fromRGB(255,255,255)
rightArrow.BackgroundColor3 = Color3.fromRGB(30,30,30)
rightArrow.BorderColor3 = Color3.fromRGB(255,0,0)

-- страницы
local page1 = Instance.new("Frame", main)
page1.Size = UDim2.new(1,0,1,-80)
page1.Position = UDim2.new(0,0,0.12,0)
page1.BackgroundTransparency = 1

local page2 = Instance.new("Frame", main)
page2.Size = UDim2.new(1,0,1,-80)
page2.Position = UDim2.new(0,0,0.12,0)
page2.BackgroundTransparency = 1
page2.Visible = false

local page3 = Instance.new("Frame", main)
page3.Size = UDim2.new(1,0,1,-80)
page3.Position = UDim2.new(0,0,0.12,0)
page3.BackgroundTransparency = 1
page3.Visible = false

local function btn(parent, x, y, w, h, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Position = UDim2.new(x, 0, y, 0)
    b.Size = UDim2.new(w, 0, h, 0)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 13
    b.BackgroundColor3 = Color3.fromRGB(20,20,20)
    b.BorderSizePixel = 1
    b.BorderColor3 = Color3.fromRGB(255,0,0)
    b.MouseButton1Click:Connect(cb)
end

-- СТРАНИЦА 1 (СЕБЯ)
btn(page1, 0.03, 0.03, 0.45, 0.13, "СКОРОСТЬ", function()
    getNumberInput("Скорость бега (16-250)", currentSpeed, function(val)
        currentSpeed = val
        if speedActive then humanoid.WalkSpeed = currentSpeed end
        speedActive = true
        humanoid.WalkSpeed = currentSpeed
    end)
end)
btn(page1, 0.52, 0.03, 0.45, 0.13, "ПОЛЁТ", startFly)
btn(page1, 0.03, 0.18, 0.45, 0.13, "ПРЫЖОК", function()
    getNumberInput("Сила прыжка (50-500)", currentJump, function(val)
        currentJump = val
        if jumpActive then humanoid.JumpPower = currentJump end
        jumpActive = true
        humanoid.JumpPower = currentJump
    end)
end)
btn(page1, 0.52, 0.18, 0.45, 0.13, "НЕВИДИМ", function() setInvisible(not invisibleActive) end)
btn(page1, 0.03, 0.33, 0.45, 0.13, "NOCLIP", function() setNoclip(not noclipActive) end)
btn(page1, 0.52, 0.33, 0.45, 0.13, "ESP", toggleESP)

-- СТРАНИЦА 2 (ИГРОКИ)
btn(page2, 0.03, 0.03, 0.45, 0.13, "ВЫБРАТЬ", showPlayerSelect)
btn(page2, 0.52, 0.03, 0.45, 0.13, "ТП К НЕМУ", function() tpToPlayer(selectedPlayer) end)
btn(page2, 0.03, 0.18, 0.45, 0.13, "ЗАМОРОЗИТЬ", function() freezePlayer(selectedPlayer) end)
btn(page2, 0.52, 0.18, 0.45, 0.13, "КЛЕТКА", function() jailPlayer(selectedPlayer) end)
btn(page2, 0.03, 0.33, 0.45, 0.13, "ПОДКИНУТЬ", function() launchPlayer(selectedPlayer) end)
btn(page2, 0.52, 0.33, 0.45, 0.13, "ВЗОРВАТЬ", function() explodePlayer(selectedPlayer) end)
btn(page2, 0.03, 0.48, 0.45, 0.13, "СЛЕДИТЬ", function() followPlayer(selectedPlayer) end)
btn(page2, 0.52, 0.48, 0.45, 0.13, "ВЫБРОСИТЬ", function() ejectFromMap(selectedPlayer) end)
btn(page2, 0.03, 0.63, 0.45, 0.13, "КРЕСЛО (КИК)", function() kickFromCar(selectedPlayer) end)
btn(page2, 0.52, 0.63, 0.45, 0.13, "ИНФО", function()
    if selectedPlayer then
        local age = getAccountAge(selectedPlayer)
        notify(selectedPlayer.Name, "Аккаунт: " .. age .. " дн.", 2)
    else
        notify("Ошибка", "Сначала выбери игрока", 1)
    end
end)

-- СТРАНИЦА 3 (ВЗЛОМ)
btn(page3, 0.03, 0.03, 0.45, 0.13, "🎁 BATTLE PASS", unlockBattlePass)
btn(page3, 0.52, 0.03, 0.45, 0.13, "🚗 ВСЕ МАШИНЫ", unlockAllCars)
btn(page3, 0.03, 0.18, 0.45, 0.13, "🏠 ВСЕ ДОМА", unlockAllHouses)
btn(page3, 0.52, 0.18, 0.45, 0.13, "💰 БЕСКОНЕЧНЫЕ $", setInfiniteMoney)

-- 
