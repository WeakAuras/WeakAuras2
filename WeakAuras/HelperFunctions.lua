local UnitAura = UnitAura
-- Unit Aura functions that return info about the first Aura matching the spellName or spellID given on the unit.
local WA_GetUnitAura = function(unit, spell, filter)
  for i = 1, 40 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then return end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

local WA_GetUnitBuff = function(unit, spell, filter)
  return WA_GetUnitAura(unit, spell, filter)
end

local WA_GetUnitDebuff = function(unit, spell, filter)
  filter = filter and filter.."|HARMFUL" or "HARMFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

-- Function to assist iterating group members whether in a party or raid.
local WA_IterateGroupMembers = function(reversed, forceParty)
  local unit  = (not forceParty and IsInRaid()) and 'raid' or 'party'
  local numGroupMembers = (forceParty and GetNumSubgroupMembers()  or GetNumGroupMembers()) - (unit == "party" and 1 or 0)
  local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
  return function()
    local ret
    if i == 0 and unit == 'party' then
      ret = 'player'
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

-- Wrapping a unit's name in its class colour is very common in custom Auras
local WA_ClassColorName = function(unit)
  local _, class = UnitClass(unit)
  if not class then return end
  return RAID_CLASS_COLORS[class]:WrapTextInColorCode(UnitName(unit))
end

local function makeIterator(api, unit, filter, offset)
  local i = 0
  if offset then
    return function()
      i = i + 1
      return select(offset, api(unit, i, filter))
    end
  else
    return function()
      i = i + 1
      return api(unit, i, filter)
    end
  end
end

local WA_IterateAuras = function(unit, filter, offset)
  return makeIterator(UnitAura, unit, filter, offset)
end

local WA_IterateBuffs = function(unit, filter, offset)
  return makeIterator(UnitBuff, unit, filter, offset)
end

local WA_IterateAuras = function(unit, filter, offset)
  return makeIterator(UnitDebuff, unit, filter, offset)
end

WeakAuras.helperFunctions = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
  WA_IterateAuras = WA_IterateAuras,
  WA_IterateBuffs = WA_IterateBuffs,
  WA_IterateDebuffs = WA_IterateDebuffs,
}
