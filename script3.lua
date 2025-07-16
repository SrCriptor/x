-- Settings
local Settings = {
    -- Aimbot Settings
 AimbotOn = false,
 ShowFOV = true,
 TeamCheck = true,
 LockRadius = 100,
 FOVColor = Color3.fromRGB(255, 255, 255),
    -- ESP Settings
 ESPOn = true,
 UseTeamColors = false,
 OwnTeamColor = Color3.fromRGB(0, 0, 255),
 OpponentTeamColor = Color3.fromRGB(255, 0, 0),
    -- Gun Mod Settings
 InstantReload = false,
 InfiniteAmmo = false,
 NoRecoil = false,
 NoSpread = false,
 FastShoot = false,
    -- Character Settings
 WalkspeedOn = false,
 WalkspeedValue = 50,
 JumpheightOn = false,
 JumpheightValue = 25
}
 
local targetList = {
    {Name = "Head", Label = "Player"},
}
 
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
 
local MainWindow = Rayfield:CreateWindow({
 Name = "Global Aimbot & Gun Mods",
 Icon = 0,
 LoadingTitle = "Loading...",
 LoadingSubtitle = "by FM",
 Theme = "Default",
 
 DisableRayfieldPrompts = true,
 DisableBuildWarnings = true,
 
 ConfigurationSaving = {
  Enabled = true,
  FolderName = nil,
  FileName = "GlobalAimbotAndGunMods"
 }
})

local createdESPs = {}
 
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
 
local function createESP(target)
    local player = Players:GetPlayerFromCharacter(target.Parent)
 
    if player == LocalPlayer or not player then
        return
    end
 
    local teamColor
    if Settings.UseTeamColors then
        teamColor = player.TeamColor.Color
    else
        if player.Team == LocalPlayer.Team then
            teamColor = Settings.OwnTeamColor
        else
            teamColor = Settings.OpponentTeamColor
        end
    end
 
    local ESPBillboard = Instance.new("BillboardGui")
    ESPBillboard.Name = "ESPBillboard"
    ESPBillboard.Adornee = target
    ESPBillboard.AlwaysOnTop = true
    ESPBillboard.Size = UDim2.new(0, 100, 0, 100)
    ESPBillboard.Parent = target
 
    table.insert(createdESPs, ESPBillboard)
 
    local ESPFrame = Instance.new("Frame")
    ESPFrame.Parent = ESPBillboard
    ESPFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ESPFrame.BackgroundColor3 = teamColor
    ESPFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    ESPFrame.Size = UDim2.new(0, 5, 0, 5)
 
    local FrameUICorner = Instance.new("UICorner")
    FrameUICorner.CornerRadius = UDim.new(1, 0)
    FrameUICorner.Parent = ESPFrame
 
    local FrameUIGradient = Instance.new("UIGradient")
    FrameUIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.5))
    FrameUIGradient.Rotation = 90
    FrameUIGradient.Parent = ESPFrame
 
    local FrameUIStroke = Instance.new("UIStroke")
    FrameUIStroke.Thickness = 2.5
    FrameUIStroke.Parent = ESPFrame
 
    local ESPLabel = Instance.new("TextLabel")
    ESPLabel.Parent = ESPBillboard
    ESPLabel.AnchorPoint = Vector2.new(0, 0.5)
    ESPLabel.BackgroundTransparency = 1
    ESPLabel.Position = UDim2.new(0, 0, 0.5, 12)
    ESPLabel.Size = UDim2.new(1, 0, 0.1, 0)
    ESPLabel.Text = player and player.Name or "Unknown Player"
    ESPLabel.TextColor3 = teamColor
    ESPLabel.TextScaled = true
 
    -- local ESPLabel = Instance.new("TextLabel")
    -- ESPLabel.Parent = ESPBillboard
    -- ESPLabel.AnchorPoint = Vector2.new(0, 0.5)
    -- ESPLabel.BackgroundTransparency = 1
    -- ESPLabel.Position = UDim2.new(0, 0, 0.5, 24)
    -- ESPLabel.Size = UDim2.new(1, 0, 0.2, 0)
    -- ESPLabel.Text = player and player.Name or "Unknown Player"
    -- ESPLabel.TextColor3 = teamColor
    -- ESPLabel.TextScaled = true
 
    local TextUIStroke = Instance.new("UIStroke")
    TextUIStroke.Thickness = 2.5
    TextUIStroke.Parent = ESPLabel
 
    if target.Parent and target.Parent:FindFirstChild("Humanoid") then
        local humanoid = target.Parent:FindFirstChild("Humanoid")
        humanoid.Died:Connect(function()
            ESPBillboard:Destroy()
            for i, esp in ipairs(createdESPs) do
                if esp == ESPBillboard then
                    table.remove(createdESPs, i)
                    break
                end
            end
        end)
    end
end
 
local function removeAllESPs()
    for _, esp in ipairs(createdESPs) do
        esp:Destroy()
    end
    createdESPs = {}
end
 
local function findTarget(target, childName)
    if childName then
        return target:WaitForChild(childName)
    end
    return target
end
 
