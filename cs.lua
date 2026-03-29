-- ⚡ SUPREME HUB | UNIVERSAL PREMIUM
-- Cleanup
pcall(function() for _,g in pairs(game:GetService("CoreGui"):GetChildren()) do if g.Name=="BonequinhoHitboxUI" or g.Name=="SupremeMobileHub" then g:Destroy() end end end)
for _,o in pairs(workspace:GetDescendants()) do if o:IsA("Highlight") then pcall(function() o:Destroy() end) end end

-- Cleanup Drawings from previous runs
if _G.SupremeHubDrawings then
    for _, d in pairs(_G.SupremeHubDrawings) do pcall(function() d:Remove() end) end
end
_G.SupremeHubDrawings = {}
local allDrawings = _G.SupremeHubDrawings

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local coreGui = game:GetService("CoreGui")
local lighting = game:GetService("Lighting")
local TPS = game:GetService("TeleportService")

-- Localization
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local WorldToViewportPoint = Camera.WorldToViewportPoint
local Vector2new, Vector3new, CFnew = Vector2.new, Vector3.new, CFrame.new
local mathfloor, mathclamp, mathabs, mathrad, mathrandom = math.floor, math.clamp, math.abs, math.rad, math.random
local tick, pairs, ipairs, pcall = tick, pairs, ipairs, pcall

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
_G.SupremeHubRunning = true

-- ═══════════ FLAGS GLOBAIS ═══════════
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotManualEnabled = _G.aimbotManualEnabled or false
_G.aimbotLegitMode = false
_G.aimbotSmoothness = 1
_G.aimbotStickiness = 10
_G.aimbotRandomizeTarget = false
_G.silentAimEnabled = _G.silentAimEnabled or false
_G.wallCheckEnabled = true
_G.aimPredictionEnabled = false
_G.silentAimHitChance = 100
_G.FOV_RADIUS = _G.FOV_RADIUS or 65
_G.FOV_VISIBLE = true
_G.espNPCEnabled = false
_G.mouseSpoofEnabled = false
_G.telekillPlayerEnabled = false
_G.telekillNPCEnabled = _G.telekillNPCEnabled or false
_G.telekillDistance = 5
_G.stealthModeEnabled = true
_G.safeModeEnabled = _G.safeModeEnabled or false
_G.radarEnabled = _G.radarEnabled or false
_G.radarScale = 0.5
_G.radarDotsOnly = false
_G.radarPos = Vector2.new(200, 200)
_G.hitboxExpanderActive = _G.hitboxExpanderActive or false
_G.espEnabled = _G.espEnabled or false
_G.legitDeadzone = 7 -- Valor interno fixo para stealth
_G.aimbotStickiness = 400
_G.espColor = Color3.fromRGB(255, 0, 0)
_G.fullbrightEnabled = _G.fullbrightEnabled or false
_G.noFogEnabled = false
_G.alwaysDayEnabled = false
_G.streamproofEnabled = false
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

-- ═══════════ NPC DETECTION (AGGRESSIVE & SMART) ═══════════
local ENEMY_KW = {"zombie","zumbi","infected","enemy","monster","mutant","soldier","mob","ghoul","undead","skeleton","elite","boss","beast"}
local FRIENDLY_KW = {"quest","shop","store","trader","merchant","guide","interaction","doctor","banker","scavenger","safezone","vendedor","comprar"}

local isZombieGame = false

local function isLikelyHostile(obj)
    local n = obj.Name:lower()
    for _, k in pairs(FRIENDLY_KW) do if n:find(k) then return false end end
    
    -- Specific Exclusions: Only exclude interaction prompts IF they are clearly for commerce/quests
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then 
        local pn = prompt.ObjectText:lower()..prompt.ActionText:lower()
        for _, k in pairs(FRIENDLY_KW) do if pn:find(k) then return false end end
    end
    
    -- Se for um jogo de zumbis, priorizamos zumbis mas não ignoramos outros se não forem "friendly"
    if isZombieGame then
        for _, k in pairs(ENEMY_KW) do if n:find(k) then return true end end
        -- Se não tiver keyword de inimigo mas também não for friendly, em jogo de zumbi, checamos se tem humanoid
        local hum = obj:FindFirstChildOfClass("Humanoid")
        return hum ~= nil
    end
    
    return true
