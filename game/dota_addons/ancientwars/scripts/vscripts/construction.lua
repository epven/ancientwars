--print("[construction.lua] - Script Initiated")
local global = require( "vars" )

HEROIC_SHRINE_CHANCE = 24

if CConstruct == nil then
	--print("[construction.lua] - Construction class created")
	CConstruct = class({})
end

function changetier(keys)
	--Remove all 'Items' from Unit to allow us to refresh 'buildings'
	local UnitName = keys.caster:GetUnitName()
	local towersLookupList = LoadKeyValues( "scripts/builderdata.txt" )
	local count = 0
	
	local ability = keys.caster:GetCurrentActiveAbility()
	local abilitname = ""
	
	if ability then
		abilitname = ability:GetAbilityName()
	end
	
	if abilitname == "abilities_worker_tier2" then count = 6 end
	
	for k, v in pairs(towersLookupList) do
		if k == UnitName then
			local countinvo = 0
			for i = count, count+5 do
				local item = keys.caster:GetItemInSlot(countinvo)
				if item then
					keys.caster:RemoveItem(item)
				end
				if i == 0 then NewItem = CreateItem(v.a, nil, nil) end
				if i == 1 then NewItem = CreateItem(v.b, nil, nil) end
				if i == 2 then NewItem = CreateItem(v.c, nil, nil) end
				if i == 3 then NewItem = CreateItem(v.d, nil, nil) end
				if i == 4 then NewItem = CreateItem(v.e, nil, nil) end
				if i == 5 then NewItem = CreateItem(v.f, nil, nil) end
				if i == 6 then NewItem = CreateItem(v.g, nil, nil) end
				if i == 7 then NewItem = CreateItem(v.h, nil, nil) end
				if i == 8 then NewItem = CreateItem(v.i, nil, nil) end
				if i == 9 then NewItem = CreateItem(v.j, nil, nil) end
				if i == 10 then NewItem = CreateItem(v.k, nil, nil) end
				if i == 11 then NewItem = CreateItem(v.l, nil, nil) end
				if NewItem then
					keys.caster:AddItem(NewItem)
				end
				countinvo = countinvo + 1
			end
		end
	end
	
end

function CheckInventory( keys )
	local caster 		= keys.caster
	local hero 			= caster
	local playerID 		= hero:GetPlayerID()
	local player		= PlayerResource:GetPlayer(playerID)
	
	for i = 0, 5 do
		local item = hero:GetItemInSlot(i)
		if item then
			item:RemoveSelf()
		end
		if global.player[playerID].item[i] then
			local NewItem = CreateItem(global.player[playerID].item[i], nil, nil)
			if NewItem then
				keys.caster:AddItem(NewItem)
			end
		end
	end
end

