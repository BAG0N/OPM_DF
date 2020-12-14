while not game:IsLoaded() do wait() end

local virtualUser = game:GetService("VirtualUser")
local run = game:GetService("RunService")
local storage = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character
local root = char.HumanoidRootPart

local noClipConnection
local killAuraOn = false
local farming = false
local autoRebirth = false
local hiddenName = false
local autoMode = false
local inf = false
local chosenMode = ''
local mobName = ''
local yOffset = 0
local zOffset = -2
local allPlayer = {}
local chosenQuests = {}


pcall(function()
	getgenv().afk:Disconnect() 
	getgenv().respawn:Disconnect()
end)


getgenv().respawn = plr.CharacterAdded:Connect(function(newChar)
	char = newChar
	root = char:WaitForChild("HumanoidRootPart")
	local info = char:WaitForChild("InfoDisplay")
	info:Destroy()
end)


getgenv().afk = plr.Idled:Connect(function()
	virtualUser:CaptureController()
	virtualUser:ClickButton2(Vector2.new())
end)


function stopInf()
	local mt = getrawmetatable(game)
	local oldCall = mt.__namecall

	setreadonly(mt, false)

	mt.__namecall = newcclosure(function(self, ...)
		if inf and self.Name == 'Moves' then
			inf = false
			storage.Remotes.Transformation:FireServer({["Name"] = "Recharge", ["Remove"] = true})
		end
		return oldCall(self, ...)
	end)

	setreadonly(mt, false)
end


function formatInt(number)
	local _, __, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end


function keys(arr)
	local result = {}
	for key, _ in pairs(arr) do
		table.insert(result, key)
	end
	return result
end


function updatePlayers()
	allPlayer = {}
	for _, v in pairs(game:GetService("Players"):GetChildren()) do
		if v ~= plr then
			table.insert(allPlayer, v.Name)
		end
	end
end


updatePlayers()


function noclip(on)
	if on then
		noClipConnection = run.RenderStepped:Connect(function()
			char.Humanoid:ChangeState(11)
		end)
	else
		pcall(function() noClipConnection:Disconnect() end)
	end
end


function getUnlockedModes()
	local result = {}
	for _, v in pairs(plr.PlayerGui.MainUI.Mainframe.Menus.Frames.Forms.Transforms:GetDescendants()) do
		if v:IsA("GuiButton") and v:FindFirstChild("Label") and not v:FindFirstChild("Lock") then
			table.insert(result, v.Label.Text)
		end
	end
	return result
end


function equipTool(toolName)
	char.Humanoid:EquipTool(plr.Backpack:FindFirstChild(toolName))
end


