--[[
Name: LibRangeCheck-2.0
Revision: $Revision$
Author(s): mitch0
Website: http://www.wowace.com/projects/librangecheck-2-0/
Description: A range checking library based on interact distances and spell ranges
Dependencies: LibStub
License: Public Domain
]]

--- LibRangeCheck-2.0 provides an easy way to check for ranges and get suitable range checking functions for specific ranges.\\
-- The checkers use spell and item range checks, or interact based checks for special units where those two cannot be used.\\
-- The lib handles the refreshing of checker lists in case talents / spells change and in some special cases when equipment changes (for example some of the mage pvp gloves change the range of the Fire Blast spell), and also handles the caching of items used for item-based range checks.\\
-- A callback is provided for those interested in checker changes.
-- @usage
-- local rc = LibStub("LibRangeCheck-2.0")
-- 
-- rc.RegisterCallback(self, rc.CHECKERS_CHANGED, function() print("need to refresh my stored checkers") end)
-- 
-- local minRange, maxRange = rc:GetRange('target')
-- if not minRange then
--     print("cannot get range estimate for target")
-- elseif not maxRange then
--     print("target is over " .. minRange .. " yards")
-- else
--     print("target is between " .. minRange .. " and " .. maxRange .. " yards")
-- end
-- 
-- local meleeChecker = rc:GetFriendMaxChecker(rc.MeleeRange) -- 5 yds
-- for i = 1, 4 do
--     -- TODO: check if unit is valid, etc
--     if meleeChecker("party" .. i) then
--         print("Party member " .. i .. " is in Melee range")
--     end
-- end
--
-- local safeDistanceChecker = rc:GetHarmMinChecker(30)
-- -- negate the result of the checker!
-- local isSafelyAway = not safeDistanceChecker('target')
--
-- @class file
-- @name LibRangeCheck-2.0
local MAJOR_VERSION = "LibRangeCheck-2.0"
local MINOR_VERSION = tonumber(("$Revision: 188$"):match("%d+")) + 100000

local lib, oldminor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
    return
end

-- << STATIC CONFIG

local UpdateDelay = .5
local ItemRequestTimeout = 10.0
local FriendColor = 'ff22ff22'
local HarmColor = 'ffff2222'

-- interact distance based checks. ranges are based on my own measurements (thanks for all the folks who helped me with this)
local DefaultInteractList = {
    [3] = 8,
--    [2] = 9,
    [4] = 28,
}

-- interact list overrides for races
local InteractLists = {
    ["Tauren"] = {
        [3] = 6,
--        [2] = 7,
        [4] = 25,
    },
    ["Scourge"] = {
        [3] = 7,
--        [2] = 8,
        [4] = 27,
    },
}

local MeleeRange = 5

-- list of friendly spells that have different ranges
local FriendSpells = {}
-- list of harmful spells that have different ranges 
local HarmSpells = {}

FriendSpells["DEATHKNIGHT"] = {
}
HarmSpells["DEATHKNIGHT"] = {
    49576, -- ["Death Grip"], -- 30
}

FriendSpells["DEMONHUNTER"] = {
}
HarmSpells["DEMONHUNTER"] = {
    185123, -- ["Throw Glaive"], -- 30
}

FriendSpells["DRUID"] = {
    774, -- ["Rejuvenation"], -- 40
    2782, -- ["Remove Corruption"], -- 40
}
HarmSpells["DRUID"] = {
    5176, -- ["Wrath"], -- 40
    339, -- ["Entangling Roots"], -- 35
    6795, -- ["Growl"], -- 30
    33786, -- ["Cyclone"], -- 20
    22568, -- ["Ferocious Bite"], -- 5
}

FriendSpells["HUNTER"] = {}
HarmSpells["HUNTER"] = {
    75, -- ["Auto Shot"], -- 40
}

FriendSpells["MAGE"] = {
}
HarmSpells["MAGE"] = {
    44614, --["Frostfire Bolt"], -- 40
    5019, -- ["Shoot"], -- 30
}

FriendSpells["MONK"] = {
    115450, -- ["Detox"], -- 40
    115546, -- ["Provoke"], -- 30
}
HarmSpells["MONK"] = {
    115546, -- ["Provoke"], -- 30
    115078, -- ["Paralysis"], -- 20
    100780, -- ["Tiger Palm"], -- 5
}

FriendSpells["PALADIN"] = {
    19750, -- ["Flash of Light"], -- 40
}
HarmSpells["PALADIN"] = {
    62124, -- ["Reckoning"], -- 30
    20271, -- ["Judgement"], -- 30
    853, -- ["Hammer of Justice"], -- 10
    35395, -- ["Crusader Strike"], -- 5
} 

FriendSpells["PRIEST"] = {
    527, -- ["Purify"], -- 40
    17, -- ["Power Word: Shield"], -- 40
}
HarmSpells["PRIEST"] = {
    589, -- ["Shadow Word: Pain"], -- 40
    5019, -- ["Shoot"], -- 30
}

FriendSpells["ROGUE"] = {}
HarmSpells["ROGUE"] = {
    2764, -- ["Throw"], -- 30
    2094, -- ["Blind"], -- 15
}

