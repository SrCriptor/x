-- 🗑️ LIMPEZA DE SCRIPTS ANTERIORES E OTIMIZAÇÃO
if _G.SupremeHubRunning then
    warn("Limpando versão anterior do Supreme Hub...")
    if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end
end
_G.SupremeHubRunning = true

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then pcall(function() obj:Destroy() end) end
end
if _G.clearDrawings then _G.clearDrawings() end

-- ==================== SERVIÇOS E VARIÁVEIS ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local currentTarget, currentTargetPart = nil, nil
local aiming = false
local aimbotKey = Enum.UserInputType.MouseButton2 
local triggerBotCooldown, lastAntiAimTick = false, tick()
local legitReactionTimer, lastLegitTarget = 0, nil

-- CONFIGURAÇÕES GLOBAIS
_G.streamerMode = false
_G.FOV_RADIUS = 150
_G.FOV_VISIBLE = true

-- Radar
_G.espRadar = false
_G.RADAR_SIZE = 150
_G.MAP_SCALE = 2

-- Aimbot
_G.aimbotMode = "Rage"
_G.legitDeadzone = 50
_G.aimbotAutoEnabled, _G.aimbotManualEnabled = false, false
_G.silentAimEnabled, _G.silentAimHitChance = false, 100
_G.aimbotSmoothness = 1
_G.wallCheckEnabled = false
_G.aimPredictionEnabled, _G.aimPredictionForce = false, 0.135
_G.triggerBotEnabled, _G.triggerBotDelay = false, 0.05

-- ESP Séries
_G.espEnemyBox, _G.espEnemyChams, _G.espEnemyTracers, _G.espEnemySkeleton, _G.espEnemyText = true, true, false, false, true
_G.espAllyBox, _G.espAllyChams, _G.espAllyTracers, _G.espAllySkeleton, _G.espAllyText = false, false, false, false, false
_G.espName, _G.espHP, _G.espDistance, _G.espWeapon = false, false, false, false
_G.espMaxDistance = 5000

-- Mods
_G.antiAimLegitEnabled, _G.noRecoilEnabled, _G.noSpreadEnabled, _G.infiniteAmmoEnabled, _G.instantReloadEnabled = false, false, false, false, false
_G.hitboxExpander, _G.walkSpeed, _G.jumpPower = 2, 16, 50

-- ==================== NATIVE DRAWING SYSTEM ====================
local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

if coreGui:FindFirstChild("SupremeDrawSpace") then coreGui.SupremeDrawSpace:Destroy() end
local supremeDrawSpace = Instance.new("ScreenGui", coreGui)
supremeDrawSpace.Name = "SupremeDrawSpace"
supremeDrawSpace.IgnoreGuiInset = true 
supremeDrawSpace.ResetOnSpawn = false

if coreGui:FindFirstChild("SupremeRadar") then coreGui.SupremeRadar:Destroy() end
local radarGui = Instance.new("ScreenGui", coreGui)
radarGui.Name = "SupremeRadar"
radarGui.ResetOnSpawn = false

local radarBg = Instance.new("Frame", radarGui)
radarBg.Size = UDim2.new(0, _G.RADAR_SIZE, 0, _G.RADAR_SIZE)
radarBg.Position = UDim2.new(1, -(_G.RADAR_SIZE + 20), 0, 20) 
radarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
radarBg.BackgroundTransparency = 0.5
radarBg.ClipsDescendants = true
radarBg.Visible = _G.espRadar and not _G.streamerMode
radarBg.Active = true
radarBg.Draggable = true
Instance.new("UICorner", radarBg).CornerRadius = UDim.new(1, 0)

local centerPoint = Instance.new("Frame", radarBg)
centerPoint.Size = UDim2.new(0, 6, 0, 6)
centerPoint.Position = UDim2.new(0.5, -3, 0.5, -3)
centerPoint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", centerPoint).CornerRadius = UDim.new(1, 0)

local fovFrame = Instance.new("Frame", supremeDrawSpace)
fovFrame.BackgroundTransparency = 1
local fovStroke = Instance.new("UIStroke", fovFrame); fovStroke.Color = Color3.fromRGB(255, 255, 255); fovStroke.Thickness = 1.5; fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local fovCorner = Instance.new("UICorner", fovFrame); fovCorner.CornerRadius = UDim.new(1, 0)

local tracers, espTexts, highlights, skeletons, boxes, radarBlips = {}, {}, {}, {}, {}, {}

local function createBox()
    local f = Instance.new("Frame", supremeDrawSpace)
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0
    local stroke = Instance.new("UIStroke", f); stroke.Thickness = 1.5
    return f
end
local function createLine()
    local f = Instance.new("Frame", supremeDrawSpace)
    f.BorderSizePixel = 0; f.AnchorPoint = Vector2.new(0.5, 0.5)
    return f
end
local function createText()
    local t = Instance.new("TextLabel", supremeDrawSpace)
    t.BackgroundTransparency = 1; t.Size = UDim2.new(0, 200, 0, 50); t.AnchorPoint = Vector2.new(0.5, 0.5)
    t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.TextStrokeTransparency = 0.2; t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    return t
end
local function createRadarBlip(player)
    local blip = Instance.new("Frame")
    blip.Size = UDim2.new(0, 6, 0, 6)
    blip.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    Instance.new("UICorner", blip).CornerRadius = UDim.new(1, 0)
    blip.Parent = radarBg
    radarBlips[player] = blip
    return blip
end

local skeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function removeESP(player)
    if tracers[player] then tracers[player]:Destroy(); tracers[player] = nil end
    if espTexts[player] then espTexts[player]:Destroy(); espTexts[player] = nil end
    if boxes[player] then boxes[player]:Destroy(); boxes[player] = nil end
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
    if skeletons[player] then for _, line in pairs(skeletons[player]) do line:Destroy() end; skeletons[player] = nil end
    if radarBlips[player] then radarBlips[player]:Destroy(); radarBlips[player] = nil end
end

