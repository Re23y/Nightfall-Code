local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharUtil = require(ReplicatedStorage.Shared.CharacterUtil)

local ZoneConfig = GameConfig.World.SprintZone
local Defaults = GameConfig.Defaults.Stats

local lobby = nil
local floorTop = nil

local sprintZone = nil

local RADIUS = ZoneConfig.SIZE.X / 2
local BASE_SPEED = Defaults.WalkSpeed.BASE
local BOOSTED_SPEED = Defaults.WalkSpeed.BASE + ZoneConfig.SPEED_BONUS

local SprintZone = {}

local function makeZone(config)
	local zone = Instance.new("Part")
	zone.Name = config.NAME
	zone.Material = config.MATERIAL
	zone.Transparency = config.TRANSPARENCY
	zone.Shape = config.PART_TYPE
	zone.Size = config.SIZE
	zone.Anchored = true
	zone.CanCollide = false
	zone.Position = Vector3.new(config.INSET.X, floorTop + config.INSET.Y, config.INSET.Z)
	zone.Parent = lobby
	return zone
end

local function distanceBetween(a, b)
	return (a - b).Magnitude
end

local function applySpeed(hum, desired)
	if hum.WalkSpeed == desired then return false end
	hum.WalkSpeed = desired
	return true
end

function SprintZone.start()
	lobby = workspace.Lobby
	floorTop = lobby.Floor.Position.Y + lobby.Floor.Size.Y / 2
	
	sprintZone = makeZone(ZoneConfig)
	
	task.spawn(function()
		while true do 
			task.wait(ZoneConfig.CHECK_INTERVAL)
			
			for _, player in Players:GetPlayers() do
				local root, hum = CharUtil.getLiveParts(player)
				if root then
					local distance = distanceBetween(root.Position, sprintZone.Position)
				
					local desired = (distance <= RADIUS) and BOOSTED_SPEED or BASE_SPEED
					if applySpeed(hum, desired) then
						print("Speed changed for "..player.Name.." to "..desired)
					end
				end
			end
		end
	end)
end

return SprintZone