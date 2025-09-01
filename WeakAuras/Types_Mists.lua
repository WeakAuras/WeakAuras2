if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local encounter_list = ""
local zoneId_list = ""

local journalID2EncoutnerID = {
  [655] = 1397,
  [708] = 1442,
  [660] = 1422,
  [688] = 1423,
  [659] = 1426,
  [673] = 1303,
  [693] = 1465,
  [668] = 1412,
  [672] = 1418,
  [679] = 1395,
  [689] = 1390,
  [682] = 1434,
  [687] = 1436,
  [726] = 1500,
  [677] = 1407,
  [745] = 1507,
  [744] = 1504,
  [713] = 1463,
  [741] = 1498,
  [737] = 1499,
  [743] = 1501,
  [683] = 1409,
  [742] = 1505,
  [729] = 1506,
  [709] = 1431,
  [827] = 1577,
  [819] = 1575,
  [816] = 1570,
  [825] = 1565,
  [821] = 1578,
  [828] = 1573,
  [818] = 1572,
  [820] = 1574,
  [824] = 1576,
  [817] = 1559,
  [829] = 1560,
  [832] = 1579,
  [852] = 1602,
  [849] = 1598,
  [866] = 1624,
  [867] = 1604,
  [868] = 1622,
  [864] = 1600,
  [856] = 1606,
  [850] = 1603,
  [846] = 1595,
  [870] = 1594,
  [851] = 1599,
  [865] = 1601,
  [853] = 1593,
  [869] = 1623,
} -- extracted from retail

function Private.InitializeEncounterAndZoneLists()
	local currTier = EJ_GetCurrentTier()
  if encounter_list ~= "" then
    return
  end
	for tier = EJ_GetNumTiers(), EJ_GetNumTiers() do
		EJ_SelectTier(tier)
		local tierName = EJ_GetTierInfo(tier)
		for _, inRaid in ipairs({false, true}) do
			local instance_index = 1
			local instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
			local title = ("%s %s"):format(tierName , inRaid and L["Raids"] or L["Dungeons"])
			local zones = ""
			while instance_id do
				EJ_SelectInstance(instance_id)
				local instance_name, _, _, _, _, _, dungeonAreaMapID = EJ_GetInstanceInfo(instance_id)
				local ej_index = 1
				local boss, _, journalID = EJ_GetEncounterInfoByIndex(ej_index, instance_id)

				-- zone ids
				if dungeonAreaMapID and dungeonAreaMapID ~= 0 then
					local mapGroupId = C_Map.GetMapGroupID(dungeonAreaMapID)
					if mapGroupId then -- If there's a group id, only list that one
						zones = ("%s%s: g%d\n"):format(zones, instance_name, mapGroupId)
					else
						zones = ("%s%s: %d\n"):format(zones, instance_name, dungeonAreaMapID)
					end
				end

				-- Encounter ids
				if inRaid then
					while boss do
						if journalID and journalID2EncoutnerID[journalID] then
							if instance_name then
								encounter_list = ("%s|cffffd200%s|r\n"):format(encounter_list, instance_name)
								instance_name = nil -- Only add it once per section
							end
							encounter_list = ("%s%s: %d\n"):format(encounter_list, boss, journalID2EncoutnerID[journalID])
						end
						ej_index = ej_index + 1
						boss, _, journalID = EJ_GetEncounterInfoByIndex(ej_index, instance_id)
					end
					encounter_list = encounter_list .. "\n"
				end
				instance_index = instance_index + 1
				instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
			end
			if zones ~= "" then
				zoneId_list = ("%s|cffffd200%s|r\n"):format(zoneId_list, title)
				zoneId_list = zoneId_list .. zones.. "\n"
			end
		end
	end
	EJ_SelectTier(currTier) -- restore previously selected tier

  encounter_list = encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

function Private.get_encounters_list()
  return encounter_list
end

function Private.get_zoneId_list()
  return zoneId_list
end

Private.glyph_types = {}
Private.glyph_sorted = {}

local function FillGlyphData()
  local sorted = {}
  for i = 1, GetNumGlyphs() do
    local name, glyphType, isKnown, icon, glyphID = GetGlyphInfo(i)
    if name and icon and glyphID then
      Private.glyph_types[glyphID] = "|T" .. icon .. ":0|t" .. name
      table.insert(sorted, {glyphID = glyphID, name = name})
    end
  end

  table.sort(sorted, function(a, b)
    return a.name < b.name
  end)

  for _, glyph in ipairs(sorted) do
    table.insert(Private.glyph_sorted, glyph.glyphID)
  end
