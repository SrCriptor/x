-- ⚡ SUPREME HUB | UNIVERSAL PREMIUM
-- Cleanup
pcall(function() for _,g in pairs(game:GetService("CoreGui"):GetChildren()) do if g.Name=="BonequinhoHitboxUI" or g.Name=="SupremeMobileHub" then g:Destroy() end end end)
for _,o in pairs(workspace:GetDescendants()) do if o:IsA("Highlight") then pcall(function() o:Destroy() end) end end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local coreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
_G.SupremeHubRunning = true

-- ═══════════ FLAGS GLOBAIS ═══════════
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotManualEnabled = _G.aimbotManualEnabled or false
_G.aimbotLegitMode = false     -- Modo PRO (Humanizado)
_G.aimbotSmoothness = 1
_G.aimbotStickiness = 10       -- Raio para "grudar" no LEGIT (10-100)
_G.aimbotRandomizeTarget = false -- Alvos Aleatórios (Head/Chest)
_G.silentAimEnabled = _G.silentAimEnabled or false
_G.wallCheckEnabled = true
_G.aimPredictionEnabled = false
_G.silentAimHitChance = 100
_G.FOV_RADIUS = _G.FOV_RADIUS or 65
_G.FOV_VISIBLE = true
_G.legitDeadzone = 10
_G.espNPCEnabled = false
_G.magicBulletNPC = false       -- Silent Aim para NPCs
_G.magicBulletEnemy = false     -- Silent Aim para Players
_G.mouseSpoofEnabled = false   -- Opcional (Spoof Mouse.Hit)
_G.telekillPlayerEnabled = false
_G.telekillNPCEnabled = false
_G.telekillDistance = 5        -- Distância para Telekill (2-20)
_G.stealthModeEnabled = true   -- Ativa Spoofing de Properties
_G.safeModeEnabled = false     -- Bloqueia Funções de Risco
_G.radarEnabled = false        -- Radar 2D
_G.radarScale = 0.5           -- Zoom das Bolinhas
_G.radarDotsOnly = false      -- Mostrar apenas as bolinhas (sem circulo)
_G.radarPos = Vector2.new(200, 200)
_G.selectedTheme = "Default"
_G.isRGBTheme = false
_G.fullbrightEnabled = _G.fullbrightEnabled or false   -- Iluminação Total
_G.noFogEnabled = false
_G.alwaysDayEnabled = false
_G.streamproofEnabled = false -- Modo Anti-OBS
_G.espEnemyBox = true; _G.espEnemyChams = true; _G.espEnemyTracers = false
_G.espEnemySkeleton = false; _G.espEnemyText = true
_G.espAllyBox = false; _G.espAllyChams = false; _G.espAllyTracers = false
_G.espAllySkeleton = false; _G.espAllyText = false
_G.espName = true; _G.espHP = true; _G.espDistance = true; _G.espWeapon = true
_G.espMaxDistance = 1000
_G.noRecoilEnabled = true; _G.noSpreadEnabled = true
_G.infiniteAmmoEnabled = true; _G.instantReloadEnabled = true; _G.rapidFireEnabled = false
_G.walkSpeed = 16; _G.jumpPower = 50
_G.hitboxExpander = 2
_G.HitboxStates = _G.HitboxStates or {Head=1,Torso=0,["Left Arm"]=0,["Right Arm"]=0,["Left Leg"]=0,["Right Leg"]=0}

local currentTarget = nil
local currentTargetModel = nil
local aiming = false
local rapidFireThread = nil
local allDrawings = {}
local espCache = {}
local npcHighlights = {}
local lastWeaponTick = 0
local lastAppliedTool = nil

-- ═══════════ KEYWORDS DETECÇÃO INTELIGENTE ═══════════
local RECOIL_KW = {"recoil","spread","kick","camerashake","recoilmax","recoilmin","spreadangle","kickback","bloom","hipfire","aimspread","deviation","inaccuracy","bulletspread","dispersion","sway"}
local AMMO_KW = {"ammo","currentammo","magsize","maxammo","clipsize","bullets","_ammo","ammocount","magazinesize","clip","magazine","rounds","bulletcount","remainingammo","currentclip"}
local RELOAD_KW = {"reloadtime","reloadspeed","reloadduration","reloadcooldown","reloaddelay","reloadlength","reloadrate"}
local FIRERATE_KW = {"firerate","firedelay","shootcooldown","rateoffire","cooldown","attackcooldown","fireinterval","shootdelay","firespeed","shotdelay","shootinterval","burstdelay","swingcooldown","attackdelay","attackspeed"}

-- ═══════════ DETECÇÃO INTELIGENTE MODO DE JOGO ═══════════
local cachedGameMode, lastModeCheck = nil, 0
local function detectGameMode()
    local now = tick()
    if cachedGameMode and (now - lastModeCheck) < 2 then return cachedGameMode end
    lastModeCheck = now
    local ok, teams = pcall(function() return game:GetService("Teams"):GetTeams() end)
    if not ok or #teams == 0 then cachedGameMode = "FFA"; return "FFA" end
    local active, neutral = {}, nil
    for _,t in pairs(teams) do
        local n = t.Name:lower()
        if n=="neutral" or n=="none" or n=="ffa" or n=="default" or n=="lobby" or n=="spectator" or n=="spectators" then neutral = t end
        if #t:GetPlayers() > 0 then active[t] = true end
    end
    local cnt = 0; for _ in pairs(active) do cnt+=1 end
    if cnt <= 1 then cachedGameMode="FFA"; return "FFA" end
    if cnt == 2 and neutral and active[neutral] then cachedGameMode="FFA"; return "FFA" end
    cachedGameMode = "TEAMS"; return "TEAMS"
end

local function isEnemy(player)
    if not player or player == LP then return false end
    if detectGameMode() == "FFA" then return true end
    if not LP.Team or not player.Team then return true end
    return LP.Team ~= player.Team
end

-- ═══════════ UTILITÁRIOS ═══════════
local function isAlive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function hasLOS(part)
    if not _G.wallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local diff = (part.Position - origin)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local r = workspace:Raycast(origin, diff, rp)
    return not r or r.Instance:IsDescendantOf(part.Parent)
end

-- ═══════════ NPC DETECTION (OTIMIZADO) ═══════════
local cachedNPCs, lastNPCScan = {}, 0
local function getNPCs()
    if tick() - lastNPCScan < 3 then return cachedNPCs end
    lastNPCScan = tick()
    -- Constrói set de characters de players UMA VEZ (evita loop dentro de loop)
    local playerChars = {}
    for _,p in pairs(Players:GetPlayers()) do if p.Character then playerChars[p.Character]=true end end
    local npcs = {}
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position
    for _,o in pairs(workspace:GetDescendants()) do
        if #npcs >= 20 then break end -- Limita a 20 NPCs para performance
        if o:IsA("Model") and not playerChars[o] and o ~= LP.Character then
            local hum = o:FindFirstChildOfClass("Humanoid")
            local head = o:FindFirstChild("Head")
            if hum and head and hum.Health > 0 then
                -- Só NPCs dentro da distância ESP
                if myPos then
                    local d = (head.Position - myPos).Magnitude
                    if d <= _G.espMaxDistance then table.insert(npcs, o) end
                else table.insert(npcs, o) end
            end
        end
    end
    cachedNPCs = npcs; return npcs
end

-- ═══════════ HITBOX PART SELECTION ═══════════
local PARTS_R6 = {Head={"Head"},Torso={"Torso"},["Left Arm"]={"Left Arm"},["Right Arm"]={"Right Arm"},["Left Leg"]={"Left Leg"},["Right Leg"]={"Right Leg"}}
local PARTS_R15 = {Head={"Head"},Torso={"UpperTorso","LowerTorso"},["Left Arm"]={"LeftUpperArm","LeftLowerArm"},["Right Arm"]={"RightUpperArm","RightLowerArm"},["Left Leg"]={"LeftUpperLeg","LeftLowerLeg"},["Right Leg"]={"RightUpperLeg","RightLowerLeg"}}

