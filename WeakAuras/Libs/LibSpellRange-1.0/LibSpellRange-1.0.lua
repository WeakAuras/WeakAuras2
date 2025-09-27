--- = Background =
-- Blizzard's IsSpellInRange API has always been very limited - you either must have the name of the spell, or its spell book ID. Checking directly by spellID is simply not possible.
-- Now, in Mists of Pandaria, Blizzard changed the way that many talents and specialization spells work - instead of giving you a new spell when leaned, they replace existing spells. These replacement spells do not work with Blizzard's IsSpellInRange function whatsoever; this limitation is what prompted the creation of this lib.
-- = Usage = 
-- **LibSpellRange-1.0** exposes an enhanced version of IsSpellInRange that:
-- * Allows ranged checking based on both spell name and spellID.
-- * Works correctly with replacement spells that will not work using Blizzard's IsSpellInRange method alone.
--
-- @class file
-- @name LibSpellRange-1.0.lua

local major = "SpellRange-1.0"
local minor = 24

assert(LibStub, format("%s requires LibStub.", major))

local Lib = LibStub:NewLibrary(major, minor)
if not Lib then return end

local tonumber = _G.tonumber
local strlower = _G.strlower
local wipe = _G.wipe
local type = _G.type
local select = _G.select

-- Handles updating spellsByName and spellsByID
if not Lib.updaterFrame then
	Lib.updaterFrame = CreateFrame("Frame")
end
Lib.updaterFrame:UnregisterAllEvents()

if C_Spell.IsSpellInRange then
	-- In TWW, IsSpellInRange supports both spell names and IDs
	-- and also automatically handles override spells (i.e. when given a base spell
	-- that has an active override, the range of the override is what's checked - 
	-- no need to pass the input through C_Spell.GetOverrideSpell).
	-- And it once again works with pet spells too!

	-- It remains to be seen if C_Spell.IsSpellInRange will continue to be so well behaved
	-- if/when it is brought to classic and era. May need to change the feature detection used.

	-- Some good spells to test with:
	-- 	Templar's Verdict (base) & Final Verdict (ret pally talent), talent has longer range than base
	--	Growl (hunter pet) - pet spell with range.

	local IsSpellInRange = C_Spell.IsSpellInRange
	local SpellHasRange = C_Spell.SpellHasRange

	function Lib.IsSpellInRange(spellInput, unit)
		local result = IsSpellInRange(spellInput, unit)
		return result and 1 or result == false and 0 or result
	end

	function Lib.SpellHasRange(spellInput)
		local result = SpellHasRange(spellInput)
		return result and 1 or result == false and 0 or result
	end

	return
end


local GetSpellBookItemInfo = _G.GetSpellBookItemInfo or _G.C_SpellBook.GetSpellBookItemType
local GetSpellBookItemName = _G.GetSpellBookItemName or _G.C_SpellBook.GetSpellBookItemName
local GetSpellLink = _G.GetSpellLink or _G.C_Spell.GetSpellLink
local GetSpellName = _G.GetSpellInfo or _G.C_Spell.GetSpellName

local IsSpellInRange = _G.IsSpellInRange
local IsSpellBookItemInRange = _G.IsSpellInRange or function(index, spellBank, unit)
  local result = C_SpellBook.IsSpellBookItemInRange(index, spellBank, unit)
  if result == true then
    return 1
  elseif result == false then
    return 0
  end
  return nil
end

local SpellHasRange = _G.SpellHasRange
local SpellBookHasRange = _G.SpellHasRange or _G.C_SpellBook.IsSpellBookItemInRange

local UnitExists = _G.UnitExists
local GetPetActionInfo = _G.GetPetActionInfo
local UnitIsUnit = _G.UnitIsUnit

local playerBook = _G.GetSpellBookItemName and "spell" or _G.Enum.SpellBookSpellBank.Player
local petBook = _G.GetSpellBookItemName and "pet" or _G.Enum.SpellBookSpellBank.Pet

-- isNumber is basically a tonumber cache for maximum efficiency
Lib.isNumber = Lib.isNumber or setmetatable({}, {
	__mode = "kv",
	__index = function(t, i)
		local o = tonumber(i) or false
		t[i] = o
		return o
end})
local isNumber = Lib.isNumber

-- strlower cache for maximum efficiency
Lib.strlowerCache = Lib.strlowerCache or setmetatable(
{}, {
	__index = function(t, i)
		if not i then return end
		local o
		if type(i) == "number" then
			o = i
		else
			o = strlower(i)
		end
		t[i] = o
		return o
	end,
}) local strlowerCache = Lib.strlowerCache

-- Matches lowercase player spell names to their spellBookID
Lib.spellsByName_spell = Lib.spellsByName_spell or {}
local spellsByName_spell = Lib.spellsByName_spell

