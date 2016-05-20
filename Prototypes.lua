-- Lua APIs
local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local fmt, tostring, string_char = string.format, tostring, string.char
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local SpellRange = LibStub("SpellRange-1.0")
function WeakAuras.IsSpellInRange(spellId, unit)
  return SpellRange.IsSpellInRange(spellId, unit);
end

-- GLOBALS: SPELL_POWER_CHI SPELL_POWER_ECLIPSE SPELL_POWER_SHADOW_ORBS SPELL_POWER_DEMONIC_FURY SPELL_POWER_BURNING_EMBERS

WeakAuras.function_strings = {
  count = [[
    return function(count)
      if(count %s %s) then
        return true
      else
        return false
      end
    end
  ]],
  count_fraction = [[
    return function(count, max)
      local fraction = count/max
      if(fraction %s %s) then
        return true
      else
        return false
      end
    end
  ]],
  always = [[
    return function()
      return true
    end
  ]]
};

WeakAuras.anim_function_strings = {
  straight = [[
    return function(progress, start, delta)
      return start + (progress * delta)
    end
  ]],
  straightTranslate = [[
    return function(progress, startX, startY, deltaX, deltaY)
      return startX + (progress * deltaX), startY + (progress * deltaY)
    end
  ]],
  straightScale = [[
    return function(progress, startX, startY, scaleX, scaleY)
      return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))
    end
  ]],
  straightColor = [[
    return function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      return r1 + (progress * (r2 - r1)), g1 + (progress * (g2 - g1)), b1 + (progress * (b2 - b1)), a1 + (progress * (a2 - a1))
    end
  ]],
  circle = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (deltaX * math.cos(angle)), startY + (deltaY * math.sin(angle))
    end
  ]],
  circle2 = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (deltaX * math.sin(angle)), startY + (deltaY * math.cos(angle))
    end
  ]],
  spiral = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (progress * deltaX * math.cos(angle)), startY + (progress * deltaY * math.sin(angle))
    end
  ]],
  spiralandpulse = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local angle = (progress + 0.25) * 2 * math.pi
      return startX + (math.cos(angle) * deltaX * math.cos(angle*2)), startY + (math.abs(math.cos(angle)) * deltaY * math.sin(angle*2))
    end
  ]],
  shake = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local prog
      if(progress < 0.25) then
        prog = progress * 4
      elseif(progress < .75) then
        prog = 2 - (progress * 4)
      else
        prog = (progress - 1) * 4
      end
      return startX + (prog * deltaX), startY + (prog * deltaY)
    end
  ]],
  bounceDecay = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local prog = (progress * 3.5) % 1
      local bounce = math.ceil(progress * 3.5)
      local bounceDistance = math.sin(prog * math.pi) * (bounce / 4)
    return startX + (bounceDistance * deltaX), startY + (bounceDistance * deltaY)
  end
  ]],
  bounce = [[
    return function(progress, startX, startY, deltaX, deltaY)
      local bounceDistance = math.sin(progress * math.pi)
      return startX + (bounceDistance * deltaX), startY + (bounceDistance * deltaY)
    end
  ]],
  flash = [[
    return function(progress, start, delta)
      local prog
      if(progress < 0.5) then
        prog = progress * 2
      else
        prog = (progress - 1) * 2
      end
      return start + (prog * delta)
    end
  ]],
  pulse = [[
    return function(progress, startX, startY, scaleX, scaleY)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      return startX + (((math.sin(angle) + 1)/2) * (scaleX - 1)), startY + (((math.sin(angle) + 1)/2) * (scaleY - 1))
    end
  ]],
  alphaPulse = [[
    return function(progress, start, delta)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      return start + (((math.sin(angle) + 1)/2) * delta)
    end
  ]],
  pulseColor = [[
    return function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      local newProgress = ((math.sin(angle) + 1)/2);
      return r1 + (newProgress * (r2 - r1)),
           g1 + (newProgress * (g2 - g1)),
           b1 + (newProgress * (b2 - b1)),
           a1 + (newProgress * (a2 - a1))
    end
  ]],
  fauxspin = [[
    return function(progress, startX, startY, scaleX, scaleY)
      local angle = progress * 2 * math.pi
      return math.cos(angle) * scaleX, startY + (progress * (scaleY - startY))
    end
  ]],
  fauxflip = [[
    return function(progress, startX, startY, scaleX, scaleY)
      local angle = progress * 2 * math.pi
      return startX + (progress * (scaleX - startX)), math.cos(angle) * scaleY
    end
  ]],
  backandforth = [[
    return function(progress, start, delta)
    local prog
    if(progress < 0.25) then
      prog = progress * 4
      elseif(progress < .75) then
      prog = 2 - (progress * 4)
    else
      prog = (progress - 1) * 4
    end
    return start + (prog * delta)
    end
  ]],
  wobble = [[
    return function(progress, start, delta)
    local angle = progress * 2 * math.pi
    return start + math.sin(angle) * delta
    end
  ]],
  hide = [[
    return function()
    return 0
    end
  ]]
};

WeakAuras.anim_presets = {
  -- Start and Finish
  slidetop = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 0, y = 50,
    use_alpha = true,
    alpha = 0
  },
  slideleft = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = -50,
    y = 0,
    use_alpha = true,
    alpha = 0
  },
  slideright = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 50,
    y = 0,
    use_alpha = true,
    alpha = 0
  },
  slidebottom = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 0,
    y = -50,
    use_alpha = true,
    alpha = 0
  },
  fade = {
    type = "custom",
    duration = 0.25,
    use_alpha = true,
    alpha = 0
  },
  grow = {
    type = "custom",
    duration = 0.25,
    use_scale = true,
    scalex = 2,
    scaley = 2,
    use_alpha = true,
    alpha = 0
  },
  shrink = {
    type = "custom",
    duration = 0.25,
    use_scale = true,
    scalex = 0,
    scaley = 0,
    use_alpha = true,
    alpha = 0
  },
  spiral = {
    type = "custom",
    duration = 0.5,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "spiral",
    use_alpha = true,
    alpha = 0
  },
  bounceDecay = {
    type = "custom",
    duration = 1.5,
    use_translate = true,
    x = 50,
    y = 50,
    translateType = "bounceDecay",
    use_alpha = true,
    alpha = 0
  },

  -- Main
  shake = {
    type = "custom",
    duration = 0.5,
    use_translate = true,
    x = 10,
    y = 0,
    translateType = "circle2"
  },
  spin = {
    type = "custom",
    duration = 1,
    use_scale = true,
    scalex = 1,
    scaley = 1,
    scaleType = "fauxspin"
  },
  flip = {
    type = "custom",
    duration = 1,
    use_scale = true,
    scalex = 1,
    scaley = 1,
    scaleType = "fauxflip"
  },
  wobble = {
    type = "custom",
    duration = 0.5,
    use_rotate = true,
    rotate = 3,
    rotateType = "wobble"
  },
  pulse = {
    type = "custom",
    duration = 0.75,
    use_scale = true,
    scalex = 1.05,
    scaley = 1.05,
    scaleType = "pulse"
  },
  alphaPulse = {
    type = "custom",
    duration = 0.5,
    use_alpha = true,
    alpha = 0.5,
    alphaType = "alphaPulse"
  },
  rotateClockwise = {
    type = "custom",
    duration = 4,
    use_rotate = true,
    rotate = -360
  },
  rotateCounterClockwise = {
    type = "custom",
    duration = 4,
    use_rotate = true,
    rotate = 360
  },
  spiralandpulse = {
    type = "custom",
    duration = 6,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "spiralandpulse"
  },
  circle = {
    type = "custom",
    duration = 4,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "circle"
  },
  orbit = {
    type = "custom",
    duration = 4,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "circle",
    use_rotate = true,
    rotate = 360
  },
  bounce = {
    type = "custom",
    duration = 0.6,
    use_translate = true,
    x = 0,
    y = 25,
    translateType = "bounce"
  }
};

WeakAuras.class_ids = {}
local classID = 1;
local _, classFileName;
while(GetClassInfo(classID)) do
  _, classFileName = GetClassInfo(classID)
  WeakAuras.class_ids[classFileName] = classID;
  classID = classID + 1;
end

function WeakAuras.CheckTalentByIndex(index)
  local tier = ceil(index / 3)
  local column = (index - 1) % 3 + 1
  local spec = GetActiveSpecGroup()
  local _, _, _, selected = GetTalentInfo(tier, column, spec)
  return selected
end

function WeakAuras.CheckGlyph(glyph)
  if (glyph) then
    glyph = tonumber(glyph);
    if (glyph) then
      for i = 1, GetNumGlyphSockets() do
        if (select(4, GetGlyphSocketInfo(i)) == glyph) then
          return true;
        end
      end
    end
  end
  return false;
