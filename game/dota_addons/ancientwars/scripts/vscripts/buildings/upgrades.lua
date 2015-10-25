local global = require( "vars" )

--[[
	Replaces the building to the upgraded unit name
]]--
function UpgradeBuilding( event )
	local caster = event.caster
	local new_unit = event.UpgradeName
	local position = caster:GetAbsOrigin()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local currentHealthPercentage = caster:GetHealthPercent() * 0.01
	
	-- Keep the gridnav blockers and orientation
	local blockers = caster.blockers
	local angle = caster:GetAngles()

    -- New building
	local building = BuildingHelper:PlaceBuilding(player, new_unit, position, false, 0)
	building:SetMana(0)
	building.blockers = blockers
	building:SetAngles(0, -angle.y, 0)

	-- If the building to ugprade is selected, change the selection to the new one
	if IsCurrentlySelected(caster) then
		AddUnitToSelection(building)
	end

	-- Remove the old building from the structures list
	if IsValidEntity(caster) then
		-- local buildingIndex = getIndex(player.structures, caster)
        -- table.remove(player.structures, buildingIndex)
		
		-- Remove old building entity
		caster:RemoveSelf()
    end

	local newRelativeHP = building:GetMaxHealth() * currentHealthPercentage
	if newRelativeHP == 0 then newRelativeHP = 1 end --just incase rounding goes wrong
	building:SetHealth(newRelativeHP)

	-- Add 1 to the buildings list for that name. The old name still remains
	-- if not player.buildings[new_unit] then
		-- player.buildings[new_unit] = 1
	-- else
		-- player.buildings[new_unit] = player.buildings[new_unit] + 1
	-- end

	-- Add the new building to the structures list
	-- table.insert(player.structures, building)
	
	-- %%%%%%%%%%%%%%%%%%%%%%% CUSTOM POST-BUILD SET UP %%%%%%%%%%%%%%%%%%%%%%% --
	-- Add to Income and Gives Energy
	
	-- Initialize building table
	local UnitKV = GameRules.UnitKV
	local TowerKV = UnitKV[new_unit]
	
	global.building[building] = {}
	
	global.building[building].self 			= building
	global.building[building].location 		= position
	global.building[building].player 		= player
	global.building[building].PlayerId 		= hero:GetPlayerID()
	global.building[building].UserTeamId 	= hero:GetTeam()
	global.building[building].hero 			= hero
	global.building[building].owner 		= hero:GetOwner()
	
	global.building[building].gold_cost 	= TowerKV.cost
	global.building[building].tech_cost 	= TowerKV.requiretechnology
	global.building[building].energy_cost 	= TowerKV.energycost
	
	global.building[building].give_energy 	= TowerKV.give_energy
	global.building[building].give_income 	= TowerKV.income
	
	global.building[building].spawns_unit 	= TowerKV.spawnunit
	global.building[building].spawned_unit 	= TowerKV.spawnedunit
	global.building[building].spawn_rate 	= TowerKV.spawnrate
	global.building[building].spawn_number	= TowerKV.spawnednumber
	
	global.building[building].autocasting 	= global.building[caster].autocasting or 1
	global.building[building].upgradeable 	= TowerKV.upgrade
	
	global.building[building].ability 		= TowerKV.abilitycasted
	
	global.building[building].tick			= 0
	global.building[building].constructing	= 0
	global.building[building].upgrading		= 0
	global.building[building].repair		= 0
	global.building[building].repairer		= {}
	global.building[building].maxhealth		= building:GetMaxHealth()
	global.building[building].IsAncient		= false
	
	_G.PLAYER_INCOME[global.building[building].PlayerId] = _G.PLAYER_INCOME[global.building[building].PlayerId] + global.building[building].give_income --Add to player income
	
	if global.building[building].give_energy > 0 then --If gives energy, do it now
			local NewIntel = global.building[building].hero:GetIntellect() + global.building[building].give_energy
			global.building[building].hero:SetBaseIntellect(NewIntel)
			PopupNumbers(global.building[building].self, "gold", Vector(100, 180, 255), 1.5, global.building[building].give_energy, POPUP_SYMBOL_PRE_PLUS, nil)
	end
	
	building:SetHullRadius(0)
	building:AddAbility("abilities_repair_state")
	building:FindAbilityByName("abilities_repair_state"):SetLevel(1)
	building:RemoveModifierByName("state_repair")
	building:RemoveModifierByName("modifier_invulnerable")
	
end