local function getTargetPart(char)
    local map = char:FindFirstChild("UpperTorso") and PARTS_R15 or PARTS_R6
    local mousePos = UIS:GetMouseLocation()
    
    -- MODO LEGIT PRO: Seleciona o osso MAIS PRÓXIMO entre os selecionados no Bonequinho
    if _G.aimbotLegitMode then
        local best, bestD = nil, math.huge
        for hName, state in pairs(_G.HitboxStates) do
            if state > 0 and map[hName] then
                for _, pName in pairs(map[hName]) do
                    local p = char:FindFirstChild(pName)
                    if p then
                        local sp, vis = Camera:WorldToViewportPoint(p.Position)
                        if vis then
                            local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                            if d < bestD then best, bestD = p, d end
                        end
                    end
                end
            end
        end
        if best then return best end
    end
    
    -- MODO NORMAL: Segue prioridade do Hitbox Selector
    for priority = 1, 2 do
        local best, bestD = nil, math.huge
        for hName, state in pairs(_G.HitboxStates) do
            if state == priority and map[hName] then
                for _,pName in pairs(map[hName]) do
                    local p = char:FindFirstChild(pName)
                    if p then
                        local sp, vis = Camera:WorldToViewportPoint(p.Position)
                        if vis then
                            local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                            if d < bestD then best, bestD = p, d end
                        end
                    end
                end
            end
        end
        if best then return best end
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════ WEAPON MODS INTELIGENTE ═══════════
local function matchKW(name, kws) local l=name:lower(); for _,k in pairs(kws) do if l:find(k,1,true) then return true end end; return false end

local function scanSet(tool, kws, val)
    if not tool then return end
    pcall(function() for an,av in pairs(tool:GetAttributes()) do if matchKW(an,kws) then
        if type(av)=="number" then tool:SetAttribute(an,val)
        elseif typeof(av)=="Vector2" then tool:SetAttribute(an,Vector2.new(val,val))
        elseif typeof(av)=="Vector3" then tool:SetAttribute(an,Vector3.new(val,val,val)) end
    end end end)
    pcall(function() for _,c in pairs(tool:GetDescendants()) do
        if matchKW(c.Name, kws) then
            if c:IsA("NumberValue") or c:IsA("IntValue") then pcall(function() c.Value=val end)
            elseif c:IsA("Vector3Value") then pcall(function() c.Value=Vector3.new(val,val,val) end)
            elseif c:IsA("BoolValue") and val==0 then pcall(function() c.Value=false end) end
        end
        pcall(function() for an,av in pairs(c:GetAttributes()) do if matchKW(an,kws) then
            if type(av)=="number" then c:SetAttribute(an,val)
            elseif typeof(av)=="Vector2" then c:SetAttribute(an,Vector2.new(val,val))
            elseif typeof(av)=="Vector3" then c:SetAttribute(an,Vector3.new(val,val,val)) end
        end end end)
    end end)
end

local function scanMaxAmmo(tool)
    if not tool then return end
    pcall(function() for an,av in pairs(tool:GetAttributes()) do if matchKW(an,AMMO_KW) and type(av)=="number" then
        local mx = tool:GetAttribute("Max"..an) or tool:GetAttribute("maxAmmo") or tool:GetAttribute("MaxAmmo") or 999
        if type(mx)~="number" or mx<=0 then mx=999 end; tool:SetAttribute(an,mx)
    end end end)
    pcall(function() for _,c in pairs(tool:GetDescendants()) do
        if (c:IsA("NumberValue") or c:IsA("IntValue")) and matchKW(c.Name,AMMO_KW) then
            local mx = c.Parent and c.Parent:FindFirstChild("Max"..c.Name)
            local v = (mx and mx:IsA("NumberValue")) and mx.Value or 999
            if v<=0 then v=999 end; c.Value = v
        end
    end end)
end

local function applyWeaponMods(tool)
    if not tool then return end
    if _G.noRecoilEnabled then scanSet(tool, RECOIL_KW, 0) end
    if _G.noSpreadEnabled then scanSet(tool, RECOIL_KW, 0) end
    if _G.instantReloadEnabled then scanSet(tool, RELOAD_KW, 0.01) end
    if _G.rapidFireEnabled then scanSet(tool, FIRERATE_KW, 0.01) end
end

-- ═══════════ FOV CIRCLE ═══════════
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency=0.2; fovCircle.Thickness=1.5; fovCircle.Filled=false; fovCircle.Color=Color3.new(1,1,1)
table.insert(allDrawings, fovCircle)

-- ═══════════ ESP DRAWING SYSTEM ═══════════
local function regDraw(d) table.insert(allDrawings, d); return d end
local function createESP()
    local e = {lastTextUpdate = 0}
    -- Box (Cantoneiras / Corners)
    e.corners = {}
    for i=1,8 do e.corners[i] = regDraw(Drawing.new("Line")); e.corners[i].Thickness=2.5; e.corners[i].Visible=false end
    -- Health bar (Sleek)
    e.hpBar = regDraw(Drawing.new("Line")); e.hpBar.Thickness=2; e.hpBar.Visible=false
    e.hpBarBG = regDraw(Drawing.new("Line")); e.hpBarBG.Thickness=4; e.hpBarBG.Color=Color3.new(0,0,0); e.hpBarBG.Visible=false
    -- Tracer
    e.tracer = regDraw(Drawing.new("Line")); e.tracer.Thickness=1; e.tracer.Visible=false
    -- Text label (Extreme Performance: Throttled & Outlined)
    e.txt = regDraw(Drawing.new("Text")); e.txt.Size=13; e.txt.Outline=true; e.txt.Center=false; e.txt.Font=3; e.txt.Visible=false
    -- Chams (Highlight)
    e.chams = nil
    -- Skeleton
    e.skel = {}
    for i=1,14 do e.skel[i]=regDraw(Drawing.new("Line")); e.skel[i].Thickness=1; e.skel[i].Transparency=0.5; e.skel[i].Visible=false end
    return e
end

local function hideESP(e)
    if not e then return end
    for i=1,8 do e.corners[i].Visible=false end
    e.hpBar.Visible=false; e.hpBarBG.Visible=false
    e.tracer.Visible=false
    e.txt.Visible=false
    for i=1,14 do e.skel[i].Visible=false end
    if e.chams then pcall(function() e.chams:Destroy() end); e.chams=nil end
end

local function removeESP(key)
    if espCache[key] then hideESP(espCache[key]); espCache[key]=nil end
end