end

local initGlyphFrame = CreateFrame("Frame")
initGlyphFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initGlyphFrame:SetScript("OnEvent", function()
  initGlyphFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  FillGlyphData()
end)

Private.talentInfo = {
  ["HUNTER"] = {
    {
      461119,
      1,
      1,
      109215,
    },
    {
      237430,
      1,
      2,
      109298,
    },
    {
      236190,
      1,
      3,
      118675,
    },
    {
      462650,
      2,
      1,
      109248,
    },
    {
      135125,
      2,
      2,
      19386,
    },
    {
      132111,
      2,
      3,
      19577,
    },
    {
      461117,
      3,
      1,
      109304,
    },
    {
      612363,
      3,
      2,
      109260,
    },
    {
      132121,
      3,
      3,
      109212,
    },
    {
      132160,
      4,
      1,
      82726,
    },
    {
      461121,
      4,
      2,
      120679,
    },
    {
      132216,
      4,
      3,
      109306,
    },
    {
      645217,
      5,
      1,
      131894,
    },
    {
      135731,
      5,
      2,
      130392,
    },
    {
      132167,
      5,
      3,
      120697,
    },
    {
      648707,
      6,
      1,
      117050,
    },
    {
      461120,
      6,
      2,
      109259,
    },
    {
      236201,
      6,
      3,
      120360,
    },
  },
  ["WARRIOR"] = {
    {
      132335,
      1,
      1,
      103826,
    },
    {
      237377,
      1,
      2,
      103827,
    },
    {
      236319,
      1,
      3,
      103828,
    },
    {
      132345,
      2,
      1,
      55694,
    },
    {
      132175,
      2,
      2,
      29838,
    },
    {
      589768,
      2,
      3,
      103840,
    },
    {
      132091,
      3,
      1,
      107566,
    },
    {
      136147,
      3,
      2,
      12323,
    },
    {
      589118,
      3,
      3,
      102060,
    },
    {
      236303,
      4,
      1,
      46924,
    },
    {
      236312,
      4,
      2,
      46968,
    },
    {
      642418,
      4,
      3,
      118000,
    },
    {
      132358,
      5,
      1,
      114028,
    },
    {
      236311,
      5,
      2,
      114029,
    },
    {
      236318,
      5,
      3,
      114030,
    },
    {
      613534,
      6,
      1,
      107574,
    },
    {
      236304,
      6,
      2,
      12292,
    },
    {
      613535,
      6,
      3,
      107570,
    },
  },
  ["ROGUE"] = {
    {
      132320,
      1,
      1,
      14062,
    },
    {
      571317,
      1,
      2,
      108208,
    },
    {
      571316,
      1,
      3,
      108209,
    },
    {
      135430,
      2,
      1,
      26679,
    },
    {
      538537,
      2,
      2,
      108210,
    },
    {
      458725,
      2,
      3,
      74001,
    },
    {
      132285,
      3,
      1,
      31230,
    },
    {
      538440,
      3,
      2,
      108211,
    },
    {
      236284,
      3,
      3,
      79008,
    },
    {
      236285,
      4,
      1,
      138106,
    },
    {
      132303,
      4,
      2,
      36554,
    },
    {
      538536,
      4,
      3,
      108212,
    },
    {
      236278,
      5,
      1,
      131511,
    },
    {
      538441,
      5,
      2,
      108215,
    },
    {
      460691,
      5,
      3,
      108216,
    },
    {
      135431,
      6,
      1,
      114014,
    },
    {
      236364,
      6,
      2,
      137619,
    },
    {
      236280,
      6,
      3,
      114015,
    },
  },
  ["MAGE"] = {
    {
      136031,
      1,
      1,
      12043,
    },
    {
      135788,
      1,
      2,
      108843,
    },
    {
      610877,
      1,
      3,
      108839,
    },
    {
      610472,
      2,
      1,
      115610,
    },
    {
      132847,
      2,
      2,
      140468,
    },
    {
      135988,
      2,
      3,
      11426,
    },
    {
      464484,
      3,
      1,
      113724,
    },
    {
      135850,
      3,
      2,
      111264,
    },
    {
      538562,
      3,
      3,
      102051,
    },
    {
      575584,
      4,
      1,
      110959,
    },
    {
      252268,
      4,
      2,
      86949,
    },
    {
      135865,
      4,
      3,
      11958,
    },
    {
      610471,
      5,
      1,
      114923,
    },
    {
      236220,
      5,
      2,
      44457,
    },
    {
      609814,
      5,
      3,
      112948,
    },
    {
      135730,
      6,
      1,
      114003,
    },
    {
      609815,
      6,
      2,
      116011,
    },
    {
      136153,
      6,
      3,
      1463,
    },
  },
  ["PRIEST"] = {
    {
      537022,
      1,
      1,
      108920,
    },
    {
      537021,
      1,
      2,
      108921,
    },
    {
      136206,
      1,
      3,
      605,
    },
    {
      135982,
      2,
      1,
      64129,
    },
    {
      642580,
      2,
      2,
      121536,
    },
    {
      614257,
      2,
      3,
      108942,
    },
    {
      135981,
      3,
      1,
      109186,
    },
    {
      136214,
      3,
      2,
      123040,
    },
    {
      612968,
      3,
      3,
      139139,
    },
    {
      237550,
      4,
      1,
      19236,
    },
    {
      775463,
      4,
      2,
      112833,
    },
    {
      633042,
      4,
      3,
      108945,
    },
    {
      237566,
      5,
      1,
      109142,
    },
    {
      135939,
      5,
      2,
      10060,
    },
    {
      537078,
      5,
      3,
      109175,
    },
    {
      612098,
      6,
      1,
      121135,
    },
    {
      537026,
      6,
      2,
      110744,
    },
    {
      632352,
      6,
      3,
      120517,
    },
  },
  ["WARLOCK"] = {
    {
      537516,
      1,
      1,
      108359,
    },
    {
      571320,
      1,
      2,
      108370,
    },
    {
      537517,
      1,
      3,
      108371,
    },
    {
      236302,
      2,
      1,
      47897,
    },
    {
      607853,
      2,
      2,
      6789,
    },
    {
      607865,
      2,
      3,
      30283,
    },
    {
      607854,
      3,
      1,
      108415,
    },
    {
      538538,
      3,
      2,
      108416,
    },
    {
      538039,
      3,
      3,
      110913,
    },
    {
      538040,
      4,
      1,
      111397,
    },
    {
      538043,
      4,
      2,
      111400,
    },
    {
      571321,
      4,
      3,
      108482,
    },
    {
      538442,
      5,
      1,
      108499,
    },
    {
      538444,
      5,
      2,
      108501,
    },
    {
      538443,
      5,
      3,
      108503,
    },
    {
      236402,
      6,
      1,
      108505,
    },
    {
      236418,
      6,
      2,
      137587,
    },
    {
      236423,
      6,
      3,
      108508,
    },
  },
  ["DEATHKNIGHT"] = {
    {
      538561,
      1,
      1,
      108170,
    },
    {
      132099,
      1,
      2,
      123693,
    },
    {
      136132,
      1,
      3,
      115989,
    },
    {
      136187,
      2,
      1,
      49039,
    },
    {
      237510,
      2,
      2,
      51052,
    },
    {
      134430,
      2,
      3,
      114556,
    },
    {
      237561,
      3,
      1,
      96268,
    },
    {
      135864,
      3,
      2,
      50041,
    },
    {
      538558,
      3,
      3,
      108194,
    },
    {
      136146,
      4,
      1,
      48743,
    },
    {
      538559,
      4,
      2,
      108196,
    },
    {
      538560,
      4,
      3,
      119975,
    },
    {
      237515,
      5,
      1,
      45529,
    },
    {
      134423,
      5,
      2,
      81229,
    },
    {
      252272,
      5,
      3,
      51462,
    },
    {
      538767,
      6,
      1,
      108199,
    },
    {
      538770,
      6,
      2,
      108200,
    },
    {
      538768,
      6,
      3,
      108201,
    },
  },
  ["DRUID"] = {
    {
      538517,
      1,
      1,
      131768,
    },
    {
      538514,
      1,
      2,
      102280,
    },
    {
      538771,
      1,
      3,
      102401,
    },
    {
      134157,
      2,
      1,
      145108,
    },
    {
      136059,
      2,
      2,
      108238,
    },
    {
      132137,
      2,
      3,
      102351,
    },
    {
      538516,
      3,
      1,
      106707,
    },
    {
      538515,
      3,
      2,
      102359,
    },
    {
      236170,
      3,
      3,
      132469,
    },
    {
      236160,
      4,
      1,
      114107,
    },
    {
      571586,
      4,
      2,
      106731,
    },
    {
      132129,
      4,
      3,
      106737,
    },
    {
      132121,
      5,
      1,
      99,
    },
    {
      571588,
      5,
      2,
      102793,
    },
    {
      132114,
      5,
      3,
      5211,
    },
    {
      135879,
      6,
      1,
      108288,
    },
    {
      132123,
      6,
      2,
      108373,
    },
    {
      236764,
      6,
      3,
      124974,
    },
  },
  ["MONK"] = {
    {
      607848,
      1,
      1,
      115173,
    },
    {
      651727,
      1,
      2,
      116841,
    },
    {
      574577,
      1,
      3,
      115174,
    },
    {
      606541,
      2,
      1,
      115098,
    },
    {
      613397,
      2,
      2,
      124081,
    },
    {
      135734,
      2,
      3,
      123986,
    },
    {
      629484,
      3,
      1,
      121817,
    },
    {
      629482,
      3,
      2,
      115396,
    },
    {
      629483,
      3,
      3,
      115399,
    },
    {
      839107,
      4,
      1,
      116844,
    },
    {
      615340,
      4,
      2,
      119392,
    },
    {
      642414,
      4,
      3,
      119381,
    },
    {
      608939,
      5,
      1,
      122280,
    },
    {
      620827,
      5,
      2,
      122278,
    },
    {
      775460,
      5,
      3,
      122783,
    },
    {
      606549,
      6,
      1,
      116847,
    },
    {
      620832,
      6,
      2,
      123904,
    },
    {
      607849,
      6,
      3,
      115008,
    },
  },
  ["PALADIN"] = {
    {
      571558,
      1,
      1,
      85499,
    },
    {
      571556,
      1,
      2,
      87172,
    },
    {
      589117,
      1,
      3,
      26023,
    },
    {
      135906,
      2,
      1,
      105593,
    },
    {
      135942,
      2,
      2,
      20066,
    },
    {
      571559,
      2,
      3,
      110301,
    },
    {
      236252,
      3,
      1,
      85804,
    },
    {
      135433,
      3,
      2,
      114163,
    },
    {
      236249,
      3,
      3,
      20925,
    },
    {
      135970,
      4,
      1,
      114039,
    },
    {
      135984,
      4,
      2,
      114154,
    },
    {
      589116,
      4,
      3,
      105622,
    },
    {
      571555,
      5,
      1,
      105809,
    },
    {
      236262,
      5,
      2,
      53376,
    },
    {
      135897,
      5,
      3,
      86172,
    },
    {
      613408,
      6,
      1,
      114165,
    },
    {
      613955,
      6,
      2,
      114158,
    },
    {
      613954,
      6,
      3,
      114157,
    },
  },
  ["SHAMAN"] = {
    {
      136060,
      1,
      1,
      30884,
    },
    {
      538572,
      1,
      2,
      108270,
    },
    {
      538565,
      1,
      3,
      108271,
    },
    {
      135776,
      2,
      1,
      63374,
    },
    {
      136100,
      2,
      2,
      51485,
    },
    {
      538576,
      2,
      3,
      108273,
    },
    {
      538570,
      3,
      1,
      108285,
    },
    {
      538573,
      3,
      2,
      108284,
    },
    {
      538574,
      3,
      3,
      108287,
    },
    {
      136115,
      4,
      1,
      16166,
    },
    {
      237576,
      4,
      2,
      16188,
    },
    {
      538566,
      4,
      3,
      108283,
    },
    {
      135127,
      5,
      1,
      147074,
    },
    {
      538564,
      5,
      2,
      108281,
    },
    {
      538567,
      5,
      3,
      108282,
    },
    {
      650636,
      6,
      1,
      117012,
    },
    {
      651081,
      6,
      2,
      117013,
    },
    {
      651244,
      6,
      3,
      117014,
    },
  },
}
