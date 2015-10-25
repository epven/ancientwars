--print("[abilities.lua] - Script Initiated")
local global = require( "vars" )

if CAbilities_Core == nil then
	--print("[abilities.lua] - Abilities Class Created")
	CAbilities_Core = class({})
end

function CAbilities_Core:OnThinkShrineRevival()

	if global.GAME_PAUSED == true then
		return 1
	end
	
	local CurrentGameTime = GameRules:GetGameTime()

	for k, v in pairs(global.SHRINEUNITSTOREVIVE) do
		if CurrentGameTime>= v  then		
			local unit = EntIndexToHScript(k)
			unit:RemoveNoDraw()
			unit:SetAttackCapability(1)
			unit:RemoveModifierByName("modifier_disarmed")
			unit:RemoveModifierByName("modifier_invulnerable")
			
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN, unit )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			
			global.SHRINEUNITSTOREVIVE[k] = nil
		end
	end
	
	return 1
end

function ability_paladin_bless_bonushealth(event)
	event.target:SetMaxHealth(event.target:GetMaxHealth()+100)
end

function ability_gryphon_chain(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId
	
	if event.target then
		local creature = CreateUnitByName( "npc_dummy" , caster:GetAbsOrigin() , false, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
		local ability = creature:FindAbilityByName("ability_npc_gryphon_lightning_p")
		
		creature:CastAbilityOnTarget(event.target, ability,  PlayerId)
		creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
		RemoveEntityTimed(creature, 3)
	end
end

function ability_sorc_chain(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId

	local creature = CreateUnitByName( "npc_dummy" , caster:GetAbsOrigin() , false, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
	local ability = creature:FindAbilityByName("ability_npc_sorceress_lightning_p")
	
	creature:CastAbilityOnTarget(event.target, ability,  PlayerId)
	creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
	RemoveEntityTimed(creature, 3)
end

function ability_wiz_chain(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId

	local creature = CreateUnitByName( "npc_dummy" , caster:GetAbsOrigin() , false, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
	local ability = creature:FindAbilityByName("ability_npc_wizard_lightning_p")
	
	creature:CastAbilityOnTarget(event.target, ability,  PlayerId)
	creature:AddNewModifier( creature, nil, "modifier_wisp_spirit_invulnerable", nil  )
	RemoveEntityTimed(creature, 3)
end

function ability_necro_swarm(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local ability 			= caster:FindAbilityByName("ability_npc_necro_swarm")
	
	caster:CastAbilityOnTarget(event.target, ability,  PlayerId)
end

function ability_necro_lifesteal(event)
	local TargetHP = event.target:GetHealth()
	local CasterHP = event.caster:GetHealth()
	
	if event.target:IsCreep() == true or event.target:IsCreature() == true then
		event.caster:SetHealth(event.caster:GetHealth() + (TargetHP/2))
		event.target:Kill(nil, event.caster)
	end
	
end

function ability_necro_pulse(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId

	local creature = CreateUnitByName( "npc_dummy" , event.caster:GetAbsOrigin() , false, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
	local ability = creature:FindAbilityByName("ability_npc_lich_pulse")
	
	creature:CastAbilityOnTarget(event.target, ability,  PlayerId)
	creature:AddNewModifier( v, nil, "modifier_wisp_spirit_invulnerable", nil  )
	RemoveEntityTimed(creature, 15)
end

function ability_vamp_summon(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId
	local owner 			= global.creep[caster].owner
	local loc 				= event.caster:GetOrigin()
	local creature
	
	local SummonName = "npc_creature_lesser_vampire"
	
	if caster:GetUnitName() == "npc_creature_vampire_lord" then
		SummonName = "npc_creature_vampire"
	end
	
	creature = CreateUnitByName( SummonName , loc , true, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
	
	global.creep[creature] 					= {}
	global.creep[creature].self				= creature
	global.creep[creature].name 			= creature:GetUnitName()
	global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
	global.creep[creature].range 			= creature:GetAttackRange()
	global.creep[creature].attacktype		= creature:GetAttackCapability()
	global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
	
	global.creep[creature].PlayerId 		= PlayerId
	global.creep[creature].UserTeamId 		= PlayerTeam
	global.creep[creature].EnemyTeamId 		= caster:GetOpposingTeamNumber()
	global.creep[creature].hero 			= global.creep[caster].hero
	global.creep[creature].owner 			= global.creep[caster].owner
	
	global.creep[creature].team_ancient			= global.creep[caster].team_ancient
	global.creep[creature].enemy_ancient		= global.creep[caster].enemy_ancient
	global.creep[creature].team_ancient_loc		= global.creep[caster].team_ancient_loc
	global.creep[creature].enemy_ancient_loc	= global.creep[caster].enemy_ancient_loc
	
	creature:MoveToPositionAggressive(global.creep[creature].enemy_ancient_loc)

end

function justice_revive(event)
	local owner 			= event.unit
	local PlayerId			= global.creep[owner].PlayerId
	local PlayerTeam 		= global.creep[owner].UserTeamId
	local loc 				= owner:GetOrigin()
	local UnitName 			= owner:GetUnitName()
	local probability 		= global.JUSTICESHRINEPERCENT
	
	if global.NUMBEROFJUSTICESHRINE[PlayerTeam] > 1 then
		probability = global.JUSTICESHRINEPERCENTMAX
	end
	
	local chance = RandomInt(0, 100)

	if chance < probability then
		local creature = CreateUnitByName( UnitName , loc , true, global.creep[owner].hero, global.creep[owner].owner, PlayerTeam )

		creature:AddNoDraw()
		creature:SetAttackCapability(0)
		creature:AddNewModifier(creature, nil, "modifier_disarmed", nil)
		creature:AddNewModifier(creature, nil, "modifier_invulnerable", nil)
		
		global.creep[creature] 					= {}
		global.creep[creature].self				= creature
		global.creep[creature].name 			= creature:GetUnitName()
		global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
		global.creep[creature].range 			= creature:GetAttackRange()
		global.creep[creature].attacktype		= creature:GetAttackCapability()
		global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]

		global.creep[creature].PlayerId 		= PlayerId
		global.creep[creature].UserTeamId 		= PlayerTeam
		global.creep[creature].EnemyTeamId 		= owner:GetOpposingTeamNumber()
		global.creep[creature].hero 			= global.creep[owner].hero
		global.creep[creature].owner 			= global.creep[owner].owner

		global.creep[creature].team_ancient			= global.creep[owner].team_ancient
		global.creep[creature].enemy_ancient		= global.creep[owner].enemy_ancient
		global.creep[creature].team_ancient_loc		= global.creep[owner].team_ancient_loc
		global.creep[creature].enemy_ancient_loc	= global.creep[owner].enemy_ancient_loc
		
		local ReviveGameTime = GameRules:GetGameTime() + 2
		global.SHRINEUNITSTOREVIVE[creature:entindex()] = ReviveGameTime
		
		global.creep[owner].reviving = ReviveGameTime
		
	end
end

function ability_hydra_split(event)
	local caster 			= event.caster
	local PlayerId			= global.creep[caster].PlayerId
	local PlayerTeam 		= global.creep[caster].UserTeamId
	local owner 			= global.creep[caster].owner
	local loc 				= caster:GetOrigin()
	local UnitName 			= caster:GetUnitName()
	local creature
	local SummonName
	
	if UnitName == "npc_creature_ancient_hydra" then
		SummonName = "npc_creature_hydra"
	elseif UnitName == "npc_creature_hydra" then
		SummonName = "npc_creature_lesser_hydra"
	end
	
	for int = 1, 2 do
		creature = CreateUnitByName( SummonName , loc , true, global.creep[caster].hero, global.creep[caster].owner, PlayerTeam )
		global.creep[creature] 					= {}
		global.creep[creature].self				= creature
		global.creep[creature].name 			= creature:GetUnitName()
		global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
		global.creep[creature].range 			= creature:GetAttackRange()
		global.creep[creature].attacktype		= creature:GetAttackCapability()
		global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
		
		global.creep[creature].PlayerId 		= PlayerId
		global.creep[creature].UserTeamId 		= PlayerTeam
		global.creep[creature].EnemyTeamId 		= caster:GetOpposingTeamNumber()
		global.creep[creature].hero 			= global.creep[caster].hero
		global.creep[creature].owner 			= global.creep[caster].owner
		
		global.creep[creature].team_ancient			= global.creep[caster].team_ancient
		global.creep[creature].enemy_ancient		= global.creep[caster].enemy_ancient
		global.creep[creature].team_ancient_loc		= global.creep[caster].team_ancient_loc
		global.creep[creature].enemy_ancient_loc	= global.creep[caster].enemy_ancient_loc
		
		creature:MoveToPositionAggressive(global.creep[creature].enemy_ancient_loc)
	end

end
