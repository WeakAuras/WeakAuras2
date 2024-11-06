if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

local removeFuncs = OptionsPrivate.commonOptions.removeFuncs
local replaceNameDescFuncs = OptionsPrivate.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = OptionsPrivate.commonOptions.replaceImageFuncs
local replaceValuesFuncs = OptionsPrivate.commonOptions.replaceValuesFuncs
local disabledAll = OptionsPrivate.commonOptions.CreateDisabledAll("load")
local hiddenAll = OptionsPrivate.commonOptions.CreateHiddenAll("load")
local getAll = OptionsPrivate.commonOptions.CreateGetAll("load")
local setAll = OptionsPrivate.commonOptions.CreateSetAll("load", getAll)

local ValidateNumeric = WeakAuras.ValidateNumeric;

local spellCache = WeakAuras.spellCache;

local function CorrectSpellName(input)
  local inputId = tonumber(input)
  if(inputId) then
    return inputId
  elseif WeakAuras.IsClassicEra() and input then
    local _, _, _, _, _, _, spellId = OptionsPrivate.Private.ExecEnv.GetSpellInfo(input)
    if spellId then
      return spellId
    end
  elseif(input) then
    local link;
    if(input:sub(1,1) == "\124") then
      link = input;
    else
      link = (GetSpellLink and GetSpellLink(input)) or (C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(input));
    end
    if(link) and link ~= "" then
      local itemId = link:match("spell:(%d+)");
      return tonumber(itemId);
    else
      local spells = spellCache.GetSpellsMatching(input)
      if type(spells) == "table" then
        for id in pairs(spells) do
          if IsPlayerSpell(id) then
            return id
          end
        end
        return next(spells)
      end
    end
  end
end

local function CorrectItemName(input)
  local inputId = tonumber(input);
  if(inputId) then
    return inputId;
  elseif(input) then
    local _, link = C_Item.GetItemInfo(input);
    if(link) then
      local itemId = link:match("item:(%d+)");
      return tonumber(itemId);
    end
  end
end

-- Also used by the GenericTrigger

local function getValue(trigger, preCheckField, field, multiEntry, entryNumber, tristate)
  if preCheckField then
    if tristate then
      if trigger[preCheckField] ~= nil then
        return nil
      end
    else
      if not trigger[preCheckField] then
        return nil
      end
    end
  end
  if multiEntry then
    return type(trigger[field]) == "table" and trigger[field][entryNumber] or nil
  else
    return trigger[field] or nil
  end
end

local function shiftTable(tbl, pos)
  local size = #tbl
  for i = pos, size, 1 do
    tbl[i] = tbl[i + 1]
  end
end

local function setValue(trigger, field, value, multiEntry, entryNumber)
  if multiEntry then
    if type(trigger[field]) ~= "table" then
      if trigger[field] == nil then
        trigger[field] = {}
      else
        trigger[field] = { trigger[field] }
      end
    end
    if value == "" or value == nil then
      shiftTable(trigger[field], entryNumber)
    else
      trigger[field][entryNumber] = value
    end
  else
    trigger[field] = value
  end
end

