-- Settings iniciais
local Settings = {
    AimbotOn = false,
    ShowFOV = true,
    TeamCheck = true,
    LockRadius = 100,
    FOVColor = Color3.fromRGB(255, 255, 255),
    ESPOn = true,
    UseTeamColors = false,
    OwnTeamColor = Color3.fromRGB(0, 0, 255),
    OpponentTeamColor = Color3.fromRGB(255, 0, 0),
    InstantReload = false,
    InfiniteAmmo = false,
    NoRecoil = false,
    NoSpread = false,
    FastShoot = false,
    WalkspeedOn = false,
    WalkspeedValue = 50,
    JumpheightOn = false,
    JumpheightValue = 25,
}

-- Importa Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Cria janela simples, tema claro
local MainWindow = Rayfield:CreateWindow({
    Name = "Aimbot & Gun Mods",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Por FM",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ConfigAimbot",
        FileName = "Config",
    },
    Theme = "Light",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
})

-- Cria abas
local AimbotTab = MainWindow:CreateTab("Aimbot")
local ESPTab = MainWindow:CreateTab("ESP")
local GunModTab = MainWindow:CreateTab("Gun Mods")
local CharacterTab = MainWindow:CreateTab("Personagem")

-- Aimbot
AimbotTab:CreateToggle({
    Name = "Ativar Aimbot",
    CurrentValue = Settings.AimbotOn,
    Callback = function(value)
        Settings.AimbotOn = value
    end,
})

AimbotTab:CreateToggle({
    Name = "Mostrar FOV",
    CurrentValue = Settings.ShowFOV,
    Callback = function(value)
        Settings.ShowFOV = value
        -- Atualize visibilidade do FOV aqui
    end,
})

AimbotTab:CreateToggle({
    Name = "Verificar Equipe",
    CurrentValue = Settings.TeamCheck,
    Callback = function(value)
        Settings.TeamCheck = value
    end,
})

AimbotTab:CreateSlider({
    Name = "Tamanho do FOV",
    Range = {1, 1000},
    Increment = 10,
    CurrentValue = Settings.LockRadius,
    Callback = function(value)
        Settings.LockRadius = value
        -- Atualize tamanho do círculo de FOV aqui
    end,
})

AimbotTab:CreateColorPicker({
    Name = "Cor do FOV",
    Color = Settings.FOVColor,
    Callback = function(value)
        Settings.FOVColor = value
        -- Atualize a cor do círculo de FOV aqui
    end,
})

-- ESP
ESPTab:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = Settings.ESPOn,
    Callback = function(value)
        Settings.ESPOn = value
        -- Lógica para ativar/desativar ESP
    end,
})

ESPTab:CreateToggle({
    Name = "Usar Cores da Equipe",
    CurrentValue = Settings.UseTeamColors,
    Callback = function(value)
        Settings.UseTeamColors = value
        -- Atualize ESP com as cores
    end,
})

ESPTab:CreateColorPicker({
    Name = "Cor da Equipe Própria",
    Color = Settings.OwnTeamColor,
    Callback = function(value)
        Settings.OwnTeamColor = value
        -- Atualize cor do ESP para a equipe própria
    end,
})

ESPTab:CreateColorPicker({
    Name = "Cor da Equipe Oponente",
    Color = Settings.OpponentTeamColor,
    Callback = function(value)
        Settings.OpponentTeamColor = value
        -- Atualize cor do ESP para oponente
    end,
})

-- Gun Mods
GunModTab:CreateToggle({
    Name = "Recarga Instantânea",
    CurrentValue = Settings.InstantReload,
    Callback = function(value)
        Settings.InstantReload = value
    end,
})

GunModTab:CreateToggle({
    Name = "Munição Infinita",
    CurrentValue = Settings.InfiniteAmmo,
    Callback = function(value)
        Settings.InfiniteAmmo = value
    end,
})

GunModTab:CreateToggle({
    Name = "Sem Recuo",
    CurrentValue = Settings.NoRecoil,
    Callback = function(value)
        Settings.NoRecoil = value
    end,
})

GunModTab:CreateToggle({
    Name = "Sem Dispersão",
    CurrentValue = Settings.NoSpread,
    Callback = function(value)
        Settings.NoSpread = value
    end,
})

GunModTab:CreateToggle({
    Name = "Tiro Rápido",
    CurrentValue = Settings.FastShoot,
    Callback = function(value)
        Settings.FastShoot = value
    end,
})

-- Personagem
CharacterTab:CreateToggle({
    Name = "Velocidade Ligada",
    CurrentValue = Settings.WalkspeedOn,
    Callback = function(value)
        Settings.WalkspeedOn = value
        -- Atualize a velocidade do personagem
    end,
})

CharacterTab:CreateSlider({
    Name = "Velocidade de Caminhada",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = Settings.WalkspeedValue,
    Callback = function(value)
        Settings.WalkspeedValue = value
        -- Atualize a velocidade do personagem
    end,
})

CharacterTab:CreateToggle({
    Name = "Pular Alto",
    CurrentValue = Settings.JumpheightOn,
    Callback = function(value)
        Settings.JumpheightOn = value
        -- Atualize a altura do pulo
    end,
})

CharacterTab:CreateSlider({
    Name = "Altura do Pulo",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = Settings.JumpheightValue,
    Callback = function(value)
        Settings.JumpheightValue = value
        -- Atualize a altura do pulo
    end,
})

-- Mostrar menu
MainWindow:Show()
