while not game:IsLoaded() do wait() end
local plr = game:GetService("Players").LocalPlayer
local tweenService = game:GetService("TweenService")


function toTarget(target)
	local speed = getgenv().speed or 300
	local info = TweenInfo.new((target.Position - plr.Character.HumanoidRootPart.Position).Magnitude / speed, Enum.EasingStyle.Linear)
	local _, err = pcall(function()
		tweenService:Create(plr.Character.HumanoidRootPart, info, {CFrame = target}):Play()
	end)
	if err then error("Couldn't create/start tween: ", err) end
end


function newIndexHook()
	local mt = getrawmetatable(game)
	local oldIndex = mt.__newindex

	setreadonly(mt, false)

	mt.__newindex = newcclosure(function(self, i, v)
		if checkcaller() and self == plr.Character.HumanoidRootPart and i == 'CFrame' then
			return toTarget(v) 
		end
		return oldIndex(self, i, v)
	end)

	setreadonly(mt, true)
end


newIndexHook()
