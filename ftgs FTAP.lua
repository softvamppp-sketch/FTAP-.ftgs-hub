print('discord.gg/25ms was here')

local Players = game:GetService('Players')
local Debris = game:GetService('Debris')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local VirtualUser = game:GetService('VirtualUser')
local UserService = game:GetService('UserService')

local CharacterEvents = ReplicatedStorage:WaitForChild('CharacterEvents')
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local Mouse = LocalPlayer:GetMouse()

local SpawnedInToys = Workspace:WaitForChild(LocalPlayer.Name .. 'SpawnedInToys')
local InPlot = LocalPlayer:WaitForChild('InPlot')
local ToysLimitCap = LocalPlayer:WaitForChild('ToysLimitCap')

local SpawnToyRF = ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('SpawnToyRemoteFunction')
local DeleteToyRE = ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('DestroyToy')
local BuyToy = ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('BuyToyRemoteFunction')
local BombEvents = ReplicatedStorage:WaitForChild('BombEvents')

local typeAnimation = ReplicatedFirst:WaitForChild('Typing'):WaitForChild('Type')
local flailAnimation = ReplicatedFirst:WaitForChild('ThrowPlayers'):WaitForChild('Flail')

local GrabEvents = ReplicatedStorage:WaitForChild('GrabEvents')
local CreateGrabLine = GrabEvents:WaitForChild('CreateGrabLine')
local DestroyGrabLine = GrabEvents:WaitForChild('DestroyGrabLine')
local SetNetworkOwner = GrabEvents:WaitForChild('SetNetworkOwner')
GrabEvents:WaitForChild('ExtendGrabLine')

local RagdollRemote = CharacterEvents:WaitForChild('RagdollRemote')
local ChatTypingBoard = CharacterEvents:WaitForChild('ChatTyping')
local Struggle = CharacterEvents:WaitForChild('Struggle')

local SayMessageRequest = nil
local defaultChatEvents = ReplicatedStorage:FindFirstChild('DefaultChatSystemChatEvents')
if defaultChatEvents and defaultChatEvents:FindFirstChild('SayMessageRequest') then
	SayMessageRequest = defaultChatEvents.SayMessageRequest
end

local UpdateLineColorsEvent = ReplicatedStorage:WaitForChild('DataEvents'):WaitForChild('UpdateLineColorsEvent')
local IsHeld = LocalPlayer:WaitForChild('IsHeld')
local PlayerScripts = LocalPlayer:WaitForChild('PlayerScripts')
local anticreatelinelocalscript = PlayerScripts:WaitForChild('CharacterAndBeamMove')

local u28 = nil
local floatName = nil

local HUB_TITLE = '.ftgs hub — M4nace × Wump'

-- Safe UI library loader with fallback
local UILib
do
	local ok, res = pcall(function()
		return loadstring(game:HttpGet('http://you.whimper.xyz/sources/blitz/orionx'))()
	end)
	if ok and type(res) == 'table' then
		UILib = res
	else
		warn('Failed to load UI library:', res)
		return
	end
end

local function Notify(content, title, img, duration)
	UILib:MakeNotification({
		Name = title or HUB_TITLE,
		Content = tostring(content),
		Image = img or 'rbxassetid://16570630989',
		Time = duration or 5,
	})
end

local function GetKey()
	return _G.ScriptKey or 'Free'
end

local function IsSolara()
	if getexecutorname then
		local execName = getexecutorname()
		if execName and string.find(execName, 'Solara') then
			return true
		end
	end
	return false
end

local function IsMobile()
	return PlayerGui:FindFirstChild('ContextActionGui') ~= nil
end

if IsSolara() then
	print('new proximity prompt created!')
	getgenv().fireproximityprompt = function(prompt)
		if typeof(prompt) ~= 'Instance' or not prompt:IsA('ProximityPrompt') then
			error('Expected ProximityPrompt, got ' .. tostring(prompt))
		end
		local oldDuration = prompt.HoldDuration
		local oldDist = prompt.MaxActivationDistance

		prompt.MaxActivationDistance = math.huge
		prompt.HoldDuration = 0

		prompt:InputHoldBegin()
		task.wait()
		prompt:InputHoldEnd()

		prompt.HoldDuration = oldDuration
		prompt.MaxActivationDistance = oldDist
	end
end

local AdminData = {}
local function checkadminData(name)
	return AdminData[name] ~= nil
end

local spawnToyThread = coroutine.create(function()
	while true do
		local args = coroutine.yield()
		if typeof(args) == 'table' then
			pcall(function()
				SpawnToyRF:InvokeServer(unpack(args))
			end)
		end
	end
end)

local function SpawnToy(args)
	if coroutine.status(spawnToyThread) == 'suspended' then
		coroutine.resume(spawnToyThread, args)
	end
end

local function GetGroupRankInfo(player, groupId)
	if typeof(player) ~= 'Instance' or not player.Parent then
		return nil
	end
	local lastUpdate = player:GetAttribute('LastTimeRankUpdate')
	if not lastUpdate or (os.clock() - lastUpdate) >= 300 then
		local okRank, rank = pcall(function()
			return player:GetRankInGroup(groupId)
		end)
		local _, role = pcall(function()
			return player:GetRoleInGroup(groupId)
		end)
		local r = okRank and rank or 0

		if r == 255 then
			player:SetAttribute('Rank', 'Leader')
		elseif r == 4 and role == 'High Rank Admin' then
			player:SetAttribute('Rank', 'High Rank Admin')
		elseif r == 3 then
			player:SetAttribute('Rank', 'Low Rank Admin')
		elseif r == 2 then
			player:SetAttribute('Rank', 'Goon')
		else
			player:SetAttribute('Rank', 'Common')
		end
		player:SetAttribute('LastTimeRankUpdate', os.clock())
	end
	return player:GetAttribute('Rank')
end

local function IsAdminPlayer(target)
	local player = nil
	if typeof(target) == 'Instance' then
		if target:IsA('Model') and target:FindFirstChildOfClass('Humanoid') then
			player = Players:GetPlayerFromCharacter(target)
		elseif target:IsA('Player') then
			player = target
		end
	end
	if not player then
		return false
	end

	local rank = GetGroupRankInfo(player, 16168861)
	local isAdmin = rank == 'Leader'
		or rank == 'High Rank Admin'
		or rank == 'Low Rank Admin'
		or rank == 'Goon'

	if checkadminData(player.Name) and AdminData[player.Name] and not AdminData[player.Name].Protection then
		isAdmin = false
	end

	return isAdmin
end

local function IsHoldingAdminPlayer()
	local grabParts = Workspace:FindFirstChild('GrabParts')
	local grabPart = grabParts and grabParts:FindFirstChild('GrabPart')
	local weld = grabPart and grabPart:FindFirstChild('WeldConstraint')
	if weld and weld.Part1 and weld.Part1.Parent then
		return IsAdminPlayer(weld.Part1.Parent)
	end
	return false
end

local function WhatIsHolding(grabModel)
	local grabPart = grabModel and grabModel:FindFirstChild('GrabPart')
	local weld = grabPart and grabPart:FindFirstChild('WeldConstraint')
	if weld and weld.Part1 and weld.Part1.Parent and weld.Part1.Parent:IsA('Model') then
		local parentModel = weld.Part1.Parent
		if Players:GetPlayerFromCharacter(parentModel) then
			return 'Player'
		elseif parentModel:FindFirstChild('Pet') then
			return 'Follow NPC'
		else
			return 'Object'
		end
	end
end

local function tableAlphabeticOrder(a, b)
	return tostring(a):lower() < tostring(b):lower()
end

local function extractUsername(entry)
	if type(entry) ~= 'string' or entry == '' then return nil end
	local name = entry:match('^([^%s%(]+)')
	return name
end

