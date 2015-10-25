local global = require( "vars" )

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:_OnConnectFull(keys)
  GameMode:_CaptureGameMode()
end

-- The overall game state has changed
function GameMode:_OnGameRulesStateChange(keys)
	local newState = GameRules:State_Get()
	
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		for i = 0, 9 do
			if PlayerResource:IsValidPlayer(i) then
				GameRules.PlayerCount = GameRules.PlayerCount + 1
				GameRules.VoteCount[i] = {}
				for count = 1, 8 do
					if count == 1 or count == 4 or count == 6 then
						GameRules.VoteCount[i][count] = 1
					else
						GameRules.VoteCount[i][count] = 0
					end
				end
			end
		end
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION and self.bFirstInitialization == true then
		self.bFirstInitialization = false
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .5
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
			if PlayerResource:HaveAllPlayersJoined() then
				GameMode:PostLoadPrecache()
				if USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS then
					for i=0,9 do
					if PlayerResource:IsValidPlayer(i) then
						local color = TEAM_COLORS[PlayerResource:GetTeam(i)]
						PlayerResource:SetCustomPlayerColor(i, color[1], color[2], color[3])
					end
				end
			end
			return 
		end
		return 1
		end
	  })
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if self.bShopInitialized == false then
			self.bShopInitialized = true
			GameMode:OnGameInProgress()
		end
		
		--SET UP INCOME
		Timers:CreateTimer( "IncomeTimer", {
		endTime = 10, 
		callback = function()
			if global.GAME_TIME_IS_FIXED == true then
				GameRules:SetTimeOfDay( global.GAME_TIME_FIXED )
			end
			
			for i = 0, 9 do
				if PlayerResource:IsValidPlayer(i) then 
					local player = PlayerResource:GetPlayer(i)
					
					if player ~= nil then
						local hero = player:GetAssignedHero()
						if hero then
							local count = 1
							local BonusIncome = 0
							local FinalIncome = ((_G.PLAYER_INCOME[i]*global.INCOME_FACTOR*global.INCOME_PERCENT))
							local IncomeAfterTax
							local TaxIncome
							local TaxPercent = 0
							local TaxDeduction = 0
						
							while count <= _G.PLAYER_INCOME_BOX[i] do
								BonusIncome = BonusIncome + global.INCOME_BOX_BASE*(global.INCOME_BOX_CUMULATIVE_REDUCTION^count)
								count = count + 1
							end
							
							FinalIncome = FinalIncome * (1+BonusIncome)
							TaxIncome = FinalIncome - global.INCOME_NO_TAX_THRESHOLD
							
							while TaxIncome > 0 do
								TaxPercent = TaxPercent + global.INCOME_TAX_PROGRESSIVE_PERCENT
								TaxIncome = TaxIncome - global.INCOME_TAX_PROGRESSIVE_STEP
							end
							
							if TaxPercent > global.INCOME_TAX_MAXIMUM_PERCENT then
								TaxPercent = global.INCOME_TAX_MAXIMUM_PERCENT
							end
							
							if FinalIncome > global.INCOME_NO_TAX_THRESHOLD then
								FinalIncome = ((FinalIncome - global.INCOME_TAX_PROGRESSIVE_STEP) * (1-TaxPercent)) + global.INCOME_TAX_PROGRESSIVE_STEP
							end
							
							hero:ModifyGold(FinalIncome, false, 0)
							hero:SetBaseAgility(0)
							hero:ModifyAgility(FinalIncome)
						end
					end
				end
			end
			return global.INCOME_DURATION
		end
		})

	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		if GameRules.DelayedFoW	== true then
			Timers:CreateTimer({
				endTime = 60,
				callback = function()
					GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
				end
			  })
		end
		Notifications:ClearTopFromAll()
		Notifications:TopToAll({text="Welcome to Ancient Wars", duration=30.0, style={color="yellow"}, continue=false})
		Notifications:TopToAll({text="Game is "..GameRules.VoteText[GameRules.VoteRoundIndex]..", Good Luck!", duration=30.0, style={color="red"}, continue=false})
		
		for i = 0, 9 do
			if PlayerResource:IsValidPlayer(i) then 
				local player = PlayerResource:GetPlayer(i)
				if player ~= nil then
					local hero = player:GetAssignedHero()
					if hero == nil then
						print("Player "..tostring(i).." hero cannot be found in game yet, attempting to manually create hero for player")
						local HeroName = PlayerResource:GetSelectedHeroName(i)
						if not HeroName then 
							HeroName = "npc_dota_hero_kunkka"
						end
						CreateHeroForPlayer( PlayerResource:GetSelectedHeroName(i), player)
					end
				end
			end
		end
	end
	
	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
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
		
		if vote_index_rounds == 1 then 
			global.GAME_ROUND_TO_WIN = 2
		elseif vote_index_rounds == 2 then
			global.GAME_ROUND_TO_WIN = 3
		elseif vote_index_rounds == 3 then
			global.GAME_ROUND_TO_WIN = 4
		end
		
		GameRules.VoteRoundIndex = vote_index_rounds
		
		if vote_index_heros == 5 then 
			for i = 0, 9 do
				local player = PlayerResource:GetPlayer(i)
				if player ~= nil then
					player:MakeRandomHeroSelection()
					PlayerResource:SetHasRepicked(i)
				end
			end
		end
		
		if vote_index_fow == 6 then 
			GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
		elseif vote_index_fow == 8 then
			GameRules:GetGameModeEntity():SetFogOfWarDisabled(false)
		else
			GameRules.DelayedFoW = true
		end
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:_OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		GameMode:OnHeroInGame(npc)
	end
