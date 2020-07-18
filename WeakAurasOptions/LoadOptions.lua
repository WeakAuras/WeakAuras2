local L = WeakAuras.L

local removeFuncs = WeakAuras.commonOptions.removeFuncs
local replaceNameDescFuncs = WeakAuras.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = WeakAuras.commonOptions.replaceImageFuncs
local replaceValuesFuncs = WeakAuras.commonOptions.replaceValuesFuncs
local disabledAll = WeakAuras.commonOptions.CreateDisabledAll("load")
local hiddenAll = WeakAuras.commonOptions.CreateHiddenAll("load")
local getAll = WeakAuras.commonOptions.CreateGetAll("load")
local setAll = WeakAuras.commonOptions.CreateSetAll("load", getAll)

local operator_types = WeakAuras.operator_types;
local operator_types_without_equal = WeakAuras.operator_types_without_equal;
local string_operator_types = WeakAuras.string_operator_types;
local ValidateNumeric = WeakAuras.ValidateNumeric;
local eventend_types = WeakAuras.eventend_types;
local timedeventend_types = WeakAuras.timedeventend_types;
local autoeventend_types = WeakAuras.autoeventend_types;


local spellCache = WeakAuras.spellCache;

local function union(table1, table2)
  local meta = {};
  for i,v in pairs(table1) do
    meta[i] = v;
  end
  for i,v in pairs(table2) do
    meta[i] = v;
  end
  return meta;
end