local function scanAndApplyESP()
    if not Settings.ESPOn then return end
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") or object:IsA("Model") then
            for _, target in ipairs(targetList) do
                if object.Name == target.Name then
                    local targetObject = findTarget(object, target.ChildName)
                    if targetObject then
                        createESP(targetObject)
                    end
                end
            end
        end
    end
end
 
local UIS = game:GetService("UserInputService")
local Mouse = LocalPlayer:GetMouse()
 
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.IgnoreGuiInset = true
 
local RadiusFrame = Instance.new("Frame")
RadiusFrame.Size = UDim2.new(0, Settings.LockRadius * 2, 0, Settings.LockRadius * 2)
RadiusFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
RadiusFrame.AnchorPoint = Vector2.new(0.5, 0.5)
RadiusFrame.BackgroundTransparency = 1
RadiusFrame.Visible = Settings.ShowFOV
RadiusFrame.ZIndex = 10
RadiusFrame.Parent = ScreenGui
 
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = RadiusFrame
 
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Settings.FOVColor
UIStroke.Transparency = 0.2
UIStroke.Parent = RadiusFrame
 
local lockOn = false
local lockedTarget = nil
 
local function getNearestPlayer()
    local closestPlayer = nil
    local closestDistance = Settings.LockRadius
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
 
            local head = player.Character.Head
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = head
                    end
                end
            end
        end
    end
    
    return closestPlayer
end
 
local AimbotTab = MainWindow:CreateTab("Aimbot", 4483362458)
 
local AimbotOnToggle = AimbotTab:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = Settings.AimbotOn,
    Flag = "aimboton",
    Callback = function(Value)
        Settings.AimbotOn = Value
    end,
})
 
local ShowFOVToggle = AimbotTab:CreateToggle({
    Name = "Show FOV",
    CurrentValue = Settings.ShowFOV,
    Flag = "fovtoggle",
    Callback = function(Value)
        Settings.ShowFOV = Value
        RadiusFrame.Visible = Value
    end,
})
 
local TeamCheckToggle = AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.TeamCheck,
    Flag = "teamchecktoggle",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end,
})
 
local Slider = AimbotTab:CreateSlider({
    Name = "FOV Size",
    Range = {1, 1000},
    Increment = 10,
    Suffix = "",
    CurrentValue = Settings.LockRadius,
    Flag = "FovValue",
    Callback = function(Value)
        Settings.LockRadius = Value
        RadiusFrame.Size = UDim2.new(0, Value * 2, 0, Value * 2)
    end,
})
 
local FOVColorPicker = AimbotTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Settings.FOVColor,
    Flag = "fovcolorpicker",
    Callback = function(Value)
        Settings.FOVColor = Value
        UIStroke.Color = Settings.FOVColor
    end
})
 
local ESPTab = MainWindow:CreateTab("ESP", 4483362458)
 
local ESPToggle = ESPTab:CreateToggle({
    Name = "ESP Enable",
    CurrentValue = Settings.ESPOn,
    Flag = "esptoggle",
    Callback = function(Value)
        Settings.ESPOn = Value
        if Value then
            scanAndApplyESP()
        else
            removeAllESPs()
        end
    end,
})
 
local UseTeamColorsToggle = ESPTab:CreateToggle({
    Name = "Use Team Colors",
    CurrentValue = Settings.UseTeamColors,
    Flag = "usetmcolors",
    Callback = function(Value)
        Settings.UseTeamColors = Value
        removeAllESPs()
        scanAndApplyESP()
    end,
})
 
local OwnTeamColorPicker = ESPTab:CreateColorPicker({
    Name = "Own Team Color",
    Color = Settings.OwnTeamColor,
    Flag = "ownteamcolorpicker",
    Callback = function(Value)
        Settings.OwnTeamColor = Value
        removeAllESPs()
        scanAndApplyESP()
    end
})
 
local OpponentTeamColorPicker = ESPTab:CreateColorPicker({
    Name = "Opponent Team Color",
    Color = Settings.OpponentTeamColor,
    Flag = "opponentteamcolorpicker",
    Callback = function(Value)
        Settings.OpponentTeamColor = Value
        removeAllESPs()
        scanAndApplyESP()
    end
})
 
local GunModTab = MainWindow:CreateTab("Gun Mods", 4483362458)
 
local InstantReloadToggle = GunModTab:CreateToggle({
    Name = "Instant Reload",
    CurrentValue = Settings.InstantReload,
    Flag = "instantreloadtoggle",
    Callback = function(Value)
        Settings.InstantReload = Value
    end,
})
 
local InfiniteAmmoToggle = GunModTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = Settings.InfiniteAmmo,
    Flag = "infiniteammotoggle",
    Callback = function(Value)
        Settings.InfiniteAmmo = Value
    end,
})
 
local NoRecoilToggle = GunModTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = Settings.NoRecoil,
    Flag = "norecoil",
    Callback = function(Value)
        Settings.NoRecoil = Value
    end,
})
 
local NoSpreadToggle = GunModTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = Settings.NoSpread,
    Flag = "nospread",
    Callback = function(Value)
        Settings.NoSpread = Value
    end,
})
 
