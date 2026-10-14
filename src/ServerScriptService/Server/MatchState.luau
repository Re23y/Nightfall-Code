-- Owns exactly one thing: which phase the match is in, and which changes to it are
-- legal. Creates nothing, touches no Instance, has no init.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Signal = require(ReplicatedStorage.Shared.Signal)

local matchConfig = GameConfig.Match
local State = matchConfig.STATES

local MatchState = {}

-- PUBLIC, and PascalCase because it is an event: this is part of MatchState's API in
-- exactly the way Died is part of Humanoid's. Read it as "MatchState's StateChanged".
--
-- DECISION: built HERE, at the top level, so it exists the moment this module is
-- required -- which is before any init() and long before any start().
-- Alternative: build it in an init(). Consequence: a system connecting in its own
-- init() would connect to nil or not, depending on Bootstrap's list order -- the exact
-- problem two-phase startup exists to kill. A value with no ordering problem needs no
-- phase. The rule that falls out:
--
--   Create signals at require time. Connect to them in start().
--
-- (start(), not init(), because init means "set yourself up, touch nothing else", and
-- connecting to another system's signal is touching another system.)
MatchState.StateChanged = Signal.new()

-- The one piece of running state in this file. Nothing outside this module can write
-- it -- that is the entire reason MatchState exists as a system rather than a value.
local _current = State.INTERMISSION

-- Rule: which transitions are allowed at all, keyed by the state being left.
local LEGAL = {
	[State.INTERMISSION]	= { [State.MAP_LOAD] = true },
	[State.MAP_LOAD]		= { [State.ROUND] = true, [State.INTERMISSION] = true },
	[State.ROUND]			= { [State.RESULTS] = true },
	[State.RESULTS]			= { [State.INTERMISSION] = true },
}

function MatchState.get()
	return _current
end

-- RoundService is the only caller of MatchState.set().
function MatchState.set(newState)
	if not LEGAL[_current][newState] then
		-- warn, not error: the caller has a bug but the machine is still in a good
		-- state, so taking the caller down would lose a working match.
		warn("[MatchState] - illegal: " .. _current .. " -> " .. tostring(newState) .. ", ignored")
		return false
	end

	local previous = _current
	_current = newState

	print("[MatchState] - " .. previous .. " -> " .. _current)

	-- Systems on this machine. We do not know or care who, or how many, or zero.
	MatchState.StateChanged.fire(_current, previous)
	return true
end

return MatchState
