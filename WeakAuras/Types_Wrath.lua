if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local encounter_list = ""
function Private.InitializeEncounterAndZoneLists()
  if encounter_list ~= "" then
    return
  end
  local raids = {
    {
      L["Vault of Archavon"],
      {
        { L["Archavon the Stone Watcher"], 1126 },
        { L["Emalon the Storm Watcher"], 1127 },
        { L["Koralon the Flame Watcher"], 1128 },
        { L["Toravon the Ice Watcher"], 1129 },
      }
    },
    {
      L["Naxxramas"],
      {
        -- The Arachnid Quarter
        { L["Anub'Rekhan"], 1107 },
        { L["Grand Widow Faerlina"], 1110 },
        { L["Maexxna"], 1116 },
        -- The Plague Quarter
        { L["Noth the Plaguebringer"], 1117 },
        { L["Heigan the Unclean"], 1112 },
        { L["Loatheb"], 1115 },
        -- The Military Quarter
        { L["Instructor Razuvious"], 1113 },
        { L["Gothik the Harvester"], 1109 },
        { L["The Four Horsemen"], 1121 },
        -- The Construct Quarter
        { L["Patchwerk"], 1118 },
        { L["Grobbulus"], 1111 },
        { L["Gluth"], 1108 },
        { L["Thaddius"], 1120 },
        -- Frostwyrm Lair
        { L["Sapphiron"], 1119 },
        { L["Kel'Thuzad"], 1114 }
      }
    },
    {
      L["The Obsidian Sanctum"],
      {
        { L["Tenebron"], 1092 },
        { L["Shadron"], 1091 },
        { L["Vesperon"], 1093 },
        { L["Sartharion"], 1090 },
      }
    },
    {
      L["The Eye of Eternity"],
      {
        { L["Malygos"], 1094 },
      }
    },
    {
      L["Ulduar"],
      {
        -- The Siege of Ulduar
        { L["Flame Leviathan"], 1132 },
        { L["Ignis the Furnace Master"], 1136 },
        { L["Razorscale"], 1139 },
        { L["XT-002 Deconstructor"], 1142 },
        -- The Antechamber of Ulduar
        { L["Assembly of Iron"], 1140 },
        { L["Kologarn"], 1137 },
        { L["Auriaya"], 1131 },
        -- The Keepers of Ulduar
        { L["Freya"], 1133 },
        { L["Hodir"], 1135 },
        { L["Mimiron"], 1138 },
        { L["Thorim"], 1141 },
        -- The Descent into Madness
        { L["General Vezax"], 1134 },
        { L["Yogg-Saron"], 1143 },
        -- Celestial Planetarium
        { L["Algalon the Observer"], 1130 },
      }
    },
    {
      L["Trial of the Crusader"],
      {
        { L["Northrend Beasts"], 1088 },
        { L["Lord Jaraxxus"], 1087 },
        { L["Faction Champions"], 1086 },
        { L["Val'kyr Twins"], 1089 },
        { L["Anub'arak"], 1085 },
      }
    },
    {
      L["Onyxia's Lair"],
      {
        { L["Onyxia"], 1084 },
      }
    },
    {
      L["Icecrown Citadel"],
      {
        -- The Lower Spire
        { L["Lord Marrowgar"], 1101 },
        { L["Lady Deathwhisper"], 1100 },
        { L["Gunship Battle"], 1099 },
        { L["Deathbringer Saurfang"], 1096 },
        -- The Plagueworks
        { L["Festergut"], 1097 },
        { L["Rotface"], 1104 },
        { L["Professor Putricide"], 1102 },
        -- The Crimson Hall
        { L["Blood Prince Council"], 1095 },
        { L["Blood-Queen Lana'thel"], 1103 },
        -- The Frostwing Halls
        { L["Valithria Dreamwalker"], 1098 },
        { L["Sindragosa"], 1105 },
        -- The Frozen Throne
        { L["The Lich King"], 1106 },
      }
    },
    {
      L["The Ruby Sanctum"],
      {
        { L["Baltharus the Warborn"], 1147 },
        { L["General Zarithrian"], 1148 },
        { L["Saviana Ragefire"], 1149 },
        { L["Halion"], 1150 },
      }
    },
  }
  for _, raid in ipairs(raids) do
    encounter_list = ("%s|cffffd200%s|r\n"):format(encounter_list, raid[1])
    for _, boss in ipairs(raid[2]) do
        encounter_list = ("%s%s: %d\n"):format(encounter_list, boss[1], boss[2])
    end
    encounter_list = encounter_list .. "\n"
  end

  encounter_list = encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

function Private.get_encounters_list()
  return encounter_list
end

function Private.get_zoneId_list()
  return ""
end
