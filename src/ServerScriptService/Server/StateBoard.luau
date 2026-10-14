-- Owns the lobby floor's colour, and nothing else. Reads MatchState, never writes it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MatchState = require(ServerScriptService.Server.MatchState)

local boardConfig = GameConfig.World.StateBoard

local StateBoard = {}

local floor = nil

function StateBoard.start()
	floor = workspace.Lobby.Floor
	floor.Color = boardConfig.COLOR[MatchState.get()]

	MatchState.StateChanged.connect(function(newState)
		floor.Color = boardConfig.COLOR[newState]
	end)
end

return StateBoard
