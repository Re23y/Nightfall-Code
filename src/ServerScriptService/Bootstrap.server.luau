-- The only Script on the server.
--
-- Two phases, and the invariant between them is the whole point:
-- EVERY system's init() finishes before ANY system's start() begins.
-- So a start() may rely on every other system's init() having happened, and the
-- order of this list stops deciding anything that init built.

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.Server

local systems = {
	require(Server.HealPad),
	require(Server.VoidWatcher),
	require(Server.RemoteService),
	require(Server.SprintZone),
	require(Server.MatchState),
	require(Server.StateBoard),
	require(Server.CapturePoint),
	require(Server.Hazard),
	require(Server.MatchStatus),
	require(Server.MapService),
	require(Server.RoleService),
	require(Server.RoundService),
}

print("[Bootstrap] ---- init phase ----")
for _, system in systems do
	if system.init then system.init() end
end

print("[Bootstrap] ---- start phase ----")
for _, system in systems do
	if system.start then system.start() end
end

print("[Bootstrap] " .. #systems .. " systems running")
