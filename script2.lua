-- [INTERFACE COMPLETA ESTILO RAYCAST COM AIMBOT, HITBOX, WALLHACK RGB E MODS DE ARMA + AJUSTES AVANÇADOS + HITBOX POPUP E VERIFICAÇÕES MELHORADAS]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis Globais Padrão
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotLegitEnabled = _G.aimbotLegitEnabled or false
_G.modInfiniteAmmo = _G.modInfiniteAmmo or false
_G.modNoRecoil = _G.modNoRecoil or false
_G.modInstantReload = _G.modInstantReload or false
_G.showFOV = _G.showFOV or true
_G.espAlly = _G.espAlly or false
_G.espEnemy = _G.espEnemy or true
_G.espBox = _G.espBox or true
_G.espName = _G.espName or true
_G.espLine = _G.espLine or true
_G.espDistance = _G.espDistance or true
_G.espHealth = _G.espHealth or true
_G.espWallhack = _G.espWallhack or true
_G.ignoreWall = _G.ignoreWall or false
_G.hitboxSelection = _G.hitboxSelection or {
    Head = true, Torso = false, LeftArm = false, RightArm = false, LeftLeg = false, RightLeg = false
}
_G.FOV_RADIUS = _G.FOV_RADIUS or 200
_G.lt = _G.lt or {
	["rateOfFire"] = 200,
	["spread"] = 0,
	["zoom"] = 3,
}

-- Criação de elementos do ESP para cada jogador
function createESPForCharacter(char, isEnemy)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 1
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = char
    highlight.Enabled = false
    highlight.Parent = char

    RunService.Heartbeat:Connect(function()
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            local canSee = true
            if not _G.ignoreWall and Camera and char:FindFirstChild("Head") then
                local result = workspace:Raycast(Camera.CFrame.Position, (char.Head.Position - Camera.CFrame.Position), RaycastParams.new())
                if result and not result.Instance:IsDescendantOf(char) then
                    canSee = false
                end
            end

            highlight.Enabled = (isEnemy and _G.espEnemy or not isEnemy and _G.espAlly) and canSee and _G.espWallhack
            if highlight.Enabled and _G.aimbotAutoEnabled and canSee then
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                highlight.OutlineTransparency = 0
            else
                highlight.OutlineTransparency = 1
            end
        end
    end)
end

function applyESPToPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            createESPForCharacter(plr.Character, plr.Team ~= LocalPlayer.Team)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        wait(0.5)
        createESPForCharacter(char, plr.Team ~= LocalPlayer.Team)
    end)
end)

applyESPToPlayers()

-- Aplicar Mods a cada arma equipada
LocalPlayer.CharacterAdded:Connect(function(char)
    local tool
    while not tool do
        tool = char:FindFirstChildWhichIsA("Tool")
        task.wait()
    end
    for i,v in pairs(_G.lt) do
        tool:SetAttribute(i,v)
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            if _G.modNoRecoil then
                tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
                tool:SetAttribute("recoilMax", Vector2.new(0, 0))
                tool:SetAttribute("recoilMin", Vector2.new(0, 0))
            end
            if _G.modInfiniteAmmo then
                local mag = tool:GetAttribute("magazineSize") or 200
                tool:SetAttribute("_ammo", math.huge)
                tool:SetAttribute("magazineSize", mag)
                local display = tool:FindFirstChild("AmmoDisplay")
                if display and display:IsA("TextLabel") then
                    display.Text = tostring(mag)
                end
            end
            if _G.modInstantReload then
                tool:SetAttribute("reloadTime", 0)
            end
        end
    end
end)

-- Atualização dinâmica do spread baseado no mouse
local mouse = LocalPlayer:GetMouse()
RunService.Heartbeat:Connect(function()
    local char, hit = LocalPlayer.Character, mouse.Hit
    if char and hit then
        local tool, hd = char:FindFirstChildWhichIsA("Tool"), char:FindFirstChild("Head")
        if tool and hd then
            tool:SetAttribute("spread", 30 - (hd.Position - hit.Position).Magnitude / 5)
        end
    end
end)
