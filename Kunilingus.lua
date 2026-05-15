-- kunilingus v2.3 | Brookhaven | ВСЁ РАБОТАЕТ

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

-- переменные
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
local currentFlySpeed = 150

-- функции
local function setInvisible(b)
    invisibleActive = b
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Transparency = b and 1 or 0
            p.CanCollide = not b
        end
    end
end

local function setNoclip(b)
    noclipActive = b
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not b
        end
    end
end

local function startFly()
    if flying then return end
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
        bodyVel.Velocity = move * currentFlySpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    flying = false
    humanoid.PlatformStand = false
    if bodyVel then bodyVel:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if flyConn then flyConn:Disconnect() end
end

local function toggleESP()
    espActive = not espActive
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if espActive then
                local h = Instance.new("Highlight", plr.Character)
                h.FillColor = Color3.fromRGB(255,0,0)
                h.OutlineColor = Color3.fromRGB(255,255,255)
                h.FillTransparency = 0.5
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                local h = plr.Character:FindFirstChild("Highlight")
                if h then h:Destroy() end
            end
        end
    end
end

local function tpToPlayer(p)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
    end
end

local function freezePlayer(p)
    if frozenPlayer then
        if frozenPlayer.Character and frozenPlayer.Character:FindFirstChild("Humanoid") then
            frozenPlayer.Character.Humanoid.WalkSpeed = frozenPlayer.Character.Humanoid:GetAttribute("oldSpeed") or 16
        end
        frozenPlayer = nil
        game.StarterGui:SetCore("SendNotification", {Title = "Заморозка", Text = "Игрок разморожен", Duration = 1})
        return
    end
    if p and p.Character and p.Character:FindFirstChild("Humanoid") then
        frozenPlayer = p
        local hum = p.Character.Humanoid
        hum:SetAttribute("oldSpeed", hum.WalkSpeed)
        hum.WalkSpeed = 0
        game.StarterGui:SetCore("SendNotification", {Title = "Заморозка", Text = "Игрок заморожен", Duration = 1})
    end
end

local function getAccountAge(plr)
    local days = (os.time() - plr.AccountAge) / 86400
    return math.floor(days)
end

-- окно выбора значения
local function showValueSelector(titleText, currentValue, callback)
    local selectorGui = Instance.new("ScreenGui", game.CoreGui)
    selectorGui.Name = "ValueSelector"
    local frame = Instance.new("Frame", selectorGui)
    frame.Size = UDim2.new(0, 250, 0, 200)
    frame.Position = UDim2.new(0.5, -125, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1,0,0,40)
    titleLabel.Text = titleText
    titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    titleLabel.BackgroundTransparency = 1
    
    local valueDisplay = Instance.new("TextLabel", frame)
    valueDisplay.Size = UDim2.new(1,0,0,40)
    valueDisplay.Position = UDim2.new(0,0,0.25,0)
    valueDisplay.Text = tostring(currentValue)
    valueDisplay.TextColor3 = Color3.fromRGB(255,255,255)
    valueDisplay.BackgroundTransparency = 1
    
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(0.8,0,0.1,0)
    slider.Position = UDim2.new(0.1,0,0.5,0)
    slider.Text = "ИЗМЕНИТЬ (введите число)"
    slider.TextColor3 = Color3.fromRGB(255,255,255)
    slider.BackgroundColor3 = Color3.fromRGB(30,30,30)
    slider.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local confirm = Instance.new("TextButton", frame)
    confirm.Size = UDim2.new(0.35,0,0.12,0)
    confirm.Position = UDim2.new(0.1,0,0.75,0)
    confirm.Text = "OK"
    confirm.TextColor3 = Color3.fromRGB(255,255,255)
    confirm.BackgroundColor3 = Color3.fromRGB(30,150,30)
    confirm.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local cancel = Instance.new("TextButton", frame)
    cancel.Size = UDim2.new(0.35,0,0.12,0)
    cancel.Position = UDim2.new(0.55,0,0.75,0)
    cancel.Text = "ОТМЕНА"
    cancel.TextColor3 = Color3.fromRGB(255,255,255)
    cancel.BackgroundColor3 = Color3.fromRGB(150,30,30)
    cancel.BorderColor3 = Color3.fromRGB(255,0,0)
    
    local newValue = currentValue
    
    slider.MouseButton1Click:Connect(function()
        local input = game:GetService("StarterGui"):SetCore("InputBegan", {UserInputType = Enum.UserInputType.Keyboard})
        local num = tonumber(string.sub(tostring(input), 1, 4))
        if num and num > 0 then
            newValue = num
            valueDisplay.Text = tostring(newValue)
        end
    end)
    
    confirm.MouseButton1Click:Connect(function()
        callback(newValue)
        selectorGui:Destroy()
    end)
    
    cancel.MouseButton1Click:Connect(function()
        selectorGui:Destroy()
    end)
end

-- окно выбора игрока
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
                game.StarterGui:SetCore("SendNotification", {Title = "Выбран", Text = plr.Name, Duration = 1})
            end)
            y = y + 40
        end
    end
    list.CanvasSize = UDim2.new(0,0,0,y)