end

local cachedNPCs, lastNPCScan = {}, 0
local function getNPCs()
    if tick() - lastNPCScan < 2 then return cachedNPCs end
    lastNPCScan = tick()
    
    local npcs = {}
    local playerChars = {}
    for _,p in pairs(Players:GetPlayers()) do if p.Character then playerChars[p.Character]=true end end
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position
    
    isZombieGame = false
    
    local function scan(parent, depth)
        if depth > 4 then return end
        local children = parent:GetChildren()
        for _, o in pairs(children) do
            if #npcs >= 50 then break end
            
            if o:IsA("Model") and o ~= LP.Character and not playerChars[o] then
                local hum = o:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local n = o.Name:lower()
                    -- Identifica se é jogo de zumbi por qualquer entidade ou pasta
                    for _, k in pairs(ENEMY_KW) do if n:find(k) then isZombieGame = true; break end end
                    
                    if isLikelyHostile(o) then
                        local root = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Head") or o.PrimaryPart
                        if root then
                            if myPos then
                                if (root.Position - myPos).Magnitude <= _G.espMaxDistance then
                                    table.insert(npcs, o)
                                end
                            else table.insert(npcs, o) end
                        end
                    end
                elseif depth < 4 then scan(o, depth + 1) end -- Scan inside models for humanoids (some games nest them)
            elseif o:IsA("Folder") and depth < 4 then
                local n = o.Name:lower()
                -- Sempre scan folders a menos que sejam explicitamente "Map" ou "Static"
                if not n:find("map") and not n:find("static") and not n:find("environment") then
                    if n:find("zombie") or n:find("enemy") then isZombieGame = true end
                    scan(o, depth + 1)
                end
            end
        end
    end
    
    scan(workspace, 0)
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

-- ═══════════ ESP DRAWING SYSTEM ═══════════
local function regDraw(d)
    table.insert(allDrawings, d)
    pcall(function() d.StreamProof = _G.streamproofEnabled or false end)
    return d
end

-- ═══════════ FOV CIRCLE ═══════════
local fovCircle = regDraw(Drawing.new("Circle"))
fovCircle.Transparency=0.2; fovCircle.Thickness=1.5; fovCircle.Filled=false; fovCircle.Color=Color3.new(1,1,1)
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
    -- Hacker Style Text Labels (Separate & Throttled)
    e.txName = regDraw(Drawing.new("Text")); e.txName.Size=14; e.txName.Outline=true; e.txName.Font=3; e.txName.Visible=false
    e.txHP = regDraw(Drawing.new("Text")); e.txHP.Size=13; e.txHP.Outline=true; e.txHP.Font=3; e.txHP.Visible=false
    e.txDist = regDraw(Drawing.new("Text")); e.txDist.Size=13; e.txDist.Outline=true; e.txDist.Font=3; e.txDist.Visible=false; e.txDist.Color=Color3.fromRGB(180,180,180)
    e.txWeapon = regDraw(Drawing.new("Text")); e.txWeapon.Size=13; e.txWeapon.Outline=true; e.txWeapon.Font=3; e.txWeapon.Visible=false; e.txWeapon.Color=Color3.fromRGB(255,165,0)
    -- Skeleton
    e.skel = {}
    for i=1,14 do e.skel[i]=regDraw(Drawing.new("Line")); e.skel[i].Thickness=1; e.skel[i].Transparency=0.5; e.skel[i].Visible=false end
    return e
end

