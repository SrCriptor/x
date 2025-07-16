--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
_G.lt = {
	["_ammo"] = 999999999999999999999999999999999999999999999999999999,
	["rateOfFire"] = 999999999999999999999999999999999999999999999999999999,
	["recoilAimReduction"] = Vector2.new(0,0),
	["recoilMax"] = Vector2.new(0,0),
	["recoilMin"] = Vector2.new(0,0),
	["spread"] = 0,
	["reloadTime"] = 0,
	["zoom"] = 3,
	["magazineSize"] = 999999999999999999999999999999999999999999999999999999
}

local plrs = game.Players
local me = plrs.LocalPlayer
local mouse = me:GetMouse()

me.CharacterAdded:Connect(function(char)
	local tool
	while not(tool) and task.wait() do tool = char:FindFirstChildWhichIsA("Tool") end
	for i,v in _G.lt do tool:SetAttribute(i,v) end
end)

while task.wait() do
	local char, hit = me.Character, mouse.Hit
	if char and hit then
		local tool, hd = char:FindFirstChildWhichIsA("Tool"), char:FindFirstChild("Head")
		if tool and hd then
			tool:SetAttribute("spread", 30-(hd.Position-hit.Position).Magnitude/5)
		end
	end
end

-- for _,plr in ipairs(game.Players:GetPlayers()) do
-- 	if plr ~= game.Players.LocalPlayer then
-- 		plr.CharacterAdded:Connect(function(char)
-- 			task.wait(0.2)
-- 			char.Head.Size = Vector3.new(100,100,100)
-- 			char.Head.CanCollide = false
-- 		end)
-- 	end
-- end
