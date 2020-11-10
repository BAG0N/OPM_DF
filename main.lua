local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local http = game:GetService("HttpService")
local tp = game:GetService("TeleportService")
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local noclip = false
local fruit = nil
local travelling = true


function contains(arr, el)
	for _, v in pairs(arr) do
		if v == el then
			return true
		end
	end
	return false
end


function esp(switch)
	if switch then
		repeat
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Tool") then
					local part = v:FindFirstChildWhichIsA("BasePart")
					if part then fruit = part; break end
				end
			end
			wait(0.1)
		until fruit or not switch

		local gui = Instance.new("BillboardGui", fruit)
		gui.AlwaysOnTop = true
		gui.Size = UDim2.new(0, 100, 0, 50)
		local txt = Instance.new("TextLabel", gui)
		txt.Text = "Devil Fruit"
		txt.Font = Enum.Font.Cartoon
		txt.TextColor3 = Color3.new(0, 1, 0)
		txt.Size = UDim2.new(0, 100, 0, 50)
		txt.BackgroundTransparency = 1
		txt.TextScaled = true
	else
		if fruit and fruit:FindFirstChildWhichIsA("BillboardGui") then
			fruit:FindFirstChildWhichIsA("BillboardGui"):Destroy()			
		end
	end
end


function serverHop()
	local servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    local randomServer = servers.data[math.ceil(math.random() * #servers.data)]

    if randomServer.playing + 2 < randomServer.maxPlayers and randomServer.id ~= game.JobId then
        local success, err = pcall(function()
			tp:TeleportToPlaceInstance(game.PlaceId, randomServer.id)
		end)
        if err then serverHop() end
    else
        serverHop()
    end
end


function checkTime()
	local serverTime = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GetTime"):InvokeServer() / 4200
	local legitTime = (math.ceil(serverTime) - serverTime) * 70
	local secs = math.floor((legitTime - math.floor(legitTime)) * 60)
	local mins = math.floor(legitTime)
	local formattedTime = string.format('%02d:%02d', mins, secs)
	return mins, secs
end


function toTarget(pos, targetPos, targetCFrame)
	local info = TweenInfo.new((targetPos - pos).Magnitude / 500, Enum.EasingStyle.Linear)
	local tween, err = pcall(function()
		local tween = tweenService:Create(game:GetService("Players").LocalPlayer.Character["HumanoidRootPart"], info, {CFrame = targetCFrame})
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
	while wait() and travelling do
		for _, v in pairs(workspace:GetChildren()) do
			if v:IsA("Tool") then
				local fruit = v:FindFirstChildWhichIsA("BasePart")
				if fruit then
					noclip = true
					toTarget(root.Position, fruit.Position, fruit.CFrame)
					while wait(0.1) and (fruit.Position - root.Position).Magnitude > 10 do end
					noclip = false
				end
			end
		end
	end
end


local fruit = nil
local plr = game:GetService("Players").LocalPlayer

function esp(switch)
	if switch then
		repeat
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Tool") then
					local part = v:FindFirstChildWhichIsA("BasePart")
					if part then fruit = part; break end
				end
			end
			wait(0.1)
		until fruit or not switch

		local gui = Instance.new("BillboardGui", fruit)
		gui.AlwaysOnTop = true
		gui.Size = UDim2.new(0, 100, 0, 50)
		local txt = Instance.new("TextLabel", gui)
		txt.Text = "Devil Fruit"
		txt.Font = Enum.Font.Cartoon
		txt.Size = UDim2.new(0, 100, 0, 50)
		txt.TextColor3 = Color3.new(0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextScaled = true
	else
		if fruit and fruit:FindFirstChildWhichIsA("BillboardGui") then
			fruit:FindFirstChildWhichIsA("BillboardGui"):Destroy()			
		end
	end
end


function createGui()
	local material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()
	local title = "One Piece Millenium 3 DF"

	local ui = material.Load({
		Title = title,
		Style = 3,
		SizeX = 300,
		SizeY = 300,
		Theme = "Light"
	})
	local mainPage = ui.New({
		Title = 'Main'
	})
	
	local hopper = mainPage.Button({
		Text = 'Continue Server Hopping',
		Callback = serverHop
	})

	local DfEsp = mainPage.Toggle({
		Text = 'DF ESP',
		Callback = function(switch) esp(switch) end
	})

	local DfTravel = mainPage.Toggle({
		Text = 'Travel to DF',
		Callback = function(switch)
			travelling = switch
			getFruit()
		end
	})

	local txt = Instance.new("ImageLabel", coreGui[title].MainFrame.Content.MAIN)
	txt.Size = UDim2.new(1, 0, 0, 30)
	txt.BackgroundTransparency = 1
	txt.BorderSizePixel = 0
	txt.ImageTransparency = 0.8
	txt.Image = 'http://www.roblox.com/asset/?id=5554237731'
	txt.ImageColor3 = Color3.fromRGB(124, 37, 255)

	local textLabel = Instance.new("TextLabel", txt)
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.TextColor3 = Color3.fromRGB(124, 37, 255)
	textLabel.Font = Enum.Font.GothamSemibold
	textLabel.TextSize = 14
	textLabel.Text = "DF should spawn in MM:SS"

	spawn(function()
		while wait(0.2) do
			local mins, secs = checkTime()
			textLabel.Text = string.format("DF should spawn in %02d:%02d", mins, secs)
		end
	end)
end


runService.RenderStepped:Connect(function()
	if noclip then char.Humanoid:ChangeState(11) end
end)


local minLeft, _ = checkTime()
if minLeft > getgenv().minutes and not fruitSpawned() then
	serverHop()
else
	createGui()
end
