if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local fmt, tostring = string.format, tostring
local pairs, type, unpack = pairs, type, unpack
local loadstring, error = loadstring, error
local coroutine = coroutine
local _G = _G

-- WoW APIs
local InCombatLockdown = InCombatLockdown
local GetSpellInfo, GetItemInfo, GetItemIcon, UnitName = GetSpellInfo, GetItemInfo, GetItemIcon, UnitName
local GetScreenWidth, GetScreenHeight, GetBuildInfo, GetLocale, GetTime, CreateFrame, IsAddOnLoaded, LoadAddOn
  = GetScreenWidth, GetScreenHeight, GetBuildInfo, GetLocale, GetTime, CreateFrame, IsAddOnLoaded, LoadAddOn

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L
local ADDON_NAME = "WeakAurasOptions";
local prettyPrint = WeakAuras.prettyPrint
local ValidateNumeric = WeakAuras.ValidateNumeric;

local dynFrame = WeakAuras.dynFrame;
WeakAuras.transmitCache = {};

local regionOptions = WeakAuras.regionOptions;
local displayButtons = {};
WeakAuras.displayButtons = displayButtons;
local optionReloads = {};
local optionTriggerChoices = {};
WeakAuras.optionTriggerChoices = optionTriggerChoices;
WeakAuras.thumbnails = {};
local thumbnails = WeakAuras.thumbnails;
local displayOptions = {};
WeakAuras.displayOptions = displayOptions;
local loaded = WeakAuras.loaded;
local spellCache = WeakAuras.spellCache;
local savedVars = {};
WeakAuras.savedVars = savedVars;

local tempGroup = {
  id = {"tempGroup"},
  regionType = "group",
  controlledChildren = {},
  load = {},
  triggers = {{}},
  config = {},
  authorOptions = {},
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0
};
WeakAuras.tempGroup = tempGroup;