local SKEL_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local SKEL_R15 = {{"Head","UpperTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"UpperTorso","LowerTorso"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}

-- ═══════════ LIGHTING RESTORE SYSTEM ═══════════
local originalLighting = {
    Ambient = lighting.Ambient,
    OutdoorAmbient = lighting.OutdoorAmbient,
    ColorShift_Bottom = lighting.ColorShift_Bottom,
    ColorShift_Top = lighting.ColorShift_Top,
    Brightness = lighting.Brightness,
    FogStart = lighting.FogStart,
    FogEnd = lighting.FogEnd,
    ClockTime = lighting.ClockTime,
    GlobalShadows = lighting.GlobalShadows
}

local function restoreLighting()
    lighting.Ambient = originalLighting.Ambient
    lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
    lighting.ColorShift_Top = originalLighting.ColorShift_Top
    lighting.Brightness = originalLighting.Brightness
    lighting.FogStart = originalLighting.FogStart
    lighting.FogEnd = originalLighting.FogEnd
    lighting.ClockTime = originalLighting.ClockTime
    lighting.GlobalShadows = originalLighting.GlobalShadows
end

-- Cor da HP baseada na porcentagem: verde → amarelo → vermelho
local function hpColor(pct)
    if pct > 0.6 then return Color3.fromRGB(0, 255, 50) end
    if pct > 0.3 then return Color3.fromRGB(255, 255, 0) end
    return Color3.fromRGB(255, 30, 30)
end

-- entityType: "enemy", "ally", "npc"
local function updateESP(key, char, color, showBox, showChams, showTracers, showSkel, showText, entityType)
    if not char or not isAlive(char) then removeESP(key); return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not head or not root then removeESP(key); return end
    local dist3D = (root.Position - Camera.CFrame.Position).Magnitude
    if dist3D > _G.espMaxDistance then if espCache[key] then hideESP(espCache[key]) end; return end

    if not espCache[key] then espCache[key] = createESP() end
    local e = espCache[key]

    local rootSP = Camera:WorldToViewportPoint(root.Position)
    local topSP, topVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.4, 0))
    local botSP, botVis = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    if not topVis or not botVis then hideESP(e); return end

    local centerX = rootSP.X
    local boxH = math.abs(botSP.Y - topSP.Y)
    local boxW = boxH * 0.6
    local boxX = centerX - boxW / 2
    local boxY = topSP.Y
    
    local isTarget = (key == currentTarget or char == currentTargetModel)
    local mainColor = isTarget and Color3.new(1,1,0) or color

    -- ═══ CORNER BOX ═══
    if showBox then
        local lineLen = boxW / 4
        local c = e.corners
        -- TL
        c[1].From = Vector2.new(boxX, boxY); c[1].To = Vector2.new(boxX + lineLen, boxY)
        c[2].From = Vector2.new(boxX, boxY); c[2].To = Vector2.new(boxX, boxY + lineLen)
        -- TR
        c[3].From = Vector2.new(boxX + boxW, boxY); c[3].To = Vector2.new(boxX + boxW - lineLen, boxY)
        c[4].From = Vector2.new(boxX + boxW, boxY); c[4].To = Vector2.new(boxX + boxW, boxY + lineLen)
        -- BL
        c[5].From = Vector2.new(boxX, boxY + boxH); c[5].To = Vector2.new(boxX + lineLen, boxY + boxH)
        c[6].From = Vector2.new(boxX, boxY + boxH); c[6].To = Vector2.new(boxX, boxY + boxH - lineLen)
        -- BR
        c[7].From = Vector2.new(boxX + boxW, boxH + boxY); c[7].To = Vector2.new(boxX + boxW - lineLen, boxH + boxY)
        c[8].From = Vector2.new(boxX + boxW, boxH + boxY); c[8].To = Vector2.new(boxX + boxW, boxH + boxY - lineLen)
        for i=1,8 do c[i].Color=mainColor; c[i].Visible=true end
    else for i=1,8 do e.corners[i].Visible=false end end

    -- ═══ HEALTH BAR ═══
    if showBox or showText then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barX = boxX - 5
            e.hpBarBG.From=Vector2.new(barX, boxY); e.hpBarBG.To=Vector2.new(barX, boxY+boxH); e.hpBarBG.Visible=true
            e.hpBar.From=Vector2.new(barX, boxY+boxH-(boxH*pct)); e.hpBar.To=Vector2.new(barX, boxY+boxH)
            e.hpBar.Color=hpColor(pct); e.hpBar.Visible=true
        else e.hpBar.Visible=false; e.hpBarBG.Visible=false end
    else e.hpBar.Visible=false; e.hpBarBG.Visible=false end

    -- ═══ CHAMS (Highlight) ═══
    if showChams then
        if not e.chams or e.chams.Parent ~= char then
            if e.chams then pcall(function() e.chams:Destroy() end) end
            e.chams = Instance.new("Highlight"); e.chams.Parent = char
        end
        e.chams.Adornee=char; e.chams.Enabled=true; e.chams.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        e.chams.FillColor=mainColor; e.chams.OutlineColor=Color3.new(1,1,1)
        e.chams.FillTransparency=0.75; e.chams.OutlineTransparency=0
    else if e.chams then pcall(function() e.chams:Destroy() end); e.chams=nil end end

    -- ═══ TRACERS ═══
    if showTracers then
        local fromPt = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        local toPt = Vector2.new(centerX, botSP.Y)
        e.tracer.From=fromPt; e.tracer.To=toPt; e.tracer.Color=mainColor; e.tracer.Visible=true
    else e.tracer.Visible=false end

    -- ═══ SKELETON ═══
    if showSkel then
        local bones = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
        for i, pair in ipairs(bones) do
            local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
            if p1 and p2 and e.skel[i] then
                local s1,v1 = Camera:WorldToViewportPoint(p1.Position)
                local s2,v2 = Camera:WorldToViewportPoint(p2.Position)
                if v1 and v2 then
                    e.skel[i].From=Vector2.new(s1.X,s1.Y); e.skel[i].To=Vector2.new(s2.X,s2.Y); e.skel[i].Color=mainColor; e.skel[i].Visible=true
                else e.skel[i].Visible=false end
            elseif e.skel[i] then e.skel[i].Visible=false end
        end
        for i=#bones+1, 14 do if e.skel[i] then e.skel[i].Visible=false end end
    else for i=1,14 do e.skel[i].Visible=false end end

    -- ═══ TEXT LABEL (THROTTLED FOR MAXIMUM PERFORMANCE) ═══
    if showText then
        if tick() - e.lastTextUpdate > 0.1 then -- Só atualiza o TEXTO a cada 100ms
            e.lastTextUpdate = tick()
            local lines = {}
            local tagT = isTarget and "TARGET" or entityType:upper()
            table.insert(lines, "[ "..tagT.." ]")
            
            if _G.espName then
                local nm = (typeof(key)=="Instance" and key:IsA("Player")) and (key.DisplayName or key.Name) or (char.Name or "NPC")
                table.insert(lines, nm)
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if _G.espHP and hum then
                table.insert(lines, "HP: "..math.floor(hum.Health))
            end
            
            if _G.espDistance then table.insert(lines, math.floor(dist3D).."m") end
            
            if _G.espWeapon then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then table.insert(lines, tool.Name) end
            end
            
            e.txt.Text = table.concat(lines, "\n")
            e.txt.Color = mainColor
        end
        -- Posição atualiza em todo frame para suavidade
        e.txt.Position = Vector2.new(boxX + boxW + 4, boxY)
        e.txt.Visible = true
    else
        e.txt.Visible = false
    end
end

-- ═══════════ TARGETING ═══════════
local function getClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestModel, bestDist = nil, nil, _G.FOV_RADIUS
    
    -- Determina o que devemos procurar baseado nas flags ativas
    local searchEnemies = _G.magicBulletEnemy or _G.aimbotAutoEnabled or _G.aimbotManualEnabled or _G.espEnemiesEnabled
    local searchNPCs = _G.magicBulletNPC or _G.espNPCEnabled
    
    if searchEnemies then
        for _,p in pairs(Players:GetPlayers()) do
            if p==LP or not p.Character or not isAlive(p.Character) then continue end
            if not isEnemy(p) then continue end
            local part = getTargetPart(p.Character)
            if part then
                local sp,vis = Camera:WorldToViewportPoint(part.Position)
                local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                if vis and d<=bestDist and (hasLOS(part) or _G.wallPierceEnabled) then bestDist=d; best=p; bestModel=p.Character end
            end
        end
    end
    
    if searchNPCs then
        for _,npc in pairs(getNPCs()) do
            -- Re-checa se NPC está vivo (cache pode estar desatualizado)
            if not isAlive(npc) then continue end
            local part = getTargetPart(npc)
            if part then
                local sp,vis = Camera:WorldToViewportPoint(part.Position)
                local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                if vis and d<=bestDist and (hasLOS(part) or _G.wallPierceEnabled) then bestDist=d; best=npc; bestModel=npc end
            end
        end
    end
    return best, bestModel
end

local function getClosest3D(npcOnly)
    local center = Camera.CFrame.Position
    local best, bestDist = nil, 1000
    if npcOnly then
        for _,npc in pairs(getNPCs()) do
            if isAlive(npc) then
                local d = (npc.PrimaryPart.Position - center).Magnitude
                if d < bestDist then bestDist = d; best = npc end
            end
        end
    else
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and isAlive(p.Character) and isEnemy(p) then
                local d = (p.Character.PrimaryPart.Position - center).Magnitude
                if d < bestDist then bestDist = d; best = p.Character end
            end
        end
    end
    return best
end

-- ═══════════ LIGHTING & UTILS ═══════════
local function toggleFullbright(v)
    _G.fullbrightEnabled = v
    if not v then restoreLighting(); return end
    task.spawn(function()
        while _G.fullbrightEnabled and _G.SupremeHubRunning do
            lighting.Ambient = Color3.fromRGB(200, 200, 200)
            lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            lighting.Brightness = 2
            lighting.GlobalShadows = false
            task.wait(1.5)
        end
    end)
end

local function toggleNoFog(v)
    _G.noFogEnabled = v
    if not v then restoreLighting(); return end
    task.spawn(function()
        while _G.noFogEnabled and _G.SupremeHubRunning do
            lighting.FogEnd = 9e9
            for _, v in pairs(lighting:GetChildren()) do
                if v:IsA("Atmosphere") then v.Density = 0 end
            end
            task.wait(1.5)
        end
    end)
end

local function toggleAlwaysDay(v)
    _G.alwaysDayEnabled = v
    if not v then restoreLighting(); return end
    task.spawn(function()
        while _G.alwaysDayEnabled and _G.SupremeHubRunning do
            lighting.ClockTime = 14
            task.wait(1.5)
        end
    end)
end

