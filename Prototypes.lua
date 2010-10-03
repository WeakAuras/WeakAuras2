local L = WeakAuras.L;
  
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
end]],
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
]]
};

WeakAuras.anim_presets = {
  --Start and Finish
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
  
  --Main
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
    duration = 0.5,
    use_scale = true,
    scalex = 1.1,
    scaley = 1.1,
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
  }
};

WeakAuras.load_prototype = {
  args = {
    {
      name = "name",
      display = "Player Name",
      type = "string",
      init = "arg"
    },
    {
      name = "class",
      display = "Player Class",
      type = "select",
      values = "class_types",
      init = "arg"
    },
    {
      name = "spec",
      display = "Talent Specialization",
      type = "select",
      values = "spec_types",
      init = "arg"
    },
    {
      name = "zone",
      display = "Zone",
      type = "string",
      init = "arg"
    },
    {
      name = "size",
      display = "Instance Type",
      type = "select",
      values = "group_types",
      init = "arg"
    },
    {
      name = "difficulty",
      display = "Dungeon Difficulty",
      type = "select",
      values = "difficulty_types",
      init = "arg"
    }
  }
};

WeakAuras.event_prototypes = {
  ["Combo Points"] = {
    events = {
      "UNIT_COMBO_POINTS"
    },
    force_events = true,
    name = L["Combo Points"],
    args = {
      {
        name = "combopoints",
        display = L["Combo Points"],
        type = "number",
        init = "GetComboPoints(UnitInVehicle('player') and 'vehicle' or 'player', 'target')"
      }
    },
    durationFunc = function(trigger)
      return GetComboPoints(UnitInVehicle('player') and 'vehicle' or 'player', 'target'), 5, true;
    end,
    automatic = true
  },
  ["Health"] = {
    events = {
      "UNIT_HEALTH",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Health"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
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
        init = "(UnitHealth(unit) / UnitHealthMax(unit)) * 100"
      }
    },
    durationFunc = function(trigger)
      return UnitHealth(trigger.unit), UnitHealthMax(trigger.unit), true;
    end,
    automatic = true
  },
  
  --[[ -------------------------------------------------------------------------------- ]
     [ The following code is only valid until 4.0                                       ]
  --]] -------------------------------------------------------------------------------- ]
  ["Mana"] = {
    events = {
      "UNIT_MANA",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Mana"],
    init = function(trigger)
      return "local unit = unit or '"..(trigger.unit or "").."'\nlocal concernedUnit = '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "power",
        display = L["Mana"],
        type = "number",
        init = "UnitPowerType(unit) == 0 and UnitPower(unit) or 0"
      },
      {
        name = "percentpower",
        display = L["Mana (%)"],
        type = "number",
        init = "UnitPowerType(unit) == 0 and (UnitPower(unit) / UnitPowerMax(unit)) * 100 or 0"
      },
      {
        name = "unitExists",
        display = L["Unit Exists"],
        type = "toggle",
        init = "UnitExists(concernedUnit)"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  ["Rage"] = {
    events = {
      "UNIT_RAGE",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Rage"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "power",
        display = L["Rage"],
        type = "number",
        init = "UnitPowerType(unit) == 1 and UnitPower(unit) or 0"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  ["Focus"] = {
    events = {
      "UNIT_FOCUS",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Focus"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "power",
        display = L["Focus"],
        type = "number",
        init = "UnitPowerType(unit) == 2 and UnitPower(unit) or 0"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  ["Energy"] = {
    events = {
      "UNIT_ENERGY",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Energy"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "power",
        display = L["Energy"],
        type = "number",
        init = "UnitPowerType(unit) == 3 and UnitPower(unit) or 0"
      },
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  ["Runic Power"] = {
    events = {
      "UNIT_RUNIC_POWER",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Runic Power"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "power",
        display = L["Runic Power"],
        type = "number",
        init = "UnitPowerType(unit) == 6 and UnitPower(unit) or 0"
      },
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  --[[ -------------------------------------------------------------------------------- ]
     [ End Patch 4.0 non-compliant code                                                 ]
  --]] -------------------------------------------------------------------------------- ]
  
  
  --[[ -------------------------------------------------------------------------------- ]
     [ Patch 4.0 compliant subsitute                                                    ]
  --]] -------------------------------------------------------------------------------- ]
  --[[
  ["Power"] = {
    events = {
      "UNIT_POWER",
      "PLAYER_TARGET_CHANGED",
      "PLAYER_FOCUS_CHANGED"
    },
    force_events = {
      "player",
      "target",
      "focus"
    },
    name = L["Power"],
    init = function(trigger)
      return "if not(UnitExists('"..(trigger.unit or "").."')) then return false end\nlocal unit = unit or '"..(trigger.unit or "").."'\n";
    end,
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "select",
        init = "arg",
        values = "actual_unit_types"
      },
      {
        name = "powertype",
        required = true,
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
        init = "(UnitPower(unit) / UnitPowerMax(unit)) * 100"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), true;
    end,
    automatic = true
  },
  ]]
  --Todo: Give useful options to condition based on GUID and flag info
  --Todo: Allow options to pass information from combat message to the display?
  ["Combat Log"] = {
    events = {
      "COMBAT_LOG_EVENT_UNFILTERED"
    },
    name = L["Combat Log"],
    args = {
      {}, --timestamp ignored with _ argument
      {}, --messageType ignored with _ argument (it is checked before the dynamic function)
      {}, --sourceGUID ignored with _ argument
      {
        name = "sourceunit",
        display = L["Source Unit"],
        type = "select",
        test = "UnitIsUnit(source, '%s')",
        values = "actual_unit_types",
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
      {}, --sourceFlags ignored with _ argument
      {}, --destGUID ignored with _ argument
      {
        name = "destunit",
        display = L["Destination Unit"],
        type = "select",
        test = "UnitIsUnit(dest, '%s')",
        values = "actual_unit_types"
      },
      {
        name = "dest",
        display = L["Destination Name"],
        type = "string",
        init = "arg"
      },
      {}, --destFlags ignored with _ argument
      {
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      }, --spellId ignored with _ argument
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
      }, --spellSchool ignored with _ argument
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
      }, --extraSpellId ignored with _ argument
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
      }, --extraSchool ignored with _ argument
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
      }, --damage school ignored with _ argument
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
      } --failedType ignored with _ argument - theoretically this is not necessary because it is the last argument in the event, but it is added here for completeness
    }
  },
  ["Cooldown (Spell)"] = {
    events = {
      "SPELL_UPDATE_COOLDOWN",
      "UNIT_RUNIC_POWER",
      "UNIT_ENERGY",
      "UNIT_FOCUS",
      "UNIT_RAGE",
      "UNIT_MANA",
      "ACTIONBAR_UPDATE_COOLDOWN"
    },
    force_events = true,
    name = "Cooldown (Spell)",
    init = function(trigger)
      trigger.spellName = trigger.spellName or "";
      return "local startTime, duration = GetSpellCooldown('"..trigger.spellName.."');";
    end,
    args = {
      {
        name = "spellName",
        display = L["Spell"],
        type = "spell",
        test = "startTime > 0"
      },
      {
        name = "cooldownDuration",
        display = L["Ignore GCD"],
        type = "toggle",
        test = "duration > 1.51"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = GetSpellCooldown(trigger.spellName);
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger) return trigger.spellName; end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName);
      return icon;
    end,
    automaticrequired = true
  },
  ["Cooldown (Item)"] = {
    events = {
      "SPELL_UPDATE_COOLDOWN",
      "ACTIONBAR_UPDATE_COOLDOWN"
    },
    force_events = true,
    name = "Cooldown (Item)",
    init = function(trigger)
      trigger.itemName = trigger.itemName or "";
      return "local startTime, duration = GetItemCooldown('"..trigger.itemName.."');";
    end,
    args = {
      {
        name = "itemName",
        display = L["Item"],
        type = "item",
        test = "startTime > 0"
      },
      {
        name = "cooldownDuration",
        display = L["Ignore GCD"],
        type = "toggle",
        test = "duration > 1.51"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = GetItemCooldown(trigger.itemName);
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      return trigger.itemName;
    end,
    iconFunc = function(trigger)
      return GetItemIcon(trigger.itemName);
    end,
    automaticrequired = true
  },
  ["Action Usable"] = {
    events = {
      "SPELL_UPDATE_USABLE",
      "PLAYER_TARGET_CHANGED"
    },
    force_events = true,
    name = "Action Usable",
    init = function(trigger)
      trigger.spellName = trigger.spellName or "";
      return "local usable = IsUsableSpell('"..trigger.spellName.."');";
    end,
    args = {
      {
        name = "spellName",
        display = L["Spell"],
        type = "spell",
        test = "IsUsableSpell('%s')"
      },
      --This parameter uses the IsSpellInRange API function, but it does not check spell range at all
      --IsSpellInRange returns nil for invalid targets, 0 for out of range, 1 for in range (0 and 1 are both "positive" values)
      {
        name = "targetRequired",
        display = L["Require Valid Target"],
        type = "toggle",
        test = "IsSpellInRange('%s')"
      }
    },
    nameFunc = function(trigger)
      return trigger.spellName;
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName);
      return icon;
    end,
    automaticrequired = true
  },
  ["Totem"] = {
    events = {
      "PLAYER_TOTEM_UPDATE"
    },
    force_events = true,
    name = "Totem",
    init = function(trigger)
      trigger.totemType = trigger.totemType or 1;
      return "local _, totemName, startTime, duration = GetTotemInfo('"..trigger.totemType.."');";
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
        init = "arg"
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
      local _, totemName = GetTotemInfo(trigger.totemType);
      local icon = GetSpellTexture(totemName);
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
    events = {
      "UNIT_INVENTORY_CHANGED"
    },
    force_events = true,
    name = "Item Count",
    init = function(trigger)
      trigger.itemName = trigger.itemName or 1;
      return "local count = GetItemCount('"..trigger.itemName.."', "..(trigger.use_includeBank and "true" or "nil")..", "..(trigger.use_includeCharges and "true" or "nil")..");\n";
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
        type = "toggle"
      },
      {
        name = "includeCharges",
        display = L["Include Charges"],
        type = "toggle"
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
    automaticrequired = true
  },
  ["Stance/Form/Aura"] = {
    events = {
      "UPDATE_SHAPESHIFT_FORM"
    },
    force_events = true,
    name = "Stance/Form/Aura",
    init = function()
    return "local form = GetShapeshiftForm();\n local _, class = UnitClass('player');\n"
    end,
    args = {
      {
        name = "class",
        display = L["Class"],
        required = true,
        type = "select",
        values = "class_for_stance_types"
      },
      {
        name = "dk_form",
        display = L["Presence (DK)"],
        type = "select",
        values = "deathknight_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "DEATHKNIGHT";
        end
      },
      {
        name = "druid_form",
        display = L["Form (Druid)"],
        type = "select",
        values = "druid_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "DRUID";
        end
      },
      {
        name = "paladin_form",
        display = L["Aura (Paladin)"],
        type = "select",
        values = "paladin_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "PALADIN";
        end
      },
      {
        name = "priest_form",
        display = L["Form (Priest)"],
        type = "select",
        values = "priest_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "PRIEST";
        end
      },
      {
        name = "rogue_form",
        display = L["Presence (Rogue)"],
        type = "select",
        values = "rogue_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "ROGUE";
        end
      },
      {
        name = "shaman_form",
        display = L["Form (Shaman)"],
        type = "select",
        values = "shaman_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "SHAMAN";
        end
      },
      {
        name = "warrior_form",
        display = L["Stance (Warrior)"],
        type = "select",
        values = "warrior_form_types",
        test = "form == %s",
        enable = function(trigger)
          return trigger.class == "WARRIOR";
        end
      }
    },
    nameFunc = function(trigger)
      local _, class = UnitClass("player");
      if(class == trigger.class) then
        local _, name = GetShapeshiftFormInfo(GetShapeshiftForm());
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
        local icon = GetShapeshiftFormInfo(GetShapeshiftForm());
        return icon;
      else
        return nil;
      end
    end,
    automaticrequired = true
  },
  --Is tracking even a useful thing to include? Possibly just delete this one!
  --Commented out until I can decide what to do with this. Tracking seems too useless to spend any time on,
  --Since any UI element that allows you to set your tracking should display what tracking you have on.
  --[[
  ["Tracking"] = {
    event = "MINIMAP_UPDATE_TRACKING",
    name = L["Tracking"],
    init = function() return "local tracking = GetTracking
    args = {
      {
        name = "tracking",
        display = L["Tracking"]
      }
    }
  },
  ]]
  --Weapon Enchant events give very little information, and there does not seem to be any proper UI function
  --to get the desired information - the only way to get it is to parse tooltips, and that seems like more work
  --than it is worth. Thus, Weapon Enchant triggers are NYI.
  --[[
  ["Weapon Enchanted"] = {
    events = {
      "UNIT_INVENTORY_CHANGED"
    },
    force_events = true,
    name = L["Weapon Enchanted"],
    init = function(trigger)
      if(trigger.weapon == "main") then
        return "local enchanted = GetWeaponEnchantInfo()";
      elseif(trigger.weapon == "off") then
        return "local _, _, _, enchanted = GetWeaponEnchantInfo()";
      else
        return "local enchanted";
      end
    end,
    args = {
      {
        name = "weapon",
        display = L["Weapon"],
        required = true,
        type = "select",
        values = "weapon_types",
        test = "enchanted"
      }
    } 
  },
  ]]
  ["Chat Message"] = {
    events = {
      "CHAT_MSG_BATTLEGROUND",
      "CHAT_MSG_BATTLEGROUND_LEADER",
      "CHAT_MSG_BN_WHISPER",
      "CHAT_MSG_CHANNEL",
      "CHAT_MSG_EMOTE",
      "CHAT_MSG_GUILD",
      "CHAT_MSG_OFFICER",
      "CHAT_MSG_PARTY",
      "CHAT_MSG_PARTY_LEADER",
      "CHAT_MSG_RAID",
      "CHAT_MSG_RAID_LEADER",
      "CHAT_MSG_RAID_BOSS_EMOTE",
      "CHAT_MSG_RAID_WARNING",
      "CHAT_MSG_SAY",
      "CHAT_MSG_WHISPER",
      "CHAT_MSG_YELL"
    },
    name = L["Chat Message"],
    init = function(trigger)
      return "if(event:find('LEADER')) then event = event:sub(0, -8) end\nif(event == 'CHAT_MSG_TEXT_EMOTE') then event = 'CHAT_MSG_EMOTE' end\n"
    end,
    args = {
      {
        name = "messageType",
        display = L["Message Type"],
        type = "select",
        values = "chat_message_types"
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
  ["Death Knight Rune"] = {
    events = {
      "RUNE_POWER_UPDATE",
      "RUNE_TYPE_UPDATE"
    },
    force_events = true,
    name = "Death Knight Rune",
    init = function(trigger)
      trigger.rune = trigger.rune or 1;
      return "local death = (GetRuneType("..trigger.rune..") == 4);\nlocal _, _, ready = GetRuneCooldown("..trigger.rune..");\n";
    end,
    args = {
      {
        name = "rune",
        display = L["Rune"],
        required = true,
        type = "select",
        values = "rune_specific_types",
        test = "true"
      },
      {
        name = "death",
        display = L["Death Rune"],
        type = "tristate"
      },
      {
        name = "ready",
        display = L["Ready For Use"],
        type = "tristate"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration, ready = GetRuneCooldown(trigger.rune);
      if(startTime > 0) then
        return duration, startTime + duration;
      else
        return 0, math.huge;
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
    expiredHideFunc = function(trigger)
      if(trigger.ready == nil) then
        return false;
      else
        return true;
      end
    end,
    automaticrequired = true
  },
  ["Item Equipped"] = {
    events = {"UNIT_INVENTORY_CHANGED"},
    force_events = true,
    name = L["Item Equipped"],
    init = function(trigger)
      return "local inverse = "..(trigger.use_inverse and "true" or "false")..";\nlocal equipped = IsEquippedItem(\""..(trigger.itemName or "").."\");\n"
    end,
    args = {
      {
        name = "itemName",
        display = L["Item"],
        type = "item",
        test = "(inverse and not equipped) or (equipped and not inverse)"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      }
    },
    automaticrequired = true
  },
  ["Threat Situation"] = {
    events = {
      "UNIT_THREAT_SITUATION_UPDATE",
      "PLAYER_TARGET_CHANGED"
    },
    force_events = true,
    name = L["Threat Situation"],
    init = function(trigger)
      return "local status = UnitThreatSituation('player', "..(trigger.threatUnit and trigger.threatUnit ~= "none" and "'"..trigger.threatUnit.."'" or "nil")..") or -1;\n";
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
      }
    },
    automatic = true
  }
};

WeakAuras.conditions = {
  combat = {
    display = L["In Combat"],
    events = {
      "PLAYER_REGEN_ENABLED",
      "PLAYER_REGEN_DISABLED"
    },
    func = function()
      return UnitAffectingCombat("player")
    end
  },
  pvpflagged = {
    display = L["PvP Flagged"],
    events = {
      "PLAYER_FLAGS_CHANGED"
    },
    func = function()
      return UnitIsPVP("player")
    end
  },
  alive = {
    display = L["Alive"],
    events = {
      "PLAYER_DEAD",
      "PLAYER_ALIVE",
      "PLAYER_UNGHOST"
    },
    func = function()
      return not UnitIsDeadOrGhost("player")
    end
  },
  vehicle = {
    display = L["In Vehicle"],
    events = {
      "UNIT_ENTERED_VEHICLE",
      "UNIT_EXITED_VEHICLE"
    },
    func = function()
      return UnitInVehicle("player")
    end
  },
  resting = {
    display = L["Resting"],
    events = {
      "PLAYER_UPDATE_RESTING"
    },
    func = function()
      return IsResting()
    end
  },
  mounted = {
    display = L["Mounted"],
    events = {
      "COMPANION_UPDATE"
    },
    func = function()
      return IsMounted()
    end
  }
};