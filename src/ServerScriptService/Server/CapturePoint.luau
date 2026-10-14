local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharUtil = require(ReplicatedStorage.Shared.CharacterUtil)

local pointConfig = GameConfig.World.CapturePoint
local States = pointConfig.STATES

local CapturePoint = {}

local currentState = States.UNCAPTURED
local progress = 0
local owner = nil
local onPoint = {}

local lobby = nil
local floorTop = nil

local capturePoint = nil
local RADIUS = pointConfig.SIZE.Y / 2
local HALF_HEIGHT = pointConfig.SIZE.X / 2

local LEGAL = {
	[States.UNCAPTURED] = { [States.CAPTURING] = true },
	[States.CAPTURING]  = { [States.UNCAPTURED] = true, [States.CAPTURED] = true },
	[States.CAPTURED]   = { [States.CAPTURING] = true, [States.UNCAPTURED] = true },
}

local function isOnPoint(position)
	local offset = position - capturePoint.Position
	
	local horizontal = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local vertical = math.abs(offset.Y)
	
	return horizontal <= RADIUS and vertical <= HALF_HEIGHT
end

function CapturePoint.get()
	return currentState
end

function CapturePoint.set(newState, player)
	if not LEGAL[currentState][newState] then
		warn("[CapturePoint] illegal state change: "..currentState.." -> "..tostring(newState)..", ignored")
		return false
	end
	
	local previous = currentState
	currentState = newState

	if newState == States.UNCAPTURED then
		progress = 0
		owner = nil
	elseif newState == States.CAPTURING then
		if player then
			owner = player
		end
	elseif newState == States.CAPTURED then
		owner = player
		progress = pointConfig.MAX_PROGRESS
	end
	
	capturePoint.Color = pointConfig.COLORS[currentState]
	print("[CapturePoint] "..previous.." -> "..newState)
	return true
end

local function makePoint()
	local point = Instance.new("Part")
	point.Name	 	= pointConfig.NAME
	point.Size 		= pointConfig.SIZE
	point.Shape		= pointConfig.SHAPE
	
	point.Rotation	= pointConfig.ROTATION
	point.Position 	= Vector3.new(pointConfig.INSET.X, floorTop + point.Size.X/2 + pointConfig.INSET.Y, pointConfig.INSET.Z)
	
	point.Anchored 	= true
	
	point.Transparency = pointConfig.TRANSPARENCY
	point.Color 	= pointConfig.COLORS[currentState]
	point.Material 	= pointConfig.MATERIAL
	
	point.CanCollide = pointConfig.CAN_COLLIDE
	point.Parent 	= lobby
	return point
end

local function zoneUpdate(player)	
	if currentState == States.CAPTURED then
		if player == owner then  return end
		CapturePoint.set(States.CAPTURING)
	elseif currentState == States.CAPTURING then
		if player == owner then
			progress += pointConfig.PROGRESS_INCREMENT * pointConfig.CHECK_INTERVAL
		else
			progress -= pointConfig.PROGRESS_INCREMENT * pointConfig.CHECK_INTERVAL
		end

		if progress >= pointConfig.MAX_PROGRESS then
			CapturePoint.set(States.CAPTURED, player)
		elseif progress <= 0 then
			CapturePoint.set(States.UNCAPTURED)
		end
	else
		CapturePoint.set(States.CAPTURING, player)
	end
end

function CapturePoint.start()
	lobby = workspace.Lobby
	local floor = lobby.Floor
	floorTop = floor.Position.Y + floor.Size.Y / 2
	
	capturePoint = makePoint()
	
	Players.PlayerRemoving:Connect(function(player)
		onPoint[player] = nil
		if owner == player then
			CapturePoint.set(States.UNCAPTURED)
		end
	end)
	
	task.spawn(function()
		while true do
			task.wait(pointConfig.CHECK_INTERVAL)
			onPoint = {}
			
			for _, player in Players:GetPlayers() do
				local root = CharUtil.getLiveParts(player)
				if root then
					if isOnPoint(root.Position) then 
						onPoint[player] = true
					end
				end
			end
			
			local count = 0 
			for _ in onPoint do
				count += 1
			end
			
			if count == 0 and currentState == States.CAPTURING then
				progress -= pointConfig.PASSIVE_RATE * pointConfig.CHECK_INTERVAL
				if progress <= 0 then
					CapturePoint.set(States.UNCAPTURED)
				end
			elseif count == 1 then
				local player = next(onPoint)
				zoneUpdate(player)
			end
		end
	end)
end

return CapturePoint