function getMobs()
	local result = {}
	for _, v in pairs(workspace.NPCS:GetDescendants()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") then
			local power = v:FindFirstChild("Power") or v.Stats.Power
			local name = string.format('%s [Power %s]', v.Name, formatInt(power.Value))
			if not table.find(result, name) then
				table.insert(result, name)
			end
		end
	end
	table.sort(result, function(a, b)
		a = string.gsub(a:split('Power ')[2]:split(']')[1], ',', '')
		b = string.gsub(b:split('Power ')[2]:split(']')[1], ',', '')
		return tonumber(a) < tonumber(b)
	end)
	
	local dataTable = {}
	table.foreach(result, function(i, v) dataTable[v] = false end)
	
	return dataTable
end


function hasQuest(name)
	local quests = plr.PlayerGui.MainUI.Mainframe.Menus.Frames.Quests.Quests
	for _, txt in pairs(quests:GetChildren()) do
		if txt:IsA("TextButton") and txt.Text:find(name) then
			return true
		end
	end
	return false
end


function takeQuest(name)
	local count = 0
	for _, v in pairs(workspace.Quests:GetChildren()) do
		if v.Name:find(name) then
			root.CFrame = v.HumanoidRootPart.CFrame
			while farming and not hasQuest(name) and wait(0.1) do
				count = count + 1
				fireclickdetector(v:FindFirstChildOfClass("ClickDetector"))
				wait(0.1)
				if plr.PlayerGui.MainUI.Mainframe.Dialog.Options:FindFirstChild('Yes') then
					firesignal(plr.PlayerGui.MainUI.Mainframe.Dialog.Options.Yes.MouseButton1Click)
				end
			end
		end
	end
end


function infEnergy()
	while inf and run.Heartbeat:Wait() do
		local v1 = {["Name"] = "Recharge", ["Remove"] = false}
		local rem = storage.Remotes.Transformation
		rem:FireServer(v1)
	end
	
	storage.Remotes.Transformation:FireServer({["Name"] = "Recharge", ["Remove"] = true})
end


function hideName()
	pcall(function()
		char:FindFirstChildWhichIsA("BillboardGui"):Destroy()
	end)
	
	game:GetService("StarterGui"):SetCore('SendNotification', {
		Title = 'Success',
		Text = 'Your identity is safe now',
		Duration = 2
	})
end


function hit()
	local v1 = "Punch"
	local v2 = root.Position
	local v4 = root.CFrame
	local rem = storage.Remotes.Moves

	rem:FireServer(v1, v2, v4)
end


function killAura()
	while killAuraOn and wait() do
		hit()
	end
end


function rebirth()
	local rem = storage.Remotes.Rebirth
	while autoRebirth and wait(5) do	
		rem:FireServer()
	end
end


function autoKill(name)
	if not hasQuest(name) then takeQuest(name) end
	
	while farming and hasQuest(name) and wait(0.1) do
		for _, npc in pairs(workspace.NPCS:GetDescendants()) do
			if npc:IsA("Model") and npc.Name == name then
				if not farming or not hasQuest(name) then break end
				while farming and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 do
					root.CFrame = (npc.HumanoidRootPart.CFrame + Vector3.new(0, yOffset, 0)) + npc.HumanoidRootPart.CFrame.LookVector * zOffset 
					hit()
					wait()
				end
			end
		end
	end
end


function autoFarm(data)
	local mobs = {}
	local cache = {}
	
	for name, v in pairs(data) do
		if v then
			local legitName = name:split(' [Power ')[1]
			table.insert(mobs, legitName)
		end
	end
	
	local startPos = root.CFrame
	noclip(true)
	
	while farming and wait(0.1) do
		for _, name in pairs(mobs) do
			if not farming then break end
			for _, npc in pairs(workspace.NPCS:GetDescendants()) do
				if not farming then break end
				if npc:IsA("Model") and npc.Name == name and npc.Humanoid.Health > 0 and not table.find(cache, name) then
					table.insert(cache, name)
					autoKill(name)
				end
			end
		end
		cache = {}
	end

	noclip(false)
	root.CFrame = startPos * CFrame.Angles(0, 0, 0)
end


function questTps()
	local result = {}
	for _, v in pairs(workspace.Quests:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
			table.insert(result, v.Name)
		end
	end
	return result
end


function bossesPadTp()
	local result = {}
	for i, v in pairs(workspace.Islands['Bosses Pad']:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") then
			table.insert(result, 'Boss Pad ' .. tostring(i))
		end
	end
	return result
end


function createText(text, title, tabTitle)
	local txt = Instance.new("ImageLabel", game:GetService("CoreGui")[title].MainFrame.Content[tabTitle:upper()])
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
	textLabel.Text = text

	return textLabel
end


function createGui()
	local material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()
	local title = "Saiyan Fighting Simulator GUI"

	local ui = material.Load({
		Title = title,
		Style = 3,
		SizeX = 350,
		SizeY = 350,
		Theme = "Light"
	})
	local mainPage = ui.New({
		Title = 'farming'
	})
	local utilsPage = ui.New({
		Title = 'Utils'
	})
	local tpPage = ui.New({
		Title = 'Teleports'
	})
	
	local infEnergyToggle = utilsPage.Toggle({
		Text = 'Auto Charge Energy',
		Callback = function(on)
			inf = on
			infEnergy()
		end
	})
	
	local autoRebirthToggle = utilsPage.Toggle({
		Text = 'Auto Rebirth',
		Callback = function(on)
			autoRebirth = on
			rebirth()
		end
	})

	local killAuraToggle = utilsPage.Toggle({
		Text = 'Auto Punch',
		Callback = function(on)
			killAuraOn = on
			killAura()
		end
	})

	local playerTp = tpPage.Dropdown({
		Text = 'Player Locations',
		Options = allPlayer,
		Callback = function(chosenPlayer)
			local targetPlayer = game:GetService("Players"):FindFirstChild(chosenPlayer)
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 30, 0)
			end
		end
	})

	game:GetService("Players").PlayerAdded:Connect(function()
		updatePlayers()
		playerTp:SetOptions(allPlayer)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function()
		updatePlayers()
		playerTp:SetOptions(allPlayer)
	end)
	
	local questTp = tpPage.Dropdown({
		Text = 'Quest NPCs',
		Options = questTps(),
		Callback = function(chosen)
			local npc = workspace.Quests:FindFirstChild(chosen)
			if npc and npc:FindFirstChild("HumanoidRootPart") then
				root.CFrame = npc.HumanoidRootPart.CFrame
			end
		end
	})
	
	local bossTp = tpPage.Dropdown({
		Text = 'Boss Pads',
		Options = bossesPadTp(),
		Callback = function(chosen)
			local index = tonumber(chosen:split('Boss Pad ')[2])
			local pads = workspace.Islands['Bosses Pad']:GetChildren()
			if index <= #pads then
				root.CFrame = pads[index]:FindFirstChildWhichIsA("BasePart").CFrame
			end
		end
	})

	local configText = createText('AutoFarm Settings', title, 'Farming')
	
	local modeName = mainPage.Dropdown({
		Text = 'Choose mode',
		Options = getUnlockedModes(),
		Callback = function(newMode) chosenMode = newMode end,
		Menu = {
			['Unlocked Modes'] = function()
				ui.Banner({
					Text = 'You have ' .. #getUnlockedModes() .. ' modes unlocked'
				})
			end
		}
	})
	
	local autoMode = mainPage.Toggle({
		Text = 'Auto Mode',
		Callback = function(on)
			autoMode = on
			if on and #chosenMode > 1 then
				local rem = game:GetService("ReplicatedStorage").Remotes.Transformation
				local v1 = {["Name"] = chosenMode, ["Remove"] = false}
				local already = false
				while autoMode and wait(1) do
					already = false
					
					for _, v in pairs(char:GetChildren()) do
						if v:IsA("Model") and v.Name:lower():find('aura') then
							already = true
						end
					end
					
					if not already then
						rem:FireServer(v1)
					end
				end
			end
		end,
	})
	
	local yOffsetSlider = mainPage.Slider({
		Text = 'Y Offset',
		Min = -10,
		Max = 10,
		Def = 0,
		Callback = function(new) yOffset = new end,
		Menu = {
			Information = function()
				ui.Banner({Text = "Determines how high/low you are from NPC when farming"})
			end
		}
	})
	
	local zOffsetSlider = mainPage.Slider({
		Text = 'Z Offset',
		Min = -5,
		Max = 5,
		Def = -2,
		Callback = function(new) zOffset = new end,
		Menu = {
			Information = function()
				ui.Banner({Text = "Determines how forward/backward you are from NPC when farming"})
			end
		}
	})
	
	local nameHider = mainPage.Button({
		Text = 'Hide Name',
		Callback = hideName
	})

	local autoFarmText = createText('AutoFarm', title, 'Farming')
	
	local questsTable = mainPage.DataTable({
		Text = 'Choose Mobs To Farm',
		Options = getMobs(),
		Callback = function(newTable) chosenQuests = newTable end
	})

	local autoFarmToggle = mainPage.Toggle({
		Text = 'Toggle Auto Farm',
		Callback = function(on)
			farming = on
			if on then
				pcall(function() autoFarm(chosenQuests) end)
				noclip(false)
			else
				noclip(false)
			end
		end
	})
end


local _, err = pcall(stopInf)
if err then warn('Your exploit threw an error on metatables:', err) end
createGui()
