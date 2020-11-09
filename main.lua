local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local http = game:GetService("HttpService")
local tp = game:GetService("TeleportService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local noclip = false

if not getgenv().cache then getgenv().cache = {} end


function contains(arr, el)
	for _, v in pairs(arr) do
		if v == el then
			return true
		end
	end
	return false
end


function serverHop()
	local servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
	for _, server in pairs(servers.data) do
		if tonumber(server.playing) + 2 < tonumber(server.maxPlayers) and server.id ~= game.JobId and not contains(getgenv().cache) then
			local success, err = pcall(function()
				tp:TeleportToPlaceInstance(game.PlaceId, server.id)
			end)
			if success then
				table.insert(getgenv().cache, server.id)
				break
			end
		end
	end
end


function checkTime()
	local serverTime = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GetTime"):InvokeServer() / 2400
	local legitTime = (math.ceil(serverTime) - serverTime) * 40
	local secs = math.floor((legitTime - math.floor(legitTime)) * 60)
	local mins = math.floor(legitTime)
	local formattedTime = string.format('%02d:%02d', mins, secs)
	print(formattedTime)
	return mins
end


function toTarget(pos, targetPos, targetCFrame)
	local info = TweenInfo.new((targetPos - pos).Magnitude / 500, Enum.EasingStyle.Linear)
	local tween, err = pcall(function()
		local tween = tweenService:Create(game:GetService("Players").LocalPlayer.Character["HumanoidRootPart"], info, {CFrame = targetCFrame * CFrame.fromAxisAngle(Vector3.new(1,0,0), math.rad(90))})
		tween:Play()
	end)
	if not tween then return err end
end


function fruitSpawned()
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Tool") and v:FindFirstChildWhichIsA("BasePart") then
			return true
		end
	end
	return false
end


function getFruit()
	print("Getting the damn fruit!")
	while wait() do
		for _, v in pairs(workspace:GetChildren()) do
			if v:IsA("Tool") then
				local fruit = v:FindFirstChildWhichIsA("BasePart")
				if fruit then
					noclip = true
					toTarget(root.Position, fruit.Position, fruit.CFrame)
					while wait() and (fruit.Position - root.Position).Magnitude > 10 do end
					noclip = false
				end
			end
		end
	end
end


runService.RenderStepped:Connect(function()
	if noclip then char.Humanoid:ChangeState(11) end
end)


local minLeft = checkTime()
if minLeft > 4 and not fruitSpawned() then
	serverHop()
else
	getFruit()
end