local function toggleStreamproof()
    local CoreGui = game:GetService("CoreGui")
    for _, v in pairs(CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == "SupremeHubUI" then
            v.DisplayOrder = -999999
        end
    end
end

-- ═══════════ THEME SYSTEM ═══════════
_G.SupremeThemes = {
    Default = {
        Main = Color3.fromRGB(25, 25, 25), Second = Color3.fromRGB(32, 32, 32), Stroke = Color3.fromRGB(60, 60, 60),
        Divider = Color3.fromRGB(60, 60, 60), Text = Color3.fromRGB(240, 240, 240), TextDark = Color3.fromRGB(150, 150, 150)
    },
    Matrix = {
        Main = Color3.fromRGB(5, 5, 5), Second = Color3.fromRGB(10, 15, 10), Stroke = Color3.fromRGB(0, 255, 0),
        Divider = Color3.fromRGB(0, 100, 0), Text = Color3.fromRGB(0, 255, 0), TextDark = Color3.fromRGB(0, 180, 0)
    },
    Cyberpunk = {
        Main = Color3.fromRGB(20, 10, 25), Second = Color3.fromRGB(30, 20, 40), Stroke = Color3.fromRGB(255, 0, 255),
        Divider = Color3.fromRGB(0, 255, 255), Text = Color3.fromRGB(255, 255, 255), TextDark = Color3.fromRGB(255, 0, 255)
    },
    WatchDogs = {
        Main = Color3.fromRGB(10, 10, 10), Second = Color3.fromRGB(20, 25, 30), Stroke = Color3.fromRGB(0, 255, 255),
        Divider = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(255, 255, 255), TextDark = Color3.fromRGB(0, 180, 255)
    },
    Yellow = {
        Main = Color3.fromRGB(15, 15, 0), Second = Color3.fromRGB(30, 30, 0), Stroke = Color3.fromRGB(255, 255, 0),
        Divider = Color3.fromRGB(100, 100, 0), Text = Color3.fromRGB(255, 255, 0), TextDark = Color3.fromRGB(200, 200, 0)
    }
}

local function applyTheme(themeName)
    _G.selectedTheme = themeName
    _G.isRGBTheme = (themeName == "Neon RGB")
    if _G.isRGBTheme then return end
    
    local theme = _G.SupremeThemes[themeName] or _G.SupremeThemes.Default
    OrionLib.Themes[themeName] = theme
    OrionLib.SelectedTheme = themeName
    
    for type, objects in pairs(OrionLib.ThemeObjects) do
        for _, obj in pairs(objects) do
            pcall(function()
                local prop = "BackgroundColor3"
                if obj:IsA("UIStroke") then prop = "Color"
                elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then prop = "TextColor3"
                elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then prop = "ImageColor3"
                elseif obj:IsA("ScrollingFrame") then prop = "ScrollBarImageColor3" end
                obj[prop] = theme[type]
            end)
        end
    end
end

task.spawn(function()
    while task.wait(0.05) do
        if _G.isRGBTheme and _G.SupremeHubRunning then
            local hue = tick() % 5 / 5
            local color = Color3.fromHSV(hue, 1, 1)
            for type, objects in pairs(OrionLib.ThemeObjects) do
                if type == "Stroke" or type == "Text" or type == "Divider" then
                    for _, obj in pairs(objects) do
                        pcall(function()
                            local prop = "BackgroundColor3"
                            if obj:IsA("UIStroke") then prop = "Color"
                            elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then prop = "TextColor3"
                            elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then prop = "ImageColor3" end
                            obj[prop] = color
                        end)
                    end
                end
            end
        end
    end
end)

local function teleportToLowPopServer()
    local Http = game:GetService("HttpService")
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local s, r = pcall(function() return Http:JSONDecode(game:HttpGet(Api)) end)
    if s and r.data then
        for _, srv in pairs(r.data) do
            if srv.playing > 0 and srv.playing < srv.maxPlayers then
                TPS:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                break
            end
        end
    end
end

-- ═══════════ RADAR 2D ═══════════
local radarCircle = Drawing.new("Circle")
radarCircle.Thickness = 2; radarCircle.NumSides = 60; radarCircle.Radius = 75; radarCircle.Filled = false; radarCircle.Color = Color3.fromRGB(255,255,255); radarCircle.Visible = false
local radarCenter = Drawing.new("Circle")
radarCenter.Radius = 3; radarCenter.Filled = true; radarCenter.Color = Color3.fromRGB(255,255,255); radarCenter.Visible = false

local draggingRadar = false
local dragStart = Vector2.new(0,0)
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and _G.radarEnabled and not _G.radarDotsOnly then
        local mPos = UIS:GetMouseLocation()
        if (mPos - _G.radarPos).Magnitude < 75 then draggingRadar = true; dragStart = mPos - _G.radarPos end
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingRadar = false end end)
RunService.RenderStepped:Connect(function() if draggingRadar then _G.radarPos = UIS:GetMouseLocation() - dragStart end end)

local radarDots = {}
local function updateRadar()
    if not _G.radarEnabled then
        radarCircle.Visible = false; radarCenter.Visible = false
        for _,d in pairs(radarDots) do d.Visible=false end; return
    end
    
    local pos = _G.radarPos
    radarCircle.Position = pos; radarCircle.Visible = not _G.radarDotsOnly; radarCircle.Transparency = 0.5
    radarCenter.Position = pos; radarCenter.Visible = not _G.radarDotsOnly

    local function drawDot(targetPos, color)
        local rel = (targetPos - Camera.CFrame.Position); local rPos = Vector2.new(rel.X, rel.Z)
        local mag = rPos.Magnitude; if mag > 1000 then return end
        local angle = math.atan2(rPos.Y, rPos.X) + math.rad(Camera.CFrame.Rotation.Y)
        local finalPos = pos + Vector2.new(math.cos(angle)*mag*_G.radarScale, math.sin(angle)*mag*_G.radarScale)
        if (finalPos - pos).Magnitude < 75 or _G.radarDotsOnly then
            local d = Drawing.new("Circle"); d.Radius=3.5; d.Filled=true; d.Color=color; d.Position=finalPos; d.Visible=not _G.streamproofEnabled; table.insert(radarDots, d)
        end
    end

    for _,d in pairs(radarDots) do d:Remove() end; radarDots = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character and isAlive(p.Character) and isEnemy(p) then drawDot(p.Character.PrimaryPart.Position, Color3.fromRGB(255,0,0)) end
    end
    for _,npc in pairs(getNPCs()) do if isAlive(npc) then drawDot(npc.PrimaryPart.Position, Color3.fromRGB(200,0,255)) end end
end

-- ═══════════ WEAPON MODS (RECURSIVE & LOCKED) ═══════════
local function weaponScan(tool)
    if not tool or not _G.SupremeHubRunning then return end
    for _, obj in pairs(tool:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local n = obj.Name:lower()
            if _G.noRecoilEnabled and (n:find("recoil") or n:find("kick") or n:find("shake")) then obj.Value = 0 end
            if _G.noSpreadEnabled and (n:find("spread") or n:find("accuracy") or n:find("minspread")) then obj.Value = 0 end
            if _G.infiniteAmmoEnabled and (n:find("ammo") or n:find("bullets") or n:find("clip")) then if obj.Value < 99 then obj.Value = 999 end end
            if _G.rapidFireEnabled and (n:find("firerate") or n:find("cooldown") or n:find("wait")) then obj.Value = 0.01 end
            if _G.instantReloadEnabled and (n:find("reload")) then obj.Value = 0.01 end
        end
    end
    for k, v in pairs(tool:GetAttributes()) do
        local n = k:lower()
        if _G.noRecoilEnabled and (n:find("recoil") or n:find("kick")) then tool:SetAttribute(k, 0) end
        if _G.noSpreadEnabled and (n:find("spread") or n:find("accuracy")) then tool:SetAttribute(k, 0) end
        if _G.rapidFireEnabled and (n:find("firerate") or n:find("delay")) then tool:SetAttribute(k, 0.01) end
    end
end

-- ═══════════ RAPID FIRE ═══════════
local isHoldingFire = false
local function startRapidFire()
    if rapidFireThread then return end
    rapidFireThread = task.spawn(function()
        while isHoldingFire and _G.rapidFireEnabled and _G.SupremeHubRunning do
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then pcall(function() tool:Activate() end)
                    pcall(function() for _,d in pairs(tool:GetDescendants()) do
                        if d:IsA("RemoteEvent") then local n=d.Name:lower()
                            if n:find("fire") or n:find("shoot") or n:find("attack") or n:find("swing") or n:find("stab") then d:FireServer() end
                        end
                    end end)
                end
            end
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 0)
                task.wait(0.02)
                vim:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 0)
            end)
            task.wait(0.03)
        end
        rapidFireThread = nil
    end)
end

Mouse.Button1Down:Connect(function() isHoldingFire=true; if _G.rapidFireEnabled then startRapidFire() end end)
Mouse.Button1Up:Connect(function() isHoldingFire=false end)
Mouse.Button2Down:Connect(function() aiming=true end)
Mouse.Button2Up:Connect(function() aiming=false end)

