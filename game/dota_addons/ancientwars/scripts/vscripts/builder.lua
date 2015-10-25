------------------------------------------
--             Build Scripts
------------------------------------------
local global = require( "vars" )

-- A build ability is used (not yet confirmed)
function Build( event )
	local caster = event.caster
	local ability = event.ability
	local ability_name = ability:GetAbilityName()
	local ItemsKV = GameRules.ItemKV
	local UnitKV = GameRules.UnitKV

    -- Hold needs an Interrupt
	if caster.bHold then
		caster.bHold = false
		caster:Interrupt()
	end
	
	-- Handle the name for item-ability build
	local building_name = ItemsKV[ability_name].unitname
	local unit_table 	= UnitKV[building_name]
	
	local build_time 	= unit_table.buildtime
	local gold_cost 	= unit_table.cost
	local lumber_cost 	= unit_table.energycost
	local energy_cost 	= unit_table.energycost
	local tech_cost 	= unit_table.requiretechnology

	local hero 			= caster
	local playerID 		= hero:GetPlayerID()
	local player		= PlayerResource:GetPlayer(playerID)
	local HeroIntellect = hero:GetIntellect()
	local gold 			= hero:GetGold()
	
	-- Checks if there is enough custom resources to start the building, else stop.

	if tech_cost > _G.PLAYER_TECH[playerID] then
		Notifications:ClearBottom(caster:GetPlayerOwnerID())
		Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough tech", duration=2, style={color="red"}, continue=false})
		return
	end
	
	if gold < gold_cost then
		Notifications:ClearBottom(caster:GetPlayerOwnerID())
		Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough gold", duration=2, style={color="red"}, continue=false})
		return
	end
	
	if (energy_cost > HeroIntellect) then
		Notifications:ClearBottom(caster:GetPlayerOwnerID())
		Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough energy", duration=2, style={color="red"}, continue=false})
		return
	end

	-- Makes a building dummy and starts panorama ghosting
	BuildingHelper:AddBuilding(event)

	-- Additional checks to confirm a valid building position can be performed here
	event:OnPreConstruction(function(vPos)

		if tech_cost > _G.PLAYER_TECH[playerID] then
			Notifications:ClearBottom(caster:GetPlayerOwnerID())
			Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough tech", duration=2, style={color="red"}, continue=false})
			return false
		end
		
		if gold < gold_cost then
			Notifications:ClearBottom(caster:GetPlayerOwnerID())
			Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough gold", duration=2, style={color="red"}, continue=false})
			return false
		end
				
		if (energy_cost > HeroIntellect) then
			Notifications:ClearBottom(caster:GetPlayerOwnerID())
			Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Not enough energy", duration=2, style={color="red"}, continue=false})
			return false
		end
		
		return true
    end)

	-- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
	
		local NewIntel = HeroIntellect - energy_cost
		_G.PLAYER_TECH[playerID] = _G.PLAYER_TECH[playerID] - tech_cost
		
		hero:SetBaseIntellect(NewIntel)
    	hero:ModifyGold(-gold_cost, false, 0)
		hero:SetBaseStrength(_G.PLAYER_TECH[playerID])

    	-- Play a sound
    	EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", player)
		caster:RemoveAbility("move_to_point_200")

	end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
	event:OnConstructionFailed(function()
		Notifications:ClearBottom(caster:GetPlayerOwnerID())
		Notifications:Bottom(caster:GetPlayerOwnerID(), {text="Invalid build position", duration=2, style={color="red"}, continue=false})
	end)

	-- Cancelled due to ClearQueue
	event:OnConstructionCancelled(function(work)
		local name = work.name
		-- print("[BH] Cancelled construction of " .. name)

		-- Refund resources for this cancelled work
		if work.refund then
			local RefundHeroIntellect = hero:GetIntellect()
			local RefundNewIntel = RefundHeroIntellect + energy_cost
			
			_G.PLAYER_TECH[playerID] = _G.PLAYER_TECH[playerID] + tech_cost
			hero:ModifyGold(gold_cost, false, 0)
			hero:SetBaseIntellect(RefundNewIntel)
			hero:SetBaseStrength(_G.PLAYER_TECH[playerID])
    	end
	end)

	-- A building unit was created
	event:OnConstructionStarted(function(unit)
		DebugPrint("[BH] Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())

	    unit.GoldCost = gold_cost
	    unit.LumberCost = lumber_cost
	    unit.BuildTime = build_time
		unit:SetControllableByPlayer( playerID, false )
    	unit:RemoveModifierByName("modifier_invulnerable")
		unit:SetHullRadius(0)

    	-- Modifier
    	ApplyModifier(unit, "modifier_construction")
		ApplyModifier(unit, "modifier_disarmed")
		
		caster:RemoveAbility("move_to_point_200")
		
	end)

	-- A building finished construction
	event:OnConstructionCompleted(function(unit)
		unit:RemoveModifierByName("modifier_construction")
		unit:RemoveModifierByName("modifier_disarmed")
		unit:SetControllableByPlayer( playerID, true )

		local building_name = unit:GetUnitName()
		local builders = {}
		
		if unit.builder then
			table.insert(builders, unit.builder)
		elseif unit.units_repairing then
			builders = unit.units_repairing
		end

		-- %%%%%%%%%%%%%%%%%%%%%%% CUSTOM POST-BUILD SET UP %%%%%%%%%%%%%%%%%%%%%%% --
		
		_G.PLAYER_INCOME[global.building[unit].PlayerId] = _G.PLAYER_INCOME[global.building[unit].PlayerId] + global.building[unit].give_income
		
		if global.building[unit].give_energy > 0 then
			local NewIntel = global.building[unit].hero:GetIntellect() + global.building[unit].give_energy
			global.building[unit].hero:SetBaseIntellect(NewIntel)
			PopupNumbers(global.building[unit].self, "gold", Vector(100, 180, 255), 1.5, global.building[unit].give_energy, POPUP_SYMBOL_PRE_PLUS, nil)
		end
		
		if building_name == "tower_treasurebox" then
			_G.PLAYER_INCOME_BOX[global.building[unit].PlayerId] = _G.PLAYER_INCOME_BOX[global.building[unit].PlayerId] + 1
		elseif building_name == "tower_arcane_tower" then
			local xAbility = global.building[unit].self:GetAbilityByIndex(0)
			xAbility:ToggleAbility()
		elseif building_name == "tower_golden_shrine_of_justice" then
			global.NUMBEROFJUSTICESHRINE[global.building[unit].UserTeamId] = global.NUMBEROFJUSTICESHRINE[global.building[unit].UserTeamId] + 1
		elseif building_name == "tower_heroicshrine" then
			global.NUMBEROFHEROSHRINE[global.building[unit].UserTeamId] = global.NUMBEROFHEROSHRINE[global.building[unit].UserTeamId] + 1
			local abilName = "ability_npc_heroicshrine_aura"
			unit:AddAbility(abilName)
			local abil = unit:FindAbilityByName(abilName)
			abil:SetLevel(1)
		elseif building_name == "tower_city_of_decay" then
			global.NUMBEROFCITYOFDECAY[global.building[unit].UserTeamId] = global.NUMBEROFCITYOFDECAY[global.building[unit].UserTeamId] + 1
			local abilName = "ability_tower_decay"
			unit:AddAbility(abilName)
			local abil = unit:FindAbilityByName(abilName)
			abil:SetLevel(1)
		elseif building_name == "tower_coral_statue" then
			local abilName = "ability_tower_naga_statue"
			unit:AddAbility(abilName)
			local abil = unit:FindAbilityByName(abilName)
			abil:SetLevel(1)
		elseif building_name == "tower_turret_of_souls" then
			local abilName = "ability_tower_weaken_soul"
			unit:AddAbility(abilName)
			local abil = unit:FindAbilityByName(abilName)
			abil:SetLevel(1)
		end
		
		unit:AddAbility("abilities_repair_state")
		unit:FindAbilityByName("abilities_repair_state"):SetLevel(1)
		unit:RemoveModifierByName("state_repair")
		
		global.building[unit].constructing = 0
		global.building[unit].repair = 0
		
		-- 
		
		if global.GAME_BUILD_COUNT < 5 and hero.bFirstBuild == true then
		
			global.GAME_BUILD_COUNT = global.GAME_BUILD_COUNT + 1
			local BonusGold = (5-global.GAME_BUILD_COUNT)*5
			local Spf
			
			if global.GAME_BUILD_COUNT == 1 then
				Spf = "st"
			elseif global.GAME_BUILD_COUNT == 2 then
				Spf = "nd"
			elseif global.GAME_BUILD_COUNT == 3 then
				Spf = "rd"
			else
				Spf = "th"
			end
			
			hero:ModifyGold(BonusGold, false, 0)
			Notifications:Bottom(caster:GetPlayerOwnerID(), {text="You received a bonus of "..tostring(BonusGold).." gold for being the "..tostring(global.GAME_BUILD_COUNT)..Spf.." player to finish constructing a structure!", duration=5, style={color="white"}, continue=false})
		end
		
		hero.bFirstBuild = false
		
		hero:SetBaseAgility(0)
		hero:ModifyAgility(_G.PLAYER_INCOME[global.building[unit].PlayerId])
		
	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't fire multiple times unnecessarily.
	event:OnBelowHalfHealth(function(unit)
		-- DebugPrint("[BH] " .. unit:GetUnitName() .. " is below half health.")	
		-- local item = CreateItem("item_apply_modifiers", nil, nil)
    	-- item:ApplyDataDrivenModifier(unit, unit, "modifier_onfire", {})
    	-- item = nil
	end)

	event:OnAboveHalfHealth(function(unit)
		-- DebugPrint("[BH] " ..unit:GetUnitName().. " is above half health.")
		-- unit:RemoveModifierByName("modifier_onfire")
	end)
end

-- Called when the move_to_point ability starts
function StartBuilding( keys )
	BuildingHelper:StartBuilding(keys)
end

-- Called when the Cancel ability-item is used
function CancelBuilding( keys )
	BuildingHelper:CancelBuilding(keys)
end
