-- 🗑️ LIMPEZA DE SCRIPTS ANTERIORES E OTIMIZAÇÃO
if _G.SupremeHubRunning then
    warn("Limpando versão anterior do Supreme Hub...")
    if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end
end
_G.SupremeHubRunning = true

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Highlight") then obj:Destroy() end
end
if _G.clearDrawings then _G.clearDrawings() end

-- ==================== SERVIÇOS E VARIÁVEIS ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Identifica Plataforma (Mobile vs PC)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local currentTarget = nil
local aiming = false
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

-- ESP
_G.espEnemyChams, _G.espEnemyTracers, _G.espEnemySkeleton, _G.espEnemyText = true, false, false, false
_G.espAllyChams, _G.espAllyTracers, _G.espAllySkeleton, _G.espAllyText = false, false, false, false

-- Filtros de Texto
_G.espName, _G.espHP, _G.espDistance, _G.espWeapon = true, true, true, true

-- Mods
_G.antiAimLegitEnabled = false
_G.noRecoilEnabled, _G.infiniteAmmoEnabled, _G.instantReloadEnabled = false, false, false
_G.hitboxExpander, _G.walkSpeed, _G.jumpPower = 2, 16, 50

-- ==================== DRAWINGS SYSTEM ====================
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency, fovCircle.Thickness, fovCircle.Filled = 0.8, 1.5, false
fovCircle.Color = Color3.fromRGB(255, 255, 255)

local tracers, espTexts, highlights, skeletons = {}, {}, {}, {}
local function createDrawing(typeStr) return Drawing.new(typeStr) end

local skeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function removeESP(player)
    if tracers[player] then tracers[player]:Remove(); tracers[player] = nil end
    if espTexts[player] then espTexts[player]:Remove(); espTexts[player] = nil end
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
    if skeletons[player] then for _, line in pairs(skeletons[player]) do line:Remove() end; skeletons[player] = nil end
end

_G.clearDrawings = function()
    if fovCircle then fovCircle:Remove() end
    for player, _ in pairs(tracers) do removeESP(player) end
    for player, _ in pairs(espTexts) do removeESP(player) end
    for player, _ in pairs(skeletons) do removeESP(player) end
end

-- ==================== HITBOX SYSTEM (PERSISTENTE) ====================
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

    local gui = Instance.new("ScreenGui", targetCore); gui.Name = "BonequinhoHitboxUI"
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

-- ==================== MOBILE HUB BUTTON (Bolinha Arrastável) ====================
local function findOrionGui()
    local targetCore = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    for _, child in pairs(targetCore:GetChildren()) do
        if child.Name == "Orion" and child:IsA("ScreenGui") then return child end
    end
    return nil
end

local function createMobileButton()
    local targetCore = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if targetCore:FindFirstChild("SupremeMobileHub") then targetCore.SupremeMobileHub:Destroy() end

    local mobileGui = Instance.new("ScreenGui", targetCore); mobileGui.Name = "SupremeMobileHub"
    local btn = Instance.new("TextButton", mobileGui)
    btn.Size, btn.Position = UDim2.new(0, 55, 0, 55), UDim2.new(1, -70, 0, 100)
    btn.BackgroundColor3, btn.BorderSizePixel = Color3.fromRGB(20, 20, 20), 0
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize = "HUB", Color3.fromRGB(255, 60, 60), Enum.Font.GothamBold, 14
    btn.Active, btn.Draggable = true, true

    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color, stroke.Thickness = Color3.fromRGB(255, 60, 60), 2

    btn.MouseButton1Click:Connect(function()
        local orion = findOrionGui()
        if orion then orion.Enabled = not orion.Enabled end
    end)
end

if isMobile then createMobileButton() end

-- ==================== INTERFACE ORION (UI BEAUTIFUL) ====================
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({ Name = "⚡ Supreme Hub | Premium Script 🔥", HidePremium = false, SaveConfig = true, ConfigFolder = "SupremeHubConfig" })

