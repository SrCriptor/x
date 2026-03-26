-- 🗑️ LIMPEZA DE SCRIPTS ANTERIORES E OTIMIZAÇÃO
if _G.SupremeHubRunning then
    warn("Limpando versão anterior do Supreme Hub...")
    if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end
end
_G.SupremeHubRunning = true

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Highlight") then pcall(function() obj:Destroy() end) end
end
if _G.clearDrawings then _G.clearDrawings() end

-- ==================== SERVIÇOS E VARIÁVEIS ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local currentTarget, aiming = nil, false
local aimbotKey = Enum.UserInputType.MouseButton2 
local triggerBotCooldown, lastAntiAimTick = false, tick()
local nextAimSwitchTime, currentFocusLevel = tick() + 2.0, 1 

-- CONFIGURAÇÕES GLOBAIS
_G.streamerMode = false
_G.FOV_RADIUS = 150
_G.FOV_VISIBLE = true

-- Aimbot
_G.aimbotAutoEnabled, _G.aimbotManualEnabled = false, false
_G.silentAimEnabled, _G.silentAimHitChance = false, 100
_G.aimbotSmoothness = 1
_G.wallCheckEnabled = false
_G.aimPredictionEnabled, _G.aimPredictionForce = false, 0.135
_G.triggerBotEnabled, _G.triggerBotDelay = false, 0.05

-- ESP Séries
_G.espEnemyBox, _G.espEnemyChams, _G.espEnemyTracers, _G.espEnemySkeleton, _G.espEnemyText = true, true, false, false, true
_G.espAllyBox, _G.espAllyChams, _G.espAllyTracers, _G.espAllySkeleton, _G.espAllyText = false, false, false, false, false
_G.espName, _G.espHP, _G.espDistance, _G.espWeapon = true, true, true, true

-- Mods
_G.antiAimLegitEnabled, _G.noRecoilEnabled, _G.infiniteAmmoEnabled, _G.instantReloadEnabled = false, false, false, false
_G.hitboxExpander, _G.walkSpeed, _G.jumpPower = 2, 16, 50

-- ==================== NATIVE DRAWING SYSTEM (100% EXECUTOR PROOF) ====================
local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if coreGui:FindFirstChild("SupremeDrawSpace") then coreGui.SupremeDrawSpace:Destroy() end

local supremeDrawSpace = Instance.new("ScreenGui", coreGui)
if not supremeDrawSpace or not supremeDrawSpace.Parent then
    supremeDrawSpace = Instance.new("ScreenGui", game.CoreGui)
end

supremeDrawSpace.Name = "SupremeDrawSpace"
supremeDrawSpace.IgnoreGuiInset = true 
supremeDrawSpace.ResetOnSpawn = false -- IMUNIDADE A MORTE DO JOGADOR (ISSO CAUSAVA O BUG DE DESAPARECER)

local fovFrame = Instance.new("Frame", supremeDrawSpace)
fovFrame.BackgroundTransparency = 1
local fovStroke = Instance.new("UIStroke", fovFrame); fovStroke.Color = Color3.fromRGB(255, 255, 255); fovStroke.Thickness = 1.5; fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local fovCorner = Instance.new("UICorner", fovFrame); fovCorner.CornerRadius = UDim.new(1, 0)

local tracers, espTexts, highlights, skeletons, boxes = {}, {}, {}, {}, {}

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
end

_G.clearDrawings = function()
    for _, v in pairs(supremeDrawSpace:GetChildren()) do
        v:Destroy()
    end

    for player, _ in pairs(tracers) do removeESP(player) end
    for player, _ in pairs(espTexts) do removeESP(player) end
    for player, _ in pairs(boxes) do removeESP(player) end
    for player, _ in pairs(skeletons) do removeESP(player) end
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
    local targetCore = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if targetCore:FindFirstChild("BonequinhoHitboxUI") then targetCore.BonequinhoHitboxUI:Destroy() end

    local gui = Instance.new("ScreenGui", targetCore); gui.Name = "BonequinhoHitboxUI"; gui.ResetOnSpawn = false
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
    local targetCore = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    for _, child in pairs(targetCore:GetDescendants()) do
        if child:IsA("TextLabel") and (string.find(child.Text, "Supreme Hub") or string.find(child.Text, "Premium Script")) then
            local p = child:FindFirstAncestorOfClass("ScreenGui")
            if p then return p end
        end
    end
    return nil