-- ═══════════ STEALTH & PROPERTY SPOOFING ═══════════
pcall(function()
    -- ═══════════ MULTI-HOOK (INDEX) ═══════════
    local oldIdx; oldIdx = hookmetamethod(game, "__index", newcclosure(function(self, idx)
        if not _G.SupremeHubRunning then return oldIdx(self, idx) end
        
        -- Stealth (WalkSpeed/JumpPower)
        if _G.stealthModeEnabled and not checkcaller() then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if self == hum then
                if idx == "WalkSpeed" then return 16 end
                if idx == "JumpPower" then return 50 end
            end
        end
        
        -- Mouse Spoofing
        if _G.mouseSpoofEnabled and (idx == "Hit" or idx == "Target") and self:IsA("Mouse") then
            local isNPC = currentTargetModel and not game:GetService("Players"):GetPlayerFromCharacter(currentTargetModel)
            local silentAllowed = (isNPC and _G.magicBulletNPC) or (not isNPC and (_G.magicBulletEnemy or _G.silentAimEnabled))
            if silentAllowed and currentTargetModel then
                local tPart = getTargetPart(currentTargetModel)
                if tPart then
                    if idx == "Hit" then return tPart.CFrame end
                    if idx == "Target" then return tPart end
                end
            end
        end
        
        return oldIdx(self, idx)
    end))

    -- ═══════════ STEALTH (NEWINDEX) ═══════════
    local oldNewIdx; oldNewIdx = hookmetamethod(game, "__newindex", newcclosure(function(self, idx, val)
        if _G.SupremeHubRunning and _G.stealthModeEnabled and not checkcaller() then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if self == hum then
                if idx == "WalkSpeed" or idx == "JumpPower" then 
                    if val == 16 or val == 50 or val == 0 then return end 
                end
            end
        end
        return oldNewIdx(self, idx, val)
    end))

    -- ═══════════ SILENT AIM (NAMECALL) ═══════════
    local oldNc; oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not _G.SupremeHubRunning then return oldNc(self, ...) end
        
        local isNPC = currentTargetModel and not game:GetService("Players"):GetPlayerFromCharacter(currentTargetModel)
        local silentAllowed = (isNPC and _G.magicBulletNPC) or (not isNPC and (_G.magicBulletEnemy or _G.silentAimEnabled))
        
        if silentAllowed and currentTargetModel then
            local tPart = getTargetPart(currentTargetModel)
            if tPart then
                if (method == "Raycast" and self == workspace) then
                    local args = {...}; args[2] = (tPart.Position - args[1]).Unit * args[2].Magnitude
                    return oldNc(self, unpack(args))
                end
                if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local args = {...}
                    if typeof(args[1]) == "Ray" then
                        args[1] = Ray.new(args[1].Origin, (tPart.Position - args[1].Origin).Unit * args[1].Direction.Magnitude)
                        return oldNc(self, unpack(args))
                    end
                end
            end
        end
        return oldNc(self, ...)
    end))
end)

-- ═══════════ MAIN LOOP ═══════════
local conn; conn = RunService.RenderStepped:Connect(function()
    if not _G.SupremeHubRunning then conn:Disconnect(); return end
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local char = LP.Character

    -- Weapon mods
    if char and tick() - lastWeaponTick > 0.5 then
        lastWeaponTick = tick()
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            if tool ~= lastAppliedTool then applyWeaponMods(tool); lastAppliedTool=tool end
            if _G.noRecoilEnabled then scanSet(tool, RECOIL_KW, 0) end
            if _G.infiniteAmmoEnabled then scanMaxAmmo(tool) end
            if _G.rapidFireEnabled then scanSet(tool, FIRERATE_KW, 0.01) end
            if _G.instantReloadEnabled then scanSet(tool, RELOAD_KW, 0.01) end
        end
    end

    -- Movement & Safety
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if _G.safeModeEnabled then
            hum.WalkSpeed = 16; hum.JumpPower = 50
        else
            hum.WalkSpeed = _G.walkSpeed; hum.JumpPower = _G.jumpPower
        end
    end

    -- ESP Players
    local activePlayers = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p==LP then continue end
        activePlayers[p] = true
        local c = p.Character
        if c and isAlive(c) then
            local enemy = isEnemy(p)
            local hasAny = false
            if enemy then
                hasAny = _G.espEnemyBox or _G.espEnemyChams or _G.espEnemyTracers or _G.espEnemySkeleton or _G.espEnemyText
                if hasAny then
                    updateESP(p, c, Color3.fromRGB(255,0,0), _G.espEnemyBox, _G.espEnemyChams, _G.espEnemyTracers, _G.espEnemySkeleton, _G.espEnemyText, "enemy")
                else removeESP(p) end

                -- Hitbox Expander (Player)
                local head = c:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    if _G.safeModeEnabled then head.Size = Vector3.new(2,1,1)
                    else head.Size = Vector3.new(_G.hitboxExpander, _G.hitboxExpander, _G.hitboxExpander) end
                    head.Transparency = 0.5; head.CanCollide = true
                end
            else
                hasAny = _G.espAllyBox or _G.espAllyChams or _G.espAllyTracers or _G.espAllySkeleton or _G.espAllyText
                if hasAny then
                    updateESP(p, c, Color3.fromRGB(0,120,255), _G.espAllyBox, _G.espAllyChams, _G.espAllyTracers, _G.espAllySkeleton, _G.espAllyText, "ally")
                else removeESP(p) end
            end
        else removeESP(p) end
    end
    for key in pairs(espCache) do if typeof(key)~="Instance" then if not activePlayers[key] then removeESP(key) end end end

    -- ESP NPCs
    if _G.espNPCEnabled then
        local npcs = getNPCs()
        local activeNPCs = {}
        for _,npc in pairs(npcs) do
            if isAlive(npc) then
                activeNPCs[npc] = true
                updateESP(npc, npc, Color3.fromRGB(200,0,255), true, true, false, true, true, "npc")
                
                -- Hitbox Expander (NPC)
                local head = npc:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    if _G.safeModeEnabled then head.Size = Vector3.new(2,1,1) -- Default
                    else head.Size = Vector3.new(_G.hitboxExpander, _G.hitboxExpander, _G.hitboxExpander) end
                    head.Transparency = 0.5; head.CanCollide = true
                end
            else
                removeESP(npc)
            end
        end
        for key in pairs(espCache) do
            if typeof(key)=="Instance" and not key:IsA("Player") and not activeNPCs[key] then removeESP(key) end
        end
    end

    -- ═══════════ TARGET SELECTION (Always Active for Aim/Magic) ═══════════
    local aimbotEnabled = _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming)
    local anyAimActive = aimbotEnabled or _G.silentAimEnabled or _G.magicBulletNPC or _G.magicBulletEnemy
    
    if anyAimActive then
        local tgt, model = getClosestTarget()
        currentTarget = tgt; currentTargetModel = model
    else
        currentTarget = nil; currentTargetModel = nil
    end

    -- ═══════════ CAMERA MOVEMENT (Aimbot Only) ═══════════
    if aimbotEnabled and currentTargetModel then
        local tPart = getTargetPart(currentTargetModel)
        if _G.aimbotRandomizeTarget and math.random(1,100) > 70 then
            tPart = currentTargetModel:FindFirstChild("UpperTorso") or currentTargetModel:FindFirstChild("Torso") or tPart
        end
        
        if tPart then
            local aimPos = tPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
            local mousePos = UIS:GetMouseLocation()
            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            
            -- Legit Mode Check: Stickiness
            local canAim = true
            if _G.aimbotLegitMode and distFromCenter > _G.aimbotStickiness then canAim = false end
            
            if canAim then
                if _G.aimPredictionEnabled then
                    local hroot = currentTargetModel:FindFirstChild("HumanoidRootPart")
                    if hroot then
                        local vel = hroot.Velocity
                        local d = (aimPos - Camera.CFrame.Position).Magnitude
                        aimPos = aimPos + vel * (d / 1000)
                    end
                end
                
                local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
                local smoothness = _G.aimbotSmoothness
                
                -- S-Curve Acceleration logic
                if _G.aimbotLegitMode then
                    local weight = math.clamp(1 - (distFromCenter / 100), 0.1, 1)
                    smoothness = smoothness * (1 / weight)
                end
                
                if smoothness > 1 then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1/smoothness)
                else Camera.CFrame = targetCF end
            end
        end
    end

    -- ═══════════ TELEKILL 360 (Experimental) ═══════════
    if _G.telekillPlayerEnabled or _G.telekillNPCEnabled then
        local tkTarget = getClosest3D(_G.telekillNPCEnabled)
        if tkTarget then
            local hroot = tkTarget:FindFirstChild("HumanoidRootPart") or tkTarget:FindFirstChild("Torso")
            if hroot then
                pcall(function()
                    hroot.CFrame = Camera.CFrame * CFrame.new(0, 0, -_G.telekillDistance)
                    hroot.Velocity = Vector3.new(0,0,0)
                end)
            end
        end
    end

    -- ═══════════ ANTI-AIM (Experimental) ═══════════
    if _G.antiAimEnabled and char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        if _G.antiAimMode == "Blatant" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
        elseif _G.antiAimMode == "Legit" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
        end
    end

    -- FOV
    fovCircle.Radius=_G.FOV_RADIUS; fovCircle.Position=center; fovCircle.Visible=_G.FOV_VISIBLE