local function refreshPlayerDropdown(dropdown, includeSelf)
	if not dropdown then return end
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if includeSelf or plr.UserId ~= LocalPlayer.UserId then
			table.insert(list, plr.Name .. ' (' .. plr.DisplayName .. ')')
		end
	end
	table.sort(list, tableAlphabeticOrder)
	if includeSelf then
		table.insert(list, 1, LocalPlayer.Name .. ' (' .. LocalPlayer.DisplayName .. ')')
	end
	pcall(function()
		dropdown:Refresh(list, true)
	end)
end

local LoopPlayers = {}
local WhitelistPlayers = {}

local function refreshStringListDropdown(dropdown, sourceList)
	if not dropdown then return end
	local clean = {}
	for _, item in pairs(sourceList or {}) do
		if type(item) == 'string' and item ~= '' then
			table.insert(clean, item)
		end
	end
	pcall(function()
		dropdown:Refresh(clean, true)
	end)
end

local function lookAt(fromPos, toPos)
	local dir = toPos - fromPos
	if dir.Magnitude < 1e-4 then
		return CFrame.new(fromPos)
	end
	local unit = dir.Unit
	local right = unit:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 1e-4 then
		right = Vector3.new(1, 0, 0)
	else
		right = right.Unit
	end
	local up = right:Cross(unit).Unit
	return CFrame.fromMatrix(fromPos, right, up)
end

local function onSpawnToyAction(actionName, inputState)
	if actionName == 'Spawn Toy (TAB)' and inputState == Enum.UserInputState.Begin then
		local char = LocalPlayer.Character
		local camPart = char and char:FindFirstChild('CamPart')
		if camPart and _G.SelectedToy then
			SpawnToyRF:InvokeServer(
				_G.SelectedToy,
				camPart.CFrame,
				Vector3.new(0, camPart.Orientation.Y, 0)
			)
		end
	end
end

local function GetPlayerCharacter()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild('HumanoidRootPart') and char:FindFirstChildOfClass('Humanoid') then
		return char
	end
end

local function GetPlayerRoot()
	local char = GetPlayerCharacter()
	return char and char:FindFirstChild('HumanoidRootPart')
end

local function GetPlayerCFrame()
	local root = GetPlayerRoot()
	return root and root.CFrame
end

local function GetPlayerHRPByName(name)
	local plr = type(name) == 'string' and Players:FindFirstChild(name)
	local char = plr and plr.Character
	return char and char:FindFirstChild('HumanoidRootPart')
end

local function Getdistancefromcharacter(pos)
	if typeof(pos) == 'Vector3' then
		return LocalPlayer:DistanceFromCharacter(pos)
	elseif typeof(pos) == 'CFrame' then
		return LocalPlayer:DistanceFromCharacter(pos.Position)
	end
	return math.huge
end

local function teleportfunc()
	local targetModel = _G.ControllingCreature or LocalPlayer.Character
	local originPart = targetModel and (targetModel:FindFirstChild('Head') or targetModel:FindFirstChild('CamPart') or targetModel:FindFirstChild('HumanoidRootPart'))
	local char = LocalPlayer.Character
	local camPart = char and char:FindFirstChild('CamPart')
	local hrp = targetModel and targetModel:FindFirstChild('HumanoidRootPart')

	if originPart and camPart and hrp then
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { targetModel }
		params.FilterType = Enum.RaycastFilterType.Exclude

		local result = Workspace:Raycast(originPart.Position, camPart.CFrame.LookVector * 5000, params)
		if result then
			hrp.CFrame = CFrame.new(result.Position.X, result.Position.Y + 5, result.Position.Z)
		end
	end
end

local function onTeleportAction(actionName, inputState)
	if actionName == 'Teleport(Z)' and inputState == Enum.UserInputState.Begin then
		teleportfunc()
	end
end

local function isWhitelisted(playerName)
	return table.find(WhitelistPlayers, playerName) ~= nil
end

-- Noclip helpers
local noclipConn = nil
local noclipDisabled = false