-- Matches player spellIDs to their spellBookID
Lib.spellsByID_spell = Lib.spellsByID_spell or {}
local spellsByID_spell = Lib.spellsByID_spell

-- Matches lowercase pet spell names to their spellBookID
Lib.spellsByName_pet = Lib.spellsByName_pet or {}
local spellsByName_pet = Lib.spellsByName_pet

-- Matches pet spellIDs to their spellBookID
Lib.spellsByID_pet = Lib.spellsByID_pet or {}
local spellsByID_pet = Lib.spellsByID_pet

-- Matches pet spell names to their pet action bar slot
Lib.actionsByName_pet = Lib.actionsByName_pet or {}
local actionsByName_pet = Lib.actionsByName_pet

-- Matches pet spell IDs to their pet action bar slot
Lib.actionsById_pet = Lib.actionsById_pet or {}
local actionsById_pet = Lib.actionsById_pet

-- Caches whether a pet spell has been observed to ever have had a range.
-- Since this should never change for any particular spell,
-- it is not wiped.
Lib.petSpellHasRange = Lib.petSpellHasRange or {}
local petSpellHasRange = Lib.petSpellHasRange

-- Updates spellsByName and spellsByID

local GetNumSpellTabs = _G.GetNumSpellTabs or C_SpellBook.GetNumSpellBookSkillLines
local GetSpellTabInfo = _G.GetSpellTabInfo or function(index)
	local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(index);
	if skillLineInfo then
		return	skillLineInfo.name,
				skillLineInfo.iconID,
				skillLineInfo.itemIndexOffset,
				skillLineInfo.numSpellBookItems,
				skillLineInfo.isGuild,
				skillLineInfo.offSpecID,
				skillLineInfo.shouldHide,
				skillLineInfo.specID;
	end
end

local function UpdateBook(bookType)
	local book = bookType == "spell" and playerBook or petBook
	local max = 0
	for i = 1, GetNumSpellTabs() do
		local _, _, offs, numspells, _, specId = GetSpellTabInfo(i)
		if specId == 0 then
			max = offs + numspells
		end
	end

	local spellsByName = Lib["spellsByName_" .. bookType]
	local spellsByID = Lib["spellsByID_" .. bookType]
	
	wipe(spellsByName)
	wipe(spellsByID)
	
	for spellBookID = 1, max do
		local type, baseSpellID = GetSpellBookItemInfo(spellBookID, book)
		
		if type == "SPELL" or type == "PETACTION" then
			local currentSpellName, _, currentSpellID = GetSpellBookItemName(spellBookID, book)
			if not currentSpellID then
				local link = GetSpellLink(currentSpellName)
				currentSpellID = tonumber(link and link:gsub("|", "||"):match("spell:(%d+)"))
			end

			-- For each entry we add to a table,
			-- only add it if there isn't anything there already.
			-- This prevents weird passives from overwriting real, legit spells.
			-- For example, in WoW 7.3.5 the ret paladin mastery 
			-- was coming back with a base spell named "Judgement",
			-- which was overwriting the real "Judgement".
			-- Passives usually come last in the spellbook,
			-- so this should work just fine as a workaround.
			-- This issue with "Judgement" is gone in BFA because the mastery changed.
			
			if currentSpellName and not spellsByName[strlower(currentSpellName)] then
				spellsByName[strlower(currentSpellName)] = spellBookID
			end
			if currentSpellID and not spellsByID[currentSpellID] then
				spellsByID[currentSpellID] = spellBookID
			end
			
			if type == "SPELL" then
				-- PETACTION (pet abilities) don't return a spellID for baseSpellID,
				-- so base spells only work for proper player spells.
				local baseSpellName = GetSpellName(baseSpellID)
				if baseSpellName and not spellsByName[strlower(baseSpellName)] then
					spellsByName[strlower(baseSpellName)] = spellBookID
				end
				if baseSpellID and not spellsByID[baseSpellID] then
					spellsByID[baseSpellID] = spellBookID
				end
			end
		end
	end
end

local function UpdatePetBar()
	wipe(actionsByName_pet)
	wipe(actionsById_pet)
	if not UnitExists("pet") then return end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID, checksRange, inRange = GetPetActionInfo(i)
		if checksRange then
			actionsByName_pet[strlower(name)] = i
			actionsById_pet[spellID] = i

			petSpellHasRange[strlower(name)] = true
			petSpellHasRange[spellID] = true
		end
	end
end
UpdatePetBar()

Lib.updaterFrame:RegisterEvent("SPELLS_CHANGED")
Lib.updaterFrame:RegisterEvent("PET_BAR_UPDATE")
Lib.updaterFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Lib.updaterFrame:RegisterEvent("CVAR_UPDATE")