--[BUILDING UNIT SPAWNING]
function CConstruct:OnThinkCheckBuildingStatus()

	if global.GAME_PAUSED == true then
		return global.GLOBAL_BUILD_RATE
	end
	
	local TargetAncient
	local TeamAncient
	local TargetAncientLoc
	local TeamLoc

	for k in pairs(global.building) do
		if global.building[k].self:IsNull() == false then
			if global.building[k].self:IsAlive() == true then --Only proceed if unit is alive
				-- If unit is alive and can spawn unit
				-- Is tower auto-spawning??
				
				local Id = global.building[k].PlayerId
				local IsFrozen = global.building[k].self:HasModifier("frost_attack_frozen")
				
				if global.building[k].autocasting == 0 or global.building[k].self:IsChanneling() then --If this building spawns unit and auto-cast is off, do not set progress (mana) bar
					global.building[k].self:SetMana(0)
					global.building[k].tick = 0
				elseif global.building[k].constructing == 1 or IsFrozen == true then
					-- Building is under constructing (Due to upgrade etc., do not set progress)
				else
					global.building[k].tick = global.building[k].tick + (global.GLOBAL_BUILD_RATE/1)
					scale = global.building[k].tick/global.building[k].spawn_rate*100
					global.building[k].self:SetMana(scale)
				end
				
				-- Repair status
				
				if global.building[k].repair > 0 then
					if global.building[k].self:GetHealthPercent() < 100 and global.building[k].constructing ~= 1 and IsFrozen == false then
						local Factor = 1
						if global.building[k].IsAncient == true then
							Factor = 0.5
						end
						local newHealth = ( global.GLOBAL_BUILD_RATE * (global.building[k].repair * global.building[k].maxhealth / 100) * Factor ) + global.building[k].self:GetHealth()
						global.building[k].self:SetHealth(newHealth)
					elseif global.building[k].self:GetHealthPercent() >= 100 or IsFrozen == true then
						global.building[k].repair = 0
						global.building[k].self:RemoveModifierByName("modifier_repair")
						for keys, v in pairs(global.building[k].repairer) do
							--print("Repaired Finished: Removing "..v:GetUnitName().." from repair group")
							v:Stop()
							v:Hold()
							global.building[k].repairer[keys] = nil
						end
					end
				end
				
				-- Auto Spawning

				if global.building[k].autocasting == 1 then --Auto-casting/spawning enabled - Allow to spawn unit
					if global.building[k].tick >= global.building[k].spawn_rate then --Cooldown reached, react now (spawn unit etc.)
						if global.building[k].spawns_unit > 0 then
							global.building[k].tick = 0
							local creature
							local count = global.building[k].spawn_number
							
							if global.building[k].self:HasModifier("shrine_aura_bonus") == true then
								local chance = math.random(0, 99)
								if chance < HEROIC_SHRINE_CHANCE then
									count = count*2
								end
							end
							
							for int = 1, count do
								if global.building[k].UserTeamId == DOTA_TEAM_GOODGUYS then
									creature = CreateUnitByName( global.building[k].spawned_unit, global.building[k].location, true, global.building[k].hero, global.building[k].player, DOTA_TEAM_GOODGUYS ) 
									creature:MoveToPositionAggressive(global.LOC_ANCIENT_BAD)
								else
									creature = CreateUnitByName( global.building[k].spawned_unit, global.building[k].location, true, global.building[k].hero, global.building[k].player, DOTA_TEAM_BADGUYS )
									creature:MoveToPositionAggressive(global.LOC_ANCIENT_GOOD)
								end
								
								local attacktype
								
								if global.building[k].UserTeamId == DOTA_TEAM_GOODGUYS then
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
								
								global.creep[creature] 					= {}
								global.creep[creature].self				= creature
								global.creep[creature].name 			= creature:GetUnitName()
								global.creep[creature].acqrange 		= creature:GetAcquisitionRange()
								global.creep[creature].range 			= creature:GetAttackRange()
								global.creep[creature].attacktype		= creature:GetAttackCapability()
								global.creep[creature].AI 				= _G.AI_TYPE[global.creep[creature].name]
								
								global.creep[creature].PlayerId 		= global.building[k].PlayerId
								global.creep[creature].UserTeamId 		= global.building[k].UserTeamId
								global.creep[creature].EnemyTeamId 		= creature:GetOpposingTeamNumber()
								global.creep[creature].hero 			= global.building[k].hero
								global.creep[creature].owner 			= global.building[k].owner
								
								global.creep[creature].team_ancient		= TeamAncient
								global.creep[creature].enemy_ancient	= TargetAncient
								
								global.creep[creature].team_ancient_loc		= TeamLoc
								global.creep[creature].enemy_ancient_loc	= TargetAncientLoc
								
								if global.creep[creature].name == "npc_creature_blood_fiend" then
									local NewATK = global.COMBAT_LIST_ATK[RandomInt(0,5)]
									local NewDEF = global.COMBAT_LIST_DEF[RandomInt(0,5)]
									
									creature:GetAbilityByIndex(1):SetLevel(0)
									creature:GetAbilityByIndex(2):SetLevel(0)
									
									creature:RemoveAbility("combat_atk_chaos")
									creature:RemoveAbility("combat_def_light")
									creature:RemoveModifierByName("combat_atk_chaos")
									creature:RemoveModifierByName("combat_def_light")
									
									creature:AddAbility(NewATK)
									creature:AddAbility(NewDEF)
									
									creature:FindAbilityByName(NewATK):SetLevel(1)
									creature:FindAbilityByName(NewDEF):SetLevel(1)
								end
							end
						end
					end
				end			
			else--Building is not alive - Destroy object
				local unitname = global.building[k].self:GetUnitName()
				if unitname ~= "fort_goodguys" and unitname ~= "fort_badguys" then
					_G.PLAYER_INCOME[global.building[k].PlayerId] = _G.PLAYER_INCOME[global.building[k].PlayerId] - global.building[k].give_income
					_G.PLAYER_TECH[global.building[k].PlayerId] = _G.PLAYER_TECH[global.building[k].PlayerId] + global.building[k].tech_cost
				end
				
				if unitname == "tower_treasurebox" then
					_G.PLAYER_INCOME_BOX[global.building[k].PlayerId] = _G.PLAYER_INCOME_BOX[global.building[k].PlayerId] - 1
				elseif unitname == "tower_golden_shrine_of_justice" then
					global.NUMBEROFJUSTICESHRINE[global.building[k].UserTeamId] = global.NUMBEROFJUSTICESHRINE[global.building[k].UserTeamId] - 1
				elseif unitname == "tower_heroicshrine" then
					global.NUMBEROFHEROSHRINE[global.building[k].UserTeamId] = global.NUMBEROFHEROSHRINE[global.building[k].UserTeamId] - 1
					global.building[k].self:RemoveModifierByName("shrine_aura")
				elseif unitname == "tower_city_of_decay" then
					global.NUMBEROFCITYOFDECAY[global.building[k].UserTeamId] = global.NUMBEROFCITYOFDECAY[global.building[k].UserTeamId] - 1
				end
				global.building[k] = nil
			end
		else
			-- This should technically never run
			global.building[k] = nil
		end
	end
	
	return global.GLOBAL_BUILD_RATE