local TabAimbot = Window:MakeTab({ Name = "Aimbot & Magic", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabESP = Window:MakeTab({ Name = "Visuals (ESP)", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local TabMods = Window:MakeTab({ Name = "Gun & Anti-Aim", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local TabConfig = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- 🎯 ABS AIMBOT
local SAimModos = TabAimbot:AddSection({ Name = "🎯 MODOS DE TIRO" })
SAimModos:AddToggle({ Name = "Aimbot Automático", Default = _G.aimbotAutoEnabled, Save = true, Flag = "AA", Callback = function(V) _G.aimbotAutoEnabled = V; if V then _G.silentAimEnabled = false end; end })
SAimModos:AddToggle({ Name = "Aimbot Manual", Default = _G.aimbotManualEnabled, Save = true, Flag = "AM", Callback = function(V) _G.aimbotManualEnabled = V end })
SAimModos:AddToggle({ Name = "✨ Silent Aim (Mágico)", Default = _G.silentAimEnabled, Save = true, Flag = "SAim", Callback = function(V) _G.silentAimEnabled = V; if V then _G.aimbotAutoEnabled = false end end })

local SAimConfigs = TabAimbot:AddSection({ Name = "⚙️ REFINAR MIRA E HITBOX" })
SAimConfigs:AddButton({ Name = "👤 Abrir Seletor Avançado do Corpo (Boneco)", Callback = function() if bonecoFrame then bonecoFrame.Visible = not bonecoFrame.Visible end end })
SAimConfigs:AddToggle({ Name = "Wall Check", Default = _G.wallCheckEnabled, Save = true, Flag = "WCheck", Callback = function(V) _G.wallCheckEnabled = V end })
SAimConfigs:AddToggle({ Name = "Aim Prediction (Inércia)", Default = _G.aimPredictionEnabled, Save = true, Flag = "APred", Callback = function(V) _G.aimPredictionEnabled = V end })
SAimConfigs:AddSlider({ Name = "Smoothness Aimbot", Min = 1, Max = 10, Default = _G.aimbotSmoothness, Color = Color3.fromRGB(0, 255, 100), Increment = 0.5, ValueName = "Lerp", Save = true, Flag = "ASmooth", Callback = function(V) _G.aimbotSmoothness = V end })
SAimConfigs:AddSlider({ Name = "Chance Acerto (Silent Aim)", Min = 1, Max = 100, Default = _G.silentAimHitChance, Color = Color3.fromRGB(200, 100, 255), Increment = 1, ValueName = "%", Save = true, Flag = "SHitC", Callback = function(V) _G.silentAimHitChance = V end })

local SAimFOV, STrigger = TabAimbot:AddSection({ Name = "⭕ CAMPO VISUAL (FOV)" }), TabAimbot:AddSection({ Name = "🔫 AUTO-ATIRADOR (TRIGGERBOT)" })
SAimFOV:AddToggle({ Name = "Mostrar Círculo do FOV", Default = _G.FOV_VISIBLE, Save = true, Flag = "FovV", Callback = function(V) _G.FOV_VISIBLE = V end })
SAimFOV:AddSlider({ Name = "Tamanho Máximo do FOV", Min = 10, Max = 600, Default = _G.FOV_RADIUS, Color = Color3.fromRGB(255, 0, 0), Increment = 5, ValueName = "Raio", Save = true, Flag = "FovR", Callback = function(V) _G.FOV_RADIUS = V end })
STrigger:AddToggle({ Name = "Ativar TriggerBot", Default = _G.triggerBotEnabled, Save = true, Flag = "TBEnable", Callback = function(V) _G.triggerBotEnabled = V end })
STrigger:AddSlider({ Name = "Delay (Milissegundos)", Min = 0, Max = 1, Default = _G.triggerBotDelay, Color = Color3.fromRGB(255, 100, 0), Increment = 0.01, ValueName = "s", Save = true, Flag = "TBDelay", Callback = function(V) _G.triggerBotDelay = V end })

-- 👁️ ABS VISUALS / ESP
local SEspInimigo = TabESP:AddSection({ Name = "🔴 INIMIGOS (ESPs SEPARADOS)" })
SEspInimigo:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espEnemyChams, Save = true, Flag = "EChams", Callback = function(V) _G.espEnemyChams = V end })
SEspInimigo:AddToggle({ Name = "Linha (Tracers)", Default = _G.espEnemyTracers, Save = true, Flag = "ETracers", Callback = function(V) _G.espEnemyTracers = V end })
SEspInimigo:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espEnemySkeleton, Save = true, Flag = "ESkel", Callback = function(V) _G.espEnemySkeleton = V end })
SEspInimigo:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espEnemyText, Save = true, Flag = "EText", Callback = function(V) _G.espEnemyText = V end })