local function enableNoclip()
	if noclipConn then return end
	noclipDisabled = false
	noclipConn = RunService.Stepped:Connect(function()
		if not noclipDisabled and LocalPlayer.Character then
			for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
				if part:IsA('BasePart') and part.CanCollide and part.Name ~= floatName then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function disableNoclip()
	if not _G.NoclipToggle then
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
		noclipDisabled = true
	end
end

local function countToys(toyName)
	local count = 0
	for _, item in ipairs(SpawnedInToys:GetChildren()) do
		if item.Name == toyName then
			count += 1
		end
	end
	return count
end

local function CheckNetworkOwnerShipOnPart(part, returnOwnerObj)
	if typeof(part) == 'Instance' then
		local owner = part:FindFirstChild('PartOwner')
		if owner and owner.Value == LocalPlayer.Name then
			return returnOwnerObj and owner or true
		end
	end
	return false
end

local function CheckNetworkOwnerShipOnPlayer(player, returnOwnerObj)
	if typeof(player) == 'Instance' and player:IsA('Player') and player.Character then
		local head = player.Character:FindFirstChild('Head')
		local owner = head and head:FindFirstChild('PartOwner')
		if owner and owner.Value == LocalPlayer.Name then
			return returnOwnerObj and owner or true
		end
	end
	return false
end

local function SNOWship(part)
	local root = GetPlayerRoot()
	if typeof(part) == 'Instance' and part:IsA('BasePart') and root then
		if LocalPlayer:DistanceFromCharacter(part.Position) <= 30 then
			SetNetworkOwner:FireServer(part, lookAt(root.Position, part.Position))
		end
	end
end

local function IsPlayerInsideSafeZone(player)
	if typeof(player) == 'Instance' and player:IsA('Player') then
		local inPlotVal = player:FindFirstChild('InPlot')
		return inPlotVal and inPlotVal.Value == true
	end
	return false
end

local function IsPlayerFloating(player)
	local hum = player and player.Character and player.Character:FindFirstChildOfClass('Humanoid')
	return hum and hum.FloorMaterial == Enum.Material.Air
end

local function CheckPlayerVelocity(player)
	local hrp = player and player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	return hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
end

local function SNOWshipOnce(part)
	local root = GetPlayerRoot()
	if typeof(part) == 'Instance' and part:IsA('BasePart') and root then
		if CheckNetworkOwnerShipOnPart(part) then
			return true
		end
		if LocalPlayer:DistanceFromCharacter(part.Position) <= 30 then
			SetNetworkOwner:FireServer(part, lookAt(root.Position, part.Position))
		end
	end
	return false
end

local function SNOWshipTrack(part)
	local model = part and part.Parent
	if not (model and model:IsA('Model')) or not GetPlayerRoot() then
		return false
	end

	if not model:GetAttribute('CreatedConnected2') then
		model:SetAttribute('CreatedConnected2', true)
		model.DescendantAdded:Connect(function(desc)
			if desc.Name == 'PartOwner' then
				model:SetAttribute('OwnershipTrackConnected', desc.Value == LocalPlayer.Name)
			end
		end)
	end

	if model:GetAttribute('OwnershipTrackConnected') then
		return true
	end

	if LocalPlayer:DistanceFromCharacter(part.Position) <= 30 then
		SetNetworkOwner:FireServer(part, lookAt(GetPlayerRoot().Position, part.Position))
	end
	return false
end

local function SNOWshipOnceAndDelete(part)
	if not (typeof(part) == 'Instance' and part:IsA('BasePart')) or not GetPlayerRoot() then
		return
	end

	if CheckNetworkOwnerShipOnPart(part) then
		part:SetAttribute('Connected', true)
		DestroyGrabLine:FireServer(part)
		if not part:GetAttribute('CreatedConnected') then
			part:SetAttribute('CreatedConnected', true)
			part.ChildAdded:Connect(function(child)
				if child.Name == 'PartOwner' and child.Value ~= LocalPlayer.Name then
					part:SetAttribute('Connected', false)
				end
			end)
		end
	elseif LocalPlayer:DistanceFromCharacter(part.Position) <= 30 and not part:GetAttribute('Connected') then
		SetNetworkOwner:FireServer(part, lookAt(GetPlayerRoot().Position, part.Position))
	end
end

local function SNOWshipPlayer(player, callback)
	local root = GetPlayerRoot()
	local targetHRP = player and player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	if root and targetHRP then
		if CheckNetworkOwnerShipOnPlayer(player) then
			if type(callback) == 'function' then
				callback()
			end
			return true
		end
		if LocalPlayer:DistanceFromCharacter(targetHRP.Position) <= 30 then
			SetNetworkOwner:FireServer(targetHRP, lookAt(root.Position, targetHRP.Position))
		end
	end
	return false
end

local function SNOWshipPermanentPlayer(player, callback)
	local root = GetPlayerRoot()
	local firePart = player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') and player.Character.HumanoidRootPart:FindFirstChild('FirePlayerPart')
	if root and firePart then
		if type(callback) == 'function' then
			callback()
		end
		if LocalPlayer:DistanceFromCharacter(firePart.Position) <= 30 then
			SetNetworkOwner:FireServer(firePart, lookAt(root.Position, firePart.Position))
			return true
		end
	end
	return false
end

_G.TP_Priority = 0

local function ChangeActivityPriority(prio)
	if _G.TP_Priority <= prio or prio == 0 then
		_G.TP_Priority = prio
		return true
	end
	return false
end

local function TeleportPlayer(targetCFrame, prio)
	if (prio == nil and 0 or prio) == _G.TP_Priority then
		local char = GetPlayerCharacter()
		local hrp = char and char:FindFirstChild('HumanoidRootPart')
		local hum = char and char:FindFirstChildOfClass('Humanoid')
		if hrp and hum and not _G.TeleportingToNetworkOwnership and typeof(targetCFrame) == 'CFrame' then
			hrp.CFrame = hrp.CFrame.Rotation + targetCFrame.Position
			if hum.SeatPart == nil or tostring(hum.SeatPart.Parent) ~= 'CreatureBlobman' then
				hum.Sit = false
			end
		end
	end
end

-- Anchor & Compile state
local AnchoredObjects = {}
local CompiledGroups = {}
local CompileGroups_Dropdown = nil

local anchorEffectTemplate = Instance.new('Attachment')
local anchorSound = Instance.new('Sound', anchorEffectTemplate)
anchorSound.Name = 'soundeffect'
anchorSound.SoundId = 'rbxassetid://1091083826'

local anchorParticles = Instance.new('ParticleEmitter', anchorEffectTemplate)
anchorParticles.Name = 'particle'
anchorParticles.LightInfluence = 1
anchorParticles.Lifetime = NumberRange.new(2, 3)
anchorParticles.Texture = 'rbxassetid://15668608167'
anchorParticles.Transparency = NumberSequence.new(0, 1)
anchorParticles.Speed = NumberRange.new(6, 6)
anchorParticles.Size = NumberSequence.new(0, 1)
anchorParticles.SpreadAngle = Vector2.new(360, 360)
anchorParticles.Rate = 20
anchorParticles.Enabled = false

local function anchorobjecteffect(part)
	if not part then return end
	local clone = anchorEffectTemplate:Clone()
	clone.Parent = part
	if clone:FindFirstChild('soundeffect') then clone.soundeffect:Play() end
	if clone:FindFirstChild('particle') then clone.particle:Emit(25) end
	Debris:AddItem(clone, 4)
end

local function ChangeSBstate(sb, state)
	if typeof(sb) == 'Instance' and sb:IsA('SelectionBox') then
		if state == 'Anchored' then
			sb.Color3 = Color3.fromRGB(22, 2, 138)
			sb.SurfaceColor3 = Color3.fromRGB(38, 85, 172)
		elseif state == 'Glue' then
			sb.Color3 = Color3.fromRGB(242, 124, 17)
			sb.SurfaceColor3 = Color3.fromRGB(253, 243, 130)
		elseif state == 'GluePrimary' then
			sb.Color3 = Color3.fromRGB(0, 85, 0)
			sb.SurfaceColor3 = Color3.fromRGB(89, 225, 65)
		else
			sb.Color3 = Color3.fromRGB(139, 0, 0)
			sb.SurfaceColor3 = Color3.fromRGB(193, 0, 0)
		end
	end
end

local function DisconnectObject(obj)
	local data = AnchoredObjects[obj]
	if data then
		if data.BodyPosition then data.BodyPosition.Parent = obj end
		if data.BodyGyro then data.BodyGyro.Parent = obj end
		data.PartAnchored = nil
		if data.SB then data.SB.Visible = false end
		for _, conn in pairs(data.Connections or {}) do
			if typeof(conn) == 'RBXScriptConnection' then
				conn:Disconnect()
			end
		end
		if typeof(obj) == 'Instance' then
			obj:SetAttribute('IsAnchored', nil)
			obj:SetAttribute('AnchorOwnership', nil)
			obj:SetAttribute('Glue', nil)
			obj:SetAttribute('GluePrimary', nil)
		end
		AnchoredObjects[obj] = nil
	end
end

local function unAnchorObject(part)
	if typeof(part) == 'Instance' and part.Parent and (part.Parent:IsA('Model') or part.Parent:IsA('Folder')) then
		local target = part.Parent
		local isAnchored = target:GetAttribute('IsAnchored')
		local gluePrimary = target:GetAttribute('GluePrimary')

		if not target:IsA('Folder') and target ~= Workspace then
			part = target
		end

		local data = AnchoredObjects[part]
		if data and isAnchored then
			if data.BodyPosition then data.BodyPosition.Parent = part end
			if data.BodyGyro then data.BodyGyro.Parent = part end
			data.PartAnchored = nil

			if gluePrimary then
				ChangeSBstate(data.SB, 'GluePrimary')
			elseif data.SB then
				data.SB.Visible = false
			end

			for _, conn in pairs(data.Connections or {}) do
				if typeof(conn) == 'RBXScriptConnection' then
					conn:Disconnect()
				end
			end

			part:SetAttribute('IsAnchored', false)
			part:SetAttribute('AnchorOwnership', false)

			if not gluePrimary then
				AnchoredObjects[part] = nil
			end
		end
	end
end

local function setanchorObject(part)
	if typeof(part) ~= 'Instance' or not part:IsA('BasePart') or not part.Parent then
		return
	end
	if not (part.Parent:IsA('Model') or part.Parent:IsA('Folder')) then
		return
	end

	local model = part.Parent
	if model:IsA('Folder') or model == Workspace then
		model = part
	end

	if model:GetAttribute('IsAnchored') or model:GetAttribute('Glue') then
		unAnchorObject(part)
		return
	end

	local bp = model:FindFirstChild('AnchorPositionBody') or part:FindFirstChild('AnchorPositionBody') or Instance.new('BodyPosition')
	local bg = model:FindFirstChild('AnchorGyroBody') or part:FindFirstChild('AnchorGyroBody') or Instance.new('BodyGyro')
	local sb = model:FindFirstChild('ObjectState') or Instance.new('SelectionBox')
	local conns = {}
	local maxForce = Vector3.new(math.huge, math.huge, math.huge)
	local zeroForce = Vector3.new(0, 0, 0)
	local homePos = part.Position
	local isNPC = part.Parent:FindFirstChild('Head') and part.Parent:FindFirstChildOfClass('Humanoid') and not Players:GetPlayerFromCharacter(part.Parent)
	local isChar = part.Parent:FindFirstChild('Head') and part.Parent:FindFirstChildOfClass('Humanoid') and Players:GetPlayerFromCharacter(part.Parent) ~= nil

	bp.Name = 'AnchorPositionBody'
	bp.Position = homePos
	bp.P = 40000
	bp.D = 950
	bp.Parent = part

	bg.Name = 'AnchorGyroBody'
	bg.CFrame = part.CFrame
	bg.P = 40000
	bg.D = 950
	bg.Parent = part

	sb.Name = 'ObjectState'
	sb.LineThickness = 0.025
	sb.SurfaceTransparency = 0.56
	sb.Transparency = 0
	sb.Visible = true
	sb.Parent = model
	sb.Adornee = model

	local function onOwned()
		if model:GetAttribute('IsAnchored') or model:GetAttribute('Glue') then
			bg.MaxTorque = maxForce
			bp.MaxForce = maxForce
		end
		if model:GetAttribute('GluePrimary') and not model:GetAttribute('IsAnchored') then
			ChangeSBstate(sb, 'GluePrimary')
		elseif model:GetAttribute('Glue') and not model:GetAttribute('IsAnchored') then
			ChangeSBstate(sb, 'Glue')
		else
			ChangeSBstate(sb, 'Anchored')
		end
	end

	local function onLostOwnership()
		bg.MaxTorque = zeroForce
		bp.MaxForce = zeroForce
		ChangeSBstate(sb)
		model:SetAttribute('AnchorOwnership', false)
	end

	conns[1] = model.DescendantAdded:Connect(function(desc)
		if desc.Name == 'PartOwner' then
			if desc.Value == LocalPlayer.Name then
				onOwned()
			else
				onLostOwnership()
			end
		end
	end)

	conns[2] = model.DescendantRemoving:Connect(function(desc)
		if desc.Name == 'PartOwner' and desc.Value == LocalPlayer.Name then
			if isNPC then
				onOwned()
			elseif isChar then
				onLostOwnership()
			end
		end
	end)

	task.spawn(function()
		while bp.Parent and not model:GetAttribute('Glue') do
			if model:GetAttribute('IsAnchored') then
				bg.MaxTorque = maxForce
				bp.MaxForce = maxForce
			else
				bg.MaxTorque = zeroForce
				bp.MaxForce = zeroForce
			end
			bp.Position = homePos + Vector3.new(0, 0.001, 0)
			task.wait()
			bp.Position = homePos
		end
	end)

	AnchoredObjects[model] = {
		BodyPosition = bp,
		BodyGyro = bg,
		PartAnchored = part,
		SB = sb,
		Connections = conns,
		Model = model,
	}

	anchorobjecteffect(part)
	model:SetAttribute('IsAnchored', true)
	onOwned()
end

local function autosetownership()
	for obj, data in pairs(AnchoredObjects) do
		if typeof(data.PartAnchored) == 'Instance' and typeof(obj) == 'Instance' and not obj:GetAttribute('AnchorOwnership') then
			local part = data.PartAnchored
			local model = data.Model
			if model and model:FindFirstChildOfClass('Humanoid') then
				part = model:FindFirstChild('Head') or part
			end
			if part and SNOWshipOnce(part) and model then
				model:SetAttribute('AnchorOwnership', true)
			end
		end
	end
end

local function anchorfunc()
	local grabParts = Workspace:FindFirstChild('GrabParts')
	local part1 = grabParts and grabParts:FindFirstChild('GrabPart') and grabParts.GrabPart:FindFirstChild('WeldConstraint') and grabParts.GrabPart.WeldConstraint.Part1
	if part1 and not part1:IsDescendantOf(Workspace.Map) and not part1.Anchored then
		setanchorObject(part1)
	end
end

local function anchorobject(actionName, inputState)
	if actionName == 'AnchorK' and inputState == Enum.UserInputState.Begin then
		anchorfunc()
	end
end

local function IsHoldingAnchoredPart()
	local grabParts = Workspace:FindFirstChild('GrabParts')
	local part1 = grabParts and grabParts:FindFirstChild('GrabPart') and grabParts.GrabPart:FindFirstChild('WeldConstraint') and grabParts.GrabPart.WeldConstraint.Part1
	if part1 then
		for anchoredModel, data in pairs(AnchoredObjects) do
			if typeof(anchoredModel) == 'Instance' and part1:IsDescendantOf(anchoredModel) then
				return data.Model
			end
		end
	end
	return nil
end

local function IsInCompileGroup(model)
	for _, grp in ipairs(CompiledGroups) do
		if grp.primaryPart then
			for _, member in pairs(grp.group) do
				local m = member.model
				if m and m == model and (m:GetAttribute('Glue') or m:GetAttribute('GluePrimary')) and not m:GetAttribute('IsAnchored') then
					return true
				end
			end
		end
	end
	return false
end

local function CheckPrimaryPartOnCompileGroup(model)
	for _, grp in ipairs(CompiledGroups) do
		if grp.primaryPart and grp.primaryPart == model and grp.primaryPart:GetAttribute('IsAnchored') then
			return true
		end
	end
	return false
end

local function ObjectStateBillboardGUI(target, stateText)
	if typeof(target) ~= 'Instance' then return end
	local gui = target:FindFirstChild('ObjectText')
	if not gui then
		gui = Instance.new('BillboardGui')
		gui.Name = 'ObjectText'
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Active = true
		gui.Adornee = target
		gui.AlwaysOnTop = true
		gui.Size = UDim2.new(3, 0, 3, 0)
		gui.Enabled = false
		gui.Parent = target

		local lbl = Instance.new('TextLabel')
		lbl.Name = 'State'
		lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
		lbl.Size = UDim2.new(1, 5, 0.34, 5)
		lbl.Font = Enum.Font.SourceSans
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextScaled = true
		lbl.TextStrokeTransparency = 0
		lbl.TextWrapped = true
		lbl.Parent = gui

		local sizeConstraint = Instance.new('UITextSizeConstraint')
		sizeConstraint.MaxTextSize = 28
		sizeConstraint.MinTextSize = 15
		sizeConstraint.Parent = lbl

		local aspect = Instance.new('UIAspectRatioConstraint')
		aspect.AspectRatio = 1.043
		aspect.Parent = gui
	end

	if type(stateText) ~= 'string' then
		gui.Enabled = false
	else
		local lbl = gui:FindFirstChild('State')
		if lbl then
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			if stateText == 'Anchored' then
				lbl.TextColor3 = Color3.fromRGB(112, 186, 255)
				lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 127)
			elseif stateText == 'Disconnected' then
				lbl.TextColor3 = Color3.fromRGB(255, 0, 0)
				lbl.TextStrokeColor3 = Color3.fromRGB(67, 0, 0)
			end
			lbl.Text = stateText
		end
		gui.Enabled = true
	end
