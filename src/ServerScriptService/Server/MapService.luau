local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local mapsConfig = GameConfig.Maps

local MapService = {}

-- Lifetime 1: server lifetime
local mapFolder = nil
local eligible = {}
local previousMap = nil

-- Lifetime 2: round lifetime
local currentMap = nil

-- Check if the map is set to usable in the config and if the map is in the server storage
local function isUsable(entry, template)
	local isEnabled = entry.ENABLED
	if not isEnabled then return false, "Map is not enabled" end
	local hasTemplate = template ~= nil
	if not hasTemplate then return false, "Map has no template" end
	local hasSpFolder = template:FindFirstChild(mapsConfig.SPAWN_FOLDER_NAME) ~= nil
	if not hasSpFolder then return false, "Map has no spawn folder" end
	return true
end

local function pickNext()
	if #eligible == 0 then warn("[MapService] - No eligible maps available") return nil end
	if #eligible == 1 then return eligible[1] end
	
	local candidates = {}
	for _, entry in pairs(eligible) do
		if entry ~= previousMap then
			table.insert(candidates, entry)
		end
	end
	
	local index = math.random(1, #candidates)
	local entry = candidates[index]

	return entry
end

function MapService.load()
	if not mapFolder then return false end
	
	local chosenMap = pickNext()
	if not chosenMap then return false end
	
	local mapTemplate = mapFolder:FindFirstChild(chosenMap.NAME)
	local canBeUsed, reason = isUsable(chosenMap, mapTemplate)
	if not canBeUsed then
		warn("[MapService] - Map " .. chosenMap.NAME .. " is not usable, at runtime: " .. reason)
		return false
	end

	
	local clone = mapTemplate:Clone()
	clone:PivotTo(CFrame.new(mapsConfig.ORIGIN))
	clone.Parent = workspace
	currentMap = clone
	previousMap = chosenMap
	
	print("[MapService] - Loaded map " .. chosenMap.NAME)
	
	return true
end

function MapService.unload()
	if not currentMap then return end
	
	print("[MapService] - Unloading map " .. currentMap.Name)
	currentMap:Destroy()
	currentMap = nil
end

function MapService.getSpawnPoints()
	if not currentMap then return nil, "No map loaded" end
	local spawnPointFolder = currentMap:FindFirstChild(mapsConfig.SPAWN_FOLDER_NAME)
	if not spawnPointFolder then return nil, "No spawn point folder" end
	local spawnPoints = spawnPointFolder:GetChildren()
	if #spawnPoints == 0 then return nil, "No spawn points" end
	return spawnPoints
end

function MapService.init()
	mapFolder = ServerStorage:WaitForChild(mapsConfig.FOLDER_NAME, 5)
	assert(mapFolder ~= nil, "MapService: could not find folder " .. mapsConfig.FOLDER_NAME .. " in ServerStorage")
	
	for _, entry in mapsConfig.Catalog do
		local template = mapFolder:FindFirstChild(entry.NAME)
		local canBeUsed, reason = isUsable(entry, template)
		if not canBeUsed then
			warn("[MapService] - Map " .. entry.NAME .. " is not usable, at init: " .. reason)
			continue
		end
		table.insert(eligible, entry)
	end
	
	print("[MapService] - " .. #eligible .. " eligible map(s) found")
end

return MapService