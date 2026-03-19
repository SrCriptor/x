-- 🔥 ANTI-DUPLICAÇÃO
if _G.AimbotScriptLoaded then
    if _G.AimbotCleanup then
        pcall(_G.AimbotCleanup)
    end
end
_G.AimbotScriptLoaded = true

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotMode = "OFF"
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

-- PARTES
local selectedParts = {
    Head = true,
    HumanoidRootPart = false,
    UpperTorso = false
}

local bodyParts = {"Head"}
local function updateParts()
    bodyParts = {}
    for part, enabled in pairs(selectedParts) do
        if enabled then
            table.insert(bodyParts, part)
        end
    end
end
updateParts()

local aiming, shooting = false, false
local currentTarget = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotPremiumGUI"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true

-- PANEL
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 260, 0, 340)
panel.Position = UDim2.new(0, 20, 0.5, -170)
panel.BackgroundColor3 = Color3.fromRGB(20,20,25)
panel.Active = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)

local gradient = Instance.new("UIGradient", panel)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,20))
}

-- HUB
local hub = Instance.new("TextButton", gui)
hub.Size = UDim2.new(0,50,0,50)
hub.Position = panel.Position
hub.Text = "⚙️"
hub.TextScaled = true
hub.BackgroundColor3 = Color3.fromRGB(35,35,35)
hub.TextColor3 = Color3.new(1,1,1)
hub.Visible = false
Instance.new("UICorner", hub).CornerRadius = UDim.new(1,0)

-- DRAG
local dragging, dragStart, startPos
local function setupDrag(obj)
    obj.InputBegan:Connect(function(input)
        if input.UserInputType.Name:find("Mouse") or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    obj.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
setupDrag(panel)
setupDrag(hub)

-- MINIMIZAR
local minimizeBtn = Instance.new("TextButton", panel)
minimizeBtn.Size = UDim2.new(0,30,0,30)
minimizeBtn.Position = UDim2.new(1,-35,0,5)
minimizeBtn.Text = "—"

minimizeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    hub.Position = panel.Position
    hub.Visible = true
end)

hub.MouseButton1Click:Connect(function()
    panel.Visible = true
    hub.Visible = false
end)

-- HEADER
local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,35)
header.Text = "⚙️ Premium Menu"
header.BackgroundTransparency = 1
header.TextColor3 = Color3.new(1,1,1)
header.Font = Enum.Font.GothamBold

-- BOTÃO BONITO
local function createButton(text,y,callback)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1,-20,0,32)
    btn.Position = UDim2.new(0,10,0,y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", btn)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(55,55,70)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- TOGGLE
local function createToggle(text,y,flag)
    local btn
    local function update()
        btn.Text = text..": "..(_G[flag] and "ON" or "OFF")
        btn.BackgroundColor3 = _G[flag] and Color3.fromRGB(40,120,60) or Color3.fromRGB(120,40,40)
    end
    btn = createButton("",y,function()
        _G[flag]=not _G[flag]
        update()
    end)
    update()
end

-- TARGET CONFIG
local partMenu = Instance.new("Frame", panel)
partMenu.Size = UDim2.new(1,-20,0,120)
partMenu.Position = UDim2.new(0,10,0,80)
partMenu.Visible = false

local parts = {"Head","HumanoidRootPart","UpperTorso"}
local y = 5
for _,p in pairs(parts) do
    local b = Instance.new("TextButton", partMenu)
    b.Size = UDim2.new(1,-10,0,25)
    b.Position = UDim2.new(0,5,0,y)
    y+=30
    b.Text = p.." [ON]"
    b.MouseButton1Click:Connect(function()
        selectedParts[p]=not selectedParts[p]
        b.Text = p..(selectedParts[p] and " [ON]" or " [OFF]")
        updateParts()
    end)
end

createButton("🎯 Target Config",40,function()
    partMenu.Visible = not partMenu.Visible
end)

-- AIMBOT
local aimbotBtn = createButton("Aimbot: OFF",210,function()
    if _G.aimbotMode=="OFF" then _G.aimbotMode="AUTO"
    elseif _G.aimbotMode=="AUTO" then _G.aimbotMode="LEGIT"
    else _G.aimbotMode="OFF" end
    aimbotBtn.Text="Aimbot: ".._G.aimbotMode
end)

-- ESP
createToggle("ESP Inimigos",250,"espEnemiesEnabled")
createToggle("ESP Aliados",285,"espAlliesEnabled")
createToggle("FOV",320,"FOV_VISIBLE")

-- FOV
local fovCircle = Drawing.new("Circle")
RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- ESP
local highlights = {}
local function updateESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local h = highlights[p] or Instance.new("Highlight",workspace)
            highlights[p]=h
            h.Adornee=p.Character
            h.Enabled=true
            local ally = p.Team==LocalPlayer.Team
            if p==currentTarget then
                h.FillColor=Color3.fromRGB(255,255,0)
            else
                h.FillColor = ally and Color3.fromRGB(0,170,255) or Color3.fromRGB(255,50,50)
            end
        end
    end
end

-- AIMBOT
local function getClosest()
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local closest,dist=nil,_G.FOV_RADIUS

    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            for _,partName in pairs(bodyParts) do
                local part=p.Character:FindFirstChild(partName)
                if part then
                    local pos,vis=Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local mag=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if mag<dist then dist=mag closest=p end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    updateESP()

    if _G.aimbotMode=="OFF" then return end
    if _G.aimbotMode=="LEGIT" and not (aiming and shooting) then return end

    local target=getClosest()
    currentTarget=target

    if target and target.Character then
        local part=target.Character:FindFirstChild(bodyParts[1])
        if part then
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,part.Position)
        end
    end
end)

-- CLEANUP
_G.AimbotCleanup = function()
    if gui then gui:Destroy() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
end