FriendSpells["SHAMAN"] = {
    8004, -- ["Healing Surge"], -- 40
    546, -- ["Water Walking"], -- 30
}
HarmSpells["SHAMAN"] = {
    403, -- ["Lightning Bolt"], -- 40
    370, -- ["Purge"], -- 30
    73899, -- ["Primal Strike"],. -- 5
}

FriendSpells["WARRIOR"] = {}
HarmSpells["WARRIOR"] = {
    355, -- ["Taunt"], -- 30
    100, -- ["Charge"], -- 8-25
    5246, -- ["Intimidating Shout"], -- 8
}

FriendSpells["WARLOCK"] = {
    5697, -- ["Unending Breath"], -- 30
}
HarmSpells["WARLOCK"] = {
    686, -- ["Shadow Bolt"], -- 40
    5019, -- ["Shoot"], -- 30
}

-- Items [Special thanks to Maldivia for the nice list]

local FriendItems  = {
    [1] = {
        90175, -- Gin-Ji Knife Set -- doesn't seem to work for pets (always returns nil)
    },
    [2] = {
        37727, -- Ruby Acorn
    },
    [3] = {
        42732, -- Everfrost Razor
    },
    [4] = {
        129055, -- Shoe Shine Kit
    },
    [5] = {
        8149, -- Voodoo Charm
        136605, -- Solendra's Compassion
        63427, -- Worgsaw
    },
    [7] = {
        61323, -- Ruby Seeds
    },
    [8] = {
        34368, -- Attuned Crystal Cores
        33278, -- Burning Torch
    },
    [10] = {
        32321, -- Sparrowhawk Net
    },
    [15] = {
        1251, -- Linen Bandage
        2581, -- Heavy Linen Bandage
        3530, -- Wool Bandage
        3531, -- Heavy Wool Bandage
        6450, -- Silk Bandage
        6451, -- Heavy Silk Bandage
        8544, -- Mageweave Bandage
        8545, -- Heavy Mageweave Bandage
        14529, -- Runecloth Bandage
        14530, -- Heavy Runecloth Bandage
        21990, -- Netherweave Bandage
        21991, -- Heavy Netherweave Bandage
        34721, -- Frostweave Bandage
        34722, -- Heavy Frostweave Bandage
--        38643, -- Thick Frostweave Bandage
--        38640, -- Dense Frostweave Bandage
    },
    [20] = {
        21519, -- Mistletoe
    },
    [25] = {
        31463, -- Zezzak's Shard
    },
    [30] = {
        1180, -- Scroll of Stamina
        1478, -- Scroll of Protection II
        3012, -- Scroll of Agility
        1712, -- Scroll of Spirit II
        2290, -- Scroll of Intellect II
        1711, -- Scroll of Stamina II
        34191, -- Handful of Snowflakes
    },
    [35] = {
        18904, -- Zorbin's Ultra-Shrinker
    },
    [38] = {
        140786, -- Ley Spider Eggs
    },
    [40] = {
        34471, -- Vial of the Sunwell
    },
    [45] = {
        32698, -- Wrangling Rope
    },
    [50] = {
        116139, -- Haunting Memento
    },
    [55] = {
        74637, -- Kiryn's Poison Vial
    },
    [60] = {
        32825, -- Soul Cannon
        37887, -- Seeds of Nature's Wrath
    },
    [70] = {
        41265, -- Eyesore Blaster
    },
    [80] = {
        35278, -- Reinforced Net
    },
    [90] = {
        133925, -- Fel Lash
    },
    [100] = {
        41058, -- Hyldnir Harpoon
    },
    [150] = {
        46954, -- Flaming Spears
    },
    [200] = {
        75208, -- Rancher's Lariat
    },
}

local HarmItems = {
    [1] = {
    },
    [2] = {
        37727, -- Ruby Acorn
    },
    [3] = {
        42732, -- Everfrost Razor
    },
    [4] = {
        129055, -- Shoe Shine Kit
    },
    [5] = {
        8149, -- Voodoo Charm
        136605, -- Solendra's Compassion
        63427, -- Worgsaw
    },
    [7] = {
        61323, -- Ruby Seeds
    },
    [8] = {
        34368, -- Attuned Crystal Cores
        33278, -- Burning Torch
    },
    [10] = {
        32321, -- Sparrowhawk Net
    },
    [15] = {
        33069, -- Sturdy Rope
    },
    [20] = {
        10645, -- Gnomish Death Ray
    },
    [25] = {
        24268, -- Netherweave Net
        41509, -- Frostweave Net
        31463, -- Zezzak's Shard
    },
    [30] = {
        835, -- Large Rope Net
        7734, -- Six Demon Bag
        34191, -- Handful of Snowflakes
    },
    [35] = {
        24269, -- Heavy Netherweave Net
        18904, -- Zorbin's Ultra-Shrinker
    },
    [38] = {
        140786, -- Ley Spider Eggs
    },
    [40] = {
        28767, -- The Decapitator
    },
    [45] = {
--        32698, -- Wrangling Rope
        23836, -- Goblin Rocket Launcher
    },
    [50] = {
        116139, -- Haunting Memento
    },
    [55] = {
        74637, -- Kiryn's Poison Vial
    },
    [60] = {
        32825, -- Soul Cannon
        37887, -- Seeds of Nature's Wrath
    },
    [70] = {
        41265, -- Eyesore Blaster
    },
    [80] = {
        35278, -- Reinforced Net
    },
    [90] = {
        133925, -- Fel Lash
    },
    [100] = {
        33119, -- Malister's Frost Wand
    },
    [150] = {
        46954, -- Flaming Spears
    },
    [200] = {
        75208, -- Rancher's Lariat
    },
}