end)
_G.RunServiceConnection = conn

-- Animation speed hook
local function hookAnims(char)
    if not char then return end
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            animator.AnimationPlayed:Connect(function(track)
                if _G.instantReloadEnabled and track.Animation then
                    local n = track.Animation.Name:lower()
                    if n:find("reload") or n:find("load") or n:find("chamber") then track:AdjustSpeed(10) end
                end
            end)
        end
    end)
end

if LP.Character then task.spawn(function() hookAnims(LP.Character) end) end
LP.CharacterAdded:Connect(function(c) task.wait(0.5); hookAnims(c); lastAppliedTool=nil end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

-- ═══════════ CLEANUP FUNCTION ═══════════
_G.clearDrawings = function()
    for _,d in pairs(allDrawings) do pcall(function() d:Remove() end) end
    allDrawings = {}
    for k in pairs(espCache) do removeESP(k) end
    for _,h in pairs(npcHighlights) do pcall(function() h:Destroy() end) end
    npcHighlights = {}
end

-- ═══════════ HITBOX SELECTOR UI (BONEQUINHO) ═══════════
local function saveBoneco() if writefile then pcall(function() writefile("SupremeHubBoneco.json", HttpService:JSONEncode(_G.HitboxStates)) end) end end
local function loadBoneco() if readfile then pcall(function()
    local d = HttpService:JSONDecode(readfile("SupremeHubBoneco.json"))
    if type(d)=="table" then for k,v in pairs(d) do _G.HitboxStates[k]=v end end
end) end end
loadBoneco()

local bonecoFrame
local function createBonecoInterface()
    local gui = Instance.new("ScreenGui", coreGui); gui.Name="BonequinhoHitboxUI"; gui.ResetOnSpawn=false
    local frame = Instance.new("Frame", gui)
    frame.Size=UDim2.new(0,200,0,280); frame.Position=UDim2.new(0.5,150,0.5,-140)
    frame.BackgroundColor3=Color3.fromRGB(28,28,30); frame.BorderSizePixel=0
    frame.Active=true; frame.Draggable=true; frame.Visible=false
    Instance.new("UICorner", frame).CornerRadius=UDim.new(0,10)
    local title = Instance.new("TextLabel", frame)
    title.Size=UDim2.new(1,0,0,35); title.BackgroundTransparency=1
    title.Text="Hitbox Selector"; title.TextColor3=Color3.new(1,1,1); title.Font=Enum.Font.GothamBold; title.TextSize=16
    local close = Instance.new("TextButton", title)
    close.Size=UDim2.new(0,35,0,35); close.Position=UDim2.new(1,-35,0,0); close.BackgroundTransparency=1
    close.Text="X"; close.TextColor3=Color3.fromRGB(255,60,60); close.Font=Enum.Font.GothamBold; close.TextSize=16
    close.MouseButton1Click:Connect(function() frame.Visible=false end)
    local help = Instance.new("TextLabel", frame)
    help.Size=UDim2.new(1,0,0,42); help.Position=UDim2.new(0,0,1,-45); help.BackgroundTransparency=1
    help.Text="Cinza: Off | Verm: Foco\nAmar: Secundário"; help.TextColor3=Color3.fromRGB(180,180,180); help.Font=Enum.Font.Gotham; help.TextSize=11
    local colors = {[0]=Color3.fromRGB(70,70,70),[1]=Color3.fromRGB(255,60,60),[2]=Color3.fromRGB(255,200,50)}
    local function cP(name,size,pos)
        local btn = Instance.new("TextButton", frame)
        btn.Size=size; btn.Position=pos; btn.BackgroundColor3=colors[_G.HitboxStates[name] or 0]
        btn.Text=""; btn.AutoButtonColor=false; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
        btn.MouseButton1Click:Connect(function()
            _G.HitboxStates[name]=((_G.HitboxStates[name] or 0)+1)%3
            btn.BackgroundColor3=colors[_G.HitboxStates[name]]; saveBoneco()
        end)
    end
    cP("Head",UDim2.new(0,46,0,46),UDim2.new(0,77,0,42))
    cP("Torso",UDim2.new(0,68,0,82),UDim2.new(0,66,0,92))
    cP("Left Arm",UDim2.new(0,28,0,82),UDim2.new(0,34,0,92))
    cP("Right Arm",UDim2.new(0,28,0,82),UDim2.new(0,138,0,92))
    cP("Left Leg",UDim2.new(0,32,0,86),UDim2.new(0,66,0,178))
    cP("Right Leg",UDim2.new(0,32,0,86),UDim2.new(0,102,0,178))
    return frame
end
bonecoFrame = createBonecoInterface()

-- ═══════════ FIND ORION GUI ═══════════
local function findOrionGui()
    for _,c in pairs(coreGui:GetDescendants()) do
        if c:IsA("TextLabel") and (c.Text:find("Supreme Hub") or c.Text:find("Premium")) then
            local p = c:FindFirstAncestorOfClass("ScreenGui")
            if p then return p end
        end
    end
    return nil
end

-- ═══════════ MOBILE BUTTON ═══════════
local function createMobileButton()
    local mg = Instance.new("ScreenGui", coreGui); mg.Name="SupremeMobileHub"; mg.ResetOnSpawn=false
    local btn = Instance.new("TextButton", mg)
    btn.Size=UDim2.new(0,55,0,55); btn.Position=UDim2.new(1,-70,0,100)
    btn.BackgroundColor3=Color3.fromRGB(20,20,20); btn.BorderSizePixel=0
    btn.Text="HUB"; btn.TextColor3=Color3.fromRGB(255,60,60); btn.Font=Enum.Font.GothamBold; btn.TextSize=14
    btn.Active=true; btn.Draggable=true
    Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
    local stroke = Instance.new("UIStroke",btn); stroke.Color=Color3.fromRGB(255,60,60); stroke.Thickness=2
    btn.MouseButton1Click:Connect(function() local o=findOrionGui(); if o then o.Enabled=not o.Enabled end end)
end
if isMobile then createMobileButton() end

-- ═══════════ ORION UI ═══════════
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name="⚡ Supreme Hub | Universal Premium", HidePremium=false, SaveConfig=true, ConfigFolder="SupremeHubConfig", ConfigName="SAutoSave"})
local function zSave() pcall(function() OrionLib:SaveConfig() end) end

-- TAB: COMBAT
local TabCombat = Window:MakeTab({Name="💥 Combat", Icon="rbxassetid://4483345998", PremiumOnly=false})
local SCombat1 = TabCombat:AddSection({Name="🎯 AIMBOT & SILENT AIM"})
SCombat1:AddToggle({Name="Aimbot Automático", Default=_G.aimbotAutoEnabled, Save=true, Flag="AAuto", Callback=function(V) _G.aimbotAutoEnabled=V; if V then _G.silentAimEnabled=false end; zSave() end})
SCombat1:AddToggle({Name="Aimbot Manual (RMB)", Default=_G.aimbotManualEnabled, Save=true, Flag="AMan", Callback=function(V) _G.aimbotManualEnabled=V; zSave() end})
SCombat1:AddToggle({Name="✨ Silent Aim (Original)", Default=_G.silentAimEnabled, Save=true, Flag="SAim", Callback=function(V) _G.silentAimEnabled=V; if V then _G.aimbotAutoEnabled=false end; zSave() end})
SCombat1:AddToggle({Name="🎯 Mouse Spoofing", Default=_G.mouseSpoofEnabled, Save=true, Flag="MSpoof", Callback=function(V) _G.mouseSpoofEnabled=V; zSave() end})

local SCLegit = TabCombat:AddSection({Name="🛡️ SUPREME PRO LEGIT (HUMANIZADO)"})
SCLegit:AddToggle({Name="Ativar Modo LEGIT (PRO Only)", Default=_G.aimbotLegitMode, Save=true, Flag="ALegit", Callback=function(V) _G.aimbotLegitMode=V; zSave() end})
SCLegit:AddSlider({Name="Magnet Stickiness (Raio)", Min=5, Max=100, Default=_G.aimbotStickiness, Color=Color3.fromRGB(0,255,100), Increment=1, ValueName="Pixels", Save=true, Flag="AStick", Callback=function(V) _G.aimbotStickiness=V; zSave() end})
SCLegit:AddLabel("💡 Segue o seu Seletor de Hitbox (Bonequinho).")
SCLegit:AddLabel("💡 Modo LEGIT foca o osso mais próximo que você escolheu.")