_G.clearDrawings = function()
    for _, v in pairs(supremeDrawSpace:GetChildren()) do v:Destroy() end
    for player, _ in pairs(tracers) do removeESP(player) end
    if radarGui then radarGui:Destroy() end
end

-- ==================== HITBOX SYSTEM ====================
_G.HitboxStates = { ["Head"] = 1, ["Torso"] = 0, ["Left Arm"] = 0, ["Right Arm"] = 0, ["Left Leg"] = 0, ["Right Leg"] = 0 }
local function saveBoneco() if writefile then pcall(function() writefile("SupremeHubBoneco.json", HttpService:JSONEncode(_G.HitboxStates)) end) end end
local function loadBoneco()
    if readfile then pcall(function() 
        local decoded = HttpService:JSONDecode(readfile("SupremeHubBoneco.json"))
        if type(decoded) == "table" then for k, v in pairs(decoded) do _G.HitboxStates[k] = v end end
    end) end
end
loadBoneco()

local bonecoFrame
local function createBonecoInterface()
    if coreGui:FindFirstChild("BonequinhoHitboxUI") then coreGui.BonequinhoHitboxUI:Destroy() end

    local gui = Instance.new("ScreenGui", coreGui); gui.Name = "BonequinhoHitboxUI"; gui.ResetOnSpawn = false
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0, 200, 0, 280), UDim2.new(0.5, 150, 0.5, -140)
    frame.BackgroundColor3, frame.BorderSizePixel = Color3.fromRGB(28, 28, 30), 0
    frame.Active, frame.Draggable, frame.Visible = true, true, false
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", frame)
    title.Size, title.BackgroundTransparency = UDim2.new(1, 0, 0, 35), 1
    title.Text, title.TextColor3, title.Font, title.TextSize = "Hitbox Selector", Color3.new(1, 1, 1), Enum.Font.GothamBold, 16

    local close = Instance.new("TextButton", title)
    close.Size, close.Position, close.BackgroundTransparency = UDim2.new(0, 35, 0, 35), UDim2.new(1, -35, 0, 0), 1
    close.Text, close.TextColor3, close.Font, close.TextSize = "X", Color3.fromRGB(255, 60, 60), Enum.Font.GothamBold, 16
    close.MouseButton1Click:Connect(function() frame.Visible = false end)

    local help = Instance.new("TextLabel", frame)
    help.Size, help.Position, help.BackgroundTransparency = UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 1, -45), 1
    help.Text, help.TextColor3, help.Font, help.TextSize = "Cinza: Off | Verm: Foco\nAmar: Secundário", Color3.fromRGB(180, 180, 180), Enum.Font.Gotham, 11

    local colors = { [0] = Color3.fromRGB(70, 70, 70), [1] = Color3.fromRGB(255, 60, 60), [2] = Color3.fromRGB(255, 200, 50) }
    local function createPart(name, size, pos)
        local btn = Instance.new("TextButton", frame)
        btn.Size, btn.Position, btn.BackgroundColor3 = size, pos, colors[_G.HitboxStates[name] or 0]
        btn.Text, btn.AutoButtonColor = "", false; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            _G.HitboxStates[name] = ((_G.HitboxStates[name] or 0) + 1) % 3
            btn.BackgroundColor3 = colors[_G.HitboxStates[name]]; saveBoneco()
        end)
    end

    createPart("Head", UDim2.new(0, 46, 0, 46), UDim2.new(0, 77, 0, 42))
    createPart("Torso", UDim2.new(0, 68, 0, 82), UDim2.new(0, 66, 0, 92))
    createPart("Left Arm", UDim2.new(0, 28, 0, 82), UDim2.new(0, 34, 0, 92))
    createPart("Right Arm", UDim2.new(0, 28, 0, 82), UDim2.new(0, 138, 0, 92))
    createPart("Left Leg", UDim2.new(0, 32, 0, 86), UDim2.new(0, 66, 0, 178))
    createPart("Right Leg", UDim2.new(0, 32, 0, 86), UDim2.new(0, 102, 0, 178))
    return frame
end
bonecoFrame = createBonecoInterface()

-- ==================== FIND ORION GUI SECURELY ====================
local function findOrionGui()
    for _, child in pairs(coreGui:GetDescendants()) do
        if child:IsA("TextLabel") and (string.find(child.Text, "Supreme Hub") or string.find(child.Text, "Premium Script")) then
            local p = child:FindFirstAncestorOfClass("ScreenGui")
            if p then return p end
        end
    end
    return nil
end

-- ==================== MOBILE HUB BUTTON ====================
local function createMobileButton()
    if coreGui:FindFirstChild("SupremeMobileHub") then coreGui.SupremeMobileHub:Destroy() end
    local mobileGui = Instance.new("ScreenGui", coreGui); mobileGui.Name = "SupremeMobileHub"; mobileGui.ResetOnSpawn = false
    local btn = Instance.new("TextButton", mobileGui)
    btn.Size, btn.Position = UDim2.new(0, 55, 0, 55), UDim2.new(1, -70, 0, 100)
    btn.BackgroundColor3, btn.BorderSizePixel = Color3.fromRGB(20, 20, 20), 0
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize = "HUB", Color3.fromRGB(255, 60, 60), Enum.Font.GothamBold, 14
    btn.Active, btn.Draggable = true, true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn); stroke.Color, stroke.Thickness = Color3.fromRGB(255, 60, 60), 2
    btn.MouseButton1Click:Connect(function() local o = findOrionGui(); if o then o.Enabled = not o.Enabled end end)
end
if isMobile then createMobileButton() end

-- ==================== INTERFACE ORION ====================
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({ Name = "⚡ Supreme Hub | Premium Script 🔥", HidePremium = false, SaveConfig = true, ConfigFolder = "SupremeHubConfig", ConfigName = "SAutoSave" })

local function zSave() pcall(function() OrionLib:SaveConfig() end) end