local SEspAliado = TabESP:AddSection({ Name = "🔵 ALIADOS (ESPs SEPARADOS)" })
SEspAliado:AddToggle({ Name = "Aura Colorida (Chams)", Default = _G.espAllyChams, Save = true, Flag = "AChams", Callback = function(V) _G.espAllyChams = V end })
SEspAliado:AddToggle({ Name = "Linha (Tracers)", Default = _G.espAllyTracers, Save = true, Flag = "ATracers", Callback = function(V) _G.espAllyTracers = V end })
SEspAliado:AddToggle({ Name = "Ossos 3D (Skeleton)", Default = _G.espAllySkeleton, Save = true, Flag = "ASkel", Callback = function(V) _G.espAllySkeleton = V end })
SEspAliado:AddToggle({ Name = "Letreiros (Textos)", Default = _G.espAllyText, Save = true, Flag = "AText", Callback = function(V) _G.espAllyText = V end })

local SEspTextConfigs = TabESP:AddSection({ Name = "⚙️ FILTROS DOS LETREIROS" })
SEspTextConfigs:AddToggle({ Name = "Mostrar Nome", Default = _G.espName, Save = true, Flag = "TxtName", Callback = function(V) _G.espName = V end })
SEspTextConfigs:AddToggle({ Name = "Mostrar HP", Default = _G.espHP, Save = true, Flag = "TxtHP", Callback = function(V) _G.espHP = V end })
SEspTextConfigs:AddToggle({ Name = "Mostrar Distância", Default = _G.espDistance, Save = true, Flag = "TxtDist", Callback = function(V) _G.espDistance = V end })
SEspTextConfigs:AddToggle({ Name = "Mostrar Arma", Default = _G.espWeapon, Save = true, Flag = "TxtWeap", Callback = function(V) _G.espWeapon = V end })

-- 🔫 ABS MODS
local SModsLegit, SModsArma, SModsPlayer = TabMods:AddSection({ Name = "👻 ANTI-AIM (DESYNC)" }), TabMods:AddSection({ Name = "🔫 ARMAS E HITBOX" }), TabMods:AddSection({ Name = "👟 PLAYER MODS" })
SModsLegit:AddToggle({ Name = "Legit Desync (Bugar Inércia)", Default = _G.antiAimLegitEnabled, Save = true, Flag = "AALegit", Callback = function(V) _G.antiAimLegitEnabled = V end })
SModsArma:AddToggle({ Name = "No Recoil", Default = _G.noRecoilEnabled, Save = true, Flag = "NRecoil", Callback = function(V) _G.noRecoilEnabled = V end })
SModsArma:AddToggle({ Name = "Infinite Ammo / Fast Reload", Default = _G.infiniteAmmoEnabled, Save = true, Flag = "IAmmo", Callback = function(V) _G.infiniteAmmoEnabled = V; _G.instantReloadEnabled = V end })
SModsArma:AddSlider({ Name = "Aumentar Cabeça Global", Min = 2, Max = 15, Default = _G.hitboxExpander, Color = Color3.fromRGB(150, 0, 255), Increment = 1, ValueName = "Tam", Save = true, Flag = "HExp", Callback = function(V) _G.hitboxExpander = V end })
SModsPlayer:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = _G.walkSpeed, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "W", Save = true, Flag = "PWS", Callback = function(V) _G.walkSpeed = V end })
SModsPlayer:AddSlider({ Name = "JumpPower", Min = 50, Max = 300, Default = _G.jumpPower, Color = Color3.fromRGB(200, 200, 200), Increment = 1, ValueName = "P", Save = true, Flag = "PJP", Callback = function(V) _G.jumpPower = V end })

