local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MatchStatusConfig = GameConfig.MatchStatus

local StateWatcher = {}

local folder = nil

local function applyPhase()
	local phase = folder:GetAttribute(MatchStatusConfig.Attributes.PHASE)
	print("[StateWatcher] - Phase is: "..phase)
end

local function applyDeadline()
	if workspace:GetServerTimeNow() == 0 then
		return print("[StateWatcher] - No server time yet.")
	end
	
	local timestamp = folder:GetAttribute(MatchStatusConfig.Attributes.DEADLINE)
	if timestamp == 0 then
		print("[StateWatcher] - No deadline set yet.")
	else
		local durationRounded = string.format("%.2f", timestamp - workspace:GetServerTimeNow())
		print("[StateWatcher] - Phase duration: "..durationRounded)
	end
end

function StateWatcher.start()
	-- Connect to attribute changes
	folder = ReplicatedStorage:WaitForChild(MatchStatusConfig.FOLDER_NAME, 5)
	if not folder then warn("[StateWatcher] - MatchStatus folder not found") return end
	
	applyPhase()
	task.spawn(function()	-- Kept here as a function that reports current state should never contain a delay. The moment it waits, what it reports is no longer current
		while workspace:GetServerTimeNow() == 0 do	-- Wait until the client knows what the time is
			task.wait()
		end
		applyDeadline()
	end)

	folder:GetAttributeChangedSignal(MatchStatusConfig.Attributes.PHASE):Connect(applyPhase)
	folder:GetAttributeChangedSignal(MatchStatusConfig.Attributes.DEADLINE):Connect(applyDeadline)
end

return StateWatcher