local TabCombat = Window:MakeTab({ Name = "💥 Combat", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabVisuals = Window:MakeTab({ Name = "👁️ Visuals", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local TabWeapon = Window:MakeTab({ Name = "🔫 Weapon", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabPlayer = Window:MakeTab({ Name = "👟 Player", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabMisc = Window:MakeTab({ Name = "⚙️ Misc", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabConfig = Window:MakeTab({ Name = "🛡️ Config", Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- 💥 TAB COMBAT
local SCombatModos = TabCombat:AddSection({ Name = "🎯 AIMBOT & SILENT AIM" })
SCombatModos:AddDropdown({ Name = "Modo do Aimbot", Default = _G.aimbotMode, Options = {"Rage", "Legit"}, Save = true, Flag = "AMode", Callback = function(V) _G.aimbotMode = V; zSave() end })
SCombatModos:AddToggle({ Name = "Aimbot Automático", Default = _G.aimbotAutoEnabled, Save = true, Flag = "AAuto", Callback = function(V) _G.aimbotAutoEnabled = V; if V then _G.silentAimEnabled = false end; zSave() end })
SCombatModos:AddToggle({ Name = "Aimbot Manual (RMB)", Default = _G.aimbotManualEnabled, Save = true, Flag = "AMan", Callback = function(V) _G.aimbotManualEnabled = V; zSave() end })
SCombatModos:AddToggle({ Name = "✨ Silent Aim (Mágico)", Default = _G.silentAimEnabled, Save = true, Flag = "SAim", Callback = function(V) _G.silentAimEnabled = V; if V then _G.aimbotAutoEnabled = false end; zSave() end })

local SCombatRefine = TabCombat:AddSection({ Name = "⚙️ AIM REFINEMENTS" })
SCombatRefine:AddButton({ Name = "👤 Abrir Seletor Avançado do Corpo", Callback = function() if bonecoFrame then bonecoFrame.Visible = not bonecoFrame.Visible end end })
SCombatRefine:AddToggle({ Name = "Wall Check", Default = _G.wallCheckEnabled, Save = true, Flag = "WCheck", Callback = function(V) _G.wallCheckEnabled = V; zSave() end })
SCombatRefine:AddToggle({ Name = "Aim Prediction (Inércia)", Default = _G.aimPredictionEnabled, Save = true, Flag = "APred", Callback = function(V) _G.aimPredictionEnabled = V; zSave() end })
SCombatRefine:AddSlider({ Name = "Smoothness Aimbot", Min = 1, Max = 10, Default = _G.aimbotSmoothness, Color = Color3.fromRGB(0, 255, 100), Increment = 0.5, ValueName = "Lerp", Save = true, Flag = "ASmoth", Callback = function(V) _G.aimbotSmoothness = V; zSave() end })
SCombatRefine:AddSlider({ Name = "Chance Acerto (Silent)", Min = 1, Max = 100, Default = _G.silentAimHitChance, Color = Color3.fromRGB(200, 100, 255), Increment = 1, ValueName = "%", Save = true, Flag = "SHit", Callback = function(V) _G.silentAimHitChance = V; zSave() end })

local SCombatFOV = TabCombat:AddSection({ Name = "⭕ FIELD OF VIEW (FOV)" })
SCombatFOV:AddToggle({ Name = "Mostrar Círculo FOV", Default = _G.FOV_VISIBLE, Save = true, Flag = "FovV", Callback = function(V) _G.FOV_VISIBLE = V; zSave() end })
SCombatFOV:AddSlider({ Name = "Tamanho Máximo FOV", Min = 10, Max = 600, Default = _G.FOV_RADIUS, Color = Color3.fromRGB(255, 0, 0), Increment = 5, ValueName = "Raio", Save = true, Flag = "FovR", Callback = function(V) _G.FOV_RADIUS = V; zSave() end })
SCombatFOV:AddSlider({ Name = "Deadzone Legit (FOV Interno)", Min = 5, Max = 300, Default = _G.legitDeadzone, Color = Color3.fromRGB(0, 200, 255), Increment = 5, ValueName = "Raio", Save = true, Flag = "LegitDz", Callback = function(V) _G.legitDeadzone = V; zSave() end })

local SCombatTrigger = TabCombat:AddSection({ Name = "🔫 TRIGGERBOT" })
SCombatTrigger:AddToggle({ Name = "Ativar TriggerBot", Default = _G.triggerBotEnabled, Save = true, Flag = "TBE", Callback = function(V) _G.triggerBotEnabled = V; zSave() end })
SCombatTrigger:AddSlider({ Name = "Delay (Segundos)", Min = 0, Max = 1, Default = _G.triggerBotDelay, Color = Color3.fromRGB(255, 100, 0), Increment = 0.01, ValueName = "s", Save = true, Flag = "TBDely", Callback = function(V) _G.triggerBotDelay = V; zSave() end })

-- 👁️ TAB VISUALS (ESP)
local SVisRadar = TabVisuals:AddSection({ Name = "📡 RADAR / MINIMAPA" })
SVisRadar:AddToggle({ Name = "Mostrar Minimapa (Hacker Map)", Default = _G.espRadar, Save = true, Flag = "RdrE", Callback = function(V) _G.espRadar = V; if radarBg then radarBg.Visible = V and not _G.streamerMode end; zSave() end })
SVisRadar:AddSlider({ Name = "Tamanho do Radar", Min = 100, Max = 300, Default = _G.RADAR_SIZE, Color = Color3.fromRGB(0, 255, 100), Increment = 10, ValueName = "px", Save = true, Flag = "RdrS", Callback = function(V) _G.RADAR_SIZE = V; if radarBg then radarBg.Size = UDim2.new(0, V, 0, V); radarBg.Position = UDim2.new(1, -(V + 20), 0, 20) end; zSave() end })
SVisRadar:AddSlider({ Name = "Zoom do Radar (Escala)", Min = 1, Max = 10, Default = _G.MAP_SCALE, Color = Color3.fromRGB(200, 100, 255), Increment = 1, ValueName = "x", Save = true, Flag = "RdrZ", Callback = function(V) _G.MAP_SCALE = V; zSave() end })

local SVisEnemy = TabVisuals:AddSection({ Name = "🔴 ENEMIES (INIMIGOS)" })
SVisEnemy:AddToggle({ Name = "Caixa 2D", Default = _G.espEnemyBox, Save = true, Flag = "EBox", Callback = function(V) _G.espEnemyBox = V; zSave() end })
SVisEnemy:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espEnemyChams, Save = true, Flag = "EChms", Callback = function(V) _G.espEnemyChams = V; zSave() end })
SVisEnemy:AddToggle({ Name = "Linha (Tracers)", Default = _G.espEnemyTracers, Save = true, Flag = "ETrc", Callback = function(V) _G.espEnemyTracers = V; zSave() end })
SVisEnemy:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espEnemySkeleton, Save = true, Flag = "ESkl", Callback = function(V) _G.espEnemySkeleton = V; zSave() end })
SVisEnemy:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espEnemyText, Save = true, Flag = "ETxt", Callback = function(V) _G.espEnemyText = V; zSave() end })

local SVisAlly = TabVisuals:AddSection({ Name = "🔵 ALLIES (ALIADOS)" })
SVisAlly:AddToggle({ Name = "Caixa 2D", Default = _G.espAllyBox, Save = true, Flag = "ABox", Callback = function(V) _G.espAllyBox = V; zSave() end })
SVisAlly:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espAllyChams, Save = true, Flag = "AChm", Callback = function(V) _G.espAllyChams = V; zSave() end })
SVisAlly:AddToggle({ Name = "Linha (Tracers)", Default = _G.espAllyTracers, Save = true, Flag = "ATrc", Callback = function(V) _G.espAllyTracers = V; zSave() end })
SVisAlly:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espAllySkeleton, Save = true, Flag = "ASkl", Callback = function(V) _G.espAllySkeleton = V; zSave() end })
SVisAlly:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espAllyText, Save = true, Flag = "ATxt", Callback = function(V) _G.espAllyText = V; zSave() end })