end

function ToggleAutoCast(event) 
	local callingTower = event.caster
	
	if global.building[callingTower].constructing == 1 then
		return
	end
	
	if global.building[callingTower].autocasting == 1 then
		global.building[callingTower].autocasting = 0
		--print("[AUTOCAST]: OFF")
	else
		global.building[callingTower].autocasting = 1
		--print("[AUTOCAST]: ON")
	end
end

function RepairStart(event) 
	local unit = event.caster
	local target = event.target
	
	if global.building[target] == nil then
		print("Something is wrong with repairing building in RepairStart() - global.building[target] is nil")
		return
	end

	if global.building[target].constructing == 1 then
		Notifications:Bottom(unit:GetPlayerOwnerID(), {text="Cannot repair when under construction", duration=2, style={color="red"}, continue=false})
		unit:Stop()
		unit:Hold()
		return
	end
	
	if global.building[target].self:HasModifier("frost_attack_frozen") == true then
		Notifications:Bottom(unit:GetPlayerOwnerID(), {text="Cannot repair when frozen", duration=2, style={color="red"}, continue=false})
		unit:Stop()
		unit:Hold()
		return
	end
	
	if not global.building[target].repair then
		global.building[target].repair = 0
	end
	
	if global.building[target].repair < 0 then
		global.building[target].repair = 0
	end
	
	if target:GetHealthPercent() < 100 then
		local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(target, target, "modifier_repair", {})
    	item = nil
	
		global.building[target].repair = global.building[target].repair + 1
		table.insert(global.building[target].repairer, unit)
	else
		Notifications:Bottom(unit:GetPlayerOwnerID(), {text="Cannot repair at full health", duration=2, style={color="red"}, continue=false})
		unit:Stop()
		unit:Hold()
	end
	
end

function RepairInterrupted(event) 
	local unit = event.caster
	local target = event.target
	
	if target == nil then
		return
	end
	
	if not global.building[target] then
		return
	end
	
	if target:GetHealthPercent() < 100 then
		global.building[target].repair = global.building[target].repair - 1
		for keys, v in pairs(global.building[target].repairer) do
			if v == unit then
				--print("Repair Interrupted: Removing "..v:GetUnitName().." from repair group")
				global.building[target].repairer[keys] = nil
				break
			end
		end
	end
	
	if global.building[target].repair <= 0 then
		target:RemoveModifierByName("modifier_repair")
	end
	
end