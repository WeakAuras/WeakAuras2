-- This file is only for base functions that work differently or are deprecated in some versions of wow

if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local WeakAuras = WeakAuras

if GetSpellInfo then
  WeakAuras.GetSpellInfo = GetSpellInfo
  WeakAuras.GetSpellName = GetSpellInfo
  WeakAuras.GetSpellIcon = GetSpellTexture
else
  WeakAuras.GetSpellInfo = function(spellID)
    if not spellID then
      return nil
    end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
      return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
  end
  WeakAuras.GetSpellName = C_Spell.GetSpellName
  WeakAuras.GetSpellIcon = C_Spell.GetSpellTexture
end