local FastShootToggle = GunModTab:CreateToggle({
    Name = "Fast Shoot",
    CurrentValue = Settings.FastShoot,
    Flag = "fastshoot",
    Callback = function(Value)
        Settings.FastShoot = Value
    end,
})
 
local CharacterTab = MainWindow:CreateTab("Character", 4483362458)
 
local WalkspeedToggle = CharacterTab:CreateToggle({
    Name = "Walkspeed Enabled",
    CurrentValue = Settings.WalkspeedOn,
    Flag = "walkspeed",
    Callback = function(Value)
        Settings.WalkspeedOn = Value
    end,
})
 
local WalkspeedSlider = CharacterTab:CreateSlider({
    Name = "Walkspeed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = Settings.WalkspeedValue,
    Flag = "speed",
    Callback = function(Value)
        Settings.WalkspeedValue = Value
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value
            end
        end
    end,
})
 
local JumppowerToggle = CharacterTab:CreateToggle({
    Name = "Jumpheight Enabled",
    CurrentValue = Settings.JumpheightOn,
    Flag = "jumpheight",
    Callback = function(Value)
        Settings.JumpheightOn = Value
    end,
})
 
local JumpheightSlider = CharacterTab:CreateSlider({
    Name = "Jumpheight",
    Range = {1, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = Settings.JumpheightValue,
    Flag = "height",
    Callback = function(Value)
        Settings.JumpheightValue = Value
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpHeight = Value
            end
        end
    end,
})
 
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockOn = true
    end
end)
 
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockOn = false
        lockedTarget = nil
    end
end)
 
Workspace.DescendantAdded:Connect(function(descendant)
    if Settings.ESPOn and (descendant:IsA("BasePart") or descendant:IsA("Model")) then
        for _, target in ipairs(targetList) do
            if descendant.Name == target.Name then
                local targetObject = findTarget(descendant, target.ChildName)
                if targetObject then
                    createESP(targetObject)
                end
            end
        end
    end
end)
 
LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    
    if Settings.WalkspeedOn then
        humanoid.WalkSpeed = Settings.WalkspeedValue
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed ~= Settings.WalkspeedValue and Settings.WalkspeedOn then
                humanoid.WalkSpeed = Settings.WalkspeedValue
            end
        end)
    end
    if Settings.JumpheightOn then
        humanoid.JumpHeight = Settings.JumpheightValue
        humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
            if humanoid.JumpHeight ~= Settings.JumpheightValue and Settings.JumpheightOn then
                humanoid.JumpHeight = Settings.JumpheightValue
            end
        end)
    end
end)
 
if LocalPlayer.Character then
    local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
    if Settings.WalkspeedOn then
        humanoid.WalkSpeed = Settings.WalkspeedValue
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed ~= Settings.WalkspeedValue and Settings.WalkspeedOn then
                humanoid.WalkSpeed = Settings.WalkspeedValue
            end
        end)
    end
    if Settings.JumpheightOn then
        humanoid.JumpHeight = Settings.JumpheightValue
        humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
            if humanoid.JumpHeight ~= Settings.JumpheightValue and Settings.JumpheightOn then
                humanoid.JumpHeight = Settings.JumpheightValue
            end
        end)
    end
end
 
game:GetService("RunService").RenderStepped:Connect(function()
    if Settings.InstantReload and workspace:FindFirstChild(LocalPlayer.Name) then
        local gun = workspace[LocalPlayer.Name]:FindFirstChild(LocalPlayer.Name .. "CustomGun")
        if gun then
            gun:SetAttribute("reloadTime", 0)
        end
    end
 
    if Settings.InfiniteAmmo and workspace:FindFirstChild(LocalPlayer.Name) then
        local gun = workspace[LocalPlayer.Name]:FindFirstChild(LocalPlayer.Name .. "CustomGun")
        if gun then
            gun:SetAttribute("magazineSize", math.huge)
        end
    end
 
    if Settings.NoRecoil and workspace:FindFirstChild(LocalPlayer.Name) then
        local gun = workspace[LocalPlayer.Name]:FindFirstChild(LocalPlayer.Name .. "CustomGun")
        if gun then
            gun:SetAttribute("recoilMin", Vector2.new(0, 0))
            gun:SetAttribute("recoilMax", Vector2.new(0, 0))
            gun:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        end
    end
 
    if Settings.NoSpread and workspace:FindFirstChild(LocalPlayer.Name) then
        local gun = workspace[LocalPlayer.Name]:FindFirstChild(LocalPlayer.Name .. "CustomGun")
        if gun then
            gun:SetAttribute("spread", 0)
        end
    end
 
    if Settings.FastShoot and workspace:FindFirstChild(LocalPlayer.Name) then
        local gun = workspace[LocalPlayer.Name]:FindFirstChild(LocalPlayer.Name .. "CustomGun")
        if gun then
            gun:SetAttribute("rateOfFire", math.huge)
        end
    end
 
    if lockOn and Settings.AimbotOn then
        lockedTarget = getNearestPlayer()
        if lockedTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockedTarget.Position)
        end
    end
end)
 
scanAndApplyESP()
