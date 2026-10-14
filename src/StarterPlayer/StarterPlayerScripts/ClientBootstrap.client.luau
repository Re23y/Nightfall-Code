local Client = script.Parent.Client

local systems = {
	require(Client.StateWatcher),
}

print("[ClientBootstrap] ---- init phase ----")
for _, system in systems do
	if system.init then system.init() end
end

print("[ClientBootstrap] ---- start phase ----")
for _, system in systems do
	if system.start then system.start() end
end

print("[ClientBootstrap] " .. #systems .. " systems running")