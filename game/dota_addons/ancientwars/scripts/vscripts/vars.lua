--GLOBAL VARIABLES--

local GV = {}

--SCRIPT VARIABLES--
-- Tower construction related
GV.GLOBAL_BUILD_RATE				= 0.2	--Determine building tick rate
GV.TOWER_SCALE						= 0.8	--How much we scale each towers we build
GV.EXCLUDE_RADIUS					= 64

-- Income related
GV.INCOME_TICK_GOAL 				= 0		--Determine the game time needed to be reached to receive income, always initiate at 0
GV.INCOME_TICK 						= 0		--Determine the current tick
GV.INCOME_DURATION					= 10	--Normally 10s, How many seconds before getting income
GV.INCOME_FACTOR					= 1		--Factor of Income given, 2 = Double income of the income you normally get, 0.5 = half etc.
GV.INCOME_PERCENT					= 1		
GV.INCOME_BASE						= 5		--Base income, you will get a minimum of this amount per income
GV.INCOME_BOX_BASE					= 0.294	--Treasure box income stuff..
GV.INCOME_BOX_CUMULATIVE_REDUCTION	= 0.85	--Treasure box income stuff.. %reduction per extra treasure box
GV.INCOME_HIGH_TAX					= false
GV.INCOME_NO_TAX_THRESHOLD			= 25
GV.INCOME_TAX_PROGRESSIVE_STEP		= 25
GV.INCOME_TAX_PROGRESSIVE_PERCENT	= 0.1
GV.INCOME_TAX_MAXIMUM_PERCENT		= 0.8

-- Game time related functions
GV.GAME_TIME 						= 0		--Initiate at 0
GV.GAME_PAUSED 						= false	--Game is never paused at the beginning
GV.FUNCTION_TICK 					= 0		--Do not change this
GV.FUNCTION_TICK_CHECK_INTERVAL		= 0.5	--How smooth the game react to game pauses, at 0.5s there will be a slight delay before Thinker based function 'stops' after a player paused the game
GV.ENDROUND_TIMER					= 0

-- Game voting


-- AI Related variable
GV.AI_TICK							= 0.5

-- Other game variable
GV.ENT_ANCIENT_GOOD 				= {} 
GV.ENT_ANCIENT_BAD 					= {} 
GV.LOC_ANCIENT_GOOD 				= Vector(0,0,0)
GV.LOC_ANCIENT_BAD 					= Vector(0,0,0) 

-- Create global tables
GV.building							= {}	--Table to store all buildings constructed
GV.creep							= {}	--Table to store all creep units (AI related)
GV.team								= {}
GV.shopitem							= {}

GV.player							= {}

_G.PLAYER_INCOME					= {}	--Table to store player's income
_G.PLAYER_INCOME_BOX				= {}	--Number of treasure box.
_G.PLAYER_TECH						= {}	--Table to store player's tech
_G.NPC_AI							= {}	--Table to store all units that requires AI
_G.DUMMY							= {}	--Table to store all dummy units for removal

_G.AI_TYPE							= {}
_G.kvUnitData 						= {}
_G.kvItemData						= {}
_G.kvBuildData						= {}

GV.NUMBEROFJUSTICESHRINE			= {}
GV.JUSTICESHRINEPERCENT				= 20
GV.JUSTICESHRINEPERCENTMAX			= 36
GV.SHRINEUNITSTOREVIVE				= {}

GV.NUMBEROFCITYOFDECAY				= {}
GV.NUMBEROFHEROSHRINE				= {}

-- GAME SETTING VARIABLES--
GV.GAME_INITIAL_GOLD 				= 250	--How much gold each player starts, determined when a player enters the game after picking hero
GV.GAME_STARTING_TECH 				= 1		--How much 'tech' is given initially, used to build legendary tier buildings
GV.GAME_TIME_IS_FIXED 				= true	--Set whether the game time of day is fixed at a particular time
GV.GAME_TIME_FIXED 					= 0.75	--If game time is fixed, what time is it fixed at
GV.GAME_ROUND						= 1
GV.GAME_ROUND_TO_WIN				= 2

GV.GAME_INITIAL_ROUND				= true
GV.GAME_BUILD_COUNT					= 0
---

GV.DMGTABLE = {}
GV.COMBAT_TYPE_ATTACK = {}
GV.COMBAT_TYPE_DEFENCE = {}

GV.COMBAT_LIST_ATK = {}
GV.COMBAT_LIST_DEF = {}


---BOT RELATED---

GV.BOTSLOT = {}
GV.HEROLIST = {}
GV.BOT_IN_GAME = false
GV.AI_STATE = true

GV.VEC_GOOD_BASE = Vector(6600, -100, 512.000000)
GV.VEC_BAD_BASE = Vector(-6800, -120, 512.000000)

GV.VEC_GOOD_BASE_SPECIAL = Vector(5090, 66, 512.000000)
GV.VEC_BAD_BASE_SPECIAL = Vector(-5350, 66, 512.000000)

GV.MAX_STEP_X = 864
GV.MAX_STEP_Y = 1380

GV.MAX_STEP_SPECIAL_X = 906
GV.MAX_STEP_SPECIAL_Y = 1024

GV.BUILDHEIGHT = 512
GV.STEP = 256

GV.BUILD_DATA = {}
GV.UPGRADE = {}
GV.BOT_UNIT_ID = {}
GV.CONSTRUCTING = {}
GV.TEAM_RS_IN_PROGRESS = {}

GV.TREASURE_BOX_TIME_LIMIT = 600
GV.BOT_BUILD_INCOME_FACTOR = 2

return GV



