-- Also used by the GenericTrigger
function WeakAuras.ConstructOptions(prototype, data, startorder, triggernum, triggertype, unevent)
  local trigger, untrigger;
  if(data.controlledChildren) then
    trigger, untrigger = {}, {};
  elseif(triggertype == "load") then
    trigger = data.load;
  elseif data.triggers[triggernum] then
    if(triggertype == "untrigger") then
      trigger = data.triggers[triggernum].untrigger
    else
      trigger, untrigger = data.triggers[triggernum].trigger, data.triggers[triggernum].untrigger
    end
  else
    error("Improper argument to WeakAuras.ConstructOptions - trigger number not in range");
  end
  unevent = unevent or trigger.unevent;
  local options = {};
  local order = startorder or 10;

  local isCollapsedFunctions;
  for index, arg in pairs(prototype.args) do
    local hidden = nil;
    if(arg.collapse and isCollapsedFunctions[arg.collapse] and type(arg.enable) == "function") then
      local isCollapsed = isCollapsedFunctions[arg.collapse]
      hidden = function()
        return isCollapsed() or not arg.enable(trigger)
      end
    elseif(type(arg.enable) == "function") then
      hidden = function() return not arg.enable(trigger) end;
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
          local collapsed = WeakAuras.IsCollapsed("trigger", name, "", true)
          return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
        end,
        imageWidth = 24,
        imageHeight = 24,
        func = function(info, button, secondCall)
          if not secondCall then
            local collapsed = WeakAuras.IsCollapsed("trigger", name, "", true)
            WeakAuras.SetCollapsed("trigger", name, "", not collapsed)
          end
        end,
      }
      order = order + 1;

      isCollapsedFunctions = isCollapsedFunctions or {};
      isCollapsedFunctions[name] = function()
        return WeakAuras.IsCollapsed("trigger", name, "", true);
      end
    elseif(name and not arg.hidden) then
      local realname = name;
      if(triggertype == "untrigger") then
        name = "untrigger_"..name;
      end
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
            elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..arg.display;
            else return "|cFF00FF00"..arg.display; end
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
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
                trigger[realname] = trigger[realname] or {};
                if(trigger[realname].single) then
                  trigger[realname].multi = trigger[realname].multi or {};
                  trigger[realname].multi[trigger[realname].single] = true;
                end
              end
            end
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
      end
      if(arg.type == "toggle" or arg.type == "tristate") then
        options["use_"..name].width = arg.width or WeakAuras.doubleWidth;
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
            values = arg.operator_types_without_equal and operator_types_without_equal or operator_types,
            disabled = function() return not trigger["use_"..realname]; end,
            get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
            set = function(info, v)
              trigger[realname.."_operator"] = v;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              WeakAuras.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              WeakAuras.UpdateDisplayButton(data);
              WeakAuras.SortDisplayButtons();
            end
          };
          if(arg.required and not triggertype) then
            options[name.."_operator"].set = function(info, v)
              trigger[realname.."_operator"] = v;
              untrigger[realname.."_operator"] = v;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              WeakAuras.ScanForLoads({[data.id] = true});
              WeakAuras.SortDisplayButtons();
            end
          elseif(arg.required and triggertype == "untrigger") then
            options[name.."_operator"] = nil;
            order = order - 1;
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            untrigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
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
            untrigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        order = order + 1;
      elseif(arg.type == "longstring") then
        options[name.."_operator"] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = L["Operator"],
          order = order,
          hidden = hidden,
          values = string_operator_types,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
          set = function(info, v)
            trigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name.."_operator"].set = function(info, v)
            trigger[realname.."_operator"] = v;
            untrigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options[name.."_operator"] = nil;
          order = order - 1;
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname] = v;
            untrigger[realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        order = order + 1;
      elseif(arg.type == "spell" or arg.type == "aura" or arg.type == "item") then
        if(not arg.required or triggertype ~= "untrigger") then
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
                WeakAuras.ScanForLoads({[data.id] = true});
                WeakAuras.UpdateThumbnail(data);
                WeakAuras.UpdateDisplayButton(data);
                WeakAuras.SortDisplayButtons();
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
            width = WeakAuras.doubleWidth,
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
                local useExactSpellId = (arg.showExactOption and trigger["use_exact_"..realname]) or arg.forceExactOption
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
                fixedInput = WeakAuras.CorrectSpellName(v);
              elseif(arg.type == "item") then
                fixedInput = WeakAuras.CorrectItemName(v);
              end
              trigger[realname] = fixedInput;
              WeakAuras.Add(data);
              if (reloadOptions) then
                WeakAuras.ClearAndUpdateOptions(data.id)
              end
              WeakAuras.ScanForLoads({[data.id] = true});
              WeakAuras.UpdateThumbnail(data);
              WeakAuras.UpdateDisplayButton(data);
              WeakAuras.SortDisplayButtons();
            end
          };
          order = order + 1;
        end
      elseif(arg.type == "select" or arg.type == "unit") then
        local values;
        if(type(arg.values) == "function") then
          values = arg.values(trigger);
        else
          values = WeakAuras[arg.values];
        end
        options[name] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          values = values,
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
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
            untrigger[realname] = v;
            if(arg.type == "unit" and v == "member") then
              untrigger["use_specific_"..realname] = true;
            else
              untrigger["use_specific_"..realname] = nil;
            end
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        if (arg.control) then
          options[name].control = arg.control;
        end
        order = order + 1;
        if(arg.type == "unit" and not (arg.required and triggertype == "untrigger")) then
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
              if(arg.required and not triggertype) then
                untrigger[realname] = v;
              end
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
          values = WeakAuras[arg.values];
        end
        options[name] = {
          type = "select",
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          values = values,
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            trigger[realname].single = v;
            untrigger[realname].single = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        end

        options["multiselect_"..name] = {
          type = "multiselect",
          name = arg.display,
          width = WeakAuras.doubleWidth,
          order = order,
          hidden = function() return (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) or trigger["use_"..realname] ~= false; end,
          values = values,
          get = function(info, v)
            if(trigger["use_"..realname] == false and trigger[realname] and trigger[realname].multi) then
              return trigger[realname].multi[v];
            end
          end,
          set = function(info, v, calledFromSetAll)
            trigger[realname].multi = trigger[realname].multi or {};
            if (calledFromSetAll) then
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
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            if(trigger[realname].multi[v]) then
              trigger[realname].multi[v] = nil;
            else
              trigger[realname].multi[v] = true;
            end
            if(untrigger[realname].multi[v]) then
              untrigger[realname].multi[v] = nil;
            else
              untrigger[realname].multi[v] = true;
            end
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ClearAndUpdateOptions(data.id)
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.UpdateThumbnail(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        end

        if(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          options["multiselect_"..name] = nil;
        else
          order = order + 1;
        end
      end
    end
  end

  if not(triggertype or prototype.automaticrequired) then
    options.unevent = {
      type = "select",
      width = WeakAuras.doubleWidth,
      name = L["Hide"],
      order = order,
      get = function()
        return trigger.unevent
      end,
      set = function(info, v)
        trigger.unevent = v
      end
    };
    order = order + 1;
    if(unevent == "timed") then
      options.unevent.width = WeakAuras.normalWidth;
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
        end
      }
      order = order + 1;
    else
      options.unevent.width = WeakAuras.doubleWidth;
    end

    if(unevent == "custom") then
      local unevent_options = WeakAuras.ConstructOptions(prototype, data, order, triggernum, "untrigger");
      options = union(options, unevent_options);
    end
    if (prototype.timedrequired) then
      if (type(prototype.timedrequired) == "function") then
        local func = prototype.timedrequired
        options.unevent.values = function()
          if func(trigger) then
            return timedeventend_types
          else
            return eventend_types
          end
        end
      else
        options.unevent.values = timedeventend_types;
      end
    elseif (prototype.automatic) then
      options.unevent.values = autoeventend_types;
    else
      options.unevent.values = eventend_types;
    end
  end

  WeakAuras.option = options;
  return options;
end

function WeakAuras.GetLoadOptions(data)
  local load = {
    type = "group",
    name = L["Load"],
    order = 0,
    get = function(info) return data.load[info[#info]] end,
    set = function(info, v)
        data.load[info[#info]] = (v ~= "" and v) or nil;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ScanForLoads({[data.id] = true});
        WeakAuras.SortDisplayButtons();
      end,
      args = {}
    }

    load.args = WeakAuras.ConstructOptions(WeakAuras.load_prototype, data, 10, nil, "load");

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
          WeakAuras.ResetMoverSizer();
        end
      end
      load.hidden = function(info, ...) return hiddenAll(data, info, ...); end;
      load.disabled = function(info, ...) return disabledAll(data, info, ...); end;
    end
    return load
end