end

-- главное окно
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "kunilingus"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.02, 0, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(255,0,0)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,35)
title.Text = "kunilingus v2.3"
title.TextColor3 = Color3.fromRGB(255,0,0)
title.BackgroundTransparency = 1
title.TextScaled = true

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
leftArrow.Position = UDim2.new(0.02,0,0.88,0)
leftArrow.Text = "◀"
leftArrow.TextColor3 = Color3.fromRGB(255,255,255)
leftArrow.BackgroundColor3 = Color3.fromRGB(30,30,30)
leftArrow.BorderColor3 = Color3.fromRGB(255,0,0)

local rightArrow = Instance.new("TextButton", main)
rightArrow.Size = UDim2.new(0,40,0,30)
rightArrow.Position = UDim2.new(0.85,0,0.88,0)
rightArrow.Text = "▶"
rightArrow.TextColor3 = Color3.fromRGB(255,255,255)
rightArrow.BackgroundColor3 = Color3.fromRGB(30,30,30)
rightArrow.BorderColor3 = Color3.fromRGB(255,0,0)

local page1 = Instance.new("Frame", main)
page1.Size = UDim2.new(1,0,1,-80)
page1.Position = UDim2.new(0,0,0.12,0)
page1.BackgroundTransparency = 1

local page2 = Instance.new("Frame", main)
page2.Size = UDim2.new(1,0,1,-80)
page2.Position = UDim2.new(0,0,0.12,0)
page2.BackgroundTransparency = 1
page2.Visible = false

local function btn(parent, x, y, w, h, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Position = UDim2.new(x, 0, y, 0)
    b.Size = UDim2.new(w, 0, h, 0)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 14
    b.BackgroundColor3 = Color3.fromRGB(20,20,20)
    b.BorderSizePixel = 1
    b.BorderColor3 = Color3.fromRGB(255,0,0)
    b.MouseButton1Click:Connect(cb)
end

-- страница 1
btn(page1, 0.05, 0.05, 0.42, 0.14, "СКОРОСТЬ", function()
    showValueSelector("Скорость (WalkSpeed)", currentSpeed, function(val)
        currentSpeed = val
        if speedActive then humanoid.WalkSpeed = currentSpeed end
    end)
end)
btn(page1, 0.52, 0.05, 0.42, 0.14, "ПОЛЁТ", function()
    showValueSelector("Скорость полёта", currentFlySpeed, function(val)
        currentFlySpeed = val
        if flying then
            stopFly()
            startFly()
        end
    end)
end)
btn(page1, 0.05, 0.22, 0.42, 0.14, "ПРЫЖОК", function()
    showValueSelector("Сила прыжка", currentJump, function(val)
        currentJump = val
        if jumpActive then humanoid.JumpPower = currentJump end
    end)
end)
btn(page1, 0.52, 0.22, 0.42, 0.14, "НЕВИДИМ", function() setInvisible(not invisibleActive) end)
btn(page1, 0.05, 0.39, 0.42, 0.14, "NOCLIP", function() setNoclip(not noclipActive) end)
btn(page1, 0.52, 0.39, 0.42, 0.14, "ESP", toggleESP)

-- страница 2
btn(page2, 0.05, 0.05, 0.42, 0.14, "ВЫБРАТЬ", showPlayerSelect)
btn(page2, 0.52, 0.05, 0.42, 0.14, "ТП К НЕМУ", function() tpToPlayer(selectedPlayer) end)
btn(page2, 0.05, 0.22, 0.42, 0.14, "ЗАМОРОЗИТЬ", function() freezePlayer(selectedPlayer) end)
btn(page2, 0.52, 0.22, 0.42, 0.14, "ИНФО", function()
    if selectedPlayer then
        local age = getAccountAge(selectedPlayer)
        game.StarterGui:SetCore("SendNotification", {Title = selectedPlayer.Name, Text = "Аккаунт создан " .. age .. " дн. назад", Duration = 3})
    else
        game.StarterGui:SetCore("SendNotification", {Title = "Ошибка", Text = "Сначала выбери игрока", Duration = 2})
    end
end)

local function updatePage()
    page1.Visible = (currentPage == 1)
    page2.Visible = (currentPage == 2)
end

leftArrow.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

rightArrow.MouseButton1Click:Connect(function()
    if currentPage < 2 then
        currentPage = currentPage + 1
        updatePage()
    end
end)

local open = Instance.new("TextButton", game.CoreGui)
open.Size = UDim2.new(0, 80, 0, 30)
open.Position = UDim2.new(0.02, 0, 0.02, 0)
open.Text = "OPEN"
open.TextColor3 = Color3.fromRGB(255,255,255)
open.BackgroundColor3 = Color3.fromRGB(0,0,0)
open.BorderColor3 = Color3.fromRGB(255,0,0)
open.Visible = false
open.MouseButton1Click:Connect(function()
    main.Visible = true
    open.Visible = false
end)
close.MouseButton1Click:Connect(function()
    main.Visible = false
    open.Visible = true
end)

updatePage()
print("kunilingus v2.3 loaded")