local SCRefine = TabCombat:AddSection({Name="⚙️ AIM REFINEMENTS"})
SCRefine:AddButton({Name="👤 Abrir Seletor de Hitbox", Callback=function() if bonecoFrame then bonecoFrame.Visible=not bonecoFrame.Visible end end})
SCRefine:AddToggle({Name="Wall Check (Visão Direta)", Default=_G.wallCheckEnabled, Save=true, Flag="WCheck", Callback=function(V) _G.wallCheckEnabled=V; zSave() end})
SCRefine:AddToggle({Name="Aim Prediction (Movimento)", Default=_G.aimPredictionEnabled, Save=true, Flag="APred", Callback=function(V) _G.aimPredictionEnabled=V; zSave() end})
SCRefine:AddSlider({Name="Smoothness Aimbot", Min=1, Max=50, Default=_G.aimbotSmoothness, Color=Color3.fromRGB(200,200,0), Increment=0.5, ValueName="Lerp", Save=true, Flag="ASmth", Callback=function(V) _G.aimbotSmoothness=V; zSave() end})
SCRefine:AddSlider({Name="Chance Acerto (Silent)", Min=1, Max=100, Default=_G.silentAimHitChance, Color=Color3.fromRGB(200,100,255), Increment=1, ValueName="%", Save=true, Flag="SHit", Callback=function(V) _G.silentAimHitChance=V; zSave() end})

local SCombat4 = TabCombat:AddSection({Name="⭕ FIELD OF VIEW (FOV)"})
SCombat4:AddToggle({Name="Mostrar Círculo FOV", Default=_G.FOV_VISIBLE, Save=true, Flag="FovV", Callback=function(V) _G.FOV_VISIBLE=V; zSave() end})
SCombat4:AddSlider({Name="Tamanho FOV", Min=10, Max=600, Default=_G.FOV_RADIUS, Color=Color3.fromRGB(255,0,0), Increment=5, ValueName="Raio", Save=true, Flag="FovR", Callback=function(V) _G.FOV_RADIUS=V; zSave() end})
SCombat4:AddSlider({Name="Deadzone Legit", Min=5, Max=300, Default=_G.legitDeadzone, Color=Color3.fromRGB(0,200,255), Increment=5, ValueName="Raio", Save=true, Flag="LegitDz", Callback=function(V) _G.legitDeadzone=V; zSave() end})

-- TAB: VISUALS
local TabVis = Window:MakeTab({Name="👁️ Visuals", Icon="rbxassetid://4483362458", PremiumOnly=false})

local SVis1 = TabVis:AddSection({Name="🔦 LIGHTING & ATMOSPHERE"})
SVis1:AddToggle({Name="Fullbright (Tirar Escuridão)", Default=_G.fullbrightEnabled, Save=true, Flag="Frt", Callback=function(V) toggleFullbright(V); zSave() end})
SVis1:AddToggle({Name="No Fog (Limpar Visão)", Default=_G.noFogEnabled, Save=true, Flag="NFog", Callback=function(V) toggleNoFog(V); zSave() end})
SVis1:AddToggle({Name="Sempre Dia (Meio-Dia)", Default=_G.alwaysDayEnabled, Save=true, Flag="ADay", Callback=function(V) toggleAlwaysDay(V); zSave() end})
SVis1:AddSlider({Name="Distância Máxima ESP", Min=50, Max=10000, Default=_G.espMaxDistance, Color=Color3.fromRGB(0,255,100), Increment=50, ValueName="Studs", Save=true, Flag="EspDist", Callback=function(V) _G.espMaxDistance=V; zSave() end})

local SVis2 = TabVis:AddSection({Name="🛰️ RADAR 2D (MODO PINNING)"})
SVis2:AddToggle({Name="Ativar Radar 2D", Default=_G.radarEnabled, Save=true, Flag="RadOn", Callback=function(V) _G.radarEnabled=V; zSave() end})
SVis2:AddToggle({Name="Modo Apenas Pontos (Ghost Mode)", Default=_G.radarDotsOnly, Save=true, Flag="RadGhost", Callback=function(V) _G.radarDotsOnly=V; zSave() end})
SVis2:AddSlider({Name="Zoom do Radar (Escala)", Min=0.05, Max=2, Default=_G.radarScale, Color=Color3.fromRGB(255,255,255), Increment=0.01, ValueName="Zoom", Save=true, Flag="RadScale", Callback=function(V) _G.radarScale=V; zSave() end})
SVis2:AddLabel("💡 Arraste o círculo do radar com o mouse!")
SVis2:AddLabel("💡 'Ghost Mode' serve para alinhar com o mapa do jogo.")

local SVis3 = TabVis:AddSection({Name="🔴 ENEMIES (INIMIGOS)"})
SVis3:AddToggle({Name="Caixa 2D", Default=_G.espEnemyBox, Save=true, Flag="EBox", Callback=function(V) _G.espEnemyBox=V; zSave() end})
SVis3:AddToggle({Name="Aura Colorida (Chams)", Default=_G.espEnemyChams, Save=true, Flag="EChm", Callback=function(V) _G.espEnemyChams=V; zSave() end})
SVis3:AddToggle({Name="Linha (Tracers)", Default=_G.espEnemyTracers, Save=true, Flag="ETrc", Callback=function(V) _G.espEnemyTracers=V; zSave() end})
SVis3:AddToggle({Name="Ossos 3D (Skeleton)", Default=_G.espEnemySkeleton, Save=true, Flag="ESkl", Callback=function(V) _G.espEnemySkeleton=V; zSave() end})
SVis3:AddToggle({Name="Letreiros (Textos)", Default=_G.espEnemyText, Save=true, Flag="ETxt", Callback=function(V) _G.espEnemyText=V; zSave() end})

local SVis4 = TabVis:AddSection({Name="🔵 ALLIES (ALIADOS)"})
SVis4:AddToggle({Name="Caixa 2D", Default=_G.espAllyBox, Save=true, Flag="ABox", Callback=function(V) _G.espAllyBox=V; zSave() end})
SVis4:AddToggle({Name="Aura Colorida (Chams)", Default=_G.espAllyChams, Save=true, Flag="AChm", Callback=function(V) _G.espAllyChams=V; zSave() end})
SVis4:AddToggle({Name="Linha (Tracers)", Default=_G.espAllyTracers, Save=true, Flag="ATrc", Callback=function(V) _G.espAllyTracers=V; zSave() end})
SVis4:AddToggle({Name="Ossos 3D (Skeleton)", Default=_G.espAllySkeleton, Save=true, Flag="ASkl", Callback=function(V) _G.espAllySkeleton=V; zSave() end})
SVis4:AddToggle({Name="Letreiros (Textos)", Default=_G.espAllyText, Save=true, Flag="ATxt", Callback=function(V) _G.espAllyText=V; zSave() end})

local SVis5 = TabVis:AddSection({Name="🟣 NPCs"})
SVis5:AddToggle({Name="ESP NPC", Default=_G.espNPCEnabled, Save=true, Flag="ENPC", Callback=function(V) _G.espNPCEnabled=V; zSave() end})

local SVis6 = TabVis:AddSection({Name="📝 TEXT FILTERS (ESP DATA)"})
SVis6:AddToggle({Name="Mostrar Nome", Default=_G.espName, Save=true, Flag="TxNm", Callback=function(V) _G.espName=V; zSave() end})
SVis6:AddToggle({Name="Mostrar Vida (HP)", Default=_G.espHP, Save=true, Flag="TxHP", Callback=function(V) _G.espHP=V; zSave() end})
SVis6:AddToggle({Name="Mostrar Distância", Default=_G.espDistance, Save=true, Flag="TxDist", Callback=function(V) _G.espDistance=V; zSave() end})
SVis6:AddToggle({Name="Mostrar Arma Atual", Default=_G.espWeapon, Save=true, Flag="TxW", Callback=function(V) _G.espWeapon=V; zSave() end})