end

-- ==================== MOBILE HUB BUTTON ====================
local function createMobileButton()
    local targetCore = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if targetCore:FindFirstChild("SupremeMobileHub") then targetCore.SupremeMobileHub:Destroy() end
    local mobileGui = Instance.new("ScreenGui", targetCore); mobileGui.Name = "SupremeMobileHub"; mobileGui.ResetOnSpawn = false
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

-- Auto Saver para garantir que o SaveConfig do OrionLib funcione real-time
local function zSave() pcall(function() OrionLib:SaveConfig() end) end

local TabAimbot = Window:MakeTab({ Name = "Aimbot & Magic", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabESP = Window:MakeTab({ Name = "Visuals (ESP)", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local TabMods = Window:MakeTab({ Name = "Gun & Anti-Aim", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabConfig = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- 🎯 AIMBOT
local SAimModos = TabAimbot:AddSection({ Name = "🎯 MODOS DE TIRO" })
SAimModos:AddToggle({ Name = "Aimbot Automático", Default = _G.aimbotAutoEnabled, Save = true, Flag = "AAuto", Callback = function(V) _G.aimbotAutoEnabled = V; if V then _G.silentAimEnabled = false end; zSave() end })
SAimModos:AddToggle({ Name = "Aimbot Manual (RMB)", Default = _G.aimbotManualEnabled, Save = true, Flag = "AMan", Callback = function(V) _G.aimbotManualEnabled = V; zSave() end })
SAimModos:AddToggle({ Name = "✨ Silent Aim (Mágico)", Default = _G.silentAimEnabled, Save = true, Flag = "SAim", Callback = function(V) _G.silentAimEnabled = V; if V then _G.aimbotAutoEnabled = false end; zSave() end })

local SAimConfigs = TabAimbot:AddSection({ Name = "⚙️ REFINAR MIRA E HITBOX" })
SAimConfigs:AddButton({ Name = "👤 Abrir Seletor Avançado do Corpo (Boneco)", Callback = function() if bonecoFrame then bonecoFrame.Visible = not bonecoFrame.Visible end end })
SAimConfigs:AddToggle({ Name = "Wall Check", Default = _G.wallCheckEnabled, Save = true, Flag = "WCheck", Callback = function(V) _G.wallCheckEnabled = V; zSave() end })
SAimConfigs:AddToggle({ Name = "Aim Prediction (Inércia)", Default = _G.aimPredictionEnabled, Save = true, Flag = "APred", Callback = function(V) _G.aimPredictionEnabled = V; zSave() end })
SAimConfigs:AddSlider({ Name = "Smoothness Aimbot", Min = 1, Max = 10, Default = _G.aimbotSmoothness, Color = Color3.fromRGB(0, 255, 100), Increment = 0.5, ValueName = "Lerp", Save = true, Flag = "ASmoth", Callback = function(V) _G.aimbotSmoothness = V; zSave() end })
SAimConfigs:AddSlider({ Name = "Chance Acerto (Silent)", Min = 1, Max = 100, Default = _G.silentAimHitChance, Color = Color3.fromRGB(200, 100, 255), Increment = 1, ValueName = "%", Save = true, Flag = "SHit", Callback = function(V) _G.silentAimHitChance = V; zSave() end })

local SAimFOV, STrigger = TabAimbot:AddSection({ Name = "⭕ CAMPO VISUAL (FOV)" }), TabAimbot:AddSection({ Name = "🔫 TRIGGERBOT" })
SAimFOV:AddToggle({ Name = "Mostrar Círculo FOV", Default = _G.FOV_VISIBLE, Save = true, Flag = "FovV", Callback = function(V) _G.FOV_VISIBLE = V; zSave() end })
SAimFOV:AddSlider({ Name = "Tamanho Máximo FOV", Min = 10, Max = 600, Default = _G.FOV_RADIUS, Color = Color3.fromRGB(255, 0, 0), Increment = 5, ValueName = "Raio", Save = true, Flag = "FovR", Callback = function(V) _G.FOV_RADIUS = V; zSave() end })
STrigger:AddToggle({ Name = "Ativar TriggerBot", Default = _G.triggerBotEnabled, Save = true, Flag = "TBE", Callback = function(V) _G.triggerBotEnabled = V; zSave() end })
STrigger:AddSlider({ Name = "Delay (Segundos)", Min = 0, Max = 1, Default = _G.triggerBotDelay, Color = Color3.fromRGB(255, 100, 0), Increment = 0.01, ValueName = "s", Save = true, Flag = "TBDely", Callback = function(V) _G.triggerBotDelay = V; zSave() end })

-- 👁️ VISUALS / ESP
local SEspInimigo = TabESP:AddSection({ Name = "🔴 INIMIGOS (ESPs SEPARADOS)" })
SEspInimigo:AddToggle({ Name = "Caixa 2D (Box Invisível à AntiCheat)", Default = _G.espEnemyBox, Save = true, Flag = "EBox", Callback = function(V) _G.espEnemyBox = V; zSave() end })
SEspInimigo:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espEnemyChams, Save = true, Flag = "EChms", Callback = function(V) _G.espEnemyChams = V; zSave() end })
SEspInimigo:AddToggle({ Name = "Linha (Tracers)", Default = _G.espEnemyTracers, Save = true, Flag = "ETrc", Callback = function(V) _G.espEnemyTracers = V; zSave() end })
SEspInimigo:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espEnemySkeleton, Save = true, Flag = "ESkl", Callback = function(V) _G.espEnemySkeleton = V; zSave() end })
SEspInimigo:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espEnemyText, Save = true, Flag = "ETxt", Callback = function(V) _G.espEnemyText = V; zSave() end })

