BAREBONES_DEBUG_SPEW = false 

if GameMode == nil then
    _G.GameMode = class({})
end

require('libraries/timers')
require('libraries/notifications')
require('libraries/animations')

require('internal/gamemode')
require('internal/events')
require('internal/util')

require('settings')
require('events')

-- Ancient Wars related
require( "construction" )
require( "ai_core" )
require( "abilities" )

local global = require( "vars" )

function GameMode:PostLoadPrecache()
end

function GameMode:OnHeroInGame(hero)
	local player 		= hero:GetPlayerOwner()
	local PlayerId 		= hero:GetOwner():GetPlayerID()

	PlayerResource:SetGold(PlayerId, 0, true)
	PlayerResource:SetGold(PlayerId, global.GAME_INITIAL_GOLD, false)

	for count = 0, 5 do
		hero:UpgradeAbility(hero:GetAbilityByIndex(count))
	end
	
	local keys = {}
	keys.caster = hero
	changetier(keys)
	
	_G.PLAYER_INCOME[PlayerId] 		= global.INCOME_BASE
	_G.PLAYER_TECH[PlayerId] 		= 1
	_G.PLAYER_INCOME_BOX[PlayerId] 	= 0
	
	global.player[PlayerId] = {}
	global.player[PlayerId].staff	= 0
	global.player[PlayerId].item	= {}
	
	player.lumber 		= 0
	player.units 		= {}
	player.structures 	= {}
	player.buildings 	= {}
	player.upgrades 	= {}
	
	hero.buildingQueue = {}
	
	hero:SetBaseAgility(_G.PLAYER_INCOME[PlayerId])
	hero:SetBaseIntellect(0)
	hero:SetBaseStrength(1)
	hero:AddNewModifier( hero, nil, "modifier_invulnerable", nil  )
	hero.bFirstBuild = true
	
	hero:FindAbilityByName("abilities_worker_repair"):ToggleAutoCast()
	
	if hero:GetTeam() == DOTA_TEAM_BADGUYS then
		hero:SetAngles(0, 180, 0)
	end
	
	PlayerResource:SetCameraTarget(PlayerId, nil)
	
	global.creep[hero] 					= {}
	global.creep[hero].self				= hero
	global.creep[hero].PlayerId 		= PlayerId
	global.creep[hero].UserTeamId 		= hero:GetTeam()
	global.creep[hero].EnemyTeamId 		= hero:GetOpposingTeamNumber()
	global.creep[hero].hero 			= hero
	global.creep[hero].owner 			= player