function OptionsPrivate.ConstructOptions(prototype, data, startorder, triggernum, triggertype)
  local trigger
  -- For load options only the hidden property counts, but for the generic trigger
  -- we look at enabled.
  local hiddenProperty = triggertype == "load" and "hidden" or "enable"
  if(data.controlledChildren) then
    trigger = {}
  elseif(triggertype == "load") then
    trigger = data.load;
  elseif data.triggers[triggernum] then
    trigger = data.triggers[triggernum].trigger
  else
    error("Improper argument to OptionsPrivate.ConstructOptions - trigger number not in range");
  end
  local options = {};
  local order = startorder or 10;

  local isCollapsedFunctions;
  local positionsForCollapseAnchor = {}
  for index, arg in pairs(prototype.args) do
    local hidden = nil;
    if(type(arg.sortOrder) == "function") then
      arg.sortOrder = arg.sortOrder()
    end
    if(arg.collapse and isCollapsedFunctions[arg.collapse] and type(arg[hiddenProperty]) == "function") then
      local isCollapsed = isCollapsedFunctions[arg.collapse]
      if hiddenProperty == "hidden" then
        hidden = function() return isCollapsed() or arg[hiddenProperty](trigger) end
      else
        hidden = function() return isCollapsed() or not arg[hiddenProperty](trigger) end
      end
    elseif type(arg[hiddenProperty]) == "function" then
      if hiddenProperty == "hidden" then
        hidden = function() return arg[hiddenProperty](trigger) end
      else
        hidden = function() return not arg[hiddenProperty](trigger) end
      end
    elseif type(arg[hiddenProperty]) == "boolean" then
      if hiddenProperty == "hidden" then
        hidden = arg[hiddenProperty]
      else
        hidden = not arg[hiddenProperty]
      end
    elseif(arg.collapse and isCollapsedFunctions[arg.collapse]) then
      hidden = isCollapsedFunctions[arg.collapse]
    end
    local name = arg.name;
    local validate = arg.validate;
    local reloadOptions = arg.reloadOptions or arg.multiEntry ~= nil
    if (name and arg.type == "collapse") then
      options["summary_" .. arg.name] = {
        type = "execute",
        control = "WeakAurasExpandSmall",
        width = WeakAuras.doubleWidth,
        name = type(arg.display) == "function" and arg.display(trigger) or arg.display,
        order = order,
        image = function()
          local collapsed = OptionsPrivate.IsCollapsed("trigger", name, "", true)
          return collapsed and "collapsed" or "expanded"
        end,
        imageWidth = 15,
        imageHeight = 15,
        func = function(info, button, secondCall)
          if not secondCall then
            local collapsed = OptionsPrivate.IsCollapsed("trigger", name, "", true)
            OptionsPrivate.SetCollapsed("trigger", name, "", not collapsed)
          end
        end,
        arg = {
          expanderName = triggernum .. "#" .. tostring(prototype) .. "#"  .. name
        }
      }
      order = order + 1;

      isCollapsedFunctions = isCollapsedFunctions or {};
      isCollapsedFunctions[name] = function()
        return OptionsPrivate.IsCollapsed("trigger", name, "", true);
      end
    elseif name and (hiddenProperty == "hidden" or not arg.hidden) then
      local realname = name;
      if (arg.type == "multiselect") then
        -- Ensure new line for non-toggle options
        options["spacer_"..name] = {
          type = "description",
          width = WeakAuras.doubleWidth,
          name = "",
          order = order,
          hidden = hidden,
        }
        order = order + 1;
      end
      if(arg.type == "tristate" or arg.type == "tristatestring") then
        options["use_"..name] = {
          type = "toggle",
          width = WeakAuras.normalWidth,
          name = function(input)
            local value = trigger["use_"..realname];
            if(value == nil) then return arg.display;
            elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..arg.display.."|r";
            else return "|cFF00FF00"..arg.display.."|r"; end
          end,
          desc = arg.desc,
          get = function()
            local value = trigger["use_"..realname];
            if(value == nil) then return false;
            elseif(value == false) then return "false";
            else return "true"; end
          end,
          set = function(info, v)
            if(v) then
              trigger["use_"..realname] = true;
            else
              local value = trigger["use_"..realname];
              if(value == false) then
                trigger["use_"..realname] = nil;
              else
                trigger["use_"..realname] = false
              end
            end
            WeakAuras.Add(data);
            WeakAuras.ClearAndUpdateOptions(data.id)
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end,
          hidden = hidden,
          order = order
        };
      elseif(arg.type == "multiselect") then
        options["use_"..name] = {
          type = "toggle",
          width = WeakAuras.normalWidth,
          name = arg.display,
          desc = function()
            if arg.multiNoSingle or arg.desc then return arg.desc end
            local v = trigger["use_"..realname];
            if(v == true) then
              return L["Multiselect single tooltip"];
            elseif(v == false) then
              return L["Multiselect multiple tooltip"];
            else
              return L["Multiselect ignored tooltip"];
            end
          end,
          get = function()
            local value = trigger["use_"..realname];
            if arg.multiNoSingle then
              if value == nil then
                return false;
              else
                return "false"
              end
            else
              if(value == nil) then return false;
              elseif(value == false) then return "false";
              else return "true"; end
            end
          end,
          set = function(info, v)
            if arg.multiNoSingle then
              trigger[realname] = trigger[realname] or {};
              trigger[realname].multi = trigger[realname].multi or {};
              if v == true then
                trigger["use_"..realname] = false;
              else
                trigger["use_"..realname] = nil;
              end
            else
              if v then
                trigger["use_"..realname] = true;
              else
                local value = trigger["use_"..realname];
                if(value == false) then
                  trigger["use_"..realname] = nil;
                else
                  trigger["use_"..realname] = false
                  trigger[realname] = trigger[realname] or {};
                  if(trigger[realname].single) then
                    trigger[realname].multi = trigger[realname].multi or {};
                    trigger[realname].multi[trigger[realname].single] = true;
                  end
                end
              end
            end
            WeakAuras.Add(data);
            WeakAuras.ClearAndUpdateOptions(data.id)
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end,
          hidden = hidden,
          order = order
        };
      elseif (arg.type == "description") then
        options["description_space_"..name] = {
          type = "description",
          width = WeakAuras.doubleWidth,
          name = "",
          order = order,
          hidden = hidden,
        }
        order = order + 1;
        options["description_title_"..name] = {
          type = "description",
          width = WeakAuras.doubleWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          fontSize = "large",
        }
        order = order + 1;
        options["description_"..name] = {
          type = "description",
          width = WeakAuras.doubleWidth,
          name = arg.text,
          order = order,
          hidden = hidden,
        }
        order = order + 1;
      elseif (arg.type == "header") then
        options["header_"..name] = {
          type = "header",
          width = WeakAuras.doubleWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
        }
        order = order + 1
      else
        options["use_"..name] = {
          type = "toggle",
          width = arg.width or WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          desc = arg.desc,
          get = function() return trigger["use_"..realname]; end,
          set = function(info, v)
            trigger["use_"..realname] = v;
            WeakAuras.Add(data);
            WeakAuras.ClearAndUpdateOptions(data.id)
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        };
      end
      if(arg.type == "toggle" or arg.type == "tristate") then
        options["use_"..name].width = arg.width or WeakAuras.doubleWidth;
      end
      if(arg.type == "spell" or arg.type == "aura" or arg.type == "item") then
        if not arg.showExactOption then
          options["use_"..name].width = (arg.width or WeakAuras.normalWidth) - 0.2;
        end
      end

      if(arg.type == "toggle") then
        options["use_"..name].desc = arg.desc;
      end
      if(arg.required) then
        if arg.type == "multiselect" and arg.multiNoSingle then
          trigger["use_"..realname] = false
        else
          trigger["use_"..realname] = true
        end
        if not(triggertype) then
          options["use_"..name].disabled = true;
        else
          options["use_"..name] = nil;
          order = order - 1;
        end
      end
      order = order + 1;

      local countEntries = 0
      local multiEntry = arg.multiEntry ~= nil
      if multiEntry then
        if type(trigger[realname]) == "table" then
          countEntries = #trigger[realname]
        elseif trigger[realname] ~= nil then
          countEntries = 1
        end
      end

      for entryNumber = 1, countEntries + 1 do
        if arg.multiEntry then
          if arg.multiEntry.limit and entryNumber > arg.multiEntry.limit then
            break
          end
          if entryNumber > 1 then
            if arg.type == "tristate" or arg.type == "tristatestring" then
              if trigger["use_"..realname] == nil then
                break
              end
            else
              if not trigger["use_"..realname] then
                break
              end
            end
          end
        end

        local suffix = multiEntry and entryNumber or ""
        if entryNumber > 1 then
          options["spacer_"..name..suffix] = {
            type = "execute",
            name = arg.multiEntry.operator == "and" and L["and"] or L["or"],
            image = function() return "", 0, 0 end,
            order = order,
            hidden = hidden,
          }
          order = order + 1
        end

        if(arg.type == "number") then
          if entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth
          end
          local disabled = not trigger["use_"..realname]
          options[name..suffix .. "dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1
          if (not arg.noOperator) then
            options[name.."_operator"..suffix] = {
              type = "select",
              width = WeakAuras.halfWidth,
              name = L["Operator"],
              order = order,
              hidden = disabled or hidden,
              values = arg.operator_types == "without_equal" and OptionsPrivate.Private.operator_types_without_equal
                       or arg.operator_types == "only_equal" and OptionsPrivate.Private.equality_operator_types
                       or OptionsPrivate.Private.operator_types,

              get = function()
                return getValue(trigger, "use_"..realname, realname.."_operator", multiEntry, entryNumber)
              end,
              set = function(info, v)
                setValue(trigger, realname.."_operator", v, multiEntry, entryNumber)
                WeakAuras.Add(data);
                if (reloadOptions) then
                  WeakAuras.ClearAndUpdateOptions(data.id)
                end
                OptionsPrivate.Private.ScanForLoads({[data.id] = true});
                WeakAuras.UpdateThumbnail(data);
                OptionsPrivate.SortDisplayButtons(nil, true);
              end
            };
            order = order + 1;
          end
          options[name..suffix] = {
            type = "input",
            width = arg.noOperator and WeakAuras.normalWidth or WeakAuras.halfWidth,
            validate = ValidateNumeric,
            name = arg.display,
            order = order,
            hidden = disabled or hidden,
            desc = arg.desc,
            get = function() return getValue(trigger, "use_"..realname, realname, multiEntry, entryNumber) end,
            set = function(info, v)
              setValue(trigger, realname, v, multiEntry, entryNumber)
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          order = order + 1;
        elseif(arg.type == "string" or arg.type == "tristatestring") then
          if not arg.multiline and entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth
          end

          local disabled
          if arg.type == "string" then
            disabled = not trigger["use_"..realname]
          else
            disabled = trigger["use_"..realname] == nil
          end

          options[name..suffix.."dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1
          options[name..suffix] = {
            type = "input",
            width = arg.multiline and WeakAuras.doubleWidth or WeakAuras.normalWidth,
            name = arg.display,
            order = order,
            hidden = disabled or hidden,
            validate = validate,
            desc = arg.desc,
            multiline = arg.multiline,
            control = arg.multiline and "WeakAuras-MultiLineEditBoxWithEnter" or nil,
            get = function()
              return getValue(trigger, "use_"..realname, realname, multiEntry, entryNumber, arg.type == "tristatestring")
            end,
            set = function(info, v)
              setValue(trigger, realname, v, multiEntry, entryNumber)
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          order = order + 1
        elseif(arg.type == "longstring") then
          if entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth
          end
          local disabled = not trigger["use_"..realname]
          options[name..suffix.."dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1;
          options[name.."_operator"..suffix] = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = L["Operator"],
            order = order,
            hidden = disabled or hidden,
            values = OptionsPrivate.Private.string_operator_types,
            get = function() return getValue(trigger, "use_"..realname, realname.."_operator", multiEntry, entryNumber) end,
            set = function(info, v)
              setValue(trigger, realname.."_operator", v, multiEntry, entryNumber)
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          order = order + 1;
          options[name..suffix] = {
            type = "input",
            width = arg.canBeCaseInsensitive and WeakAuras.normalWidth or WeakAuras.doubleWidth,
            name = arg.display,
            order = order,
            hidden = disabled or hidden,
            validate = validate,
            get = function() return getValue(trigger, "use_"..realname, realname, multiEntry, entryNumber) end,
            set = function(info, v)
              setValue(trigger, realname, v, multiEntry, entryNumber)
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          order = order + 1;
          if arg.canBeCaseInsensitive then
            options[name.."_caseInsensitive"..suffix] = {
              type = "toggle",
              width = WeakAuras.normalWidth,
              name = L["Case Insensitive"],
              order = order,
              hidden = disabled or hidden,
              get = function() return getValue(trigger, "use_"..realname, realname.."_caseInsensitive", multiEntry, entryNumber) end,
              set = function(info, v)
                setValue(trigger, realname.."_caseInsensitive", v, multiEntry, entryNumber)
                WeakAuras.Add(data);
                if (reloadOptions) then
                  WeakAuras.ClearAndUpdateOptions(data.id)
                end
                OptionsPrivate.Private.ScanForLoads({[data.id] = true});
                WeakAuras.UpdateThumbnail(data);
                OptionsPrivate.SortDisplayButtons(nil, true);
              end
            };
            order = order + 1;
          end
        elseif(arg.type == "spell" or arg.type == "aura" or arg.type == "item") then
          if entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth - (arg.showExactOption and 0 or 0.2)
          end
          local disabled = not trigger["use_"..realname]
          options[name..suffix.."dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1
          if (arg.showExactOption) then
            options["exact"..name..suffix] = {
              type = "toggle",
              width = WeakAuras.normalWidth,
              name = arg.type == "item" and L["Exact Item Match"] or L["Exact Spell Match"],
              order = order,
              hidden = disabled or hidden,
              get = function()
                return getValue(trigger, nil, "use_exact_"..realname, multiEntry, entryNumber)
              end,
              set = function(info, v)
                setValue(trigger, "use_exact_"..realname, v, multiEntry, entryNumber)
                WeakAuras.Add(data);
                OptionsPrivate.Private.ScanForLoads({[data.id] = true});
                WeakAuras.UpdateThumbnail(data);
                OptionsPrivate.SortDisplayButtons(nil, true);
              end,
            };
            order = order + 1;
          end
          options["icon"..name..suffix] = {
            type = "execute",
            width = 0.2,
            name = "",
            order = order,
            hidden = disabled or hidden,
            image = function()
              local value = getValue(trigger, "use_"..realname, realname, multiEntry, entryNumber)
              if value then
                if(arg.type == "aura") then
                  local icon = spellCache.GetIcon(value);
                  return icon and tostring(icon) or "", 18, 18;
                elseif(arg.type == "spell") then
                  if arg.negativeIsEJ and WeakAuras.IsRetail() then
                    local key = WeakAuras.SafeToNumber(value)
                    if key and key < 0 then
                      local tbl = C_EncounterJournal.GetSectionInfo(-key)
                      if tbl and tbl.abilityIcon then
                        return tostring(tbl.abilityIcon) or "", 18, 18;
                      end
                    end
                  end
                  local icon = OptionsPrivate.Private.ExecEnv.GetSpellIcon(value);
                  return icon and tostring(icon) or "", 18, 18;
                elseif(arg.type == "item") then
                  local _, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(value);
                  return icon and tostring(icon) or "", 18, 18;
                end
              else
                return "", 18, 18;
              end
            end,
            disabled = function()
              local value = getValue(trigger, nil, realname, multiEntry, entryNumber)
              return not ((arg.type == "aura" and value and spellCache.GetIcon(value)) or (arg.type == "spell" and value and OptionsPrivate.Private.ExecEnv.GetSpellName(value)) or (arg.type == "item" and value and C_Item.GetItemIconByID(value or '')))
            end
          };
          order = order + 1;
          options[name..suffix] = {
            type = "input",
            width = (arg.showExactOption and WeakAuras.doubleWidth or WeakAuras.normalWidth) - (arg.showExactOption and 0.2 or 0),
            name = arg.display,
            order = order,
            hidden = disabled or hidden,
            validate = validate,
            get = function()
              local value = getValue(trigger, "use_"..realname, realname, multiEntry, entryNumber)
              if(arg.type == "item") then
                local useExactSpellId = (arg.showExactOption and getValue(trigger, nil, "use_exact_"..realname, multiEntry, entryNumber))
                if value and value ~= "" then
                  if useExactSpellId then
                    local itemId = tonumber(value)
                    if itemId and itemId ~= 0 then
                      local itemName = C_Item.GetItemInfo(value)
                      if itemName then
                        return ("%s (%s)"):format(itemId, itemName) .. "\0" .. value
                      end
                      return tostring(value)
                    end
                  else
                    local name = C_Item.GetItemInfo(value);
                    if name then
                      return name;
                    end
                  end
                  return (useExactSpellId and L["Invalid Item ID"] or L["Invalid Item Name/ID/Link"]) .. "\0"
                else
                  return nil;
                end
              elseif(arg.type == "spell") then
                local useExactSpellId = (arg.showExactOption and getValue(trigger, nil, "use_exact_"..realname, multiEntry, entryNumber))
                if value and value ~= "" then
                  local spellID = WeakAuras.SafeToNumber(value)
                  if spellID then
                    if arg.negativeIsEJ and WeakAuras.IsRetail() and spellID < 0 then
                      local tbl = C_EncounterJournal.GetSectionInfo(-spellID)
                      if tbl and tbl.title then
                        return ("%s (%s)"):format(spellID, tbl.title) .. "\0" .. value
                      end
                      return ("%s (%s)"):format(spellID, L["Unknown Encounter's Spell Id"]) .. "\0" .. value
                    end
                    local spellName = OptionsPrivate.Private.ExecEnv.GetSpellName(spellID)
                    if spellName then
                      return ("%s (%s)"):format(spellID, spellName) .. "\0" .. value
                    end
                    return ("%s (%s)"):format(spellID, L["Unknown Spell"]) .. "\0" .. value
                  elseif not useExactSpellId and not arg.noValidation then
                    local spellName = OptionsPrivate.Private.ExecEnv.GetSpellName(value)
                    if spellName then
                      return spellName
                    end
                  end
                end
                if arg.noValidation then
                  return value and tostring(value)
                end
                if value == nil then
                  return nil
                end
                return (useExactSpellId and L["Invalid Spell ID"] or L["Invalid Spell Name/ID/Link"]) .. "\0"
              else
                return value or nil
              end
            end,
            set = function(info, v)
              local fixedInput = v;
              if not arg.noValidation then
                if(arg.type == "aura") then
                  fixedInput = WeakAuras.spellCache.CorrectAuraName(v);
                elseif(arg.type == "spell") then
                  fixedInput = CorrectSpellName(v);
                elseif(arg.type == "item") then
                  fixedInput = CorrectItemName(v);
                end
              end
              setValue(trigger, realname, fixedInput, multiEntry, entryNumber)
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end,
            control = "WeakAurasInputFocus",
          };
          order = order + 1;
        elseif(arg.type == "select" or arg.type == "unit" or arg.type == "currency") then
          if entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth
          end

          local disabled = not trigger["use_"..realname]
          options[name..suffix.."dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1
          local values;
          if(type(arg.values) == "function") then
            values = arg.values(trigger);
          else
            if OptionsPrivate.Private[arg.values] then
              values = OptionsPrivate.Private[arg.values]
            else
              values = WeakAuras[arg.values];
            end
          end
          local sortOrder = arg.sorted and (arg.sortOrder or OptionsPrivate.Private.SortOrderForValues(values)) or nil
          options[name..suffix] = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = arg.display,
            order = order,
            hidden = disabled or hidden,
            values = values,
            sorting = sortOrder,
            desc = arg.desc,
            itemControl = arg.itemControl,
            headers = arg.headers,

            get = function()
              if((arg.type == "unit" or arg.type == "currency") and trigger["use_specific_"..realname]) then
                return "member";
              end

              if (not trigger["use_"..realname]) then
                return nil;
              end

              if (arg.default and (not trigger[realname] or not values[trigger[realname]])) then
                trigger[realname] = arg.default;
                return arg.default;
              end

              return trigger[realname] or nil;
            end,
            set = function(info, v)
              setValue(trigger, realname, v, multiEntry, entryNumber)
              if((arg.type == "unit" or arg.type == "currency") and v == "member") then
                trigger["use_specific_"..realname] = true;
                trigger[realname] = arg.type == "unit" and UnitName("player") or nil;
              else
                trigger["use_specific_"..realname] = nil;
              end
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          if (arg.control) then
            options[name .. suffix].control = arg.control;
          end
          order = order + 1;
          if(arg.type == "unit" or arg.type == "currency") then
            local specificName = arg.type == "unit" and L["Specific Unit"] or L["Specific Currency ID"];
            local specificDesc = arg.type == "unit" and L["Can be a UID (e.g., party1)."] or nil;
            options["use_specific_"..name..suffix] = {
              type = "toggle",
              width = WeakAuras.normalWidth,
              name = specificName,
              order = order,
              hidden = disabled or function()
                return (not trigger["use_specific_"..realname] and trigger[realname] ~= "member")
                      or (type(hidden) == "function" and hidden(trigger))
                      or (type(hidden) ~= "function" and hidden)
                end,
              get = function() return true end,
              set = function(info, v)
                trigger["use_specific_"..realname] = nil;
                options[name .. suffix].set(info, "player");
                WeakAuras.Add(data)
              end
            }
            order = order + 1;
            options["specific_"..name..suffix] = {
              type = "input",
              width = WeakAuras.normalWidth,
              name = specificName,
              desc = specificDesc,
              order = order,
              validate = arg.type == "currency" and WeakAuras.ValidateNumeric or false,
              hidden = disabled or function() return (not trigger["use_specific_"..realname] and trigger[realname] ~= "member") or (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) end,
              get = function() return trigger[realname] end,
              set = function(info, v)
                trigger[realname] = v;
                WeakAuras.Add(data);
                if (reloadOptions) then
                  WeakAuras.ClearAndUpdateOptions(data.id)
                end
              end
            };
            order = order + 1;
          end
        elseif(arg.type == "multiselect") then
          if entryNumber > 1 then
            options["spacer_"..name..suffix].width = WeakAuras.normalWidth
          end
          local disabled = trigger["use_"..realname] == nil
          options[name..suffix.."dummy"] = {
            type = "description",
            name = "",
            width = WeakAuras.normalWidth,
            order = order,
            hidden = not disabled or hidden,
            hiddenAllIfAnyHidden = true
          }
          order = order + 1
          local values;
          if(type(arg.values) == "function") then
            values = arg.values(trigger);
          else
            if OptionsPrivate.Private[arg.values] then
              values = OptionsPrivate.Private[arg.values]
            else
              values = WeakAuras[arg.values];
            end
          end
          local sortOrder = arg.sorted and (arg.sortOrder or OptionsPrivate.Private.SortOrderForValues(values)) or nil
          options[name..suffix] = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = arg.display,
            order = order,
            values = values,
            sorting = sortOrder,
            control = arg.control,
            hidden = disabled or function()
              return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] == false;
            end,
            get = function() return trigger["use_"..realname] and trigger[realname] and trigger[realname].single or nil; end,
            set = function(info, v)
              trigger[realname] = trigger[realname] or {};
              trigger[realname].single = v;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };

          if arg.extraOption then
            options["multiselect_extraOption_" .. name..suffix] =
            {
              name = arg.extraOption.display,
              type = "select",
              values = arg.extraOption.values,
              order = order,
              width = WeakAuras.normalWidth,
              hidden = disabled or function() return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] ~= false; end,
              get = function(info, v)
                return trigger[realname .. "_extraOption"] or 0
              end,
              set = function(info, v)
                trigger[realname .. "_extraOption"] = v
                WeakAuras.Add(data)
                OptionsPrivate.Private.ScanForLoads({[data.id] = true})
                OptionsPrivate.SortDisplayButtons(nil, true)
              end
            }
            order = order + 1
          end

          options["multiselect_"..name..suffix] = {
            type = "multiselect",
            name = arg.display,
            width = WeakAuras.doubleWidth,
            order = order,
            hidden = disabled or function() return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] ~= false; end,
            values = values,
            control = arg.multiUseControlWhenFalse and arg.control,
            multiTristate = arg.multiTristate,
            get = function(info, v)
              if(trigger["use_"..realname] == false and trigger[realname] and trigger[realname].multi) then
                if arg.multiConvertKey then
                  v = arg.multiConvertKey(trigger, v)
                end
                if v then
                  return trigger[realname].multi[v];
                end
              end
            end,
            set = function(info, v, calledFromSetAll)
              if arg.multiConvertKey then
                v = arg.multiConvertKey(trigger, v)
              end
              if v then
                trigger[realname] = trigger[realname] or {}
                trigger[realname].multi = trigger[realname].multi or {};
                if (calledFromSetAll or arg.multiTristate) then
                  trigger[realname].multi[v] = calledFromSetAll;
                elseif(trigger[realname].multi[v]) then
                  trigger[realname].multi[v] = nil;
                else
                  trigger[realname].multi[v] = true;
                end
                WeakAuras.Add(data);
                if (reloadOptions) then
                  -- Hack specifally for dragon flight mini talent
                  -- That widget needs to be informed before and
                  -- after a reload
                  OptionsPrivate.Private.callbacks:Fire("BeforeReload")
                  WeakAuras.ClearAndUpdateOptions(data.id)
                  WeakAuras.FillOptions()
                  OptionsPrivate.Private.callbacks:Fire("AfterReload")
                end
                OptionsPrivate.Private.ScanForLoads({[data.id] = true});
                WeakAuras.UpdateThumbnail(data);
                OptionsPrivate.SortDisplayButtons(nil, true);
              end
            end
          };
          order = order + 1;
        end
      end
    end

    if(arg.collapse and isCollapsedFunctions[arg.collapse]) then
      positionsForCollapseAnchor[arg.collapse] = order
      order = order +1
    end
  end

  if prototype.countEvents then
    options.use_count = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = WeakAuras.newFeatureString .. L["Count"],
      order = order,
      get = function()
        return trigger.use_count
      end,
      set = function(info, v)
        trigger.use_count = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    };
    order = order + 1;

    local disabled = not trigger.use_count
    if disabled then
      options.countDummy = {
        type = "description",
        name = "",
        width = WeakAuras.normalWidth,
        order = order,
        hidden = not disabled,
        hiddenAllIfAnyHidden = true
      }
      order = order + 1
    else
      options.count = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Count"],
        desc = L["Occurrence of the event, reset when aura is unloaded\nCan be a range of values\nCan have multiple values separated by a comma or a space\n\nExamples:\n2nd 5th and 6th events: 2, 5, 6\n2nd to 6th: 2-6\nevery 2 events: /2\nevery 3 events starting from 2nd: 2/3\nevery 3 events starting from 2nd and ending at 11th: 2-11/3"],
        order = order,
        get = function()
          return trigger.count
        end,
        set = function(info, v)
          trigger.count = v
          WeakAuras.Add(data)
        end,
        hidden = disabled
      };
      order = order + 1;
    end
  end
  if prototype.delayEvents then
    options.use_delay = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = WeakAuras.newFeatureString .. L["Delay"],
      order = order,
      get = function()
        return trigger.use_delay
      end,
      set = function(info, v)
        trigger.use_delay = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    };
    order = order + 1;

    local disabled = not trigger.use_delay
    if disabled then
      options.delayDummy = {
        type = "description",
        name = "",
        width = WeakAuras.normalWidth,
        order = order,
        hiddenAllIfAnyHidden = true
      }
      order = order + 1
    else
      options.delay = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Delay"],
        order = order,

        validate = WeakAuras.ValidateTime,
        get = function()
          return OptionsPrivate.Private.tinySecondFormat(trigger.delay)
        end,
        set = function(info, v)
          trigger.delay = WeakAuras.TimeToSeconds(v)
          WeakAuras.Add(data)
        end
      };
      order = order + 1;
    end
  end
  if prototype.timedrequired then
    options.unevent = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hide"],
      order = order,
      values = OptionsPrivate.Private.timedeventend_types,
      get = function()
        return "timed"
      end,
      set = function(info, v)
        -- unevent is no longer used
      end
    };
    order = order + 1;

    options.duration = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Duration (s)"],
      validate = WeakAuras.ValidateTime,
      order = order,
      get = function()
        return OptionsPrivate.Private.tinySecondFormat(trigger.duration)
      end,
      set = function(info, v)
        trigger.duration = tostring(WeakAuras.TimeToSeconds(v))
        WeakAuras.Add(data)
      end
    }
    order = order + 1;
  end

  for name, order in pairs(positionsForCollapseAnchor) do
    options[name .. "anchor"] = {
      type = "description",
      name = "",
      control = "WeakAurasExpandAnchor",
      order = order,
      arg = {
        expanderName = triggernum .. "#" .. tostring(prototype) .. "#"  .. name
      },
      hidden = isCollapsedFunctions[name]
    }
  end

  return options;