local function hideESP(e)
    if not e then return end
    for i=1,8 do e.corners[i].Visible=false end
    e.hpBar.Visible=false; e.hpBarBG.Visible=false; e.tracer.Visible=false
    e.txName.Visible=false; e.txHP.Visible=false; e.txDist.Visible=false; e.txWeapon.Visible=false
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
    local boxH = mathabs(botSP.Y - topSP.Y)
    local boxW = boxH * 0.6
    local boxX = centerX - boxW / 2
    local boxY = topSP.Y
    
    local isTarget = (key == currentTarget or char == currentTargetModel)
    local mainColor = isTarget and Color3.new(1,1,0) or color

    if showBox then
        local lineLen = boxW / 4
        local c = e.corners
        local bX, bY, bW, bH = boxX, boxY, boxW, boxH
        c[1].From = Vector2new(bX, bY); c[1].To = Vector2new(bX + lineLen, bY)
        c[2].From = Vector2new(bX, bY); c[2].To = Vector2new(bX, bY + lineLen)
        c[3].From = Vector2new(bX + bW, bY); c[3].To = Vector2new(bX + bW - lineLen, bY)
        c[4].From = Vector2new(bX + bW, bY); c[4].To = Vector2new(bX + bW, bY + lineLen)
        c[5].From = Vector2new(bX, bY + bH); c[5].To = Vector2new(bX + lineLen, bY + bH)
        c[6].From = Vector2new(bX, bY + bH); c[6].To = Vector2new(bX, bY + bH - lineLen)
        c[7].From = Vector2new(bX + bW, bH + bY); c[7].To = Vector2new(bX + bW - lineLen, bH + bY)
        c[8].From = Vector2new(bX + bW, bH + bY); c[8].To = Vector2new(bX + bW, bH + bY - lineLen)
        for i=1,8 do c[i].Color=mainColor; c[i].Visible=true end
    else for i=1,8 do e.corners[i].Visible=false end end

    if showBox or showText then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local pct = mathclamp(hum.Health / hum.MaxHealth, 0, 1)
            local barX = boxX - 5
            e.hpBarBG.From=Vector2new(barX, boxY); e.hpBarBG.To=Vector2new(barX, boxY+boxH); e.hpBarBG.Visible=true
            e.hpBar.From=Vector2new(barX, boxY+boxH-(boxH*pct)); e.hpBar.To=Vector2new(barX, boxY+boxH)
            e.hpBar.Color=hpColor(pct); e.hpBar.Visible=true
        else e.hpBar.Visible=false; e.hpBarBG.Visible=false end
    else e.hpBar.Visible=false; e.hpBarBG.Visible=false end

    if showChams then
        if not e.chams or e.chams.Parent ~= char then
            if e.chams then pcall(function() e.chams:Destroy() end) end
            e.chams = Instance.new("Highlight"); e.chams.Parent = char
        end
        e.chams.Adornee=char; e.chams.Enabled=true; e.chams.FillColor=mainColor; e.chams.OutlineColor=Color3.new(1,1,1)
        e.chams.FillTransparency=1; e.chams.OutlineTransparency=0
    elseif e.chams then pcall(function() e.chams:Destroy() end); e.chams=nil end

    if showTracers then
        e.tracer.From=Vector2new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); e.tracer.To=Vector2new(centerX, botSP.Y); e.tracer.Color=mainColor; e.tracer.Visible=true
    else e.tracer.Visible=false end

    if showSkel then
        local bones = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
        for i, pair in ipairs(bones) do
            local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
            if p1 and p2 and e.skel[i] then
                local s1,v1 = WorldToViewportPoint(Camera, p1.Position); local s2,v2 = WorldToViewportPoint(Camera, p2.Position)
                if v1 and v2 then e.skel[i].From=Vector2new(s1.X,s1.Y); e.skel[i].To=Vector2new(s2.X,s2.Y); e.skel[i].Color=mainColor; e.skel[i].Visible=true
                else e.skel[i].Visible=false end
            elseif e.skel[i] then e.skel[i].Visible=false end
        end
        for i=#bones+1, 14 do if e.skel[i] then e.skel[i].Visible=false end end
    else for i=1,14 do e.skel[i].Visible=false end end

    if showText then
        if tick() - e.lastTextUpdate > 0.25 then
            e.lastTextUpdate = tick()
            local nm = (typeof(key)=="Instance" and key:IsA("Player")) and (key.DisplayName or key.Name) or (char.Name or "NPC")
            e.txName.Text = nm; e.txName.Color = (isTarget and Color3.new(1,1,0) or Color3.new(1,1,1))
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then e.txHP.Text = "HP: "..mathfloor(hum.Health); e.txHP.Color = hpColor(hum.Health/hum.MaxHealth) end
            e.txDist.Text = mathfloor(dist3D).."m"
            local tool = char:FindFirstChildWhichIsA("Tool")
            e.txWeapon.Text = tool and tool.Name or "Hands"
        end
        local curY = boxY
        if _G.espName then e.txName.Position=Vector2new(boxX+boxW+4, curY); e.txName.Visible=true; curY=curY+14 else e.txName.Visible=false end
        if _G.espHP then e.txHP.Position=Vector2new(boxX+boxW+4, curY); e.txHP.Visible=true; curY=curY+13 else e.txHP.Visible=false end
        if _G.espDistance then e.txDist.Position=Vector2new(boxX+boxW+4, curY); e.txDist.Visible=true; curY=curY+13 else e.txDist.Visible=false end
        if _G.espWeapon then e.txWeapon.Position=Vector2new(boxX+boxW+4, curY); e.txWeapon.Visible=true end
    else e.txName.Visible=false; e.txHP.Visible=false; e.txDist.Visible=false; e.txWeapon.Visible=false end
