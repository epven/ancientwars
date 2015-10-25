--print("[ai_core.lua] - Script Initiated")
local global = require( "vars" )

NecroSummon = { 
[1] = "npc_creature_skeleton_warrior", 
[2] = "npc_creature_skeleton_archer", 
[3] = "npc_creature_skeletal_mage",

[4] = "npc_creature_greater_skeleton_warrior",
[5] = "npc_creature_greater_skeleton_archer",
[6] = "npc_creature_greater_skeletal_mage",
[7] = "npc_creature_skeleton_hero", 

[8] = "npc_creature_skeleton_hero",
[9] = "npc_creature_skeleton_general"
}

if CAICore == nil then
	--print("[ai_core.lua] - AI Core Class Created")
	CAICore = class({})
end

--[AI MODULE][COMMON]: Return a valid target to attack
function ReturnValidTarget( Arg_CallingPlayerId, Arg_CallingUnit, Arg_VictimUnit,
							Arg_TargetTeam, Arg_CallingUnitLoc, Arg_FindTargetRange, Arg_FindTeamFilter, Arg_FindTypeFilter, Arg_FindFlagFilter, Arg_TargetOrderFilter, 
							Arg_FindMoveType, Arg_GetTargetInCombat, Arg_UnitHasModifier, Arg_AllowFindSelf)
	
	local PotentialVictims = FindUnitsInRadius( Arg_TargetTeam, Arg_CallingUnitLoc, nil, Arg_FindTargetRange, Arg_FindTeamFilter, Arg_FindTypeFilter, Arg_FindFlagFilter, Arg_TargetOrderFilter, false )
	local NewVictim
	local Ancient = nil
	
	Arg_GetTargetInCombat = Arg_GetTargetInCombat or false
	Arg_AllowFindSelf = Arg_AllowFindSelf or false
	
	for k, v in pairs(PotentialVictims) do
		if (v:IsAncient() == true or v:IsBuilding() == true) and Arg_FindTypeFilter == DOTA_UNIT_TARGET_ALL and Ancient == nil then -- The first instance of a building is found
			Ancient = v
		end
		
		if (v:IsHero() == false and v:IsAlive() == true) then
			if (Arg_AllowFindSelf == false and v ~= Arg_CallingUnit) or (Arg_AllowFindSelf == true) then
				if (v:HasGroundMovementCapability() == true and Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_GROUND) or (v:HasFlyMovementCapability() == true and Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_FLY) or (Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_BOTH) then
					if (Arg_GetTargetInCombat == false) or (Arg_GetTargetInCombat == true and v:IsAttacking() == true) then
						if (Arg_UnitHasModifier == nil) or (v:HasModifier(Arg_UnitHasModifier)) == false then
							if v == Arg_VictimUnit and v:IsCreature() == true then --Same target found, return that target no matter what unless it is an building then we try find a new target
								return v
							end
							if v ~= Ancient then
								NewVictim = v
								return NewVictim
							end
						end
					end
				end
			end
		end
	end
	
	if Arg_FindTypeFilter == DOTA_UNIT_TARGET_ALL then
		if NewVictim then
			return NewVictim
		else
			return Ancient
		end
	end
	
	return NewVictim
end

