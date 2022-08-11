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
      L["Karazhan"],
      {
        { L["Attumen the Huntsman"], 652 },
        { L["Moroes"], 653 },
        { L["Maiden of Virtue"], 654 },
        { L["Opera Hall"], 655 },
        { L["The Curator"], 656 },
        { L["Terestian Illhoof"], 657 },
        { L["Shade of Aran"], 658 },
        { L["Netherspite"], 659 },
        { L["Chess Event"], 660 },
        { L["Prince Malchezaar"], 661 },
        { L["Nightbane"], 662 },
      }
    },
    {
      L["Gruul's Lair"],
      {
        { L["High King Maulgar"], 649 },
        { L["Gruul the Dragonkiller"], 650 },
      }
    },
    {
      L["Magtheridon's Lair"],
      {
        { L["Magtheridon"], 651 },
      }
    },
    {
      L["Coilfang: Serpentshrine Cavern"],
      {
        { L["Hydross the Unstable"], 623 },
        { L["The Lurker Below"], 624 },
        { L["Leotheras the Blind"], 625 },
        { L["Fathom-Lord Karathress"], 626 },
        { L["Morogrim Tidewalker"], 627 },
        { L["Lady Vashj"], 628 },
      }
    },
    {
      L["Tempest Keep"],
      {
        { L["Al'ar"], 730 },
        { L["Void Reaver"], 731 },
        { L["High Astromancer Solarian"], 732 },
        { L["Kael'thas Sunstrider"], 733 },
      }
    },
    {
      L["The Battle for Mount Hyjal"],
      {
        { L["Rage Winterchill"], 618 },
        { L["Anetheron"], 619 },
        { L["Kaz'rogal"], 620 },
        { L["Azgalor"], 621 },
        { L["Archimonde"], 622 },
      }
    },
    {
      L["Black Temple"],
      {
        { L["High Warlord Naj'entus"], 601 },
        { L["Supremus"], 602 },
        { L["Shade of Akama"], 603 },
        { L["Teron Gorefiend"], 604 },
        { L["Gurtogg Bloodboil"], 605 },
        { L["Reliquary of Souls"], 606 },
        { L["Mother Shahraz"], 607 },
        { L["The Illidari Council"], 608 },
        { L["Illidan Stormrage"], 609 },
      }
    },
    {
      L["Zul'Aman"],
      {
        { L["Akil'zon"], 1189 },
        { L["Nalorakk"], 1190 },
        { L["Jan'alai"], 1191 },
        { L["Halazzi"], 1192 },
        { L["Hex Lord Malacrass"], 1193 },
        { L["Daakara"], 1194 },
      }
    },
    {
      L["The Sunwell Plateau"],
      {
        { L["Kalecgos"], 724 },
        { L["Brutallus"], 725 },
        { L["Felmyst"], 726 },
        { L["Eredar Twins"], 727 },
        { L["M'uru"], 728 },
        { L["Kil'jaeden"], 729 },
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


function Private.get_zoneId_list()
  return ""
end