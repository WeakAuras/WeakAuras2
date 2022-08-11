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
      L["Black Wing Lair"],
      {
          { L["Razorgore the Untamed"], 610 },
          { L["Vaelastrasz the Corrupt"], 611 },
          { L["Broodlord Lashlayer"], 612 },
          { L["Firemaw"], 613 },
          { L["Ebonroc"], 614 },
          { L["Flamegor"], 615 },
          { L["Chromaggus"], 616 },
          { L["Nefarian"], 617 }
      }
    },
    {
      L["Molten Core"],
      {
        { L["Lucifron"], 663 },
        { L["Magmadar"], 664 },
        { L["Gehennas"], 665 },
        { L["Garr"], 666 },
        { L["Shazzrah"], 667 },
        { L["Baron Geddon"], 668 },
        { L["Sulfuron Harbinger"], 669 },
        { L["Golemagg the Incinerator"], 670 },
        { L["Majordomo Executus"], 671 },
        { L["Ragnaros"], 672 }
      }
    },
    {
      L["Ahn'Qiraj"],
      {
        { L["The Prophet Skeram"], 709 },
        { L["Silithid Royalty"], 710 },
        { L["Battleguard Sartura"], 711 },
        { L["Fankriss the Unyielding"], 712 },
        { L["Viscidus"], 713 },
        { L["Princess Huhuran"], 714 },
        { L["Twin Emperors"], 715 },
        { L["Ouro"], 716 },
        { L["C'thun"], 717 }
      }
    },
    {
      L["Ruins of Ahn'Qiraj"],
      {
        { L["Kurinnaxx"], 718 },
        { L["General Rajaxx"], 719 },
        { L["Moam"], 720 },
        { L["Buru the Gorger"], 721 },
        { L["Ayamiss the Hunter"], 722 },
        { L["Ossirian the Unscarred"], 723 }
      }
    },
    {
      L["Zul'Gurub"],
      {
        { L["High Priest Venoxis"], 784 },
        { L["High Priestess Jeklik"], 785 },
        { L["High Priestess Mar'li"], 786 },
        { L["Bloodlord Mandokir"], 787 },
        { L["Edge of Madness"], 788 },
        { L["High Priest Thekal"], 789 },
        { L["Gahz'ranka"], 790 },
        { L["High Priestess Arlokk"], 791 },
        { L["Jin'do the Hexxer"], 792 },
        { L["Hakkar"], 793 }
      }
    },
    {
      L["Onyxia's Lair"],
      {
        { L["Onyxia"], 1084 }
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
    }
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