local SEspAliado = TabESP:AddSection({ Name = "🔵 ALIADOS (ESPs SEPARADOS)" })
SEspAliado:AddToggle({ Name = "Caixa 2D (Box)", Default = _G.espAllyBox, Save = true, Flag = "ABox", Callback = function(V) _G.espAllyBox = V; zSave() end })
SEspAliado:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espAllyChams, Save = true, Flag = "AChm", Callback = function(V) _G.espAllyChams = V; zSave() end })
SEspAliado:AddToggle({ Name = "Linha (Tracers)", Default = _G.espAllyTracers, Save = true, Flag = "ATrc", Callback = function(V) _G.espAllyTracers = V; zSave() end })
SEspAliado:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espAllySkeleton, Save = true, Flag = "ASkl", Callback = function(V) _G.espAllySkeleton = V; zSave() end })
SEspAliado:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espAllyText, Save = true, Flag = "ATxt", Callback = function(V) _G.espAllyText = V; zSave() end })

local SEspTextConfigs = TabESP:AddSection({ Name = "⚙️ FILTROS DOS LETREIROS" })
SEspTextConfigs:AddToggle({ Name = "Mostrar Nome do Player", Default = _G.espName, Save = true, Flag = "TxNm", Callback = function(V) _G.espName = V; zSave() end })
SEspTextConfigs:AddToggle({ Name = "Mostrar Vida (HP)", Default = _G.espHP, Save = true, Flag = "TxHP", Callback = function(V) _G.espHP = V; zSave() end })
SEspTextConfigs:AddToggle({ Name = "Mostrar Distância", Default = _G.espDistance, Save = true, Flag = "TxDist", Callback = function(V) _G.espDistance = V; zSave() end })
SEspTextConfigs:AddToggle({ Name = "Mostrar Arma Atual", Default = _G.espWeapon, Save = true, Flag = "TxW", Callback = function(V) _G.espWeapon = V; zSave() end })

-- 🔫 MODS
local SModsLegit, SModsArma, SModsPlayer = TabMods:AddSection({ Name = "👻 ANTI-AIM (DESYNC)" }), TabMods:AddSection({ Name = "🔫 ARMAS E HITBOX" }), TabMods:AddSection({ Name = "👟 PLAYER MODS" })
SModsLegit:AddToggle({ Name = "Legit Desync (Bugar Velocidade)", Default = _G.antiAimLegitEnabled, Save = true, Flag = "AALg", Callback = function(V) _G.antiAimLegitEnabled = V; zSave() end })
SModsArma:AddToggle({ Name = "No Recoil", Default = _G.noRecoilEnabled, Save = true, Flag = "NRec", Callback = function(V) _G.noRecoilEnabled = V; zSave() end })
SModsArma:AddToggle({ Name = "Infinite Ammo / Fast Reload", Default = _G.infiniteAmmoEnabled, Save = true, Flag = "IAmmo", Callback = function(V) _G.infiniteAmmoEnabled = V; _G.instantReloadEnabled = V; zSave() end })
SModsArma:AddSlider({ Name = "Aumentar Cabeça Global", Min = 2, Max = 15, Default = _G.hitboxExpander, Color = Color3.fromRGB(150, 0, 255), Increment = 1, ValueName = "T", Save = true, Flag = "HEx", Callback = function(V) _G.hitboxExpander = V; zSave() end })
SModsPlayer:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = _G.walkSpeed, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "W", Save = true, Flag = "PWS", Callback = function(V) _G.walkSpeed = V; zSave() end })
SModsPlayer:AddSlider({ Name = "JumpPower", Min = 50, Max = 300, Default = _G.jumpPower, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "P", Save = true, Flag = "PJP", Callback = function(V) _G.jumpPower = V; zSave() end })

