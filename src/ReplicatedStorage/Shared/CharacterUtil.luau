-- Character lookups shared by every system that acts on players.
-- Owns nothing, decides nothing: pure functions of their arguments.

local CharacterUtil = {}

-- Returns root, humanoid for a player worth acting on -- or nil if there is no
-- character, it is still assembling, or it is a corpse. One nil for all three,
-- so no caller has to tell them apart.
function CharacterUtil.getLiveParts(player)
	local character = player.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return nil end
	if humanoid.Health <= 0 then return nil end

	return root, humanoid
end

return CharacterUtil