local SVisText = TabVisuals:AddSection({ Name = "📝 TEXT FILTERS" })
SVisText:AddToggle({ Name = "Mostrar Nome do Player", Default = _G.espName, Save = true, Flag = "TxNm", Callback = function(V) _G.espName = V; zSave() end })
SVisText:AddToggle({ Name = "Mostrar Vida (HP)", Default = _G.espHP, Save = true, Flag = "TxHP", Callback = function(V) _G.espHP = V; zSave() end })
SVisText:AddToggle({ Name = "Mostrar Distância", Default = _G.espDistance, Save = true, Flag = "TxDist", Callback = function(V) _G.espDistance = V; zSave() end })
SVisText:AddToggle({ Name = "Mostrar Arma Atual", Default = _G.espWeapon, Save = true, Flag = "TxW", Callback = function(V) _G.espWeapon = V; zSave() end })

local SVisGlobal = TabVisuals:AddSection({ Name = "⚙️ GLOBAL ESP LIMITS" })
SVisGlobal:AddSlider({ Name = "Distância Máxima do ESP", Min = 50, Max = 10000, Default = _G.espMaxDistance, Color = Color3.fromRGB(0, 255, 100), Increment = 50, ValueName = "Studs", Save = true, Flag = "EspDist", Callback = function(V) _G.espMaxDistance = V; zSave() end })

-- 🔫 TAB WEAPON
local SWeaponGun = TabWeapon:AddSection({ Name = "🛠️ GUN MODS" })
SWeaponGun:AddToggle({ Name = "No Recoil (Remove Camera Shake)", Default = _G.noRecoilEnabled, Save = true, Flag = "NRec", Callback = function(V) _G.noRecoilEnabled = V; zSave() end })
SWeaponGun:AddToggle({ Name = "No Spread (Remove Bullet Cone)", Default = _G.noSpreadEnabled, Save = true, Flag = "NSprd", Callback = function(V) _G.noSpreadEnabled = V; zSave() end })
SWeaponGun:AddToggle({ Name = "Infinite Ammo (Munição Infinita)", Default = _G.infiniteAmmoEnabled, Save = true, Flag = "IAmm", Callback = function(V) _G.infiniteAmmoEnabled = V; zSave() end })
SWeaponGun:AddToggle({ Name = "Fast Reload (Recarga Rápida)", Default = _G.instantReloadEnabled, Save = true, Flag = "IRel", Callback = function(V) _G.instantReloadEnabled = V; zSave() end })

local SWeaponHitbox = TabWeapon:AddSection({ Name = "💀 EXTRA HITBOX" })
SWeaponHitbox:AddSlider({ Name = "Aumentar Cabeça Global", Min = 2, Max = 15, Default = _G.hitboxExpander, Color = Color3.fromRGB(150, 0, 255), Increment = 1, ValueName = "T", Save = true, Flag = "HEx", Callback = function(V) _G.hitboxExpander = V; zSave() end })

-- 👟 TAB PLAYER
local SPlayerMove = TabPlayer:AddSection({ Name = "🏃 MOVEMENT" })
SPlayerMove:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = _G.walkSpeed, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "W", Save = true, Flag = "PWS", Callback = function(V) _G.walkSpeed = V; zSave() end })
SPlayerMove:AddSlider({ Name = "JumpPower", Min = 50, Max = 300, Default = _G.jumpPower, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "P", Save = true, Flag = "PJP", Callback = function(V) _G.jumpPower = V; zSave() end })

local SPlayerAntiAim = TabPlayer:AddSection({ Name = "👻 ANTI-AIM (DESYNC)" })
SPlayerAntiAim:AddToggle({ Name = "Legit Desync (Bugar Velocidade)", Default = _G.antiAimLegitEnabled, Save = true, Flag = "AALg", Callback = function(V) _G.antiAimLegitEnabled = V; zSave() end })