end

local function CreateNoCollisionConstraintsCompile(primaryPart)
	for _, grp in ipairs(CompiledGroups) do
		if grp.primaryPart and grp.primaryPart == primaryPart then
			for _, member in pairs(grp.group) do
				local m = member.model
				if m and m:IsA('Model') then
					for _, partA in ipairs(m:GetChildren()) do
						if partA:IsA('BasePart') then
							for _, otherMember in pairs(grp.group) do
								local otherModel = otherMember.model
								if otherModel and otherModel:IsA('Model') then
									for _, partB in ipairs(otherModel:GetChildren()) do
										if partB:IsA('BasePart') then
											local ncc = Instance.new('NoCollisionConstraint')
											ncc.Part0 = partA
											ncc.Part1 = partB
											ncc.Enabled = true
											ncc.Parent = partA
											table.insert(grp.Nc_Group, ncc)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

local function updateCompiledGroup(primaryPart)
	for _, grp in ipairs(CompiledGroups) do
		if grp.primaryPart and grp.primaryPart == primaryPart then
			local anchorPart = primaryPart:IsA('Model') and (primaryPart.PrimaryPart or primaryPart:FindFirstChildOfClass('BasePart'))
				or (primaryPart:IsA('BasePart') and primaryPart)
			if anchorPart then
				for _, member in ipairs(grp.group) do
					if member.model ~= primaryPart then
						local bp = member.bodypos
						local bg = member.bodygyro
						local targetCF = anchorPart.CFrame * member.offset
						if bp then
							bp.P = 40000
							bp.D = 200
							bp.Position = targetCF.Position
						end
						if bg then
							bg.P = 40000
							bg.D = 200
							bg.CFrame = targetCF
						end
					end
				end
			end
		end
	end