-- This could've been done by checking player race as well and creating tables for those, but it's easier like this
for k, v in pairs(FriendSpells) do
    tinsert(v, 28880) -- ["Gift of the Naaru"]
end

-- >> END OF STATIC CONFIG

-- cache

local setmetatable = setmetatable
local tonumber = tonumber
local pairs = pairs
local tostring = tostring
local print = print
local next = next
local type = type
local wipe = wipe
local tinsert = tinsert
local tremove = tremove
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local GetSpellInfo = GetSpellInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellTabInfo = GetSpellTabInfo
local GetItemInfo = GetItemInfo
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local CheckInteractDistance = CheckInteractDistance
local IsSpellInRange = IsSpellInRange
local IsItemInRange = IsItemInRange
local UnitClass = UnitClass
local UnitRace = UnitRace
local GetInventoryItemLink = GetInventoryItemLink
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local HandSlotId = GetInventorySlotInfo("HandsSlot")
local math_floor = math.floor
local UnitIsVisible = UnitIsVisible

-- temporary stuff

local itemRequestTimeoutAt
local foundNewItems
local cacheAllItems
local friendItemRequests
local harmItemRequests
local lastUpdate = 0

-- minRangeCheck is a function to check if spells with minimum range are really out of range, or fail due to range < minRange. See :init() for its setup
local minRangeCheck = function(unit) return CheckInteractDistance(unit, 2) end

local checkers_Spell = setmetatable({}, {
    __index = function(t, spellIdx)
        local func = function(unit)
            if IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1 then
                 return true
            end
        end
        t[spellIdx] = func
        return func
    end
})
local checkers_SpellWithMin = setmetatable({}, {
    __index = function(t, spellIdx)
        local func = function(unit)
            if IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1 then
                return true
            elseif minRangeCheck(unit) then
                return true, true
            end
        end
        t[spellIdx] = func
        return func
    end
})
local checkers_Item = setmetatable({}, {
    __index = function(t, item)
        local func = function(unit)
            return IsItemInRange(item, unit)
        end
        t[item] = func
        return func
    end
})
local checkers_Interact = setmetatable({}, {
    __index = function(t, index)
        local func = function(unit)
            if CheckInteractDistance(unit, index) then
                 return true
            end
        end
        t[index] = func
        return func
    end
})

-- helper functions

local function copyTable(src, dst)
    if type(dst) ~= "table" then dst = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then
                v = copyTable(v, dst[k])
            end
            dst[k] = v
        end
    end
    return dst
end


local function initItemRequests(cacheAll)
    friendItemRequests = copyTable(FriendItems)
    harmItemRequests = copyTable(HarmItems)
    cacheAllItems = cacheAll
    foundNewItems = nil
end

local function getNumSpells()
    local _, _, offset, numSpells = GetSpellTabInfo(GetNumSpellTabs())
    return offset + numSpells
end

-- return the spellIndex of the given spell by scanning the spellbook
local function findSpellIdx(spellName)
    if not spellName or spellName == "" then
        return nil
    end
    for i = 1, getNumSpells() do
        local spell, rank = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if spell == spellName then return i end
    end
    return nil
end

-- minRange should be nil if there's no minRange, not 0
local function addChecker(t, range, minRange, checker, info)
    local rc = { ["range"] = range, ["minRange"] = minRange, ["checker"] = checker, ["info"] = info }
    for i = 1, #t do
        local v = t[i]
        if rc.range == v.range then return end
        if rc.range > v.range then
            tinsert(t, i, rc)
            return
        end
    end
    tinsert(t, rc)
end

local function createCheckerList(spellList, itemList, interactList)
    local res = {}
    if itemList then
        for range, items in pairs(itemList) do
            for i = 1, #items do
                local item = items[i]
                if GetItemInfo(item) then
                    addChecker(res, range, nil, checkers_Item[item], "item:" .. item)
                    break
                end
            end
        end
    end
    
    if spellList then
        for i = 1, #spellList do
            local sid = spellList[i]
            local name, _, _, _, minRange, range = GetSpellInfo(sid)
            local spellIdx = findSpellIdx(name)
            if spellIdx and range then
                minRange = math_floor(minRange + 0.5)
                range = math_floor(range + 0.5)
                -- print("### spell: " .. tostring(name) .. ", " .. tostring(minRange) .. " - " ..  tostring(range))
                if minRange == 0 then -- getRange() expects minRange to be nil in this case
                    minRange = nil
                end
                if range == 0 then
                    range = MeleeRange
                end
                if minRange then
                    addChecker(res, range, minRange, checkers_SpellWithMin[spellIdx], "spell:" .. sid .. ":" .. tostring(name))
                else
                    addChecker(res, range, minRange, checkers_Spell[spellIdx], "spell:" .. sid .. ":" .. tostring(name))
                end
            end
        end
    end
    
    if interactList and not next(res) then
        for index, range in pairs(interactList) do
            addChecker(res, range, nil,  checkers_Interact[index], "interact:" .. index)
        end
    end

    return res
