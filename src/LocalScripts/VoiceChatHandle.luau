-- SERVICES --
local VoiceChatService=game:GetService("VoiceChatService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

-- LOCALS --
local eventsFolder=ReplicatedStorage:WaitForChild("VoiceChatZonesEvents")
local voiceEvent:RemoteEvent=eventsFolder:WaitForChild("voiceEvent")
local voiceFunction:RemoteFunction=eventsFolder:WaitForChild("voiceFunction")

-- MAIN HANDLER --

local localPlayer=Players["LocalPlayer"]

local myZoneId=""

local activeTweens={}

local function getVoiceObject(player: Player)
	local AudioDeviceInput = player:FindFirstChildOfClass("AudioDeviceInput")
	return AudioDeviceInput
end

local function fadeOutUser(player:Player)
	local voiceInput=getVoiceObject(player)
	if voiceInput then
		if activeTweens[player] then
			activeTweens[player]:Cancel()
			activeTweens[player] = nil
		end
		local tween=TweenService:Create(voiceInput,TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),{Volume=0})
		activeTweens[player]=tween
		tween:Play()
		tween.Completed:Connect(function(playBackState)
			activeTweens[player] = nil
		end)
	end
end

local function fadeInUser(player:Player)
	local voiceInput=getVoiceObject(player)
	if voiceInput then
		if activeTweens[player] then
			activeTweens[player]:Cancel()
			activeTweens[player] = nil
		end
		local tween=TweenService:Create(voiceInput,TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),{Volume=1})
		activeTweens[player]=tween
		tween:Play()
		tween.Completed:Connect(function(playBackState)
			activeTweens[player] = nil
		end)
	end
end

local getPlayersInZones=voiceFunction:InvokeServer("getPlayersInZones")

for _, playerData in ipairs(getPlayersInZones) do
	local userid=playerData.uid
	local player=Players:GetPlayerByUserId(userid)
	if player then
		local voiceInput=player:FindFirstChildOfClass("AudioDeviceInput")
		if voiceInput then
			voiceInput.Volume=0
		end
	end
end


voiceEvent.OnClientEvent:Connect(function(data)
	local t=data["type"]
	if t=="zoneAdd" then
		local userid=data["uid"]
		local player=Players:GetPlayerByUserId(userid)
		if not player then return end
		local zoneId=data["zid"]

		if player==localPlayer then
			local playersInZone=data["playersInZone"]
			myZoneId=zoneId
			local inZone={}
			for _, pUid in pairs(playersInZone) do inZone[pUid]=true end

			for _, player2 in ipairs(Players:GetPlayers()) do
				if player2 == localPlayer then continue end
				if inZone[player2.UserId] then
					task.spawn(fadeInUser,player2)
				else
					task.spawn(fadeOutUser,player2)
				end
			end
		else
			if myZoneId == zoneId then
				task.spawn(fadeInUser,player)
			else
				task.spawn(fadeOutUser,player)
			end
		end

	elseif t=="zoneRemove" then
		local userid=data["uid"]
		local player=Players:GetPlayerByUserId(userid)
		if not player then return end

		if player==localPlayer then
			myZoneId="" 
			local getPlayersInZones=voiceFunction:InvokeServer("getPlayersInZones")
			local playerInAnyZone={}
			for _, playerData in ipairs(getPlayersInZones) do
				playerInAnyZone[playerData.uid] = true
			end

			for _, player2 in ipairs(Players:GetPlayers()) do
				if player2 == localPlayer then continue end
				if not playerInAnyZone[player2.UserId] then
					task.spawn(fadeInUser,player2)
				else
					task.spawn(fadeOutUser,player2)
				end
			end
		else
			if myZoneId == "" then
				task.spawn(fadeInUser,player)
			else
				task.spawn(fadeOutUser,player)
			end
		end
	end
end)