local function UpdateSpells(_, event, arg1)
	if event == "PET_BAR_UPDATE" then
		UpdatePetBar()
	elseif event == "PLAYER_TARGET_CHANGED" then
		-- `checksRange` from GetPetActionInfo() changes based on whether the player has a target or not.
		UpdatePetBar()
	elseif event == "SPELLS_CHANGED" then
		UpdateBook("spell")
		UpdateBook("pet")
	elseif event == "CVAR_UPDATE" and arg1 == "ShowAllSpellRanks" then
		UpdateBook("spell")
		UpdateBook("pet")
	end
end

Lib.updaterFrame:SetScript("OnEvent", UpdateSpells)


--- Improved spell range checking function.
-- @name SpellRange.IsSpellInRange
-- @paramsig spell, unit
-- @param spell Name or spellID of a spell that you wish to check the range of. The spell must be a spell that you have in your spellbook or your pet's spellbook.
-- @param unit UnitID of the spell that you wish to check the range on.
-- @return Exact same returns as http://wowprogramming.com/docs/api/IsSpellInRange
-- @usage
-- -- Check spell range by spell name on unit "target"
-- local SpellRange = LibStub("SpellRange-1.0")
-- local inRange = SpellRange.IsSpellInRange("Stormstrike", "target")
--
-- -- Check spell range by spellID on unit "mouseover"
-- local SpellRange = LibStub("SpellRange-1.0")
-- local inRange = SpellRange.IsSpellInRange(17364, "mouseover")
function Lib.IsSpellInRange(spellInput, unit)
	if isNumber[spellInput] then
		local spell = spellsByID_spell[spellInput]
		if spell then
			return IsSpellBookItemInRange(spell, playerBook, unit)
		else
			local spell = spellsByID_pet[spellInput]
			if spell then
				local petResult = IsSpellBookItemInRange(spell, petBook, unit)
				if petResult ~= nil then
					return petResult
				end
				
				-- IsSpellInRange seems to no longer work for pet spellbook,
				-- so we also try the action bar API.
				local actionSlot = actionsById_pet[spellInput]
				if actionSlot and (unit == "target" or UnitIsUnit(unit, "target")) then
					return select(9, GetPetActionInfo(actionSlot)) and 1 or 0
				end
			end
		end

		-- if "show all ranks" in spellbook is not ticked and the input was a lower rank of a spell, it won't exist in spellsByID_spell. 
		-- Workaround this issue by testing by name when no result was found using spellbook
		local name = GetSpellName(spellInput)
		if name then
			return IsSpellInRange(name, unit)
		end
	else
		local spellInput = strlowerCache[spellInput]
		
		local spell = spellsByName_spell[spellInput]
		if spell then
			return IsSpellBookItemInRange(spell, playerBook, unit)
		else
			local spell = spellsByName_pet[spellInput]
			if spell then
				local petResult = IsSpellBookItemInRange(spell, petBook, unit)
				if petResult ~= nil then
					return petResult
				end

				-- IsSpellInRange seems to no longer work for pet spellbook,
				-- so we also try the action bar API.
				local actionSlot = actionsByName_pet[spellInput]
				if actionSlot and (unit == "target" or UnitIsUnit(unit, "target")) then
					return select(9, GetPetActionInfo(actionSlot)) and 1 or 0
				end
			end
		end
		return IsSpellInRange(spellInput, unit)
	end
end


--- Improved SpellHasRange.
-- @name SpellRange.SpellHasRange
-- @paramsig spell
-- @param spell Name or spellID of a spell that you wish to check for a range. The spell must be a spell that you have in your spellbook or your pet's spellbook.
-- @return Exact same returns as http://wowprogramming.com/docs/api/SpellHasRange
-- @usage
-- -- Check if a spell has a range by spell name
-- local SpellRange = LibStub("SpellRange-1.0")
-- local hasRange = SpellRange.SpellHasRange("Stormstrike")
--
-- -- Check if a spell has a range by spellID
-- local SpellRange = LibStub("SpellRange-1.0")
-- local hasRange = SpellRange.SpellHasRange(17364)
function Lib.SpellHasRange(spellInput)
	if isNumber[spellInput] then
		local spell = spellsByID_spell[spellInput]
		if spell then
			return SpellBookHasRange(spell, playerBook)
		else
			local spell = spellsByID_pet[spellInput]
			if spell then
				-- SpellHasRange seems to no longer work for pet spellbook.
				return SpellBookHasRange(spell, petBook) or petSpellHasRange[spellInput] or false
			end
		end
	
		local name = GetSpellName(spellInput)
		if name then
			return SpellHasRange(name)
		end
	else
		local spellInput = strlowerCache[spellInput]
		
		local spell = spellsByName_spell[spellInput]
		if spell then
			return SpellBookHasRange(spell, playerBook)
		else
			local spell = spellsByName_pet[spellInput]
			if spell then
				-- SpellHasRange seems to no longer work for pet spellbook.
				return SpellBookHasRange(spell, petBook) or petSpellHasRange[spellInput] or false
			end
		end
		return SpellHasRange(spellInput)
	end
end