--[AI MODULE][COMMON]: Return a valid target to cast an ability on
function ReturnValidCastTarget( Arg_CallingUnit, Arg_CastingUnitPlayerId,
							Arg_FindTargetTeam, Arg_FindVector, Arg_FindRangefromVector, 
							Arg_FindTeamFilter, Arg_FindTypeFilter, Arg_FindFlagFilter, Arg_TargetOrderFilter, 
							Arg_FindMoveType, Arg_GetTargetInCombat, Arg_FindUnitWithoutModifier, Arg_FindUnitWithModifier, Arg_AllowToFindSelf, Arg_GetRandomValidTarget)
	
	local PotentialVictims = FindUnitsInRadius( Arg_FindTargetTeam, Arg_FindVector, nil, Arg_FindRangefromVector, Arg_FindTeamFilter, Arg_FindTypeFilter, Arg_FindFlagFilter, Arg_TargetOrderFilter, false )
	local NewVictim
	local Ancient = nil
	local ValidTargets = {}
	
	Arg_GetTargetInCombat = Arg_GetTargetInCombat or false
	Arg_AllowToFindSelf = Arg_AllowToFindSelf or false
	Arg_GetRandomValidTarget = Arg_GetRandomValidTarget or false
	
	for k, v in pairs(PotentialVictims) do
		if (v:IsAncient() == true or v:IsBuilding() == true) and Arg_FindTypeFilter == DOTA_UNIT_TARGET_ALL then
			Ancient = v
		end
		
		if (v:IsHero() == false and v:IsAlive() == true) then
			if (Arg_AllowToFindSelf == false and v ~= Arg_CallingUnit) or (Arg_AllowToFindSelf == true) then
				if (v:HasGroundMovementCapability() == true and Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_GROUND) or (v:HasFlyMovementCapability() == true and Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_FLY) or (Arg_FindMoveType == DOTA_UNIT_CAP_MOVE_BOTH) then
					if (Arg_GetTargetInCombat == false) or (Arg_GetTargetInCombat == true and v:IsAttacking() == true) then
						if (Arg_FindUnitWithModifier == nil) or (v:HasModifier(Arg_FindUnitWithModifier)) == true then
							if (Arg_FindUnitWithoutModifier == nil) or (v:HasModifier(Arg_FindUnitWithoutModifier)) == false then
								if Arg_GetRandomValidTarget == true then
									table.insert(ValidTargets, v)
								else
									if Ancient and not NewVictim then --If not proper unit is found yet, but found a building
										NewVictim = Ancient
									else
										NewVictim = v
										return NewVictim
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	if Arg_GetRandomValidTarget == true then
		local index = RandomInt( 1, #ValidTargets )
		return ValidTargets[index]
	else
		return NewVictim or Ancient
	end
	return NewVictim
end

--[AI MODULE][CREATURE-RELATED-DYNAMIC]: Creature related AI
function CAICore:OnThinkAI()
	
	if global.GAME_PAUSED == true then
		return global.AI_TICK
	end

	local Victim 

	for k in pairs(global.creep) do
		if global.creep[k].self:IsNull() == false then
			if global.creep[k].self:IsAlive() == true then
				Victim = global.creep[k].self:GetAttackTarget()
				--[[***********************[AI START]***********************]]--
				--[[***********************[GENERIC]***********************]]--
				if global.creep[k].AI == "GENERIC_ATTACK_BOTH" and global.creep[k].self:IsAttacking() == false and not global.creep[k].self:GetCurrentActiveAbility() then
					global.creep[k].self:MoveToPositionAggressive(global.creep[k].enemy_ancient_loc)
				elseif global.creep[k].AI == "GENERIC_ATTACK_GROUND_ONLY" then
					if (Victim and Victim:HasFlyMovementCapability() == false) or global.creep[k].self:GetCurrentActiveAbility() then
					else
						local NewVictim = ReturnValidTarget(global.creep[k].PlayerId , global.creep[k].self, Victim, global.creep[k].EnemyTeamId, global.creep[k].self:GetOrigin(), global.creep[k].acqrange, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, DOTA_UNIT_CAP_MOVE_GROUND, false, "", false )
						if NewVictim then
							if NewVictim ~= Victim then
								global.creep[k].self:SetAttackCapability(global.creep[k].attacktype)
								global.creep[k].self:MoveToTargetToAttack(NewVictim)
							end
						else
							global.creep[k].self:SetAttackCapability( DOTA_UNIT_CAP_NO_ATTACK )
							global.creep[k].self:MoveToPosition( global.creep[k].enemy_ancient_loc )
						end
					end
				elseif global.creep[k].AI == "GENERIC_ATTACK_AIR_ONLY" then
					if (Victim and Victim:HasGroundMovementCapability() == false) or global.creep[k].self:GetCurrentActiveAbility() then
					else
						local NewVictim = ReturnValidTarget(global.creep[k].PlayerId, global.creep[k].self, Victim, global.creep[k].EnemyTeamId, global.creep[k].self:GetOrigin(), global.creep[k].acqrange, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, DOTA_UNIT_CAP_MOVE_FLY, false, "", false )
						if NewVictim then
							if NewVictim ~= Victim then
								global.creep[k].self:SetAttackCapability(global.creep[k].attacktype)
								global.creep[k].self:MoveToTargetToAttack(NewVictim)
							end
						else
							global.creep[k].self:SetAttackCapability( DOTA_UNIT_CAP_NO_ATTACK )
							global.creep[k].self:MoveToPosition( global.creep[k].enemy_ancient_loc )
						end
					end
				elseif global.creep[k].AI == "CAST_GROUND_ENEMY_NO_COMBAT" then
					local ability = global.creep[k].self:FindAbilityByName("ability_npc_warlock_chamber")
					local AbilityCooldown = ability:GetCooldownTimeRemaining() or 100
					if ( ability:IsNull() == true ) or ( ability:IsInAbilityPhase() == true ) then
					else
						if AbilityCooldown <= 0 then
							local NewVictim = ReturnValidTarget(global.creep[k].PlayerId, global.creep[k].self, Victim, global.creep[k].EnemyTeamId, global.creep[k].self:GetOrigin(), global.creep[k].acqrange, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, DOTA_UNIT_CAP_MOVE_GROUND, false, "", false )
							if NewVictim then
								if NewVictim:IsAncient() == true then
									global.creep[k].self:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
									global.creep[k].self:MoveToTargetToAttack(NewVictim)
								else
									global.creep[k].self:SetBaseMoveSpeed(300)
									global.creep[k].self:CastAbilityOnPosition(NewVictim:GetCenter(), ability, global.creep[k].PlayerId)
								end
							else
								global.creep[k].self:SetBaseMoveSpeed(300)
								global.creep[k].self:MoveToPosition( global.creep[k].enemy_ancient_loc )
							end
						elseif AbilityCooldown > 0 then
							global.creep[k].self:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
							global.creep[k].self:MoveToPosition( global.creep[k].team_ancient_loc )
							global.creep[k].self:SetBaseMoveSpeed(135)
						end
					end
				end
				--[[***********************[AI END]***********************]]--
			else
				global.creep[k] = nil
			end
		else
			-- This should technically never run
			global.creep[k] = nil
		end
	end

	return global.AI_TICK
end

--[[ AI: DATA DRIVEN ABILITIES HOOK
	The below functions are executed from thinkers defined in npc_abilities_custom.txt, therefore thinkers are attached to particular unit(s) with applied modifier
	Because of this, we can define when the thinker are activated (always, on attacked, damage taken, new modifier applied from another abilities etc.), and how long it runs for using 'Duration' in npc_abilities_custom.txt
	We can set it to always run by not defining 'Duration', and we can manually destroy the Thinker when the unit has died, or any conditions called by LUA (picked up item, levelled up, reached checkpoint etc.)
	Functions below therefore checks for conditions every defined thinker interval and run abilities/action if conditions are met
	These 'hooks' will override other AI modules, i.e. abilities will always be casted if available, instead of finding new unit to attack or continue attacking
	This will allow for almost unlimited possibilities in how we control both unit attacks and casting
]]

function ability_naga_summon(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_naga_summon")
	local creature
	
	local owner = global.creep[caster].owner
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId

	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 90 then
		caster:CastAbilityNoTarget( ability, playerId )
		for int = 1, 2 do
			creature = CreateUnitByName( "npc_creature_naga_lobster" , loc , true, global.creep[caster].hero, owner, UserTeamId )
			creature:MoveToPositionAggressive( global.creep[caster].enemy_ancient_loc )
			
			global.creep[creature] 					= {}
			global.creep[creature].self				= creature
			global.creep[creature].name 			= creature:GetUnitName()
			global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
			global.creep[creature].range 			= creature:GetAttackRange()
			global.creep[creature].attacktype		= creature:GetAttackCapability()
			global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
			
			global.creep[creature].PlayerId 		= playerId
			global.creep[creature].UserTeamId 		= UserTeamId
			global.creep[creature].EnemyTeamId 		= creature:GetOpposingTeamNumber()
			global.creep[creature].hero 			= global.creep[caster].hero
			global.creep[creature].owner 			= global.creep[caster].owner
			
			global.creep[creature].team_ancient		= global.creep[caster].team_ancient
			global.creep[creature].enemy_ancient	= global.creep[caster].enemy_ancient
			
			global.creep[creature].team_ancient_loc		= global.creep[caster].team_ancient_loc
			global.creep[creature].enemy_ancient_loc	= global.creep[caster].enemy_ancient_loc
			
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_kunkka/kunkka_ghostship_marker_splash.vpcf", PATTACH_ABSORIGIN, creature )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
	end
end

function ability_naga_purge(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_naga_purge")
	local Buff = "modifier_satyr_trickster_purge"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 20 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
	end
end

function ability_human_bless(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId

	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_crusader_blessing") or caster:FindAbilityByName("ability_npc_paladin_blessing")
	local Buff = "blessing_effect"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 35 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, true, Buff, nil, true, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
	end
end

function ability_human_resurrection(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_crusader_resurrection")
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 105 then
		local NewVictim = ReturnValidCastTarget(
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, nil, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityNoTarget( ability, playerId )
			print("FOUND A DEAD")
			print(NewVictim:GetUnitName())
		end
	end
	
end

function ability_elf_amp(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_bloodthirster_amp")
	local Buff = "modifier_slardar_amplify_damage"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 20 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
	end
end

function ability_elf_heal(event)
	local caster = event.caster

	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_sorceress_heal") or caster:FindAbilityByName("ability_npc_wizard_heal")
	local ability_secondary = caster:FindAbilityByName("ability_npc_wizard_bolt")
	local range = global.creep[caster].acqrange
		
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 20 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, true, nil, nil, true, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
			return
		end
	end
	
	if ability_secondary then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, nil, nil, false, true
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability_secondary, playerId)
			return
		end
	end
		
end

function ability_chaos_roar(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local ability = caster:FindAbilityByName("ability_npc_chaos_roar")
			
	if ability and caster:IsAttacking() == true and ability:GetCooldownTimeRemaining() <= 0 then
		caster:CastAbilityNoTarget(ability, playerId)
	end

end

function ability_chaos_curse(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_succubus_curse")
	local Buff = "modifier_tinker_laser_blind"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 20 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
		
	end
end

function ability_necro_summon(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local owner = global.creep[caster].owner
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local creature
	local ability = caster:FindAbilityByName("ability_npc_necro_summon")
	
	local NPCName = caster:GetUnitName()
	local ChanceMin
	local ChanceMax
	local SpawnNumber = 1
	
	if NPCName == "npc_creature_necromancer" then
		ChanceMin = 1
		ChanceMax = 3
	elseif NPCName == "npc_creature_mighty_necromancer" then
		ChanceMin = 1
		ChanceMax = 7
	elseif NPCName == "npc_creature_lich_king" then
		ChanceMin = 4
		ChanceMax = 9
		SpawnNumber = 2
	end
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 75 then
		caster:CastAbilityNoTarget(ability, playerId)
		for int = 1, SpawnNumber do
			local UnitToSpawn = NecroSummon[RandomInt(ChanceMin,ChanceMax)]
			
			creature = CreateUnitByName( UnitToSpawn , loc , true, global.creep[caster].hero, owner, UserTeamId )

			global.creep[creature] 					= {}
			global.creep[creature].self				= creature
			global.creep[creature].name 			= creature:GetUnitName()
			global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
			global.creep[creature].range 			= creature:GetAttackRange()
			global.creep[creature].attacktype		= creature:GetAttackCapability()
			global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
			
			global.creep[creature].PlayerId 		= playerId
			global.creep[creature].UserTeamId 		= UserTeamId
			global.creep[creature].EnemyTeamId 		= creature:GetOpposingTeamNumber()
			global.creep[creature].hero 			= global.creep[caster].hero
			global.creep[creature].owner 			= global.creep[caster].owner
			
			global.creep[creature].team_ancient		= global.creep[caster].team_ancient
			global.creep[creature].enemy_ancient	= global.creep[caster].enemy_ancient
			
			global.creep[creature].team_ancient_loc		= global.creep[caster].team_ancient_loc
			global.creep[creature].enemy_ancient_loc	= global.creep[caster].enemy_ancient_loc
			
			creature:MoveToPositionAggressive( global.creep[caster].enemy_ancient_loc )
			
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_visage/visage_summon_familiars.vpcf", PATTACH_ABSORIGIN, creature )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
	end
end

function ability_undead_slow(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_banshee_slow")
	local Buff = "modifier_lich_slow"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 25 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
		
	end
end

function ability_orc_buff(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_shaman_buff")
	local Buff = "shaman_effect"
	local range = global.creep[caster].acqrange

	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 35 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, true, true
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
	end
end

function ability_orc_ensnare(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_troll_ensnare")
	local Buff = "troll_ensnare_effect"
	local range = global.creep[caster].acqrange
	
	if ability and ability:GetCooldownTimeRemaining() <= 0 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_FLY, false, Buff, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
			NewVictim:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
		end
		
	end
end

function ability_orc_ensnare_off(event)
	event.target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end

function ability_ice_stomp(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_mag_stomp")
	local range = global.creep[caster].acqrange
		
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 25 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_GROUND, false, nil, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityNoTarget( ability, playerId )
		end
	end
end

function ability_ice_armor(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_frost_armor") or caster:FindAbilityByName("ability_npc_greater_frost_armor")
	local Buff = "modifier_ogre_magi_frost_armor"
	local range = global.creep[caster].acqrange

	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 35 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, Buff, nil, true, true
												)
		if NewVictim then
			caster:CastAbilityOnTarget(NewVictim, ability, playerId)
		end
	end
end

function ability_ice_howl(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_howl")
	local range = global.creep[caster].acqrange
		
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 30 then
		local NewVictim = ReturnValidCastTarget(	
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_GROUND, false, nil, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityNoTarget( ability, playerId )
		end
	end
end

function ability_frost_nova(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local playerId = global.creep[caster].PlayerId
	local UserTeamId = global.creep[caster].UserTeamId
	local loc = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_npc_frost_nova")
	local range = global.creep[caster].acqrange
		
	if ability and ability:GetCooldownTimeRemaining() <= 0 and caster:GetMana() >= 80 then
		local NewVictim = ReturnValidCastTarget(
												caster, playerId, 
												UserTeamId, loc, range,
												DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST,
												DOTA_UNIT_CAP_MOVE_BOTH, false, nil, nil, false, false
												)
		if NewVictim then
			caster:CastAbilityOnPosition(NewVictim:GetOrigin(), ability, playerId)
		end
	end
end



--Tower Abilities--
--Core AI--
function tower_AI(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	if not global.building[caster] then
		return
	end
	
	if global.building[caster].constructing == 1 or global.building[caster].autocasting == 0 then
		return
	end
	
	local AbilityToCast		= caster:FindAbilityByName(global.building[caster].ability)
	local CasterPlayerId	= global.building[caster].PlayerId
	local CasterName		= caster:GetUnitName()

	if AbilityToCast and caster:GetMana() >= 100 and AbilityToCast:GetCooldownTimeRemaining() <= 0 then
		if CasterName == "tower_gjallarhorn" then
			local range = AbilityToCast:GetCastRange()
			local NewVictim = ReturnValidCastTarget(	
													caster, CasterPlayerId, 
													global.building[caster].UserTeamId, global.building[caster].location, range,
													DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
													DOTA_UNIT_CAP_MOVE_BOTH, false, "gjallarhorn_aura", nil, false, false
													)
			if NewVictim then
				caster:CastAbilityNoTarget(AbilityToCast, CasterPlayerId)
				global.building[caster].tick = 0
			end
		else
			caster:CastAbilityNoTarget(AbilityToCast, CasterPlayerId)
			global.building[caster].tick = 0
		end
	end
end

--Tower abilities code--

function ability_artillery_attack(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local AbilityUsedName 	= event.abilityname
	local PlayerId			= global.building[caster].PlayerId
	local PlayerTeam 		= global.building[caster].UserTeamId

	local PotentialVictims = FindUnitsInRadius( PlayerTeam, Vector(0, 0, 0), nil, 50000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false )
	local m = RandomInt(1, #PotentialVictims)
	local TargetUnit = PotentialVictims[m]
	
	if TargetUnit then
		local TargetVec  = TargetUnit:GetOrigin()
		
		local mRandomAngle = RandomInt(0, 360)
		local mRandomDist = RandomInt(0, 600)
		
		local newX = TargetVec.x + mRandomDist*math.cos(mRandomAngle)
		local newY = TargetVec.y + mRandomDist*math.sin(mRandomAngle)
		
		local NewVector = TargetVec + Vector(newX, newY, TargetVec.z)
		
		local creature = CreateUnitByName( "npc_dummy" , NewVector , false, global.building[caster].hero, global.building[caster].owner, PlayerTeam )
		local ability = creature:FindAbilityByName("ability_tower_artillery_damage")
		creature:CastAbilityImmediately( ability,  PlayerId )
		RemoveEntityTimed(creature, 3)
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_ABSORIGIN, creature )
		ParticleManager:SetParticleControl( nFXIndex, 0, NewVector )
		ParticleManager:SetParticleControl( nFXIndex, 1, NewVector )
		ParticleManager:SetParticleControl( nFXIndex, 2, NewVector )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
	end
end

function tower_earthquake(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterOwner		= global.building[caster].owner
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, CasterOwner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_earthquake_p")
			creature:CastAbilityNoTarget(CastAbility,  CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 5)
	
			local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_ursa/ursa_earthshock_rocks.vpcf", PATTACH_ABSORIGIN, Target )
			ParticleManager:ReleaseParticleIndex( nFX )
		end
	end
end

function tower_control_enemy(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterOwner		= global.building[caster].owner
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()

	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		
		if Target then
			local TargetName = Target:GetUnitName()
			local TargetMaxHP = Target:GetMaxHealth()
			local TargetHP = Target:GetHealth()
			local TargetMP = Target:GetMana()
			local TargetVec = Target:GetAbsOrigin()
			
			local creature = CreateUnitByName( TargetName , TargetVec , false, global.building[caster].hero, CasterOwner, CasterTeam )
			
			creature:SetMaxHealth(TargetMaxHP)
			creature:SetHealth(TargetHP)
			creature:SetMana(TargetMP)
			
			global.creep[creature] 					= {}
			global.creep[creature].self				= creature
			global.creep[creature].name 			= creature:GetUnitName()
			global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
			global.creep[creature].range 			= creature:GetAttackRange()
			global.creep[creature].attacktype		= creature:GetAttackCapability()
			global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
			
			global.creep[creature].PlayerId 		= CasterPlayerId
			global.creep[creature].UserTeamId 		= CasterTeam
			global.creep[creature].EnemyTeamId 		= caster:GetOpposingTeamNumber()
			global.creep[creature].hero 			= global.building[caster].hero
			global.creep[creature].owner 			= global.building[caster].owner  	
			
			local TargetAncient
			local TeamAncient
			local TargetAncientLoc
			local TeamLoc
			
			if CasterTeam == DOTA_TEAM_GOODGUYS then
				TargetAncient = global.ENT_ANCIENT_BAD
				TeamAncient = global.ENT_ANCIENT_GOOD
				TargetAncientLoc = global.LOC_ANCIENT_BAD
				TeamLoc = global.LOC_ANCIENT_GOOD
			else
				TargetAncient = global.ENT_ANCIENT_GOOD
				TeamAncient = global.ENT_ANCIENT_BAD
				TargetAncientLoc = global.LOC_ANCIENT_GOOD
				TeamLoc = global.LOC_ANCIENT_BAD
			end
			
			global.creep[creature].team_ancient			= TeamAncient
			global.creep[creature].enemy_ancient		= TargetAncient
			global.creep[creature].team_ancient_loc		= TeamLoc
			global.creep[creature].enemy_ancient_loc	= TargetAncientLoc
			
			creature:MoveToPositionAggressive(TargetAncientLoc)

			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_treant/treant_overgrowth_vine_core_sparkly.vpcf", PATTACH_ABSORIGIN, creature )
			ParticleManager:SetParticleControl( nFXIndex, 0, creature:GetOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, creature:GetOrigin() )
			
			Target:RemoveSelf()
		end
	end
end

function tower_tsunami(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , CasterVector , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_naga_tsunami_p")
			
			creature:CastAbilityOnTarget(Target, CastAbility,  CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 10)

		end
	end
	
end

function tower_hex(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_elf_hex_p")
			
			creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 2)
		end
	end
	
end

function tower_beam(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_elf_beam_p")
			
			creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 3)
		end
	end
	
end

function tower_eraser(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterName		= caster:GetUnitName()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterOwner		= global.building[caster].owner
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	local TargetName 
	local StrErase
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			TargetName = Target:GetUnitName()
		else
			return
		end
		
		print("Target Acquired = "..TargetName)

		for _, v in pairs(_G.kvUnitData) do
			if v.pszLabel == TargetName then
				print("Found Building data")
				print("@@@@"..v.nErase)
				if v.nErase then
					StrErase = v.nErase
					print("Target Acquired List = "..StrErase)
				else
					print("This building does not spawn units")
					return
				end
				break
			end
		end
	end
	
	local NewTarget = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewTarget and StrErase then
		print("Looking for target")
		for k, v in pairs(NewTarget) do
			if string.match(StrErase, v:GetUnitName()) then
				print("Killing unit: "..v:GetUnitName())
				v:Kill(AbilityToCast, caster)
			end
		end
	end
	
end

function tower_volcano(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_chaos_erupt_p")
			
			creature:CastAbilityNoTarget(CastAbility, CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 3)
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", PATTACH_ABSORIGIN, Target )
			ParticleManager:SetParticleControl( nFXIndex, 0, Target:GetOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Target:GetOrigin() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
	end
	
end

function tower_chaos_present(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterOwner		= global.building[caster].owner
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()

	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local SpawnCreature
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		
		if Target then
			local TargetLoc = Target:GetAbsOrigin()
			local Chance = RandomInt(0, 7)
			local Bounty = Target:GetGoldBounty()

			if Chance == 0 then
				Target:Kill( AbilityToCast, global.building[caster].hero )
			elseif Chance == 1 then
				Target:Kill( AbilityToCast, caster )
			elseif Chance == 2 then
				Target:Kill( AbilityToCast, caster)
				PlayerResource:ModifyGold( CasterPlayerId, -Bounty, false, 0 )
				SpawnCreature = CreateUnitByName( "npc_creature_mutation" , TargetLoc , true, global.building[caster].hero, CasterOwner, CasterTeam )
				local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform_d.vpcf", PATTACH_ABSORIGIN, SpawnCreature )
				ParticleManager:ReleaseParticleIndex( nFX )
			elseif Chance == 3 then
				local creature = CreateUnitByName( "npc_dummy" , TargetLoc , false, global.building[caster].hero, CasterOwner, CasterTeam )
				local CastAbility = creature:FindAbilityByName("ability_tower_elf_hex_p")
				creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
				creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
				RemoveEntityTimed(creature, 3)
			elseif Chance == 4 then
				Target:SetHealth(Target:GetHealth()-500)
				local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform_d.vpcf", PATTACH_ABSORIGIN, Target )
				ParticleManager:ReleaseParticleIndex( nFX )
			elseif Chance == 5 then
				Target:SetMaxHealth(Target:GetMaxHealth() + 400)
				Target:SetHealth(Target:GetMaxHealth())
				Target:SetBaseDamageMax(Target:GetBaseDamageMax() +25)
				Target:SetBaseDamageMin(Target:GetBaseDamageMin() +25)
				local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow_b.vpcf", PATTACH_ABSORIGIN, Target )
				ParticleManager:ReleaseParticleIndex( nFX )
			elseif Chance == 6 then
				local creature = CreateUnitByName( "npc_dummy" , TargetLoc , false, global.building[caster].hero, CasterOwner, CasterTeam )
				local CastAbility = creature:FindAbilityByName("ability_tower_chaos_blast_p")
				creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
				creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
				RemoveEntityTimed(creature, 3)
			elseif Chance == 7 then
			end
		end
		
		if SpawnCreature then
			local creature = SpawnCreature
		
			global.creep[creature] 					= {}
			global.creep[creature].self				= creature
			global.creep[creature].name 			= creature:GetUnitName()
			global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
			global.creep[creature].range 			= creature:GetAttackRange()
			global.creep[creature].attacktype		= creature:GetAttackCapability()
			global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
			
			global.creep[creature].PlayerId 		= CasterPlayerId
			global.creep[creature].UserTeamId 		= CasterTeam
			global.creep[creature].EnemyTeamId 		= caster:GetOpposingTeamNumber()
			global.creep[creature].hero 			= global.building[caster].hero
			global.creep[creature].owner 			= global.building[caster].owner
			
			local TargetAncient
			local TeamAncient
			local TargetAncientLoc
			local TeamLoc
			
			if CasterTeam == DOTA_TEAM_GOODGUYS then
				TargetAncient = global.ENT_ANCIENT_BAD
				TeamAncient = global.ENT_ANCIENT_GOOD
				TargetAncientLoc = global.LOC_ANCIENT_BAD
				TeamLoc = global.LOC_ANCIENT_GOOD
			else
				TargetAncient = global.ENT_ANCIENT_GOOD
				TeamAncient = global.ENT_ANCIENT_BAD
				TargetAncientLoc = global.LOC_ANCIENT_GOOD
				TeamLoc = global.LOC_ANCIENT_BAD
			end
			
			global.creep[creature].team_ancient			= TeamAncient
			global.creep[creature].enemy_ancient		= TargetAncient
			global.creep[creature].team_ancient_loc		= TeamLoc
			global.creep[creature].enemy_ancient_loc	= TargetAncientLoc
			
			creature:MoveToPositionAggressive(TargetAncientLoc)
		end
	end
end

function tower_hellfist(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()

	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_hell_fist_p")
			
			creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
			creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
			RemoveEntityTimed(creature, 5)

			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_ABSORIGIN, Target )
			ParticleManager:SetParticleControl( nFXIndex, 0, Target:GetOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Target:GetOrigin() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
	end
end

function tower_sudden_death(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()

	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_life_stealer/life_stealer_rage_end.vpcf", PATTACH_ABSORIGIN, Target )
			local TargetOrigin = Target:GetOrigin()
			ParticleManager:SetParticleControl( nFXIndex, 0, TargetOrigin )
			ParticleManager:SetParticleControl( nFXIndex, 1, TargetOrigin )
			ParticleManager:SetParticleControl( nFXIndex, 2, TargetOrigin )
			ParticleManager:SetParticleControl( nFXIndex, 3, TargetOrigin )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			Target:Kill(AbilityToCast, caster)
		end
	end
end

function tower_raise_dead(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterOwner		= global.building[caster].owner
	local CasterPlayerId	= global.building[caster].PlayerId
	local CasterTeam 		= global.building[caster].UserTeamId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	local CasterName		= caster:GetUnitName()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		
		if Target then
			local TargetLoc = Target:GetAbsOrigin()
			local ChanceMin
			local ChanceMax
			local SpawnNumber = 1
			
			if CasterName == "tower_skull_pile" then
				ChanceMin = 1
				ChanceMax = 3
			else
				ChanceMin = 1
				ChanceMax = 9
			end
			
			local UnitToSpawn = NecroSummon[RandomInt(ChanceMin,ChanceMax)]
			local creature = CreateUnitByName( UnitToSpawn , TargetLoc , true, global.building[caster].hero, CasterOwner, CasterTeam )
			local nFX = ParticleManager:CreateParticle( "particles/items_fx/necronomicon_spawn_warrior_dust.vpcf", PATTACH_ABSORIGIN, Target )
			ParticleManager:ReleaseParticleIndex( nFX )
			
			global.creep[creature] 					= {}
			global.creep[creature].self				= creature
			global.creep[creature].name 			= creature:GetUnitName()
			global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
			global.creep[creature].range 			= creature:GetAttackRange()
			global.creep[creature].attacktype		= creature:GetAttackCapability()
			global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
			
			global.creep[creature].PlayerId 		= CasterPlayerId
			global.creep[creature].UserTeamId 		= CasterTeam
			global.creep[creature].EnemyTeamId 		= caster:GetOpposingTeamNumber()
			global.creep[creature].hero 			= global.building[caster].hero
			global.creep[creature].owner 			= global.building[caster].owner
			
			local TargetAncient
			local TeamAncient
			local TargetAncientLoc
			local TeamLoc
			
			if CasterTeam == DOTA_TEAM_GOODGUYS then
				TargetAncient = global.ENT_ANCIENT_BAD
				TeamAncient = global.ENT_ANCIENT_GOOD
				TargetAncientLoc = global.LOC_ANCIENT_BAD
				TeamLoc = global.LOC_ANCIENT_GOOD
			else
				TargetAncient = global.ENT_ANCIENT_GOOD
				TeamAncient = global.ENT_ANCIENT_BAD
				TargetAncientLoc = global.LOC_ANCIENT_GOOD
				TeamLoc = global.LOC_ANCIENT_BAD
			end
			
			global.creep[creature].team_ancient			= TeamAncient
			global.creep[creature].enemy_ancient		= TargetAncient
			global.creep[creature].team_ancient_loc		= TeamLoc
			global.creep[creature].enemy_ancient_loc	= TargetAncientLoc
			
			creature:MoveToPositionAggressive(TargetAncientLoc)
			
		end
	end
end

function tower_poison_area(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()
	
	local NewVictim = FindUnitsInRadius(CasterTeam, CasterVector, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	
	if NewVictim then
		local Target = NewVictim[RandomInt(1, #NewVictim)]
		if Target then
			local creature = CreateUnitByName( "npc_dummy" , Target:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
			local CastAbility = creature:FindAbilityByName("ability_tower_orc_poison_effect")
			
			creature:CastAbilityOnTarget(Target, CastAbility, CasterPlayerId)
			RemoveEntityTimed(creature, 25)
		end
	end
	
end

function tower_tribal_bless(event)
	local Ability = event.target:FindAbilityByName("ability_npc_tribal_demolish")
	if Ability then
		Ability:SetLevel(1)
	end
	Ability = event.target:FindAbilityByName("ability_npc_tribal_critical")
	if Ability then
		Ability:SetLevel(1)
	end
	Ability = event.target:FindAbilityByName("ability_npc_tribal_evasion")
	if Ability then
		Ability:SetLevel(1)
	end
end

function tower_chilling_mushroom(event)
	local caster = event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	local range 			= AbilityToCast:GetCastRange()

	local NewVictim = ReturnValidCastTarget(	
											caster, CasterPlayerId, 
											CasterTeam, Vector(0,0,0), 50000,
											DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
											DOTA_UNIT_CAP_MOVE_FLY, false, nil, nil, false, true
											)
											
	if NewVictim then
		local creature = CreateUnitByName( "npc_dummy" , caster:GetAbsOrigin() , false, global.building[caster].hero, global.building[caster].owner, CasterTeam )
		local CastAbility = creature:FindAbilityByName("ability_tower_chilling_mushroom_dmg")
		creature:CastAbilityOnTarget(NewVictim, CastAbility, CasterPlayerId)
		creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
		RemoveEntityTimed(creature, 3)
	end
end

function tower_world_freeze(event)
	local caster			= event.caster
	
	if caster == nil then
		return
	end
	
	local CasterVector 		= caster:GetOrigin()
	local CasterTeam 		= global.building[caster].UserTeamId
	local CasterPlayerId	= global.building[caster].PlayerId
	local AbilityToCast		= caster:GetAbilityByIndex(0)
	
	local AngleMin
	local AngleMax

	if CasterTeam == DOTA_TEAM_BADGUYS then
		AngleMin = 90
		AngleMax = 270
	else
		AngleMin = -90
		AngleMax = 90
	end
	
	for i = 0, 2 do
		local creature = CreateUnitByName( "npc_dummy_world_freezer" , caster:GetOrigin() , true, global.building[caster].hero, global.building[caster].owner, CasterTeam )
		local Angle = RandomFloat(AngleMin, AngleMax) * math.pi / 180
		local Dist  = 10000
		
		if Angle < 0 then
			--Angle = (Angle * - 1) + 270
		end
		
		local newX
		local newY
		local NewVector

		newX = CasterVector.x + Dist * math.cos(Angle)
		newY = CasterVector.y + Dist * math.sin(Angle)
		NewVector = Vector( newX, newY, CasterVector.z)
		
		creature:SetControllableByPlayer( 0, true )
		creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
		RemoveEntityTimed(creature, 25)
		
		Timers:CreateTimer({
		endTime = 0.2,
		callback = function()
		  creature:MoveToPosition(NewVector)
		end
		})
	end
end



--Bot AI--

function ReturnValidBuildLocation( StartingVec, Special, Team )

	local NewVec
	local DirectionX
	local DirectionY
	local Found = false
	
	local MaxStepX
	local MaxStepY
	local StepX = 0
	local StepY = 0
	local NewX = StartingVec.x
	local NewY = StartingVec.y
	
	if Team == DOTA_TEAM_GOODGUYS then
		if Special == 1 then
			DirectionX = -1
			DirectionY = -1
		else
			DirectionX = -1
			DirectionY = -1
		end
	else
		if Special == 1 then
			DirectionX = 1
			DirectionY = -1
		else
			DirectionX = 1
			DirectionY = -1
		end
	end
	
	if Special == 1 then
		MaxStepX = global.MAX_STEP_SPECIAL_X
		MaxStepY = global.MAX_STEP_SPECIAL_Y
	else
		MaxStepX = global.MAX_STEP_X
		MaxStepY = global.MAX_STEP_Y
	end
		
	NewVec = StartingVec
	
	while Found == false do
		local Blocked = false
		local IsPath = Entities:FindAllInSphere( NewVec , global.EXCLUDE_RADIUS )
		
		for k, v in pairs(IsPath) do
			if string.match(v:GetName(), "blockbuild") or v:GetClassname() == "npc_dota_holdout_tower" or v:GetClassname() == "npc_dota_creature" or v:GetClassname() == "npc_dota_fort" then
				Blocked = true
			end
		end
		
		if Blocked == true then
			NewY = NewY + (global.STEP*DirectionY)
			StepY = StepY + global.STEP
			if StepY > MaxStepY then
				NewY = StartingVec.y
				StepY = 0
				NewX = NewX + (global.STEP*DirectionX)
				StepX = StepX + global.STEP
			end
			NewVec = Vector(NewX, NewY, global.BUILDHEIGHT)
		else
			return NewVec
		end
	end
	
	return NewVec
end

function CAICore:OnThinkBotAI()
	
	if global.GAME_PAUSED == true or global.AI_STATE == false then
		return 1
	end
	
	--print("----------")
	--print("Running AI")
	
	global.TEAM_RS_IN_PROGRESS[DOTA_TEAM_GOODGUYS] = false
	global.TEAM_RS_IN_PROGRESS[DOTA_TEAM_BADGUYS] = false
	
	for _, v in pairs(global.BOTSLOT) do
	
		--print("---AI FOR BOT ID: "..tostring(v.botId).."---")
		--print("RESOURCE GOLD: "..tostring(v.gold))
		--print("RESOURCE ENERGY: "..tostring(v.energy))
	
		--REPAIR AND RS--
		local NearbyBuildings = FindUnitsInRadius( v.team, v.hero:GetOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false )
		local MostDamagedBuilding
		
		--Find the most damaged building
		for _, sv in pairs(NearbyBuildings) do
			if sv:GetHealthPercent() < 100 and not global.CONSTRUCTING[sv] then
				if MostDamagedBuilding then
					if sv:GetHealthPercent() < MostDamagedBuilding:GetHealthPercent() then
						MostDamagedBuilding = sv
					end
				else
					MostDamagedBuilding = sv
				end
			end
		end
		
		--Repair the most damaged building and use RS when building is below 20%
		--Set that if building HP is < 30%, bot must repair and not execute other commands (i.e. build)
		if MostDamagedBuilding then
			local HealthPercent = MostDamagedBuilding:GetHealthPercent()
			if HealthPercent > 20 then
				v.hero:MoveToPosition(MostDamagedBuilding:GetOrigin())
				if HealthPercent > 30 then
					v.mustrepair = false
				else
					v.mustrepair = true
				end
			elseif v.used_rs == false and global.TEAM_RS_IN_PROGRESS[v.team] == false then
				local NearbyUnits = FindUnitsInRadius( v.team, MostDamagedBuilding:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_FARTHEST, false )
				local BestTarget
				local TargetCount = 0
				
				for _, sv in pairs(NearbyUnits) do
					local NearbyTargets = FindUnitsInRadius( v.team, sv:GetOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_FARTHEST, false )
					if #NearbyTargets > TargetCount then
						BestTarget = sv
						TargetCount = #NearbyTargets
					end
				end
				
				if BestTarget and TargetCount > 5 then
					local ability = v.hero:FindAbilityByName("abilities_worker_rescuestrike")
					v.hero:CastAbilityOnPosition(BestTarget:GetOrigin(), ability, v.botId)
					v.used_rs = true
					global.TEAM_RS_IN_PROGRESS[v.team] = true
				end
			end
		end
		
		--CHECK BUILD GOAL--
		if v.mustrepair == false then --Do not try and build if a building desperately needs to be repaired instead
			if v.BuildGoal then --If queued for build or upgrade
			
				if v.upgrading == true then
					--print("BOT AI: Attempting to upgrade: "..tostring(v.BuildGoal))
				else
					--print("BOT AI: Attempting to build: "..tostring(v.BuildGoal))
				end

				if global.BOTSLOT[v.botId].gold >= v.Goal_Gold and global.BOTSLOT[v.botId].energy >= v.Goal_Energy then
					--Start the build if enough gold and energy, If not do nothing and wait
					if v.upgrading == true and (not global.CONSTRUCTING[v.BuildGoal]) then
						--print("Enough resources, calling upgrade function")
						
						local ability = v.BuildGoal:GetAbilityByIndex(0) --Find proper upgrade ability
						v.BuildGoal:CastAbilityNoTarget(ability, v.botId)
						
						v.upgrading = false
						v.buildindex = v.buildindex + 1
						v.BuildGoal = nil
					else
						--print("Enough resources, calling construction function")
						local event = {}
						local InitialLoc
						local Special = 0
						event.AbilityUsedName = v.BuildGoal
						event.hero = v.hero
						event.PlayerId = v.botId
						event.UserTeamId = v.team
						event.Owner = v.hero:GetOwner()
						event.Bot = true
						
						if v.botId < 5 then
							if v.BuildType == "OPEN" then
								InitialLoc = global.VEC_GOOD_BASE_SPECIAL
								Special = 1
							else
								InitialLoc = global.VEC_GOOD_BASE
							end
						else
							if v.BuildType == "OPEN" then
								InitialLoc = global.VEC_BAD_BASE_SPECIAL
								Special = 1
							else
								InitialLoc = global.VEC_BAD_BASE
							end
						end
						
						event.CastLocation = ReturnValidBuildLocation(InitialLoc, Special, v.team)
						
						if v.hero:IsPositionInRange(event.CastLocation, 400) == true then
							if v.Goal_Energy > 0 then
								local ability = v.hero:GetAbilityByIndex(0)
								v.hero:CastAbilityNoTarget(ability, v.botId)
								if global.BOTSLOT[v.botId][v.BuildGoal] then
									global.BOTSLOT[v.botId][v.BuildGoal] = global.BOTSLOT[v.botId][v.BuildGoal] + 1
								else
									global.BOTSLOT[v.botId][v.BuildGoal] = 1
								end
								v.buildindex_s = v.buildindex_s + 1
							else
								local ability = v.hero:GetAbilityByIndex(0)
								v.hero:CastAbilityNoTarget(ability, v.botId)
							end
							
							OnPlayerCallConstruct(event)
							v.buildindex = v.buildindex + 1
							
							v.BuildGoal = nil
						else
							v.hero:MoveToPosition(event.CastLocation)
						end
					end
				else
					--print("BOT AI: Not enough resources to build or upgrade - "..tostring(v.BuildGoal).." yet")
				end
				
				
			else --If there is no defined building queued for construction - Define it here
				--print("No prior Build queue, determining now")
				--Set up common variables
				local PotentialUpgrade = {}
				local PotentialBuild = {}
				local PotentialBuildGoldFactor = v.buildindex*50
				
				--Upgrade is first priority--
				local NearbyTargets = FindUnitsInRadius( v.team, v.hero:GetOrigin(), nil, 5000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false )
				if NearbyTargets then
					for _, value in pairs(NearbyTargets) do
						if (value ~= global.ENT_ANCIENT_GOOD and value ~= global.ENT_ANCIENT_BAD) then
							if global.BOT_UNIT_ID[value] == v.botId and global.UPGRADE[value:GetUnitName()].upgrade > 0 then
								--print("Found NearbyTarget with upgrade option")
								table.insert(PotentialUpgrade, value)
							end
						end
					end
					if PotentialUpgrade then
						local BestUpgrade
						local PossibleUpgrade = {}
						while #PotentialUpgrade > 0 do
							local PotentialNUpgradeName = PotentialUpgrade[#PotentialUpgrade]:GetUnitName()
							if ( global.BOTSLOT[v.botId].energy >= global.UPGRADE[PotentialNUpgradeName].energy ) and ( global.BOTSLOT[v.botId].tech >= global.UPGRADE[PotentialNUpgradeName].tech ) then
								--print(PotentialNUpgradeName) --TODO: If upgrade gold is too high relative to income
															 --TODO: If upgrade is not worth it (I.E no air units but upgrade is anti-air only)
								table.insert(PossibleUpgrade, PotentialUpgrade[#PotentialUpgrade])
							end
							table.remove(PotentialUpgrade)
						end
						
						if PossibleUpgrade then
							BestUpgrade = PossibleUpgrade[RandomInt(1, #PossibleUpgrade)]
						end
						if BestUpgrade then
							v.upgrading = true
							v.BuildGoal = BestUpgrade
							v.Goal_Gold		= global.UPGRADE[BestUpgrade:GetUnitName()].gold
							v.Goal_Energy	= global.UPGRADE[BestUpgrade:GetUnitName()].energy
							--TODO: Decision if there is multiple options for upgrade
							--TODO: v.UpgradeIndex = 0 by default
						end
					end
				end
					
				if not v.BuildGoal and v.upgrading == false then --If currently not building or queued to build/upgrade
					local i = 1
					local BuildIndex = 0
					local SpecialIndex = 0
					local s
					local PotentialSpecial = {}
					--First off is to see if we have enough energy to build a special tower
					while global.BUILD_DATA[v.heroname][i] do
						for _, value in pairs(_G.kvUnitData) do
							s = "tower_"..string.sub(global.BUILD_DATA[v.heroname][i], 12)
							if value.pszLabel == s then
								if (( v.gold + PotentialBuildGoldFactor ) >= value.nBuildingGoldCost)  and ( v.energy >= value.nBuildingEnergyCost ) and ( v.tech >= value.nBuildingRequiresTech ) then 
								--TODO: Add decision based on income factor (HALF DONE)
								--TODO: Add decision based on if a building already exist (NON STACKABLE BUILDING DONE)
								--TODO: Add decision based ratio of spawner v.s. special
									if (s == "tower_golden_shrine_of_justice" and global.NUMBEROFJUSTICESHRINE[v.team] >= 2) then
									elseif (s == "tower_heroicshrine" and global.NUMBEROFHEROSHRINE[v.team] >= 1) then
									elseif (s == "tower_city_of_decay" and global.NUMBEROFCITYOFDECAY[v.team] >= 1) then
									elseif (s == "tower_treasurebox") and (_G.PLAYER_INCOME_BOX[v.botId] >=2 or GameRules:GetGameTime() > global.TREASURE_BOX_TIME_LIMIT) then
									elseif _G.PLAYER_INCOME[v.botId]*global.BOT_BUILD_INCOME_FACTOR > value.nBuildingGoldCost then
										--print("TIER LOW")
										--print(_G.PLAYER_INCOME[v.botId])
										--print(value.nBuildingGoldCost)
									elseif s == "tower_watchtower" or s == "tower_arcane_tower" or s == "tower_turret_of_souls" or s == "tower_anti_air_tower" or s == "tower_icy_tower" then
									else
										local AllowSpecial = false
										if v.buildindex_s > 1 then
											if (1-math.log(v.buildindex_s))^0.5 > RandomFloat(0, 0.999) or (v.buildindex_s > 9 and (1-math.log(9))^0.5 > RandomFloat(0, 0.999))  then
												if global.BOTSLOT[v.botId][pszLabel] then
													local Chance = math.pow(global.BOTSLOT[v.botId][pszLabel], -1)
													if (Chance) < RandomFloat(0, 0.999) then
														AllowSpecial = true
													end
												end
											end
										else
											AllowSpecial = true
										end
										
										if ( AllowSpecial == true and value.nBuildingEnergyCost > 0 ) or value.nBuildingEnergyCost <= 0 then
											local NewStr = string.gsub( value.pszLabel,"tower_","item_build_")
											BuildIndex = BuildIndex + 1
											PotentialBuild[BuildIndex] = {}
											PotentialBuild[BuildIndex].name 		= NewStr
											PotentialBuild[BuildIndex].gold 		= value.nBuildingGoldCost
											PotentialBuild[BuildIndex].energy 		= value.nBuildingEnergyCost
											PotentialBuild[BuildIndex].buildtype 	= value.sAI_BUILD_TYPE
											if PotentialBuild[BuildIndex].energy > 0 then
												SpecialIndex = SpecialIndex + 1
												PotentialSpecial[SpecialIndex] = PotentialBuild[BuildIndex]
											end
										end
									end
								end
							end
						end
						i = i + 1
					end
					
					--print("Number of potential build: "..tostring(BuildIndex))
					
					if SpecialIndex > 0 then
						--print("SPECIAL BUILDING AVAL")
						local RandomIndex = RandomInt(1, SpecialIndex)
						v.BuildGoal 	= PotentialSpecial[RandomIndex].name
						v.Goal_Gold 	= PotentialSpecial[RandomIndex].gold
						v.Goal_Energy 	= PotentialSpecial[RandomIndex].energy
						v.BuildType 	= PotentialSpecial[RandomIndex].buildtype
					elseif BuildIndex > 0 then
						local RandomIndex = RandomInt(1, BuildIndex)
						v.BuildGoal 	= PotentialBuild[RandomIndex].name
						v.Goal_Gold 	= PotentialBuild[RandomIndex].gold
						v.Goal_Energy 	= PotentialBuild[RandomIndex].energy
						v.BuildType 	= PotentialBuild[RandomIndex].buildtype
					end
				end
			end
		end
	end
	
	return 3
end



