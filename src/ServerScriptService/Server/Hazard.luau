local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CharUtil = require(ReplicatedStorage.Shared.CharacterUtil)

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HazardConfig = GameConfig.World.Hazard

local TAG = HazardConfig.TAG
local DEFAULT_DAMAGE = HazardConfig.DEFAULT_DAMAGE

local bindings = {}

local Hazard = {}

local function bind(part)
	if bindings[part] then return end -- Already bound.
	
	local conn = part.Touched:Connect(function(hit)
		local partTable = bindings[part]
		if not partTable then return end	-- Not bound.
		
		if partTable.debounce then return end
		
		local char = hit:FindFirstAncestorOfClass("Model")
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player then return end
		
		local _, hum = CharUtil.getLiveParts(player)
		if not hum then return end
		
		local damage = part:GetAttribute("Damage") or DEFAULT_DAMAGE
		
		partTable.debounce = true
		hum.Health -= damage
		print("Hazard damaged "..player.Name)
		task.delay(HazardConfig.DEBOUNCE_TIME, function()
			partTable.debounce = false
		end)
	end)
	
	bindings[part] = { touchConn = conn, debounce = false }
end
local function unbind(part)
	local partTable = bindings[part]
	if not partTable then return end
	
	partTable.touchConn:Disconnect()
	bindings[part] = nil
	print("unbound	"..part.Name)
end

function Hazard.start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(bind)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unbind)
	for _, part in CollectionService:GetTagged(TAG) do
		bind(part)
	end
end

return Hazard