--[[
	Disable any queue-able ability that the building could have, because the caster will be removed when the channel ends
	A modifier from the ability can also be passed here to attach particle effects
]]--
function StartUpgrade( event )	
	local caster = event.caster
	local ability = event.ability
	local modifier_name = event.ModifierName
	local abilities = {}

	-- Check to not disable when the queue was full
	if #caster.queue < 5 then

		-- Iterate through abilities marking those to disable
		for i=0,15 do
			local abil = caster:GetAbilityByIndex(i)
			if abil then
				local ability_name = abil:GetName()

				-- Abilities to hide can be filtered to include the strings train_ and research_, and keep the rest available
				--if string.match(ability_name, "train_") or string.match(ability_name, "research_") then
					table.insert(abilities, abil)
				--end
			end
		end

		-- Keep the references to enable if the upgrade gets canceled
		caster.disabled_abilities = abilities

		for k,disable_ability in pairs(abilities) do
			disable_ability:SetHidden(true)		
		end

		-- Pass a modifier with particle(s) of choice to show that the building is upgrading. Remove it on CancelUpgrade
		if modifier_name then
			ability:ApplyDataDrivenModifier(caster, caster, modifier_name, {})
			caster.upgrade_modifier = modifier_name
		end

	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	
	-- FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

--[[
	Replaces the building to the upgraded unit name
]]--
function CancelUpgrade( event )
	
	local caster = event.caster
	local abilities = caster.disabled_abilities

	for k,ability in pairs(abilities) do
		ability:SetHidden(false)		
	end

	local upgrade_modifier = caster.upgrade_modifier
	if upgrade_modifier and caster:HasModifier(upgrade_modifier) then
		caster:RemoveModifierByName(upgrade_modifier)
	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	-- FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

-- Forces an ability to level 0
function SetLevel0( event )
	local ability = event.ability
	if ability:GetLevel() == 1 then
		ability:SetLevel(0)	
	end
end

function CheckResources( event )
	local caster 		= event.caster
	local ability 		= event.ability
	local hero			= caster:GetPlayerOwner():GetAssignedHero()
	local playerID 		= hero:GetPlayerID()
	local player 		= PlayerResource:GetPlayer(playerID)
	local HeroIntellect = hero:GetIntellect()
	
	local UnitKV 		= GameRules.UnitKV
	local unit_table 	= UnitKV[event.UpgradeName]
	
	local gold_cost 	= unit_table.cost
	local energy_cost 	= unit_table.energycost
	local tech_cost 	= unit_table.requiretechnology
	
	if global.building[caster].constructing == 1 then
		caster:InterruptChannel()
		caster:Interrupt()
		caster:Stop()
		return
	end
	
	if tech_cost > _G.PLAYER_TECH[playerID] then
		Notifications:ClearBottom(playerID)
		Notifications:Bottom(playerID, {text="Not enough tech", duration=2, style={color="red"}, continue=false})
		caster:InterruptChannel()
		caster:Interrupt()
		caster:Stop()
		return
	end
	
	if not PlayerHasEnoughGold( player, gold_cost ) then
		Notifications:ClearBottom(playerID)
		Notifications:Bottom(playerID, {text="Not enough gold", duration=2, style={color="red"}, continue=false})
		caster:InterruptChannel()
		caster:Interrupt()
		caster:Stop()
		return
	end
	
	if (energy_cost > HeroIntellect) then
		Notifications:ClearBottom(playerID)
		Notifications:Bottom(playerID, {text="Not enough energy", duration=2, style={color="red"}, continue=false})
		caster:InterruptChannel()
		caster:Interrupt()
		caster:Stop()
		return
	end
		
	local NewIntel = HeroIntellect - energy_cost
	_G.PLAYER_TECH[playerID] = _G.PLAYER_TECH[playerID] - tech_cost
	
	hero:SetBaseIntellect(NewIntel)
	hero:ModifyGold(-gold_cost, false, 0)
	hero:SetBaseStrength(_G.PLAYER_TECH[playerID])
	global.building[caster].upgrading = 1
	
end

function UpgradeInterrupt( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local HeroIntellect = hero:GetIntellect()
	
	local UnitKV = GameRules.UnitKV
	local unit_table = UnitKV[event.UpgradeName]
	
	local gold_cost = unit_table.cost
	local energy_cost = unit_table.energycost
	local tech_cost = unit_table.requiretechnology
	
	if global.building[caster].upgrading == 1 and global.building[caster].constructing == 0 then
		hero:ModifyGold(gold_cost, false, 0)
		
		_G.PLAYER_TECH[playerID] = _G.PLAYER_TECH[playerID] + tech_cost
		hero:SetBaseStrength(_G.PLAYER_TECH[playerID])
		
		local NewIntel = HeroIntellect + energy_cost
		hero:SetBaseIntellect(NewIntel)
		
		global.building[caster].upgrading = 0
	end
	
end