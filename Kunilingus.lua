-- kunilingus v2.0 | Brookhaven | by cOOLkidd

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

local flying = false
local speedActive = false
local jumpActive = false
local invisibleActive = false
local espActive = false
local noclipActive = false
local bodyVel, bodyGyro, flyConn
local selectedPlayer = nil

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
        bodyVel.Velocity = move * 150
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

local function wearSkin()
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then v:Destroy() end
    end
    local shirt = Instance.new("Shirt", char)
    shirt.ShirtTemplate = "rbxassetid://10233388082"
    local pants = Instance.new("Pants", char)
    pants.PantsTemplate = "rbxassetid://10233388490"
end

local function killAll()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.Health = 0
        end
    end
end

local function tpToPlayer(p)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
    end
end

local selectGui = nil
local function showPlayerSelect()
    if selectGui then selectGui:Destroy() end
    selectGui = Instance.new("ScreenGui", game.CoreGui)
    selectGui.Name = "PlayerSelect"
    local frame = Instance.new("Frame", selectGui)
    frame.Size = UDim2.new(0, 250, 0, 300)
    frame.Position = UDim2.new(0.5, -125, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255,0,0)
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Text = "ВЫБЕРИ ИГРОКА"
    title.TextColor3 = Color3.fromRGB(255,0,0)
    title.BackgroundTransparency = 1
    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0,30,0,30)
    close.Position = UDim2.new(1,-35,0,5)
    close.Text = "X"
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

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "kunilingus"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 400)
main.Position = UDim2.new(0.02, 0, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(255,0,0)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,35)
title.Text = "kunilingus v2.0"
title.TextColor3 = Color3.fromRGB(255,0,0)
title.BackgroundTransparency = 1

local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0,35,0,30)
close.Position = UDim2.new(1,-40,0,2)
close.Text = "❌"
close.TextSize = 16
close.BackgroundColor3 = Color3.fromRGB(100,0,0)
close.BorderColor3 = Color3.fromRGB(255,0,0)

local open = Instance.new("TextButton", game.CoreGui)
open.Size = UDim2.new(0, 80, 0, 30)
open.Position = UDim2.new(0.02, 0, 0.02, 0)
open.Text = "OPEN"
open.TextColor3 = Color3.fromRGB(255,0,0)
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

local function btn(x, y, w, h, text, cb)
    local b = Instance.new("TextButton", main)
    b.Position = UDim2.new(x, 0, y, 0)
    b.Size = UDim2.new(w, 0, h, 0)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 13
    b.BackgroundColor3 = Color3.fromRGB(25,25,25)
    b.BorderSizePixel = 1
    b.BorderColor3 = Color3.fromRGB(255,0,0)
    b.MouseButton1Click:Connect(cb)
end

btn(0.02, 0.12, 0.22, 0.12, "СКОРОСТЬ", function() speedActive = not speedActive humanoid.WalkSpeed = speedActive and 150 or 16 end)
btn(0.26, 0.12, 0.22, 0.12, "ПОЛЁТ", function() if not flying then startFly() else stopFly() end end)
btn(0.50, 0.12, 0.22, 0.12, "ПРЫЖОК", function() jumpActive = not jumpActive humanoid.JumpPower = jumpActive and 300 or 50 end)
btn(0.74, 0.12, 0.24, 0.12, "НЕВИДИМ", function() setInvisible(not invisibleActive) end)

btn(0.02, 0.27, 0.22, 0.12, "NOCLIP", function() setNoclip(not noclipActive) end)
btn(0.26, 0.27, 0.22, 0.12, "ESP", toggleESP)
btn(0.50, 0.27, 0.22, 0.12, "СКИН", wearSkin)
btn(0.74, 0.27, 0.24, 0.12, "УБИТЬ ВСЕХ", killAll)

btn(0.02, 0.42, 0.22, 0.12, "ВЫБРАТЬ", showPlayerSelect)
btn(0.26, 0.42, 0.22, 0.12, "ТП К НЕМУ", function() tpToPlayer(selectedPlayer) end)
btn(0.50, 0.42, 0.22, 0.12, "ИНФО", function() 
    if selectedPlayer then
        game.StarterGui:SetCore("SendNotification", {Title = "Игрок", Text = selectedPlayer.Name, Duration = 2})
    else
        game.StarterGui:SetCore("SendNotification", {Title = "Ошибка", Text = "Сначала выбери игрока", Duration = 2})
    end
end)

print("kunilingus v2.0 loaded")