end

local function RemoveCompileGroup(primaryPart)
	for i = #CompiledGroups, 1, -1 do
		local grp = CompiledGroups[i]
		if grp.primaryPart and grp.primaryPart == primaryPart then
			for _, ncc in pairs(grp.Nc_Group or {}) do
				if typeof(ncc) == 'Instance' then ncc:Destroy() end
			end
			ObjectStateBillboardGUI(primaryPart)
			for _, conn in pairs(grp.gC or {}) do
				if typeof(conn) == 'RBXScriptConnection' then conn:Disconnect() end
			end
			for _, member in pairs(grp.group or {}) do
				local m = member.model
				if typeof(m) == 'Instance' then
					m:SetAttribute('Glue', false)
					m:SetAttribute('GluePrimary', false)
					m:SetAttribute('IsAnchored', false)
				end
			end
			table.remove(CompiledGroups, i)
		end
	end
end

local function RemoveGroupCompileFromName(groupName)
	for _, grp in ipairs(CompiledGroups) do
		if grp.gN == groupName then
			local primary = grp.primaryPart
			for _, member in pairs(grp.group or {}) do
				DisconnectObject(member.model)
			end
			RemoveCompileGroup(primary)
		end
	end
end

local function updateCompileGroupsDropdown(dropdown)
	if not dropdown then return end
	local names = {}
	for _, grp in ipairs(CompiledGroups) do
		table.insert(names, grp.gN)
	end
	pcall(function()
		dropdown:Refresh(names, true)
	end)
end