-- ⚙️ TAB MISC
local SMiscUtils = TabMisc:AddSection({ Name = "🛠️ UTILITIES & PERFORMANCE" })
SMiscUtils:AddBind({ Name = "👁️ Modo Streamer (Ocultar Desenhos)", Default = Enum.KeyCode.F4, Hold = false, Callback = function() _G.streamerMode = not _G.streamerMode; if radarBg then radarBg.Visible = _G.espRadar and not _G.streamerMode end end })

-- 🛡️ TAB CONFIG
local SConfigGerais = TabConfig:AddSection({ Name = "🛡️ INTERFACE & SCRIPTS" })
if not isMobile then
    SConfigGerais:AddBind({ Name = "⌨️ Tecla para Abrir/Fechar a Interface", Default = Enum.KeyCode.Home, Hold = false, Callback = function() local o = findOrionGui(); if o then o.Enabled = not o.Enabled end end })
else
    SConfigGerais:AddButton({ Name = "🔴 Uma Bolinha HUB foi criada para mobile", Callback = function() end })
end
SConfigGerais:AddButton({ Name = "💾 FORÇAR SALVAMENTO (MANUAL)", Callback = function() zSave(); OrionLib:MakeNotification({Name = "Supreme Hub", Content = "Configurações Globais Salvas!", Image = "rbxassetid://4483345998", Time = 3}) end })
SConfigGerais:AddBind({ Name = "🛑 BOTÃO DE PÂNICO (Apagar Script Completamente)", Default = Enum.KeyCode.End, Hold = false, Callback = function() _G.SupremeHubRunning = false; if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end; _G.clearDrawings(); if bonecoFrame then bonecoFrame:Destroy() end; local mGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"); if mGui:FindFirstChild("SupremeMobileHub") then mGui.SupremeMobileHub:Destroy() end; OrionLib:Destroy() end })

OrionLib:Init()

-- ==================== ABSTRACTIONS & HELPERS (UNIVERSAL FPS) ====================
local function getCharacter(player)
    if not player then return nil end
    if player.Character then return player.Character end
    local pf = workspace:FindFirstChild(player.Name)
    if pf and pf:IsA("Model") then return pf end
    local folders = {"Players", "Characters", "Entities", "Models", "Game", "Baddies"}
    for _, fName in pairs(folders) do
        local f = workspace:FindFirstChild(fName)
        if f then local c = f:FindFirstChild(player.Name) if c and c:IsA("Model") then return c end end
    end
    return nil
end
local function getHumanoid(char) if not char then return nil end return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid") end
local function getRoot(char) if not char then return nil end return char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Hitbox") end
local function getHead(char) if not char then return nil end return char:FindFirstChild("Head") or char:FindFirstChild("HeadHitbox") or char:FindFirstChild("FakeHead") or getRoot(char) end
local function getHealth(char) local h = getHumanoid(char) if h then return h.Health, h.MaxHealth end local hd = char and char:FindFirstChild("Health") if hd and (hd:IsA("NumberValue") or hd:IsA("IntValue")) then return hd.Value, 100 end return 100, 100 end
local function getWeapon(char) if not char then return nil end local tool = char:FindFirstChildOfClass("Tool") if tool then return tool end for _, v in pairs(char:GetChildren()) do if v:IsA("Model") and (v.Name:lower():find("gun") or v.Name:lower():find("weapon")) then return v end end return nil end
local function getTeam(player) if not player then return "None" end if player.Team then return player.Team.Name end if player.TeamColor then return player.TeamColor.Name end local tVal = player:FindFirstChild("Team") or player:FindFirstChild("team") if tVal and (tVal:IsA("StringValue") or tVal:IsA("ObjectValue")) then return tostring(tVal.Value) end return "None" end

-- ==================== CORE FUNCTIONS ====================
local function isAlive(c) if not c then return false end local h = getHumanoid(c) if h then return h.Health > 0 end return getRoot(c) ~= nil end
local function isSameTeam(p1, p2) if not p1 or not p2 then return false end local t1, t2 = getTeam(p1), getTeam(p2) if t1 ~= "None" and t2 ~= "None" then return t1 == t2 end return false end
local function isFFA() local t = {}; local c = 0; for _, p in pairs(Players:GetPlayers()) do local team = getTeam(p) if team ~= "None" then t[team] = true end end; for _ in pairs(t) do c = c + 1 end; return c < 2 end

local function hasLineOfSight(tp) 
    local cam = workspace.CurrentCamera
    if not cam then return false end
    
    local ignores = {cam}
    local localChar = getCharacter(LocalPlayer)
    if localChar then table.insert(ignores, localChar) end
    for _, v in pairs(cam:GetChildren()) do table.insert(ignores, v) end
    
    local r = RaycastParams.new(); r.FilterDescendantsInstances = ignores; r.FilterType = Enum.RaycastFilterType.Blacklist
    local res = workspace:Raycast(cam.CFrame.Position, (tp.Position - cam.CFrame.Position).Unit * 5000, r)
    return not res or res.Instance:IsDescendantOf(tp.Parent) 
end

-- 🧠 PRIORIDADE DE HITBOX (SMART RESOLVER)
local function getPriorityParts(character)
    local primary = {}
    local secondary = {}
    local head = getHead(character)
    local root = getRoot(character)

    local vel = root and (root.AssemblyLinearVelocity or root.Velocity) or Vector3.new(0, 0, 0)
    local isMoving = vel.Magnitude > 5
    local localRoot = getRoot(getCharacter(LocalPlayer))
    local dist = (root and localRoot) and (root.Position - localRoot.Position).Magnitude or 0

    local preferTorso = isMoving or dist > 150

    -- Smart Hitbox Override
    if preferTorso and root then
        table.insert(primary, root)
        if head then table.insert(secondary, head) end
    else
        if head then table.insert(primary, head) end
        if root then table.insert(secondary, root) end
    end

    -- Inject UI configurations
    for partName, state in pairs(_G.HitboxStates) do
        local part = character:FindFirstChild(partName)
        if part then
            if state == 1 and not table.find(primary, part) then
                table.insert(primary, part)
            elseif state == 2 and not table.find(secondary, part) then
                table.insert(secondary, part)
            end
        end
    end

    if #primary == 0 and #secondary > 0 then
        primary = secondary
    elseif #secondary == 0 and #primary > 0 then
        secondary = primary
    end

    return primary, secondary
end

-- 🎯 TARGET SYSTEM (REAL-TIME NO TIMERS)
local function getClosestEnemyAdvanced()
    local cam = workspace.CurrentCamera
    if not cam then return nil, nil end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    local bestPlayerPrimary, bestPartPrimary, shortestPrimary = nil, nil, _G.FOV_RADIUS
    local bestPlayerSecondary, bestPartSecondary, shortestSecondary = nil, nil, _G.FOV_RADIUS
    local bestPlayerLegit, bestPartLegit, shortestLegit = nil, nil, _G.legitDeadzone

    for _, player in pairs(game.Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = getCharacter(player)
        if not char or not isAlive(char) then continue end
        if not isFFA() and isSameTeam(player, LocalPlayer) then continue end

        if _G.aimbotMode == "Legit" then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    local screenPos, visible = cam:WorldToViewportPoint(part.Position)
                    if visible then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortestLegit then
                            if not _G.wallCheckEnabled or hasLineOfSight(part) then
                                shortestLegit = dist
                                bestPlayerLegit = player
                                bestPartLegit = part
                            end
                        end
                    end
                end
            end
        else
            local primaryParts, secondaryParts = getPriorityParts(char)
            
            for _, part in pairs(primaryParts) do
                local screenPos, visible = cam:WorldToViewportPoint(part.Position)
                if visible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestPrimary then
                        if not _G.wallCheckEnabled or hasLineOfSight(part) then
                            shortestPrimary = dist
                            bestPlayerPrimary = player
                            bestPartPrimary = part
                        end
                    end
                end
            end

            for _, part in pairs(secondaryParts) do
                local screenPos, visible = cam:WorldToViewportPoint(part.Position)
                if visible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestSecondary then
                        if not _G.wallCheckEnabled or hasLineOfSight(part) then
                            shortestSecondary = dist
                            bestPlayerSecondary = player
                            bestPartSecondary = part
                        end
                    end
                end
            end
        end
    end

    if _G.aimbotMode == "Legit" then
        return bestPlayerLegit, bestPartLegit
    else
        if bestPartPrimary then return bestPlayerPrimary, bestPartPrimary end
        return bestPlayerSecondary, bestPartSecondary
    end
end

-- ==================== SILENT AIM HOOK (UNIVERSAL FPS) ====================
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    local args = {...}

    if not checkcaller() and _G.silentAimEnabled and math.random(1, 100) <= _G.silentAimHitChance then
        if currentTarget and currentTargetPart then
            if m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" or m == "FindPartOnRay" or m == "Raycast" then
                local cam = workspace.CurrentCamera
                if cam then
                    local origin = cam.CFrame.Position
                    if typeof(args[1]) == "Ray" then 
                        args[1] = Ray.new(origin, (currentTargetPart.Position - origin).Unit * 1000)
                    elseif m == "Raycast" then 
                        args[1] = origin
                        args[2] = (currentTargetPart.Position - origin).Unit * 1500 
                    end
                    return OldNamecall(self, unpack(args))
                end
            elseif m == "FireServer" or m == "InvokeServer" then
                local n = tostring(self):lower()
                if n:find("hit") or n:find("damage") or n:find("fire") or n:find("shoot") or n:find("weapon") or n:find("bullet") or n:find("event") then
                    local modified = false
                    for i, arg in pairs(args) do
                        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            args[i] = currentTargetPart
                            modified = true
                        end
                    end
                    if modified then return OldNamecall(self, unpack(args)) end
                end
            end
        end
    end
    return OldNamecall(self, ...)
end)

-- ==================== RENDER LOOP (NATIVE ESP) ====================
_G.RunServiceConnection = RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local c = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    
    currentTarget, currentTargetPart = getClosestEnemyAdvanced()
    
    if not fovFrame or not fovFrame.Parent then
        fovFrame = Instance.new("Frame", supremeDrawSpace)
        fovFrame.BackgroundTransparency = 1
        local stroke = Instance.new("UIStroke", fovFrame)
        stroke.Color = Color3.fromRGB(255,255,255)
        stroke.Thickness = 1.5
        local corner = Instance.new("UICorner", fovFrame)
        corner.CornerRadius = UDim.new(1,0)
    end

    if fovFrame then
        fovFrame.Size = UDim2.new(0, _G.FOV_RADIUS * 2, 0, _G.FOV_RADIUS * 2)
        fovFrame.Position = UDim2.new(0, c.X - _G.FOV_RADIUS, 0, c.Y - _G.FOV_RADIUS)
        fovFrame.Visible = _G.FOV_VISIBLE
        fovFrame.ZIndex = 999
    end

    local localChar = getCharacter(LocalPlayer)
    if localChar and isAlive(localChar) then
        local hum = getHumanoid(localChar)
        if hum then 
            pcall(function() hum.WalkSpeed = _G.walkSpeed end)
            pcall(function() hum.JumpPower = _G.jumpPower end)
        end
    end

    if _G.antiAimLegitEnabled and localChar then
        local root = getRoot(localChar)
        if root and tick() - lastAntiAimTick > 0.05 then
            local ov = root.AssemblyLinearVelocity or root.Velocity
            pcall(function() root.Velocity = Vector3.new(math.random(-100, 100), math.random(-50, 50), math.random(-100, 100)) end)
            task.spawn(function() RunService.RenderStepped:Wait(); pcall(function() root.Velocity = ov end) end)
            lastAntiAimTick = tick()
        end
    end

    local ffa = isFFA()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = getCharacter(player)
        if char and isAlive(char) then
            local isAlly = not ffa and isSameTeam(player, LocalPlayer)
            local targetRoot = getRoot(char)
            local localRoot = getRoot(localChar)
            
            local playerDist = math.huge
            if targetRoot and localRoot then
                playerDist = (targetRoot.Position - localRoot.Position).Magnitude
            end

            if playerDist > _G.espMaxDistance then
                removeESP(player)
                continue
            end

            if _G.hitboxExpander > 2 and not isAlly then
                local head = getHead(char)
                if head and head:IsA("BasePart") then head.Size = Vector3.new(_G.hitboxExpander, _G.hitboxExpander, _G.hitboxExpander); head.Transparency = 0.5; head.CanCollide = false end
            end

            local bEn = isAlly and _G.espAllyBox or (not isAlly and _G.espEnemyBox)
            local cEn = isAlly and _G.espAllyChams or (not isAlly and _G.espEnemyChams)
            local tEn = isAlly and _G.espAllyTracers or (not isAlly and _G.espEnemyTracers)
            local sEn = isAlly and _G.espAllySkeleton or (not isAlly and _G.espEnemySkeleton)
            local txtEn = isAlly and _G.espAllyText or (not isAlly and _G.espEnemyText)

            -- NATIVE BOX 2D
            if bEn and not _G.streamerMode and targetRoot then
                local sPos, on = cam:WorldToViewportPoint(targetRoot.Position)
                local box = boxes[player] or createBox(); boxes[player] = box
                if on then
                    local hd = getHead(char)
                    local headPos = cam:WorldToViewportPoint((hd and hd.Position or targetRoot.Position) + Vector3.new(0, 1.5, 0))
                    local height = math.abs(headPos.Y - sPos.Y) * 2.2
                    local width = height * 0.55
                    box.Visible = true; box.Size = UDim2.new(0, width, 0, height); box.Position = UDim2.new(0, sPos.X - width / 2, 0, headPos.Y)
                    box.UIStroke.Color = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(231, 76, 60)
                else box.Visible = false end
            else if boxes[player] then boxes[player]:Destroy(); boxes[player] = nil end end

            -- CHAMS
            if cEn and not _G.streamerMode then
                local high = highlights[player]
                if high and high.Parent ~= char then high:Destroy(); highlights[player] = nil; high = nil end
                if not high then high = char:FindFirstChild("ESPHighlight") end
                if not high then
                    high = Instance.new("Highlight")
                    high.Name = "ESPHighlight"
                    high.FillTransparency = 0.5
                    high.OutlineTransparency = 0.1
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.Parent = char
                    highlights[player] = high
                end
                high.Enabled = true
                high.Adornee = char
                high.FillColor = (player == currentTarget and Color3.fromRGB(255, 235, 59)) or (isAlly and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(231, 76, 60)
                high.OutlineColor = (player == currentTarget and Color3.fromRGB(245, 127, 23)) or (isAlly and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(231, 76, 60)
            else if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end end

            -- NATIVE TEXTOS
            if txtEn and not _G.streamerMode and targetRoot then
                local hd = getHead(char)
                local sPos, on = cam:WorldToViewportPoint((hd and hd.Position or targetRoot.Position) + Vector3.new(0, 2, 0))
                local txt = espTexts[player] or createText(); espTexts[player] = txt
                if on then
                    txt.Visible = true; txt.Position = UDim2.new(0, sPos.X, 0, sPos.Y - 15)
                    txt.TextColor3 = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(255, 255, 255)
                    local info = _G.espName and (player.DisplayName .. "\n") or ""
                    local hp, _ = getHealth(char)
                    if _G.espHP then info = info .. "[" .. math.floor(hp) .. " HP] " end
                    if _G.espDistance then info = info .. "[" .. math.floor((cam.CFrame.Position - targetRoot.Position).Magnitude) .. "m]\n" else info = info .. (info ~= "" and "\n" or "") end
                    if _G.espWeapon then local tool = getWeapon(char); info = info .. (tool and "["..tool.Name.."]" or "[Mãos]") end
                    txt.Text = info
                else txt.Visible = false end
            else if espTexts[player] then espTexts[player]:Destroy(); espTexts[player] = nil end end

            -- NATIVE TRACERS
            if tEn and not _G.streamerMode and targetRoot then
                local sPos, on = cam:WorldToViewportPoint(targetRoot.Position)
                local tracer = tracers[player] or createLine(); tracers[player] = tracer
                if on then
                    local p1, p2 = Vector2.new(c.X, cam.ViewportSize.Y), Vector2.new(sPos.X, sPos.Y)
                    local dist = (p2 - p1).Magnitude
                    tracer.Size = UDim2.new(0, dist, 0, 1.5)
                    tracer.Position = UDim2.new(0, (p1.X + p2.X) / 2, 0, (p1.Y + p2.Y) / 2)
                    tracer.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
                    tracer.BackgroundColor3 = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(231, 76, 60)
                    tracer.Visible = true
                else tracer.Visible = false end
            else if tracers[player] then tracers[player]:Destroy(); tracers[player] = nil end end

            -- NATIVE SKELETON
            if sEn and not _G.streamerMode then
                if not skeletons[player] then skeletons[player] = {} end
                local skelParts = skeletons[player]
                for i, con in ipairs(skeletonConnections) do
                    local pa, pb = char:FindFirstChild(con[1]), char:FindFirstChild(con[2])
                    if pa and pb then
                        local posA, oA = cam:WorldToViewportPoint(pa.Position); local posB, oB = cam:WorldToViewportPoint(pb.Position)
                        if oA or oB then
                            local line = skelParts[i] or createLine(); skelParts[i] = line
                            local pA, pB = Vector2.new(posA.X, posA.Y), Vector2.new(posB.X, posB.Y)
                            local dist = (pB - pA).Magnitude
                            line.Size = UDim2.new(0, dist, 0, 1.2)
                            line.Position = UDim2.new(0, (pA.X + pB.X) / 2, 0, (pA.Y + pB.Y) / 2)
                            line.Rotation = math.deg(math.atan2(pB.Y - pA.Y, pB.X - pA.X))
                            line.BackgroundColor3 = isAlly and Color3.fromRGB(150,200,255) or Color3.fromRGB(255,255,255)
                            line.Visible = true
                        else if skelParts[i] then skelParts[i].Visible = false end end
                    else if skelParts[i] then skelParts[i].Visible = false end end
                end
            else if skeletons[player] then for _, line in pairs(skeletons[player]) do line:Destroy() end; skeletons[player] = nil end end

            -- RADAR MINIMAPA (Universal / Qualquer Jogo)
            if _G.espRadar and not _G.streamerMode and targetRoot and localRoot then
                local blip = radarBlips[player] or createRadarBlip(player)
                if isAlly then blip.BackgroundColor3 = Color3.fromRGB(46, 204, 113) else blip.BackgroundColor3 = Color3.fromRGB(231, 76, 60) end
                
                local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
                local flatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                local offset = targetRoot.Position - localRoot.Position
                
                local rX = offset:Dot(flatRight)
                local rY = -offset:Dot(flatLook)
                local distance = math.sqrt(rX*rX + rY*rY)

                if distance <= (_G.RADAR_SIZE / 2) * _G.MAP_SCALE then
                    blip.Visible = true
                    blip.Position = UDim2.new(0.5, (rX / _G.MAP_SCALE) - 3, 0.5, (rY / _G.MAP_SCALE) - 3)
                else
                    blip.Visible = false
                end
            else
                if radarBlips[player] then radarBlips[player].Visible = false end
            end
        else
            removeESP(player)
        end
    end

    -- AIMBOT
    if (_G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming)) and not _G.silentAimEnabled then
        if currentTarget and currentTargetPart then
            if currentTarget ~= lastLegitTarget then
                legitReactionTimer = tick() + (_G.aimbotMode == "Legit" and (math.random(5, 15) / 100) or 0)
                lastLegitTarget = currentTarget
            end

            if tick() >= legitReactionTimer then
                local aimPosition = currentTargetPart.Position

                if _G.aimPredictionEnabled then
                    local targetVelocity = currentTargetPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                    local predScale = 1
                    if _G.aimbotMode == "Legit" then
                        local dist = (aimPosition - cam.CFrame.Position).Magnitude
                        predScale = math.clamp(dist / 100, 0.3, 1.5)
                    end
                    aimPosition = aimPosition + (targetVelocity * (_G.aimPredictionForce * predScale))
                end

                if _G.aimbotMode == "Legit" then
                    local rx = (math.random() - 0.5) * 0.4
                    local ry = (math.random() - 0.5) * 0.4
                    local rz = (math.random() - 0.5) * 0.4
                    aimPosition = aimPosition + Vector3.new(rx, ry, rz)
                end

                local targetCFrame = CFrame.new(cam.CFrame.Position, aimPosition)

                if _G.aimbotMode == "Legit" then
                    local isFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                    local baseSmoothness = _G.aimbotSmoothness * 2.5
                    local currentSmoothness = isFiring and (baseSmoothness * 0.8) or (baseSmoothness * 3.0)
                    cam.CFrame = cam.CFrame:Lerp(targetCFrame, math.clamp(1 / currentSmoothness, 0.001, 1))
                else
                    if _G.aimbotSmoothness <= 1 then 
                        cam.CFrame = targetCFrame
                    else 
                        cam.CFrame = cam.CFrame:Lerp(targetCFrame, math.clamp(1 / _G.aimbotSmoothness, 0.01, 1)) 
                    end
                end
            end
        else
            lastLegitTarget = nil
        end
    end

    -- 🔫 TRIGGERBOT
    if _G.triggerBotEnabled and not triggerBotCooldown then
        if currentTarget and currentTargetPart then
            local direction = (currentTargetPart.Position - cam.CFrame.Position).Unit * 1000
            local raycastParams = RaycastParams.new()
            
            local ignores = {cam}
            if localChar then table.insert(ignores, localChar) end
            for _, v in pairs(cam:GetChildren()) do table.insert(ignores, v) end
            
            raycastParams.FilterDescendantsInstances = ignores
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local result = workspace:Raycast(cam.CFrame.Position, direction, raycastParams)

            if result and result.Instance and result.Instance:IsDescendantOf(currentTarget.Character) then
                triggerBotCooldown = true

                task.spawn(function()
                    mouse1press()
                    task.wait(0.02)
                    mouse1release()

                    task.wait(_G.triggerBotDelay)
                    triggerBotCooldown = false
                end)
            end
        end
    end

    -- ==================== WEAPON MODS ABSTRACTION ====================
    if localChar then
        local tool = getWeapon(localChar)

        if tool then
            for _, v in pairs(tool:GetDescendants()) do
                local name = string.lower(v.Name)

                if _G.infiniteAmmoEnabled and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                    if name:find("ammo") or name:find("clip") or name:find("mag") then v.Value = 999 end
                end

                if _G.instantReloadEnabled then
                    if v:IsA("NumberValue") and (name:find("reload") or name:find("cooldown") or name:find("delay")) then v.Value = 0 end
                    if v:IsA("BoolValue") and name:find("reloading") then v.Value = false end
                end

                if _G.noSpreadEnabled and v:IsA("NumberValue") and (name:find("spread") or name:find("cone")) then
                    v.Value = 0
                end
            end
        end
    end

    -- 🎯 NO RECOIL
    if _G.noRecoilEnabled then
        local camCF = cam.CFrame
        local _, y, _ = camCF:ToOrientation()
        cam.CFrame = CFrame.new(camCF.Position) * CFrame.Angles(0, y, 0)
    end
end)

-- ==================== INPUT ====================
UserInputService.InputBegan:Connect(function(input, isProcessed) 
    if isProcessed then return end
    if input.UserInputType == aimbotKey or input.UserInputType == Enum.UserInputType.Touch then aiming = true end
end)

UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == aimbotKey or input.UserInputType == Enum.UserInputType.Touch then aiming = false end
end)

-- ==================== CLEANUP ====================
Players.PlayerRemoving:Connect(function(player) 
    removeESP(player) 
    if currentTarget == player then currentTarget, currentTargetPart = nil, nil end 
end)
