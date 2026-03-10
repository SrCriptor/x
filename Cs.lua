-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURAÇÕES
local Config = {
    Aimbot = false, Silent = false, Trigger = false, RedDot = false, 
    PartyMode = false, FOV = 90, Smoothness = 0.15
}
local ColorList = {Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1), Color3.new(1,1,0)}
local CurCol = 1

-- GUI PRINCIPAL
local Gui = Instance.new("ScreenGui", game.CoreGui)
local ToggleBtn = Instance.new("TextButton", Gui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
ToggleBtn.Text = "-"
ToggleBtn.TextSize = 30
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Active = true
ToggleBtn.Draggable = true 

local Corner = Instance.new("UICorner", ToggleBtn)
Corner.CornerRadius = UDim.new(1, 0)

local Main = Instance.new("Frame", ToggleBtn)
Main.Size = UDim2.new(0, 180, 0, 310) 
Main.Position = UDim2.new(0, 0, 1.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    ToggleBtn.Text = Main.Visible and "-" or "+"
end)

-- FUNÇÃO CRIAR TOGGLES
local function CreateToggle(text, pos, varName, hasColor)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(hasColor and 0.7 or 0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)

    btn.MouseButton1Click:Connect(function()
        Config[varName] = not Config[varName]
        btn.BackgroundColor3 = Config[varName] and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(100, 40, 40)
        if varName == "RedDot" then Config.DotObj.Visible = Config.RedDot end
    end)
    
    if hasColor then
        local cBtn = Instance.new("TextButton", Main)
        cBtn.Size = UDim2.new(0.15, 0, 0, 35)
        cBtn.Position = UDim2.new(0.8, 0, 0, pos)
        cBtn.Text = "🎨"
        cBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        cBtn.MouseButton1Click:Connect(function()
            CurCol = (CurCol % #ColorList) + 1
            if Config.DotObj then Config.DotObj.Color = ColorList[CurCol] end
        end)
    end
end

CreateToggle("Aimbot", 10, "Aimbot")
CreateToggle("Silent", 50, "Silent")
CreateToggle("Trigger", 90, "Trigger")
CreateToggle("Red Dot", 130, "RedDot", true)
CreateToggle("Modo Festa 🌈", 170, "PartyMode")

-- FOV SEÇÃO
local fovDisplay = Instance.new("TextLabel", Main)
fovDisplay.Size = UDim2.new(0.9, 0, 0, 25)
fovDisplay.Position = UDim2.new(0.05, 0, 0, 215)
fovDisplay.Text = "FOV: " .. Config.FOV
fovDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fovDisplay.TextColor3 = Color3.new(1, 1, 1)

local fovPlus = Instance.new("TextButton", Main)
fovPlus.Size = UDim2.new(0.42, 0, 0, 30)
fovPlus.Position = UDim2.new(0.05, 0, 0, 245)
fovPlus.Text = "+"
fovPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovPlus.TextColor3 = Color3.new(1, 1, 1)

local fovMinus = Instance.new("TextButton", Main)
fovMinus.Size = UDim2.new(0.42, 0, 0, 30)
fovMinus.Position = UDim2.new(0.53, 0, 0, 245)
fovMinus.Text = "-"
fovMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovMinus.TextColor3 = Color3.new(1, 1, 1)

fovPlus.MouseButton1Click:Connect(function() Config.FOV = Config.FOV + 10 fovDisplay.Text = "FOV: "..Config.FOV end)
fovMinus.MouseButton1Click:Connect(function() Config.FOV = math.max(10, Config.FOV - 10) fovDisplay.Text = "FOV: "..Config.FOV end)

-- DESENHOS (ALTERAÇÃO AQUI: FOV TRANSPARENTE)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false     -- Garante que o meio seja transparente
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Transparency = 0.8 -- Deixa a linha sutil
FOVCircle.Visible = true

local Dot = Drawing.new("Circle")
Dot.Radius = 4
Dot.Filled = true
Dot.Visible = false
Config.DotObj = Dot

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    local center = (UserInputService.TouchEnabled and Camera.ViewportSize/2) or UserInputService:GetMouseLocation()
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV
    Dot.Position = center
    
    if Config.PartyMode then
        local hue = tick() % 1
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
                for _, part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Color = rainbowColor
                        part.Material = Enum.Material.Neon
                    end
                end
            end
        end
    end

    local isAiming = (UserInputService.TouchEnabled and Config.Aimbot) or (not UserInputService.TouchEnabled and Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if isAiming then
        local target = nil
        local dist = Config.FOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Team ~= LocalPlayer.Team then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis and (Vector2.new(pos.X, pos.Y) - center).Magnitude < dist then
                    target = p.Character.Head.Position
                    dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                end
            end
        end
        if target then
            if Config.Silent then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target), Config.Smoothness)
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target)
            end
        end
    end
end)

-- ESP ESTÁTICO
local function ApplyESP(p)
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        local isAlly = (p.Team == LocalPlayer.Team)
        local hl = Instance.new("Highlight", c)
        hl.FillColor = isAlly and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.5
        for _, part in pairs(c:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = isAlly and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(200, 140, 60)
            end
        end
    end)
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyESP(p) end end
Players.PlayerAdded:Connect(ApplyESP)
