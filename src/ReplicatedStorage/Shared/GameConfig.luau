local GameConfig = {}

GameConfig.Remotes = {
	Settings = {
		FOLDER_NAME 	= "Remotes",
	},
	RemoteEvents = {
		VOTE_REQUEST 	= "VoteRequest",		-- Client -> server: "I want to vote for this map"
		VOTE_RESULT		= "VoteResult",
		VOTE_ANNOUNCE 	= "VoteAnnounce",		-- Server -> all clients: "This is the map we're playing"
		VOID_FALL		= "VoidFall",			-- Server -> all clients: "this player fell out of the world"
		HEAL_NOTICE		= "HealNotice",
	}
}

GameConfig.Maps = {
	FOLDER_NAME = "Maps",
	SPAWN_FOLDER_NAME = "SpawnPoints",
	ORIGIN = Vector3.new(400,0,0),
	
	Catalog = {
		Castle = {
			NAME = "Castle",
			ENABLED = true,
		},
		Ruins = {
			NAME = "Ruins",
			ENABLED = true,
		},
		Tower = {
			NAME = "Tower",
			ENABLED = true,
		}
	}
}

GameConfig.Defaults = {
	Stats = {
		WalkSpeed = {
			BASE = 16
		}
	}
}

GameConfig.Messages = {
	VotingMessages = {
		ALREADY_VOTED = "You have already voted.",
		BAD_REQUEST = "Something went wrong.",
		NO_SUCH_MAP = "That map doesn't exist.",
		SUCCESS = "Successfully voted.",
		PLAYER_LEFT = "left, tally recalculated."
	},
	StatMessages = {
		BAD_PARAMETER = "Invalid parameter(s).",
		BAD_TYPE = "Invalid type(s).",
		NO_SUCH_STAT = "That stat doesn't exist.",
	}
}

local CAPTURE_POINT_STATES = {
	UNCAPTURED = "Uncaptured",
	CAPTURING = "Capturing",
	CAPTURED = "Captured",
}

-- The vocabulary of the match. Never changes while the server runs, nobody writes it,
-- and no reason to hide it from a player: config.
-- The CURRENT state is none of those three things. It does not live here.
local STATES = {
	INTERMISSION	= "Intermission",
	MAP_LOAD		= "MapLoad",
	ROUND			= "Round",
	RESULTS			= "Results",
}

GameConfig.Match = {
	STATES = STATES,
	
	MIN_PLAYERS = 2,

	-- How long the machine sits in each state. Short on purpose, for testing.
	DURATION = {
		[STATES.INTERMISSION]	= 8,
		[STATES.MAP_LOAD]		= 3,
		[STATES.ROUND]			= 12,
		[STATES.RESULTS]		= 5,
	},
	
	RoundService = {
		POLL_INTERVAL = 0.1,
		
		Reasons = {
			OUT_OF_TIME = "Ran out of time.",
			NOT_ENOUGH_PLAYERS = "Not enough players.",
		}
	}
}

GameConfig.MatchStatus = {
	FOLDER_NAME = "MatchStatus",
	
	Attributes = {
		PHASE = "Phase",
		DEADLINE = "Deadline",	-- This attribute is 0 when no deadline has been set yet but has been created. This would be nil if the attribute was never set.
	}
}

GameConfig.Roles = {
	Murderer = {
		NAME = "Murderer",
		MIN_SLOTS = 1,
		PLAYERS_PER_SLOT = 4,
	},
	Sheriff = {
		NAME = "Sheriff",
		MIN_SLOTS = 1,
		PLAYERS_PER_SLOT = 4,
	},
	Civilian = {
		NAME = "Civilian",
	}
}

GameConfig.World = {
	Void = {
		Y = -50,		-- The Y position of the void
		INTERVAL = 1	-- Time between checks of player position
	},
	HealPad = {
		NAME = "HealPad",						-- The name of the part
		COOLDOWN = 5,							-- Cooldown between uses
		SIZE = Vector3.new(10, 1, 10),			-- Size of the part
		MATERIAL = Enum.Material.Neon,			-- Material of the part
		ACTIVE_COLOR = Color3.fromRGB(83, 255, 117),	-- Active colour of the part
		DISABLED_COLOR = Color3.fromRGB(28, 127, 36),	-- Colour to show the pad is disabled
		INSET = Vector3.new(-20, 0, -20),			-- Inset from the world's origin
	},
	Cover = {
		NAME = "CoverWall",						-- The name of the part
		SIZE = Vector3.new(12, 4, 1),			-- Size of the part
		INSET = Vector3.new(0, 0, 20)			-- Inset from the world's origin
	},
	StateBoard = {
		COLOR = {
			[STATES.INTERMISSION]	= Color3.fromRGB(70, 90, 120),
			[STATES.MAP_LOAD]		= Color3.fromRGB(170, 130, 40),
			[STATES.ROUND]			= Color3.fromRGB(60, 150, 75),
			[STATES.RESULTS]		= Color3.fromRGB(125, 65, 150),
		},
	},
	SprintZone = {
		NAME = "SprintZone",
		PART_TYPE = "Ball",
		TRANSPARENCY = 0.5,
		MATERIAL = Enum.Material.Neon,
		SIZE = Vector3.new(40,40,40),
		INSET = Vector3.new(20, 0, -20),
		
		SPEED_BONUS = 14,
		CHECK_INTERVAL = 0.1,
	},
	CapturePoint = {
		NAME = "CapturePoint",
		SHAPE = "Cylinder",
		SIZE = Vector3.new(20, 40, 40),
		ROTATION = Vector3.new(0, 0, 90),
		INSET = Vector3.new(-20, 0, 20),
		TRANSPARENCY = 0.6,
		MATERIAL = Enum.Material.Neon,
		CAN_COLLIDE = false,
		
		PASSIVE_RATE = 4,
		PROGRESS_INCREMENT = 10,
		CHECK_INTERVAL = 0.1,
		MAX_PROGRESS = 100,
		
		COLORS = {
			["Uncaptured"] = Color3.fromRGB(120, 120, 120),
			["Capturing"] = Color3.fromRGB(255, 245, 193),
			["Captured"] = Color3.fromRGB(255, 170, 0),
		},
		
		STATES = CAPTURE_POINT_STATES,
	},
	Hazard = {
		DEFAULT_DAMAGE = 10,
		TAG = "Hazard",
		DEBOUNCE_TIME = 1,
	}
}

return GameConfig