function WeakAuras.DuplicateAura(data, newParent)
  local base_id = data.id .. " "
  local num = 2

  -- if the old id ends with a number increment the number
  local matchName, matchNumber = string.match(data.id, "^(.-)(%d*)$")
  matchNumber = tonumber(matchNumber)
  if (matchName ~= "" and matchNumber ~= nil) then
    base_id = matchName
    num = matchNumber + 1
  end

  local new_id = base_id .. num
  while(WeakAuras.GetData(new_id)) do
    new_id = base_id .. num
    num = num + 1
  end

  local newData = {}
  WeakAuras.DeepCopy(data, newData)
  newData.id = new_id
  newData.parent = nil
  newData.uid = WeakAuras.GenerateUniqueID()
  if newData.controlledChildren then
    newData.controlledChildren = {}
  end
  WeakAuras.Add(newData)
  WeakAuras.NewDisplayButton(newData)
  if(newParent or data.parent) then
    local parentId = newParent or data.parent
    local parentData = WeakAuras.GetData(parentId)
    local index
    if newParent then
      index = #parentData.controlledChildren
    else
      index = tIndexOf(parentData.controlledChildren, data.id)
    end
    if(index) then
      tinsert(parentData.controlledChildren, index + 1, newData.id)
      newData.parent = parentId
      WeakAuras.Add(parentData)
      WeakAuras.Add(newData)

      for index, id in pairs(parentData.controlledChildren) do
        local childButton = WeakAuras.GetDisplayButton(id)
        childButton:SetGroup(parentData.id, parentData.regionType == "dynamicgroup")
        childButton:SetGroupOrder(index, #parentData.controlledChildren)
      end

      local button = WeakAuras.GetDisplayButton(parentData.id)
      button.callbacks.UpdateExpandButton()
      WeakAuras.UpdateDisplayButton(parentData)
      WeakAuras.ReloadGroupRegionOptions(parentData)
    end
  end
  return newData.id
end

local point_types = WeakAuras.point_types;
local operator_types = WeakAuras.operator_types;
local operator_types_without_equal = WeakAuras.operator_types_without_equal;
local string_operator_types = WeakAuras.string_operator_types;
local eventend_types = WeakAuras.eventend_types;
local autoeventend_types = WeakAuras.autoeventend_types;
local timedeventend_types = WeakAuras.timedeventend_types;
local subevent_actual_prefix_types = WeakAuras.subevent_actual_prefix_types;


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

AceGUI:RegisterLayout("AbsoluteList", function(content, children)
  local yOffset = 0;
  for i = 1, #children do
    local child = children[i]

    local frame = child.frame;
    frame:ClearAllPoints();
    frame:Show();

    frame:SetPoint("LEFT", content);
    frame:SetPoint("RIGHT", content);
    frame:SetPoint("TOP", content, "TOP", 0, yOffset)

    if child.DoLayout then
      child:DoLayout()
    end

    yOffset = yOffset - ((frame.height or frame:GetHeight() or 0) + 2);
  end
  if(content.obj.LayoutFinished) then
    content.obj:LayoutFinished(nil, yOffset * -1);
  end
end);

AceGUI:RegisterLayout("ButtonsScrollLayout", function(content, children, skipLayoutFinished)
  local yOffset = 0
  local scrollTop, scrollBottom = content.obj:GetScrollPos()
  for i = 1, #children do
    local child = children[i]
    local frame = child.frame;

    if not child.dragging then
      local frameHeight = (frame.height or frame:GetHeight() or 0);
      frame:ClearAllPoints();
      if (-yOffset + frameHeight > scrollTop and -yOffset - frameHeight < scrollBottom) then
        frame:Show();
        frame:SetPoint("LEFT", content);
        frame:SetPoint("RIGHT", content);
        frame:SetPoint("TOP", content, "TOP", 0, yOffset)
      else
        frame:Hide();
        frame.yOffset = yOffset
      end
      yOffset = yOffset - (frameHeight + 2);
    end

    if child.DoLayout then
      child:DoLayout()
    end

  end
  if(content.obj.LayoutFinished and not skipLayoutFinished) then
    content.obj:LayoutFinished(nil, yOffset * -1)
  end
end)

function WeakAuras.MultipleDisplayTooltipDesc()
  local desc = {{L["Multiple Displays"], L["Temporary Group"]}};
  for index, id in pairs(tempGroup.controlledChildren) do
    desc[index + 1] = {" ", id};
  end
  desc[2][1] = L["Children:"]
  tinsert(desc, " ");
  tinsert(desc, {" ", "|cFF00FFFF"..L["Right-click for more options"]});
  tinsert(desc, {" ", "|cFF00FFFF"..L["Drag to move"]});
  return desc;
end

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
        type = "description",
        width = WeakAuras.doubleWidth - 0.15,
        name = type(arg.display) == "function" and arg.display(trigger) or arg.display,
        order = order,
        fontSize = "medium"
      }
      order = order + 1;
      options["button_" .. arg.name] = {
        type = "execute",
        width = 0.15,
        name = function()
          local collapsed = WeakAuras.IsCollapsed("trigger", name, "", true)
          return collapsed and L["Show Extra Options"] or L["Hide Extra Options"]
        end,
        order = order,
        image = function()
          local collapsed = WeakAuras.IsCollapsed("trigger", name, "", true)
          return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
        end,
        imageWidth = 24,
        imageHeight = 24,
        func = function()
          local collapsed = WeakAuras.IsCollapsed("trigger", name, "", true)
          WeakAuras.SetCollapsed("trigger", name, "", not collapsed)
          WeakAuras.ReloadTriggerOptions(data);
        end,
        control = "WeakAurasIcon"
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
          width = WeakAuras.normalWidth,
          name = arg.display,
          order = order,
          hidden = hidden,
          desc = arg.desc,
          get = function() return trigger["use_"..realname]; end,
          set = function(info, v)
            trigger["use_"..realname] = v;
            WeakAuras.Add(data);
            if (reloadOptions) then
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
                WeakAuras.ScheduleReloadOptions(data);
              end
              WeakAuras.ScanForLoads({[data.id] = true});
              WeakAuras.SetThumbnail(data);
              WeakAuras.SetIconNames(data);
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
                WeakAuras.ScheduleReloadOptions(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
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
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
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
                WeakAuras.ScheduleReloadOptions(data);
              end
              WeakAuras.ScanForLoads({[data.id] = true});
              WeakAuras.SetThumbnail(data);
              WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
                WeakAuras.ScheduleReloadOptions(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
              WeakAuras.ScheduleReloadOptions(data);
            end
            WeakAuras.ScanForLoads({[data.id] = true});
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
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
      order = order
    };
    order = order + 1;
    if(unevent == "timed") then
      options.unevent.width = WeakAuras.normalWidth;
      options.duration = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Duration (s)"],
        order = order
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

local frame;
local db;
local odb;
local options;
local newOptions;
local loadedOptions;
local unloadedOptions;
local reopenAfterCombat = false;
local loadedFrame = CreateFrame("FRAME");
loadedFrame:RegisterEvent("ADDON_LOADED");
loadedFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
loadedFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
loadedFrame:SetScript("OnEvent", function(self, event, addon)
  if (event == "ADDON_LOADED") then
    if(addon == ADDON_NAME) then
      db = WeakAurasSaved;
      WeakAurasOptionsSaved = WeakAurasOptionsSaved or {};

      odb = WeakAurasOptionsSaved;

      -- Remove icon and id cache (replaced with spellCache)
      if (odb.iconCache) then
        odb.iconCache = nil;
      end
      if (odb.idCache) then
        odb.idCache = nil;
      end
      odb.spellCache = odb.spellCache or {};
      spellCache.Load(odb.spellCache);

      local _, build = GetBuildInfo();
      local locale = GetLocale();
      local version = WeakAuras.versionString

      local num = 0;

      for i,v in pairs(odb.spellCache) do
        num = num + 1;
      end

      if(num < 39000 or odb.locale ~= locale or odb.build ~= build or odb.version ~= version) then
        spellCache.Build();

        odb.build = build;
        odb.locale = locale;
        odb.version = version;
      end

      -- Updates the icon cache with whatever icons WeakAuras core has actually used.
      -- This helps keep name<->icon matches relevant.
      for name, icons in pairs(db.dynamicIconCache) do
        if db.dynamicIconCache[name] then
          for spellId, icon in pairs(db.dynamicIconCache[name]) do
            spellCache.AddIcon(name, spellId, icon)
          end
        end
      end
      savedVars.db = db;
      savedVars.odb = odb;
    end
  elseif (event == "PLAYER_REGEN_DISABLED") then
    if(frame and frame:IsVisible()) then
      reopenAfterCombat = true;
      WeakAuras.HideOptions();
    end
  elseif (event == "PLAYER_REGEN_ENABLED") then
    if (reopenAfterCombat) then
      reopenAfterCombat = nil;
      WeakAuras.ShowOptions()
    end
  end
end);

function WeakAuras.MultipleDisplayTooltipMenu()
  local frame = frame;
  local menu = {
    {
      text = L["Add to new Group"],
      notCheckable = 1,
      func = function()
        local data = {
          id = WeakAuras.FindUnusedId(tempGroup.controlledChildren[1].." Group"),
          regionType = "group",
        };
        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);

        for index, childId in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          tinsert(data.controlledChildren, childId);
          childData.parent = data.id;
          WeakAuras.Add(data);
          WeakAuras.Add(childData);
        end

        for index, id in pairs(data.controlledChildren) do
          local childButton = WeakAuras.GetDisplayButton(id);
          childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
          childButton:SetGroupOrder(index, #data.controlledChildren);
        end

        local button = WeakAuras.GetDisplayButton(data.id);
        button.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadGroupRegionOptions(data);
        WeakAuras.SortDisplayButtons();
        button:Expand();
      end
    },
    {
      text = L["Add to new Dynamic Group"],
      notCheckable = 1,
      func = function()
        local data = {
          id = WeakAuras.FindUnusedId(tempGroup.controlledChildren[1].." Group"),
          regionType = "dynamicgroup",
        };

        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);

        for index, childId in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          tinsert(data.controlledChildren, childId);
          childData.parent = data.id;
          childData.xOffset = 0;
          childData.yOffset = 0;
          WeakAuras.Add(data);
          WeakAuras.Add(childData);
        end

        for index, id in pairs(data.controlledChildren) do
          local childButton = WeakAuras.GetDisplayButton(id);
          childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
          childButton:SetGroupOrder(index, #data.controlledChildren);
        end

        local button = WeakAuras.GetDisplayButton(data.id);
        button.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadGroupRegionOptions(data);
        WeakAuras.SortDisplayButtons();
        button:Expand();
        WeakAuras.PickDisplay(data.id);
      end
    },
    {
      text = L["Duplicate All"],
      notCheckable = 1,
      func = function()
        local toDuplicate = {};
        for index, id in pairs(tempGroup.controlledChildren) do
          toDuplicate[index] = id;
        end

        local duplicated = {};

        for index, id in ipairs(toDuplicate) do
          local childData = WeakAuras.GetData(id);
          duplicated[index] = WeakAuras.DuplicateAura(childData);
        end

        WeakAuras.ClearPicks();
        frame:PickDisplayBatch(duplicated);
      end
    },
    {
      text = " ",
      notCheckable = 1,
      notClickable = 1
    },
    {
      text = L["Delete all"],
      notCheckable = 1,
      func = function()
        local toDelete = {};
        local parents = {};
        for index, id in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(id);
          toDelete[index] = childData;
          if(childData.parent) then
            parents[childData.parent] = true;
          end
        end
        WeakAuras.ConfirmDelete(toDelete, parents)
      end
    },
    {
      text = " ",
      notClickable = 1,
      notCheckable = 1,
    },
    {
      text = L["Close"],
      notCheckable = 1,
      func = function() WeakAuras_DropDownMenu:Hide() end
    }
  };
  local anyGrouped = false;
  for index, id in pairs(tempGroup.controlledChildren) do
    local childData = WeakAuras.GetData(id);
    if(childData and childData.parent) then
      anyGrouped = true;
      break;
    end
  end
  if(anyGrouped) then
    menu[1].notClickable = 1;
    menu[1].text = "|cFF777777"..menu[1].text;
    menu[2].notClickable = 1;
    menu[2].text = "|cFF777777"..menu[2].text;
  end
  return menu;
end

function WeakAuras.DeleteOption(data, massDelete)
  local id = data.id;
  local parentData;
  if(data.parent) then
    parentData = db.displays[data.parent];
  end

  if(data.controlledChildren) then
    for index, childId in pairs(data.controlledChildren) do
      local childButton = displayButtons[childId];
      if(childButton) then
        childButton:SetGroup();
      end
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = nil;
      end
    end
  end

  WeakAuras.CollapseAllClones(id);

  frame:ClearPicks();
  WeakAuras.Delete(data);
  frame.buttonsScroll:DeleteChild(displayButtons[id]);
  thumbnails[id].region:Hide();
  thumbnails[id] = nil;
  displayButtons[id] = nil;

  if(parentData and parentData.controlledChildren and not massDelete) then
    for index, childId in pairs(parentData.controlledChildren) do
      local childButton = displayButtons[childId];
      if(childButton) then
        childButton:SetGroupOrder(index, #parentData.controlledChildren);
      end
    end
    WeakAuras.Add(parentData);
    WeakAuras.ReloadOptions2(parentData);
    WeakAuras.UpdateDisplayButton(parentData);
  end
end

StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"] = {
  text = "",
  button1 = L["Delete"],
  button2 = L["Cancel"],
  OnAccept = function(self)
    if self.data then
      for _, auraData in pairs(self.data.toDelete) do
        WeakAuras.DeleteOption(auraData, true)
      end
      if self.data.parents then
        for id in pairs(self.data.parents) do
          local parentData = WeakAuras.GetData(id)
          local parentButton = WeakAuras.GetDisplayButton(id)
          WeakAuras.UpdateGroupOrders(parentData)
          if(#parentData.controlledChildren == 0) then
            parentButton:DisableExpand()
          else
            parentButton:EnableExpand()
          end
          parentButton:SetNormalTooltip()
          WeakAuras.Add(parentData)
          WeakAuras.ReloadOptions2(parentData)
          WeakAuras.UpdateDisplayButton(parentData)
        end
      end
      WeakAuras.SortDisplayButtons()
    end
  end,
  OnCancel = function(self)
    if self.data.parents then
      for id in pairs(self.data.parents) do
        local parentRegion = WeakAuras.GetRegion(id)
        if parentRegion.Resume then
          parentRegion:Resume()
        end
      end
    end
    self.data = nil
  end,
  showAlert = true,
  whileDead = true,
  preferredindex = STATICPOPUP_NUMDIALOGS,
}

function WeakAuras.ConfirmDelete(toDelete, parents)
  if toDelete then
    local warningForm = L["You are about to delete %d aura(s). |cFFFF0000This cannot be undone!|r Would you like to continue?"]
    StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"].text = warningForm:format(#toDelete)
    StaticPopup_Show("WEAKAURAS_CONFIRM_DELETE", "", "", {toDelete = toDelete, parents = parents})
  end
end

function WeakAuras.OptionsFrame()
  if(frame) then
    return frame;
  else
    return nil;
  end
end

function WeakAuras.ToggleOptions(msg)
  if(frame and frame:IsVisible()) then
    WeakAuras.HideOptions();
  elseif (InCombatLockdown()) then
    prettyPrint(L["Options will open after combat ends."])
    reopenAfterCombat = true;
  else
    WeakAuras.ShowOptions(msg);
  end
end

function WeakAuras.UpdateCloneConfig(data)
  if(WeakAuras.CanHaveClones(data)) then
    local cloneRegion = WeakAuras.EnsureClone(data.id, 1);
    cloneRegion:Expand();

    cloneRegion = WeakAuras.EnsureClone(data.id, 2);
    cloneRegion:Expand();

    WeakAuras.SetIconNames(data);
  end
end

function WeakAuras.ShowOptions(msg)
  local firstLoad = not(frame);
  WeakAuras.Pause();
  WeakAuras.SetFakeStates()

  if (firstLoad) then
    frame = WeakAuras.CreateFrame();
    frame.buttonsScroll.frame:Show();
    WeakAuras.AddOption(tempGroup.id, tempGroup);
    WeakAuras.LayoutDisplayButtons(msg);
  end
  frame.buttonsScroll.frame:Show();

  if (frame.needsSort) then
    WeakAuras.SortDisplayButtons();
    frame.needsSort = nil;
  end

  frame:Show();

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:OptionsOpened();
  end

  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:OptionsOpened();
  end

  if (frame.pickedDisplay) then
    if (WeakAuras.IsPickedMultiple()) then
      local children = {}
      for k,v in pairs(tempGroup.controlledChildren) do
        children[k] = v
      end
      frame:PickDisplayBatch(children);
    else
      WeakAuras.PickDisplay(frame.pickedDisplay);
    end
  else
    frame:PickOption("New");
  end
  if not(firstLoad) then
    -- Show what was last shown
    WeakAuras.PauseAllDynamicGroups();
    for id, button in pairs(displayButtons) do
      if (button:GetVisibility() > 0) then
        button:PriorityShow(button:GetVisibility());
      end
    end
    WeakAuras.ResumeAllDynamicGroups();
  end

  if (frame.window == "codereview") then
    frame.codereview:Close();
  end
end

function WeakAuras.HideOptions()
  if(frame) then
    frame:Hide()
  end
end

function WeakAuras.IsOptionsOpen()
  if(frame and frame:IsVisible()) then
    return true;
  else
    return false;
  end
end

function WeakAuras.SetIconNames(data)
  if (not thumbnails[data.id]) then return end;
  WeakAuras.SetIconName(data, WeakAuras.regions[data.id].region);
  WeakAuras.SetIconName(data, thumbnails[data.id].region);
  if(WeakAuras.clones[data.id]) then
    for index, cloneRegion in pairs(WeakAuras.clones[data.id]) do
      WeakAuras.SetIconName(data, cloneRegion);
    end
  end
end

function WeakAuras.SetIconName(data, region)
  local name, icon = WeakAuras.GetNameAndIcon(data);
  WeakAuras.transmitCache[data.id] = icon;

  if(region.SetIcon) then
    region:SetIcon(icon);
  end
  if(region.SetName) then
    region:SetName(name);
  end
end

function WeakAuras.GetSortedOptionsLists()
  local loadedSorted, unloadedSorted = {}, {};
  local to_sort = {};
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
    elseif(loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a < b end);
  for _, id in ipairs(to_sort) do
    tinsert(loadedSorted, id);
    local data = WeakAuras.GetData(id);
    local controlledChildren = data.controlledChildren;
    if(controlledChildren) then
      for _, childId in pairs(controlledChildren) do
        tinsert(loadedSorted, childId);
      end
    end
  end

  wipe(to_sort);
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
    elseif not(loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a < b end);
  for _, id in ipairs(to_sort) do
    tinsert(unloadedSorted, id);
    local data = WeakAuras.GetData(id);
    local controlledChildren = data.controlledChildren;
    if(controlledChildren) then
      for _, childId in pairs(controlledChildren) do
        tinsert(unloadedSorted, childId);
      end
    end
  end

  return loadedSorted, unloadedSorted;
end

function WeakAuras.BuildOptions(list, callback)
  frame.loadProgress:Show();
  frame.filterInput:Hide();
  frame.filterInputClear:Hide();

  local total = 0;
  for _,_ in pairs(list) do
    total = total + 1;
  end

  local func = function()
    local num = 0;
    for id, data in pairs(list) do
      if(data) then
        if not(data.regionType == "group" or data.regionType == "dynamicgroup") then
          WeakAuras.AddOption(id, data);
          num = num + 1;
        end
      end
      frame.loadProgress:SetText(L["Creating options: "]..num.."/"..total);

      coroutine.yield();
    end

    callback();
    frame.loadProgress:Hide();
    frame.filterInput:Show();
    frame.filterInputClear:Show();
  end

  local co = coroutine.create(func);
  dynFrame:AddAction("BuildOptions", co);
end

function WeakAuras.LayoutDisplayButtons(msg)
  local total = 0;
  for _,_ in pairs(db.displays) do
    total = total + 1;
  end

  local loadedSorted, unloadedSorted = WeakAuras.GetSortedOptionsLists();

  frame.loadProgress:Show();
  frame.buttonsScroll:AddChild(frame.newButton);
  if(frame.addonsButton) then
    frame.buttonsScroll:AddChild(frame.addonsButton);
  end
  frame.buttonsScroll:AddChild(frame.loadedButton);
  frame.buttonsScroll:AddChild(frame.unloadedButton);

  local func2 = function()
    local num = frame.loadProgressNum or 0;
    for index, id in pairs(unloadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        WeakAuras.EnsureDisplayButton(data);
        WeakAuras.UpdateDisplayButton(data);

        frame.buttonsScroll:AddChild(displayButtons[data.id]);
        WeakAuras.SetIconNames(data);
        if(WeakAuras.regions[data.id].region.SetStacks) then
          WeakAuras.regions[data.id].region:SetStacks(1);
        end

        if (num % 50 == 0) then
          frame.buttonsScroll:ResumeLayout()
          frame.buttonsScroll:PerformLayout()
          frame.buttonsScroll:PauseLayout()
        end

        num = num + 1;
      end
      frame.loadProgress:SetText(L["Creating buttons: "]..num.."/"..total);
      frame.loadProgressNum = num;
      coroutine.yield();
    end

    frame.buttonsScroll:ResumeLayout()
    frame.buttonsScroll:PerformLayout()
    WeakAuras.SortDisplayButtons(msg);

    WeakAuras.PauseAllDynamicGroups();
    if (WeakAuras.IsOptionsOpen()) then
      for id, button in pairs(displayButtons) do
        if(loaded[id] ~= nil) then
          button:PriorityShow(1);
        end
        if WeakAurasCompanion and not button.data.parent then
          -- initialize update icons on top level buttons
          button:RefreshUpdate()
        end
      end
    end
    WeakAuras.ResumeAllDynamicGroups();

    frame.loadProgress:Hide();
    frame.filterInput:Show();
    frame.filterInputClear:Show();
  end

  local func1 = function()
    local num = frame.loadProgressNum or 0;
    frame.buttonsScroll:PauseLayout()
    for index, id in pairs(loadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        WeakAuras.EnsureDisplayButton(data);
        WeakAuras.UpdateDisplayButton(data);

        local button = displayButtons[data.id]
        frame.buttonsScroll:AddChild(button);
        WeakAuras.SetIconNames(data);
        if(WeakAuras.regions[data.id].region.SetStacks) then
          WeakAuras.regions[data.id].region:SetStacks(1);
        end

        num = num + 1;
      end

      if (num % 50 == 0) then
        frame.buttonsScroll:ResumeLayout()
        frame.buttonsScroll:PerformLayout()
        frame.buttonsScroll:PauseLayout()
      end

      frame.loadProgress:SetText(L["Creating buttons: "]..num.."/"..total);
      frame.loadProgressNum = num;
      coroutine.yield();
    end

    local co2 = coroutine.create(func2);
    dynFrame:AddAction("LayoutDisplayButtons2", co2);
  end

  local co1 = coroutine.create(func1);
  dynFrame:AddAction("LayoutDisplayButtons1", co1);
end


local function removeFuncs(intable)
  for i,v in pairs(intable) do
    if(i == "get" or i == "set" or i == "hidden" or i == "disabled") then
      intable[i] = nil;
    elseif(type(v) == "table" and i ~= "values") then
      removeFuncs(v);
    end
  end
end

local function hiddenChild(childOptionTable, info)
  for i=#childOptionTable,0,-1 do
    if(childOptionTable[i].hidden ~= nil) then
      if(type(childOptionTable[i].hidden) == "boolean") then
        return childOptionTable[i].hidden;
      elseif(type(childOptionTable[i].hidden) == "function") then
        return childOptionTable[i].hidden(info);
      end
    end
  end
  return false;
end

local function disabledChild(childOptionTable, info)
  for i=#childOptionTable,0,-1 do
    if(childOptionTable[i].disabled ~= nil) then
      if(type(childOptionTable[i].disabled) == "boolean") then
        return childOptionTable[i].disabled;
      elseif(type(childOptionTable[i].disabled) == "function") then
        return childOptionTable[i].disabled(info);
      end
    end
  end
  return false;
end

local function disabeldOrHiddenChild(childOptionTable, info)
  return hiddenChild(childOptionTable, info) or disabledChild(childOptionTable, info);
end

local function getChildOption(displayOptions, info)
  for i=1,#info do
    displayOptions = displayOptions.args[info[i]];
    if not(displayOptions) then
      return nil;
    end

    if (displayOptions.hidden) then
      local type = type(displayOptions.hidden);
      if (type == "bool") then
        if (displayOptions.hidden) then
          return nil;
        end
      elseif (type == "function") then
        if (displayOptions.hidden(info)) then
          return nil;
        end
      end
    end

  end
  return displayOptions
end

local function getAll(data, info, ...)
  local combinedValues = {};
  local first = true;
  local debug = false;
  local isToggle = nil
  for index, childId in ipairs(data.controlledChildren) do
    if isToggle == nil then
      local childOptions = getChildOption(displayOptions[childId], info)
      isToggle = childOptions and childOptions.type == "toggle"
    end

    local childData = WeakAuras.GetData(childId);

    if(childData) then
      WeakAuras.EnsureOptions(childId);
      local childOptions = displayOptions[childId];
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end

      if (childOption and not hiddenChild(childOptionTable, info)) then
        for i=#childOptionTable,0,-1 do
          if(childOptionTable[i].get) then
            local values = {childOptionTable[i].get(info, ...)};
            if isToggle and values[1] == nil then
              values[1] = false
            end
            if(first) then
              combinedValues = values;
              first = false;
            else
              local same = true;
              if(#combinedValues == #values) then
                for j=1,#combinedValues do
                  if(type(combinedValues[j]) == "number" and type(values[j]) == "number") then
                    if((math.floor(combinedValues[j] * 100) / 100) ~= (math.floor(values[j] * 100) / 100)) then
                      same = false;
                      break;
                    end
                  else
                    if(combinedValues[j] ~= values[j]) then
                      same = false;
                      break;
                    end
                  end
                end
              else
                same = false;
              end
              if not(same) then
                return nil;
              end
            end
            break;
          end
        end
      end
    end
    if (debug) then print("  \n") end
  end
  return unpack(combinedValues);
end
WeakAuras.getAll = getAll

local function setAll(data, info, ...)
  WeakAuras.pauseOptionsProcessing(true);
  WeakAuras.PauseAllDynamicGroups()
  local before = getAll(data, info, ...)
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      WeakAuras.EnsureOptions(childId);
      local childOptions = displayOptions[childId];
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end

      if (childOption and not disabeldOrHiddenChild(childOptionTable, info)) then
        for i=#childOptionTable,0,-1 do
          if(childOptionTable[i].set) then
            if (childOptionTable[i].type == "multiselect") then
              childOptionTable[i].set(info, ..., not before);
            else
              childOptionTable[i].set(info, ...);
            end
            break;
          end
        end
      end
    end
  end

  WeakAuras.ResumeAllDynamicGroups()
  WeakAuras.pauseOptionsProcessing(false);
  WeakAuras.ScanForLoads();
  WeakAuras.SortDisplayButtons();
end
WeakAuras.setAll = setAll

local function hiddenAll(data, info)
  if(#data.controlledChildren == 0 and info[1] ~= "group") then
    return true;
  end
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      WeakAuras.EnsureOptions(childId);
      local childOptions = displayOptions[childId];
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end
      if (childOption) then
        if (not hiddenChild(childOptionTable, info)) then
          return false;
        end
      end
    end
  end

  return true;
end



local function disabledAll(data, info)
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      WeakAuras.EnsureOptions(childId);
      local childOptions = displayOptions[childId];
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end
      if (childOption) then
        if (not disabledChild(childOptionTable, info)) then
          return false;
        end
      end
    end
  end

  return true;
end

local function replaceNameDescFuncs(intable, data)

  local function compareTables(tableA, tableB)
    if(#tableA == #tableB) then
      for j=1,#tableA do
        if(type(tableA[j]) == "number" and type(tableB[j]) == "number") then
          if((math.floor(tableA[j] * 100) / 100) ~= (math.floor(tableB[j] * 100) / 100)) then
            return false;
          end
        else
          if(tableA[j] ~= tableB[j]) then
            return false;
          end
        end
      end
    else
      return false;
    end
    return true;
  end

  local function getValueFor(displayOptions, info, key)
    local childOptionTable = {[0] = displayOptions};
    for i=1,#info do
      displayOptions = displayOptions.args[info[i]];
      if (not displayOptions) then
        return nil;
      end
      childOptionTable[i] = displayOptions;
    end

    if (hiddenChild(childOptionTable, info)) then
      return nil;
    end

    for i=#childOptionTable,0,-1 do
      if(childOptionTable[i][key]) then
        return childOptionTable[i][key];
      end
    end
    return nil;
  end

  local function combineKeys(info)
    local combinedKeys = nil;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);

        local values = getValueFor(displayOptions[childId], info, "values");
        if (values) then
          if (type(values) == "function") then
            values = values(info);
          end
          if (type(values) == "table") then
            combinedKeys = combinedKeys or {};
            for k, v in pairs(values) do
              combinedKeys[k] = v;
            end
          end
        end
      end
    end
    return combinedKeys;
  end

  local function regionPrefix(input)
    local index = string.find(input, ".", 1, true);
    if (index) then
      local regionType = string.sub(input, 1, index - 1);
      return regionOptions[regionType] and regionType;
    end
    return nil;
  end

  local function sameAll(info)
    local combinedValues = {};
    local first = true;
    local combinedKeys = combineKeys(info);

    local isToggle = nil

    for index, childId in ipairs(data.controlledChildren) do
      if isToggle == nil then
        local childOption = getChildOption(displayOptions[childId], info)
        isToggle = childOption and childOption.type == "toggle"
      end

      local childData = WeakAuras.GetData(childId);

      local regionType = regionPrefix(info[#info]);
      if(childData and (not regionType or childData.regionType == regionType or regionType == "sub")) then
        WeakAuras.EnsureOptions(childId);
        local childOptions = displayOptions[childId];

        local get = getValueFor(displayOptions[childId], info, "get");
        if (combinedKeys) then
          for key, _ in pairs(combinedKeys) do
            local values = {};
            if (get) then
              values = { get(info, key) };
            end
            if (combinedValues[key] == nil) then
              combinedValues[key] = values;
            else
              if (not compareTables(combinedValues[key], values)) then
                return nil;
              end
            end
          end
        else
          local values = {};
          if (get) then
            values = { get(info) };
            local childOption = getChildOption(displayOptions[childId], info)
            if isToggle and values[1] == nil then
              values[1] = false
            end
          end
          if(first) then
            combinedValues = values;
            first = false;
          else
            if (not compareTables(combinedValues, values)) then
              return nil;
            end
          end
        end
      end
    end

    return true;
  end

  local function nameAll(info)
    local combinedName;
    local first = true;
    local foundNames = {};
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);
        local childOption = getChildOption(displayOptions[childId], info);
        if (childOption) then
          local name;
          if(type(childOption.name) == "function") then
            name = childOption.name(info);
          else
            name = childOption.name;
          end
          if (not name) then
          -- Do nothing
          elseif(first) then
            if (combinedName ~= "") then
              combinedName = name;
              first = false;
            end
            foundNames[name] = true;
          elseif not(foundNames[name]) then
            if (name ~= "") then
              if (childOption.type == "description") then
                combinedName = combinedName .. "\n\n" .. name;
              else
                combinedName = combinedName .. " / " .. name;
              end
            end
            foundNames[name] = true;
          end
        end
      end
    end

    return combinedName;
  end

  local function descAll(info)
    local combinedDesc;
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);
        local childOption = getChildOption(displayOptions[childId], info);
        if (childOption) then
          local desc;
          if(type(childOption.desc) == "function") then
            desc = childOption.desc(info);
          else
            desc = childOption.desc;
          end
          if(first) then
            combinedDesc = desc;
            first = false;
          elseif not(combinedDesc == desc) then
            return L["Not all children have the same value for this option"];
          end
        end
      end
    end
    return combinedDesc;
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "name" and type(v) ~= "table") then
        intable.name = function(info)
          local name = nameAll(info);
          if(sameAll(info)) then
            return name;
          else
            if(name == "") then
              return name;
            else
              return "|cFF4080FF"..(name or "error");
            end
          end
        end
        intable.desc = function(info)
          if(sameAll(info)) then
            return descAll(info);
          else
            local combinedKeys = nil;
            if (intable.type == "multiselect") then
              combinedKeys = combineKeys(info)
            end

            local values = {};
            for index, childId in ipairs(data.controlledChildren) do
              local childData = WeakAuras.GetData(childId);
              if(childData) then
                WeakAuras.EnsureOptions(childId);
                local childOptions = displayOptions[childId];
                local childOption = childOptions;
                local childOptionTable = {[0] = childOption};
                for i=1,#info do
                  childOption = childOption.args[info[i]];
                  childOptionTable[i] = childOption;
                end
                if (childOption and not hiddenChild(childOptionTable, info)) then
                  for i=#childOptionTable,0,-1 do
                    if(childOptionTable[i].get) then
                      if(intable.type == "toggle") then
                        local name, tri;
                        if(type(childOption.name) == "function") then
                          name = childOption.name(info);
                          tri = true;
                        else
                          name = childOption.name;
                        end
                        if(tri and childOptionTable[i].get(info)) then
                          tinsert(values, "|cFFE0E000"..childId..": |r"..name);
                        elseif(tri) then
                          tinsert(values, "|cFFE0E000"..childId..": |r"..L["Ignored"]);
                        elseif(childOptionTable[i].get(info)) then
                          tinsert(values, "|cFFE0E000"..childId..": |r|cFF00FF00"..L["Enabled"]);
                        else
                          tinsert(values, "|cFFE0E000"..childId..": |r|cFFFF0000"..L["Disabled"]);
                        end
                      elseif(intable.type == "color") then
                        local r, g, b = childOptionTable[i].get(info);
                        r, g, b = r or 1, g or 1, b or 1;
                        tinsert(values, ("|cFF%2x%2x%2x%s"):format(r * 220 + 35, g * 220 + 35, b * 220 + 35, childId));
                      elseif(intable.type == "select") then
                        local selectValues = type(intable.values) == "table" and intable.values or intable.values(info);
                        local key = childOptionTable[i].get(info);
                        local display = key and selectValues[key] or L["None"];
                        if intable.dialogControl == "LSM30_Font" then
                          tinsert(values, "|cFFE0E000"..childId..": |r" .. key);
                        else
                          tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                        end
                      elseif(intable.type == "multiselect") then
                        local selectedValues = {};
                        for k, v in pairs(combinedKeys) do
                          if (childOptionTable[i].get(info, k)) then
                            tinsert(selectedValues, tostring(v))
                          end
                        end
                        tinsert(values, "|cFFE0E000"..childId..": |r"..table.concat(selectedValues, ","));
                      else
                        local display = childOptionTable[i].get(info) or L["None"];
                        if(type(display) == "number") then
                          display = math.floor(display * 100) / 100;
                        else
                          if #display > 50 then
                            display = display:sub(1, 50) .. "..."
                          end
                        end
                        tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                      end
                      break;
                    end
                  end
                end
              end
            end
            return table.concat(values, "\n");
          end
        end
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local function replaceImageFuncs(intable, data)
  local function imageAll(info)
    local combinedImage = {};
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);
        local childOption = displayOptions[childId];
        if not(childOption) then
          return "error"
        end
        childOption = getChildOption(childOption, info);
        if childOption and childOption.image then
          local image = {childOption.image(info)};
          if(first) then
            combinedImage = image;
            first = false;
          else
            if not(combinedImage[1] == image[1]) then
              return "", 0, 0;
            end
          end
        end
      end
    end

    return unpack(combinedImage);
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "image" and type(v) == "function") then
        intable[i] = imageAll;
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local function replaceValuesFuncs(intable, data)
  local function valuesAll(info)
    local combinedValues = {};
    local handledValues = {};
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);
        local childOption = displayOptions[childId];
        if not(childOption) then
          return "error"
        end

        childOption = getChildOption(childOption, info);
        if (childOption) then
          local values = childOption.values;
          if (type(values) == "function") then
            values = values(info);
          end
          if(first) then
            for k, v in pairs(values) do
              handledValues[k] = handledValues[k] or {};
              handledValues[k][v] = true;
              combinedValues[k] = v;
            end
            first = false;
          else
            for k, v in pairs(values) do
              if (handledValues[k] and handledValues[k][v]) then
              -- Already known key/value pair
              else
                if (combinedValues[k]) then
                  combinedValues[k] = combinedValues[k] .. "/" .. v;
                else
                  combinedValues[k] = v;
                end
                handledValues[k] = handledValues[k] or {};
                handledValues[k][v] = true;
              end
            end
          end
        end
      end
    end

    return combinedValues;
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "values" and type(v) == "function") then
        intable[i] = valuesAll;
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local function GetCustomCode(data, path)
  for _, key in ipairs(path) do
    if (not data or not data[key]) then
      return nil;
    end
    data = data[key];
  end
  return data;
end

-- TODO: find a paradigm which doesn't have five million flags for AddCodeOption so that calls to it don't always go off the screen
-- a table of settings is the obvious option to pack the flags.
-- alternatively, we could create a "code" type option which then gets processed before sending to AceConfig
function WeakAuras.AddCodeOption(args, data, name, prefix, order, hiddenFunc, path, encloseInFunction, multipath, extraSetFunction, extraFunctions, reloadOptions, setOnParent)
  extraFunctions = extraFunctions or {};
  tinsert(extraFunctions, 1, {
    buttonLabel = L["Expand"],
    func = function()
      WeakAuras.OpenTextEditor(data, path, encloseInFunction, multipath, reloadOptions, setOnParent)
    end
  });

  args[prefix .. "_custom"] = {
    type = "input",
    width = WeakAuras.doubleWidth,
    name = name,
    order = order,
    multiline = true,
    hidden = hiddenFunc,
    control = "WeakAurasMultiLineEditBox",
    arg = {
      extraFunctions = extraFunctions,
    },
    set = function(info, v)
      local subdata = data;
      for i = 1, #path -1 do
        local key = path[i];
        subdata[key] = subdata[key] or {};
        subdata = subdata[key];
      end

      subdata[path[#path]] = v;
      WeakAuras.Add(data);
      if (extraSetFunction) then
        extraSetFunction();
      end
      if (reloadOptions) then
        WeakAuras.ScheduleReloadOptions(data);
      end
    end,
    get = function(info)
      return GetCustomCode(data, path);
    end
  };

  args[prefix .. "_customError"] = {
    type = "description",
    name = function()
      if hiddenFunc() then
        return "";
      end

      local code = GetCustomCode(data, path);

      if (not code) then
        return ""
      end

      if (encloseInFunction) then
        code = "function() "..code.."\n end";
      end

      code = "return " .. code;

      local _, errorString = loadstring(code);
      return errorString and "|cFFFF0000"..errorString or "";
    end,
    width = WeakAuras.doubleWidth,
    order = order + 0.002,
    hidden = function()
      if (hiddenFunc()) then
        return true;
      end

      local code = GetCustomCode(data, path);
      if (not code) then
        return true;
      end

      if (encloseInFunction) then
        code = "function() "..code.."\n end";
      end

      code = "return " .. code;

      local loadedFunction, errorString = loadstring(code);
      if(errorString and not loadedFunction) then
        return false;
      else
        return true;
      end
    end
  };
end

local function addCollapsibleHeader(options, key, input, order, isGroupTab)
  if input.__noHeader then
    return
  end
  local title = input.__title
  local hasDelete = input.__delete
  local hasUp = input.__up
  local hasDown = input.__down
  local hasDuplicate = input.__duplicate
  local hiddenFunc = input.__hidden
  local nooptions = input.__nooptions
  local marginTop = input.__topLine

  local titleWidth = WeakAuras.doubleWidth - (hasDelete and 0.15 or 0) - (hasUp and 0.15 or 0) - (hasDown and 0.15 or 0) - (hasDuplicate and 0.15 or 0)

  options[key .. "collapseSpacer"] = {
    type = marginTop and "header" or "description",
    name = "",
    order = order,
    width = "full",
    hidden = hiddenFunc,
  }
  options[key .. "collapseButton"] = {
    type = "execute",
    name = title,
    order = order + 0.1,
    width = titleWidth,
    func = function(info)
      if not nooptions then
        local isCollapsed = WeakAuras.IsCollapsed("collapse", "region", key, false)
        WeakAuras.SetCollapsed("collapse", "region", key, not isCollapsed)
        WeakAuras.RefillOptions()
      end
    end,
    image = function()
      if nooptions then
        return "Interface\\AddOns\\WeakAuras\\Media\\Textures\\bullet1", 18, 18
      else
        local isCollapsed = WeakAuras.IsCollapsed("collapse", "region", key, false)
        return isCollapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse", 18, 18
      end
    end,
    control = "WeakAurasExpand",
    hidden = hiddenFunc
  }

  if hasUp then
    options[key .. "upButton"] = {
      type = "execute",
      name = "",
      order = order + 0.3,
      width = 0.15,
      func = input.__up,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
      imageWidth = 24,
      imageHeight = 24,
      hidden = hiddenFunc,
    }
  end

  if hasDown then
    options[key .. "downButton"] = {
      type = "execute",
      name = "",
      order = order + 0.4,
      width = 0.15,
      func = input.__down,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
      imageWidth = 24,
      imageHeight = 24,
      hidden = hiddenFunc
    }
  end

  if hasDuplicate then
    options[key .. "duplicateButton"] = {
      type = "execute",
      name = "",
      order = order + 0.5,
      width = 0.15,
      func = input.__duplicate,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\duplicate",
      imageWidth = 24,
      imageHeight = 24,
      hidden = hiddenFunc
    }
  end

  if hasDelete then
    options[key .. "deleteButton"] = {
      type = "execute",
      name = "",
      order = order + 0.6,
      width = 0.15,
      func = input.__delete,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
      imageWidth = 24,
      imageHeight = 24,
      hidden = hiddenFunc
    }
  end

  if hiddenFunc then
    return function()
      return hiddenFunc() or WeakAuras.IsCollapsed("collapse", "region", key, false)
    end
  else
    return function()
      return WeakAuras.IsCollapsed("collapse", "region", key, false)
    end
  end
end

local function copyOptionTable(input, orderAdjustment, collapsedFunc)
  local resultOption = {};
  WeakAuras.DeepCopy(input, resultOption);
  resultOption.order = orderAdjustment + resultOption.order;
  if collapsedFunc then
    local oldHidden = resultOption.hidden;
    if oldHidden ~= nil then
      local oldFunc
      if type(oldHidden) ~= "function" then
        oldFunc = function(...) return oldHidden end
      else
        oldFunc = oldHidden
      end
      resultOption.hidden = function(...)
        if collapsedFunc() then
          return true
        else
          return oldFunc(...)
        end
      end
    else
      resultOption.hidden = collapsedFunc;
    end
  end
  return resultOption;
end

local function flattenRegionOptions(allOptions, isGroupTab)
  local result = {};
  local base = 1000;

  for optionGroup, options in pairs(allOptions) do
    local groupBase = base * options.__order

    local collapsedFunc = addCollapsibleHeader(result, optionGroup, options, groupBase, isGroupTab)

    for optionName, option in pairs(options) do
      if not optionName:find("^__") then
        result[optionGroup .. "." .. optionName] = copyOptionTable(option, groupBase, collapsedFunc);
      end
    end
  end

  return result;
end

local function parsePrefix(input, data, create)
  local subRegionIndex, property = string.match(input, "^sub%.(%d+)%..+%.(.+)")
  subRegionIndex = tonumber(subRegionIndex)
  if subRegionIndex then
    if create then
      data.subRegions = data.subRegions or {}
      data.subRegions[subRegionIndex] = data.subRegions[subRegionIndex] or {}
    else
      if not data.subRegions or not data.subRegions[subRegionIndex] then
        return nil
      end
    end
    return data.subRegions[subRegionIndex], property
  end
  local index = string.find(input, ".", 1, true);
  if (index) then
    return data, string.sub(input, index + 1);
  end
  return data, input
end

local function AddSubRegionImpl(data, subRegionName)
  data.subRegions = data.subRegions or {}
  if WeakAuras.subRegionTypes[subRegionName] and WeakAuras.subRegionTypes[subRegionName] then
    if WeakAuras.subRegionTypes[subRegionName].supports(data.regionType) then
      local default = WeakAuras.subRegionTypes[subRegionName].default
      local subRegionData = type(default) == "function" and default(data.regionType) or CopyTable(default)
      subRegionData.type = subRegionName
      tinsert(data.subRegions, subRegionData)
      WeakAuras.Add(data)
      WeakAuras.ReloadOptions2(data.id, data)
    end
  end
end

local function AddSubRegion(data, subRegionName)
  WeakAuras.ApplyToDataOrChildData(data, AddSubRegionImpl, subRegionName)
  WeakAuras.ReloadOptions2(data.id, data)
end

local function AddOptionsForSupportedSubRegion(regionOption, data, supported)
  if not next(supported) then
    return
  end
  local hasSubRegions = false

  local result = {}
  local order = 1
  result.__order = 300
  result.__title = L["Add Extra Elements"]
  result.__topLine = true
  for subRegionType in pairs(supported) do
    if WeakAuras.subRegionTypes[subRegionType].supportsAdd then
      hasSubRegions = true
      result[subRegionType .. "space"] = {
        type = "description",
        width = WeakAuras.doubleWidth,
        name = "",
        order = order,
      }
      order = order + 1
      result[subRegionType] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = string.format(L["Add %s"], WeakAuras.subRegionTypes[subRegionType].displayName),
        order = order,
        func = function()
          AddSubRegion(data, subRegionType)
        end,
      }
      order = order + 1
    end
  end
  regionOption["sub"] = result;
  return hasSubRegions
end

function WeakAuras.AddOption(id, data)
  local regionOption;
  local commonOption = {};

  local hasSubElements = false

  if(regionOptions[data.regionType]) then
    regionOption = regionOptions[data.regionType].create(id, data);

    if data.subRegions then
      local subIndex = {}
      for index, subRegionData in ipairs(data.subRegions) do
        local subRegionType = subRegionData.type
        if WeakAuras.subRegionOptions[subRegionType] then
          hasSubElements = true
          subIndex[subRegionType] = subIndex[subRegionType] and subIndex[subRegionType] + 1 or 1
          local options, common = WeakAuras.subRegionOptions[subRegionType].create(data, subRegionData, index, subIndex[subRegionType])
          options.__order = 200 + index
          regionOption["sub." .. index .. "." .. subRegionType] = options
          commonOption[subRegionType] = common
        end
      end
    end

    local commonOptionIndex = 0
    for option, optionData in pairs(commonOption) do
      commonOptionIndex = commonOptionIndex + 1
      optionData.__order = 100 + commonOptionIndex
      regionOption[option] = optionData
    end

    local supported = {}
    for subRegionName, subRegionType in pairs(WeakAuras.subRegionTypes) do
      if subRegionType.supports(data.regionType) then
        supported[subRegionName] = true
      end
    end
    hasSubElements = AddOptionsForSupportedSubRegion(regionOption, data, supported) or hasSubElements
  else
    regionOption = {
      [data.regionType] = {
        __title = "|cFFFFFF00" .. data.regionType,
        __order = 1,
        unsupported = {
          type = "description",
          name = L["This region of type \"%s\" is not supported."]:format(data.regionType),
          order = 2,
        }
      }
    };
  end

  if hasSubElements then
    regionOption["SubElementsHeader"] = {
      __order = 100,
      __noHeader = true,
      header = {
        type = "header",
        name = L["Sub Elements"],
        order = 1
      }
    }
  end

  local options = flattenRegionOptions(regionOption, true)
  displayOptions[id] = {
    type = "group",
    childGroups = "tab",
    args = {
      region = {
        type = "group",
        name = L["Display"],
        order = 10,
        get = function(info)
          local base, property = parsePrefix(info[#info], data);
          if not base then
            return nil
          end
          if(info.type == "color") then
            base[property] = base[property] or {};
            local c = base[property];
            return c[1], c[2], c[3], c[4];
          else
            return base[property];
          end
        end,
        set = function(info, v, g, b, a)
          local base, property = parsePrefix(info[#info], data, true);
          if(info.type == "color") then
            base[property] = base[property] or {};
            local c = base[property];
            c[1], c[2], c[3], c[4] = v, g, b, a;
          elseif(info.type == "toggle") then
            base[property] = v;
          else
            base[property] = (v ~= "" and v) or nil;
          end
          WeakAuras.Add(data);
          WeakAuras.SetThumbnail(data);
          WeakAuras.SetIconNames(data);
          if(data.parent) then
            local parentData = WeakAuras.GetData(data.parent);
            if(parentData) then
              WeakAuras.Add(parentData);
              WeakAuras.SetThumbnail(parentData);
            end
          end
          WeakAuras.ResetMoverSizer();
        end,
        args = options
      },
      trigger = {
        type = "group",
        name = L["Trigger"],
        order = 20,
        args = {}
      },
      conditions = {
        type = "group",
        name = L["Conditions"],
        order = 25,
        args = {}
      },
      load = {
        type = "group",
        name = L["Load"],
        order = 30,
        get = function(info) return data.load[info[#info]] end,
        set = function(info, v)
          data.load[info[#info]] = (v ~= "" and v) or nil;
          WeakAuras.Add(data);
          WeakAuras.SetThumbnail(data);
          WeakAuras.ScanForLoads({[data.id] = true});
          WeakAuras.SortDisplayButtons();
        end,
        args = {}
      },
      authorOptions = {
        type = "group",
        name = L["Custom Options"],
        order = 100
      }
    }
  };

  displayOptions[id].args.action = WeakAuras.AddActionOption(id, data);
  displayOptions[id].args.animation = WeakAuras.AddAnimationOption(id, data);

  WeakAuras.ReloadTriggerOptions(data);
end

-- This is a hack...
-- Some options change which options are available, for example toggling the "inverse"
-- option of some triggers changes whether "remaining time" is available in the Conditions
-- We can't call ReloadOptions from the set call, since that removes the widgets immediately
-- which AceConfig doesn't like.
-- Thus Reload the options after a very small delay.
function WeakAuras.ScheduleReloadOptions(data)
  if (type(data.id) ~= "table") then
    C_Timer.After(0.1, function()
      WeakAuras.ReloadOptions(data.id)
    end );
  end
end

function WeakAuras.ReloadOptions(id)
  displayOptions[id] = nil;
  WeakAuras.EnsureOptions(id);
  WeakAuras.RefillOptions()
end

function WeakAuras.EnsureOptions(id)
  if not(displayOptions[id]) then
    WeakAuras.AddOption(id, WeakAuras.GetData(id));
  end
end

local scheduleRefillFrame = CreateFrame("FRAME", "", UIParent)
scheduleRefillFrame.OnUpdate = function()
  for id, data in pairs(scheduleRefillFrame.ids) do
    if not(displayOptions[id]) then
      WeakAuras.AddOption(id, data);
    end
  end
  wipe(scheduleRefillFrame.ids)

  frame:RefillOptions()
  frame:SetScript("OnUpdate", nil)
end

scheduleRefillFrame.ScheduleRefillOnly = function()
  frame:SetScript("OnUpdate", scheduleRefillFrame.OnUpdate)
end
scheduleRefillFrame.ScheduleReload = function(self, id, data)
  scheduleRefillFrame.ids[id] = data
  scheduleRefillFrame:ScheduleRefillOnly()
end

scheduleRefillFrame.ids = {}


-- TODO replace older ReloadOptions, SchduleReloadOptions, ReloadTriggerOptions, ReloadGroupRegionOptions
-- automatically clear parent/tempGroup ?
function WeakAuras.ReloadOptions2(id, data)
  displayOptions[id] = nil
  scheduleRefillFrame:ScheduleReload(id, data)
end

function WeakAuras.RefillOptions()
  frame:RefillOptions()
end

function WeakAuras.SchduleRefillOptions()
   scheduleRefillFrame:ScheduleRefillOnly()
end


function WeakAuras.GetSpellTooltipText(id)
  local tooltip = WeakAuras.GetHiddenTooltip();
  tooltip:SetSpellByID(id);
  local lines = { tooltip:GetRegions() };
  local i = 1;
  local tooltipText = "";
  while(lines[i]) do
    if(lines[i]:GetObjectType() == "FontString") then
      if(lines[i]:GetText()) then
        if(tooltipText == "") then
          tooltipText = lines[i]:GetText();
        else
          tooltipText = tooltipText.." - "..lines[i]:GetText();
        end
      end
    end
    i = i + 1;
  end
  tooltipText = tooltipText or L["No tooltip text"];
  return tooltipText;
end

local function DeleteConditionsForTriggerHandleSubChecks(checks, triggernum)
  for _, check in ipairs(checks) do
    if (check.trigger == triggernum) then
      check.trigger = nil;
    end

    if (check.trigger and check.trigger > triggernum) then
      check.trigger = check.trigger - 1;
    end

    if (checks.checks) then
      DeleteConditionsForTriggerHandleSubChecks(checks.checks, triggernum);
    end
  end
end

function WeakAuras.DeleteConditionsForTrigger(data, triggernum)
  for _, condition in ipairs(data.conditions) do
    if (condition.check and condition.check.trigger == triggernum) then
      condition.check.trigger = nil;
    end

    if (condition.check and condition.check.trigger and condition.check.trigger > triggernum) then
      condition.check.trigger = condition.check.trigger - 1;
    end

    if (condition.check and condition.check.checks) then
      DeleteConditionsForTriggerHandleSubChecks(condition.check.checks, triggernum)
    end
  end
end

function WeakAuras.ReloadTriggerOptions(data)
  local id = data.id;
  local iconCache = spellCache.Get();
  WeakAuras.EnsureOptions(id);

  local appendToTriggerPath, appendToUntriggerPath;
  if(data.controlledChildren) then
    optionTriggerChoices[id] = nil;
    for index, childId in pairs(data.controlledChildren) do
      if not(optionTriggerChoices[id]) then
        optionTriggerChoices[id] = optionTriggerChoices[childId];
      else
        if(optionTriggerChoices[id] ~= optionTriggerChoices[childId]) then
          optionTriggerChoices[id] = -1;
          break;
        end
      end
    end

    optionTriggerChoices[id] = optionTriggerChoices[id] or 1;

    local commonOptionTriggerChoice = optionTriggerChoices[id] >= 1 and optionTriggerChoices[id];
    for index, childId in pairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        optionTriggerChoices[childId] = commonOptionTriggerChoice or optionTriggerChoices[childId] or 1;
        WeakAuras.ReloadTriggerOptions(childData);
      end
    end
  else
    optionTriggerChoices[id] = min(optionTriggerChoices[id] or 1, #data.triggers);
    local triggerChoice = optionTriggerChoices[id]
    -- TODO: remove this once legacy aura trigger is removed
    local button = displayButtons[id]
    if (button) then
      button:RefreshBT2UpgradeIcon()
    end
  end

  local function deleteTrigger()
    if(data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          if #childData.triggers > 1 then
            tremove(childData.triggers, optionTriggerChoices[childId])
            WeakAuras.DeleteConditionsForTrigger(childData, optionTriggerChoices[childId]);
            optionTriggerChoices[childId] = max(1, optionTriggerChoices[childId] - 1)
            WeakAuras.ReloadTriggerOptions(childData);
          end
        end
      end
    else
      tremove(data.triggers, optionTriggerChoices[id])
      WeakAuras.DeleteConditionsForTrigger(data, optionTriggerChoices[id]);
      optionTriggerChoices[id] = max(1, optionTriggerChoices[id] - 1)
    end
    WeakAuras.Add(data);
    WeakAuras.ReloadTriggerOptions(data);
  end

  local function moveTriggerDownConditionCheck(check, i)
    if (check.trigger == i) then
      check.trigger = i + 1;
    elseif (check.trigger == i  + 1) then
      check.trigger = i;
    end
    if (check.checks) then
      for _, subCheck in ipairs(check.checks) do
        moveTriggerDownConditionCheck(subCheck, i);
      end
    end
  end

  local function moveTriggerDownImpl(data, i)
    if (i < 1 or i >= #data.triggers) then
      return false;
    end
    data.triggers[i], data.triggers[i + 1] = data.triggers[i + 1], data.triggers[i]
    for _, condition in ipairs(data.conditions) do
      moveTriggerDownConditionCheck(condition.check, i);
    end

    return true;
  end

  local function moveTriggerDown(data, i)
    if (moveTriggerDownImpl(data, i)) then
      optionTriggerChoices[data.id] = optionTriggerChoices[data.id] + 1;
      WeakAuras.Add(data);
      WeakAuras.ReloadTriggerOptions(data);
    end
  end

  local function moveTriggerUp(data, i)
    if (moveTriggerDownImpl(data, i - 1)) then
      optionTriggerChoices[data.id] = optionTriggerChoices[data.id] - 1;
      WeakAuras.Add(data);
      WeakAuras.ReloadTriggerOptions(data);
    end
  end


  local chooseTriggerWidth = 1.2;
  if (data.controlledChildren) then
    local hasMultipleTriggers = false;
    for index, id in pairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(id);
      if (#childData.triggers ~=1) then
        hasMultipleTriggers = true;
        break;
      end
    end
    if (not hasMultipleTriggers) then
      chooseTriggerWidth = chooseTriggerWidth + 0.45;
    end
  else
    if (#data.triggers == 1) then
      chooseTriggerWidth = chooseTriggerWidth + 0.45;
    end
  end

  if (GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") == 0) then
    chooseTriggerWidth = chooseTriggerWidth + 0.15;
  end

  local trigger;
  if (not data.controlledChildren) then
    local triggerNum = optionTriggerChoices[id];
    trigger = data.triggers[triggerNum].trigger;
  end

  local trigger_types = {};
  for type, triggerSystem in pairs(WeakAuras.triggerTypes) do
    trigger_types[type] = triggerSystem.GetName(type);
  end
  local trigger_options = {
    disjunctive = {
      type = "select",
      name = L["Required for Activation"],
      width = WeakAuras.doubleWidth,
      order = 0,
      values = function()
        if #data.triggers > 1 then
          return WeakAuras.trigger_require_types;
        else
          return  WeakAuras.trigger_require_types_one;
        end
      end,
      get = function()
        if #data.triggers > 1 then
          return data.triggers.disjunctive or "all";
        else
          return (data.triggers.disjunctive and data.triggers.disjunctive ~= "all") and data.triggers.disjunctive or "any";
        end
      end,
      set = function(info, v)
        data.triggers.disjunctive = v;
        WeakAuras.Add(data);
      end
    },
    -- custom trigger combiner text editor added below
    activeTriggerMode = {
      type = "select",
      name = L["Dynamic Information"],
      width = WeakAuras.doubleWidth,
      order = 0.3,
      values = function()
        local vals = {};
        vals[WeakAuras.trigger_modes.first_active] = L["Dynamic information from first active trigger"];
        for i = 1, #data.triggers do
          vals[i] = L["Dynamic information from Trigger %i"]:format(i);
        end
        return vals;
      end,
      get = function()
        return data.triggers.activeTriggerMode or WeakAuras.trigger_modes.first_active;
      end,
      set = function(info, v)
        data.triggers.activeTriggerMode = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      hidden = function() return #data.triggers <= 1 end
    },
    chooseTrigger = {
      type = "select",
      name = L["Choose Trigger"],
      order = 0.5,
      values = function()
        local ret = {};
        if(data.controlledChildren) then
          for index = 1, #data.triggers do
            local all, none, any = true, true, false;
            for _, childId in pairs(data.controlledChildren) do
              local childData = WeakAuras.GetData(childId);
              if(childData) then
                none = false;
                if childData.triggers[index] then
                  any = true;
                else
                  all = false;
                end
              end
            end
            if not(none) then
              if(all) then
                ret[index] = L["Trigger %d"]:format(index);
              elseif(any) then
                ret[index] = "|cFF777777"..L["Trigger %d"]:format(index);
              end
            end
          end
        else
          for i = 1, #data.triggers do
            ret[i] = L["Trigger %d"]:format(i);
          end
        end
        return ret;
      end,
      get = function() return optionTriggerChoices[id]; end,
      set = function(info, v)
        if data.triggers[v] then
          optionTriggerChoices[id] = v;
          WeakAuras.ReloadTriggerOptions(data);
        end
      end,
      width = chooseTriggerWidth
    },
    chooseTriggerSpace = {
      type = "description",
      name = "",
      order = 0.75,
      width = 0.04
    },
    addTrigger = {
      type = "execute",
      name = L["Add Trigger"],
      order = 1,
      func = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            if(childData) then
              tinsert(childData.triggers, {trigger = {}, untrigger = {}});
              optionTriggerChoices[childId] = #childData.triggers;
              WeakAuras.ReloadTriggerOptions(childData);
            end
          end
        else
          tinsert(data.triggers, {trigger = {}, untrigger = {}});
          optionTriggerChoices[id] = #data.triggers;
        end
        WeakAuras.ReloadTriggerOptions(data);
      end,
      width = 0.15,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\add",
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon"
    },
    deleteTrigger = {
      type = "execute",
      name = L["Delete Trigger"],
      order = 1.1,
      func = deleteTrigger,
      hidden = function()
        return #data.triggers < 2
      end,
      width = 0.15,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon"
    },
    triggerUp = {
      type = "execute",
      name = L["Up"],
      order = 1.2,
      func = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            moveTriggerUp(childData, optionTriggerChoices[childId])
          end
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        else
          moveTriggerUp(data, optionTriggerChoices[id])
        end
      end,
      disabled = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            if(childData) then
              if (optionTriggerChoices[childId] ~= 1) then
                return false;
              end
            end
          end
          return true;
        else
          if (optionTriggerChoices[id] == 1) then
            return true;
          else
            return false;
          end
        end
      end,
      hidden = function()
        return #data.triggers < 2
      end,
      width = 0.15,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon"
    },
    triggerDown = {
      type = "execute",
      name = L["Down"],
      order = 1.3,
      func = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            moveTriggerDown(childData, optionTriggerChoices[childId]);
          end
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        else
          moveTriggerDown(data, optionTriggerChoices[id]);
        end
      end,
      disabled = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            if(childData) then
              if (optionTriggerChoices[childId] ~= #childData.triggers) then
                return false;
              end
            end
          end
          return true;
        else
          if (optionTriggerChoices[id] ~= #data.triggers) then
            return false;
          else
            return true;
          end
        end
      end,
      hidden = function()
        return #data.triggers < 2
      end,
      width = 0.15,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon"
    },
    applyTemplate = {
      type = "execute",
      name = L["Apply Template"],
      order = 1.4,
      func = function()
        WeakAuras.OpenTriggerTemplate(data);
      end,
      hidden = function()
        return GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") == 0
      end,
      width = 0.15,
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\template",
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon"
    },
    triggerHeader = {
      type = "header",
      name = function(info)
        if(info == "default") then
          return L["Multiple Triggers"];
        else
          return L["Trigger %d"]:format(optionTriggerChoices[id]);
        end
      end,
      order = 2
    },
    typedesc = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Type"],
      order = 5,
      disabled = true,
      get = function() return true end
    },
    type = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Type"],
      desc = L["The type of trigger"],
      order = 6,
      values = trigger_types,
      set = function(info, v)
        trigger.type = v;
        if(trigger.event) then
          local prototype = WeakAuras.event_prototypes[trigger.event];
          if(prototype) then
            if(v == "status" and prototype.type == "event") then
              trigger.event = "Health";
            elseif(v == "event" and prototype.type == "status") then
              trigger.event = "Chat Message";
            end
          end
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    },
  };

  local function hideTriggerCombiner()
    return not (data.triggers.disjunctive == "custom")
  end
  WeakAuras.AddCodeOption(trigger_options, data, L["Custom"], "custom_trigger_combination", 0.1, hideTriggerCombiner, {"triggers", "customTriggerLogic"}, false);

  local order = 81;

  if(data.controlledChildren) then
    local function options_set(info, ...)
      setAll(data, info, ...);
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ReloadTriggerOptions(data);
    end

    local commontriggerSystemOptionsFunction = nil;
    local first = true;

    local anyOldAuraTriggers = false;
    for index, childId in ipairs(data.controlledChildren) do
      local triggerChoice = optionTriggerChoices[childId];
      local childData = WeakAuras.GetData(childId);
      local trigger = triggerChoice and childData.triggers[triggerChoice].trigger;
      local triggerSystemOptionsFunction = trigger.type and WeakAuras.triggerTypesOptions[trigger.type];
      if (trigger.type == "aura") then
        anyOldAuraTriggers = true;
      end
      if (triggerSystemOptionsFunction) then
        if (first) then
          commontriggerSystemOptionsFunction = triggerSystemOptionsFunction
          first = false;
        elseif(commontriggerSystemOptionsFunction ~= triggerSystemOptionsFunction) then
          commontriggerSystemOptionsFunction = nil;
        end
      end
    end

    if (commontriggerSystemOptionsFunction) then
      trigger_options = union(trigger_options, commontriggerSystemOptionsFunction(data, optionTriggerChoices));
    end
    if (anyOldAuraTriggers) then
      trigger_options = union(trigger_options, WeakAuras.GetBuffConversionOptions(data, optionTriggerChoices));
    end
    displayOptions[id].args.trigger.args = trigger_options;

    removeFuncs(displayOptions[id]);
    replaceNameDescFuncs(displayOptions[id], data);
    replaceImageFuncs(displayOptions[id], data);
    replaceValuesFuncs(displayOptions[id], data);

    displayOptions[id].get = function(info, ...) return getAll(data, info, ...); end;
    displayOptions[id].set = function(info, ...)
      setAll(data, info, ...);
      if(type(id) == "string") then
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    end
    displayOptions[id].hidden = function(info, ...) return hiddenAll(data, info, ...); end;
    displayOptions[id].disabled = function(info, ...) return disabledAll(data, info, ...); end;

    displayOptions[id].args.trigger.args.chooseTrigger.set = options_set;
    if (displayOptions[id].args.trigger.args.type) then
      displayOptions[id].args.trigger.args.type.set = options_set;
    end
    if (displayOptions[id].args.trigger.args.event) then
      displayOptions[id].args.trigger.args.event.set = options_set;
    end

    local regionOption;
    if (regionOptions[data.regionType]) then
      regionOption = regionOptions[data.regionType].create(id, data);
    else
      regionOption = {
        [data.regionType] = {
          __title = "|cFFFFFF00" .. data.regionType,
          __order = 1,
          unsupported = {
            type = "description",
            name = L["This region of type \"%s\" is not supported."]:format(data.regionType)
          }
        };
      };
    end
    displayOptions[id].args.group = {
      type = "group",
      name = L["Group"],
      order = 0,
      get = function(info)
        local base, property = parsePrefix(info[#info], data);
        if not base then
          return nil
        end
        if(info.type == "color") then
          base[property] = base[property] or {};
          local c = base[property];
          return c[1], c[2], c[3], c[4];
        else
          return base[property];
        end
      end,
      set = function(info, v, g, b, a)
        local base, property = parsePrefix(info[#info], data, true);
        if(info.type == "color") then
          base[property] = base[property] or {};
          local c = base[property];
          c[1], c[2], c[3], c[4] = v, g, b, a;
        elseif(info.type == "toggle") then
          base[property] = v;
        else
          base[property] = (v ~= "" and v) or nil;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.ResetMoverSizer();
      end,
      hidden = function() return false end,
      disabled = function() return false end,
      args = flattenRegionOptions(regionOption, true);
    };

    data.load.use_class = getAll(data, {"load", "use_class"});
    local single_class = getAll(data, {"load", "class"});
    data.load.class = {
      single = single_class,
      multi = {},
    }

    displayOptions[id].args.load.args = WeakAuras.ConstructOptions(WeakAuras.load_prototype, data, 10, optionTriggerChoices[id], "load");
    removeFuncs(displayOptions[id].args.load);
    replaceNameDescFuncs(displayOptions[id].args.load, data);
    replaceImageFuncs(displayOptions[id].args.load, data);
    replaceValuesFuncs(displayOptions[id].args.load, data);

    WeakAuras.ReloadGroupRegionOptions(data);
  else -- One aura selected
    local triggerChoice = optionTriggerChoices[id];
    local trigger, untrigger = data.triggers[triggerChoice].trigger, data.triggers[triggerChoice].untrigger;
    local function options_set(info, v)
      trigger[info[#info]] = v;
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ReloadTriggerOptions(data);
    end
    local triggerSystemOptionsFunction = trigger.type and WeakAuras.triggerTypesOptions[trigger.type];
    if (triggerSystemOptionsFunction) then
      trigger_options = union(trigger_options, triggerSystemOptionsFunction(data, optionTriggerChoices));
    end
    if (trigger.type == "aura") then
      trigger_options = union(trigger_options, WeakAuras.GetBuffConversionOptions(data, optionTriggerChoices));
    end

    displayOptions[id].args.trigger.args = trigger_options;
    displayOptions[id].args.load.args = WeakAuras.ConstructOptions(WeakAuras.load_prototype, data, 10, optionTriggerChoices[id], "load");

    if (displayOptions[id].args.trigger.args.event) then
      displayOptions[id].args.trigger.args.event.set = function(info, v, ...)
        local prototype = WeakAuras.event_prototypes[v];
        if(prototype) then
          if(prototype.automatic or prototype.automaticrequired) then
            trigger.unevent = "auto";
          else
            trigger.unevent = "timed";
          end
        end
        options_set(info, v, ...);
      end
    end
    trigger.event = trigger.event or "Health";
    trigger.subeventPrefix = trigger.subeventPrefix or "SPELL"
    trigger.subeventSuffix = trigger.subeventSuffix or "_CAST_START";

    displayOptions[id].args.trigger.get = function(info, index)
      local childOption = getChildOption(displayOptions[id], info)
      if childOption.type == "multiselect" then
        return trigger[info[#info]] and trigger[info[#info]][index]
      else
        return trigger[info[#info]]
      end
    end;
    displayOptions[id].args.trigger.set = function(info, arg1, arg2)
      local childOption = getChildOption(displayOptions[id], info)
      if childOption.type == "multiselect" then
        local index, value = arg1, arg2
        if type(trigger[info[#info]]) ~= "table" then
          trigger[info[#info]] = {}
        end
        if value ~= nil then
          if value then
            trigger[info[#info]][index] = true
          else
            trigger[info[#info]][index] = nil
          end
        else
          if trigger[info[#info]][index] then
            trigger[info[#info]][index] = nil
          else
            trigger[info[#info]][index] = true
          end
        end
        local next = next
        if next(trigger[info[#info]]) == nil then
          trigger[info[#info]] = nil
        end
      else
        trigger[info[#info]] = (arg1 ~= "" and arg1) or nil;
      end

      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ReloadTriggerOptions(data);
    end;
  end

  displayOptions[id].args.authorOptions.args = {}
  displayOptions[id].args.authorOptions.hidden = function()
    return false;
  end
  displayOptions[id].args.authorOptions.disabled = function()
    return false;
  end
  WeakAuras.GetAuthorOptions(data, displayOptions[id].args.authorOptions.args, 0)

  displayOptions[id].args.conditions.args = {};
  -- We never want the condition options to use the hiddenAll, disabledAll functions
  displayOptions[id].args.conditions.hidden = function()
    return false;
  end
  displayOptions[id].args.conditions.disabled = function()
    return false;
  end
  WeakAuras.GetConditionOptions(data, displayOptions[id].args.conditions.args, "conditions", 0, nil);

  if(type(id) ~= "string") then
    displayOptions[id].args.group = nil;
  end
end

local function fixMetaOrders(allOptions)
  -- assumes that the results from create methods are contiguous in __order fields
  -- shifts __order fields such that each optionGroup is ordered correctly relative
  -- to its peers, but has a unique __order number in the combined option table.
  local groupOrders = {}
  local maxGroupOrder = 0
  for optionGroup, options in pairs(allOptions) do
    local metaOrder = options.__order
    groupOrders[metaOrder] = groupOrders[metaOrder] or {}
    maxGroupOrder = max(maxGroupOrder, metaOrder)
    tinsert(groupOrders[metaOrder], optionGroup)
  end

  local index = 0
  local newOrder = 1
  while index <= maxGroupOrder do
    index = index + 1
    if groupOrders[index] then
      table.sort(groupOrders[index])
      for _, optionGroup in ipairs(groupOrders[index]) do
        allOptions[optionGroup].__order = newOrder
        newOrder = newOrder + 1
      end
    end
  end
end

function WeakAuras.ReloadGroupRegionOptions(data)
  local regionTypes = {};
  local id = data.id;
  WeakAuras.EnsureOptions(id);
  local options = displayOptions[id];
  local allOptions = {};
  local commonOption = {};
  local unsupportedCount = 0
  local supportedSubRegions = {}
  local hasSubElements = false
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if childData and not regionTypes[childData.regionType] then
      regionTypes[childData.regionType] = true;
      if regionOptions[childData.regionType] then
        allOptions = union(allOptions, regionOptions[childData.regionType].create(id, data));
      else
        unsupportedCount = unsupportedCount + 1
        allOptions["__unsupported" .. unsupportedCount] =  {
          __title = "|cFFFFFF00" .. childData.regionType,
          __order = 1,
          warning = {
            type = "description",
            name = L["Regions of type \"%s\" are not supported."]:format(childData.regionType),
            order = 1
          },
        }
      end
      for subRegionName, subRegionType in pairs(WeakAuras.subRegionTypes) do
        if subRegionType.supports(childData.regionType) then
          supportedSubRegions[subRegionName] = true
        end
      end
    end
    if childData.subRegions then
      local subIndex = {}
      for index, subRegionData in ipairs(childData.subRegions) do
        local subRegionType = subRegionData.type
        if WeakAuras.subRegionOptions[subRegionType] then
          hasSubElements = true
          subIndex[subRegionType] = subIndex[subRegionType] and subIndex[subRegionType] + 1 or 1
          local options, common = WeakAuras.subRegionOptions[subRegionType].create(data, subRegionData, index, subIndex[subRegionType])
          options.__order = 200 + index
          allOptions["sub." .. index .. "." .. subRegionType] = options
          commonOption[subRegionType] = common
        end
      end
    end
  end

  local commonOptionIndex = 0
  for option, optionData in pairs(commonOption) do
    commonOptionIndex = commonOptionIndex + 1
    optionData.__order = 100 + commonOptionIndex
    allOptions[option] = optionData
  end

  hasSubElements = AddOptionsForSupportedSubRegion(allOptions, data, supportedSubRegions) or hasSubElements

  if hasSubElements then
    allOptions["SubElementsHeader"] = {
      __order = 100,
      __noHeader = true,
      header = {
        order = 1,
        type = "header",
        name = L["Sub Elements"],
      }
    }
  end

  fixMetaOrders(allOptions);

  local regionOption = flattenRegionOptions(allOptions, false);

  replaceNameDescFuncs(regionOption, data);
  replaceImageFuncs(regionOption, data);
  replaceValuesFuncs(regionOption, data);
  removeFuncs(regionOption);

  options.args.region.args = regionOption;
end

function WeakAuras.PositionOptions(id, data, _, hideWidthHeight, disableSelfPoint)
  local metaOrder = 99
  local function IsParentDynamicGroup()
    return data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup";
  end

  local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
  local positionOptions = {
    __title = L["Position Settings"],
    __order = metaOrder,
    width = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Width"],
      order = 60,
      min = 1,
      softMax = screenWidth,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    height = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Height"],
      order = 61,
      min = 1,
      softMax = screenHeight,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    xOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["X Offset"],
      order = 62,
      softMin = (-1 * screenWidth),
      softMax = screenWidth,
      bigStep = 10,
      get = function() return data.xOffset end,
      set = function(info, v)
        data.xOffset = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
        if(data.parent) then
          local parentData = WeakAuras.GetData(data.parent);
          if(parentData) then
            WeakAuras.Add(parentData);
            WeakAuras.SetThumbnail(parentData);
          end
        end
      end
    },
    yOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Y Offset"],
      order = 63,
      softMin = (-1 * screenHeight),
      softMax = screenHeight,
      bigStep = 10,
      get = function() return data.yOffset end,
      set = function(info, v)
        data.yOffset = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
        if(data.parent) then
          local parentData = WeakAuras.GetData(data.parent);
          if(parentData) then
            WeakAuras.Add(parentData);
            WeakAuras.SetThumbnail(parentData);
          end
        end
      end
    },
    selfPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchor"],
      order = 70,
      hidden = IsParentDynamicGroup,
      values = point_types,
      disabled = disableSelfPoint,
    },
    anchorFrameType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchored To"],
      order = 72,
      hidden = IsParentDynamicGroup,
      values = WeakAuras.anchor_frame_types,
    },
    -- Input field to select frame to anchor on
    anchorFrameFrame = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Frame"],
      order = 72.2,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        return not (data.anchorFrameType == "SELECTFRAME")
      end
    },
    -- Button to select frame to anchor on
    chooseAnchorFrameFrame = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Choose"],
      order = 72.4,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        return not (data.anchorFrameType == "SELECTFRAME")
      end,
      func = function()
        WeakAuras.StartFrameChooser(data, {"anchorFrameFrame"});
      end
    },
    anchorPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = function()
        if (data.anchorFrameType == "SCREEN") then
          return L["To Screen's"]
        elseif (data.anchorFrameType == "PRD") then
          return L["To Personal Ressource Display's"];
        elseif (data.anchorFrameType == "SELECTFRAME" or data.anchorFrameType == "CUSTOM") then
          return L["To Frame's"];
        end
      end,
      order = 75,
      hidden = function()
        if (data.parent) then
          --if (IsParentDynamicGroup()) then
          --  return true;
          --end
          return data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE";
        else
          return data.anchorFrameType == "MOUSE";
        end
      end,
      values = point_types
    },
    anchorPointGroup = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = function() return L["to group's"] end,
      order = 76,
      hidden = function()
        if (data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        if (data.parent) then
          return IsParentDynamicGroup();
        end
        return true;
      end,
      disabled = true,
      values = {["CENTER"] = L["Anchor Point"]},
      get = function() return "CENTER"; end
    },
    anchorFrameParent = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Set Parent to Anchor"],
      desc = L["Sets the anchored frame as the aura's parent, causing the aura to inherit attributes such as visiblility and scale."],
      order = 77,
      get = function()
        return data.anchorFrameParent or data.anchorFrameParent == nil;
      end,
      hidden = function()
        return (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE" or IsParentDynamicGroup());
      end,
    },
    frameStrata = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Frame Strata"],
      order = 78,
      values = WeakAuras.frame_strata_types
    },
    anchorFrameSpace = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = "",
      order = 79,
      image = function() return "", 0, 0 end,
      hidden = function()
        return not (data.anchorFrameType ~= "SCREEN" or IsParentDynamicGroup());
      end
    },
  };
  WeakAuras.AddCodeOption(positionOptions, data, L["Custom Anchor"], "custom_anchor", 72.1, function() return not(data.anchorFrameType == "CUSTOM" and not IsParentDynamicGroup()) end, {"customAnchor"}, nil, nil, nil, nil, nil, true)
  return positionOptions;
end

function WeakAuras.GlowOptions(id, data, order)
  local hiddenGlowExtra = function()
    return WeakAuras.IsCollapsed("glow", "glow", "glowextra", true);
  end

  local indentWidth = 0.15

  local glowOptions = {
    glowHeader = {
      type = "header",
      order = order,
      name = L["Glow Settings"]
    },
    glow = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Glow"],
      order = order + 0.02,
    },
    glowType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Type"],
      order = order + 0.03,
      values = WeakAuras.glow_types,
    },
    glowExtraDescription = {
      type = "description",
      name = function()
        local line = L["|cFFffcc00Extra Options:|r"]
        local color = L["Default Color"]
        if data.useGlowColor then
          color = L["|c%02x%02x%02x%02xColor|r"]:format(
            data.glowColor[4] * 255,
            data.glowColor[1] * 255,
            data.glowColor[2] * 255,
            data.glowColor[3] * 255
          )
        end
        if data.glowType == "buttonOverlay" then
          line = ("%s %s"):format(line, color)
        elseif data.glowType == "ACShine" then
          line = L["%s %s, Particles: %d, Frequency: %0.2f, Scale: %0.2f"]:format(
            line,
            color,
            data.glowLines,
            data.glowFrequency,
            data.glowScale
          )
          if data.glowXOffset ~= 0 or data.glowYOffset ~= 0 then
            line = L["%s, offset: %0.2f;%0.2f"]:format(line, data.glowXOffset, data.glowYOffset)
          end
        elseif data.glowType == "Pixel" then
          line = L["%s %s, Lines: %d, Frequency: %0.2f, Length: %d, Thickness: %d"]:format(
            line,
            color,
            data.glowLines,
            data.glowFrequency,
            data.glowLength,
            data.glowThickness
          )
          if data.glowXOffset ~= 0 or data.glowYOffset ~= 0 then
            line = L["%s, Offset: %0.2f;%0.2f"]:format(line, data.glowXOffset, data.glowYOffset)
          end
          if data.glowBorder then
            line = L["%s, Border"]:format(line)
          end
        end
        return line
      end,
      width = WeakAuras.doubleWidth - 0.15,
      order = order + 1,
      fontSize = "medium"
    },
    glowExpand = {
      type = "execute",
      name = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra", true)
        return collapsed and L["Show Extra Options"] or L["Hide Extra Options"]
      end,
      order = order + 1.01,
      width = 0.15,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra", true);
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24,
      func = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra", true);
        WeakAuras.SetCollapsed("glow", "glow", "glowextra", not collapsed);
      end,
      control = "WeakAurasIcon"
    },
    glow_space1 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.10,
      hidden = hiddenGlowExtra,
    },
    useGlowColor = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Color"],
      desc = L["If unchecked, then a default color will be used (usually yellow)"],
      order = order + 1.11,
      hidden = hiddenGlowExtra
    },
    glowColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      order = order + 1.12,
      disabled = function() return not data.useGlowColor end,
      hidden = hiddenGlowExtra
    },
    glow_space2 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.20,
      hidden = hiddenGlowExtra,
    },
    glowLines = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Lines & Particles"],
      order = order + 1.21,
      min = 1,
      softMax = 30,
      step = 1,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glowFrequency = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Frequency"],
      order = order + 1.22,
      softMin = -2,
      softMax = 2,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glow_space3 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.30,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowLength = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Length"],
      order = order + 1.31,
      min = 1,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowThickness = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = order + 1.32,
      min = 0.05,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glow_space4 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.40,
      hidden = hiddenGlowExtra,
    },
    glowXOffset = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["X-Offset"],
      order = order + 1.41,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glowYOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Y-Offset"],
      order = order + 1.42,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glow_space5 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.50,
      hidden = hiddenGlowExtra,
    },
    glowScale = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Scale"],
      order = order + 1.52,
      min = 0.05,
      softMax = 10,
      step = 0.05,
      isPercent = true,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "ACShine" end,
    },
    glowBorder = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Border"],
      order = order + 1.53,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    }
  }

  return glowOptions
end

-- TODO: update this function to not have an unused parameter
function WeakAuras.BorderOptions(id, data, showBackDropOptions, hiddenFunc, order)
  local borderOptions = {
    borderHeader = {
      type = "header",
      order = order,
      name = L["Border Settings"],
      hidden = hiddenFunc,
    },
    border = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Border"],
      order = order + 0.1,
      hidden = hiddenFunc,
    },
    borderEdge = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Border",
      name = L["Border Style"],
      order = order + 0.2,
      values = AceGUIWidgetLSMlists.border,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderBackdrop = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Background",
      name = L["Backdrop Style"],
      order = order + 0.3,
      values = AceGUIWidgetLSMlists.background,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = order + 0.3,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Border Size"],
      order = order + 0.4,
      softMin = 1,
      softMax = 64,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderInset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Border Inset"],
      order = order + 0.5,
      softMin = 1,
      softMax = 32,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    border_spacer = {
      type = "description",
      name = "",
      width = WeakAuras.normalWidth,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
      order = order + 0.6
    },
    borderColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Border Color"],
      hasAlpha = true,
      order = order + 0.7,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderInFront  = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Border in Front"],
      order = order + 0.8,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border or not showBackDropOptions end,
    },
    backdropColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Backdrop Color"],
      hasAlpha = true,
      order = order + 0.9,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    backdropInFront  = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Backdrop in Front"],
      order = order + 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border or not showBackDropOptions end,
    },
  }

  return borderOptions;
end

function WeakAuras.OpenTextEditor(...)
  frame.texteditor:Open(...);
end

function WeakAuras.ExportToString(id)
  frame.importexport:Open("export", id);
end

function WeakAuras.ExportToTable(id)
  frame.importexport:Open("table", id);
end

function WeakAuras.ImportFromString()
  frame.importexport:Open("import");
end

function WeakAuras.CloseImportExport()
  frame.codereview:Close();
  frame.importexport:Close();
end

function WeakAuras.ConvertDisplay(data, newType)
  local id = data.id;
  -- thumbnails[id].region:SetScript("OnUpdate", nil);
  thumbnails[id].region:Hide();
  thumbnails[id] = nil;
  local visibility = displayButtons[id]:GetVisibility();
  displayButtons[id]:PriorityHide(0);

  WeakAuras.regions[id].region:Collapse();
  WeakAuras.CollapseAllClones(id);

  WeakAuras.Convert(data, newType);
  displayButtons[id]:SetViewRegion(WeakAuras.regions[id].region);
  displayButtons[id]:Initialize();
  displayButtons[id]:PriorityShow(visibility);
  displayOptions[id] = nil;
  WeakAuras.AddOption(id, data);
  frame:FillOptions(displayOptions[id]);
  WeakAuras.UpdateDisplayButton(data);
  frame.mover.moving.region = WeakAuras.regions[id].region;
  WeakAuras.ResetMoverSizer();
end

function WeakAuras.NewDisplayButton(data)
  local id = data.id;
  WeakAuras.ScanForLoads({[id] = true});
  WeakAuras.EnsureDisplayButton(db.displays[id]);
  WeakAuras.UpdateDisplayButton(db.displays[id]);
  if(WeakAuras.regions[id].region.SetStacks) then
    WeakAuras.regions[id].region:SetStacks(1);
  end
  frame.buttonsScroll:AddChild(displayButtons[id]);
  WeakAuras.AddOption(id, data);
  WeakAuras.SetIconNames(data);
  WeakAuras.SortDisplayButtons();
end

function WeakAuras.UpdateGroupOrders(data)
  if(data.controlledChildren) then
    local total = #data.controlledChildren;
    for index, id in pairs(data.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(id);
      button:SetGroupOrder(index, total);
    end
  end
end

function WeakAuras.UpdateButtonsScroll()
  if WeakAuras.IsOptionsProcessingPaused() then return end
  frame.buttonsScroll:DoLayout()
end

local previousFilter;
function WeakAuras.SortDisplayButtons(filter, overrideReset, id)
  if (WeakAuras.IsOptionsProcessingPaused()) then
    return;
  end
  local recenter = false;
  filter = filter or (overrideReset and previousFilter or "");
  if(frame.filterInput:GetText() ~= filter) then
    frame.filterInput:SetText(filter);
  end
  if(previousFilter and previousFilter ~= "" and (filter == "" or not filter)) then
    recenter = true;
  end
  previousFilter = filter;
  filter = filter:lower();

  wipe(frame.buttonsScroll.children);
  tinsert(frame.buttonsScroll.children, frame.newButton);
  if(frame.addonsButton) then
    tinsert(frame.buttonsScroll.children, frame.addonsButton);
  end
  tinsert(frame.buttonsScroll.children, frame.loadedButton);
  local numLoaded = 0;
  local to_sort = {};
  local children = {};
  local containsFilter = false;
  for id, child in pairs(displayButtons) do
    containsFilter = false;
    local data = WeakAuras.GetData(id);
    if not(data) then
      print("|cFF8800FFWeakAuras|r: No data for", id);
    else
      if(filter and data.controlledChildren) then
        for index, childId in pairs(data.controlledChildren) do
          if(childId:lower():find(filter, 1, true)) then
            containsFilter = true;
            break;
          end
        end
      end
      if(
        frame.loadedButton:GetExpanded()
        and (not filter or id:lower():find(filter, 1, true) or containsFilter)
        ) then
        child.frame:Show();
        local group = child:GetGroup();
        if(group) then
          if(loaded[group]) then
            if(loaded[id]) then
              child:EnableLoaded();
            else
              child:DisableLoaded();
            end
            children[group] = children[group] or {};
            tinsert(children[group], child);
          end
        else
          if(loaded[id] ~= nil) then
            if(loaded[id]) then
              child:EnableLoaded();
            else
              child:DisableLoaded();
            end
            tinsert(to_sort, child);
          end
        end
      else
        child.frame:Hide();
      end
    end
  end
  table.sort(to_sort, function(a, b) return a:GetTitle() < b:GetTitle() end);
  for _, child in ipairs(to_sort) do
    tinsert(frame.buttonsScroll.children, child);
    local controlledChildren = children[child:GetTitle()];
    if(controlledChildren) then
      table.sort(controlledChildren, function(a, b) return a:GetGroupOrder() < b:GetGroupOrder(); end);
      for _, groupchild in ipairs(controlledChildren) do
        if(child:GetExpanded()) then
          tinsert(frame.buttonsScroll.children, groupchild);
        else
          groupchild.frame:Hide();
        end
      end
    end
  end

  tinsert(frame.buttonsScroll.children, frame.unloadedButton);
  local numUnloaded = 0;
  wipe(to_sort);
  wipe(children);
  for id, child in pairs(displayButtons) do
    containsFilter = false;
    local data = WeakAuras.GetData(id);
    if(filter and data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        if(childId:lower():find(filter, 1, true)) then
          containsFilter = true;
          break;
        end
      end
    end
    if(
      frame.unloadedButton:GetExpanded()
      and (not filter or id:lower():find(filter, 1, true) or containsFilter)
      ) then
      local group = child:GetGroup();
      if(group) then
        if not(loaded[group]) then
          if(loaded[id]) then
            child:EnableLoaded();
          else
            child:DisableLoaded();
          end
          children[group] = children[group] or {};
          tinsert(children[group], child);
        end
      else
        if(loaded[id] == nil) then
          child:DisableLoaded();
          tinsert(to_sort, child);
        end
      end
    else
      child.frame:Hide();
    end
  end
  table.sort(to_sort, function(a, b) return a:GetTitle() < b:GetTitle() end);
  for _, child in ipairs(to_sort) do
    tinsert(frame.buttonsScroll.children, child);
    local controlledChildren = children[child:GetTitle()];
    if(controlledChildren) then
      table.sort(controlledChildren, function(a, b) return a:GetGroupOrder() < b:GetGroupOrder(); end);
      for _, groupchild in ipairs(controlledChildren) do
        if(child:GetExpanded()) then
          tinsert(frame.buttonsScroll.children, groupchild);
        else
          groupchild.frame:Hide();
        end
      end
    end
  end

  frame.buttonsScroll:DoLayout();
  if(recenter) then
    frame:CenterOnPicked();
  end
end

WeakAuras.afterScanForLoads = function()
  if(frame) then
    if (frame:IsVisible()) then
      WeakAuras.SortDisplayButtons(nil, true);
    else
      frame.needsSort = true;
    end
  end
end

function WeakAuras.IsPickedMultiple()
  if(frame.pickedDisplay == tempGroup) then
    return true;
  else
    return false;
  end
end

function WeakAuras.IsDisplayPicked(id)
  if(frame.pickedDisplay == tempGroup) then
    for index, childId in pairs(tempGroup.controlledChildren) do
      if(id == childId) then
        return true;
      end
    end
    return false;
  else
    return frame.pickedDisplay == id;
  end
end

function WeakAuras.PickDisplay(id, tab, noHide) -- TODO: remove tab parametter once legacy aura trigger is removed
  frame:PickDisplay(id, tab, noHide)
  WeakAuras.UpdateButtonsScroll()
end

function WeakAuras.PickAndEditDisplay(id)
  frame:PickDisplay(id);
  displayButtons[id].callbacks.OnRenameClick();
  WeakAuras.UpdateButtonsScroll()
end

function WeakAuras.ClearPick(id)
  frame:ClearPick(id);
end

function WeakAuras.ClearPicks()
  frame:ClearPicks();
end

function WeakAuras.PickDisplayMultiple(id)
  frame:PickDisplayMultiple(id);
end

function WeakAuras.PickDisplayMultipleShift(target)
  if (frame.pickedDisplay) then
    -- get first aura selected
    local first;
    if (WeakAuras.IsPickedMultiple()) then
      first = tempGroup.controlledChildren[#tempGroup.controlledChildren];
    else
      first = frame.pickedDisplay;
    end
    if (first and first ~= target) then
      -- check if target and first are in same group and are not a group
      local firstData = WeakAuras.GetData(first);
      local targetData = WeakAuras.GetData(target);
      if (firstData.parent == targetData.parent and not targetData.controlledChildren and not firstData.controlledChildren) then
        local batchSelection = {};
        -- in a group
        if (firstData.parent) then
          local group = WeakAuras.GetData(targetData.parent);
          for index, child in ipairs(group.controlledChildren) do
            -- 1st button
            if (child == target or child == first) then
              table.insert(batchSelection, child);
              for i = index + 1, #group.controlledChildren do
                local current = group.controlledChildren[i];
                table.insert(batchSelection, current);
                -- last button: stop selection
                if (current == target or current == first) then
                  break;
                end
              end
              break;
            end
          end
        elseif (firstData.parent == nil and targetData.parent == nil) then
          -- top-level
          for index, button in ipairs(frame.buttonsScroll.children) do
            local data = button.data;
            -- 1st button
            if (data and (data.id == target or data.id == first)) then
              table.insert(batchSelection, data.id);
              for i = index + 1, #frame.buttonsScroll.children do
                local current = frame.buttonsScroll.children[i];
                local currentData = current.data;
                if currentData and not currentData.parent and not currentData.controlledChildren then
                  table.insert(batchSelection, currentData.id);
                  -- last button: stop selection
                  if (currentData.id == target or currentData.id == first) then
                    break;
                  end
                end
              end
              break;
            end
          end
        end
        if #batchSelection > 0 then
          frame:PickDisplayBatch(batchSelection);
        end
      end
    end
  else
    WeakAuras.PickDisplay(target);
  end
end

function WeakAuras.GetDisplayButton(id)
  if(id and displayButtons[id]) then
    return displayButtons[id];
  end
end

function WeakAuras.AddDisplayButton(data)
  WeakAuras.EnsureDisplayButton(data);
  WeakAuras.UpdateDisplayButton(data);
  frame.buttonsScroll:AddChild(displayButtons[data.id]);
  WeakAuras.AddOption(data.id, data);
  WeakAuras.SetIconNames(data);
  if(WeakAuras.regions[data.id] and WeakAuras.regions[data.id].region.SetStacks) then
    WeakAuras.regions[data.id].region:SetStacks(1);
  end
end

function WeakAuras.EnsureDisplayButton(data)
  local id = data.id;
  if not(displayButtons[id]) then
    displayButtons[id] = AceGUI:Create("WeakAurasDisplayButton");
    if(displayButtons[id]) then
      displayButtons[id]:SetData(data);
      displayButtons[id]:Initialize();
    else
      print("|cFF8800FFWeakAuras|r: Error creating button for", id);
    end
  end
end

function WeakAuras.SetGrouping(data)
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0 and data) then
    local children = {};
    -- set grouping for selected buttons
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(childId);
      button:SetGrouping(tempGroup.controlledChildren, true);
      children[childId] = true;
    end
    -- set grouping for non selected buttons
    for id, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:SetGrouping(tempGroup.controlledChildren);
      end
    end
  else
    for id, button in pairs(displayButtons) do
      button:SetGrouping(data);
    end
  end
end

function WeakAuras.Ungroup(data)
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(childId);
      button:Ungroup(data);
    end
  else
    local button = WeakAuras.GetDisplayButton(data.id);
    button:Ungroup(data);
  end
end

function WeakAuras.SetDragging(data, drop)
  WeakAuras_DropDownMenu:Hide()
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    local children = {};
    local size = #tempGroup.controlledChildren;
    -- set dragging for selected buttons in reverse for ordering
    for index = size, 1, -1 do
      local childId = tempGroup.controlledChildren[index];
      local button = WeakAuras.GetDisplayButton(childId);
      button:SetDragging(data, drop, size);
      children[childId] = true;
    end
    -- set dragging for non selected buttons
    for id, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:SetDragging(data, drop);
      end
    end
  else
    for id, button in pairs(displayButtons) do
      button:SetDragging(data, drop);
    end
  end
end

function WeakAuras.DropIndicator()
  local indicator = frame.dropIndicator
  if not indicator then
    indicator = CreateFrame("Frame", "WeakAuras_DropIndicator")
    indicator:SetHeight(4)
    indicator:SetFrameStrata("FULLSCREEN")

    local texture = indicator:CreateTexture(nil, "FULLSCREEN")
    texture:SetBlendMode("ADD")
    texture:SetAllPoints(indicator)
    texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")

    local icon = indicator:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16,16)
    icon:SetPoint("CENTER", indicator)

    indicator.icon = icon
    indicator.texture = texture
    frame.dropIndicator = indicator
    indicator:Hide()
  end
  return indicator
end

function WeakAuras.UpdateDisplayButton(data)
  local id = data.id;
  local button = displayButtons[id];
  if (button) then
    button:SetIcon(WeakAuras.SetThumbnail(data));
    if WeakAurasCompanion and button:IsGroup() then
      button:RefreshUpdate()
    end
    -- TODO: remove this once legacy aura trigger is removed
    button:RefreshBT2UpgradeIcon()
  end
end

function WeakAuras.SetThumbnail(data)
  local regionType = data.regionType;
  local regionTypes = WeakAuras.regionTypes;
  if not(regionType) then
    error("Improper arguments to WeakAuras.SetThumbnail - regionType not defined");
  else
    local id = data.id;
    local button = displayButtons[id];
    if (not button) then return end;
    local thumbnail;
    if((not thumbnails[id]) or (not thumbnails[id].region) or thumbnails[id].regionType ~= regionType) then
      if(regionOptions[regionType] and regionOptions[regionType].createThumbnail and regionOptions[regionType].modifyThumbnail) then
        thumbnail = regionOptions[regionType].createThumbnail(button.frame, regionTypes[regionType].create);
      else
        thumbnail = button.frame:CreateTexture();
        thumbnail:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
      end
      thumbnails[id] = {
        regionType = regionType,
        region = thumbnail
      };
    end

    thumbnail = thumbnails[id].region;
    if(regionOptions[regionType] and regionOptions[regionType].modifyThumbnail) then
      WeakAuras.validate(data, regionTypes[regionType].default);
      regionOptions[regionType].modifyThumbnail(button.frame, thumbnail, data, regionTypes[regionType].modify);
    end
    thumbnail:Show();
    return thumbnail;
  end
end

function WeakAuras.OpenTexturePicker(data, field, textures, stopMotion)
  frame.texturePicker:Open(data, field, textures, stopMotion);
end

function WeakAuras.OpenIconPicker(data, field, groupIcon)
  frame.iconPicker:Open(data, field, groupIcon);
end

function WeakAuras.OpenModelPicker(data, field, parentData)
  if not(IsAddOnLoaded("WeakAurasModelPaths")) then
    local loaded, reason = LoadAddOn("WeakAurasModelPaths");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      print(WeakAuras.printPrefix .. "ModelPaths could not be loaded, the addon is " .. reason);
      WeakAuras.ModelPaths = {};
    end
    frame.modelPicker.modelTree:SetTree(WeakAuras.ModelPaths);
  end
  frame.modelPicker:Open(data, field, parentData);
end

function WeakAuras.OpenCodeReview(data)
  frame.codereview:Open(data);
end

function WeakAuras.CloseCodeReview(data)
  frame.codereview:Close();
end

function WeakAuras.OpenTriggerTemplate(data, targetId)
  if not(IsAddOnLoaded("WeakAurasTemplates")) then
    local loaded, reason = LoadAddOn("WeakAurasTemplates");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      print(WeakAuras.printPrefix .. "Templates could not be loaded, the addon is " .. reason);
      return;
    end
    frame.newView = WeakAuras.CreateTemplateView(frame);
  end
  frame.newView.targetId = targetId;
  frame.newView:Open(data);
end

function WeakAuras.ResetMoverSizer()
  if(frame and frame.mover and frame.moversizer and frame.mover.moving.region and frame.mover.moving.data) then
    frame.moversizer:SetToRegion(frame.mover.moving.region, frame.mover.moving.data);
  end
end

function WeakAuras.ShowCloneDialog(data)
  if(
    not(
    data.parent
    and WeakAuras.GetData(data.parent)
    and WeakAuras.GetData(data.parent).regionType == "dynamicgroup"
    )
    and not(odb.preventCloneDialog)
    ) then
    StaticPopupDialogs["WEAKAURAS_CLONE_OPTION_ENABLED"] = {
      text = L["Clone option enabled dialog"],
      button1 = L["Yes"],
      button2 = L["No"],
      button3 = L["Never"],
      OnAccept = function()
        local parentData = {
          id = WeakAuras.FindUnusedId(data.id.." Group"),
          regionType = "dynamicgroup",
        };
        WeakAuras.Add(parentData);
        WeakAuras.NewDisplayButton(parentData);

        tinsert(parentData.controlledChildren, data.id);
        data.parent = parentData.id;
        WeakAuras.Add(parentData);
        WeakAuras.Add(data);

        local button = WeakAuras.GetDisplayButton(data.id);
        button:SetGroup(parentData.id, true);
        button:SetGroupOrder(1, #parentData.controlledChildren);

        local parentButton = WeakAuras.GetDisplayButton(parentData.id);
        parentButton.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(parentData);
        WeakAuras.ReloadGroupRegionOptions(parentData);
        WeakAuras.SortDisplayButtons();
        parentButton:Expand();
      end,
      OnCancel = function()
      -- do nothing
      end,
      OnAlt = function()
        odb.preventCloneDialog = true
      end,
      hideOnEscape = true,
      whileDead = true,
      timeout = 0,
      preferredindex = STATICPOPUP_NUMDIALOGS
    };

    StaticPopup_Show("WEAKAURAS_CLONE_OPTION_ENABLED");
  end
end

local function AddDefaultSubRegions(data)
  data.subRegions = data.subRegions or {}
  for type, subRegionData in pairs(WeakAuras.subRegionTypes) do
    if subRegionData.addDefaultsForNewAura then
      subRegionData.addDefaultsForNewAura(data)
    end
  end
end

function WeakAuras.NewAura(sourceData, regionType, targetId)
  local function ensure(t, k, v)
    return t and k and v and t[k] == v
  end
  local new_id = WeakAuras.FindUnusedId("New")
  local data = {id = new_id, regionType = regionType, uid = WeakAuras.GenerateUniqueID()}
  WeakAuras.DeepCopy(WeakAuras.data_stub, data);
  if (sourceData) then
    WeakAuras.DeepCopy(sourceData, data);
  end
  data.internalVersion = WeakAuras.InternalVersion();
  WeakAuras.validate(data, WeakAuras.regionTypes[regionType].default);

  AddDefaultSubRegions(data)

  if (data.regionType ~= "group" and data.regionType ~= "dynamicgroup" and targetId) then
    local target = WeakAuras.GetDisplayButton(targetId);
    local group
    if (target) then
      if (target:IsGroup()) then
        group = target;
      else
        group = WeakAuras.GetDisplayButton(target.data.parent);
      end
      if (group) then
        local children = group.data.controlledChildren;
        local index = target:GetGroupOrder();
        if (ensure(children, index, target.data.id)) then
          -- account for insert position
          index = index + 1;
          tinsert(children, index, data.id);
        else
          -- move source into group as the first child
          tinsert(children, 1, data.id);
        end
        data.parent = group.data.id;
        WeakAuras.Add(data);
        WeakAuras.Add(group.data);
        WeakAuras.NewDisplayButton(data);
        WeakAuras.UpdateGroupOrders(group.data);
        WeakAuras.ReloadGroupRegionOptions(group.data);
        WeakAuras.UpdateDisplayButton(group.data);
        group.callbacks.UpdateExpandButton();
        group:Expand();
        group:ReloadTooltip();
        WeakAuras.PickAndEditDisplay(data.id);
      else
        -- move source into the top-level list
        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);
        WeakAuras.PickAndEditDisplay(data.id);
      end
    else
      error("Calling 'WeakAuras.NewAura' with invalid groupId. Reload your UI to fix the display list.")
    end
  else
    -- move source into the top-level list
    WeakAuras.Add(data);
    WeakAuras.NewDisplayButton(data);
    WeakAuras.PickAndEditDisplay(data.id);
  end
end

local collapsedOptions = {}
local collapsed = {} -- magic value
WeakAuras.collapsedOptions = collapsedOptions
function WeakAuras.ResetCollapsed(id, namespace)
  if id then
    if namespace and collapsedOptions[id] then
      collapsedOptions[id][namespace] = nil
    else
      collapsedOptions[id] = nil
    end
  end
end

function WeakAuras.IsCollapsed(id, namespace, path, default)
  local tmp = collapsedOptions[id]
  if tmp == nil then return default end

  tmp = tmp[namespace]
  if tmp == nil then return default end

  if type(path) ~= "table" then
    tmp = tmp[path]
  else
    for _, key in ipairs(path) do
      tmp = tmp[key]
      if tmp == nil or tmp[collapsed] then
        break
      end
    end
  end
  if tmp == nil or tmp[collapsed] == nil then
    return default
  else
    return tmp[collapsed]
  end
end

function WeakAuras.SetCollapsed(id, namespace, path, v)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path] = collapsedOptions[id][namespace][path] or {}
    collapsedOptions[id][namespace][path][collapsed] = v
  else
    local tmp = collapsedOptions[id][namespace] or {}
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[collapsed] = v
  end
end

function WeakAuras.MoveCollapseDataUp(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path - 1] = collapsedOptions[id][namespace][path - 1], collapsedOptions[id][namespace][path]
  else
    local tmp = collapsedOptions[id][namespace]
    local lastKey = tremove(path)
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[lastKey], tmp[lastKey - 1] = tmp[lastKey - 1], tmp[lastKey]
  end
end

function WeakAuras.MoveCollapseDataDown(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path + 1] = collapsedOptions[id][namespace][path + 1], collapsedOptions[id][namespace][path]
  else
    local tmp = collapsedOptions[id][namespace]
    local lastKey = tremove(path)
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[lastKey], tmp[lastKey + 1] = tmp[lastKey + 1], tmp[lastKey]
  end
end

function WeakAuras.RemoveCollapsed(id, namespace, path)
  local data = collapsedOptions[id] and collapsedOptions[id][namespace]
  if not data then
    return
  end
  local index
  local maxIndex = 0
  if type(path) ~= "table" then
    index = path
  else
    index = path[#path]
    for i = 1, #path - 1 do
      data = data[path[i]]
      if not data then
        return
      end
    end
  end
  for k in pairs(data) do
    if k ~= collapsed then
      maxIndex = max(maxIndex, k)
    end
  end
  while index <= maxIndex do
    data[index] = data[index + 1]
    index = index + 1
  end
end

function WeakAuras.InsertCollapsed(id, namespace, path, value)
  local data = collapsedOptions[id] and collapsedOptions[id][namespace]
  if not data then
    return
  end
  local insertPoint
  local maxIndex
  if type(path) ~= "table" then
    insertPoint = path
  else
    insertPoint = path[#path]
    for i = 1, #path - 1 do
      data = data[path[i]]
      if not data then
        return
      end
    end
  end
  for k in pairs(data) do
    if k ~= collapsed and k >= insertPoint then
      if not maxIndex or k > maxIndex then
        maxIndex = k
      end
    end
  end
  if maxIndex then -- may be nil if insertPoint is greater than the max of anything else
    for i = maxIndex, insertPoint, -1 do
      data[i + 1] = data[i]
    end
  end
  data[insertPoint] = {[collapsed] = value}
end

function WeakAuras.RenameCollapsedData(oldid, newid)
  collapsedOptions[newid] = collapsedOptions[oldid]
  collapsedOptions[oldid] = nil
end

function WeakAuras.DeleteCollapsedData(id)
  collapsedOptions[id] = nil
end
