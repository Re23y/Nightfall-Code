local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RolesConfig = GameConfig.Roles

local RoleService = {}

local roles = {}

-- Returns the players role if they have one, otherwise returns nil. Nil returned if not in the round.
function RoleService.getPlayerRole(player:Player)
	return roles[player]
end

function RoleService.roleSelect()
	local players = Players:GetPlayers()
	local murdererSlots = math.max(math.floor(#players / RolesConfig.Murderer.PLAYERS_PER_SLOT), RolesConfig.Murderer.MIN_SLOTS)
	local sheriffSlots = math.max(math.floor(#players / RolesConfig.Sheriff.PLAYERS_PER_SLOT), RolesConfig.Sheriff.MIN_SLOTS)
	local totalSlots = murdererSlots + sheriffSlots
	
	if totalSlots > #players then
		warn("[RoleService] - Not enough players! "..#players.." players, for "..totalSlots.." slots.")
		return false
	end
	
	for i = 1, murdererSlots do
		local index = math.random(#players)
		local player = players[index]
		roles[player] = RolesConfig.Murderer.NAME
		table.remove(players, index)
		print("[RoleService] - "..player.Name.." selected as a "..RolesConfig.Murderer.NAME)
	end
	
	for i = 1, sheriffSlots do
		local index = math.random(#players)
		local player = players[index]
		roles[player] = RolesConfig.Sheriff.NAME
		table.remove(players, index)
		print("[RoleService] - "..player.Name.." selected as a "..RolesConfig.Sheriff.NAME)
	end
	
	for _, player in ipairs(players) do
		roles[player] = RolesConfig.Civilian.NAME
		print("[RoleService] - "..player.Name.." selected as a "..RolesConfig.Civilian.NAME)
	end
	
	print("[RoleService] - Roles selected")
	return true
end

function RoleService.roleClear()
	roles = {}
	print("[RoleService] - Roles cleared")
end

function RoleService.start()
	Players.PlayerRemoving:Connect(function(player)
		roles[player] = nil
		print("[RoleService] - Player ("..player.Name..") removed")
	end)
end

return RoleService
