local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

-- Extras para armas
_G.infiniteAmmo = true
_G.instantReload = true
_G.noRecoil = true
_G.noSpread = true
_G.fastShoot = false

-- Tabela de atributos default da arma
_G.lt = {
    ["_ammo"] = math.huge,
    ["rateOfFire"] = 0.1,  -- Cadência padrão, ajuste se quiser fastShoot
    ["recoilAimReduction"] = Vector2.new(0, 0),
    ["recoilMax"] = Vector2.new(0, 0),
    ["recoilMin"] = Vector2.new(0, 0),
    ["spread"] = 0,
    ["reloadTime"] = 0,
    ["zoom"] = 3,
    ["magazineSize"] = math.huge
}

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil

-- Referência aos botões mobile - adapte se necessário
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Função para saber se é Free For All
local function isFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then
            teams[player.Team] = true
        end
    end
    local count = 0
    for _ in pairs(teams) do count = count + 1 end
    return count <= 1
end

-- Função para checar se personagem está vivo
local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Função para checar linha de visão
local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
    else
        return true
    end
end

-- Atualiza os atributos da arma (tool) com as configurações globais
local function applyWeaponAttributes(tool)
    if not tool then return end

    -- Infinite Ammo: setar munição alta
    local ammo = tool:FindFirstChild("Ammo")
    if ammo and _G.infiniteAmmo then
        ammo.Value = math.huge
    end

    -- Instant Reload: para jogos que usam BoolValue ou NumberValue para reload
    local reloading = tool:FindFirstChild("Reloading")
    if reloading and _G.instantReload then
        if reloading:IsA("BoolValue") then
            reloading.Value = false
        elseif reloading:IsA("NumberValue") then
            reloading.Value = 0
        end
    end

    -- No Recoil: zera recoil (supondo atributos)
    if _G.noRecoil then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    end

    -- No Spread
    if _G.noSpread then
        tool:SetAttribute("spread", 0)
    end

    -- Fast Shoot: diminuir tempo entre tiros
    if _G.fastShoot then
        tool:SetAttribute("rateOfFire", 0.02) -- 20ms entre tiros (muito rápido)
    else
        tool:SetAttribute("rateOfFire", 0.1) -- padrão (ajuste conforme seu jogo)
    end
end

-- Atualiza arma atual e aplica atributos
local function onCharacterAdded(character)
    local tool

    -- Espera até o personagem ter uma arma
    repeat
        tool = character:FindFirstChildWhichIsA("Tool")
        task.wait(0.1)
    until tool

    applyWeaponAttributes(tool)

    -- Caso troque de arma, reaplica
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            applyWeaponAttributes(child)
        end
    end)
end

-- Evento para aplicar atributos quando personagem nasce
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

-- Função para achar o inimigo visível mais próximo no FOV
local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local closestEnemy = nil
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not isAlive(player.Character) then continue end

        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then continue end
            if player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = player.Character:FindFirstChild("Head")
        if not head then continue end

        local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
        if not visible then continue end

        local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distToCenter > shortestDistance then continue end

        if not hasLineOfSight(head) then continue end

        shortestDistance = distToCenter
        closestEnemy = player
    end

    return closestEnemy
end

-- Controles dos botões de mira e tiro mobile
aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
    currentTarget = nil
end)
shootButton.MouseButton1Down:Connect(function()
    shooting = true
end)
shootButton.MouseButton1Up:Connect(function()
    shooting = false
end)

-- Desenho do círculo do FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- Loop principal para aimbot e cheats
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot automático
    if _G.aimbotAutoEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    end

    -- Aimbot manual (quando mira e atira)
    if _G.aimbotManualEnabled and aiming and shooting then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    elseif not (_G.aimbotManualEnabled and aiming and shooting) and not _G.aimbotAutoEnabled then
        currentTarget = nil
    end

    -- Atualiza atributos da arma em loop (se quiser garantir cheat ativo)
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            applyWeaponAttributes(tool)
        end
    end
end)
