-- kunilingus | Blox Fruits Edition | Для Delta Executor
-- Полностью рабочий скрипт с GUI, автофармом, фруктами, ESP и телепортами

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

-- ========== ПЕРЕМЕННЫЕ ==========
local farming = false
local fruitSniper = false
local espEnabled = false
local teleportEnabled = false
local flyEnabled = false
local fastAttack = false
local currentIsland = "Начальный остров"
local farmMobs = true
local farmBosses = false

-- ========== УВЕДОМЛЕНИЯ ==========
local function notify(msg)
    game.StarterGui:SetCore("SendNotification", {
        Title = "kunilingus",
        Text = msg,
        Duration = 2
    })
end

-- ========== ESP (подсветка игроков и фруктов) ==========
local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hl = Instance.new("Highlight", plr.Character)
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
        end
        -- подсветка фруктов
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("fruit") or obj.Name:lower():find("devil") then
                local hl = Instance.new("Highlight", obj)
                hl.FillColor = Color3.fromRGB(0, 255, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            end
        end
        notify("ESP включен")
    else
        for _, hl in pairs(workspace:GetDescendants()) do
            if hl:IsA("Highlight") then hl:Destroy() end
        end
        notify("ESP выключен")
    end
end

-- ========== АВТОФАРМ ==========
local farmLoop = nil
local function toggleAutoFarm()
    farming = not farming
    if farming then
        notify("Автофарм включен")
        farmLoop = game:GetService("RunService").RenderStepped:Connect(function()
            if not farming then return end
            -- поиск ближайшего моба
            local nearest = nil
            local minDist = math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                    if v.Humanoid.Health > 0 and not v:IsDescendantOf(player.Character) then
                        local dist = (hrp.Position - v.HumanoidRootPart.Position).Magnitude
                        if dist < minDist and dist < 200 then
                            minDist = dist
                            nearest = v
                        end
                    end
                end
            end
            if nearest then
                hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                -- атака
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Activate")
                        if remote then
                            pcall(function() remote:FireServer() end)
                        end
                    end
                end
            end
        end)
    else
        if farmLoop then farmLoop:Disconnect() end
        notify("Автофарм выключен")
    end
end

-- ========== ПОИСК ФРУКТОВ ==========
local fruitLoop = nil
local function toggleFruitSniper()
    fruitSniper = not fruitSniper
    if fruitSniper then
        notify("Охота за фруктами включена")
        fruitLoop = game:GetService("RunService").RenderStepped:Connect(function()
            if not fruitSniper then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("fruit") or obj.Name:lower():find("devil") then
                    if obj:FindFirstChild("Handle") or obj:FindFirstChild("HumanoidRootPart") then
                        local pos = obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or obj.Position
                        if pos then
                            hrp.CFrame = CFrame.new(pos)
                            notify("Найден фрукт! Телепорт...")
                            wait(0.5)
                        end
                    end
                end
            end
        end)
    else
        if fruitLoop then fruitLoop:Disconnect() end
        notify("Охота за фруктами выключена")
    end
end

-- ========== ТЕЛЕПОРТЫ ==========
local islands = {
    ["Начальный остров"] = CFrame.new(-1174, 140, 550),
    ["Море 1 - Джангл"] = CFrame.new(-1200, 140, 1040),
    ["Море 1 - Тюрьма"] = CFrame.new(-4850, 890, -50),
    ["Море 2 - Зеленая зона"] = CFrame.new(-2450, 80, 850),
    ["Море 2 - Магазин"] = CFrame.new(-1870, 50, 1750),
    ["Море 3 - Замок"] = CFrame.new(-12400, 600, 11000),
    ["Море 3 - Кузница"] = CFrame.new(-11800, 400, 11200),
    ["Рейд-портал"] = CFrame.new(-5350, 150, -1150),
    ["Фруктовый продовец"] = CFrame.new(-1875, 55, 1765),
}

local function teleportTo(islandName)
    local cf = islands[islandName]
    if cf then
        hrp.CFrame = cf
        currentIsland = islandName
        notify("Телепорт на " .. islandName)
    else
        notify("Остров не найден")
    end
end

-- ========== ПОЛЁТ ==========
local bv, bg, flyConn
local function toggleFly()
    flyEnabled = not flyEnabled
    if flyEnabled then
        hum.PlatformStand = true
        bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bg = Instance.new("BodyGyro", hrp)
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyConn = game:GetService("RunService").RenderStepped:Connect(function()
            if not flyEnabled then return end
            local move = Vector3.new()
            local cam = workspace.CurrentCamera
            local forward = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local uis = game:GetService("UserInputService")
            if uis:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
            if uis:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
            if uis:IsKeyDown(Enum.KeyCode.D) then move = move + right end
            if uis:IsKeyDown(Enum.KeyCode.A) then move = move - right end
            if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            bv.Velocity = move * 120
            bg.CFrame = cam.CFrame
        end)
        notify("Полёт включен (WASD + Пробел/Ctrl)")
    else
        hum.PlatformStand = false
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if flyConn then flyConn:Disconnect() end
        notify("Полёт выключен")
    end
end

-- ========== БЫСТРЫЕ АТАКИ ==========
local function toggleFastAttack()
    fastAttack = not fastAttack
    if fastAttack then
        game:GetService("RunService").Stepped:Connect(function()
            if not fastAttack then return end
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Activate")
                    if remote then
                        pcall(function() remote:FireServer() end)
                    end
                end
            end
        end)
        notify("Быстрые атаки включены")
    else
        notify("Быстрые атаки выключены")
    end
end

-- ========== БЕССМЕРТИЕ ==========
local function godMode()
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        if hum.Health < 100 then
            hum.Health = 10000
        end
    end)
    hum.MaxHealth = 10000
    hum.Health = 10000
    notify("Режим бога включен")
