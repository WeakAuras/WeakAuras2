if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

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
  local inputId = tonumber(input);
  if(inputId) then
    local name = GetSpellInfo(inputId);
    if(name) then
      return inputId;
    else
      return nil;
    end
  elseif WeakAuras.IsClassic() and input then
    local _, _, _, _, _, _, spellId = GetSpellInfo(input)
    if spellId then
      return spellId
    end
  elseif(input) then
    local link;
    if(input:sub(1,1) == "\124") then
      link = input;
    else
      link = GetSpellLink(input);
    end
    if(link) and link ~= "" then
      local itemId = link:match("spell:(%d+)");
      return tonumber(itemId);
    elseif WeakAuras.IsRetail() then
      for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
          local _, _, _, _, _, spellId = GetTalentInfo(tier, column, 1)
          local name = GetSpellInfo(spellId);
          if name == input then
            return spellId;
          end
        end
      end
    end
  end
end

local function CorrectItemName(input)
  local inputId = tonumber(input);
  if(inputId) then
    return inputId;
  elseif(input) then
    local _, link = GetItemInfo(input);
    if(link) then
      local itemId = link:match("item:(%d+)");
      return tonumber(itemId);
    else
      return nil;
    end
  end
end

-- Also used by the GenericTrigger
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
    local reloadOptions = arg.reloadOptions;
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
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
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
            if arg.multiNoSingle then return arg.desc end
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
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
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
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
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
          options["use_"..name].width = arg.width or WeakAuras.normalWidth - 0.1;
        end
      end

      if(arg.type == "toggle") then
        options["use_"..name].desc = arg.desc;
      end
      if(arg.required) then
        trigger["use_"..realname] = true;
        if not(triggertype) then
          options["use_"..name].disabled = true;
        else
          options["use_"..name] = nil;
          order = order - 1;
        end
      end
      order = order + 1;
      if(arg.type == "number") then
        if (not arg.noOperator) then
          options[name.."_operator"] = {
            type = "select",
            width = WeakAuras.halfWidth,
            name = L["Operator"],
            order = order,
            hidden = hidden,
            values = arg.operator_types == "without_equal" and OptionsPrivate.Private.operator_types_without_equal or OptionsPrivate.Private.operator_types,
            disabled = function() return not trigger["use_"..realname]; end,
            get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
            set = function(info, v)
              trigger[realname.."_operator"] = v;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          };
          if(arg.required and not triggertype) then
            options[name.."_operator"].set = function(info, v)
              trigger[realname.."_operator"] = v;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          end
          order = order + 1;
        end
        options[name] = {
          type = "input",
          width = arg.noOperator and WeakAuras.normalWidth or WeakAuras.halfWidth,
          validate = ValidateNumeric,
          name = arg.display,
          order = order,
          hidden = hidden,
          desc = arg.desc,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] or nil; end,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end
        order = order + 1;
      elseif(arg.type == "string" or arg.type == "tristatestring") then
        options[name] = {
          type = "input",
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          validate = validate,
          desc = arg.desc,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        };

        if arg.type == "string" then
          options[name].disabled = function() return not trigger["use_"..realname] end
          options[name].get = function() return trigger["use_"..realname] and trigger[realname] or nil; end
        else
          options[name].disabled = function() return trigger["use_"..realname] == nil end
          options[name].get = function() return trigger["use_"..realname] ~= nil and trigger[realname] or nil; end
        end

        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end
        order = order + 1;
      elseif(arg.type == "longstring") then
        options[name.."_operator"] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = L["Operator"],
          order = order,
          hidden = hidden,
          values = OptionsPrivate.Private.string_operator_types,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
          set = function(info, v)
            trigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        };
        if(arg.required and not triggertype) then
          options[name.."_operator"].set = function(info, v)
            trigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end
        order = order + 1;
        options[name] = {
          type = "input",
          width = WeakAuras.doubleWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          validate = validate,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] or nil; end,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end
        order = order + 1;
      elseif(arg.type == "spell" or arg.type == "aura" or arg.type == "item") then
        if (arg.showExactOption) then
          options["exact"..name] = {
            type = "toggle",
            width = WeakAuras.normalWidth - 0.1,
            name = L["Exact Spell Match"],
            order = order,
            hidden = hidden,
            get = function()
              return trigger["use_exact_"..realname];
            end,
            set = function(info, v)
              trigger["use_exact_"..realname] = v;
              WeakAuras.Add(data);
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end,
          };
          order = order + 1;
        end
        options["icon"..name] = {
          type = "execute",
          width = 0.1,
          name = "",
          order = order,
          hidden = hidden,
          image = function()
            if(trigger["use_"..realname] and trigger[realname]) then
              if(arg.type == "aura") then
                local icon = spellCache.GetIcon(trigger[realname]);
                return icon and tostring(icon) or "", 18, 18;
              elseif(arg.type == "spell") then
                local _, _, icon = GetSpellInfo(trigger[realname]);
                return icon and tostring(icon) or "", 18, 18;
              elseif(arg.type == "item") then
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(trigger[realname]);
                return icon and tostring(icon) or "", 18, 18;
              end
            else
              return "", 18, 18;
            end
          end,
          disabled = function() return not ((arg.type == "aura" and trigger[realname] and spellCache.GetIcon(trigger[realname])) or (arg.type == "spell" and trigger[realname] and GetSpellInfo(trigger[realname])) or (arg.type == "item" and trigger[realname] and GetItemIcon(trigger[realname]))) end
        };
        order = order + 1;
        options[name] = {
          type = "input",
          width = arg.showExactOption and WeakAuras.doubleWidth or WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          validate = validate,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function()
            if(arg.type == "item") then
              if(trigger["use_"..realname] and trigger[realname] and trigger[realname] ~= "") then
                local name = GetItemInfo(trigger[realname]);
                if(name) then
                  return name;
                else
                  local itemId = tonumber(trigger[realname])
                  if itemId and itemId ~= 0 then
                    return tostring(trigger[realname])
                  end
                  return L["Invalid Item Name/ID/Link"];
                end
              else
                return nil;
              end
            elseif(arg.type == "spell") then
              local useExactSpellId = (arg.showExactOption and trigger["use_exact_"..realname])
              if(trigger["use_"..realname]) then
                if (trigger[realname] and trigger[realname] ~= "") then
                  if useExactSpellId then
                    local spellId = tonumber(trigger[realname])
                    if (spellId and spellId ~= 0) then
                      return tostring(spellId);
                    end
                  else
                    local name = GetSpellInfo(trigger[realname]);
                    if(name) then
                      return name;
                    end
                  end
                end
                return useExactSpellId and L["Invalid Spell ID"] or L["Invalid Spell Name/ID/Link"];
              else
                return nil;
              end
            else
              return trigger["use_"..realname] and trigger[realname] or nil;
            end
          end,
          set = function(info, v)
            local fixedInput = v;
            if(arg.type == "aura") then
              fixedInput = WeakAuras.spellCache.CorrectAuraName(v);
            elseif(arg.type == "spell") then
              fixedInput = CorrectSpellName(v);
            elseif(arg.type == "item") then
              fixedInput = CorrectItemName(v);
            end
            trigger[realname] = fixedInput;
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
      elseif(arg.type == "select" or arg.type == "unit") then
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
        local sortOrder = arg.sorted and OptionsPrivate.Private.SortOrderForValues(values) or nil
        options[name] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          values = values,
          sorting = sortOrder,
          desc = arg.desc,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function()
            if(arg.type == "unit" and trigger["use_specific_"..realname]) then
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
            trigger[realname] = v;
            if(arg.type == "unit" and v == "member") then
              trigger["use_specific_"..realname] = true;
              trigger[realname] = UnitName("player");
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
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            if(arg.type == "unit" and v == "member") then
              trigger["use_specific_"..realname] = true;
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
        end
        if (arg.control) then
          options[name].control = arg.control;
        end
        order = order + 1;
        if(arg.type == "unit") then
          options["use_specific_"..name] = {
            type = "toggle",
            width = WeakAuras.normalWidth,
            name = L["Specific Unit"],
            order = order,
            hidden = function() return (not trigger["use_specific_"..realname] and trigger[realname] ~= "member") or (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) end,
            get = function() return true end,
            set = function(info, v)
              trigger["use_specific_"..realname] = nil;
              options[name].set(info, "player");
              WeakAuras.Add(data)
            end
          }
          order = order + 1;
          options["specific_"..name] = {
            type = "input",
            width = WeakAuras.normalWidth,
            name = L["Specific Unit"],
            desc = L["Can be a UID (e.g., party1)."],
            order = order,
            hidden = function() return (not trigger["use_specific_"..realname] and trigger[realname] ~= "member") or (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) end,
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
        local sortOrder = arg.sorted and OptionsPrivate.Private.SortOrderForValues(values) or nil
        options[name] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          values = values,
          sorting = sortOrder,
          control = arg.control,
          hidden = function()
            return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] == false;
          end,
          disabled = function() return not trigger["use_"..realname]; end,
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
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname].single = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end

        if arg.extraOption then
          options["multiselect_extraOption_" .. name] =
          {
            name = arg.extraOption.display,
            type = "select",
            values = arg.extraOption.values,
            order = order,
            width = WeakAuras.normalWidth,
            hidden = function() return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] ~= false; end,
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

        options["multiselect_"..name] = {
          type = "multiselect",
          name = arg.display,
          width = WeakAuras.doubleWidth,
          order = order,
          hidden = function() return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] ~= false; end,
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
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              OptionsPrivate.Private.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              OptionsPrivate.SortDisplayButtons(nil, true);
            end
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            if(trigger[realname].multi[v]) then
              trigger[realname].multi[v] = nil;
            else
              trigger[realname].multi[v] = true;
            end
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            OptionsPrivate.Private.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            OptionsPrivate.SortDisplayButtons(nil, true);
          end
        end

        order = order + 1;
      end
    end

    if(arg.collapse and isCollapsedFunctions[arg.collapse]) then
      positionsForCollapseAnchor[arg.collapse] = order
      order = order +1
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
      order = order,
      get = function()
        return trigger.duration
      end,
      set = function(info, v)
        trigger.duration = v
        WeakAuras.Add(data)
      end,
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