end

-- ═══════════ TARGETING ═══════════
local function getClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestModel, bestDist = nil, nil, _G.FOV_RADIUS
    
    -- Targets: Players & NPCs
    for _,p in pairs(Players:GetPlayers()) do
        if p==LP or not p.Character or not isAlive(p.Character) or not isEnemy(p) then continue end
        local part = getTargetPart(p.Character)
        if part then
            local sp, vis = Camera:WorldToViewportPoint(part.Position)
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if vis and d <= bestDist and hasLOS(part) then bestDist = d; best = p; bestModel = p.Character end
        end
    end
    
    if _G.espNPCEnabled or _G.silentAimEnabled or _G.telekillNPCEnabled then
        local npcs = getNPCs()
        -- Prioridade: Se houver Zumbis/Inimigos, foca apenas neles primeiro
        local hostiles = {}
        for _, n in pairs(npcs) do
            local ln = n.Name:lower()
            local isH = false
            for _, k in pairs(ENEMY_KW) do if ln:find(k) then isH = true; break end end
            if isH then table.insert(hostiles, n) end
        end
        
        local targetsToScan = #hostiles > 0 and hostiles or npcs
        for _,npc in pairs(targetsToScan) do
            if not isAlive(npc) then continue end
            local part = getTargetPart(npc)
            if part then
                local sp, vis = Camera:WorldToViewportPoint(part.Position)
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if vis and d <= bestDist and hasLOS(part) then bestDist = d; best = npc; bestModel = npc end
            end
        end
    end
    return best, bestModel
end