end

-- ========== GUI ==========
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "kunilingus"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 350, 0, 500)
main.Position = UDim2.new(0.5, -175, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(255, 0, 0)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 45)
title.Text = "KUNILINGUS | BLOX FRUITS"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.BackgroundTransparency = 1
title.TextScaled = true

local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -40, 0, 5)
close.Text = "❌"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
close.BorderColor3 = Color3.fromRGB(255, 0, 0)

local function btn(x, y, w, h, text, callback)
    local b = Instance.new("TextButton", main)
    b.Position = UDim2.new(x, 0, y, 0)
    b.Size = UDim2.new(w, 0, h, 0)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 14
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b.BorderSizePixel = 1
    b.BorderColor3 = Color3.fromRGB(255, 0, 0)
    b.MouseButton1Click:Connect(callback)
    return b
end

-- Кнопки основных функций
btn(0.05, 0.12, 0.42, 0.11, "🔁 АВТОФАРМ", toggleAutoFarm)
btn(0.53, 0.12, 0.42, 0.11, "🍎 ОХОТА НА ФРУКТЫ", toggleFruitSniper)
btn(0.05, 0.25, 0.42, 0.11, "👁️ ESP", toggleESP)
btn(0.53, 0.25, 0.42, 0.11, "🕊️ ПОЛЁТ", toggleFly)
btn(0.05, 0.38, 0.42, 0.11, "⚡ БЫСТРЫЕ АТАКИ", toggleFastAttack)
btn(0.53, 0.38, 0.42, 0.11, "🛡️ БЕССМЕРТИЕ", godMode)

-- Телепорты (первые 4)
btn(0.05, 0.52, 0.42, 0.11, "🏝️ СТАРТ", function() teleportTo("Начальный остров") end)
btn(0.53, 0.52, 0.42, 0.11, "🌴 ДЖАНГЛ", function() teleportTo("Море 1 - Джангл") end)
btn(0.05, 0.66, 0.42, 0.11, "🏰 ЗАМОК (Море 3)", function() teleportTo("Море 3 - Замок") end)
btn(0.53, 0.66, 0.42, 0.11, "🛒 ФРУКТОВЫЙ ПРОДАВЕЦ", function() teleportTo("Фруктовый продовец") end)

-- Кнопка открытия
local open = Instance.new("TextButton", game.CoreGui)
open.Size = UDim2.new(0, 80, 0, 35)
open.Position = UDim2.new(0.02, 0, 0.02, 0)
open.Text = "OPEN"
open.TextColor3 = Color3.fromRGB(255, 0, 0)
open.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
open.BorderColor3 = Color3.fromRGB(255, 0, 0)
open.BorderSizePixel = 2
open.Visible = false

close.MouseButton1Click:Connect(function()
    main.Visible = false
    open.Visible = true
end)

open.MouseButton1Click:Connect(function()
    main.Visible = true
    open.Visible = false
end)

notify("kunilingus Blox Fruits загружен")
print("kunilingus Blox Fruits Edition loaded")