end


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
	GameMode = self
	GameMode:_InitGameMode()
	
	-- Override Settings
	
	GameRules:SetCustomGameSetupTimeout( 90 )
	GameRules:SetCustomGameSetupAutoLaunchDelay( 60 )
	
	-- Set up timer things
	global.FUNCTION_TICK = GameRules:GetGameTime()
	
	-- Initialize variables
	global.team[DOTA_TEAM_GOODGUYS] 	= {}
	global.team[DOTA_TEAM_BADGUYS] 		= {}
	global.team[DOTA_TEAM_GOODGUYS].Name 			= "Radiant"
	global.team[DOTA_TEAM_BADGUYS].Name 			= "Dire"
	global.team[DOTA_TEAM_GOODGUYS].VictoryText 	= "Radiant Victory"
	global.team[DOTA_TEAM_BADGUYS].VictoryText 		= "Dire Victory"
	global.team[DOTA_TEAM_GOODGUYS].VictoryColor 	= "teal"
	global.team[DOTA_TEAM_BADGUYS].VictoryColor 	= "yellow"
	global.team[DOTA_TEAM_GOODGUYS].Score 			= 0
	global.team[DOTA_TEAM_BADGUYS].Score 			= 0

	local towerLookupList = LoadKeyValues( "scripts/npc/npc_units_custom.txt" )
	local skillLookupList = LoadKeyValues( "scripts/npc/npc_items_custom.txt" )
	local buildLookupList = LoadKeyValues( "scripts/builderdata.txt" )
	
	if towerLookupList then for k, v in pairs(towerLookupList) do table.insert( _G.kvUnitData, self:_readUnitKeyValues(k, v) ) end end
	if skillLookupList then for k, v in pairs(skillLookupList) do table.insert( _G.kvItemData, self:_readItemKeyValues(k, v) ) end end
	
	if skillLookupList then 
		for k, v in pairs(buildLookupList) do
			table.insert( _G.kvBuildData, self:_readBuildKeyValues(k, v) ) 
		end
	end
	
	-- Armour against Attack = %Dmg
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"] = {}
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_NORMAL"]			= 1.05
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_PIERCE"] 		= 1.05
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_MAGIC"] 			= 1.05
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_CHAOS"] 			= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_SIEGE"] 			= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_HERO"] 			= 1.10
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_NONE"]["CUSTOM_COMBAT_TYPE_SPELL"] 			= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_NORMAL"]		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_PIERCE"] 		= 1.75
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_MAGIC"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_CHAOS"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_SIEGE"] 		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_HERO"] 			= 1.10
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_LIGHT"]["CUSTOM_COMBAT_TYPE_SPELL"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_NORMAL"]		= 1.75
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_PIERCE"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_MAGIC"] 		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_CHAOS"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_SIEGE"] 		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_HERO"] 		= 1.10
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_MEDIUM"]["CUSTOM_COMBAT_TYPE_SPELL"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_NORMAL"]		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_PIERCE"] 		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_MAGIC"] 		= 1.75
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_CHAOS"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_SIEGE"] 		= 0.70
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_HERO"] 			= 1.10
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_HEAVY"]["CUSTOM_COMBAT_TYPE_SPELL"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_NORMAL"]	= 0.50
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_PIERCE"] 	= 0.45
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_MAGIC"] 	= 0.40
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_CHAOS"] 	= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_SIEGE"] 	= 1.60
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_HERO"] 		= 0.60
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_FORTIFIED"]["CUSTOM_COMBAT_TYPE_SPELL"] 	= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_NORMAL"]		= 0.25
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_PIERCE"] 		= 0.25
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_MAGIC"] 		= 0.25
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_CHAOS"] 		= 1.00
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_SIEGE"] 		= 0.20
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_HERO"] 		= 0.40
	global.DMGTABLE["CUSTOM_COMBAT_TYPE_DIVINE"]["CUSTOM_COMBAT_TYPE_SPELL"] 		= 0.25
	
	global.COMBAT_LIST_ATK[0] = "combat_atk_normal"
	global.COMBAT_LIST_ATK[1] = "combat_atk_pierce"
	global.COMBAT_LIST_ATK[2] = "combat_atk_magic"
	global.COMBAT_LIST_ATK[3] = "combat_atk_chaos"
	global.COMBAT_LIST_ATK[4] = "combat_atk_siege"
	global.COMBAT_LIST_ATK[5] = "combat_atk_hero"
	
	global.COMBAT_LIST_DEF[0] = "combat_def_none"
	global.COMBAT_LIST_DEF[1] = "combat_def_light"
	global.COMBAT_LIST_DEF[2] = "combat_def_medium"
	global.COMBAT_LIST_DEF[3] = "combat_def_heavy"
	global.COMBAT_LIST_DEF[4] = "combat_def_fortified"
	global.COMBAT_LIST_DEF[5] = "combat_def_divine"
	
	local HeroLookupList = LoadKeyValues( "scripts/npc/herolist.txt" )
	local i = 1
	for k, v in pairs(HeroLookupList) do
		if v ~= 0 then
			global.HEROLIST[i] = k
			i = i + 1
		end
	end
	
	-- Register Convars
	Convars:RegisterCommand( "call1", function(...) return self:call1( ... ) end, "Call function 1", FCVAR_CHEAT )
	
	-- Event Hooks
	ListenToGameEvent( "dota_inventory_changed", Dynamic_Wrap(GameMode, 'OnItemPurchased'), self )

	-- Thinkers
	GameRules:GetGameModeEntity():SetThink( "OnThinkAI", CAICore, "GlobalThinker", global.AI_TICK )
	GameRules:GetGameModeEntity():SetThink( "OnThinkCheckBuildingStatus", CConstruct, "GlobalThinkerConstruction", 1 )
	GameRules:GetGameModeEntity():SetThink( "OnThinkGetGamePauseState", self, "SetGameTime", 1 )
	GameRules:GetGameModeEntity():SetThink( "OnThinkCleanUpDummies", self, "CleanUp", 1 )
	GameRules:GetGameModeEntity():SetThink( "OnThinkShrineRevival", CAbilities_Core, "ShrineRevive", 1 )
	
	-- Filters
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( GameMode, "FilterExecuteOrder" ), self )

    -- Register Listener (Building Helper)
    CustomGameEventManager:RegisterListener( "update_selected_entities", Dynamic_Wrap(GameMode, 'OnPlayerSelectedEntities'))
   	CustomGameEventManager:RegisterListener( "repair_order", Dynamic_Wrap(GameMode, "RepairOrder"))  	
    CustomGameEventManager:RegisterListener( "building_helper_build_command", Dynamic_Wrap(BuildingHelper, "BuildCommand"))
	CustomGameEventManager:RegisterListener( "building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "CancelCommand"))
	
    -- Register Listener (Game Mode Voting)
    CustomGameEventManager:RegisterListener( "vote_gamemode", Dynamic_Wrap(GameMode, 'OnPlayerVote'))
	CustomGameEventManager:RegisterListener( "vote_gamemode_confirmed", Dynamic_Wrap(GameMode, 'OnPlayerVoteConfirmed'))
	
	-- Full units file to get the custom values
	GameRules.AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  	GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
  	GameRules.ItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  	GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")

  	-- Buildinger Helper
	GameRules.SELECTED_UNITS = {}
	GameRules.Blight = {}
	
	-- Game Mode Voting
	GameRules.PlayerCount 		= 0
	GameRules.VoteRoundIndex	= 0
	GameRules.DelayedFoW		= false
	GameRules.VoteCount 		= {}
	GameRules.TotalCount		= {}
	GameRules.VoteText			= {}
	
	for i = 1, 8 do
		GameRules.VoteText[i] = {}
		GameRules.TotalCount[i] = 0
	end
	
	GameRules.VoteText[1] = "Best of 3"
	GameRules.VoteText[2] = "Best of 5"
	GameRules.VoteText[3] = "Best of 7"
	GameRules.VoteText[4] = "All pick"
	GameRules.VoteText[5] = "All random"
	GameRules.VoteText[6] = "None"
	GameRules.VoteText[7] = "60s"
	GameRules.VoteText[8] = "Always ON"
	
	-- Start a new round
	NewRound()
	
end

-- Load key-values into tables

function GameMode:_readUnitKeyValues( kvItem, kvUnit )
	if kvUnit.AI_type then
		if not _G.AI_TYPE[kvItem] then
			_G.AI_TYPE[kvItem] = kvUnit.AI_type
		end
	end
	
	global.COMBAT_TYPE_ATTACK[kvItem] = kvUnit.aw_class_combat or "CUSTOM_COMBAT_TYPE_NORMAL"
	global.COMBAT_TYPE_DEFENCE[kvItem] = kvUnit.aw_class_defend or "CUSTOM_COMBAT_TYPE_FORTIFIED"
	
	global.UPGRADE[kvItem] = {}
	global.UPGRADE[kvItem].upgrade = kvUnit.upgrade or 0
	
	if string.match(kvUnit.Ability1, "upgrade") then
		local towerLookupList = LoadKeyValues( "scripts/npc/npc_units_custom.txt" )
		local s = string.gsub( kvUnit.Ability1,"tower_upgrade","tower")
		for k, v in pairs(towerLookupList) do
			if k == s then
				global.UPGRADE[kvItem].gold = v.cost or 0
				global.UPGRADE[kvItem].energy = v.energycost or 0
				global.UPGRADE[kvItem].tech = v.requiretechnology or 0
				global.UPGRADE[kvItem].primary = kvUnit.Ability1
				if string.match(kvUnit.Ability2, "upgrade") then
					global.UPGRADE[kvItem].secondary = kvUnit.Ability2
				end
				if string.match(kvUnit.Ability3, "upgrade") then
					global.UPGRADE[kvItem].alt = kvUnit.Ability3
				end
			end
		end
	end
	
	local AI_BUILD_TYPE
	
	if kvUnit.ai_build_type then
		AI_BUILD_TYPE = kvUnit.ai_build_type
	else
		AI_BUILD_TYPE = "PROTECTED"
	end
	
	return
	{
		pszLabel = kvItem or "",
		nBuildTime = kvUnit.buildtime or 0,
		nSpawnsUnit = kvUnit.spawnunit or 0,
		nSpawnedUnit = kvUnit.spawnedunit or "",
		nSpawnedNumber = kvUnit.spawnednumber or 0,
		nSpawnRate = kvUnit.spawnrate or 0,
		nAutoCast = kvUnit.auto or 0,
		nAbilityCasted = kvUnit.abilitycasted or "",
		nUpgradeAvaliable = kvUnit.upgrade or 0,
		nBuildingGoldCost = kvUnit.cost or 0,
		nBuildingEnergyCost = kvUnit.energycost or 0,
		nBuildingProvidesEnergy = kvUnit.give_energy or 0,
		nBuildingIncome = kvUnit.income or 0,
		nBuildingRequiresTech = kvUnit.requiretechnology or 0,
		nUnitRequiresAI = kvUnit.AI or 0,
		nTrainsAirUnit = kvUnit.air_unit or 0,
		nErase = kvUnit.erase or "",
		sCombat_Type_Attack = kvUnit.aw_class_combat or "",
		sCombat_Type_Defence = kvUnit.aw_class_defend or "",
		sAI_BUILD_TYPE = AI_BUILD_TYPE
	}
end

function GameMode:_readItemKeyValues( kvItem, TableName )

	if TableName.Shop == 1 then
		global.shopitem[kvItem] 						= {}
		global.shopitem[kvItem].gold_cost 				= TableName.ItemCost or 0
		global.shopitem[kvItem].energy_cost 			= TableName.EnergyCost or 0
		global.shopitem[kvItem].inventory_item 			= TableName.UseInventory or 0
		global.shopitem[kvItem].shop_stock_max 			= TableName.Stock_Max or 0
		global.shopitem[kvItem].shop_stock_interval 	= TableName.Stock_Interval or 0
		global.shopitem[kvItem].shop_initial_interval 	= TableName.Stock_Initial_Cooldown or 0
		
		global.team[DOTA_TEAM_GOODGUYS][kvItem] 				= {}
		global.team[DOTA_TEAM_BADGUYS][kvItem] 					= {}
	end
	
	return 
	{
		pszLabel = kvItem or "",
		iItemUpgradeBuildingName = TableName.unitname or ""
	}
end

function GameMode:_readBuildKeyValues( kvItem, TableName )

	global.BUILD_DATA[kvItem] = {}
	global.BUILD_DATA[kvItem][1] = TableName.a
	global.BUILD_DATA[kvItem][2] = TableName.b
	global.BUILD_DATA[kvItem][3] = TableName.c
	global.BUILD_DATA[kvItem][4] = TableName.d
	global.BUILD_DATA[kvItem][5] = TableName.e
	global.BUILD_DATA[kvItem][6] = TableName.f
	global.BUILD_DATA[kvItem][7] = TableName.g

	global.BUILD_DATA[kvItem][8] = TableName.h
	global.BUILD_DATA[kvItem][9] = TableName.i
	global.BUILD_DATA[kvItem][10] = TableName.j
	global.BUILD_DATA[kvItem][11] = TableName.k
	global.BUILD_DATA[kvItem][12] = TableName.l
	global.BUILD_DATA[kvItem][13] = TableName.m
	
	return 
	{
		pszLabel = kvItem or "",
		sTower_N1 = TableName.a or "",
		sTower_N2 = TableName.b or "",
		sTower_N3 = TableName.c or "",
		sTower_N4 = TableName.d or "",
		sTower_N5 = TableName.e or "",
		sTower_N6 = TableName.f or "",
		
		sTower_S1 = TableName.g or "",
		sTower_S2 = TableName.h or "",
		sTower_S3 = TableName.i or "",
		sTower_S4 = TableName.j or "",
		sTower_S5 = TableName.k or ""
	}
end

-- Pre-game Voting

function GameMode:OnPlayerVote( event )
	local PlayerId 	= event.PlayerID
	local vote 		= event.voteid
	local vote_type = event.vote_type
	
	if vote_type == "rounds" then
		GameRules.VoteCount[PlayerId][1] = 0
		GameRules.VoteCount[PlayerId][2] = 0
		GameRules.VoteCount[PlayerId][3] = 0
	elseif vote_type == "heros" then
		GameRules.VoteCount[PlayerId][4] = 0
		GameRules.VoteCount[PlayerId][5] = 0
	elseif vote_type == "fow" then
		GameRules.VoteCount[PlayerId][6] = 0
		GameRules.VoteCount[PlayerId][7] = 0
		GameRules.VoteCount[PlayerId][8] = 0
	end

	GameRules.VoteCount[PlayerId][vote] = 1
end

function GameMode:OnPlayerVoteConfirmed( event )
	local PlayerId 	= event.PlayerID
	
	for i = 1, 8 do
		GameRules.TotalCount[i] = GameRules.TotalCount[i] + GameRules.VoteCount[PlayerId][i]
	end
	
	local vote_index_rounds = 1
	local vote_index_heros = 4
	local vote_index_fow = 6
	
	for i = 1, 3 do
		if GameRules.TotalCount[i] > GameRules.TotalCount[vote_index_rounds] then
			vote_index_rounds = i
		end
	end
	
	if GameRules.TotalCount[5] > GameRules.TotalCount[4] then
		vote_index_heros = 5
	else
		vote_index_heros = 4
	end

	for i = 6, 8 do
		if GameRules.TotalCount[i] > GameRules.TotalCount[vote_index_fow] then
			vote_index_fow = i
		end
	end
	
	local vote_percent_rounds 	= GameRules.TotalCount[vote_index_rounds] / GameRules.PlayerCount * 100
	local vote_percent_heros 		= GameRules.TotalCount[vote_index_heros] / GameRules.PlayerCount * 100
	local vote_percent_fow 		= GameRules.TotalCount[vote_index_fow] / GameRules.PlayerCount * 100
	
	Say(nil,"Game Voting Progress", false)
	Say(nil,"Number of rounds: "..GameRules.VoteText[vote_index_rounds].." ("..tostring(vote_percent_rounds).."%)", false)
	Say(nil,"Hero Selection: "..GameRules.VoteText[vote_index_heros].." ("..tostring(vote_percent_heros).."%)", false)
	Say(nil,"Fog of War: "..GameRules.VoteText[vote_index_fow].." ("..tostring(vote_percent_fow).."%)", false)
	
end

-- Set up a new game round

function NewRound()

	-- Spawn new Ancients and set up parameters
	if global.GAME_INITIAL_ROUND == true then
		global.ENT_ANCIENT_GOOD = CreateUnitByName( "fort_goodguys" , Vector(-6570, 300, 500) , false, nil, nil, DOTA_TEAM_GOODGUYS )
		global.ENT_ANCIENT_BAD = CreateUnitByName( "fort_badguys" , Vector(6300, 300, 500) , false, nil, nil, DOTA_TEAM_BADGUYS )
	else
		if global.ENT_ANCIENT_GOOD:IsNull() == true or global.ENT_ANCIENT_GOOD:IsAlive() == false then
			global.ENT_ANCIENT_GOOD = CreateUnitByName( "fort_goodguys" , Vector(-6570, 300, 500) , false, nil, nil, DOTA_TEAM_GOODGUYS )
		end
		if global.ENT_ANCIENT_BAD:IsNull() == true or global.ENT_ANCIENT_BAD:IsAlive() == false then
			global.ENT_ANCIENT_BAD = CreateUnitByName( "fort_badguys" , Vector(6300, 300, 500) , false, nil, nil, DOTA_TEAM_BADGUYS )
		end
	end
	
	for i = 1, 2 do
		local building
		if i == 1 then
			building = global.ENT_ANCIENT_GOOD
		else
			building = global.ENT_ANCIENT_BAD
		end
		global.building[building] = {}
		global.building[building].self			= building
		global.building[building].spawns_unit 	= 0
		global.building[building].autocasting 	= 0
		global.building[building].tick			= 0
		global.building[building].constructing	= 0
		global.building[building].upgrading		= 0
		global.building[building].repair 		= 0
		global.building[building].repairer		= {}
		global.building[building].maxhealth		= building:GetMaxHealth()
		global.building[building].IsAncient		= true
		building:RemoveModifierByName("modifier_invulnerable")
	end
	
	global.LOC_ANCIENT_GOOD					= global.ENT_ANCIENT_GOOD:GetAbsOrigin()
	global.LOC_ANCIENT_BAD					= global.ENT_ANCIENT_BAD:GetAbsOrigin()
	global.team[DOTA_TEAM_GOODGUYS].Loc 	= global.LOC_ANCIENT_GOOD
	global.team[DOTA_TEAM_BADGUYS].Loc 		= global.LOC_ANCIENT_BAD
	
	-- Reset game stats
	global.NUMBEROFJUSTICESHRINE[DOTA_TEAM_GOODGUYS] = 0
	global.NUMBEROFJUSTICESHRINE[DOTA_TEAM_BADGUYS] = 0
	global.NUMBEROFHEROSHRINE[DOTA_TEAM_GOODGUYS] = 0
	global.NUMBEROFHEROSHRINE[DOTA_TEAM_BADGUYS] = 0
	global.NUMBEROFCITYOFDECAY[DOTA_TEAM_GOODGUYS] = 0
	global.NUMBEROFCITYOFDECAY[DOTA_TEAM_BADGUYS] = 0
	
	global.TEAM_RS_IN_PROGRESS[DOTA_TEAM_GOODGUYS] = false
	global.TEAM_RS_IN_PROGRESS[DOTA_TEAM_BADGUYS] = false
	
	global.GAME_BUILD_COUNT = 0
	
	-- Reset shop data
	
	local ItemKV = GameRules.ItemKV
	for k, v in pairs(ItemKV) do
		if v.Shop == 1 then
			global.team[DOTA_TEAM_GOODGUYS][k].cooldown			= v.Stock_Initial_Cooldown
			global.team[DOTA_TEAM_BADGUYS][k].cooldown			= v.Stock_Initial_Cooldown
			global.team[DOTA_TEAM_GOODGUYS][k].stock			= v.Stock_Initial
			global.team[DOTA_TEAM_BADGUYS][k].stock				= v.Stock_Initial
			global.team[DOTA_TEAM_GOODGUYS][k].replenishing		= false
			global.team[DOTA_TEAM_BADGUYS][k].replenishing		= false
			
			if v.Stock_Initial_Cooldown > 0 then
				global.team[DOTA_TEAM_GOODGUYS][k].initial_cd		= true
				global.team[DOTA_TEAM_BADGUYS][k].initial_cd		= true
			else
				global.team[DOTA_TEAM_GOODGUYS][k].initial_cd		= false
				global.team[DOTA_TEAM_BADGUYS][k].initial_cd		= false
			end
		end
	end
	
	-- Switch back to hero selection if appropriate
	
	if global.GAME_INITIAL_ROUND == false then
		GameRules:ResetToHeroSelection()
	end

end

-- Functions required to run the game

function GameMode:OnGameInProgress()

	--SET UP SHOP
	Timers:CreateTimer(function()
		for k, v in pairs(global.shopitem) do
			for i = 2, 3 do
				if global.team[i][k].stock < global.shopitem[k].shop_stock_max then --Team Stock is less than the maximum avaliable
					if global.team[i][k].replenishing == false then
						if global.team[i][k].initial_cd == true then
							global.team[i][k].cooldown = global.shopitem[k].shop_initial_interval
							global.team[i][k].initial_cd = false
						else
							global.team[i][k].cooldown = global.shopitem[k].shop_stock_interval
						end
						global.team[i][k].replenishing = true
					elseif global.team[i][k].replenishing == true then
						global.team[i][k].cooldown = global.team[i][k].cooldown - 1 --Reduce cooldown tick by 1
						if global.team[i][k].cooldown <= 0 then --Cooldown tick reaches 0
							global.team[i][k].stock = global.team[i][k].stock + 1 --Add +1 to stock
							if global.team[i][k].stock < global.shopitem[k].shop_stock_max then --If stock can be further replenished, start replenshing again
								global.team[i][k].cooldown = global.shopitem[k].shop_stock_interval
							else
								global.team[i][k].replenishing = false
							end
						end
					end
				end
			end
		end
		return 1.0
	end
	)
	
	--SET UP AUTO-REPAIR
	Timers:CreateTimer(function()
		for i = 0, 9 do
			if PlayerResource:IsValidPlayer(i) then 
				local player = PlayerResource:GetPlayer(i)
				if player ~= nil then
				local hero = player:GetAssignedHero()
					if hero ~= nil then
						local ability = hero:FindAbilityByName("abilities_worker_repair")
						if ability:GetAutoCastState() == true then
							hero.bAutoRepair = true
							if not hero:GetCurrentActiveAbility() and hero:IsIdle() == true then
								local PotentialBuildings = FindUnitsInRadius( hero:GetTeamNumber(), hero:GetOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
								if #PotentialBuildings > 0 then
									for k, v in pairs(PotentialBuildings) do
										if v:GetHealthPercent() < 100 and v:HasModifier("frost_attack_frozen") == false then
											if global.building[v] ~= nil then
												if global.building[v].constructing ~= 1 then
													hero:CastAbilityOnTarget(v, ability, i)
													break
												end
											end
										end
									end
								end
							end
						else
							hero.bAutoRepair = false
						end
					end
				end
			end
		end
		return 1.0
	end
	)
	
	
	
end

function Teleport(trigger)
	local TeamId = trigger.activator:GetTeamNumber()
	local TeamLoc
	
	if TeamId == DOTA_TEAM_GOODGUYS then
		TeamLoc = global.LOC_ANCIENT_GOOD
	else
		TeamLoc = global.LOC_ANCIENT_BAD
	end
	
	trigger.activator:SetAbsOrigin(TeamLoc)
	FindClearSpaceForUnit(trigger.activator, TeamLoc, true)
	trigger.activator:Stop()
	
	if TeamId == DOTA_TEAM_BADGUYS then
		trigger.activator:SetAngles(0, 180, 0)
	end
end

function OnEntHurt(event)
	local Attacker = event.attacker
	local Victim = event.target
	
	if Attacker == nil or Victim == nil then
		print("Something is wrong with the custom damage system (OnEntHurt)")
		return
	end
	
	local ATK_TYPE = global.COMBAT_TYPE_ATTACK[Attacker:GetUnitName()] or ""
	local DEF_TYPE = global.COMBAT_TYPE_DEFENCE[Victim:GetUnitName()] or ""
	
	local DMG_FACTOR
	local DMG
	
	if Attacker:GetUnitName() == "npc_creature_blood_fiend" then
		ATK_TYPE = ReturnCombatMod(true, Attacker)
	end
	
	if Victim:GetUnitName() == "npc_creature_blood_fiend" then
		DEF_TYPE = ReturnCombatMod(false, Victim)
	end
	
	DMG_FACTOR = global.DMGTABLE[DEF_TYPE][ATK_TYPE]
	DMG = event.damage*DMG_FACTOR
	
	if Attacker:GetUnitName() == "tower_anti_air_tower" and Victim:HasFlyMovementCapability() == true then
		DMG = DMG*3
	elseif Attacker:GetUnitName() == "npc_creature_marksman" and ( Victim:GetUnitName() == "npc_dota_badguys_fort" or Victim:GetUnitName() == "npc_dota_goodguys_fort" ) then
		DMG = DMG/3
	end
	
	Victim:SetHealth( Victim:GetHealth() + event.damage )
	
	local damageTable = {
		victim = Victim,
		attacker = Attacker,
		damage = DMG,
		damage_type = DAMAGE_TYPE_PURE,
	}
	
	ApplyDamage(damageTable)
end

-- Game events

function GameMode:OnThinkCleanUpDummies()
	local CurrentGameTime = GameRules:GetGameTime()
	for k, v in pairs(_G.DUMMY) do 
		if CurrentGameTime >= _G.DUMMY[k] then
			k:RemoveSelf()
			_G.DUMMY[k] = nil
		end
	end
	return 1
end

function GameMode:OnThinkGetGamePauseState()
	global.GAME_TIME = GameRules:GetGameTime()
	if global.FUNCTION_TICK < global.GAME_TIME then
		global.FUNCTION_TICK = GameRules:GetGameTime()
		global.GAME_PAUSED = false
		--print("Game is not paused")
	else
		global.GAME_PAUSED = true
		--print("Game paused")
	end
	return global.FUNCTION_TICK_CHECK_INTERVAL
end

function GameMode:OnItemPurchased(event)
	local PlayerId 	= event.PlayerID
	local ItemName	= event.itemname
	local ItemCost	= event.itemcost
	
	local player		= PlayerResource:GetPlayer(PlayerId)
	local hero			= player:GetAssignedHero()
	local HeroIntellect = hero:GetIntellect()
	local team			= hero:GetTeamNumber()
	
	local ItemCount 	= 0
	local StaffLevel 	= 0
	local Error			= false
	local RuneLevel		= 0
	local Set			= false
	
	for i = 0, 11 do
		local item = hero:GetItemInSlot(i)
		if item then
			if item:GetAbilityName() == ItemName then
				if global.team[team][ItemName].stock > 0 then
					if ( HeroIntellect >= global.shopitem[ItemName].energy_cost ) then
						local NewIntel = HeroIntellect - global.shopitem[ItemName].energy_cost
						hero:SetBaseIntellect(NewIntel)
					else
						Notifications:ClearBottom(PlayerId)
						Notifications:Bottom(PlayerId, {text="Not enough energy", duration=2, style={color="red"}, continue=false})
						Error = true
					end
				else
					Error = true
					Notifications:ClearBottom(PlayerId)
					local Int = math.floor( global.team[team][ItemName].cooldown )
					Notifications:Bottom(PlayerId, {text="Out of stock: "..tostring(Int).."s remaining", duration=4, style={color="orange"}, continue=false})
				end
				item:RemoveSelf()
			end
		end
	end
	
	if Error == true then
		local keys = {}
		keys.caster = hero
		CheckInventory(keys)
		hero:ModifyGold(ItemCost, false, 0)
		return
	else
		for i = 0, 5 do
			if global.player[PlayerId].item[i] then
				ItemCount = ItemCount + 1
				if global.player[PlayerId].item[i] == "item_shop_blast_staff" then
					StaffLevel = StaffLevel + 1
				elseif global.player[PlayerId].item[i] == "item_shop_rune_repair" then
					RuneLevel = RuneLevel + 1
				end
			elseif Set == false and not global.player[PlayerId].item[i] and global.shopitem[ItemName].inventory_item > 0  then
				-- To make for persistence item only
				Set = true
				ItemCount = ItemCount + 1
				global.player[PlayerId].item[i] = ItemName
				if global.player[PlayerId].item[i] == "item_shop_blast_staff" then
					StaffLevel = StaffLevel + 1
				elseif global.player[PlayerId].item[i] == "item_shop_rune_repair" then
					RuneLevel = RuneLevel + 1
				end
				if i >= 5 then
					--print("This is the last spare slot")
				end
			end
		end
	end
	
	if (Set == true and ItemCount > 6) or (Set == false and ItemCount >= 6) then
		Notifications:ClearBottom(PlayerId)
		Notifications:Bottom(PlayerId, {text="Inventory Full", duration=2, style={color="red"}, continue=false})
		hero:ModifyGold(ItemCost, false, 0)
		hero:SetBaseIntellect(hero:GetIntellect() + global.shopitem[ItemName].energy_cost)
	else
		global.team[team][ItemName].stock = global.team[team][ItemName].stock - 1 --Take away 1 from shop's stock
		-- Item specific action here --
		if ItemName == "item_shop_blast_staff" then
			if hero:FindAbilityByName("ability_item_blast_staff") then
				hero:FindAbilityByName("ability_item_blast_staff"):SetLevel(0)
				hero:RemoveAbility("ability_item_blast_staff")
				hero:RemoveModifierByName("blast_staff_aura")
			end
			hero:AddAbility("ability_item_blast_staff")
			hero:FindAbilityByName("ability_item_blast_staff"):SetLevel(StaffLevel)
		elseif ItemName == "item_shop_rune_repair" then
			if hero:FindAbilityByName("ability_item_rune_repair") then
				hero:FindAbilityByName("ability_item_rune_repair"):SetLevel(0)
				hero:RemoveAbility("ability_item_rune_repair")
				hero:RemoveModifierByName("rune_repair_aura")
			end
			hero:AddAbility("ability_item_rune_repair")
			hero:FindAbilityByName("ability_item_rune_repair"):SetLevel(RuneLevel)
		elseif ItemName == "item_shop_cheese" then
			_G.PLAYER_TECH[PlayerId] = _G.PLAYER_TECH[PlayerId] + 1
			hero:SetBaseStrength(_G.PLAYER_TECH[PlayerId])
		elseif ItemName == "item_boost_speed" then
			local item = CreateItem("item_boost_speed", nil, nil)
			item:ApplyDataDrivenModifier(hero, hero, "item_boost_speed_aura", {})
			item = nil
		elseif ItemName == "item_boost_damage" then
			local item = CreateItem("item_boost_damage", nil, nil)
			item:ApplyDataDrivenModifier(hero, hero, "item_boost_damage_aura", {})
			item = nil
		elseif ItemName == "item_damage_double" then
			local item = CreateItem("item_damage_double", nil, nil)
			item:ApplyDataDrivenModifier(hero, hero, "item_boost_damage_aura_bonus", {})
			item = nil
			Notifications:TopToAll({text= global.team[team].Name.." activated DOUBLE DAMAGE!", duration=4, style={color="yellow"}})
		elseif ItemName == "item_damage_triple" then
			local item = CreateItem("item_damage_triple", nil, nil)
			item:ApplyDataDrivenModifier(hero, hero, "item_boost_damage_aura_bonus", {})
			item = nil
			Notifications:TopToAll({text= global.team[team].Name.." activated TRIPLE DAMAGE!", duration=4, style={color="yellow"}})
		end
	end
	
	local keys = {}
	keys.caster = hero
	CheckInventory(keys)
	
end

-- Building Helper
-- Called whenever a player changes its current selection, it keeps a list of entity indexes
function GameMode:OnPlayerSelectedEntities( event )
	local pID = event.pID

	GameRules.SELECTED_UNITS[pID] = event.selected_entities

	-- This is for Building Helper to know which is the currently active builder
	local mainSelected = GetMainSelectedEntity(pID)
	if IsValidEntity(mainSelected) and IsBuilder(mainSelected) then
		local player = PlayerResource:GetPlayer(pID)
		player.activeBuilder = mainSelected
	end
end

-- Debug commands
function GameMode:call1()

	local cmdClient = Convars:GetCommandClient()
	local hero = cmdClient:GetAssignedHero()
	local Loc = hero:GetAbsOrigin()
	
	local A = 1
	if A == 1 then
		return
	end
	
	hero:SetBaseIntellect(5000)
	hero:SetGold(10000, false)
	
	local creature = CreateUnitByName( "npc_creature_murloc" , Loc , true, cmdClient, cmdClient, DOTA_TEAM_BADGUYS )
	creature:SetControllableByPlayer( 0, true )
	creature:SetAttackCapability(1)
	creature:SetBaseDamageMin(100)
	creature:SetBaseDamageMax(100)
	creature:SetBaseHealthRegen(11000)
	--creature:SetHealth(100)
	creature:SetBaseManaRegen(0)
	creature:SetMana(0)
	global.creep[creature] 					= {}
	global.creep[creature].self 			= creature
	global.creep[creature].acqrange			= 800
	global.creep[creature].UserTeamId		= DOTA_TEAM_BADGUYS
	global.creep[creature].PlayerId			= 0
	
	-- global.LOC_ANCIENT_GOOD
	
	local A = 1
	if A == 1 then
		return
	end
	
	local creature = CreateUnitByName( "npc_creature_blood_fiend" , Loc , true, cmdClient, cmdClient, DOTA_TEAM_BADGUYS )
	creature:SetControllableByPlayer( 0, true )
	creature:SetAttackCapability(0)
	
end