-- RoundService is the only caller of MatchState.set()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MatchState = require(script.Parent.MatchState)
local MatchStatus = require(script.Parent.MatchStatus)
local MapService = require(script.Parent.MapService)
local RoleService = require(script.Parent.RoleService)

local matchConfig = GameConfig.Match
local roundServiceConfig = matchConfig.RoundService
local State = matchConfig.STATES

local RoundService = {}

local NEXT = {
	[State.INTERMISSION]	= State.MAP_LOAD,
	[State.MAP_LOAD]		= State.ROUND,
	[State.ROUND]			= State.RESULTS,
	[State.RESULTS]			= State.INTERMISSION,
}

local reason = nil

local function countEligiblePlayers()
	return #Players:GetPlayers()
end

local function hasEnoughPlayers()
	return countEligiblePlayers() >= matchConfig.MIN_PLAYERS
end

local ENDS_EARLY = {
	[State.ROUND] = function()
		local enoughPlayers = hasEnoughPlayers()

		if not enoughPlayers then
			return roundServiceConfig.Reasons.NOT_ENOUGH_PLAYERS
		else 
			return false
		end
	end,
}

local function publishStatus()
	local timestamp = workspace:GetServerTimeNow() + matchConfig.DURATION[MatchState.get()]
	MatchStatus.setPhase(MatchState.get())
	MatchStatus.setDeadline(timestamp)
end

local function cleanupRound()
	RoleService.roleClear()
	MapService.unload()
end

local function enterIntermission()
	MatchState.set(State.INTERMISSION)
	cleanupRound()
end

local function nextState(currentState)
	MatchState.set(NEXT[currentState])
	local state = MatchState.get()
	if state == State.INTERMISSION then
		cleanupRound()
	elseif state == State.MAP_LOAD then
		if not RoleService.roleSelect() then
			enterIntermission()
		elseif not MapService.load() then
			enterIntermission()
		end
	end
end

local function waitForPhaseEnd(duration, endedEarly)
	local deadline = os.clock() + duration
	
	while os.clock() < deadline do 
		if endedEarly then
			local shouldEnd = endedEarly()
			if shouldEnd then
				return shouldEnd
			end
		end
		-- This ensures the function keeps checking the time for the duration of the phase. 
		task.wait(roundServiceConfig.POLL_INTERVAL)
	end
	
	return roundServiceConfig.Reasons.OUT_OF_TIME
end

function RoundService.start()
	task.spawn(function()
		while true do
			task.wait()
			publishStatus()
			local state = MatchState.get()
			reason = waitForPhaseEnd(matchConfig.DURATION[state], ENDS_EARLY[state])
			-- if the current state is intermission and there isn't enough players 
			-- then don't go onto the next state
			local intermissionCheck = state == State.INTERMISSION and not hasEnoughPlayers()
			if intermissionCheck then
				reason = roundServiceConfig.Reasons.NOT_ENOUGH_PLAYERS
			else
				nextState(state)
			end
			print("[RoundService] - "..state..": "..reason)
		end 
	end)
end

return RoundService