end

function OptionsPrivate.GetLoadOptions(data)
  local load = {
    type = "group",
    name = L["Load"],
    order = 0,
    get = function(info) return data.load[info[#info]] end,
    set = function(info, v)
        data.load[info[#info]] = (v ~= "" and v) or nil;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        OptionsPrivate.Private.ScanForLoads({[data.id] = true});
        OptionsPrivate.SortDisplayButtons(nil, true);
      end,
      args = {}
    }

    load.args = OptionsPrivate.ConstructOptions(OptionsPrivate.Private.load_prototype, data, 10, nil, "load");

    if(data.controlledChildren) then
      removeFuncs(load);
      replaceNameDescFuncs(load, data, "load");
      replaceImageFuncs(load, data, "load");
      replaceValuesFuncs(load, data, "load");

      load.get = function(info, ...) return getAll(data, info, ...); end;
      load.set = function(info, ...)
        setAll(data, info, ...);
        if(type(data.id) == "string") then
          WeakAuras.Add(data);
          WeakAuras.UpdateThumbnail(data);
          OptionsPrivate.ResetMoverSizer();
        end
      end
      load.hidden = function(info, ...) return hiddenAll(data, info, ...); end;
      load.disabled = function(info, ...) return disabledAll(data, info, ...); end;
    end
    return load
end
