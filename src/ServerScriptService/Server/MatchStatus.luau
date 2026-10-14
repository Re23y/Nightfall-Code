local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MatchState = require(script.Parent.MatchState)
local MatchStatusConfig = GameConfig.MatchStatus

local MatchStatus = {}

local folder = nil

function MatchStatus.setDeadline(timestamp)
	folder:SetAttribute(MatchStatusConfig.Attributes.DEADLINE, timestamp)
end

function MatchStatus.setPhase(phase)
	folder:SetAttribute(MatchStatusConfig.Attributes.PHASE, phase)
end

function MatchStatus.init()
	folder = Instance.new("Folder")
	folder.Name = MatchStatusConfig.FOLDER_NAME
	folder:SetAttribute(MatchStatusConfig.Attributes.PHASE, MatchState.get())
	folder:SetAttribute(MatchStatusConfig.Attributes.DEADLINE, 0)
	folder.Parent = ReplicatedStorage
end

return MatchStatus