end

-- An entity died (Ancient or creep etc.)
function GameMode:_OnEntityKilled( keys )
	local Victim = EntIndexToHScript( keys.entindex_killed )
	local Attacker = nil
	if keys.entindex_attacker ~= nil then
		Attacker = EntIndexToHScript( keys.entindex_attacker )
	end
	
	if Victim:IsAncient() == true then -- Ancient is destroyed, start a new round or end the game
		local VictoryTeam 	= Victim:GetOpposingTeamNumber()
		local DefeatTeam 	= Victim:GetTeam()
		local TextScore
		
		Timers:RemoveTimer("IncomeTimer")

		global.ENDROUND_TIMER = 35
		
		Notifications:ClearTopFromAll()
		global.GAME_INITIAL_ROUND = false
		global.team[VictoryTeam].Score = global.team[VictoryTeam].Score + 1
		
		TextScore = "Score: Radiant "..global.team[DOTA_TEAM_GOODGUYS].Score.." - Dire "..global.team[DOTA_TEAM_BADGUYS].Score
		Notifications:TopToAll({text=global.team[VictoryTeam].VictoryText, duration=30.0, style={color=global.team[VictoryTeam].VictoryColor}})
		Notifications:TopToAll({text=TextScore, duration=30.0, style={color="red"}})
		
		EmitGlobalSound("Dire.ancient.Destruction")
		EmitGlobalSound("diretide_roshdeath_Stinger")
		
		local creature = CreateUnitByName( "npc_dummy" , global.team[DefeatTeam].Loc , false, nil, nil, VictoryTeam )
		RemoveEntityTimed(creature, 30)
		
		local Effect = {}
		local nFXIndex
		Effect[0] = "particles/dire_fx/dire_ancient_base001_destruction_d.vpcf"
		Effect[1] = "particles/dire_fx/dire_ancient_base001_destruction_e.vpcf"
		Effect[2] = "particles/dire_fx/dire_ancient_base001_destruction_f.vpcf"
		Effect[3] = "particles/dire_fx/dire_ancient_base001_destruction_g.vpcf"
		Effect[4] = "particles/dire_fx/dire_ancient_base001_destruction_h.vpcf"
		Effect[5] = "particles/dire_fx/dire_ancient_base001_destruction_i.vpcf"
		Effect[6] = "particles/dire_fx/dire_ancient_base001_destruction_k.vpcf"
		
		for i= 1, 6 do
			nFXIndex = ParticleManager:CreateParticle( Effect[i], PATTACH_ABSORIGIN, creature )
			ParticleManager:SetParticleControl( nFXIndex, 0, global.team[DefeatTeam].Loc )
			ParticleManager:SetParticleControl( nFXIndex, 1, global.team[DefeatTeam].Loc )
			ParticleManager:SetParticleControl( nFXIndex, 2, global.team[DefeatTeam].Loc )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
		
		GameRules:GetGameModeEntity():SetTopBarTeamValue( DOTA_TEAM_GOODGUYS, global.team[DOTA_TEAM_GOODGUYS].Score )
		GameRules:GetGameModeEntity():SetTopBarTeamValue( DOTA_TEAM_BADGUYS, global.team[DOTA_TEAM_BADGUYS].Score )
       
		-- Remove all creeps and remove from creeps table
		for k, v in pairs (global.creep) do
			if k then
				if k:IsHero() == false then
					k:RemoveSelf()
				end
			end
			global.creep[k] = nil
		end

		-- Remove all buildings and remove from buildings table
		for k, v in pairs (global.building) do
			if k then
				k:RemoveSelf()
			end
			global.building[k] = nil
		end
		
		for i = 0, 9 do
			if PlayerResource:IsValidPlayer(i) then
				local player = PlayerResource:GetPlayer(i)
				if player ~= nil then
					local hero = player:GetAssignedHero()
					if hero then
						PlayerResource:SetCameraTarget(i, creature)
						hero:AddNoDraw()
					end
				end
			end
		end
		
		if global.team[VictoryTeam].Score >= global.GAME_ROUND_TO_WIN then
			-- Game is won
			local WinDiff = global.team[VictoryTeam].Score - global.team[DefeatTeam].Score
			local WinText = "The "..global.team[VictoryTeam].Name.." is VICTORIOUS!!! "
			
			Notifications:TopToAll({text=WinText, duration=30.0, style={color="white"}})
			
			if WinDiff == 1 then
				Notifications:TopToAll({text="defeating the "..global.team[DefeatTeam].Name.." in a close game!", duration=30.0, style={color="white"}, continue=true})
			elseif WinDiff == 2 then
				Notifications:TopToAll({text="with a resounding victory against the "..global.team[DefeatTeam].Name.."!!", duration=30.0, style={color="white"}, continue=true})
			elseif WinDiff > 2 then
				Notifications:TopToAll({text="with a DOMINATING victory against the "..global.team[DefeatTeam].Name.."!!", duration=30.0, style={color="white"}, continue=true})
			end

			Timers:CreateTimer({
				endTime = 10,
				callback = function()
				  GameRules:SetGameWinner(VictoryTeam)
				end
			  })
		else
			-- Proceed to next round
			local GoalText = "Total rounds needed to win: "..tostring(global.GAME_ROUND_TO_WIN)
			Notifications:TopToAll({text=GoalText, duration=30.0, style={color="white"}})
			
			Timers:CreateTimer({
			callback = function()
				global.ENDROUND_TIMER = global.ENDROUND_TIMER - 5
				Notifications:ClearBottomFromAll()
				Notifications:BottomToAll({text=tostring(global.ENDROUND_TIMER).." seconds until next round", duration=4.8, style={color="white"}})
				if global.ENDROUND_TIMER > 0 then
					return 4.99
				else
					NewRound()
				end
			end})
		end
		return
	elseif Attacker then
		if Attacker:IsHero() == true or ( Attacker:IsBuilding() == true and Attacker:GetAttackDamage() > 0 ) then
			return
		else
			local AttackerOwner = Attacker:GetOwner()
			if AttackerOwner ~= nil then
				local AttackerId = AttackerOwner:GetPlayerID()
				local hero 		= AttackerOwner:GetAssignedHero()
				
				if Attacker:HasModifier("hell_fist_target") == true then
					print("Hell Fist - No Gold Given")
					return
				else
					Victim:RespawnUnit()
					Victim:Kill(nil, hero)
				end
				
				if Victim:IsBuilding() == true then
					PlayerResource:SetGold(AttackerId, 0, true)
				end
			end
		end
	end
	
end