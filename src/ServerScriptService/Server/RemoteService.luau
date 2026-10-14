-- Creates the RemoteEvents that both machines look for, and hands them out by name.
--
-- This is the clearest possible init: every system that talks to a client comes
-- looking for these, and every client is sitting in WaitForChild until they exist.
-- Nobody waits on us; everybody waits FOR us.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local remotesConfig = GameConfig.Remotes

local RemoteService = {}

local folder = nil

function RemoteService.init()
	folder = Instance.new("Folder")
	folder.Name = remotesConfig.Settings.FOLDER_NAME

	for _, remoteName in remotesConfig.RemoteEvents do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end

	-- parent LAST (L2). Here it is load-bearing: a client that sees the folder
	-- half-filled gets a real remote for one event and nil for the next.
	folder.Parent = ReplicatedStorage
end

function RemoteService.get(remoteName)
	local remote = folder and folder:FindFirstChild(remoteName)
	if not remote then
		error("RemoteService.get: no remote named " .. tostring(remoteName))
	end
	return remote
end

return RemoteService