local function getClosest3D(npcOnly)
    local center = (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")) and LP.Character.HumanoidRootPart.Position or Camera.CFrame.Position
    local best, bestDist = nil, 1000
    if npcOnly then
        local npcs = getNPCs()
        local hostiles = {}
        for _, n in pairs(npcs) do
            local ln = n.Name:lower()
            local isH = false
            for _, k in pairs(ENEMY_KW) do if ln:find(k) then isH = true; break end end
            if isH then table.insert(hostiles, n) end
        end
        
        local targetsToScan = #hostiles > 0 and hostiles or npcs
        for _,npc in pairs(targetsToScan) do
            if isAlive(npc) then
                local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChild("Head")
                if root then
                    local d = (root.Position - center).Magnitude
                    if d < bestDist then bestDist = d; best = npc end
                end
            end
        end
    else
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and isAlive(p.Character) and isEnemy(p) then
                local hroot = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
                if hroot then
                    local d = (hroot.Position - center).Magnitude
                    if d < bestDist then bestDist = d; best = p.Character end
                end
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

local function teleportToLowPopServer()
    local Http = game:GetService("HttpService")
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local s, r = pcall(function() 
            local highlight = target:FindFirstChild("SupremeHighlight") or Instance.new("Highlight")
            highlight.Name = "SupremeHighlight"
            highlight.Parent = target
            highlight.FillColor = _G.espColor
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 1 -- Silhouette Mode (Apenas Contorno)
            highlight.OutlineTransparency = 0
            highlight.Enabled = _G.espEnabled and not visible
    return Http:JSONDecode(game:HttpGet(Api)) end)
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
local radarCircle = regDraw(Drawing.new("Circle"))
radarCircle.Thickness = 2; radarCircle.NumSides = 60; radarCircle.Radius = 75; radarCircle.Filled = false; radarCircle.Color = Color3.fromRGB(255,255,255); radarCircle.Visible = false
local radarCenter = regDraw(Drawing.new("Circle"))
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

-- ═══════════ RADAR DOT POOL (ULTRA-LEVE) ═══════════
local radarPool = {}
for i=1,50 do
    local d = regDraw(Drawing.new("Circle")); d.Radius=3.5; d.Filled=true; d.Visible=false
    table.insert(radarPool, d)
end

local function updateRadar()
    if not _G.radarEnabled then
        radarCircle.Visible = false; radarCenter.Visible = false
        for _,d in pairs(radarPool) do d.Visible=false end; return
    end
    
    local isVisible = _G.SupremeHubRunning
    radarCircle.Position = _G.radarPos; radarCircle.Visible = not _G.radarDotsOnly and isVisible; radarCircle.Transparency = 0.5
    radarCenter.Position = _G.radarPos; radarCenter.Visible = not _G.radarDotsOnly and isVisible

    local dotIndex = 1
    local function drawDot(targetPos, color)
        if dotIndex > 50 then return end
        -- Converte a posição do mundo para o espaço local da câmera (Relativo ao jogador)
        local rel = Camera.CFrame:PointToObjectSpace(targetPos)
        -- rel.X é Direita(+)/Esquerda(-), rel.Z é Atrás(+)/Frente(-)
        -- No radar: Cima é Frente (-Z), Direita é (+X)
        local rPos = Vector2.new(rel.X, rel.Z)
        
        -- Calcula a posição final baseada no zoom e posição central
        local finalPos = _G.radarPos + Vector2.new(rPos.X, rPos.Y) * _G.radarScale
        
        -- Só mostra se estiver dentro do círculo do radar (75px) ou de qualquer forma se Ghost Mode ativado
        if (finalPos - _G.radarPos).Magnitude < 75 or _G.radarDotsOnly then
            local d = radarPool[dotIndex]
            if d then
                d.Color = color
                d.Position = finalPos
                d.Visible = _G.SupremeHubRunning
                dotIndex = dotIndex + 1
            end
        end
    end

    for _,d in pairs(radarPool) do d.Visible=false end
    
    -- Inimigos (Vermelho)
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) and isEnemy(p) then 
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            if root then drawDot(root.Position, Color3.fromRGB(255,0,0)) end
        end
    end
    
    -- NPCs (Roxo)
    for _,npc in pairs(getNPCs()) do 
        if isAlive(npc) then 
            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if root then drawDot(root.Position, Color3.fromRGB(200,0,255)) end 
        end 
    end
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
            if _G.silentAimEnabled and currentTargetModel then
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
        
        if _G.silentAimEnabled and currentTargetModel then
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

    -- Optimized Entity ESP & Hitbox Expander
    local entities = {}
    for _,p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(entities, {p, p.Character, isEnemy(p) and "enemy" or "ally"}) end end
    if _G.espNPCEnabled or _G.silentAimEnabled then for _,n in pairs(getNPCs()) do table.insert(entities, {n, n, "npc"}) end end
    
    local activeHashes = {}
    for _, data in ipairs(entities) do
        local key, char, etype = data[1], data[2], data[3]
        if char and isAlive(char) then
            activeHashes[key] = true
            local head = char:FindFirstChild("Head")
            
            -- Hitbox Expander Otimizado
                if _G.hitboxExpanderActive and head then
                    local targetSize = Vector3.new(7, 7, 7)
                    if head.Size ~= targetSize then
                        head.Size = targetSize
                        head.Transparency = 0.7
                        head.CanCollide = false
                    end
                elseif head and head.Size ~= Vector3.new(2, 2, 2) then
                    head.Size = Vector3.new(2, 2, 2)
                    head.Transparency = 0
                end
            
            local color = (etype == "enemy" and Color3.fromRGB(255,0,0)) or (etype == "ally" and Color3.fromRGB(0,120,255)) or Color3.fromRGB(200,0,255)
            local showBox, showChams, showTracers, showSkel, showText = false, false, false, false, false
            
            if etype == "enemy" then
                showBox, showChams, showTracers, showSkel, showText = _G.espEnemyBox, _G.espEnemyChams, _G.espEnemyTracers, _G.espEnemySkeleton, _G.espEnemyText
            elseif etype == "ally" then
                showBox, showChams, showTracers, showSkel, showText = _G.espAllyBox, _G.espAllyChams, _G.espAllyTracers, _G.espAllySkeleton, _G.espAllyText
            else -- NPC
                showBox, showChams, showTracers, showSkel, showText = true, true, false, true, true
            end
            
            if showBox or showChams or showTracers or showSkel or showText then
                updateESP(key, char, color, showBox, showChams, showTracers, showSkel, showText, etype)
            else removeESP(key) end
        end
    end
    for k in pairs(espCache) do if not activeHashes[k] then removeESP(k) end end

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

    -- Radar & FOV
    if _G.radarEnabled then pcall(function() updateRadar() end) else 
        radarCircle.Visible = false; radarCenter.Visible = false
        for _,d in pairs(radarPool) do d.Visible = false end
    end
    
    fovCircle.Radius=_G.FOV_RADIUS; fovCircle.Position=center
    fovCircle.Visible = _G.FOV_VISIBLE and _G.SupremeHubRunning
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

