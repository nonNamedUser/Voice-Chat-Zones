-- SERVICES --
local VoiceChatService=game:GetService("VoiceChatService")
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterPlayer=game:GetService("StarterPlayer")

-- MOVE LOCALSCRIPTS --
local localScripts=script["LocalScripts"]
localScripts.Parent=StarterPlayer["StarterPlayerScripts"]

-- ZONEPLUS --
local zoneplus=require(script.Zone)

-- ZONES FOLDER --
local zones=script.Parent:WaitForChild("Zones")

-- TABLES --
local zonesTable={}
local playersInZone={}

-- CREATE EVENTS --
local eventsFolder=Instance.new("Folder",ReplicatedStorage)
eventsFolder.Name="VoiceChatZonesEvents"
local voiceEvent=Instance.new("RemoteEvent",eventsFolder)
voiceEvent.Name="voiceEvent"
local voiceFunction=Instance.new("RemoteFunction",eventsFolder)
voiceFunction.Name="voiceFunction"

-- MAIN ZONE HANDLER --
for _, zoneGroup in pairs(zones:GetChildren()) do
	local uniqueIdentifier=HttpService:GenerateGUID(false)
	zonesTable[uniqueIdentifier]={}
	local zone=zoneplus.new(zoneGroup)
	
	zone.playerEntered:Connect(function(player)
		local playersInZoneData={ 
			["uid"]=player.UserId,
			["zid"]=uniqueIdentifier
		}
		
		table.insert(zonesTable[uniqueIdentifier],player.UserId)
		
		table.insert(playersInZone,playersInZoneData)
		
		local eventData={
			["type"]="zoneAdd",
			["uid"]=player.UserId,
			["zid"]=uniqueIdentifier,
			["playersInZone"]=zonesTable[uniqueIdentifier]
		}
		
		voiceEvent:FireAllClients(eventData)
	end)
	
	zone.playerExited:Connect(function(player)
		for index, data in ipairs(playersInZone) do
			if data.uid==player.UserId then
				local zone=data.zid
				local zindex=table.find(zonesTable[zone], player.UserId)
				if zindex then
					table.remove(zonesTable[zone],zindex)
				end
				table.remove(playersInZone,index)
			end
		end
		
		local eventData={
			["type"]="zoneRemove",
			["uid"]=player.UserId,
			["zid"]=uniqueIdentifier
		}

		voiceEvent:FireAllClients(eventData)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	for index, data in ipairs(playersInZone) do
		if data.uid==player.UserId then
			local zone=data.zid
			local zindex=table.find(zonesTable[zone], player.UserId)
			if zindex then
				table.remove(zonesTable[zone],zindex)
			end
			table.remove(playersInZone,index)
		end
	end
end)

voiceFunction.OnServerInvoke=function(player,data,userId:number?)
	if data=="getPlayersInZones" then
		return playersInZone
	end
	return {}
end
