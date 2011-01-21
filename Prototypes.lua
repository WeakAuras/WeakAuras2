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
]],
	hide = [[
return function()
	return 0
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
            type = "multiselect",
            values = "class_types",
            init = "arg"
        },
        {
            name = "spec",
            display = "Talent Specialization",
            type = "multiselect",
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
            type = "multiselect",
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
        type = "status",
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
        type = "status",
        events = {
            "UNIT_HEALTH",
            "PLAYER_TARGET_CHANGED",
            "PLAYER_FOCUS_CHANGED"
        },
        force_events = {
            "player",
            "target",
            "focus",
            "pet"
        },
        name = L["Health"],
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
            },
            {
                hidden = true,
                test = "UnitExists(concernedUnit)"
            }
        },
        durationFunc = function(trigger)
            return UnitHealth(trigger.unit), UnitHealthMax(trigger.unit), true;
        end,
        automatic = true
    },
    ["Power"] = {
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
        name = L["Power"],
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
                name = "powertype",
                --required = true,
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
                init = "(UnitPower(unit) / UnitPowerMax(unit)) * 100;"
            },
            {
                hidden = true,
                test = "UnitExists(concernedUnit)"
            }
        },
        durationFunc = function(trigger)
            return UnitPower(trigger.unit), UnitPowerMax(trigger.unit), function() return UnitPower(trigger.unit), UnitPowerMax(trigger.unit) end;
        end,
        automatic = true
    },
    ["Holy Power"] = {
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
        name = L["Holy Power"],
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
                display = L["Holy Power"],
                type = "number",
                init = "UnitPower(unit, 9)"
            },
            {
                hidden = true,
                test = "UnitExists(concernedUnit)"
            }
        },
        durationFunc = function(trigger)
            return UnitPower(trigger.unit, 9), UnitPowerMax(trigger.unit, 9), function() return UnitPower(trigger.unit, 9), UnitPowerMax(trigger.unit, 9) end;
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
            local ret = [[
local unit = unit or '%s'
local concernedUnit = '%s'
local _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo('%s');
]]
            return ret:format(trigger.unit or "", trigger.unit or "", trigger.unit or "");
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
            return UnitPower(trigger.unit, 10), UnitPowerMax(trigger.unit, 10), function() return UnitPower(trigger.unit, 10), UnitPowerMax(trigger.unit, 10) end;
        end,
        nameFunc = function(trigger)
            local _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo(trigger.unit);
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
            "PLAYER_TARGET_CHANGED",
            "PLAYER_FOCUS_CHANGED"
        },
        force_events = {
            "player",
            "target",
            "focus",
            "pet"
        },
        name = L["Shards"],
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
                display = L["Shards"],
                type = "number",
                init = "UnitPower(unit, 7)"
            },
            {
                hidden = true,
                test = "UnitExists(concernedUnit)"
            }
        },
        durationFunc = function(trigger)
            return UnitPower(trigger.unit, 7), UnitPowerMax(trigger.unit, 7), true;
        end,
        automatic = true
    },
    ["Eclipse Power"] = {
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
        name = L["Eclipse Power"],
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
                name = "eclipsetype",
                --required = true,
                display = L["Eclipse Type"],
                type = "select",
                values = "eclipse_types",
                test = "true"
            },
            {
                name = "lunar_power",
                display = L["Lunar Power"],
                type = "number",
                init = "math.min(UnitPower(unit, 8), -0) * -1",
                enable = function(trigger)
                    return trigger.eclipsetype == "moon"
                end
            },
            {
                name = "solar_power",
                display = L["Solar Power"],
                type = "number",
                init = "math.max(UnitPower(unit, 8), 0)",
                enable = function(trigger)
                    return trigger.eclipsetype == "sun"
                end
            },
            {
                hidden = true,
                test = "UnitExists(concernedUnit)"
            }
        },
        durationFunc = function(trigger)
            if(trigger.eclipsetype == "moon") then
                local lunar_power = math.min(UnitPower(trigger.unit, 8), -0) * -1;
                return lunar_power, UnitPowerMax(trigger.unit, 8), true;
            elseif(trigger.eclipsetype == "sun") then
                local solar_power = math.max(UnitPower(trigger.unit, 8), 0);
                return solar_power, UnitPowerMax(trigger.unit, 8), true;
            else
                return 0, 0, true;
            end
        end,
        automatic = true
    },
    ["Eclipse Direction"] = {
        type = "status",
        events = {
            "UNIT_POWER"
        },
        force_events = true,
        name = L["Eclipse Direction"],
        args = {
            {
                name = "eclipse_direction",
                --required = true,
                display = L["Eclipse Direction"],
                type = "select",
                values = "eclipse_types",
                init = "GetEclipseDirection()"
            }
        },
        automatic = true
    },
    --Todo: Give useful options to condition based on GUID and flag info
    --Todo: Allow options to pass information from combat message to the display?
    ["Combat Log"] = {
        type = "event",
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
                test = "dest and UnitIsUnit(dest, '%s')",
                values = "actual_unit_types"
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
        type = "status",
        events = {
            "SPELL_COOLDOWN_READY",
			"SPELL_COOLDOWN_CHANGED",
			"SPELL_COOLDOWN_STARTED"
        },
        force_events = true,
        name = L["Cooldown Progress (Spell)"],
        init = function(trigger)
            trigger.spellName = trigger.spellName or 0;
            local spellName = (type(trigger.spellName) == "number" and trigger.spellName or "'"..trigger.spellName.."'");
            WeakAuras.WatchSpellCooldown(trigger.spellName);
            local ret = [[
local startTime, duration = WeakAuras.GetSpellCooldown(%s);
local inverse = %s;
]];
            return ret:format(spellName, (trigger.use_inverse and "true" or "false"));
        end,
        args = {
            {
                name = "spellName",
				required = true,
                display = L["Spell"],
                type = "spell",
				init = "arg"
            },
            {
                name = "inverse",
                display = L["Inverse"],
                type = "toggle",
                test = "true"
            },
			{
				hidden = true,
				test = "(inverse and startTime == 0) or (not inverse and startTime > 0)"
			}
        },
        durationFunc = function(trigger)
            local startTime, duration;
            if not(trigger.use_inverse) then
                startTime, duration = WeakAuras.GetSpellCooldown(trigger.spellName or 0);
            end
            return duration or 0, startTime + duration or 0;
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
        automaticrequired = true
    },
    ["Cooldown Ready (Spell)"] = {
        type = "event",
        events = {
            "SPELL_COOLDOWN_READY"
        },
        name = L["Cooldown Ready (Spell)"],
        init = function(trigger)
            trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
            WeakAuras.WatchSpellCooldown(trigger.spellName);
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
        end
    },
    ["Cooldown Progress (Item)"] = {
        type = "status",
        events = {
            "ITEM_COOLDOWN_READY",
			"ITEM_COOLDOWN_CHANGED",
			"ITEM_COOLDOWN_STARTED"
        },
        force_events = true,
        name = L["Cooldown Progress (Item)"],
        init = function(trigger)
            trigger.itemName = trigger.itemName or 0;
            local itemName = (type(trigger.itemName) == "number" and trigger.itemName or 0);
            WeakAuras.WatchItemCooldown(trigger.itemName);
            local ret = [[
local startTime, duration = WeakAuras.GetItemCooldown(%s);
local inverse = %s;
]];
            return ret:format(itemName, (trigger.use_inverse and "true" or "false"));
        end,
        args = {
            {
                name = "itemName",
				required = true,
                display = L["Item"],
                type = "item",
				init = "arg"
            },
            {
                name = "inverse",
                display = L["Inverse"],
                type = "toggle",
                test = "true"
            },
			{
				hidden = true,
				test = "(inverse and startTime == 0) or (not inverse and startTime > 0)"
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
        automaticrequired = true
    },
    ["Cooldown Ready (Item)"] = {
        type = "event",
        events = {
            "ITEM_COOLDOWN_READY"
        },
        name = L["Cooldown Ready (Item)"],
        init = function(trigger)
            trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
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
        end
    },
    ["Action Usable"] = {
        type = "status",
        events = {
            "SPELL_UPDATE_USABLE",
            "PLAYER_TARGET_CHANGED",
            "SPELL_UPDATE_COOLDOWN",
            "UNIT_POWER",
            "ACTIONBAR_UPDATE_COOLDOWN"
        },
        force_events = true,
        name = L["Action Usable"],
        init = function(trigger)
            trigger.spellName = trigger.spellName or 0;
            local spellName = type(trigger.spellName) == "number" and trigger.spellName or "'"..trigger.spellName.."'";
            local ret = [[
local spell = %s;
local spellName = GetSpellInfo(spell);
local startTime, duration = GetSpellCooldown(spellName);
startTime = startTime or 0;
duration = duration or 0;
onCooldown = duration > 1.51;
]]
            return ret:format(spellName);
        end,
        args = {
            {
                name = "spellName",
                display = L["Spell"],
                type = "spell",
                test = "IsUsableSpell(spell) and not onCooldown"
            },
            --This parameter uses the IsSpellInRange API function, but it does not check spell range at all
            --IsSpellInRange returns nil for invalid targets, 0 for out of range, 1 for in range (0 and 1 are both "positive" values)
            {
                name = "targetRequired",
                display = L["Require Valid Target"],
                type = "toggle",
                test = "IsSpellInRange(spellName or '')"
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
        automaticrequired = true
    },
    ["Totem"] = {
        type = "status",
        events = {
            "PLAYER_TOTEM_UPDATE"
        },
        force_events = true,
        name = L["Totem"],
        init = function(trigger)
            trigger.totemType = trigger.totemType or 1;
            local ret = [[
local totemType = %i;
local _, totemName, startTime, duration = GetTotemInfo(totemType);
]]
            return ret:format(trigger.totemType);
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
            },
            {
                hidden = true,
                test = "startTime ~= 0"
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
        type = "status",
        events = {
            "BAG_UPDATE",
            "UNIT_SPELLCAST_SUCCEEDED"
        },
        force_events = true,
        name = L["Item Count"],
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
        automaticrequired = true
    },
    ["Stance/Form/Aura"] = {
        type = "status",
        events = {
            "UPDATE_SHAPESHIFT_FORM"
        },
        force_events = true,
        name = L["Stance/Form/Aura"],
        init = function()
        return "local form = GetShapeshiftForm();\n local _, class = UnitClass('player');\n"
        end,
        args = {
            {
                name = "form",
                display = L["Form"],
                type = "select",
                values = "form_types",
                test = "form == %s"
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
        name = L["Weapon Enchant"],
        init = function(trigger)
            WeakAuras.TenchInit();
            return "local weapon = '"..(trigger.weapon or "none").."'\n";
        end,
        args = {
            {
                name = "weapon",
                display = L["Weapon"],
                type = "select",
                values = "weapon_types",
                test = "(weapon == 'main' and WeakAuras.GetMHTenchInfo() or weapon == 'off' and WeakAuras.GetOHTenchInfo())"
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
            "CHAT_MSG_BATTLEGROUND",
            "CHAT_MSG_BATTLEGROUND_LEADER",
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
    ["Death Knight Rune"] = {
        type = "status",
        events = {
            "RUNE_POWER_UPDATE",
            "RUNE_TYPE_UPDATE"
        },
        force_events = true,
        name = L["Death Knight Rune"],
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
            if(startTime and startTime > 0) then
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
        type = "status",
        events = {
            "UNIT_INVENTORY_CHANGED"
        },
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
        type = "status",
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