end

function WeakAuras.CheckNumericIds(loadids, currentId)
  local searchFrom = 0;

  local startI, endI = string.find(loadids, currentId, searchFrom);
  while (startI) do
    searchFrom = endI + 1; -- start next search from end
    if (startI == 1 or tonumber(string.sub(loadids, startI - 1, startI - 1)) == nil) then
      -- Either right at start, or character before is not a number
      if (endI == string.len(loadids) or tonumber(string.sub(loadids, endI + 1, endI + 1)) == nil) then
        return true;
      end
    end
    startI, endI = string.find(loadids, currentId, searchFrom);
  end
  return false;
end

WeakAuras.load_prototype = {
  args = {
    {
      name = "combat",
      display = L["In Combat"],
      type = "tristate",
      width = "normal",
      init = "arg"
    },
    {
      name = "never",
      display = L["Never"],
      type = "toggle",
      width = "normal",
      init = "false"
    },
    {
      name = "petbattle",
      display = L["In Pet Battle"],
      type = "tristate",
      init = "arg"
    },
    {
      name = "vehicle",
      display = L["In Vehicle"],
      type = "tristate",
      init = "arg",
      width = "normal",
    },
    {
      name = "vehicleUi",
      display = L["Has Vehicle UI"],
      type = "tristate",
      init = "arg",
      width = "normal",
    },
    {
      name = "name",
      display = L["Player Name"],
      type = "string",
      init = "arg"
    },
    {
      name = "realm",
      display = L["Realm"],
      type = "string",
      init = "arg"
    },
    {
      name = "class",
      display = L["Player Class"],
      type = "multiselect",
      values = "class_types",
      init = "arg"
    },
    {
      name = "spec",
      display = L["Talent Specialization"],
      type = "multiselect",
      values = function(trigger)
        return function()
          local _, class = UnitClass("player")
          local single_class;
          local min_specs = 4;
          -- First check to use if the class load is on multi-select with only one class selected
          -- Also check the number of specs for each class selected in the multi-select and keep track of the minimum
          -- (i.e., 3 unless Druid is the only thing selected, but this method is flexible in case another spec gets added to another class)
          if(trigger.use_class == false and trigger.class and trigger.class.multi) then
            local num_classes = 0;
            for class in pairs(trigger.class.multi) do
              single_class = class;
              -- If any checked class has only 3 specs, min_specs will become 3
              min_specs = min(min_specs, GetNumSpecializationsForClassID(WeakAuras.class_ids[class]))
              num_classes = num_classes + 1;
            end
            if(num_classes ~= 1) then
              single_class = nil;
            end
          end
          -- If that is not the case, see if it is on single-select
          if((not single_class) and trigger.use_class and trigger.class and trigger.class.single) then
            single_class = trigger.class.single
          end
          -- If a single specific class was found, load the specific list for it
          if(single_class == class) then
            return WeakAuras.spec_types_specific[single_class];
          else
            -- List 4 specs if no class is specified, but if any multi-selected classes have less than 4 specs, list 3 instead
            if(min_specs < 4) then
              return WeakAuras.spec_types_reduced;
            else
              return WeakAuras.spec_types;
            end
          end
        end
      end,
      init = "arg"
    },
    {
      name = "talent",
      display = L["Talent selected"],
      type = "multiselect",
      values = function(trigger)
        return function()
          local single_class;
          -- First check to use if the class load is on multi-select with only one class selected
          if(trigger.use_class == false and trigger.class and trigger.class.multi) then
            local num_classes = 0;
            for class in pairs(trigger.class.multi) do
              single_class = class;
              num_classes = num_classes + 1;
            end
            if(num_classes ~= 1) then
              single_class = nil;
            end
          end
          -- If that is not the case, see if it is on single-select
          if((not single_class) and trigger.use_class and trigger.class and trigger.class.single) then
            single_class = trigger.class.single
          end
          -- If a single specific class was found, load the specific list for it
          if(single_class and WeakAuras.talent_types_specific[single_class]) then
              return WeakAuras.talent_types_specific[single_class];
          else
            return WeakAuras.talent_types;
          end
        end
      end,
      test = "WeakAuras.CheckTalentByIndex(%d)"
    },
    {
        name = "glyph",
        display = L["Glyph"],
        type = "string",
        test = "WeakAuras.CheckGlyph(%d)",
        desc = function()
          local desc = L["Enter a glpyh ID\n"];
          for i = 1,  NUM_GLYPH_SLOTS do
            local _, _, _, glyphSpell = GetGlyphSocketInfo(i);
            if (glyphSpell) then
              local name = GetSpellInfo(glyphSpell);
              desc = desc .. L["%s: %s\n"]:format(name, glyphSpell);
            end
          end
          return desc;
        end
    },
    {
      name = "race",
      display = L["Player Race"],
      type = "multiselect",
      values = "race_types",
      init = "arg"
    },
    {
      name = "faction",
      display = L["Player Faction"],
      type = "multiselect",
      values = "faction_group",
      init = "arg"
    },
    {
      name = "level",
      display = L["Player Level"],
      type = "number",
      init = "arg"
    },
    {
      name = "zone",
      display = L["Zone"],
      type = "string",
      init = "arg"
    },
    {
      name = "zoneId",
      display = L["Zone ID"],
      type = "string",
      init = "arg",
      desc = L["Zone ID List"],
      test = "WeakAuras.CheckNumericIds('%s', zoneId)"
    },
    {
      name = "encounterid",
      display = L["Encounter ID"],
      type = "string",
      init = "arg",
      desc = L["EncounterID List"],
      test = "WeakAuras.CheckNumericIds('%s', encounterid)"
    },
    {
      name = "size",
      display = L["Instance Type"],
      type = "multiselect",
      values = "group_types",
      init = "arg"
    },
    {
      name = "difficulty",
      display = L["Dungeon Difficulty"],
      type = "multiselect",
      values = "difficulty_types",
      init = "arg"
    },
    {
      name = "role",
      display = L["Player Dungeon Role"],
      type = "multiselect",
      values = "role_types",
      init = "arg"
    },
  }
};

