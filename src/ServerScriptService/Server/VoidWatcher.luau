-- Kills any player who falls below the void height, and tells every client who it was.
-- There is no floor outside the lobby, so this is the only thing catching a fall.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local CharacterUtil = require(Shared.CharacterUtil)
local RemoteService = require(ServerScriptService.Server.RemoteService)

local voidConfig = GameConfig.World.Void
local remotesConfig = GameConfig.Remotes

local VoidWatcher = {}

local fallRemote = nil

-- no init: nothing comes looking for the void watcher

function VoidWatcher.start()
	-- safe here, and ONLY here: RemoteService.init has already run
	fallRemote = RemoteService.get(remotesConfig.RemoteEvents.VOID_FALL)

	task.spawn(function()
		while true do
			task.wait(voidConfig.INTERVAL)

			for _, player in Players:GetPlayers() do
				local root, humanoid = CharacterUtil.getLiveParts(player)
				if root and root.Position.Y < voidConfig.Y then
					humanoid.Health = 0
					fallRemote:FireAllClients(player.Name)
					print(player.Name .. " fell into the void")
				end
			end
		end
	end)
end

return VoidWatcher
