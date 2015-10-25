function DebugPrint(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  if spew == 1 then
    print(...)
  end
end

function DebugPrintTable(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  if spew == 1 then
    PrintTable(...)
  end
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end

function StringStartsWith( fullstring, substring )
    local strlen = string.len(substring)
    local first_characters = string.sub(fullstring, 1 , strlen)
    return (first_characters == substring)
end

function VectorString(v)
    return '[' .. math.floor(v.x) .. ', ' .. math.floor(v.y) .. ', ' .. math.floor(v.z) .. ']'
end

function tobool(s)
    if s=="true" or s=="1" or s==1 then
        return true
    else --nil "false" "0"
        return false
    end
end

function RemoveEntityTimed(ent, sec)
	_G.DUMMY[ent] = GameRules:GetGameTime() + sec
end

function ReturnCombatMod(IsAttacker, Unit)
	if IsAttacker == true then
		if Unit:FindAbilityByName("combat_atk_normal") then
			return "CUSTOM_COMBAT_TYPE_NORMAL"
		elseif Unit:FindAbilityByName("combat_atk_pierce") then
			return "CUSTOM_COMBAT_TYPE_PIERCE"
		elseif Unit:FindAbilityByName("combat_atk_magic") then
			return "CUSTOM_COMBAT_TYPE_MAGIC"
		elseif Unit:FindAbilityByName("combat_atk_chaos") then
			return "CUSTOM_COMBAT_TYPE_CHAOS"
		elseif Unit:FindAbilityByName("combat_atk_siege") then
			return "CUSTOM_COMBAT_TYPE_SIEGE"
		elseif Unit:FindAbilityByName("combat_atk_hero") then
			return "CUSTOM_COMBAT_TYPE_HERO"
		end
	elseif IsAttacker == false then
		if Unit:FindAbilityByName("combat_def_none") then
			return "CUSTOM_COMBAT_TYPE_NONE"
		elseif Unit:FindAbilityByName("combat_def_light") then
			return "CUSTOM_COMBAT_TYPE_LIGHT"
		elseif Unit:FindAbilityByName("combat_def_medium") then
			return "CUSTOM_COMBAT_TYPE_MEDIUM"
		elseif Unit:FindAbilityByName("combat_def_heavy") then
			return "CUSTOM_COMBAT_TYPE_HEAVY"
		elseif Unit:FindAbilityByName("combat_def_fortified") then
			return "CUSTOM_COMBAT_TYPE_FORTIFIED"
		elseif Unit:FindAbilityByName("combat_def_divine") then
			return "CUSTOM_COMBAT_TYPE_DIVINE"
		end
	end
	return
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'