end

-- returns minRange, maxRange  or nil
local function getRange(unit, checkerList)
    local lo, hi = 1, #checkerList
    while lo <= hi do
        local mid = math_floor((lo + hi) / 2)
        local rc = checkerList[mid]
        if rc.checker(unit) then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    if lo > #checkerList then
        return 0, checkerList[#checkerList].range
    elseif lo <= 1 then
        return checkerList[1].range, nil
    else
        return checkerList[lo].range, checkerList[lo - 1].range
    end
end

local function updateCheckers(origList, newList)
    if #origList ~= #newList then
        wipe(origList)
        copyTable(newList, origList)
        return true
    end
    for i = 1, #origList do
        if origList[i].range ~= newList[i].range or origList[i].checker ~= newList[i].checker then
            wipe(origList)
            copyTable(newList, origList)
            return true
        end
    end
end

local function rcIterator(checkerList)
    local curr = #checkerList
    return function()
        local rc = checkerList[curr]
        if not rc then
             return nil
        end
        curr = curr - 1
        return rc.range, rc.checker
    end
end

local function getMinChecker(checkerList, range)
    local checker, checkerRange
    for i = 1, #checkerList do
        local rc = checkerList[i]
        if rc.range < range then
            return checker, checkerRange
        end
        checker, checkerRange = rc.checker, rc.range
    end
    return checker, checkerRange
end

local function getMaxChecker(checkerList, range)
    for i = 1, #checkerList do
        local rc = checkerList[i]
        if rc.range <= range then
            return rc.checker, rc.range
        end
    end
end

local function getChecker(checkerList, range)
    for i = 1, #checkerList do
        local rc = checkerList[i]
        if rc.range == range then
            return rc.checker
        end
    end
end

local function null()
end

local function createSmartChecker(friendChecker, harmChecker, miscChecker)
    miscChecker = miscChecker or null
    friendChecker = friendChecker or miscChecker
    harmChecker = harmChecker or miscChecker
    return function(unit)
        if not UnitExists(unit) then
            return nil
        end
        if UnitIsDeadOrGhost(unit) then
            return miscChecker(unit)
        end
        if UnitCanAttack("player", unit) then
            return harmChecker(unit)
        elseif UnitCanAssist("player", unit) then
            return friendChecker(unit)
        else
            return miscChecker(unit)
        end
    end
end

-- OK, here comes the actual lib

-- pre-initialize the checkerLists here so that we can return some meaningful result even if
-- someone manages to call us before we're properly initialized. miscRC should be independent of
-- race/class/talents, so it's safe to initialize it here
-- friendRC and harmRC will be properly initialized later when we have all the necessary data for them
lib.checkerCache_Spell = lib.checkerCache_Spell or {}
lib.checkerCache_Item = lib.checkerCache_Item or {}
lib.miscRC = createCheckerList(nil, nil, DefaultInteractList)
lib.friendRC = createCheckerList(nil, nil, DefaultInteractList)
lib.harmRC = createCheckerList(nil, nil, DefaultInteractList)

lib.failedItemRequests = {}

-- << Public API

--@do-not-package@
-- this is here just for .docmeta
--- A checker function. This type of function is returned by the various Get*Checker() calls.
-- @param unit the unit to check range to.
-- @return **true** if the unit is within the range for this checker.
local function checker(unit)
end

--@end-do-not-package@ 

--- The callback name that is fired when checkers are changed.
-- @field
lib.CHECKERS_CHANGED = "CHECKERS_CHANGED"
-- "export" it, maybe someone will need it for formatting
--- Constant for Melee range (5yd).
-- @field
lib.MeleeRange = MeleeRange

function lib:findSpellIndex(spell)
    if type(spell) == 'number' then
        spell = GetSpellInfo(spell)
    end
    return findSpellIdx(spell)
end

-- returns the range estimate as a string
-- deprecated, use :getRange(unit) instead and build your own strings
-- @param checkVisible if set to true, then a UnitIsVisible check is made, and **nil** is returned if the unit is not visible
function lib:getRangeAsString(unit, checkVisible, showOutOfRange)
    local minRange, maxRange = self:getRange(unit, checkVisible)
    if not minRange then return nil end
    if not maxRange then
        return showOutOfRange and minRange .. " +" or nil
    end
    return minRange .. " - " .. maxRange
end

-- initialize RangeCheck if not yet initialized or if "forced"
function lib:init(forced)
    if self.initialized and (not forced) then
        return
    end
    self.initialized = true
    local _, playerClass = UnitClass("player")
    local _, playerRace = UnitRace("player")

    minRangeCheck = nil
    -- first try to find a nice item we can use for minRangeCheck
    if HarmItems[15] then
        local items = HarmItems[15]
        for i = 1, #items do
            local item = items[i]
            if GetItemInfo(item) then
                minRangeCheck = function(unit)
                    return IsItemInRange(item, unit)
                end
                break
            end
        end
    end
    if not minRangeCheck then
        -- ok, then try to find some class specific spell
        if playerClass == "WARRIOR" then
            -- for warriors, use Intimidating Shout if available
            local name = GetSpellInfo(5246) -- ["Intimidating Shout"]
            local spellIdx = findSpellIdx(name)
            if spellIdx then
                minRangeCheck = function(unit)
                    return (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1)
                end
            end
        elseif playerClass == "ROGUE" then
            -- for rogues, use Blind if available
            local name = GetSpellInfo(2094) -- ["Blind"]
            local spellIdx = findSpellIdx(name)
            if spellIdx then
                minRangeCheck = function(unit)
                    return (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1)
                end
            end
        end
    end
    if not minRangeCheck then
        -- fall back to interact distance checks
        if playerClass == "HUNTER" or playerRace == "Tauren" then
            -- for hunters, use interact4 as it's safer
            -- for Taurens interact4 is actually closer than 25yd and interact3 is closer than 8yd, so we can't use that
            minRangeCheck = checkers_Interact[4]
        else
            minRangeCheck = checkers_Interact[3]
        end
    end

    local interactList = InteractLists[playerRace] or DefaultInteractList
    self.handSlotItem = GetInventoryItemLink("player", HandSlotId)
    local changed = false
    if updateCheckers(self.friendRC, createCheckerList(FriendSpells[playerClass], FriendItems, interactList)) then
        changed = true
    end
    if updateCheckers(self.harmRC, createCheckerList(HarmSpells[playerClass], HarmItems, interactList)) then
        changed = true
    end
    if updateCheckers(self.miscRC, createCheckerList(nil, nil, interactList)) then
        changed = true
    end
    if changed and self.callbacks then
        self.callbacks:Fire(self.CHECKERS_CHANGED)
    end
end

--- Return an iterator for checkers usable on friendly units as (**range**, **checker**) pairs.
function lib:GetFriendCheckers()
    return rcIterator(self.friendRC)
end

--- Return an iterator for checkers usable on enemy units as (**range**, **checker**) pairs.
function lib:GetHarmCheckers()
    return rcIterator(self.harmRC)
end

--- Return an iterator for checkers usable on miscellaneous units as (**range**, **checker**) pairs.  These units are neither enemy nor friendly, such as people in sanctuaries or corpses.
function lib:GetMiscCheckers()
    return rcIterator(self.miscRC)
end

--- Return a checker suitable for out-of-range checking on friendly units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetFriendMinChecker(range)
    return getMinChecker(self.friendRC, range)
end

--- Return a checker suitable for out-of-range checking on enemy units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetHarmMinChecker(range)
    return getMinChecker(self.harmRC, range)
end

--- Return a checker suitable for out-of-range checking on miscellaneous units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetMiscMinChecker(range)
    return getMinChecker(self.miscRC, range)
end

--- Return a checker suitable for in-range checking on friendly units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetFriendMaxChecker(range)
    return getMaxChecker(self.friendRC, range)
end

--- Return a checker suitable for in-range checking on enemy units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetHarmMaxChecker(range)
    return getMaxChecker(self.harmRC, range)
end

--- Return a checker suitable for in-range checking on miscellaneous units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetMiscMaxChecker(range)
    return getMaxChecker(self.miscRC, range)
end

--- Return a checker for the given range for friendly units.
-- @param range the range to check for.
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetFriendChecker(range)
    return getChecker(self.friendRC, range)
end

--- Return a checker for the given range for enemy units.
-- @param range the range to check for.
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetHarmChecker(range)
    return getChecker(self.harmRC, range)
end

--- Return a checker for the given range for miscellaneous units.
-- @param range the range to check for.
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetMiscChecker(range)
    return getChecker(self.miscRC, range)
end

--- Return a checker suitable for out-of-range checking that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @return **checker** function.
function lib:GetSmartMinChecker(range)
    return createSmartChecker(
        getMinChecker(self.friendRC, range),
        getMinChecker(self.harmRC, range),
        getMinChecker(self.miscRC, range))
end

--- Return a checker suitable for in-of-range checking that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @return **checker** function.
function lib:GetSmartMaxChecker(range)
    return createSmartChecker(
        getMaxChecker(self.friendRC, range),
        getMaxChecker(self.harmRC, range),
        getMaxChecker(self.miscRC, range))
end

--- Return a checker for the given range that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @param fallback optional fallback function that gets called as fallback(unit) if a checker is not available for the given type (friend/harm/misc) at the requested range. The default fallback function return nil.
-- @return **checker** function.
function lib:GetSmartChecker(range, fallback)
    return createSmartChecker(
        getChecker(self.friendRC, range) or fallback,
        getChecker(self.harmRC, range) or fallback,
        getChecker(self.miscRC, range) or fallback)
end

--- Get a range estimate as **minRange**, **maxRange**.
-- @param unit the target unit to check range to.
-- @param checkVisible if set to true, then a UnitIsVisible check is made, and **nil** is returned if the unit is not visible
-- @return **minRange**, **maxRange** pair if a range estimate could be determined, **nil** otherwise. **maxRange** is **nil** if **unit** is further away than the highest possible range we can check.
-- Includes checks for unit validity and friendly/enemy status.
-- @usage
-- local rc = LibStub("LibRangeCheck-2.0")
-- local minRange, maxRange = rc:GetRange('target')
-- local minRangeIfVisible, maxRangeIfVisible = rc:GetRange('target', true)
function lib:GetRange(unit, checkVisible)
    if not UnitExists(unit) then
        return nil
    end
    if checkVisible and not UnitIsVisible(unit) then
        return nil
    end
    if UnitIsDeadOrGhost(unit) then
        return getRange(unit, self.miscRC)
    end
    if UnitCanAttack("player", unit) then
        return getRange(unit, self.harmRC)
    elseif UnitCanAssist("player", unit) then
        return getRange(unit, self.friendRC)
    else
        return getRange(unit, self.miscRC)
    end
end

-- keep this for compatibility
lib.getRange = lib.GetRange

-- >> Public API

function lib:OnEvent(event, ...)
    if type(self[event]) == 'function' then
        self[event](self, event, ...)
    end
end

function lib:LEARNED_SPELL_IN_TAB()
    self:scheduleInit()
end

function lib:CHARACTER_POINTS_CHANGED()
    self:scheduleInit()
end

function lib:PLAYER_TALENT_UPDATE()
    self:scheduleInit()
end

function lib:SPELLS_CHANGED()
    self:scheduleInit()
end

function lib:UNIT_INVENTORY_CHANGED(event, unit)
    if self.initialized and unit == "player" and self.handSlotItem ~= GetInventoryItemLink("player", HandSlotId) then
        self:scheduleInit()
    end
end

function lib:UNIT_AURA(event, unit)
    if self.initialized and unit == "player" then
        self:scheduleAuraCheck()
    end
end

function lib:processItemRequests(itemRequests)
    while true do
        local range, items = next(itemRequests)
        if not range then return end
        while true do
            local i, item = next(items)
            if not i then
                itemRequests[range] = nil
                break
            elseif self.failedItemRequests[item] then
                tremove(items, i)
            elseif GetItemInfo(item) then
                if itemRequestTimeoutAt then
                    foundNewItems = true
                    itemRequestTimeoutAt = nil
                end
                if not cacheAllItems then
                    itemRequests[range] = nil
                    break
                end
                tremove(items, i)   
            elseif not itemRequestTimeoutAt then
                itemRequestTimeoutAt = GetTime() + ItemRequestTimeout
                return true
            elseif GetTime() > itemRequestTimeoutAt then
                if cacheAllItems then
                    print(MAJOR_VERSION .. ": timeout for item: " .. tostring(item))
                end
                self.failedItemRequests[item] = true
                itemRequestTimeoutAt = nil
                tremove(items, i)
            else
                return true -- still waiting for server response
            end
        end
    end
end

function lib:initialOnUpdate()
    self:init()
    if friendItemRequests then
        if self:processItemRequests(friendItemRequests) then return end
        friendItemRequests = nil
    end
    if harmItemRequests then
        if self:processItemRequests(harmItemRequests) then return end
        harmItemRequests = nil
    end
    if foundNewItems then
        self:init(true)
        foundNewItems = nil
    end
    if cacheAllItems then
        print(MAJOR_VERSION .. ": finished cache")
        cacheAllItems = nil
    end
    self.frame:Hide()
end

function lib:scheduleInit()
    self.initialized = nil
    lastUpdate = 0
    self.frame:Show()
end

function lib:scheduleAuraCheck()
    lastUpdate = UpdateDelay
    self.frame:Show()
end

--@do-not-package@
-- << DEBUG STUFF

local function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do tinsert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function lib:cacheAllItems()
    if (not self.initialized) or harmItemRequests then
        print(MAJOR_VERSION .. ": init hasn't finished yet")
        return
    end
    print(MAJOR_VERSION .. ": starting item cache")
    initItemRequests(true)
    self.frame:Show()
end

function lib:startMeasurement(unit, resultTable)
    if (not self.initialized) or harmItemRequests then
        print(MAJOR_VERSION .. ": init hasn't finished yet")
        return
    end
    if self.measurements then
        print(MAJOR_VERSION .. ": measurements already running")
        return
    end
    print(MAJOR_VERSION .. ": starting measurements")
    local _, playerClass = UnitClass("player")
    local spellList
    local itemList
    if UnitCanAttack("player", unit) then
        spellList = HarmSpells[playerClass]
        itemList = HarmItems
    elseif UnitCanAssist("player", unit) then
        spellList = FriendSpells[playerClass]
        itemList = FriendItems
    end
    self.spellsToMeasure = {}
    if spellList then
        for i = 1, #spellList do
            local sid = spellList[i]
            local name = GetSpellInfo(sid)
            local spellIdx = findSpellIdx(name)
            if spellIdx then
                self.spellsToMeasure[name] = spellIdx
            end
        end
    end
    self.itemsToMeasure = {}
    if itemList then
        for range, items in pairs(itemList) do
            for i = 1, #items do
                local item = items[i]
                local name = GetItemInfo(item)
                if name then
                    self.itemsToMeasure[name] = item
                end
            end
        end
    end
    self.measurements = resultTable
    self.measurementUnit = unit
    self.measurementStart = GetTime()
    self.lastMeasurements = {}
    self:updateMeasurements()
    self.frame:SetScript("OnUpdate", function(frame, elapsed) self:updateMeasurements() end)
    self.frame:Show()
end

function lib:stopMeasurement()
    print(MAJOR_VERSION .. ": stopping measurements")
    self.frame:Hide()
    self.frame:SetScript("OnUpdate", function(frame, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate < UpdateDelay then
            return
        end
        lastUpdate = 0
        self:initialOnUpdate()
    end)
    self.measurements = nil
end

function lib:checkItems(itemList, verbose, color)
    if not itemList then return end
    color = color or 'ffffffff'
    for range, items in pairsByKeys(itemList) do
        for i = 1, #items do
            local item = items[i]
            local name = GetItemInfo(item)
            if not name then
                print(MAJOR_VERSION .. ": |c" .. color .. tostring(item) .. "|r: " .. tostring(range) .. "yd: |cffeda500not in cache|r")
            else
                local res = IsItemInRange(item, "target") 
                if res == nil or verbose then
                    if res == nil then res = "|cffed0000nil|r" end
                    print(MAJOR_VERSION .. ": |c" .. color .. tostring(item) .. ": " .. tostring(name) .. "|r: " .. tostring(range) .. "yd: " .. tostring(res))
                end
            end
        end
    end
end

function lib:checkSpells(spellList, verbose, color)
    if not spellList then return end
    color = color or 'ffffffff'
    for i = 1, #spellList do 
        local sid = spellList[i]
        local name, _, _, _, minRange, range = GetSpellInfo(sid)
        if (not name) or (name == "") or (not range) then
            print(MAJOR_VERSION .. ": |c" .. color .. tostring(sid) .. "|r: " .. tostring(range) .. "yd: |cffeda500invalid spell id|r")
        else
            local spellIdx = self:findSpellIndex(sid)
            if not spellIdx then
                print(MAJOR_VERSION .. ": |c" .. color .. tostring(sid) .. ": " .. tostring(name) .. "|r: " .. tostring(minRange) .. "-" .. tostring(range) .. "yd: |cffeda500not in spellbook|r")
            else
                local res = IsSpellInRange(spellIdx, BOOKTYPE_SPELL, "target")
                if res == nil or verbose then
                    if res == nil then res = "|cffed0000nil|r" end
                    print(MAJOR_VERSION .. ": |c" .. color .. tostring(sid) .. ": " .. tostring(name) .. "|r: " .. tostring(minRange) .. "-" .. tostring(range) .. "yd: " .. tostring(res))
                end
            end
        end
    end
end

function lib:checkAllItems()
    print(MAJOR_VERSION .. ": Checking FriendItems...")
    self:checkItems(FriendItems, true, FriendColor)
    print(MAJOR_VERSION .. ": Checking HarmItems...")
    self:checkItems(HarmItems, true, HarmColor)
end

function lib:checkAllSpells()
    local _, playerClass = UnitClass("player")
    print(MAJOR_VERSION .. ": Checking FriendSpells: " .. playerClass)
    self:checkSpells(FriendSpells[playerClass], true, FriendColor)
    print(MAJOR_VERSION .. ": Checking HarmSpells..." .. playerClass)
    self:checkSpells(HarmSpells[playerClass], true, HarmColor)
end

local function dumpCheckerList(checkerList)
    for _, rc in ipairs(checkerList) do
        if rc.minRange then
            print(rc.minRange .. "-" .. rc.range .. ": " .. rc.info)
        else
            print(rc.range .. ": " .. rc.info)
        end
    end
end

function lib:checkAllCheckers()
    if not UnitExists("target") then
        print(MAJOR_VERSION .. ": Invalid unit, cannot check")
        return
    end
    local _, playerClass = UnitClass("player")
    if UnitCanAttack("player", "target") then
        print(MAJOR_VERSION .. ": Harm checker list: " .. playerClass)
        dumpCheckerList(self.harmRC)
        print(MAJOR_VERSION .. ": Checking HarmCheckers: " .. playerClass)
        self:checkItems(HarmItems)
        self:checkSpells(HarmSpells[playerClass])
    elseif UnitCanAssist("player", "target") then
        print(MAJOR_VERSION .. ": Friend checker list: " .. playerClass)
        dumpCheckerList(self.friendRC)
        print(MAJOR_VERSION .. ": Checking FriendCheckers: ")
        self:checkItems(FriendItems)
        self:checkSpells(FriendSpells[playerClass])
    else
        print(MAJOR_VERSION .. ": Misc checker list: " .. playerClass)
        dumpCheckerList(self.miscRC)
        print(MAJOR_VERSION .. ": Misc unit, cannot check")
        return
    end
    print(MAJOR_VERSION .. ": done.")
end

local function logMeasurementChange(t, t0, key, last, curr)
    local d = 0
    local scale = 1240
    if t0 then
        local dx = scale * (t.x - t0.x)
        local dy = scale * (t.y - t0.y)
        d = _G.sqrt(dx * dx + dy * dy)
    end
    print(MAJOR_VERSION .. ": t=" .. ("%.4f"):format(t.stamp) .. ": d=" .. ("%.4f"):format(d) .. ": " .. tostring(key) .. ": " .. tostring(last) .. " ->  " .. tostring(curr))
end

local GetPlayerMapPosition = GetPlayerMapPosition
function lib:updateMeasurements()
    local now = GetTime() - self.measurementStart
    local x, y = GetPlayerMapPosition("player")
    local t0 = self.measurements[0]
    local t = self.measurements[now]
    local unit = self.measurementUnit
    for name, id in pairs(self.spellsToMeasure) do
        local key = 'spell: ' .. name
        local last = self.lastMeasurements[key]
        local curr = (IsSpellInRange(id, BOOKTYPE_SPELL, unit) == 1) and true or false
        if last == nil or last ~= curr then
            if not t then
                t = {}
                t.x, t.y, t.stamp, t.states = x, y, now, {}
                self.measurements[now] = t
            end
            logMeasurementChange(t, t0, key, last, curr)
            t.states[key]= curr
            self.lastMeasurements[key] = curr
        end
    end
    for name, item in pairs(self.itemsToMeasure) do
        local key = 'item: ' .. name;
        local last = self.lastMeasurements[key]
        local curr = IsItemInRange(item, unit) and true or false
        if last == nil or last ~= curr then
            if not t then
                t = {}
                t.x, t.y, t.stamp, t.states = x, y, now, {}
                self.measurements[now] = t
            end
            logMeasurementChange(t, t0, key, last, curr)
            t.states[key]= curr
            self.lastMeasurements[key] = curr
        end
    end
    for i, v in pairs(DefaultInteractList) do
        local key = 'interact: ' .. i
        local last = self.lastMeasurements[key]
        local curr = CheckInteractDistance(unit, i) and true or false
        if last == nil or last ~= curr then
            if not t then
                t = {}
                t.x, t.y, t.stamp, t.states = x, y, now, {}
                self.measurements[now] = t
            end
            logMeasurementChange(t, t0, key, last, curr)
            t.states[key] = curr
            self.lastMeasurements[key] = curr
        end
    end
end

local debugprofilestop = debugprofilestop
function lib:speedTest(numIterations)
    if not UnitExists("target") then
        print(MAJOR_VERSION .. ": Invalid unit, cannot check")
        return
    end
    numIterations = numIterations or 10000
    local start = debugprofilestop()
    for i = 1, numIterations do
        self:getRange("target")
    end
    local duration = debugprofilestop() - start
    print("numIterations: " .. tostring(numIterations) .. ", time: " .. tostring(duration))
end

-- >> DEBUG STUFF
--@end-do-not-package@ 

-- << load-time initialization 

function lib:activate()
    if not self.frame then
        local frame = CreateFrame("Frame")
        self.frame = frame
        frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
        frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
        frame:RegisterEvent("PLAYER_TALENT_UPDATE")
        frame:RegisterEvent("SPELLS_CHANGED")
        local _, playerClass = UnitClass("player")
        if playerClass == "MAGE" or playerClass == "SHAMAN" then
            -- Mage and Shaman gladiator gloves modify spell ranges
            frame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
        end
    end
    initItemRequests()
    self.frame:SetScript("OnEvent", function(frame, ...) self:OnEvent(...) end)
    self.frame:SetScript("OnUpdate", function(frame, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate < UpdateDelay then
            return
        end
        lastUpdate = 0
        self:initialOnUpdate()
    end)
    self:scheduleInit()
end

--- BEGIN CallbackHandler stuff

do
    local lib = lib -- to keep a ref even though later we nil lib
    --- Register a callback to get called when checkers are updated
    -- @class function
    -- @name lib.RegisterCallback
    -- @usage
    -- rc.RegisterCallback(self, rc.CHECKERS_CHANGED, "myCallback")
    -- -- or
    -- rc.RegisterCallback(self, "CHECKERS_CHANGED", someCallbackFunction)
    -- @see CallbackHandler-1.0 documentation for more details
    lib.RegisterCallback = lib.RegisterCallback or function(...)
        local CBH = LibStub("CallbackHandler-1.0")
        lib.RegisterCallback = nil -- extra safety, we shouldn't get this far if CBH is not found, but better an error later than an infinite recursion now
        lib.callbacks = CBH:New(lib)
        -- ok, CBH hopefully injected or new shiny RegisterCallback
        return lib.RegisterCallback(...)
    end
end

--- END CallbackHandler stuff

lib:activate()
lib = nil