local SCLegit = TabCombat:AddSection({Name="🛡️ PRO LEGIT (HUMANIZADO)"})
SCLegit:AddToggle({Name="Ativar Modo Aim LEGIT", Default=_G.aimbotLegitMode, Save=true, Flag="ALegit", Callback=function(V) _G.aimbotLegitMode=V; zSave() end})
SCLegit:AddSlider({Name="Magnet Stickiness (Raio)", Min=5, Max=100, Default=_G.aimbotStickiness, Color=Color3.fromRGB(0,255,100), Increment=1, ValueName="Pixels", Save=true, Flag="AStick", Callback=function(V) _G.aimbotStickiness=V; zSave() end})
SCLegit:AddLabel("💡 Segue o seu Seletor de Hitbox.")
SCLegit:AddLabel("💡 Modo LEGIT foca a parte do corpo mais próximo que você escolheu.")

local SCRefine = TabCombat:AddSection({Name="⚙️ AIM REFINEMENTS"})
SCRefine:AddButton({Name="👤 Abrir Seletor de Hitbox", Callback=function() if bonecoFrame then bonecoFrame.Visible=not bonecoFrame.Visible end end})
SCRefine:AddToggle({Name="Wall Check (Visão Direta)", Default=_G.wallCheckEnabled, Save=true, Flag="WCheck", Callback=function(V) _G.wallCheckEnabled=V; zSave() end})
SCRefine:AddToggle({Name="Aim Prediction (Movimento)", Default=_G.aimPredictionEnabled, Save=true, Flag="APred", Callback=function(V) _G.aimbotSmoothness=V; zSave() end})
local SComb = TabCombat:AddSection({Name="Ajustes Focados em Stealth (Indetectável)"})
SComb:AddSlider({Name="Aimbot Distância (FOV)", Min=50, Max=800, Default=_G.aimbotStickiness, Color=Color3.fromRGB(255,100,0), Increment=10, ValueName="PX", Save=true, Flag="AimS", Callback=function(V) _G.aimbotStickiness=V; zSave() end})
SComb:AddParagraph("Nota:","A Zona Morta (Deadzone) foi fixada em 7px para garantir uma mira humana.")