local function compileAnchoredObjects()
	local count = 0
	for obj in pairs(AnchoredObjects) do
		if not IsInCompileGroup(obj) then
			count += 1
		end
	end

	if count == 0 then
		Notify('No anchored parts found', 'Error', 'rbxassetid://4483345998')
		return
	elseif count == 1 then
		Notify('Needs at least 2 anchored objects', 'Error', 'rbxassetid://4483345998')
		return
	end

	local primary = IsHoldingAnchoredPart()
	if not primary then
		Notify('You need to hold one of your anchored object', 'Error', 'rbxassetid://4483345998')
		return
	end

	local primaryBase = primary:IsA('Model') and (primary.PrimaryPart or primary:FindFirstChildOfClass('BasePart'))
		or (primary:IsA('BasePart') and primary)
	if not primaryBase then
		Notify('Selected object has no valid BasePart', 'Error', 'rbxassetid://4483345998')
		return
	end

	Notify('Compiled ' .. count .. ' Toys together', 'Success', 'rbxassetid://4483345998')

	for obj in pairs(AnchoredObjects) do
		if not IsInCompileGroup(obj) and CheckPrimaryPartOnCompileGroup(obj) then
			RemoveCompileGroup(obj)
		end
	end

	local groupName = 'Group ' .. (#CompiledGroups + 1)
	local groupMembers = {}
	local groupConns = {}

	for _, data in pairs(AnchoredObjects) do
		local model = data.Model
		if not IsInCompileGroup(model) and data.PartAnchored then
			local offset = primaryBase.CFrame:ToObjectSpace(data.PartAnchored.CFrame)
			model:SetAttribute('IsAnchored', false)

			if model == primary then
				if data.BodyGyro then data.BodyGyro.MaxTorque = Vector3.new() end
				if data.BodyPosition then data.BodyPosition.MaxForce = Vector3.new() end
				model:SetAttribute('GluePrimary', true)
				ChangeSBstate(data.SB, 'GluePrimary')
			else
				model:SetAttribute('Glue', true)
				ChangeSBstate(data.SB, 'Glue')
			end

			table.insert(groupMembers, {
				model = model,
				part = data.PartAnchored,
				offset = offset,
				bodypos = data.BodyPosition,
				bodygyro = data.BodyGyro,
			})
		end
	end

	table.insert(CompiledGroups, {
		primaryPart = primary,
		group = groupMembers,
		Nc_Group = {},
		gC = groupConns,
		gN = groupName,
	})

	CreateNoCollisionConstraintsCompile(primary)
	ObjectStateBillboardGUI(primary, groupName)

	local hbConn = RunService.Heartbeat:Connect(function()
		updateCompiledGroup(primary)
	end)
	table.insert(groupConns, hbConn)
	updateCompileGroupsDropdown(CompileGroups_Dropdown)
end

-- Safe defaults for toggles/sliders
_G.SilentAim = false
_G.FutherExtend = false
_G.FireBomb = false
_G.ControllingCreature = nil
_G.FlingStrength = 400
_G.FlingTarget = 1
_G.AnchorTarget = 1
_G.TornadoShape = 'Blackhole'
_G.TornadoFollowType = 'Player'
_G.TornadoTarget = 1
_G.Strength = 400
_G.CounterMode = 'Repulsion'
_G.PlayerToTeleportDirection = 'Behind'
_G.LineColorChangeValue = Color3.fromRGB(255, 0, 0)
_G.AntiRagdoll = false
_G.AntiGrab = false
_G.AntiVoid = false
_G.AutoStruggle = false
_G.ESPEnabled = false
_G.FlingAura = false
_G.AttractAura = false
_G.LoopFlingEnabled = false
_G.AutoClaimPlot = false

local silentAimRange = 50
local explosionInterval = 0
local IncreaseLineExtend = 0
local TeleportPlayerOffset = 1
local TornadoOffset = 10
local TornadoHeight = 10
local TornadoSpeed = 0.01
local Lag_Intensity = 150
local Multiplier = 0.25
local SelectedTargetPlayer = nil
local SelectedLoopPlayer = nil
local SelectedWhitelistPlayer = nil
local SelectedTeleportLocation = 'Spawn'

local TeleportLocations = {
	Spawn = CFrame.new(0, 10, 0),
	Hole = CFrame.new(100, -10, 100),
	Factory = CFrame.new(-150, 15, 80),
}

-- Poison parts repositioned safely
local poisonBig = Workspace:FindFirstChild('Map') and Workspace.Map:FindFirstChild('Hole') and Workspace.Map.Hole:FindFirstChild('PoisonBigHole') and Workspace.Map.Hole.PoisonBigHole:FindFirstChild('PoisonHurtPart')
local poisonSmall = Workspace:FindFirstChild('Map') and Workspace.Map:FindFirstChild('Hole') and Workspace.Map.Hole:FindFirstChild('PoisonSmallHole') and Workspace.Map.Hole.PoisonSmallHole:FindFirstChild('PoisonHurtPart')
local poisonFactory = Workspace:FindFirstChild('Map') and Workspace.Map:FindFirstChild('FactoryIsland') and Workspace.Map.FactoryIsland:FindFirstChild('PoisonContainer') and Workspace.Map.FactoryIsland.PoisonContainer:FindFirstChild('PoisonHurtPart')

for _, pPart in ipairs({ poisonBig, poisonSmall, poisonFactory }) do
	if pPart and pPart:IsA('BasePart') then
		pPart.Size = Vector3.new(2, 2, 2)
		pPart.Position = Vector3.new(0, -50, 0)
	end
end

local function SetModelProperties(model)
	if typeof(model) == 'Instance' then
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA('BasePart') then
				desc.CanCollide = false
			end
		end
	end
end

local function SetAimPart(aimModel)
	if typeof(aimModel) ~= 'Instance' then return end
	for _, desc in ipairs(aimModel:GetDescendants()) do
		if desc:IsA('BasePart') then
			desc.CanQuery = false
			desc.Transparency = 1
			desc.CanCollide = false
		elseif desc:IsA('SurfaceGui') then
			desc.Enabled = false
		end
	end

	local center = aimModel:WaitForChild('Center', 1)
	if center then
		local bgui = Instance.new('BillboardGui')
		bgui.ClipsDescendants = true
		bgui.Brightness = 3.5
		bgui.Size = UDim2.new(1.5, 18, 1.5, 18)
		bgui.Adornee = center
		bgui.AlwaysOnTop = true
		bgui.Active = true
		bgui.Parent = center

		local img = Instance.new('ImageLabel')
		img.BorderSizePixel = 0
		img.BackgroundTransparency = 1
		img.Image = 'rbxassetid://12717676115'
		img.Size = UDim2.new(1, 0, 1, 0)
		img.ImageColor3 = Color3.new(0.333333, 1, 0)
		img.Parent = bgui

		local sound = Instance.new('Sound')
		sound.SoundId = 'rbxassetid://9119713951'
		sound.PlaybackSpeed = 1.5
		sound.Parent = Workspace

		local wasReady = false
		task.spawn(function()
			while aimModel.Parent do
				if _G.CanExplodeBombs and not wasReady then
					img.ImageColor3 = Color3.new(0.333333, 1, 0)
					sound:Play()
					wasReady = true
				elseif not _G.CanExplodeBombs and wasReady then
					wasReady = false
					img.ImageColor3 = Color3.new(1, 0, 0)
				end
				task.wait()
			end
			sound:Destroy()
		end)
	end
end

local function SpiralFormulaCalculation(origin, theta, radius, heightScale)
	if _G.TornadoShape == 'Tornado' then
		return Vector3.new(
			origin.X + 15 * heightScale * math.sin(theta),
			origin.Y + 20 + heightScale * 2 + math.sin(theta * 0.5) * 40 + math.random(-20, 20),
			origin.Z + 15 * heightScale * math.cos(theta)
		)
	else
		local r = math.max(radius, 1)
		return Vector3.new(
			origin.X + r * math.sin(theta),
			origin.Y + TornadoHeight,
			origin.Z + r * math.cos(theta)
		)
	end
end

local function FlingTargetPlayer(targetName)
	local username = extractUsername(targetName)
	local targetPlr = username and Players:FindFirstChild(username)
	local targetHRP = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild('HumanoidRootPart')
	local myRoot = GetPlayerRoot()
	if not targetHRP or not myRoot then
		Notify('Target or character not found', 'Error')
		return
	end
	SetNetworkOwner:FireServer(targetHRP, lookAt(myRoot.Position, targetHRP.Position))
	task.wait(0.08)
	local bv = Instance.new('BodyVelocity')
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity = (targetHRP.Position - myRoot.Position).Unit * (_G.FlingStrength or 400) + Vector3.new(0, 150, 0)
	bv.Parent = targetHRP
	Debris:AddItem(bv, 0.2)
end

-- Build UI Window & Tabs
local Window = UILib:MakeWindow({
	Name = HUB_TITLE,
	HidePremium = true,
	SaveConfig = true,
	ConfigFolder = 'FTGS_M4nace_Wump_Config',
	IntroEnabled = false,
	KeyToOpenWindow = 'M',
	FreeMouse = true,
})

local CombatTab = Window:MakeTab({ Name = 'Combat', Icon = 'rbxassetid://7485051715', PremiumOnly = false })
local BlobmanTab = Window:MakeTab({ Name = 'Blobman Grab', Icon = 'rbxassetid://7734058599', PremiumOnly = false })
local InvincibilityTab = Window:MakeTab({ Name = 'Invincibility', Icon = 'rbxassetid://7734056608', PremiumOnly = false })
local PlayerTab = Window:MakeTab({ Name = 'Player', Icon = 'rbxassetid://7743871002', PremiumOnly = false })
local EspTab = Window:MakeTab({ Name = 'ESP', Icon = 'rbxassetid://7733774602', PremiumOnly = false })
local ExplosionsTab = Window:MakeTab({ Name = 'Explosions', Icon = 'rbxassetid://17837704089', PremiumOnly = false })
local TeleportTab = Window:MakeTab({ Name = 'Teleport', Icon = 'rbxassetid://7733992829', PremiumOnly = false })
local CustomLineTab = Window:MakeTab({ Name = 'Custom Line', Icon = 'rbxassetid://7734022107', PremiumOnly = false })
local GrabAurasTab = Window:MakeTab({ Name = 'Grab Auras', Icon = 'rbxassetid://7733955740', PremiumOnly = false })
local KeybindsTab = Window:MakeTab({ Name = 'Keybinds', Icon = 'rbxassetid://11710306232', PremiumOnly = false })
local LoopPlayersTab = Window:MakeTab({ Name = 'Loop Players', Icon = 'rbxassetid://7733964640', PremiumOnly = false })
local AutoTab = Window:MakeTab({ Name = 'Auto', Icon = 'rbxassetid://7733916988', PremiumOnly = false })
local MiscTab = Window:MakeTab({ Name = 'Misc', Icon = 'rbxassetid://7733917120', PremiumOnly = false })
local ConfigTab = Window:MakeTab({ Name = 'Config', Icon = 'rbxassetid://7734053495', PremiumOnly = false })
Window:MakeTab({ Name = 'Premium Info', Icon = 'rbxassetid://7734053495', PremiumOnly = false })
local CreditsTab = Window:MakeTab({ Name = 'Credits', Icon = 'rbxassetid://7733687281', PremiumOnly = false })

-- 1. Combat Tab
do
	local flingSec = CombatTab:AddSection({ Name = 'Target Fling' })
	local targetDropdown = flingSec:AddDropdown({
		Name = 'Select Player',
		Default = '',
		Options = {},
		Callback = function(val)
			SelectedTargetPlayer = val
		end,
	})
	refreshPlayerDropdown(targetDropdown, false)

	flingSec:AddButton({
		Name = 'Refresh Players',
		Callback = function()
			refreshPlayerDropdown(targetDropdown, false)
		end,
	})

	flingSec:AddSlider({
		Name = 'Fling Strength',
		Min = 50,
		Max = 1500,
		Default = 400,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 25,
		ValueName = 'Power',
		Callback = function(v) _G.FlingStrength = v end,
		Save = true,
		Flag = 'flingstrength_slider',
	})

	flingSec:AddButton({
		Name = 'Fling Selected Player',
		Callback = function()
			FlingTargetPlayer(SelectedTargetPlayer)
		end,
	})

	local tornadoSec = CombatTab:AddSection({ Name = 'Tornado / Blackhole' })
	tornadoSec:AddDropdown({
		Name = 'Shape Mode',
		Default = 'Blackhole',
		Options = { 'Blackhole', 'Tornado' },
		Callback = function(v) _G.TornadoShape = v end,
	})
	tornadoSec:AddSlider({
		Name = 'Tornado Height',
		Min = 1,
		Max = 60,
		Default = 10,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 1,
		ValueName = 'Studs',
		Callback = function(v) TornadoHeight = v end,
	})
end

-- 2. Blobman Grab Tab
do
	local blobSec = BlobmanTab:AddSection({ Name = 'Blobman & Grab Controls' })
	blobSec:AddButton({
		Name = 'Anchor Held Object',
		Callback = anchorfunc,
	})
	blobSec:AddButton({
		Name = 'Compile Anchored Group',
		Callback = compileAnchoredObjects,
	})
	blobSec:AddButton({
		Name = 'Unanchor All Objects',
		Callback = function()
			for _, data in pairs(AnchoredObjects) do
				if typeof(data.PartAnchored) == 'Instance' then
					unAnchorObject(data.PartAnchored)
				end
			end
		end,
	})
end

-- 3. Invincibility Tab
do
	local protSec = InvincibilityTab:AddSection({ Name = 'Protection' })
	protSec:AddToggle({
		Name = 'Anti-Ragdoll',
		Default = false,
		Callback = function(v) _G.AntiRagdoll = v end,
		Save = true,
		Flag = 'antiragdoll_toggle',
	})
	protSec:AddToggle({
		Name = 'Anti-Grab Struggle',
		Default = false,
		Callback = function(v) _G.AutoStruggle = v end,
		Save = true,
		Flag = 'autostruggle_toggle',
	})
	protSec:AddToggle({
		Name = 'Anti-Void',
		Default = false,
		Callback = function(v) _G.AntiVoid = v end,
		Save = true,
		Flag = 'antivoid_toggle',
	})
end

-- 4. Player Tab
do
	local moveSec = PlayerTab:AddSection({ Name = 'Movement' })
	moveSec:AddToggle({
		Name = 'Super Speed',
		Default = false,
		Callback = function(v) _G.SuperSpeed = v end,
		Save = true,
		Flag = 'superspeed_toggle',
	})
	moveSec:AddSlider({
		Name = 'Speed Multiplier',
		Min = 0.05,
		Max = 2,
		Default = 0.25,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 0.05,
		ValueName = 'x',
		Callback = function(v) Multiplier = v end,
		Save = true,
		Flag = 'speedmult_slider',
	})
	moveSec:AddToggle({
		Name = 'Infinite Jump',
		Default = false,
		Callback = function(v) _G.InfiniteJump = v end,
		Save = true,
		Flag = 'infjump_toggle',
	})
	moveSec:AddToggle({
		Name = 'Noclip',
		Default = false,
		Callback = function(v)
			_G.NoclipToggle = v
			if v then
				enableNoclip()
			else
				disableNoclip()
			end
		end,
		Save = true,
		Flag = 'noclip_toggle',
	})
end

-- 5. ESP Tab
do
	local espSec = EspTab:AddSection({ Name = 'Player ESP' })
	espSec:AddToggle({
		Name = 'Player Highlights',
		Default = false,
		Callback = function(v) _G.ESPEnabled = v end,
		Save = true,
		Flag = 'esp_toggle',
	})
end

-- 6. Explosions Tab
do
	local expSec = ExplosionsTab:AddSection({ Name = 'Bomb & Explosion Settings' })
	expSec:AddSlider({
		Name = 'Explosion Interval',
		Min = 0,
		Max = 5,
		Default = 0,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 0.1,
		ValueName = 'sec',
		Callback = function(v) explosionInterval = v end,
		Save = true,
		Flag = 'expinterval_slider',
	})
end

-- 7. Teleport Tab
do
	local tpSec = TeleportTab:AddSection({ Name = 'Quick Teleports' })
	tpSec:AddDropdown({
		Name = 'Location',
		Default = 'Spawn',
		Options = { 'Spawn', 'Hole', 'Factory' },
		Callback = function(v) SelectedTeleportLocation = v end,
	})
	tpSec:AddButton({
		Name = 'Teleport to Location',
		Callback = function()
			local cf = TeleportLocations[SelectedTeleportLocation]
			if cf then
				TeleportPlayer(cf, 0)
			end
		end,
	})
	tpSec:AddButton({
		Name = 'Aim Raycast Teleport',
		Callback = teleportfunc,
	})
end

-- 8. Custom Line Tab
do
	local extSec = CustomLineTab:AddSection({ Name = 'Line Extender' })
	extSec:AddToggle({
		Name = 'Further Extend',
		Default = false,
		Callback = function(v) _G.FutherExtend = v end,
		Save = true,
		Flag = 'FurtherLineExtend_toggle',
	})
	extSec:AddSlider({
		Name = 'Increase Extend',
		Min = 3,
		Max = 25,
		Default = 3,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 1,
		ValueName = 'Ammount',
		Callback = function(v) IncreaseLineExtend = v end,
		Save = true,
		Flag = 'FurtherLineExtend_slider',
	})

	local lineColors = table.create(10, Color3.new(1, 0, 0))
	local colorSec = CustomLineTab:AddSection({ Name = 'Change your entire line color' })

	colorSec:AddColorpicker({
		Name = 'Choose the color',
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(col)
			_G.LineColorChangeValue = col
		end,
		Save = true,
		Flag = 'changelinecolor_picker',
	})

	colorSec:AddButton({
		Name = 'Apply Colors',
		Callback = function()
			local col = _G.LineColorChangeValue or Color3.fromRGB(255, 0, 0)
			for idx = 1, #lineColors do
				if idx == 1 then
					lineColors[idx] = ColorSequence.new(col)
				else
					lineColors[idx] = col
				end
			end
			UpdateLineColorsEvent:FireServer(unpack(lineColors))
		end,
	})
end

-- 9. Grab Auras Tab
do
	local auraSec = GrabAurasTab:AddSection({ Name = 'Auras' })
	auraSec:AddToggle({
		Name = 'Fling Aura',
		Default = false,
		Callback = function(v) _G.FlingAura = v end,
		Save = true,
		Flag = 'flingaura_toggle',
	})
	auraSec:AddToggle({
		Name = 'Attract Aura',
		Default = false,
		Callback = function(v) _G.AttractAura = v end,
		Save = true,
		Flag = 'attractaura_toggle',
	})
end

-- 10. Keybinds Tab
do
	local tpBindSec = KeybindsTab:AddSection({ Name = 'Teleport' })
	local spawnBindSec = KeybindsTab:AddSection({ Name = 'Spawn Toy' })
	local anchorBindSec = KeybindsTab:AddSection({ Name = 'Anchor Objects' })
	local compileBindSec = KeybindsTab:AddSection({ Name = 'Compile Objects' })
	local ctrlBindSec = KeybindsTab:AddSection({ Name = 'Control Player/NPC' })

	tpBindSec:AddToggle({
		Name = 'Teleport (Z)',
		Default = false,
		Callback = function(enabled)
			if enabled then
				ContextActionService:BindAction('Teleport(Z)', onTeleportAction, false, Enum.KeyCode.Z)
			else
				ContextActionService:UnbindAction('Teleport(Z)')
			end
		end,
		Save = true,
		Flag = 'teleportbind_toggle',
	})

	spawnBindSec:AddDropdown({
		Name = 'Select Toy',
		Default = 'Pallet',
		Options = { 'Pallet', 'BombMissile' },
		Callback = function(choice)
			_G.SelectedToy = (choice == 'Pallet') and 'PalletLightBrown' or choice
		end,
		Save = true,
		Flag = 'selecttoy_dropdown',
	})

	spawnBindSec:AddToggle({
		Name = 'Spawn Toy (TAB)',
		Default = false,
		Callback = function(enabled)
			if enabled then
				ContextActionService:BindAction('Spawn Toy (TAB)', onSpawnToyAction, false, Enum.KeyCode.Tab)
			else
				ContextActionService:UnbindAction('Spawn Toy (TAB)')
			end
		end,
		Save = true,
		Flag = 'spawntoy_toggle',
	})

	anchorBindSec:AddToggle({
		Name = 'Anchor (K)',
		Default = false,
		Callback = function(enabled)
			if enabled then
				ContextActionService:BindAction('AnchorK', anchorobject, false, Enum.KeyCode.K)
			else
				ContextActionService:UnbindAction('AnchorK')
			end
		end,
		Save = true,
		Flag = 'anchorbind_toggle',
	})

	anchorBindSec:AddButton({
		Name = 'Unanchor All',
		Callback = function()
			for _, data in pairs(AnchoredObjects) do
				if typeof(data.PartAnchored) == 'Instance' then
					unAnchorObject(data.PartAnchored)
				end
			end
		end,
	})

	compileBindSec:AddButton({
		Name = 'Compile New Group',
		Callback = compileAnchoredObjects,
	})

	CompileGroups_Dropdown = compileBindSec:AddDropdown({
		Name = 'Groups',
		Default = '',
		Options = { '' },
		Callback = function(grp)
			_G.CompileGroupSelected = grp
		end,
	})

	compileBindSec:AddButton({
		Name = 'Delete Group',
		Callback = function()
			if _G.CompileGroupSelected then
				RemoveGroupCompileFromName(_G.CompileGroupSelected)
				updateCompileGroupsDropdown(CompileGroups_Dropdown)
			end
		end,
	})

	ctrlBindSec:AddToggle({
		Name = 'Control (C)',
		Default = false,
		Callback = function(enabled)
			if enabled then
				ContextActionService:BindAction('Control(C)', function(name, state)
					if name == 'Control(C)' and state == Enum.UserInputState.Begin then
						_G.ControllingCreature = nil
					end
				end, false, Enum.KeyCode.C)
			else
				ContextActionService:UnbindAction('Control(C)')
			end
		end,
		Save = true,
		Flag = 'controlbind_toggle',
	})
end

-- 11. Loop Players Tab
do
	local loopSec = LoopPlayersTab:AddSection({ Name = 'Loop & Whitelist' })
	local loopDropdown = loopSec:AddDropdown({
		Name = 'Select Player',
		Default = '',
		Options = {},
		Callback = function(val)
			SelectedLoopPlayer = extractUsername(val)
			SelectedWhitelistPlayer = SelectedLoopPlayer
		end,
	})
	refreshPlayerDropdown(loopDropdown, false)

	loopSec:AddButton({
		Name = 'Add to Loop List',
		Callback = function()
			if SelectedLoopPlayer and not table.find(LoopPlayers, SelectedLoopPlayer) then
				table.insert(LoopPlayers, SelectedLoopPlayer)
				Notify('Added ' .. SelectedLoopPlayer .. ' to loop list')
			end
		end,
	})

	loopSec:AddButton({
		Name = 'Add to Whitelist',
		Callback = function()
			if SelectedWhitelistPlayer and not isWhitelisted(SelectedWhitelistPlayer) then
				table.insert(WhitelistPlayers, SelectedWhitelistPlayer)
				Notify('Whitelisted ' .. SelectedWhitelistPlayer)
			end
		end,
	})

	loopSec:AddToggle({
		Name = 'Enable Loop Fling',
		Default = false,
		Callback = function(v) _G.LoopFlingEnabled = v end,
		Save = true,
		Flag = 'loopfling_toggle',
	})
end

-- 12. Auto Tab
do
	local autoSec = AutoTab:AddSection({ Name = 'Automation' })
	autoSec:AddToggle({
		Name = 'Auto Claim Plot',
		Default = false,
		Callback = function(v) _G.AutoClaimPlot = v end,
		Save = true,
		Flag = 'autoclaimplot_toggle',
	})
end

-- 13. Misc Tab
do
	local saSec = MiscTab:AddSection({ Name = 'Silent-Aim' })
	saSec:AddToggle({
		Name = 'Silent Aim',
		Default = false,
		Callback = function(v) _G.SilentAim = v end,
		Save = true,
		Flag = 'SilentAim_toggle',
	})
	saSec:AddSlider({
		Name = 'Silent-Aim Range',
		Min = 0,
		Max = 50,
		Default = 50,
		Color = Color3.fromRGB(255, 255, 255),
		Increment = 1,
		ValueName = '',
		Callback = function(v) silentAimRange = v end,
		Save = true,
		Flag = 'silentaimrange_slider',
	})

	local miscSec = MiscTab:AddSection({ Name = 'Utilities' })
	miscSec:AddButton({
		Name = 'Rejoin Server',
		Callback = function()
			local ok, err = pcall(function()
				game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end)
			if not ok then
				Notify('Rejoin failed: ' .. tostring(err), 'Error')
			end
		end,
	})
end

-- 14. Config Tab
do
	local cfgSec = ConfigTab:AddSection({ Name = 'Configuration' })
	cfgSec:AddParagraph(HUB_TITLE, 'Toggles and sliders with Save = true automatically save to ' .. 'FTGS_M4nace_Wump_Config' .. '.')
end

-- 15. Credits Tab
do
	local c1 = CreditsTab:AddSection({ Name = '1# Medal credits' })
	local c2 = CreditsTab:AddSection({ Name = '2# Medal credits' })
	local c3 = CreditsTab:AddSection({ Name = '3# Medal credits' })

	local creditIds = {
		90063030, 2298910483, 1030559478, 1762306425,
		542649826, 237152138, 1390422876, 3089724826,
		882860613, 7280113503, 3485279105,
	}

	local ok, infos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(creditIds)
	end)

	local resolved = {}
	for i, id in ipairs(creditIds) do
		local found = { DisplayName = 'deleted', Username = 'deleted' }
		if ok and infos then
			for _, info in ipairs(infos) do
				if info.Id == id then
					found = info
					break
				end
			end
		end
		resolved[i] = found
	end

	local function fmt(idx)
		return resolved[idx].DisplayName .. ' (' .. resolved[idx].Username .. ')'
	end

	c1:AddParagraph(HUB_TITLE, 'Edited & rebranded edition: M4nace × Wump')
	c1:AddParagraph(fmt(1), 'I made the whole GUI (Combat, Player, Auras and more) XD!')
	c1:AddParagraph(fmt(2), 'Thanks for giving me inspiration to create the blobman functions, Massless Grab and Line color changer script!')
	c1:AddParagraph(fmt(3) .. ' and ' .. fmt(6), 'Thanks for sharing the Attraction Aura, Silent Aim, Further Extend scripts for me!')
	c1:AddParagraph(fmt(7), 'Thanks for helping me to fix kick stuff and my anti-blobman')
	c1:AddParagraph(fmt(8), 'Thanks for explosion stuff, fireproximityprompt fix and script updater')
	c1:AddParagraph(fmt(9), 'Thanks for laggy stuff!')
	c1:AddParagraph(fmt(10), 'Thanks for Anchor Objects Glue/Compile')
	c1:AddParagraph(fmt(11), 'Thanks for Tornado Shape')
	c2:AddParagraph(fmt(4), 'Thanks for releasing my script!')
	c3:AddParagraph(fmt(5), 'Thanks for testing my scripts')