WeakAuras.event_prototypes = {
  ["Combo Points"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED",
      "UNIT_COMBO_POINTS"
    },
    force_events = true,
    name = L["Combo Points"],
    args = {
      {
        name = "combopoints",
        display = L["Combo Points"],
        type = "number",
        init = "UnitInVehicle('player') and UnitHasVehicleUI('player') and GetComboPoints('vehicle', 'target') or UnitPower('player', 4)"
      }
    },
    durationFunc = function(trigger)
      if UnitInVehicle('player') then
        return GetComboPoints('vehicle', 'target'), 5, true;
      else
        return UnitPower('player', 4), 5, true;
      end
    end,
    stacksFunc = function(trigger)
      if UnitInVehicle('player') then
        return GetComboPoints('vehicle', 'target');
      else
        return UnitPower('player', 4);
      end
    end,
    automatic = true
  },
  ["Unit Characteristics"] = {
    type = "status",
    events = {
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED",
      "UNIT_LEVEL",
      "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
    },
    force_events = true,
    name = L["Unit Characteristics"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [[
        local unit = '%s';
        local concernedUnit = '%s';
      ]];

    return ret:format(trigger.unit, trigger.unit);
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific"
      },
      {
        name = "name",
        display = L["Name"],
        type = "string",
        init = "UnitName(concernedUnit)"
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types"
      },
      {
        name = "hostility",
        display = L["Hostility"],
        type = "select",
        init = "UnitIsEnemy('player', concernedUnit) and 'hostile' or 'friendly'",
        values = "hostility_types"
      },
      {
        name = "character",
        display = L["Character Type"],
        type = "select",
        init = "UnitIsPlayer(concernedUnit) and 'player' or 'npc'",
        values = "character_types"
      },
      {
        name = "level",
        display = L["Level"],
        type = "number",
        init = "UnitLevel(concernedUnit)"
      },
      {
        name = "attackable",
        display = L["Attackable"],
        type = "tristate",
        init = "UnitCanAttack('player', concernedUnit)",
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    automatic = true
  },
  ["Health"] = {
    type = "status",
    events = {
      "UNIT_HEALTH_FREQUENT",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED",
      "WA_UNIT_PET",
      "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = {
      "player",
      "target",
      "focus",
      "pet"
    },
    name = L["Health"],
    init = function(trigger)
    trigger.unit = trigger.unit or "player";
      local ret = [[
        local unit = unit or '%s';
        local concernedUnit = '%s';
        if (unit == "pet") then
          WeakAuras.WatchForUnitPet();
        end
      ]];

    return ret:format(trigger.unit, trigger.unit);
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific"
      },
      {
        name = "health",
        display = L["Health"],
        type = "number",
        init = "UnitHealth(unit)"
      },
      {
        name = "percenthealth",
        display = L["Health (%)"],
        type = "number",
        init = "(UnitHealth(unit) / math.max(1, UnitHealthMax(unit))) * 100"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    durationFunc = function(trigger)
      return UnitHealth(trigger.unit), UnitHealthMax(trigger.unit), true;
    end,
    nameFunc = function(trigger)
      return UnitName(trigger.unit);
    end,
    automatic = true
  },
  ["Power"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED",
      "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
      "WA_DELAYED_PLAYER_ENTERING_WORLD",
      "UNIT_DISPLAYPOWER"
    },
    force_events = {
      "player",
      "target",
      "focus",
      "pet"
    },
    name = L["Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [[
        local unit = unit or '%s';
        local concernedUnit = '%s';
      ]];

    return ret:format(trigger.unit, trigger.unit);
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific"
      },
      {
        name = "powertype",
        -- required = true,
        display = L["Power Type"],
        type = "select",
        values = "power_types",
        init = "UnitPowerType(unit)"
      },
      {
        name = "power",
        display = L["Power"],
        type = "number",
        init = "UnitPower(unit)"
      },
      {
        name = "percentpower",
        display = L["Power (%)"],
        type = "number",
        init = "(UnitPower(unit) / math.max(1, UnitPowerMax(unit))) * 100;"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), math.max(1, UnitPowerMax(trigger.unit)), "fastUpdate";
    end,
    automatic = true
  },
  ["Holy Power"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Holy Power"],
    args = {
      {
        name = "power",
        display = L["Holy Power"],
        type = "number",
        init = "UnitPower('player', 9)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', 9), UnitPowerMax('player', 9), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', 9);
    end,
    automatic = true
  },
  ["Demonic Fury"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Demonic Fury"],
    args = {
      {
        name = "power",
        display = L["Demonic Fury"],
        type = "number",
        init = "UnitPower('player', SPELL_POWER_DEMONIC_FURY)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_DEMONIC_FURY), math.max(1, UnitPowerMax('player', SPELL_POWER_DEMONIC_FURY)), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_DEMONIC_FURY);
    end,
    automatic = true
  },
  ["Burning Embers"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Burning Embers"],
    args = {
      {
        name = "ember",
        display = L["Burning Embers"],
        type = "number",
        init = "UnitPower('player', SPELL_POWER_BURNING_EMBERS, true)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_BURNING_EMBERS, true), math.max(1, UnitPowerMax('player', SPELL_POWER_BURNING_EMBERS, true)), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_BURNING_EMBERS, true);
    end,
    automatic = true
  },
  ["Shadow Orbs"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Shadow Orbs"],
    args = {
      {
        name = "power",
        display = L["Shadow Orbs"],
        type = "number",
        init = "UnitPower('player', SPELL_POWER_SHADOW_ORBS)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_SHADOW_ORBS), math.max(1, UnitPowerMax('player', SPELL_POWER_SHADOW_ORBS)), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_SHADOW_ORBS);
    end,
    automatic = true
  },
  ["Chi Power"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Chi Power"],
    args = {
      {
        name = "power",
        display = L["Chi Power"],
        type = "number",
        init = "UnitPower('player', SPELL_POWER_CHI)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_CHI), math.max(1, UnitPowerMax('player', SPELL_POWER_CHI)), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', SPELL_POWER_CHI);
    end,
    automatic = true
  },
  ["Alternate Power"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus",
      "pet"
    },
    name = L["Alternate Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [[
        local unit = unit or '%s'
        local concernedUnit = '%s'
        local _, _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo('%s');
      ]]
      return ret:format(trigger.unit, trigger.unit, trigger.unit);
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific"
      },
      {
        name = "power",
        display = L["Alternate Power"],
        type = "number",
        init = "UnitPower(unit, 10)"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit) and name"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit, 10), math.max(1, UnitPowerMax(trigger.unit, 10)), "fastUpdate";
    end,
    nameFunc = function(trigger)
      local _, _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo(trigger.unit);
      return name;
    end,
    iconFunc = function(trigger)
      local icon = UnitAlternatePowerTextureInfo(trigger.unit, 0);
      return icon;
    end,
    automatic = true
  },
  ["Shards"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Shards"],
    args = {
      {
        name = "power",
        display = L["Shards"],
        type = "number",
        init = "UnitPower('player', 7)"
      },
    },
    durationFunc = function(trigger)
      return UnitPower('player', 7), math.max(1, UnitPowerMax('player', 7)), true;
    end,
    stacksFunc = function(trigger)
      return UnitPower('player', 7);
    end,
    automatic = true
  },
  ["Eclipse Power"] = {
    type = "status",
    events = {
      "UNIT_POWER_FREQUENT",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = {
      "player",
      "target",
      "focus",
      "pet"
    },
    name = L["Eclipse Power"],
    init = function(trigger)
      local ret = [[
        local unit = 'player';
        local GetRealEclipseDirection = UnitPower(unit, SPELL_POWER_ECLIPSE) > 0 and "sun" or UnitPower(unit, SPELL_POWER_ECLIPSE) < 0 and "moon" or GetEclipseDirection();
      ]];

    return ret;
    end,
    args = {
      {
        name = "eclipsetype",
        -- required = true,
        display = L["Eclipse Type"],
        type = "select",
        values = "eclipse_types",
        init = "GetRealEclipseDirection"
      },
      {
        name = "lunar_power",
        display = L["Lunar Power"],
        type = "number",
        init = "math.min(UnitPower('player', SPELL_POWER_ECLIPSE), -0) * -1",
        enable = function(trigger)
          return trigger.eclipsetype == "moon"
        end
      },
      {
        name = "solar_power",
        display = L["Solar Power"],
        type = "number",
        init = "math.max(UnitPower('player', SPELL_POWER_ECLIPSE), 0)",
        enable = function(trigger)
          return trigger.eclipsetype == "sun"
        end
      },
      {
        name = "absolutValues",
        display = L["Absolute values"],
        type = "toggle",
        init = "arg",
        enable = function(trigger)
          return not trigger.eclipsetype
        end
      }
    },
    durationFunc = function(trigger)
    local GetRealEclipseDirection = UnitPower('player', SPELL_POWER_ECLIPSE) > 0 and "sun" or UnitPower('player', SPELL_POWER_ECLIPSE) < 0 and "moon" or GetEclipseDirection();

    if(trigger.use_absolutValues) then
      return math.max(UnitPower('player', SPELL_POWER_ECLIPSE) + UnitPowerMax('player', SPELL_POWER_ECLIPSE), 0), math.max(UnitPowerMax('player', SPELL_POWER_ECLIPSE) * 2, 1), true;
    elseif(not trigger.use_eclipsetype or trigger.eclipsetype == GetRealEclipseDirection) then
      return math.max(math.abs(UnitPower('player', SPELL_POWER_ECLIPSE)), 0), math.max(math.abs(UnitPowerMax('player', SPELL_POWER_ECLIPSE)), 1), true;
    else
      return 0, 0, true;
    end
    end,
    nameFunc = function(trigger)
      return WeakAuras.eclipse_types[UnitPower('player', SPELL_POWER_ECLIPSE) > 0 and "sun" or UnitPower('player', SPELL_POWER_ECLIPSE) < 0 and "moon" or GetEclipseDirection()];
    end,
    iconFunc = function(trigger)
      local eclipseIcons = {
        ["moon"] = "Interface\\Icons\\ability_druid_eclipse",
        ["sun"] = "Interface\\Icons\\ability_druid_eclipseorange"
      };
      return eclipseIcons[UnitPower('player', SPELL_POWER_ECLIPSE) > 0 and "sun" or UnitPower('player', SPELL_POWER_ECLIPSE) < 0 and "moon" or GetEclipseDirection()];
    end,
    automatic = true
  },
  ["Eclipse Direction"] = {
    type = "status",
    events = {
      "UNIT_POWER",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Eclipse Direction"],
    args = {
      {
        name = "eclipse_direction",
        -- required = true,
        display = L["Eclipse Direction"],
        type = "select",
        values = "eclipse_types",
        init = "GetEclipseDirection()"
      }
    },
    nameFunc = function(trigger)
      return WeakAuras.eclipse_types[GetEclipseDirection()];
    end,
    iconFunc = function(trigger)
      local eclipseIcons = {
        ["moon"] = "Interface\\Icons\\ability_druid_eclipse",
        ["sun"] = "Interface\\Icons\\ability_druid_eclipseorange"
      };
      return eclipseIcons[GetEclipseDirection()];
    end,
    automatic = true
  },
  -- Todo: Give useful options to condition based on GUID and flag info
  -- Todo: Allow options to pass information from combat message to the display?
  ["Combat Log"] = {
    type = "event",
    events = {
      "COMBAT_LOG_EVENT_UNFILTERED"
    },
    name = L["Combat Log"],
    args = {
      {}, -- timestamp ignored with _ argument
      {}, -- messageType ignored with _ argument (it is checked before the dynamic function)
      {}, -- sourceGUID ignored with _ argument
      {}, -- hideCaster ignored with _ argument
      {
        name = "sourceunit",
        display = L["Source Unit"],
        type = "unit",
        test = "source and UnitIsUnit(source, '%s')",
        values = "actual_unit_types_with_specific",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "ENVIRONMENTAL")
        end
      },
      {
        name = "source",
        display = L["Source Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "ENVIRONMENTAL")
        end
      },
      {}, -- sourceFlags ignored with _ argument
      {}, -- sourceRaidFlags ignored with _ argument
      {
        name = "destGUID",
        init = "arg",
        hidden = "true",
        test = "true"
      },
      {
        name = "destunit",
        display = L["Destination Unit"],
        type = "unit",
        test = "(destGUID or '') == (UnitGUID('%s') or '') and destGUID",
        values = "actual_unit_types_with_specific",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end
      },
      {
        name = "dest",
        display = L["Destination Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end
      },
      {
        enable = function(trigger)
          return (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end
      },
      {}, -- destFlags ignored with _ argument
      {}, -- destRaidFlags ignored with _ argument
      {
        name = "spellId",
        display = L["Spell Id"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      },
      {
        name = "spellName",
        display = L["Spell Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      },
      {
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      }, -- spellSchool ignored with _ argument
      {
        name = "environmentalType",
        display = L["Environment Type"],
        type = "select",
        values = "environmental_types",
        enable = function(trigger)
          return trigger.subeventPrefix == "ENVIRONMENTAL"
        end
      },
      {
        name = "missType",
        display = L["Miss Type"],
        type = "select",
        init = "arg",
        values = "miss_types",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_MISSED" or trigger.subeventPrefix == "DAMAGE_SHIELD_MISSED")
        end
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      }, -- extraSpellId ignored with _ argument
      {
        name = "extraSpellName",
        display = L["Extra Spell Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      }, -- extraSchool ignored with _ argument
      {
        name = "auraType",
        display = L["Aura Type"],
        type = "select",
        init = "arg",
        values = "aura_types",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix:find("AURA") or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_STOLEN")
        end
      },
      {
        name = "amount",
        display = L["Amount"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventSuffix == "_MISSED" or trigger.subeventSuffix == "_HEAL" or trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH" or trigger.subeventPrefix:find("DAMAGE"))
        end
      },
      {
        name = "overkill",
        display = L["Overkill"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "overhealing",
        display = L["Overhealing"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventSuffix == "_HEAL"
        end
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      }, -- damage school ignored with _ argument
      {
        name = "resisted",
        display = L["Resisted"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "blocked",
        display = L["Blocked"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "absorbed",
        display = L["Absorbed"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
        end
      },
      {
        name = "critical",
        display = L["Critical"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
        end
      },
      {
        name = "glancing",
        display = L["Glancing"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "crushing",
        display = L["Crushing"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "isOffHand",
        display = L["Is Off Hand"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      },
      {
        name = "multistrike",
        display = L["Multistrike"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
        end
      },
      {
        name = "number",
        display = L["Number"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_EXTRA_ATTACKS" or trigger.subeventSuffix:find("DOSE"))
        end
      },
      {
        name = "powerType",
        display = L["Power Type"],
        type = "select", init = "arg",
        values = "power_types",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH")
        end
      },
      {
        name = "extraAmount",
        display = L["Extra Amount"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH")
        end
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix == "_CAST_FAILED"
        end
      } -- failedType ignored with _ argument - theoretically this is not necessary because it is the last argument in the event, but it is added here for completeness
    }
  },
  ["Cooldown Progress (Spell)"] = {
    type = "status",
    events = {
      "SPELL_COOLDOWN_READY",
      "SPELL_COOLDOWN_CHANGED",
      "SPELL_COOLDOWN_STARTED",
      "COOLDOWN_REMAINING_CHECK",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "SPELL_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Spell)"],
    init = function(trigger)
      --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
      trigger.spellName = trigger.spellName or 0;
      local spellName = (type(trigger.spellName) == "number" and trigger.spellName or "'"..trigger.spellName.."'");
      WeakAuras.WatchSpellCooldown(trigger.spellName, trigger.use_matchedRune);
      local ret = [[
        local spellname = %s
        local ignoreRuneCD = %s
        local startTime, duration = WeakAuras.GetSpellCooldown(spellname, ignoreRuneCD);
        local charges = WeakAuras.GetSpellCharges(spellname);
        if (charges == nil) then
            charges = (duration == 0) and 1 or 0;
        end
        local showOn = %s
      ]];
      if(trigger.use_remaining and trigger.showOn == "showOnCooldown") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime - GetTime();
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining) or 0);
      end
      return ret:format(spellName, (trigger.use_matchedRune and "true" or "false"),
                                   "\"" .. (trigger.showOn or "") .. "\"");
    end,
    args = {
      {
      }, -- Ignore first argument (id)
      {
        name = "matchedRune",
        display = L["Ignore Rune CD"],
        type = "toggle",
        test = "true"
      },
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.showOn == "showOnCooldown") end
      },
      {
        name = "charges",
        display = L["Charges"],
        type = "number"
      },
      {
        name = "showOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        required = true,
      },
      {
        hidden = true,
        test = "(showOn == \"showOnReady\" and startTime == 0) " ..
               "or (showOn == \"showOnCooldown\" and startTime > 0) " ..
               "or (showOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = WeakAuras.GetSpellCooldown(trigger.spellName or 0, trigger.use_matchedRune);
      startTime = startTime or 0;
      duration = duration or 0;
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.spellName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    stacksFunc = function(trigger)
      return WeakAuras.GetSpellCharges(trigger.spellName);
    end,
    hasSpellID = true,
    automaticrequired = true
  },
  ["Cooldown Ready (Spell)"] = {
    type = "event",
    events = {
      "SPELL_COOLDOWN_READY",
    },
    name = L["Cooldown Ready (Spell)"],
    init = function(trigger)
    --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
    trigger.spellName = trigger.spellName or 0;
      WeakAuras.WatchSpellCooldown(trigger.spellName or 0);
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        init = "arg"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.spellName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    hasSpellID = true
  },
  ["Cooldown Progress (Item)"] = {
    type = "status",
    events = {
      "ITEM_COOLDOWN_READY",
      "ITEM_COOLDOWN_CHANGED",
      "ITEM_COOLDOWN_STARTED",
      "COOLDOWN_REMAINING_CHECK"
    },
    force_events = "ITEM_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Item)"],
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "'"..trigger.itemName.."'";
      WeakAuras.WatchItemCooldown(trigger.itemName);
      local ret = [[
        local startTime, duration = WeakAuras.GetItemCooldown(%s);
        local showOn = %s
      ]];
      if(trigger.use_remaining and trigger.showOn == "showOnCooldown") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime - GetTime();
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining) or 0);
      end
      return ret:format(itemName,  "\"" .. (trigger.showOn or "") .. "\"");
    end,
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.showOn == "showOnCooldown") end,
        init = "remaining"
      },
      {
        name = "showOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        required = true,
      },
      {
        hidden = true,
        test = "(showOn == \"showOnReady\" and startTime == 0) " ..
               "or (showOn == \"showOnCooldown\" and startTime > 0) " ..
               "or (showOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = WeakAuras.GetItemCooldown(type(trigger.itemName) == "number" and trigger.itemName or 0);
      startTime = startTime or 0;
      duration = duration or 0;
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      local name = GetItemInfo(trigger.itemName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(trigger.itemName or 0);
      return icon;
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Cooldown Ready (Item)"] = {
    type = "event",
    events = {
      "ITEM_COOLDOWN_READY"
    },
    name = L["Cooldown Ready (Item)"],
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      WeakAuras.WatchItemCooldown(trigger.itemName);
    end,
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        init = "arg"
      }
    },
    nameFunc = function(trigger)
      local name = GetItemInfo(trigger.itemName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(trigger.itemName or 0);
      return icon;
    end,
    hasItemID = true
  },
  ["GTFO"] = {
    type = "event",
    events = {
      "GTFO_DISPLAY"
    },
    name = L["GTFO Alert"],
    args = {
      {
        name = "alertType",
        display = "Alert Type",
        type = "select",
        init = "arg",
        values = "gtfo_types"
      },
    },
  },
  -- DBM events
  ["DBM Announce"] = {
    type = "event",
    events = {
      "DBM_Announce"
    },
    name = L["DBM Announce"],
    init = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_Announce");
      return "";
    end,
    args = {
      {
        name = "message",
        init = "arg",
        display = L["Message"],
        type = "longstring"
      }
    }
  },
  ["DBM Timer"] = {
    type = "status",
    events = {
      "DBM_TimerUpdate"
    },
    force_events = "DBM_TimerUpdate",
    name = L["DBM Timer"],
    init = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_TimerStart");
      WeakAuras.RegisterDBMCallback("DBM_TimerStop");
      WeakAuras.RegisterDBMCallback("wipe");
      WeakAuras.RegisterDBMCallback("kill");

      local ret = "";

      if (trigger.use_id) then
        ret = "local triggerId = \"" .. (trigger.id or "") .. "\"\n";
      else
        ret = "local triggerId = nil\n";
      end

      local test;
      if (trigger.use_message) then
        local ret2 = [[
          local triggerMessage = "%s"
          local triggerOperator = "%s"
        ]]
        ret = ret .. ret2:format(trigger.message or "", trigger.message_operator  or "")
      else
        ret = ret .. [[
          local triggerMessage = nil;
          local triggerOperator = nil;
        ]]
        test = "true";
      end

      if (trigger.use_spellId and trigger.spellId) then
        local ret2 = [[
          local triggerSpellId = "%s";
        ]];
        ret = ret .. ret2:format(trigger.spellId or "");
      else
        ret = ret .. [[
          local triggerSpellId = nil;
        ]];
      end

      ret = ret .. [[
        local duration, expirationTime = WeakAuras.GetDBMTimer(triggerId, triggerMessage, triggerOperator, triggerSpellId);
      ]]

      if (trigger.use_remaining) then
        local ret2 = [[
          local remainingCheck = %s;
          local remaining = expirationTime - GetTime();
          if (remaining >= remainingCheck) then
            WeakAuras.ScheduleDbmCheck(expirationTime - remainingCheck);
          end
        ]]
        ret = ret .. ret2:format(tonumber(trigger.remaining) or 0);
      end
      --print (ret);
      return ret;
    end,
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetDBMTimer(
          trigger.use_id and trigger.id,
          trigger.use_message and trigger.message,
          trigger.use_message and trigger.message_operator,
          trigger.use_spellId and trigger.spellId);
      return duration, expirationTime;
    end,

    iconFunc = function(trigger)
      local _, _, icon = WeakAuras.GetDBMTimer(
          trigger.use_id and trigger.id,
          trigger.use_message and trigger.message,
          trigger.use_message and trigger.message_operator,
          trigger.use_spellId and trigger.spellId);
      return icon;
    end,
    args = {
      {
        name = "id", -- TODO Is there ever anything useful in ID?
        display = L["Id"],
        type = "string",
        test = "true"
      },
      {
        name = "message",
        display = L["Message"],
        type = "longstring",
        test = "true"
      },
      {
        name = "spellId",
        display = L["Spell/Encounter Id"],
        type = "string",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        init = "remaining"
      },
      {
        hidden = true,
        test = "duration > 0"
      }
    },
    automaticrequired = true
  },
  -- BigWigs
  ["BigWigs Message"] = {
    type = "event",
    events = {
      "BigWigs_Message"
    },
    name = L["BigWigs Message"],
    init = function(trigger)
      WeakAuras.RegisterBigWigsCallback("BigWigs_Message");
      return "";
    end,
    args = {
      {
        name = "addon",
        init = "arg",
        display = L["BigWigs Addon"],
        type = "string"
      },
      {
        name = "spellId",
        init = "arg",
        display = L["Spell Id"],
        type = "number"
      },
      {
        name = "text",
        init = "arg",
        display = L["Message"],
        type = "longstring",
      },
      {}, -- Importance, might be useful
      {}, -- Icon
    }
  },
  ["BigWigs Timer"] = {
    type = "status",
    events = {
      "BigWigs_Timer_Update"
    },
    force_events = "BigWigs_Timer_Update",
    name = L["BigWigs Timer"],
    init = function(trigger)
      WeakAuras.RegisterBigWigsTimer();
      local ret = [[
        local triggerAddon = %s;
        local triggerSpellId = %s;
        local triggerText = %s;
        local triggerTextOperator = "%s";
      ]]

      ret = ret:format(trigger.use_addon and ('"' .. (trigger.addon or '') .. '"') or "nil",
                       trigger.use_spellId and tostring(trigger.spellId) or "nil",
                       trigger.use_text and ('"' .. (trigger.text or '') .. '"') or "nil",
                       trigger.use_text and trigger.text_operator or ""
                       );

      ret = ret .. [[
        local duration, expirationTime = WeakAuras.GetBigWigsTimer(triggerAddon, triggerSpellId, triggerText, triggerTextOperator);
      ]];

      if (trigger.use_remaining) then
        local ret2 = [[
          local remainingCheck = %s;
          local remaining = expirationTime - GetTime();
          if (remaining >= remainingCheck) then
            WeakAuras.ScheduleBigWigsCheck(expirationTime - remainingCheck);
          end
        ]]
        ret = ret .. ret2:format(tonumber(trigger.remaining) or 0);
      end

      return ret;
    end,
    args = {
      {
        name = "addon",
        display = L["BigWigs Addon"],
        type = "string",
        test = "true"
      },
      {
        name = "spellId",
        display = L["Spell Id"], -- Correct?
        type = "number",
        test = "true"
      },
      {
        name = "text",
        display = L["Message"],
        type = "longstring",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        init = "remaining"
      },
      {
        hidden = true,
        test = "duration > 0"
      },
    },
    automaticrequired = true,
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetBigWigsTimer(trigger.use_addon and trigger.addon,
                                                                 trigger.use_spellId and trigger.spellId,
                                                                 trigger.use_text and trigger.text,
                                                                 trigger.use_text and trigger.text_operator);
      return duration, expirationTime;
    end,
    iconFunc = function(trigger)
      local _, _, icon = WeakAuras.GetBigWigsTimer(trigger.use_addon and trigger.addon,
                                                   trigger.use_spellId and trigger.spellId,
                                                   trigger.use_text and trigger.text,
                                                   trigger.use_text and trigger.text_operator);
      return icon;
    end,
  },
  ["Global Cooldown"] = {
    type = "status",
    events = {
      "GCD_START",
      "GCD_CHANGE",
      "GCD_END"
    },
    name = L["Global Cooldown"],
    init = function(trigger)
      WeakAuras.WatchGCD();
      local ret = [[
        local inverse = %s;
        local onGCD = WeakAuras.GetGCDInfo();
      ]];
      return ret:format(trigger.use_inverse and "true" or "false");
    end,
    args = {
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and onGCD == 0) or (not inverse and onGCD > 0)"
      }
    },
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetGCDInfo();
      return duration, expirationTime;
    end,
    nameFunc = function(trigger)
      local _, _, name = WeakAuras.GetGCDInfo();
      return name;
    end,
    iconFunc = function(trigger)
      local _, _, _, icon = WeakAuras.GetGCDInfo();
      return icon;
    end,
    hasSpellID = true,
    automaticrequired = true
  },
  ["Swing Timer"] = {
    type = "status",
    events = {
      "SWING_TIMER_START",
      "SWING_TIMER_CHANGE",
      "SWING_TIMER_END"
    },
    name = L["Swing Timer"],
    init = function(trigger)
      trigger.hand = trigger.hand or "main";
      WeakAuras.InitSwingTimer();
      local ret = [[
        local inverse = %s;
        local hand = "%s";
        local duration, expirationTime = WeakAuras.GetSwingTimerInfo(hand);
      ]];
      return ret:format((trigger.use_inverse and "true" or "false"), trigger.hand);
    end,
    args = {
      {
        name = "hand",
        required = true,
        display = L["Weapon"],
        type = "select",
        values = "swing_types",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and duration == 0) or (not inverse and duration > 0)"
      }
    },
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return duration, expirationTime;
    end,
    nameFunc = function(trigger)
      local _, _, name = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return name;
    end,
    iconFunc = function(trigger)
      local _, _, _, icon = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return icon;
    end,
    automaticrequired = true
  },
  ["Action Usable"] = {
    type = "status",
    events = {
      "SPELL_COOLDOWN_READY",
      "SPELL_COOLDOWN_CHANGED",
      "SPELL_COOLDOWN_STARTED",
      "SPELL_UPDATE_USABLE",
      "PLAYER_TARGET_CHANGED",
      "UNIT_POWER",
      "RUNE_POWER_UPDATE",
      "RUNE_TYPE_UPDATE"
    },
    force_events = true,
    name = L["Action Usable"],
    init = function(trigger)
      --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
      trigger.spellName = trigger.spellName or 0;
      local spellName = type(trigger.spellName) == "number" and trigger.spellName or "'"..trigger.spellName.."'";
      WeakAuras.WatchSpellCooldown(spellName);
      local ret = [[
        local spell = %s;
        local spellName = GetSpellInfo(spell);
        local startTime, duration = WeakAuras.GetSpellCooldown(spell);
        local charges = WeakAuras.GetSpellCharges(spell);
        startTime = startTime or 0;
        duration = duration or 0;
        local onCooldown = (duration > 1.51 and charges == nil) or (charges and charges == 0);
        local active = IsUsableSpell(spell) and not onCooldown
        if (charges == nil) then
          charges = (duration == 0) and 1 or 0;
        end
      ]]
      if(trigger.use_targetRequired) then
        ret = ret.."active = active and WeakAuras.IsSpellInRange(spellName or '', 'target')\n";
      end
      if(trigger.use_inverse) then
        ret = ret.."active = not active\n";
      end

      return ret:format(spellName)
    end,
    args = {
      {
        name = "spellName",
        display = L["Spell"],
        required = true,
        type = "spell",
        test = "true"
      },
      -- This parameter uses the IsSpellInRange API function, but it does not check spell range at all
      -- IsSpellInRange returns nil for invalid targets, 0 for out of range, 1 for in range (0 and 1 are both "positive" values)
      {
        name = "targetRequired",
        display = L["Require Valid Target"],
        type = "toggle",
        test = "true"
      },
      {
        name = "charges",
        display = L["Charges"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "active"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.spellName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    stacksFunc = function(trigger)
      return WeakAuras.GetSpellCharges(trigger.spellName);
    end,
    hasSpellID = true,
    automaticrequired = true
  },
  ["Totem"] = {
    type = "status",
    events = {
      "PLAYER_TOTEM_UPDATE",
      "COOLDOWN_REMAINING_CHECK"
    },
    force_events = true,
    name = L["Totem"],
    init = function(trigger)
      --trigger.totemName = WeakAuras.CorrectSpellName(trigger.totemName) or 0;
      trigger.totemType = trigger.totemType or 1;

      local ret = [[
        local totemType = %i;
        local _, totemName, startTime, duration = GetTotemInfo(totemType);

        local active = (startTime ~= 0);
      ]];
    ret = ret:format(trigger.totemType);
    if trigger.use_totemName then
      trigger.totemName = trigger.totemName or 0;
      local totemName = type(trigger.totemName) == "number" and trigger.totemName or "'"..trigger.totemName.."'";

      ret = ret .. [[
        active = active and (]] .. totemName .. [[ == totemName);
      ]];
    end

    if(trigger.use_remaining and not trigger.use_inverse) then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime - GetTime();
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining) or 0);
    end

    if trigger.use_inverse then
      ret = ret .. [[
        active = not active;
      ]];
    end

    return ret;
    end,
    args = {
      {
        name = "totemType",
        display = L["Totem Type"],
        required = true,
        type = "select",
        values = "totem_types"
      },
      {
        name = "totemName",
        display = L["Totem Name"],
        type = "aura",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "active"
      }
    },
    durationFunc = function(trigger)
      local _, _, startTime, duration = GetTotemInfo(trigger.totemType);
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      local _, totemName = GetTotemInfo(trigger.totemType);
      return totemName;
    end,
    iconFunc = function(trigger)
      local icon = select(5, GetTotemInfo(trigger.totemType))
      if(icon) then
        return icon;
      else
        local totemIcons = {
          [1] = "Interface\\Icons\\spell_fire_sealoffire",
          [2] = "Interface\\Icons\\inv_elemental_primal_earth",
          [3] = "Interface\\Icons\\spell_frost_summonwaterelemental",
          [4] = "Interface\\Icons\\spell_nature_earthbind"
        };
        return totemIcons[trigger.totemType];
      end
    end,
    automaticrequired = true
  },
  ["Item Count"] = {
    type = "status",
    events = {
      "BAG_UPDATE",
      "ITEM_COUNT_UPDATE",
      "PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Item Count"],
    init = function(trigger)
      if(trigger.use_includeCharges) then
        WeakAuras.RegisterItemCountWatch();
      end
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "'"..trigger.itemName.."'";
      local ret = [[
        local count = GetItemCount(%s, %s, %s);
      ]];
      return ret:format(itemName, trigger.use_includeBank and "true" or "nil", trigger.use_includeCharges and "true" or "nil");
    end,
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        test = "true"
      },
      {
        name = "includeBank",
        display = L["Include Bank"],
        type = "toggle",
        test = "true"
      },
      {
        name = "includeCharges",
        display = L["Include Charges"],
        type = "toggle",
        test = "true"
      },
      {
        name = "count",
        display = L["Item Count"],
        type = "number"
      }
    },
    durationFunc = function(trigger)
      local count = GetItemCount(trigger.itemName, trigger.use_includeBank, trigger.use_includeCharges);
      return count, 0, true;
    end,
    nameFunc = function(trigger)
      return trigger.itemName;
    end,
    iconFunc = function(trigger)
      return GetItemIcon(trigger.itemName);
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Stance/Form/Aura"] = {
    type = "status",
    events = {
      "UPDATE_SHAPESHIFT_FORM",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Stance/Form/Aura"],
    init = function(trigger)
    local ret = [[
      local form = GetShapeshiftForm();
      local _, class = UnitClass('player');
      local form_ = %s;
      local inverse = %s;
    ]];

    return ret:format(trigger.form or 0, trigger.use_inverse and "true" or "false");
    end,
    args = {
      {
        name = "form",
        required = true,
        display = L["Form"],
        type = "select",
        values = "form_types",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and form ~= form_ or not inverse and form == form_)"
      }
    },
    nameFunc = function(trigger)
      local _, class = UnitClass("player");
      if(class == trigger.class) then
        local form = GetShapeshiftForm();
        local _, name = form > 0 and GetShapeshiftFormInfo(form) or "Humanoid";
        return name;
      else
        local types = WeakAuras[class:lower().."_form_types"];
        if(types) then
          return types[GetShapeshiftForm()];
        end
      end
    end,
    iconFunc = function(trigger)
      local _, class = UnitClass("player");
      if(class == trigger.class) then
        local form = GetShapeshiftForm();
        local icon = form > 0 and GetShapeshiftFormInfo(form) or "Interface\\Icons\\Achievement_Character_Human_Male";
        return icon;
      else
        return nil;
      end
    end,
    automaticrequired = true
  },
  ["Weapon Enchant"] = {
    type = "status",
    events = {
      "MAINHAND_TENCH_UPDATE",
      "OFFHAND_TENCH_UPDATE"
    },
    force_events = true,
    name = L["Fishing Lure / Weapon Enchant (Old)"],
    init = function(trigger)
      WeakAuras.TenchInit();
      local ret = [[
        local exists, _, name
        local inverse
      ]];
      if(trigger.weapon == "main") then
        ret = ret .. [[
          exists, _, name = WeakAuras.GetMHTenchInfo()
        ]];
      elseif(trigger.weapon == "off") then
        ret = ret .. [[
          exists, _, name = WeakAuras.GetOHTenchInfo()
        ]];
      end

      if(trigger.use_inverse) then
        ret = ret..[[
          inverse = true;
        ]];
      end

      if(trigger.use_enchant and trigger.enchant and trigger.enchant ~= "") then
        ret = ret .. [[
          exists = name == ']] .. trigger.enchant .. [[';
        ]]
      end
      return ret;
    end,
    args = {
      {
        name = "weapon",
        display = L["Weapon"],
        type = "select",
        values = "weapon_types",
        test = "(inverse and not exists) or (not inverse and exists)"
      },
      {
        name = "enchant",
        display = L["Weapon Enchant"],
        type = "string",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      }
    },
    durationFunc = function(trigger)
      local expirationTime, duration;
      if(trigger.weapon == "main") then
        expirationTime, duration = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        expirationTime, duration = WeakAuras.GetOHTenchInfo();
      end
      if(expirationTime) then
        return duration, expirationTime;
      else
        return 0, math.huge;
      end
    end,
    nameFunc = function(trigger)
      local _, name;
      if(trigger.weapon == "main") then
        _, _, name = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, name = WeakAuras.GetOHTenchInfo();
      end
      return name;
    end,
    iconFunc = function(trigger)
      local _, icon;
      if(trigger.weapon == "main") then
        _, _, _, icon = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, _, icon = WeakAuras.GetOHTenchInfo();
      end
      return icon;
    end,
    automaticrequired = true
  },
  ["Chat Message"] = {
    type = "event",
    events = {
      "CHAT_MSG_INSTANCE_CHAT",
      "CHAT_MSG_INSTANCE_CHAT_LEADER",
      "CHAT_MSG_BG_SYSTEM_ALLIANCE",
      "CHAT_MSG_BG_SYSTEM_HORDE",
      "CHAT_MSG_BG_SYSTEM_NEUTRAL",
      "CHAT_MSG_BN_WHISPER",
      "CHAT_MSG_CHANNEL",
      "CHAT_MSG_EMOTE",
      "CHAT_MSG_GUILD",
      "CHAT_MSG_MONSTER_YELL",
      "CHAT_MSG_OFFICER",
      "CHAT_MSG_PARTY",
      "CHAT_MSG_PARTY_LEADER",
      "CHAT_MSG_RAID",
      "CHAT_MSG_RAID_LEADER",
      "CHAT_MSG_RAID_BOSS_EMOTE",
      "CHAT_MSG_RAID_WARNING",
      "CHAT_MSG_SAY",
      "CHAT_MSG_WHISPER",
      "CHAT_MSG_YELL",
      "CHAT_MSG_SYSTEM"
    },
    name = L["Chat Message"],
    init = function(trigger)
      return [[
        if (event:find('LEADER')) then
          event = event:sub(0, -8);
        end
        if (event == 'CHAT_MSG_TEXT_EMOTE') then
          event = 'CHAT_MSG_EMOTE';
        end
      ]];
    end,
    args = {
      {
        name = "messageType",
        display = L["Message Type"],
        type = "select",
        values = "chat_message_types",
        test = "event=='%s'"
      },
      {
        name = "message",
        display = L["Message"],
        init = "arg",
        type = "longstring"
      },
      {
        name = "sourceName",
        display = L["Source Name"],
        init = "arg",
        type = "string"
      }
    }
  },
  ["Ready Check"] = {
    type = "event",
    events = {
      "READY_CHECK",
    },
    name = L["Ready Check"],
    args = {}
  },
  ["Death Knight Rune"] = {
    type = "status",
    events = {
      "RUNE_POWER_UPDATE",
      "RUNE_TYPE_UPDATE",
      "RUNE_COOLDOWN_READY",
      "RUNE_COOLDOWN_CHANGED",
      "RUNE_COOLDOWN_STARTED",
      "COOLDOWN_REMAINING_CHECK",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "RUNE_COOLDOWN_FORCE",
    name = L["Death Knight Rune"],
    init = function(trigger)
    trigger.rune = trigger.rune or 0;
    WeakAuras.WatchRuneCooldown(trigger.rune);
    local ret = [[
      local rune = %s;
      local startTime, duration = WeakAuras.GetRuneCooldown(rune);
      local inverse = %s;
      local death = %s;

      local numBloodRunes = 0;
      local numUnholyRunes = 0;
      local numFrostRunes = 0;
      local numDeathRunes = 0;
      for index = 1, 6 do
        local startTime = select(1, GetRuneCooldown(index));
        if startTime == 0 then
          if GetRuneType(index) == 1 then
            numBloodRunes = numBloodRunes  + 1;
          elseif GetRuneType(index) == 2 then
            numUnholyRunes = numUnholyRunes + 1;
          elseif GetRuneType(index) == 3 then
            numFrostRunes = numFrostRunes  + 1;
          elseif GetRuneType(index) == 4 then
            numDeathRunes = numDeathRunes  + 1;
          end
        end
      end

      if %s then
        numBloodRunes  = numBloodRunes  + numDeathRunes;
        numUnholyRunes = numUnholyRunes + numDeathRunes;
        numFrostRunes  = numFrostRunes  + numDeathRunes;
      end
    ]];
    if(trigger.use_remaining and not trigger.use_inverse) then
      local ret2 = [[
        local expirationTime = startTime + duration
        local remaining = expirationTime - GetTime();
        local remainingCheck = %s;
        if(remaining >= remainingCheck) then
          WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
        end
      ]];
      ret = ret..ret2:format(tonumber(trigger.remaining) or 0);
    end
    return ret:format(trigger.rune, (trigger.use_inverse and "true" or "false"), (trigger.use_deathRune == true and "true" or trigger.use_deathRune == false and "false" or "nil"), (trigger.use_includeDeath and "true" or "false"));
  end,
    args = {
      {
        name = "rune",
        display = L["Rune"],
        type = "select",
        values = "rune_specific_types",
        test = [[
          ((inverse and startTime == 0) or (not inverse and startTime > 0))
          and
          ((death == nil) or (death == true and GetRuneType(rune) == 4) or (death == false and GetRuneType(rune) ~= 4))
        ]],
        enable = function(trigger) return not trigger.use_bloodRunes and not trigger.use_unholyRunes and not trigger.use_frostRunes end
      },
      {
        name = "deathRune",
        display = L["Death Rune"],
        type = "tristate",
        test = "true",
        enable = function(trigger) return trigger.use_rune end
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return trigger.use_rune and not(trigger.use_inverse) end
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_rune end
      },
      {
        name = "bloodRunes",
        display = L["Blood Runes"],
        type = "number",
        init = "numBloodRunes",
        enable = function(trigger) return not trigger.use_rune end
      },
      {
        name = "unholyRunes",
        display = L["Unholy Runes"],
        type = "number",
        init = "numUnholyRunes",
        enable = function(trigger) return not trigger.use_rune end
      },
      {
        name = "frostRunes",
        display = L["Frost Runes"],
        type = "number",
        init = "numFrostRunes",
        enable = function(trigger) return not trigger.use_rune end
      },
      {
        name = "includeDeath",
        display = L["Include Death Runes"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_bloodRunes or trigger.use_unholyRunes or trigger.use_frostRunes end
      },
    },
    durationFunc = function(trigger)
    if trigger.use_rune then
    local startTime, duration
    if not(trigger.use_inverse) then
      startTime, duration = WeakAuras.GetRuneCooldown(trigger.rune);
    end

    startTime = startTime or 0;
    duration = duration or 0;

    return duration, startTime + duration;
    else
    return 1, 0;
    end
    end,
    nameFunc = function(trigger)
      local runeNames = {
        [1] = L["Blood"],
        [2] = L["Unholy"],
        [3] = L["Frost"],
        [4] = L["Death"]
      };
      return runeNames[GetRuneType(trigger.rune)];
    end,
    iconFunc = function(trigger)
      local runeIcons = {
        [1] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
        [2] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
        [3] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
        [4] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death"
      };
      return runeIcons[GetRuneType(trigger.rune)];
    end,
    automaticrequired = true,
  },
  ["Item Equipped"] = {
    type = "status",
    events = {
      "UNIT_INVENTORY_CHANGED",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Item Equipped"],
    init = function(trigger)
    --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
    trigger.itemName = trigger.itemName or 0;
    local itemName = type(trigger.itemName) == "number" and trigger.itemName or "'" .. trigger.itemName .. "'";

      local ret = [[
        local inverse = %s;
        local equipped = IsEquippedItem(%s);
      ]];

    return ret:format(trigger.use_inverse and "true" or "false", itemName);
    end,
    args = {
      {
        name = "itemName",
        display = L["Item"],
        type = "item",
        required = true,
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and not equipped) or (equipped and not inverse)"
      }
    },
    nameFunc = function(trigger)
      if not trigger.use_inverse then
        local name = GetItemInfo(trigger.itemName);
        return name;
      else
        return nil;
      end
    end,
    iconFunc = function(trigger)
      if not trigger.use_inverse then
        local texture = select(10, GetItemInfo(trigger.itemName));
        return texture;
      else
        return nil;
      end
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Item Set Equipped"] = {
    type = "status",
    events = {
      "PLAYER_EQUIPMENT_CHANGED",
      "WEAR_EQUIPMENT_SET",
      "EQUIPMENT_SETS_CHANGED",
      "EQUIPMENT_SWAP_FINISHED",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "PLAYER_EQUIPMENT_CHANGED",
    name = L["Item Set Equipped"],
    init = function(trigger)
      trigger.itemSetName = trigger.itemSetName or 0;
      local itemSetName = type(trigger.itemSetName) == "number" and trigger.itemSetName or "'" .. trigger.itemSetName .. "'";

      local ret = [[
        local useItemSetName = %s;
        local itemSetName = %s;
        local inverse = %s;
        local partial = %s;

        local equipped = WeakAuras.GetEquipmentSetInfo(useItemSetName and itemSetName or nil, partial);
      ]];

      return ret:format(trigger.use_itemSetName and "true" or "false",
                        itemSetName,
                        trigger.use_inverse and "true" or "false",
                        trigger.use_partial and "true" or "false");
    end,
    args = {
      {
        name = "itemSetName",
        display = L["Item Set"],
        type = "string",
        test = "true"
      },
      {
        name = "partial",
        display = L["Allow partial matches"],
        type = toggle,
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and not equipped) or (equipped and not inverse)"
      }
    },
    nameFunc = function(trigger)
      return WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
    end,
    iconFunc = function(trigger)
      local _, icon = WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
      return icon;
    end,
    durationFunc = function(trigger)
      local _, _, numEquipped, numItems = WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
      return numEquipped, numItems, true;
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Threat Situation"] = {
    type = "status",
    events = {
      "UNIT_THREAT_SITUATION_UPDATE",
      "PLAYER_TARGET_CHANGED"
    },
    force_events = true,
    name = L["Threat Situation"],
    init = function(trigger)
      local ret = [[
        local status = UnitThreatSituation('player', %s) or -1;
        local aggro = status == 2 or status == 3;
      ]];

    return ret:format(trigger.threatUnit and trigger.threatUnit ~= "none" and "'"..trigger.threatUnit.."'" or "nil");
    end,
    args = {
      {
        name = "threatUnit",
        display = L["Unit"],
        required = true,
        type = "select",
        values = "threat_unit_types",
        test = "true"
      },
      {
        name = "status",
        display = L["Status"],
        type = "select",
        values = "unit_threat_situation_types"
      },
      {
        name = "aggro",
        display = L["Aggro"],
        type = "tristate"
      },
      {
        hidden = true,
        test = "status ~= -1"
      },
    },
    automatic = true
  },
  ["Crowd Controlled"] = {
    type = "status",
    events = {
      "UNIT_AURA"
    },
    force_events = true,
    name = L["Crowd Controlled"],
    args = {
      {
        name = "controlled",
        display = L["Crowd Controlled"],
        type = "tristate",
        init = "not HasFullControl()"
      }
    },
    automaticrequired = true
  },
  ["Cast"] = {
    type = "status",
    events = {
      "UNIT_SPELLCAST_CHANNEL_START",
      "UNIT_SPELLCAST_CHANNEL_STOP",
      "UNIT_SPELLCAST_CHANNEL_UPDATE",
      "UNIT_SPELLCAST_START",
      "UNIT_SPELLCAST_STOP",
      "UNIT_SPELLCAST_DELAYED",
      "UNIT_SPELLCAST_INTERRUPTIBLE",
      "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = true,
    name = L["Cast"],
    init = function(trigger)
      trigger.unit = trigger.unit or "";
      local ret = [[
        local unit = "%s"
        local inverse = %s
        local spell, interruptible, _;
        local castType;
        spell, _, _, _, _, _, _, _, interruptible = UnitCastingInfo(unit)
        if(spell) then
          castType = "cast"
        else
          spell, _, _, _, _, _, _, interruptible = UnitChannelInfo(unit)
          if(spell) then
            castType = "channel"
          end
        end
        interruptible = not interruptible;
      ]];
      return ret:format(trigger.unit, trigger.use_inverse and "true" or "false");
    end,
    args = {
      {
        name = "unit",
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        required = true
      },
      {
        name = "spell",
        display = L["Spell Name"],
        type = "string" ,
        enable = function(trigger) return not(trigger.use_inverse) end,
      },
      {
        name = "castType",
        display = L["Cast Type"],
        type = "select",
        values = "cast_types",
        enable = function(trigger) return not(trigger.use_inverse) end,
      },
      {
        name = "interruptible",
        display = L["Interruptible"],
        type = "tristate",
        enable = function(trigger) return not(trigger.use_inverse) end,
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "UnitExists(unit) and ((not inverse and spell) or (inverse and not spell))"
      }
    },
    durationFunc = function(trigger)
      local _, _, _, _, startTime, endTime = UnitCastingInfo(trigger.unit);
      if not(startTime) then
        local _, _, _, _, startTime, endTime = UnitChannelInfo(trigger.unit);
        if not(startTime) then
          return 0, math.huge;
        else
          return (endTime - startTime)/1000, endTime/1000;
        end
      else
        return (endTime - startTime)/1000, endTime/1000, nil, true;
      end
    end,
    nameFunc = function(trigger)
      local name = UnitCastingInfo(trigger.unit);
      if not(name) then
        local name = UnitChannelInfo(trigger.unit);
        if not(name) then
          return trigger.spell or L["Spell Name"];
        else
          return name;
        end
      else
        return name;
      end
    end,
    iconFunc = function(trigger)
      local _, _, _, icon = UnitCastingInfo(trigger.unit);
      if not(icon) then
        local _, _, _, icon = UnitChannelInfo(trigger.unit);
        if not(icon) then
          return "Interface\\AddOns\\WeakAuras\\icon";
        else
          return icon;
        end
      else
        return icon;
      end
    end,
    automaticrequired = true
  },
  ["Conditions"] = {
    type = "status",
    events = {
      "PLAYER_REGEN_ENABLED",
      "PLAYER_REGEN_DISABLED",
      "PLAYER_FLAGS_CHANGED",
      "PLAYER_DEAD",
      "PLAYER_ALIVE",
      "PLAYER_UNGHOST",
      "UNIT_PET",
      "PET_UPDATE",
      "UNIT_ENTERED_VEHICLE",
      "UNIT_EXITED_VEHICLE",
      "PLAYER_UPDATE_RESTING",
      "MOUNTED_UPDATE",
      "CONDITIONS_CHECK",
      "PLAYER_MOVING_UPDATE"
    },
    force_events = "CONDITIONS_CHECK",
    name = L["Conditions"],
    init = function(trigger)
      if(trigger.use_mounted ~= nil) then
        WeakAuras.WatchForMounts();
      end
      if (trigger.use_HasPet ~= nil) then
        WeakAuras.WatchForPetDeath();
      end
      if (trigger.use_ismoving ~= nil) then
        WeakAuras.WatchForPlayerMoving();
      end
      return "";
    end,
    args = {
      {
        name = "alwaystrue",
        display = L["Always active trigger"],
        type = "tristate",
        init = "true"
      },
      {
        name = "pvpflagged",
        display = L["PvP Flagged"],
        type = "tristate",
        init = "UnitIsPVP('player')"
      },
      {
        name = "alive",
        display = L["Alive"],
        type = "tristate",
        init = "not UnitIsDeadOrGhost('player')"
      },
      {
        name = "vehicle",
        display = L["In Vehicle"],
        type = "tristate",
        init = "UnitInVehicle('player')"
      },
      {
        name = "resting",
        display = L["Resting"],
        type = "tristate",
        init = "IsResting()"
      },
      {
        name = "mounted",
        display = L["Mounted"],
        type = "tristate",
        init = "IsMounted()"
      },
      {
        name = "HasPet",
        display = L["HasPet"],
        type = "tristate",
        init = "UnitExists('pet') and not UnitIsDead('pet')"
      },
      {
        name = "ismoving",
        display = L["Is Moving"],
        type = "tristate",
        init = "IsPlayerMoving()"
      }
    },
    automaticrequired = true
  },
  ["Pet Behavior"] = {
    type = "status",
    events = {
      "PET_BAR_UPDATE",
      "UNIT_PET",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = true,
    name = L["Pet Behavior"],
    init = function(trigger)
      local ret = [[
          local inverse = %s
          local check_behavior = "%s"
          local name,_,_,_,active,_,_,exists
          local behavior
          local index = 1
          repeat
            name,_,_,_,active,_,_,exists = GetPetActionInfo(index);
            index = index + 1
            if(name == "PET_MODE_ASSIST" and active == true) then
              behavior = "assist"
            elseif(name == "PET_MODE_DEFENSIVE" and active == true) then
              behavior = "defensive"
            elseif(name == "PET_MODE_PASSIVE" and active == true) then
              behavior = "passive"
            end
          until index == 12
      ]]
      return ret:format(trigger.use_inverse and "true" or "false", trigger.behavior or "");
    end,
    args = {
      {
        name = "behavior",
        display = L["Pet Behavior"],
        required = true,
        type = "select",
        values = "pet_behavior_types",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "UnitExists('pet') and ((inverse and check_behavior ~= behavior) or (not inverse and check_behavior == behavior))"
      }
    },
    automaticrequired = true
  }
};

WeakAuras.dynamic_texts = {
  ["%%p"] = {
    unescaped = "%p",
    name = L["Progress"],
    value = "progress",
    static = "8.0"
  },
  ["%%t"] = {
    unescaped = "%t",
    name = L["Total"],
    value = "duration",
    static = "12.0"
  },
  ["%%n"] = {
    unescaped = "%n",
    name = L["Name"],
    value = "name"
  },
  ["%%i"] = {
    unescaped = "%i",
    name = L["Icon"],
    value = "icon"
  },
  ["%%s"] = {
    unescaped = "%s",
    name = L["Stacks"],
    value = "stacks",
    static = 1
  },
  ["%%c"] = {
    unescaped = "%c",
    name = L["Custom"],
    value = "custom",
    static = L["Custom"]
  }
};