-- ⚙️ CONFIG
local SConfigGerais = TabConfig:AddSection({ Name = "🛡️ Ocultação e Desligamento" })
SConfigGerais:AddBind({ Name = "👁️ Modo Streamer (Ocultar Desenhos)", Default = Enum.KeyCode.F4, Hold = false, Callback = function() _G.streamerMode = not _G.streamerMode end })

if not isMobile then
    SConfigGerais:AddBind({ 
        Name = "⌨️ Tecla para Abrir/Fechar a Interface", 
        Default = Enum.KeyCode.RightControl, 
        Hold = false, 
        Callback = function() 
            local o = findOrionGui()
            if o then o.Enabled = not o.Enabled end 
        end 
    })
else
    SConfigGerais:AddButton({ Name = "🔴 Uma Bolinha HUB foi criada para mobile", Callback = function() end })
end

SConfigGerais:AddButton({ Name = "💾 FORÇAR SALVAMENTO (MANUAL)", Callback = function() zSave(); OrionLib:MakeNotification({Name = "Supreme Hub", Content = "Configurações Globais Salvas!", Image = "rbxassetid://4483345998", Time = 3}) end })
SConfigGerais:AddButton({ Name = "🛑 BOTÃO DE PÂNICO (Apagar Script Completamente)", Callback = function() _G.SupremeHubRunning = false; if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end; _G.clearDrawings(); if bonecoFrame then bonecoFrame:Destroy() end; local mGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"); if mGui:FindFirstChild("SupremeMobileHub") then mGui.SupremeMobileHub:Destroy() end; OrionLib:Destroy() end })

OrionLib:Init()

-- ==================== CORE FUNCTIONS ====================
local function isAlive(c) local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0 end
local function isSameTeam(p1, p2) if not p1 or not p2 then return false end; if p1.Team and p2.Team then return p1.Team == p2.Team end; if p1.TeamColor and p2.TeamColor then return p1.TeamColor == p2.TeamColor end; return false end
local function isFFA() local t = {}; local c = 0; for _, p in pairs(Players:GetPlayers()) do if p.Team or p.TeamColor then t[p.Team and p.Team.Name or p.TeamColor.Name] = true end end; for _ in pairs(t) do c = c + 1 end; return c < 2 end

local function hasLineOfSight(tp) 
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local r = RaycastParams.new(); r.FilterDescendantsInstances = {LocalPlayer.Character}; r.FilterType = Enum.RaycastFilterType.Blacklist
    return not workspace:Raycast(cam.CFrame.Position, (tp.Position - cam.CFrame.Position).Unit * 5000, r) or workspace:Raycast(cam.CFrame.Position, (tp.Position - cam.CFrame.Position).Unit * 5000, r).Instance:IsDescendantOf(tp.Parent) 
end

local function getClosestEnemyAndPart()
    local cam = workspace.CurrentCamera
    if not cam then return nil, nil end
    local c = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local clTarget, fAimPart, sDist = nil, nil, _G.FOV_RADIUS
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character or not isAlive(player.Character) then continue end
        if not ffa and isSameTeam(player, LocalPlayer) then continue end 

        local chosenPartList = {}
        for k, state in pairs(_G.HitboxStates) do
            if (state == 1 or (state == 2 and currentFocusLevel == 2)) then
                local t = player.Character:FindFirstChild(k); if not t and k == "Torso" then t = player.Character:FindFirstChild("HumanoidRootPart") end
                if t then table.insert(chosenPartList, t) end
            end
        end

        if #chosenPartList == 0 then table.insert(chosenPartList, player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")) end

        for _, aimPart in ipairs(chosenPartList) do
            if aimPart then
                local sPos, v = cam:WorldToViewportPoint(aimPart.Position)
                local dist = (Vector2.new(sPos.X, sPos.Y) - c).Magnitude
                if v and dist <= 12000 and dist <= sDist then
                    if _G.wallCheckEnabled and not hasLineOfSight(aimPart) then continue end
                    sDist, clTarget, fAimPart = dist, player, aimPart
                end
            end
        end
    end
    return clTarget, fAimPart
end

-- ==================== SILENT AIM HOOK ====================
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    local args = {...}

    if not checkcaller() and _G.silentAimEnabled and math.random(1, 100) <= _G.silentAimHitChance then
        if m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" or m == "FindPartOnRay" or m == "Raycast" then
            local t, ap = getClosestEnemyAndPart()
            local cam = workspace.CurrentCamera
            if t and ap and cam then
                local origin = cam.CFrame.Position
                if typeof(args[1]) == "Ray" then args[1] = Ray.new(origin, (ap.Position - origin).Unit * 1000)
                elseif m == "Raycast" then args[1] = origin; args[2] = (ap.Position - origin).Unit * 1500 end
                return OldNamecall(self, unpack(args))
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
    
    if tick() >= nextAimSwitchTime then currentFocusLevel = (currentFocusLevel == 1) and 2 or 1; nextAimSwitchTime = tick() + ((currentFocusLevel == 1) and 1.8 or 0.35) end
    
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
    fovFrame.Visible = not _G.streamerMode and _G.FOV_VISIBLE 
end

    if LocalPlayer.Character and isAlive(LocalPlayer.Character) then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = _G.walkSpeed; hum.JumpPower = _G.jumpPower end
    end

    if _G.antiAimLegitEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        if tick() - lastAntiAimTick > 0.05 then
            local ov = root.Velocity; root.Velocity = Vector3.new(math.random(-100, 100), math.random(-50, 50), math.random(-100, 100))
            task.spawn(function() RunService.RenderStepped:Wait(); root.Velocity = ov end); lastAntiAimTick = tick()
        end
    end

    local ffa = isFFA()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if char and isAlive(char) then
            local isAlly = not ffa and isSameTeam(player, LocalPlayer)
            
            if _G.hitboxExpander > 2 and not isAlly then
                local head = char:FindFirstChild("Head")
                if head and head:IsA("BasePart") then head.Size = Vector3.new(_G.hitboxExpander, _G.hitboxExpander, _G.hitboxExpander); head.Transparency = 0.5; head.CanCollide = false end
            end

            local bEn = isAlly and _G.espAllyBox or (not isAlly and _G.espEnemyBox)
            local cEn = isAlly and _G.espAllyChams or (not isAlly and _G.espEnemyChams)
            local tEn = isAlly and _G.espAllyTracers or (not isAlly and _G.espEnemyTracers)
            local sEn = isAlly and _G.espAllySkeleton or (not isAlly and _G.espEnemySkeleton)
            local txtEn = isAlly and _G.espAllyText or (not isAlly and _G.espEnemyText)

            -- NATIVE BOX 2D
            if bEn and not _G.streamerMode and char:FindFirstChild("HumanoidRootPart") then
            local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                local sPos, on = cam:WorldToViewportPoint(rootPart.Position)
                local box = boxes[player] or createBox()
                boxes[player] = box
                if on then
                    local headPos = cam:WorldToViewportPoint((char:FindFirstChild("Head") and char.Head.Position or rootPart.Position) + Vector3.new(0, 1.5, 0))
                    local height = math.abs(headPos.Y - sPos.Y) * 2.2
                    local width = height * 0.55
                    box.Visible = true; box.Size = UDim2.new(0, width, 0, height); box.Position = UDim2.new(0, sPos.X - width / 2, 0, headPos.Y)
                    box.UIStroke.Color = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(0, 150, 255)) or Color3.fromRGB(255, 0, 0)
                else box.Visible = false end
            else if boxes[player] then boxes[player]:Destroy(); boxes[player] = nil end end

            -- CHAMS (Aura do Roblox)
            if cEn and not _G.streamerMode then
                local high = highlights[player] or Instance.new("Highlight")
                high.Parent = char; highlights[player] = high; high.Adornee = char; high.Enabled = true; high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                high.FillColor = (player == currentTarget and Color3.fromRGB(255, 235, 59)) or (isAlly and Color3.fromRGB(33, 150, 243)) or Color3.fromRGB(244, 67, 54)
                high.OutlineColor = (player == currentTarget and Color3.fromRGB(245, 127, 23)) or (isAlly and Color3.fromRGB(13, 71, 161)) or Color3.fromRGB(183, 28, 28)
            else if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end end

            -- NATIVE TEXTOS
            if txtEn and not _G.streamerMode and char:FindFirstChild("HumanoidRootPart") then
                local sPos, on = cam:WorldToViewportPoint((char:FindFirstChild("Head") and char.Head.Position or char.HumanoidRootPart.Position) + Vector3.new(0, 2, 0))
                local txt = espTexts[player] or createText(); espTexts[player] = txt
                if on then
                    txt.Visible = true; txt.Position = UDim2.new(0, sPos.X, 0, sPos.Y - 15)
                    txt.TextColor3 = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(0, 150, 255)) or Color3.fromRGB(255, 255, 255)
                    local info = _G.espName and (player.DisplayName .. "\n") or ""
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if _G.espHP and hum then info = info .. "[" .. math.floor(hum.Health) .. " HP] " end
                    if _G.espDistance then info = info .. "[" .. math.floor((cam.CFrame.Position - char.HumanoidRootPart.Position).Magnitude) .. "m]\n" else info = info .. (info ~= "" and "\n" or "") end
                    if _G.espWeapon then local tool = char:FindFirstChildOfClass("Tool"); info = info .. (tool and "["..tool.Name.."]" or "[Mãos]") end
                    txt.Text = info
                else txt.Visible = false end
            else if espTexts[player] then espTexts[player]:Destroy(); espTexts[player] = nil end end

            -- NATIVE TRACERS
            if tEn and not _G.streamerMode and char:FindFirstChild("HumanoidRootPart") then
                local sPos, on = cam:WorldToViewportPoint(char.HumanoidRootPart.Position)
                local tracer = tracers[player] or createLine(); tracers[player] = tracer
                if on then
                    local p1, p2 = Vector2.new(c.X, cam.ViewportSize.Y), Vector2.new(sPos.X, sPos.Y)
                    local dist = (p2 - p1).Magnitude
                    tracer.Size = UDim2.new(0, dist, 0, 1.5)
                    tracer.Position = UDim2.new(0, (p1.X + p2.X) / 2, 0, (p1.Y + p2.Y) / 2)
                    tracer.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
                    tracer.BackgroundColor3 = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(0, 150, 255)) or Color3.fromRGB(255, 0, 0)
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

        else
            removeESP(player)
            if player == currentTarget then currentTarget = nil end
        end
    end

    if (_G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming)) and not _G.silentAimEnabled then
        local target, aimPart = getClosestEnemyAndPart()
        if target and aimPart then
            currentTarget = target
            local aimPosition = aimPart.Position
            if _G.aimPredictionEnabled then
                local targetVelocity = aimPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                aimPosition = aimPosition + (targetVelocity * _G.aimPredictionForce)
            end
            local targetCFrame = CFrame.new(cam.CFrame.Position, aimPosition)
            if _G.aimbotSmoothness == 1 then cam.CFrame = targetCFrame
            else cam.CFrame = cam.CFrame:Lerp(targetCFrame, math.clamp(1 / _G.aimbotSmoothness, 0.01, 1)) end
        else currentTarget = nil end
    else
        if _G.silentAimEnabled then currentTarget, _ = getClosestEnemyAndPart() else currentTarget = nil end
    end
end)

UserInputService.InputBegan:Connect(function(input, isProcessed) 
    if isProcessed then return end; if input.UserInputType == aimbotKey or input.UserInputType == Enum.UserInputType.Touch then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input, isProcessed) 
    if input.UserInputType == aimbotKey or input.UserInputType == Enum.UserInputType.Touch then aiming = false end
end)

Players.PlayerRemoving:Connect(function(player) removeESP(player); if currentTarget == player then currentTarget = nil end end)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if _G.noRecoilEnabled then tool:SetAttribute("recoilMax", Vector2.new(0,0)) end
            if _G.infiniteAmmoEnabled then tool:SetAttribute("_ammo", 999) end
            if _G.instantReloadEnabled then tool:SetAttribute("ReloadTime", 0) end
        end
    end
end)
