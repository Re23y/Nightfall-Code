local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharUtil = require(ReplicatedStorage.Shared.CharacterUtil)

local RemoteService = require(ServerScriptService.Server.RemoteService)

local worldConfig = GameConfig.World
local healpadConfig = worldConfig.HealPad
local remotesConfig = GameConfig.Remotes

local HealPad = {}

local lobby = nil
local floorTop = nil

local debounce = false
local healPad = nil

local healRemote = nil

local function makePad(config)
	local pad = Instance.new("Part")
	pad.Name	 	= config.NAME
	pad.Size 		= config.SIZE
	pad.Position 	= Vector3.new(config.INSET.X, floorTop + pad.Size.Y/2 + config.INSET.Y, config.INSET.Z)
	pad.Anchored 	= true
	pad.Color 		= config.ACTIVE_COLOR
	pad.Material 	= config.MATERIAL
	pad.Parent 		= lobby
	return pad
end

local function padTouched(otherPart)
	if debounce then return end
	
	-- If other part is for example a handle, the parent would be the tool and not the character
	local char = otherPart:FindFirstAncestorOfClass("Model")
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	
	local _, hum = CharUtil.getLiveParts(player)
	if not hum then return end
	
	debounce = true
	print("Healing player: " .. player.Name)
	hum.Health = hum.MaxHealth
	healRemote:FireClient(player)
	healPad.Color = healpadConfig.DISABLED_COLOR
	
	task.wait(healpadConfig.COOLDOWN)
	healPad.Color = healpadConfig.ACTIVE_COLOR
	debounce = false
end

function HealPad.start()
	lobby = workspace.Lobby
	local floor = lobby.Floor
	floorTop = floor.Position.Y + floor.Size.Y / 2
	
	healRemote = RemoteService.get(remotesConfig.RemoteEvents.HEAL_NOTICE)
	
	healPad = makePad(healpadConfig)
	healPad.Touched:Connect(padTouched)
end

return HealPad