-- TAB: WEAPON
local TabWeap = Window:MakeTab({Name="🔫 Weapon", Icon="rbxassetid://4483345998", PremiumOnly=false})
local SWeap1 = TabWeap:AddSection({Name="🛠️ GUN MODS (UNIVERSAL)"})
SWeap1:AddToggle({Name="No Recoil", Default=_G.noRecoilEnabled, Save=true, Flag="NRec", Callback=function(V) _G.noRecoilEnabled=V; zSave() end})
SWeap1:AddToggle({Name="No Spread (Bala Reta)", Default=_G.noSpreadEnabled, Save=true, Flag="NSprd", Callback=function(V) _G.noSpreadEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Infinite Ammo", Default=_G.infiniteAmmoEnabled, Save=true, Flag="IAmm", Callback=function(V) _G.infiniteAmmoEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Fast Reload", Default=_G.instantReloadEnabled, Save=true, Flag="IRel", Callback=function(V) _G.instantReloadEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Rapid Fire (Auto Bullet)", Default=_G.rapidFireEnabled, Save=true, Flag="RFire", Callback=function(V) _G.rapidFireEnabled=V; zSave() end})

local SWeap2 = TabWeap:AddSection({Name="💀 HITBOX EXPANDER (🔴 ALTO RISCO)"})
SWeap2:AddSlider({Name="Aumentar Cabeça (Tamanho)", Min=2, Max=15, Default=_G.hitboxExpander, Color=Color3.fromRGB(150,0,255), Increment=1, ValueName="Scale", Save=true, Flag="HEx", Callback=function(V) 
    if _G.safeModeEnabled and V > 2 then OrionLib:MakeNotification({Name="Aviso", Content="Safe Mode ativado! Hitbox bloqueada.", Time=2}); return end
    _G.hitboxExpander=V; zSave() 
end})
SWeap2:AddLabel("⚠️ CAUSA #1 DE BANS: Use com moderação!")

-- TAB: PLAYER
local TabPlayer = Window:MakeTab({Name="👟 Player", Icon="rbxassetid://4483345998", PremiumOnly=false})
local SPlay1 = TabPlayer:AddSection({Name="🏃 MOVEMENT & SPEED"})
SPlay1:AddSlider({Name="WalkSpeed", Min=16, Max=250, Default=_G.walkSpeed, Color=Color3.fromRGB(200,200,200), Increment=1, ValueName="W", Save=true, Flag="PWS", Callback=function(V) _G.walkSpeed=V; zSave() end})
SPlay1:AddSlider({Name="JumpPower", Min=50, Max=300, Default=_G.jumpPower, Color=Color3.fromRGB(200,200,200), Increment=1, ValueName="P", Save=true, Flag="PJP", Callback=function(V) _G.jumpPower=V; zSave() end})

-- TAB: EXPERIMENTAL
local TabExp = Window:MakeTab({Name="🧪 Experimental", Icon="rbxassetid://4483345998", PremiumOnly=false})
local SExp0 = TabExp:AddSection({Name="🛡️ STEALTH & SAFETY"})
SExp0:AddToggle({Name="Anti-Detecção (Property Spoof)", Default=_G.stealthModeEnabled, Save=true, Flag="Stlth", Callback=function(V) _G.stealthModeEnabled=V; zSave() end})
SExp0:AddToggle({Name="Safe Mode (Bloquear Risco)", Default=_G.safeModeEnabled, Save=true, Flag="SafeM", Callback=function(V) 
    _G.safeModeEnabled=V
    if V then _G.telekillPlayerEnabled=false; _G.telekillNPCEnabled=false; _G.hitboxExpander=2 end
    zSave() 
end})

local SExp1 = TabExp:AddSection({Name="🚀 360 TELEKILL (🔴 ALTO RISCO)"})
SExp1:AddToggle({Name="Telekill Players (360°)", Default=_G.telekillPlayerEnabled, Save=true, Flag="TKP", Callback=function(V) 
    if _G.safeModeEnabled and V then OrionLib:MakeNotification({Name="Aviso", Content="Safe Mode ativado! Desative para usar Telekill.", Time=2}); return end
    _G.telekillPlayerEnabled=V; if V then _G.telekillNPCEnabled=false end; zSave() 
end})
SExp1:AddToggle({Name="Telekill NPCs (360°)", Default=_G.telekillNPCEnabled, Save=true, Flag="TKN", Callback=function(V) 
    if _G.safeModeEnabled and V then OrionLib:MakeNotification({Name="Aviso", Content="Safe Mode ativado! Desative para usar Telekill.", Time=2}); return end
    _G.telekillNPCEnabled=V; if V then _G.telekillPlayerEnabled=false end; zSave() 
end})
SExp1:AddSlider({Name="Distância do Telekill", Min=2, Max=20, Default=_G.telekillDistance, Color=Color3.fromRGB(255,150,0), Increment=0.5, ValueName="Studs", Save=true, Flag="TKDist", Callback=function(V) _G.telekillDistance=V; zSave() end})

local SExp2 = TabExp:AddSection({Name="🌀 ANTI-AIM / SPINBOT (PRO)"})
SExp2:AddToggle({Name="Ativar Anti-Aim", Default=_G.antiAimEnabled, Save=true, Flag="AAOn", Callback=function(V) _G.antiAimEnabled=V; zSave() end})
SExp2:AddDropdown({Name="Modo Anti-Aim", Default=_G.antiAimMode or "Legit", Options={"Legit", "Blatant"}, Save=true, Flag="AAMode", Callback=function(V) _G.antiAimMode=V; zSave() end})
SExp2:AddLabel("💡 Legit AA faz você desviar de balas sem girar.")

local SExp3 = TabExp:AddSection({Name="⚙️ OTHERS (🟡 MÉDIO RISCO)"})
SExp3:AddToggle({Name="Mouse Spoofing (Silent Aim Helper)", Default=_G.mouseSpoofEnabled, Save=true, Flag="MSpoof", Callback=function(V) _G.mouseSpoofEnabled=V; zSave() end})
SExp3:AddLabel("⚠️ Telekill e Hitbox Expander dão ban facilmente.")
local TabCfg = Window:MakeTab({Name="⚙️ Config", Icon="rbxassetid://4483345998", PremiumOnly=false})

local SCfgTheme = TabCfg:AddSection({Name="🎨 CUSTOMIZAÇÃO VISUAL"})
SCfgTheme:AddDropdown({Name="Tema da Interface", Default=_G.selectedTheme or "Default", Options={"Default", "Matrix", "Cyberpunk", "WatchDogs", "Yellow", "Neon RGB"}, Save=true, Flag="STheme", Callback=function(V) applyTheme(V); zSave() end})

local SCfg1 = TabCfg:AddSection({Name="🛡️ INTERFACE & SISTEMA"})
if not isMobile then
    SCfg1:AddBind({Name="⌨️ Tecla do Menu (Abrir/Fechar)", Default=Enum.KeyCode.Home, Hold=false, Callback=function() local o=findOrionGui(); if o then o.Enabled=not o.Enabled end end})
else
    SCfg1:AddButton({Name="🔴 Botão HUB criado na tela", Callback=function() end})
end
SCfg1:AddButton({Name="💾 FORÇAR SALVAMENTO", Callback=function() zSave(); OrionLib:MakeNotification({Name="Supreme Hub", Content="Configurações salvas!", Image="rbxassetid://4483345998", Time=3}) end})
SCfg1:AddToggle({Name="🕵️ Streamproof (Anti-OBS)", Default=_G.streamproofEnabled, Save=true, Flag="StPrf", Callback=function(V) 
    _G.streamproofEnabled=V
    local o = findOrionGui()
    if o then o.DisplayOrder = V and 0 or 100 end
    for _,d in pairs(allDrawings) do d.Visible = not V end
    zSave() 
end})

local SCfg2 = TabCfg:AddSection({Name="🛑 EMERGÊNCIA & SEGURANÇA"})
SCfg2:AddButton({Name="🔄 Server Hopper (Low Pop)", Callback=function() teleportToLowPopServer() end})
SCfg2:AddBind({Name="🛑 BOTÃO DE PÂNICO (Destruir Tudo)", Default=Enum.KeyCode.End, Hold=false, Callback=function()
    _G.SupremeHubRunning = false
    pcall(function() conn:Disconnect() end)
    pcall(function() _G.clearDrawings() end)
    if bonecoFrame then pcall(function() bonecoFrame.Parent:Destroy() end) end
    pcall(function() if coreGui:FindFirstChild("SupremeMobileHub") then coreGui.SupremeMobileHub:Destroy() end end)
    pcall(function() OrionLib:Destroy() end)
    OrionLib:MakeNotification({Name="Supreme Hub", Content="Script encerrado com sucesso!", Time=5})
end})
SCfg2:AddButton({Name="Reinstalar Menu (Reset)", Callback=function() pcall(function() OrionLib:Destroy() end); task.wait(0.5); loadstring(game:HttpGet("https://raw.githubusercontent.com/ExiT/SupremeHub/main/aimnpc.lua"))() end})

pcall(function() applyTheme(_G.selectedTheme or "Default") end)
OrionLib:Init()
print("⚡ Supreme Hub Loaded | All Systems Active")