local SCombat4 = TabCombat:AddSection({Name="⭕ FIELD OF VIEW (FOV)"})
SCombat4:AddToggle({Name="Mostrar Círculo FOV", Default=_G.FOV_VISIBLE, Save=true, Flag="FovV", Callback=function(V) _G.FOV_VISIBLE=V; zSave() end})
SCombat4:AddSlider({Name="Tamanho FOV", Min=10, Max=600, Default=_G.FOV_RADIUS, Color=Color3.fromRGB(255,0,0), Increment=5, ValueName="Raio", Save=true, Flag="FovR", Callback=function(V) _G.FOV_RADIUS=V; zSave() end})

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
local SWeap2 = TabWeap:AddSection({Name="💀 HITBOX EXPANDER (🔴 ALTO RISCO)"})
SWeap2:AddToggle({Name="Ativar Cabeção (Tamanho Otimizado)", Default=false, Callback=function(V) 
    if _G.safeModeEnabled and V then 
        OrionLib:MakeNotification({Name="Aviso", Content="Safe Mode ativado! Hitbox bloqueada.", Time=2})
        return 
    end
    _G.hitboxExpanderActive = V 
end})
SWeap2:AddLabel("⚠️ CAUSA #1 DE BANS: Use com moderação!")
local SWeap1 = TabWeap:AddSection({Name="🛠️ GUN MODS (UNIVERSAL)"})
SWeap1:AddToggle({Name="No Recoil", Default=_G.noRecoilEnabled, Save=true, Flag="NRec", Callback=function(V) _G.noRecoilEnabled=V; zSave() end})
SWeap1:AddToggle({Name="No Spread (Bala Reta)", Default=_G.noSpreadEnabled, Save=true, Flag="NSprd", Callback=function(V) _G.noSpreadEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Infinite Ammo", Default=_G.infiniteAmmoEnabled, Save=true, Flag="IAmm", Callback=function(V) _G.infiniteAmmoEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Fast Reload", Default=_G.instantReloadEnabled, Save=true, Flag="IRel", Callback=function(V) _G.instantReloadEnabled=V; zSave() end})
SWeap1:AddToggle({Name="Rapid Fire (Auto Bullet)", Default=_G.rapidFireEnabled, Save=true, Flag="RFire", Callback=function(V) _G.rapidFireEnabled=V; zSave() end})

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

local SSystem = TabCfg:AddSection({Name="🛡️ SISTEMA & UTILITÁRIOS"})
if not isMobile then
    SSystem:AddBind({Name="Tecla do Menu", Default=Enum.KeyCode.Home, Hold=false, Callback=function() local o=findOrionGui(); if o then o.Enabled=not o.Enabled end end})
end
SSystem:AddButton({Name="💾 SALVAR TUDO AGORA", Callback=function() zSave() end})
SSystem:AddButton({Name="🔄 Server Hopper (Low Pop)", Callback=function() teleportToLowPopServer() end})

local function Panic()
    _G.aimbot = false
    _G.silentAimEnabled = false
    _G.espEnabled = false
    _G.hitboxExpanderActive = false
    
    -- Silent cleanup of ESP highlights
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("SupremeHighlight")
            if h then h:Destroy() end
        end
    end

    -- Clear all logic connections
    pcall(function() if _G.RunServiceConnection then _G.RunServiceConnection:Disconnect() end end)
    pcall(function() _G.clearDrawings() end)
    if bonecoFrame then pcall(function() bonecoFrame.Parent:Destroy() end) end

    -- Destroy UI silently
    if OrionLib then
        OrionLib:Destroy()
    end
    
    -- Stealth Console Wipe (Sem avisos no log)
    pcall(function() 
        if rconsoleclear then rconsoleclear() end
        if printconsole then printconsole("", "clear") end
    end)
    
    -- Cleanup global vars
    for k,v in pairs(_G) do 
        if k:find("Supreme") or k:find("aimbot") or k:find("esp") or k:find("radar") or k:find("FOV") or k:find("silent") then 
            _G[k] = nil 
        end 
    end

    -- Stop script
    script:Destroy()
end

local SPanic = TabCfg:AddSection({Name="🛑 EMERGÊNCIA"})
SPanic:AddBind({Name="🛑 TECLA DE PÂNICO (Encerrar)", Default=Enum.KeyCode.End, Hold=false, Callback=function()
    Panic()
end})

SPanic:AddButton({Name="🛑 CLIQUE PARA ENCERRAR SCRIPT", Callback=function()
    Panic()
end})


local SVisualTools = TabCfg:AddSection({Name="🎨 FERRAMENTAS EXTRAS"})
SVisualTools:AddButton({Name="🎯 Resetar Posição Radar", Callback=function() _G.radarPos = Vector2new(200, 200) end})
SVisualTools:AddToggle({Name="🕵️ Streamproof (Anti-OBS)", Default=_G.streamproofEnabled, Save=true, Flag="StPrf", Callback=function(V) 
    _G.streamproofEnabled=V
    local o = findOrionGui()
    if o then o.DisplayOrder = V and 0 or 100 end
    for _,d in pairs(allDrawings) do pcall(function() d.StreamProof = V end) end
    zSave() 
end})

OrionLib:Init()
print("⚡ Supreme Hub Loaded | Radar & System Active")