end

-- Safe descendant cleanup handler
Workspace.DescendantAdded:Connect(function(desc)
	if desc.Name == 'PartOwner' and desc.Parent and desc.Parent.Name == 'Head' then
		local char = desc.Parent.Parent
		local hrp = char and char:FindFirstChild('HumanoidRootPart')
		if hrp then
			for _, objName in ipairs({ 'KickAuraP', 'KickAuraP1', 'SkyVelocity', 'BringBody' }) do
				local existing = hrp:FindFirstChild(objName)
				if existing then
					existing:Destroy()
				end
			end
		end
	elseif desc.Name == 'TimeRemainingNum' and desc.Parent and desc.Parent.Value == LocalPlayer.Name then
		_G.RemainingTimeInHouse = desc
	end
end)

-- Active runtime loops for toggles
UserInputService.JumpRequest:Connect(function()
	if _G.InfiniteJump then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local char = GetPlayerCharacter()
	local root = GetPlayerRoot()
	local hum = char and char:FindFirstChildOfClass('Humanoid')

	if _G.SuperSpeed and root and hum then
		root.CFrame = root.CFrame + hum.MoveDirection * (Multiplier or 0.25)
	end

	if _G.AntiRagdoll and hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	if _G.AutoStruggle and IsHeld and IsHeld.Value then
		pcall(function()
			Struggle:FireServer()
		end)
	end

	if _G.AntiVoid and root and root.Position.Y < -45 then
		root.CFrame = CFrame.new(0, 15, 0)
	end

	if _G.ESPEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hl = plr.Character:FindFirstChild('FTGS_Highlight')
				if not hl then
					hl = Instance.new('Highlight')
					hl.Name = 'FTGS_Highlight'
					hl.FillTransparency = 0.65
					hl.OutlineTransparency = 0
					hl.Parent = plr.Character
				end
			end
		end
	else
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild('FTGS_Highlight') then
				plr.Character.FTGS_Highlight:Destroy()
			end
		end
	end
end)

LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

UILib:Init()