-- ⚙️ ABS CONFIG (Ocultação, Pânico, Hotkey)
local SConfigGerais = TabConfig:AddSection({ Name = "🛡️ Ocultação e Desligamento" })
SConfigGerais:AddBind({ Name = "👁️ Modo Streamer (Ocultar Desenhos)", Default = Enum.KeyCode.F4, Hold = false, Callback = function() _G.streamerMode = not _G.streamerMode end })

if not isMobile then
    SConfigGerais:AddBind({ 
        Name = "⌨️ Tecla para Abrir/Fechar a Interface do Menu", 
        Default = Enum.KeyCode.RightControl, -- (Padrão RightControl no teclado, ele pode clicar e mudar pra Insert se quiser)
        Hold = false, 
        Callback = function() 
            local orion = findOrionGui()
            if orion then orion.Enabled = not orion.Enabled end
        end 
    })
else
    -- Apenas informa o usuário Mobile que a bolinha dele já ta na tela.
    SConfigGerais:AddButton({ Name = "🔴 Uma Bolinha HUB Flutuante foi criada para você (Mobile)", Callback = function() end })
end

SConfigGerais:AddButton({ Name = "🛑 BOTÃO DE PÂNICO (Apagar Script Completamente)", Callback = function() _G.SupremeHubRunning = false; if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end; _G.clearDrawings(); if bonecoFrame then bonecoFrame:Destroy() end; local mGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"); if mGui:FindFirstChild("SupremeMobileHub") then mGui.SupremeMobileHub:Destroy() end; OrionLib:Destroy() end })

OrionLib:Init()

-- ==================== CORE FUNCTIONS ====================
local function isAlive(c) local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0 end
local function isSameTeam(p1, p2) if not p1 or not p2 then return false end; if p1.Team and p2.Team then return p1.Team == p2.Team end; if p1.TeamColor and p2.TeamColor then return p1.TeamColor == p2.TeamColor end; return false end
local function isFFA() local t = {}; local c = 0; for _, p in pairs(Players:GetPlayers()) do if p.Team or p.TeamColor then t[p.Team and p.Team.Name or p.TeamColor.Name] = true end end; for _ in pairs(t) do c = c + 1 end; return c < 2 end
local function hasLineOfSight(tp) local r = RaycastParams.new(); r.FilterDescendantsInstances = {LocalPlayer.Character}; r.FilterType = Enum.RaycastFilterType.Blacklist; return not workspace:Raycast(Camera.CFrame.Position, (tp.Position - Camera.CFrame.Position).Unit * 5000, r) or workspace:Raycast(Camera.CFrame.Position, (tp.Position - Camera.CFrame.Position).Unit * 5000, r).Instance:IsDescendantOf(tp.Parent) end

local function getRbxPartNames(vName)
    local m = { ["Head"]={"Head"}, ["Torso"]={"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}, ["Left Arm"]={"Left Arm", "LeftUpperArm", "LeftHand"}, ["Right Arm"]={"Right Arm", "RightUpperArm", "RightHand"}, ["Left Leg"]={"Left Leg", "LeftUpperLeg", "LeftFoot"}, ["Right Leg"]={"Right Leg", "RightUpperLeg", "RightFoot"} }
    return m[vName] or {}
end

local function getClosestEnemyAndPart()
    local c = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local clTarget, fAimPart, sDist = nil, nil, _G.FOV_RADIUS
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character or not isAlive(player.Character) then continue end
        if not ffa and isSameTeam(player, LocalPlayer) then continue end 

        local chosenPartList = {}
        for k, state in pairs(_G.HitboxStates) do
            if (state == 1 or (state == 2 and currentFocusLevel == 2)) then
                local t = player.Character:FindFirstChild(k)
                if not t and k == "Torso" then t = player.Character:FindFirstChild("HumanoidRootPart") end
                if t then table.insert(chosenPartList, t) end
            end
        end

        if #chosenPartList == 0 then table.insert(chosenPartList, player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")) end

        for _, aimPart in ipairs(chosenPartList) do
            if aimPart then
                local sPos, v = Camera:WorldToViewportPoint(aimPart.Position)
                local dist = (Vector2.new(sPos.X, sPos.Y) - c).Magnitude
                if v and dist <= 12000 and dist <= sDist then -- Limite pra não bugar na math global
                    if _G.wallCheckEnabled and not hasLineOfSight(aimPart) then continue end
                    sDist, clTarget, fAimPart = dist, player, aimPart
                end
            end
        end
    end
    return clTarget, fAimPart
end

-- ==================== METATABLE HOOKS (SILENT AIM UNIVERSAL) ====================
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    local args = {...}

    if not checkcaller() and _G.silentAimEnabled and math.random(1, 100) <= _G.silentAimHitChance then
        if m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" or m == "FindPartOnRay" or m == "Raycast" then
            local t, ap = getClosestEnemyAndPart()
            if t and ap then
                local origin = Camera.CFrame.Position
                if typeof(args[1]) == "Ray" then args[1] = Ray.new(origin, (ap.Position - origin).Unit * 1000)
                elseif m == "Raycast" then args[1] = origin; args[2] = (ap.Position - origin).Unit * 1500 end
                return OldNamecall(self, unpack(args))
            end
        end
    end
    return OldNamecall(self, ...)
end)

-- ==================== RENDER LOOP (VISUAIS E MACROS) ====================
_G.RunServiceConnection = RunService.RenderStepped:Connect(function()
    local c = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if tick() >= nextAimSwitchTime then currentFocusLevel = (currentFocusLevel == 1) and 2 or 1; nextAimSwitchTime = tick() + ((currentFocusLevel == 1) and 1.8 or 0.35) end
    if fovCircle then fovCircle.Radius = _G.FOV_RADIUS; fovCircle.Position = c; fovCircle.Visible = not _G.streamerMode and _G.FOV_VISIBLE end
    
    if LocalPlayer.Character and isAlive(LocalPlayer.Character) then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = _G.walkSpeed; hum.JumpPower = _G.jumpPower end
    end

    if _G.antiAimLegitEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        if tick() - lastAntiAimTick > 0.05 then
            local ov = root.Velocity
            root.Velocity = Vector3.new(math.random(-100, 100), math.random(-50, 50), math.random(-100, 100))
            task.spawn(function() RunService.RenderStepped:Wait(); root.Velocity = ov end)
            lastAntiAimTick = tick()
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

            local cEn = isAlly and _G.espAllyChams or (not isAlly and _G.espEnemyChams)
            local tEn = isAlly and _G.espAllyTracers or (not isAlly and _G.espEnemyTracers)
            local sEn = isAlly and _G.espAllySkeleton or (not isAlly and _G.espEnemySkeleton)
            local txtEn = isAlly and _G.espAllyText or (not isAlly and _G.espEnemyText)

            -- CHAMS
            if cEn and not _G.streamerMode then
                local high = highlights[player] or Instance.new("Highlight")
                high.Parent = char; highlights[player] = high; high.Adornee = char; high.Enabled = true; high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                high.FillColor = (player == currentTarget and Color3.fromRGB(255, 235, 59)) or (isAlly and Color3.fromRGB(33, 150, 243)) or Color3.fromRGB(244, 67, 54)
                high.OutlineColor = (player == currentTarget and Color3.fromRGB(245, 127, 23)) or (isAlly and Color3.fromRGB(13, 71, 161)) or Color3.fromRGB(183, 28, 28)
            else if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end end

            -- TEXTOS
            if txtEn and not _G.streamerMode and char:FindFirstChild("HumanoidRootPart") then
                local sPos, on = Camera:WorldToViewportPoint((char:FindFirstChild("Head") and char.Head.Position or char.HumanoidRootPart.Position) + Vector3.new(0, 1.5, 0))
                local txt = espTexts[player] or createDrawing("Text")
                espTexts[player] = txt
                if on then
                    txt.Visible = true; txt.Position = Vector2.new(sPos.X, sPos.Y); txt.Center = true; txt.Outline = true; txt.Size = 14; 
                    txt.Color = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(0, 150, 255)) or Color3.fromRGB(255, 255, 255)
                    local info = _G.espName and (player.DisplayName .. "\n") or ""
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if _G.espHP and hum then info = info .. "[" .. math.floor(hum.Health) .. " HP] " end
                    if _G.espDistance then info = info .. "[" .. math.floor((Camera.CFrame.Position - char.HumanoidRootPart.Position).Magnitude) .. "m]\n" else info = info .. (info ~= "" and "\n" or "") end
                    if _G.espWeapon then local tool = char:FindFirstChildOfClass("Tool"); info = info .. (tool and "["..tool.Name.."]" or "[Mãos]") end
                    txt.Text = info
                else txt.Visible = false end
            else if espTexts[player] then espTexts[player]:Remove(); espTexts[player] = nil end end

            -- TRACERS
            if tEn and not _G.streamerMode and char:FindFirstChild("HumanoidRootPart") then
                local sPos, on = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                local tracer = tracers[player] or createDrawing("Line")
                tracers[player] = tracer
                if on then
                    tracer.Visible = true; tracer.Thickness = 1.5; tracer.Transparency = 1
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); tracer.To = Vector2.new(sPos.X, sPos.Y)
                    tracer.Color = (player == currentTarget and Color3.fromRGB(255, 255, 0)) or (isAlly and Color3.fromRGB(0, 150, 255)) or Color3.fromRGB(255, 0, 0)
                else tracer.Visible = false end
            else if tracers[player] then tracers[player]:Remove(); tracers[player] = nil end end

            -- SKELETON ESP
            if sEn and not _G.streamerMode then
                if not skeletons[player] then skeletons[player] = {} end
                local skelParts = skeletons[player]
                for i, con in ipairs(skeletonConnections) do
                    local pa, pb = char:FindFirstChild(con[1]), char:FindFirstChild(con[2])
                    if pa and pb then
                        local posA, oA = Camera:WorldToViewportPoint(pa.Position)
                        local posB, oB = Camera:WorldToViewportPoint(pb.Position)
                        if oA or oB then
                            local line = skelParts[i] or createDrawing("Line"); skelParts[i] = line
                            line.Visible = true; line.Thickness = 1.2; line.Color = isAlly and Color3.fromRGB(150,200,255) or Color3.fromRGB(255,255,255)
                            line.From = Vector2.new(posA.X, posA.Y); line.To = Vector2.new(posB.X, posB.Y)
                        else if skelParts[i] then skelParts[i].Visible = false end end
                    else if skelParts[i] then skelParts[i].Visible = false end end
                end
            else if skeletons[player] then for _, line in pairs(skeletons[player]) do line:Remove() end; skeletons[player] = nil end end

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
            local targetCFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
            if _G.aimbotSmoothness == 1 then Camera.CFrame = targetCFrame
            else Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(1 / _G.aimbotSmoothness, 0.01, 1)) end
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
