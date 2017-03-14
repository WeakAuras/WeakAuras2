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
local GetScreenWidth, GetScreenHeight, GetBuildInfo, GetLocale, GetTime, PlaySoundFile, PlaySoundKitID, CreateFrame, IsAddOnLoaded, LoadAddOn
  = GetScreenWidth, GetScreenHeight, GetBuildInfo, GetLocale, GetTime, PlaySoundFile, PlaySoundKitID, CreateFrame, IsAddOnLoaded, LoadAddOn

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L
local ADDON_NAME = "WeakAurasOptions";

local font_close,yellow_font,red_font = FONT_COLOR_CODE_CLOSE,YELLOW_FONT_COLOR_CODE,RED_FONT_COLOR_CODE
local ValidateNumeric = function(info,val)
  if not tonumber(val) then
    return print(fmt("|cff9900FF"..ADDON_NAME..font_close..":"..yellow_font.." %s"..red_font.." is not a number!",tostring(val)))
  end
  return true
end

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
  trigger = {},
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0
};
WeakAuras.tempGroup = tempGroup;

function WeakAuras.MultipleDisplayTooltipDesc()
  local desc = {{L["Multiple Displays"], L["Temporary Group"]}};
  for index, id in pairs(tempGroup.controlledChildren) do
    desc[index + 1] = {" ", id};
  end
  desc[2][1] = L["Children:"]
  tinsert(desc, " ");
  tinsert(desc, {" ", "|cFF00FFFF"..L["Right-click for more options"]});
  return desc;
end

function WeakAuras.MultipleDisplayTooltipMenu()
  local menu = {
    {
      text = L["Add to new Group"],
      notCheckable = 1,
      func = function()
        local new_id = tempGroup.controlledChildren[1].." Group";
        local num = 2;
        while(WeakAuras.GetData(new_id)) do
          new_id = "New "..num;
          num = num + 1;
        end

        local data = {
          id = new_id,
          regionType = "group",
          trigger = {},
          load = {}
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
        local new_id = tempGroup.controlledChildren[1].." Group";
        local num = 2;
        while(WeakAuras.GetData(new_id)) do
          new_id = "New "..num;
          num = num + 1;
        end

        local data = {
          id = new_id,
          regionType = "dynamicgroup",
          trigger = {},
          load = {}
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
        WeakAuras.PickDisplay(new_id);
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
        for index, id in pairs(tempGroup.controlledChildren) do
          local toDelete = {};
          local parents = {};
          for index, id in pairs(tempGroup.controlledChildren) do
            local childData = WeakAuras.GetData(id);
            toDelete[index] = childData;
            if(childData.parent) then
              parents[childData.parent] = true;
            end
          end
          for index, childData in pairs(toDelete) do
            WeakAuras.DeleteOption(childData);
          end
          for id, _ in pairs(parents) do
            local parentData = WeakAuras.GetData(id);
            local parentButton = WeakAuras.GetDisplayButton(id);
            WeakAuras.UpdateGroupOrders(parentData);
            if(#parentData.controlledChildren == 0) then
              parentButton:DisableExpand();
            else
              parentButton:EnableExpand();
            end
            parentButton:SetNormalTooltip();
          end
        end
        WeakAuras.SortDisplayButtons();
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

local trigger_types = WeakAuras.trigger_types;
local debuff_types = WeakAuras.debuff_types;
local unit_types = WeakAuras.unit_types;
local actual_unit_types_with_specific = WeakAuras.actual_unit_types_with_specific;
local point_types = WeakAuras.point_types;
local event_types = WeakAuras.event_types;
local status_types = WeakAuras.status_types;
local subevent_prefix_types = WeakAuras.subevent_prefix_types;
local subevent_actual_prefix_types = WeakAuras.subevent_actual_prefix_types;
local subevent_suffix_types = WeakAuras.subevent_suffix_types;
local operator_types = WeakAuras.operator_types;
local string_operator_types = WeakAuras.string_operator_types;
local check_types = WeakAuras.check_types;
local custom_trigger_types = WeakAuras.custom_trigger_types;
local eventend_types = WeakAuras.eventend_types;
local autoeventend_types = WeakAuras.autoeventend_types;
local anim_types = WeakAuras.anim_types;
local anim_translate_types = WeakAuras.anim_translate_types;
local anim_scale_types = WeakAuras.anim_scale_types;
local anim_alpha_types = WeakAuras.anim_alpha_types;
local anim_rotate_types = WeakAuras.anim_rotate_types;
local anim_color_types = WeakAuras.anim_color_types;
local anim_start_preset_types = WeakAuras.anim_start_preset_types;
local anim_main_preset_types = WeakAuras.anim_main_preset_types;
local anim_finish_preset_types = WeakAuras.anim_finish_preset_types;
local send_chat_message_types = WeakAuras.send_chat_message_types;
local sound_types = WeakAuras.sound_types;
local duration_types = WeakAuras.duration_types;
local duration_types_no_choice = WeakAuras.duration_types_no_choice;
local group_aura_name_info_types = WeakAuras.group_aura_name_info_types;
local group_aura_stack_info_types = WeakAuras.group_aura_stack_info_types;

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

AceGUI:RegisterLayout("ButtonsScrollLayout", function(content, children)
  local yOffset = 0;
  local scrollTop, scrollBottom = content.obj:GetScrollPos();
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
  if(content.obj.LayoutFinished) then
    content.obj:LayoutFinished(nil, yOffset * -1);
  end
end);

function WeakAuras.ConstructOptions(prototype, data, startorder, subPrefix, subSuffix, triggernum, triggertype, unevent)
  local trigger, untrigger;
  if(data.controlledChildren) then
    trigger, untrigger = {}, {};
  elseif(triggertype == "load") then
    trigger = data.load;
  else
    if(triggernum == 0) then
      data.untrigger = data.untrigger or {};
      if(triggertype == "untrigger") then
        trigger = data.untrigger;
      else
        trigger = data.trigger;
        untrigger = data.untrigger;
      end
    elseif(triggernum >= 1) then
      data.additional_triggers[triggernum].untrigger = data.additional_triggers[triggernum].untrigger or {};
      if(triggertype == "untrigger") then
        trigger = data.additional_triggers[triggernum].untrigger;
      else
        trigger = data.additional_triggers[triggernum].trigger;
        untrigger = data.additional_triggers[triggernum].untrigger;
      end
    else
      error("Improper argument to WeakAuras.ConstructOptions - trigger number not in range");
    end
  end
  unevent = unevent or trigger.unevent;
  local options = {};
  local order = startorder or 10;
  for index, arg in pairs(prototype.args) do
    local hidden = nil;
    if(type(arg.enable) == "function") then
      hidden = function() return not arg.enable(trigger) end;
    end
    local name = arg.name;
    if(name and not arg.hidden) then
      local realname = name;
      if(triggertype == "untrigger") then
        name = "untrigger_"..name;
      end
      if (arg.type == "multiselect") then
        -- Ensure new line for non-toggle options
        options["spacer_"..name] = {
          type = "description",
          name = "",
          order = order,
          hidden = hidden,
        }
        order = order + 1;
      end
      if(arg.type == "tristate") then
        options["use_"..name] = {
          type = "toggle",
          name = function(input)
            local value = trigger["use_"..realname];
            if(value == nil) then return arg.display;
            elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..arg.display;
            else return "|cFF00FF00"..arg.display; end
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
              if(value == false) then trigger["use_"..realname] = nil;
              else trigger["use_"..realname] = false end
            end
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
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
              if(value == false) then trigger["use_"..realname] = nil;
              else
                trigger["use_"..realname] = false
                if(trigger[realname].single) then
                  trigger[realname].multi[trigger[realname].single] = true;
                end
              end
            end
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end,
          hidden = hidden,
          order = order
        };
      else
        options["use_"..name] = {
          type = "toggle",
          name = arg.display,
          order = order,
          hidden = hidden,
          desc = arg.desc,
          get = function() return trigger["use_"..realname]; end,
          set = function(info, v)
            trigger["use_"..realname] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
      end
      if(arg.type == "toggle" or arg.type == "tristate") then
        options["use_"..name].width = arg.width or "double";
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
        options[name.."_operator"] = {
          type = "select",
          name = L["Operator"],
          width = "half",
          order = order,
          hidden = hidden,
          values = operator_types,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
          set = function(info, v)
            trigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name.."_operator"].set = function(info, v) trigger[realname.."_operator"] = v; untrigger[realname.."_operator"] = v; WeakAuras.Add(data); WeakAuras.ScanForLoads(); WeakAuras.SortDisplayButtons(); end
        elseif(arg.required and triggertype == "untrigger") then
          options[name.."_operator"] = nil;
          order = order - 1;
        end
        order = order + 1;
        options[name] = {
          type = "input",
          validate = ValidateNumeric,
          name = arg.display,
          width = "half",
          order = order,
          hidden = hidden,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] or nil; end,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v) trigger[realname] = v; untrigger[realname] = v; WeakAuras.Add(data); WeakAuras.ScanForLoads(); WeakAuras.SortDisplayButtons(); end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        order = order + 1;
      elseif(arg.type == "string") then
        options[name] = {
          type = "input",
          name = arg.display,
          order = order,
          hidden = hidden,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] or nil; end,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v) trigger[realname] = v; untrigger[realname] = v; WeakAuras.Add(data); WeakAuras.ScanForLoads(); WeakAuras.SortDisplayButtons(); end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        order = order + 1;
      elseif(arg.type == "longstring") then
        options[name.."_operator"] = {
          type = "select",
          name = L["Operator"],
          order = order,
          hidden = hidden,
          values = string_operator_types,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname.."_operator"] or nil; end,
          set = function(info, v)
            trigger[realname.."_operator"] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name.."_operator"].set = function(info, v) trigger[realname.."_operator"] = v; untrigger[realname.."_operator"] = v; WeakAuras.Add(data); WeakAuras.ScanForLoads(); WeakAuras.SortDisplayButtons(); end
        elseif(arg.required and triggertype == "untrigger") then
          options[name.."_operator"] = nil;
          order = order - 1;
        end
        order = order + 1;
        options[name] = {
          type = "input",
          name = arg.display,
          width = "double",
          order = order,
          hidden = hidden,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] or nil; end,
          set = function(info, v)
            trigger[realname] = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v) trigger[realname] = v; untrigger[realname] = v; WeakAuras.Add(data); WeakAuras.ScanForLoads(); WeakAuras.SortDisplayButtons(); end
        elseif(arg.required and triggertype == "untrigger") then
          options[name] = nil;
          order = order - 1;
        end
        order = order + 1;
      elseif(arg.type == "spell" or arg.type == "aura" or arg.type == "item") then
        options["icon"..name] = {
          type = "execute",
          name = "",
          order = order,
          hidden = hidden,
          width = "normal",
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
          name = arg.display,
          order = order,
          hidden = hidden,
          width = "double",
          disabled = function() return not trigger["use_"..realname]; end,
          get = function()
            if(arg.type == "item") then
              if(trigger["use_"..realname] and trigger[realname] and trigger[realname] ~= "") then
                local name = GetItemInfo(trigger[realname]);
                if(name) then
                  return name;
                else
                  return "Invalid Item Name/ID/Link";
                end
              else
                return nil;
              end
            elseif(arg.type == "spell") then
              if(trigger["use_"..realname] and trigger[realname] and trigger[realname] ~= "") then
                local name = GetSpellInfo(trigger[realname]);
                if(name) then
                  return name;
                else
                  return "Invalid Spell Name/ID/Link";
                end
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
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        if(arg.required and not triggertype) then
          options[name].set = function(info, v)
            local fixedInput = v;
            if(arg.type == "aura") then
              fixedInput = WeakAuras.spellCache.CorrectAuraName(v);
            elseif(arg.type == "spell") then
              fixedInput = WeakAuras.CorrectSpellName(v);
            elseif(arg.type == "item") then
              fixedInput = WeakAuras.CorrectItemName(v);
            end
            trigger[realname] = fixedInput;
            untrigger[realname] = fixedInput;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        elseif(arg.required and triggertype == "untrigger") then
          options["icon"..name] = nil;
          options[name] = nil;
          order = order - 2;
        end
        order = order + 1;
      elseif(arg.type == "select" or arg.type == "unit") then
        local values;
        if(type(arg.values) == "function") then
          values = arg.values(trigger);
        else
          values = WeakAuras[arg.values];
        end
        options[name] = {
          type = "select",
          name = arg.display,
          order = order,
          hidden = hidden,
          values = values,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function()
            if(arg.type == "unit" and trigger["use_specific_"..realname]) then
              return "member";
            end
            return trigger["use_"..realname] and trigger[realname] or nil;
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
            WeakAuras.ScanForLoads();
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
            WeakAuras.ScanForLoads();
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
            name = L["Specific Unit"],
            order = order,
            hidden = function() return (not trigger["use_specific_"..realname]) or (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) end,
            get = function() return true end,
            set = function(info, v)
              trigger["use_specific_"..realname] = nil;
              options[name].set(info, "player");
            end
          }
          order = order + 1;
          options["specific_"..name] = {
            type = "input",
            name = L["Specific Unit"],
            desc = L["Can be a name or a UID (e.g., party1). Only works on friendly players in your group."],
            order = order,
            hidden = function() return (not trigger["use_specific_"..realname]) or (type(hidden) == "function" and hidden(trigger)) or (type(hidden) ~= "function" and hidden) end,
            get = function() return trigger[realname] end,
            set = function(info, v)
              trigger[realname] = v;
              if(arg.required and not triggertype) then
                untrigger[realname] = v;
              end
              WeakAuras.Add(data);
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
          name = arg.display,
          order = order,
          values = values,
          hidden = function() return hidden or trigger["use_"..realname] == false; end,
          disabled = function() return not trigger["use_"..realname]; end,
          get = function() return trigger["use_"..realname] and trigger[realname] and trigger[realname].single or nil; end,
          set = function(info, v)
            trigger[realname].single = v;
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
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
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        end

        options["multiselect_"..name] = {
          type = "multiselect",
          name = arg.display,
          order = order,
          hidden = function() return hidden or trigger["use_"..realname] ~= false; end,
          values = values,
          -- width = "half",
          get = function(info, v)
            if(trigger["use_"..realname] == false and trigger[realname] and trigger[realname].multi) then
              return trigger[realname].multi[v];
            end
          end,
          set = function(info, v, calledFromSetAll)
            if (calledFromSetAll) then
              trigger[realname].multi[v] = calledFromSetAll;
            elseif(trigger[realname].multi[v]) then
              trigger[realname].multi[v] = nil;
            else
              trigger[realname].multi[v] = true;
            end
            WeakAuras.Add(data);
            WeakAuras.ScanForLoads();
            WeakAuras.SetThumbnail(data);
            WeakAuras.SetIconNames(data);
            WeakAuras.UpdateDisplayButton(data);
            WeakAuras.SortDisplayButtons();
          end
        };
        options["multiselectspace_"..name] = {
          type = "execute",
          name = "",
          order = (order - 0.5),
          hidden = function() return hidden or trigger["use_"..realname] ~= false; end,
          disabled = true,
          image = function() return "", 52, 52 end
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
            WeakAuras.ScanForLoads();
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
      name = L["Hide"],
      width = "double",
      order = order
    };
    order = order + 1;
    if(unevent == "timed") then
      options.unevent.width = "normal";
      options.duration = {
        type = "input",
        name = L["Duration (s)"],
        order = order
      }
      order = order + 1;
    else
      options.unevent.width = "double";
    end
    if(unevent == "custom") then
      local unevent_options = WeakAuras.ConstructOptions(prototype, data, order, subPrefix, subSuffix, triggernum, "untrigger");
      options = union(options, unevent_options);
    end
    if(prototype.automatic) then
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

function WeakAuras.DeleteOption(data)
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

  WeakAuras.Delete(data);
  frame:ClearPicks();
  frame.buttonsScroll:DeleteChild(displayButtons[id]);
  thumbnails[id].region:Hide();
  thumbnails[id] = nil;
  displayButtons[id] = nil;

  if(parentData and parentData.controlledChildren) then
    for index, childId in pairs(parentData.controlledChildren) do
      local childButton = displayButtons[childId];
      if(childButton) then
        childButton:SetGroupOrder(index, #parentData.controlledChildren);
      end
    end
    WeakAuras.Add(parentData);
    WeakAuras.ReloadGroupRegionOptions(parentData);
    WeakAuras.UpdateDisplayButton(parentData);
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
    print("|cff9900FF".."WeakAuras Options"..FONT_COLOR_CODE_CLOSE.." will open after combat.")
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

    --if(data.parent and WeakAuras.regions[data.parent]) then
    if(data.parent and WeakAuras.regions[data.parent] and
      WeakAuras.regions[data.parent].region and
      WeakAuras.regions[data.parent].region.ControlChildren) then
      WeakAuras.regions[data.parent].region:ControlChildren();
    end

    WeakAuras.SetIconNames(data);
  end
end

function WeakAuras.ShowOptions(msg)
  local firstLoad = not(frame);
  WeakAuras.Pause();

  if (firstLoad) then
    frame = WeakAuras.CreateFrame();
    frame.buttonsScroll.frame:Show();
    WeakAuras.AddOption(tempGroup.id, tempGroup);
    WeakAuras.LayoutDisplayButtons(msg);
  end
  frame.buttonsScroll.frame:Show();
  WeakAuras.LockUpdateInfo();

  if (frame.needsSort) then
    WeakAuras.SortDisplayButtons();
    frame.needsSort = nil;
  end

  frame:Show();
  frame:PickOption("New");
  if not(firstLoad) then
    for id, button in pairs(displayButtons) do
      if(loaded[id] ~= nil) then
        button:PriorityShow(1);
      end
    end
  end

  if (frame.window == "codereview") then
    frame.codereview:Close();
  end

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:OptionsOpened();
  end
  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:OptionsOpened();
  end
end

function WeakAuras.HideOptions()
  -- dynFrame:SetScript("OnUpdate", nil);
  WeakAuras.UnlockUpdateInfo();
  WeakAuras.SetDragging()

  if(frame) then
    frame:Hide();
  end

  local tutFrame = WeakAuras.TutorialsFrame and WeakAuras.TutorialsFrame();
  if(tutFrame and tutFrame:IsVisible()) then
    tutFrame:Hide();
  end

  WeakAuras.PauseAllDynamicGroups();

  for id, data in pairs(WeakAuras.regions) do
    data.region:Collapse();
  end

  WeakAuras.ResumeAllDynamicGroups();

  WeakAuras.ReloadAll();
  WeakAuras.Resume();

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:OptionsClosed();
  end
  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:OptionsClosed();
  end
end

function WeakAuras.IsOptionsOpen()
  if(frame and frame:IsVisible()) then
    return true;
  else
    return false;
  end
end

function WeakAuras.DoConfigUpdate()
  local function GiveDynamicInfo(id, region, data, cloneNum)
    if(WeakAuras.CanHaveDuration(data) == "timed") then
      local rem = GetTime() + 8 - (frame.count + frame.elapsed);
      if(cloneNum) then
        rem = rem + (cloneNum == 1 and (frame.count >= 1 and 1 or -3) or (frame.count >= 2 and 2 or -2));
      end
      if(region.SetDurationInfo) then
        if not(frame.count ~= 0 and region.cooldown and region.cooldown:IsVisible()) then
          region:SetDurationInfo(12, rem);
        end
      end
    elseif(type(WeakAuras.CanHaveDuration(data)) == "table") then
      local demoValues = WeakAuras.CanHaveDuration(data);
      local current, maximum = demoValues.current or 10, demoValues.maximum or 100;
      if(region.SetDurationInfo) then
        region:SetDurationInfo(current, maximum, true);
      end
    else
      if(region.SetDurationInfo) then
        region:SetDurationInfo(0, math.huge);
      end
    end
  end

  for id, region in pairs(WeakAuras.regions) do
    local data = db.displays[id];
    if(data) then
      GiveDynamicInfo(id, region.region, data);

      if(WeakAuras.clones[id]) then
        for cloneNum, cloneRegion in pairs(WeakAuras.clones[id]) do
          GiveDynamicInfo(id, cloneRegion, data, cloneNum);
        end
      end
    end
  end
end

function WeakAuras.LockUpdateInfo()
  frame.elapsed = 12;
  frame.count = 0;
  frame:SetScript("OnUpdate", function(self, elapsed)
    frame.elapsed = frame.elapsed + elapsed;
    if(frame.elapsed > 1) then
      frame.elapsed = frame.elapsed - 1;
      frame.count = (frame.count + 1) % 4;
      WeakAuras.DoConfigUpdate();
    end
  end);
end

function WeakAuras.UnlockUpdateInfo()
  frame:SetScript("OnUpdate", nil);
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

    if (WeakAuras.IsOptionsOpen()) then
      for id, button in pairs(displayButtons) do
        if(loaded[id] ~= nil) then
          button:PriorityShow(1);
        end
      end
    end

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

local function filterAnimPresetTypes(intable, id)
  local ret = {};
  local region = WeakAuras.regions[id] and WeakAuras.regions[id].region;
  local regionType = WeakAuras.regions[id] and WeakAuras.regions[id].regionType;
  local data = db.displays[id];
  if(region and regionType and data) then
    for key, value in pairs(intable) do
      local preset = WeakAuras.anim_presets[key];
      if(preset) then
        if(regionType == "group" or regionType == "dynamicgroup") then
          local valid = true;
          for index, childId in pairs(data.controlledChildren) do
            local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region
            if(childRegion and ((preset.use_scale and not childRegion.Scale) or (preset.use_rotate and not childRegion.Rotate))) then
              valid = false;
            end
          end
          if(valid) then
            ret[key] = value;
          end
        else
          if not((preset.use_scale and not region.Scale) or (preset.use_rotate and not region.Rotate)) then
            ret[key] = value;
          end
        end
      end
    end
  end
  return ret;
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

local function getAll(data, info, ...)
  local combinedValues = {};
  local first = true;
  local debug = false;
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
      for i=#childOptionTable,0,-1 do
        if(childOptionTable[i].get) then
          local values = {childOptionTable[i].get(info, ...)};
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
  return unpack(combinedValues);
end
WeakAuras.getAll = getAll

local function setAll(data, info, ...)
  WeakAuras.pauseOptionsProcessing(true);
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
      for i=#childOptionTable,0,-1 do
        if(childOptionTable[i].hidden ~= nil) then
          if(type(childOptionTable[i].hidden) == "boolean") then
            if(childOptionTable[i].hidden) then
              return true;
            else
              return false;
            end
          elseif(type(childOptionTable[i].hidden) == "function") then
            if(childOptionTable[i].hidden(info)) then
              return true;
            end
          end
        end
      end
    end
  end

  return false;
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
      for i=#childOptionTable,0,-1 do
        if(childOptionTable[i].disabled ~= nil) then
          if(type(childOptionTable[i].disabled) == "boolean") then
            if(childOptionTable[i].disabled) then
              return true;
            else
              return false;
            end
          elseif(type(childOptionTable[i].disabled) == "function") then
            if(childOptionTable[i].disabled(info)) then
              return true;
            end
          end
        end
      end
    end
  end

  return false;
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

  local function combineKeys(info)
    local combinedKeys = nil;
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
        for i=#childOptionTable,0,-1 do
          if(childOptionTable[i].values) then
            local values;
            if (type(childOptionTable[i].values) == "function") then
              values = childOptionTable[i].values(info);
            elseif (type(childOptionTable[i].values) == "table") then
              values = childOptionTable[i].values;
            end
            if (values) then
              combinedKeys = combinedKeys or {};
              for k, v in pairs(values) do
                combinedKeys[k] = v;
              end
            end
          end
        end
      end
    end
    return combinedKeys;
  end

  local function sameAll(info)
    local combinedValues = {};
    local first = true;
    local combinedKeys = combineKeys(info);

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
        for i=#childOptionTable,0,-1 do
          if(childOptionTable[i].get) then
            if (combinedKeys) then
              for key, _ in pairs(combinedKeys) do
                local values = {childOptionTable[i].get(info, key)};
                if (combinedValues[key] == nil) then
                  combinedValues[key] = values;
                else
                  if (not compareTables(combinedValues[key], values)) then
                    return nil;
                  end
                end
              end
            else
              local values = {childOptionTable[i].get(info)};
              if(first) then
                combinedValues = values;
                first = false;
              else
                if (not compareTables(combinedValues, values)) then
                  return nil;
                end
              end
            end
            break; -- Found get function
          end
        end
      end
    end

    return true;
  end

  local function nameAll(info)
    local combinedName;
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        WeakAuras.EnsureOptions(childId);
        local childOption = displayOptions[childId];
        if not(childOption) then
          return "error 1";
        end
        for i=1,#info do
          childOption = childOption.args[info[i]];
          if not(childOption) then
            return "error 2 - "..childId.." - "..table.concat(info, ", ").." - "..i;
          end
        end
        local name;
        if(type(childOption.name) == "function") then
          name = childOption.name(info);
        else
          name = childOption.name;
        end
        if(first) then
          combinedName = name;
          first = false;
        elseif not(combinedName == name) then
          return childOption.name("default");
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
        local childOption = displayOptions[childId];
        if not(childOption) then
          return "error"
        end
        for i=1,#info do
          childOption = childOption.args[info[i]];
          if not(childOption) then
            return "error"
          end
        end
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
                      tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                    elseif(intable.type == "multiselect") then
                      local selectedValues = "";
                      for k, v in pairs(combinedKeys) do
                        if (childOptionTable[i].get(info, k)) then
                          if (not selectedValues) then
                            selectedValues = tostring(v);
                          else
                            selectedValues = selectedValues .. ", " .. tostring(v);
                          end
                        end
                      end
                      tinsert(values, "|cFFE0E000"..childId..": |r"..selectedValues);
                    else
                      local display = childOptionTable[i].get(info) or L["None"];
                      if(type(display) == "number") then
                        display = math.floor(display * 100) / 100;
                      end
                      tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                    end
                    break;
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
        for i=1,#info do
          childOption = childOption.args[info[i]];
          if not(childOption) then
            return "error"
          end
        end
        local image;
        if not(childOption.image) then
          return "", 0, 0;
        else
          image = {childOption.image(info)};
        end
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
        for i=1,#info do
          childOption = childOption.args[info[i]];
          if not(childOption) then
            return "error"
          end
        end
        local values;
        if not(childOption.values) then
          return {};
        else
          values = childOption.values(info);
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


function WeakAuras.AddOption(id, data)
  local regionOption;
  if(regionOptions[data.regionType]) then
    regionOption = regionOptions[data.regionType].create(id, data);
  else
    regionOption = {
      unsupported = {
        type = "description",
        name = L["This region of type \"%s\" is not supported."]:format(data.regionType)
      }
    };
  end

  displayOptions[id] = {
    type = "group",
    childGroups = "tab",
    args = {
      region = {
        type = "group",
        name = L["Display"],
        order = 10,
        get = function(info)
          if(info.type == "color") then
            data[info[#info]] = data[info[#info]] or {};
            local c = data[info[#info]];
            return c[1], c[2], c[3], c[4];
          else
            return data[info[#info]];
          end
        end,
        set = function(info, v, g, b, a)
          if(info.type == "color") then
            data[info[#info]] = data[info[#info]] or {};
            local c = data[info[#info]];
            c[1], c[2], c[3], c[4] = v, g, b, a;
          elseif(info.type == "toggle") then
            data[info[#info]] = v;
          else
            data[info[#info]] = (v ~= "" and v) or nil;
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
        args = regionOption
      },
      trigger = {
        type = "group",
        name = L["Trigger"],
        order = 20,
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
          WeakAuras.ScanForLoads();
          WeakAuras.SortDisplayButtons();
        end,
        args = {}
      },
      action = {
        type = "group",
        name = L["Actions"],
        order = 50,
        get = function(info)
          local split = info[#info]:find("_");
          if(split) then
            local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
            if(data.actions and data.actions[field]) then
              return data.actions[field][value];
            else
              return nil;
            end
          end
        end,
        set = function(info, v)
          local split = info[#info]:find("_");
          local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
          data.actions = data.actions or {};
          data.actions[field] = data.actions[field] or {};
          data.actions[field][value] = v;
          if(value == "sound" or value == "sound_path") then
            PlaySoundFile(v, data.actions.start.sound_channel or "Master");
          elseif(value == "sound_kit_id") then
            PlaySoundKitID(v, data.actions.start.sound_channel or "Master");
          end
          WeakAuras.Add(data);
        end,
        args = {
          init_header = {
            type = "header",
            name = L["On Init"],
            order = 0.005
          },
          init_do_custom = {
            type = "toggle",
            name = L["Custom"],
            order = 0.011,
            width = "double"
          },
          init_custom = {
            type = "input",
            width = "normal",
            name = L["Custom Code"],
            order = 0.013,
            multiline = true,
            hidden = function() return not data.actions.init.do_custom end
          },
          init_expand = {
            type = "execute",
            order = 0.014,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"actions", "init", "custom"}, true)
            end,
            hidden = function() return not data.actions.init.do_custom end
          },
          init_customError = {
            type = "description",
            name = function()
              if not(data.actions.init.custom) then
                return "";
              end
              local _, errorString = loadstring("return function() "..data.actions.init.custom.."\n end");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 0.015,
            hidden = function()
              if not(data.actions.init.do_custom and data.actions.init.custom) then
                return true;
              else
                local loadedFunction, errorString = loadstring("return function() "..data.actions.init.custom.."\n end");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_header = {
            type = "header",
            name = L["On Show"],
            order = 0.5
          },
          start_do_message = {
            type = "toggle",
            name = L["Chat Message"],
            order = 1
          },
          start_message_type = {
            type = "select",
            name = L["Message Type"],
            order = 2,
            values = send_chat_message_types,
            disabled = function() return not data.actions.start.do_message end,
            control = "WeakAurasSortedDropdown"
          },
          start_message_space = {
            type = "execute",
            name = "",
            order = 3,
            image = function() return "", 0, 0 end,
            hidden = function() return not(data.actions.start.message_type == "WHISPER" or data.actions.start.message_type == "CHANNEL" or data.actions.start.message_type == "COMBAT" or data.actions.start.message_type == "PRINT") end
          },
          start_message_color = {
            type = "color",
            name = L["Color"],
            order = 3,
            hasAlpha = false,
            hidden = function() return not(data.actions.start.message_type == "COMBAT" or data.actions.start.message_type == "PRINT") end,
            get = function() return data.actions.start.r or 1, data.actions.start.g or 1, data.actions.start.b or 1 end,
            set = function(info, r, g, b)
              data.actions.start.r = r;
              data.actions.start.g = g;
              data.actions.start.b = b;
              WeakAuras.Add(data);
            end
          },
          start_message_dest = {
            type = "input",
            name = L["Send To"],
            order = 4,
            disabled = function() return not data.actions.start.do_message end,
            hidden = function() return data.actions.start.message_type ~= "WHISPER" end
          },
          start_message_channel = {
            type = "input",
            name = L["Channel Number"],
            order = 4,
            disabled = function() return not data.actions.start.do_message end,
            hidden = function() return data.actions.start.message_type ~= "CHANNEL" end
          },
          start_message = {
            type = "input",
            name = L["Message"],
            width = "double",
            order = 5,
            disabled = function() return not data.actions.start.do_message end,
            desc = function()
              local ret = L["Dynamic text tooltip"];
              ret = ret .. WeakAuras.GetAdditionalProperties(data);
              return ret
            end,
          },
          start_do_sound = {
            type = "toggle",
            width = "double",
            name = L["Play Sound"],
            order = 7
          },
          start_sound = {
            type = "select",
            name = L["Sound"],
            order = 8,
            values = sound_types,
            disabled = function() return not data.actions.start.do_sound end,
            control = "WeakAurasSortedDropdown"
          },
          start_sound_channel = {
            type = "select",
            name = L["Sound Channel"],
            order = 8.5,
            values = WeakAuras.sound_channel_types,
            disabled = function() return not data.actions.start.do_sound end,
            get = function() return data.actions.start.sound_channel or "Master" end
          },
          start_sound_path = {
            type = "input",
            name = L["Sound File Path"],
            order = 9,
            width = "double",
            hidden = function() return data.actions.start.sound ~= " custom" end,
            disabled = function() return not data.actions.start.do_sound end
          },
          start_sound_kit_id = {
            type = "input",
            name = L["Sound Kit ID"],
            order = 9,
            width = "double",
            hidden = function() return data.actions.start.sound ~= " KitID" end,
            disabled = function() return not data.actions.start.do_sound end
          },
          start_do_glow = {
            type = "toggle",
            name = L["Button Glow"],
            order = 10.1
          },
          start_glow_action = {
            type = "select",
            name = L["Glow Action"],
            order = 10.2,
            values = WeakAuras.glow_action_types,
            disabled = function() return not data.actions.start.do_glow end
          },
          start_glow_frame = {
            type = "input",
            name = L["Frame"],
            order = 10.3,
            hidden = function() return not data.actions.start.do_glow end
          },
          start_choose_glow_frame = {
            type = "execute",
            name = L["Choose"],
            order = 10.4,
            hidden = function() return not data.actions.start.do_glow end,
            func = function()
              if(data.controlledChildren and data.controlledChildren[1]) then
                WeakAuras.PickDisplay(data.controlledChildren[1]);
                WeakAuras.StartFrameChooser(WeakAuras.GetData(data.controlledChildren[1]), {"actions", "start", "glow_frame"});
              else
                WeakAuras.StartFrameChooser(data, {"actions", "start", "glow_frame"});
              end
            end
          },
          start_do_custom = {
            type = "toggle",
            name = L["Custom"],
            order = 11,
            width = "double"
          },
          start_custom = {
            type = "input",
            width = "normal",
            name = L["Custom Code"],
            order = 13,
            multiline = true,
            hidden = function() return not data.actions.start.do_custom end
          },
          start_expand = {
            type = "execute",
            order = 14,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"actions", "start", "custom"}, true)
            end,
            hidden = function() return not data.actions.start.do_custom end
          },
          start_customError = {
            type = "description",
            name = function()
              if not(data.actions.start.custom) then
                return "";
              end
              local _, errorString = loadstring("return function() "..data.actions.start.custom.."\n end");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 15,
            hidden = function()
              if not(data.actions.start.do_custom and data.actions.start.custom) then
                return true;
              else
                local loadedFunction, errorString = loadstring("return function() "..data.actions.start.custom.."\n end");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_header = {
            type = "header",
            name = L["On Hide"],
            order = 20.5
          },
          finish_do_message = {
            type = "toggle",
            name = L["Chat Message"],
            order = 21
          },
          finish_message_type = {
            type = "select",
            name = L["Message Type"],
            order = 22,
            values = send_chat_message_types,
            disabled = function() return not data.actions.finish.do_message end,
            control = "WeakAurasSortedDropdown"
          },
          finish_message_space = {
            type = "execute",
            name = "",
            order = 23,
            image = function() return "", 0, 0 end,
            hidden = function() return not(data.actions.finish.message_type == "WHISPER" or data.actions.finish.message_type == "CHANNEL") end
          },
          finish_message_color = {
            type = "color",
            name = L["Color"],
            order = 23,
            hasAlpha = false,
            hidden = function() return not(data.actions.finish.message_type == "COMBAT" or data.actions.finish.message_type == "PRINT") end,
            get = function() return data.actions.finish.r or 1, data.actions.finish.g or 1, data.actions.finish.b or 1 end,
            set = function(info, r, g, b)
              data.actions.finish.r = r;
              data.actions.finish.g = g;
              data.actions.finish.b = b;
              WeakAuras.Add(data);
            end
          },
          finish_message_dest = {
            type = "input",
            name = L["Send To"],
            order = 24,
            disabled = function() return not data.actions.finish.do_message end,
            hidden = function() return data.actions.finish.message_type ~= "WHISPER" end
          },
          finish_message_channel = {
            type = "input",
            name = L["Channel Number"],
            order = 24,
            disabled = function() return not data.actions.finish.do_message end,
            hidden = function() return data.actions.finish.message_type ~= "CHANNEL" end
          },
          finish_message = {
            type = "input",
            name = L["Message"],
            width = "double",
            order = 25,
            disabled = function() return not data.actions.finish.do_message end,
            desc = function()
              local ret = L["Dynamic text tooltip"];
              ret = ret .. WeakAuras.GetAdditionalProperties(data);
              return ret
            end,
          },
          finish_do_sound = {
            type = "toggle",
            width = "double",
            name = L["Play Sound"],
            order = 27
          },
          finish_sound = {
            type = "select",
            name = L["Sound"],
            order = 28,
            values = sound_types,
            disabled = function() return not data.actions.finish.do_sound end,
            control = "WeakAurasSortedDropdown"
          },
          finish_sound_channel = {
            type = "select",
            name = L["Sound Channel"],
            order = 28.5,
            values = WeakAuras.sound_channel_types,
            disabled = function() return not data.actions.finish.do_sound end,
            get = function() return data.actions.finish.sound_channel or "Master" end
          },
          finish_sound_path = {
            type = "input",
            name = L["Sound File Path"],
            order = 29,
            width = "double",
            hidden = function() return data.actions.finish.sound ~= " custom" end,
            disabled = function() return not data.actions.finish.do_sound end
          },
          finish_sound_kit_id = {
            type = "input",
            name = L["Sound Kit ID"],
            order = 29,
            width = "double",
            hidden = function() return data.actions.finish.sound ~= " KitID" end,
            disabled = function() return not data.actions.finish.do_sound end
          },
          finish_do_glow = {
            type = "toggle",
            name = L["Button Glow"],
            order = 30.1
          },
          finish_glow_action = {
            type = "select",
            name = L["Glow Action"],
            order = 30.2,
            values = WeakAuras.glow_action_types,
            disabled = function() return not data.actions.finish.do_glow end
          },
          finish_glow_frame = {
            type = "input",
            name = L["Frame"],
            order = 30.3,
            hidden = function() return not data.actions.finish.do_glow end
          },
          finish_choose_glow_frame = {
            type = "execute",
            name = L["Choose"],
            order = 30.4,
            hidden = function() return not data.actions.finish.do_glow end,
            func = function()
              if(data.controlledChildren and data.controlledChildren[1]) then
                WeakAuras.PickDisplay(data.controlledChildren[1]);
                WeakAuras.StartFrameChooser(WeakAuras.GetData(data.controlledChildren[1]), {"actions", "finish", "glow_frame"});
              else
                WeakAuras.StartFrameChooser(data, {"actions", "finish", "glow_frame"});
              end
            end
          },
          finish_do_custom = {
            type = "toggle",
            name = L["Custom"],
            order = 31,
            width = "double"
          },
          finish_custom = {
            type = "input",
            name = L["Custom Code"],
            order = 33,
            multiline = true,
            width = "normal",
            hidden = function() return not data.actions.finish.do_custom end
          },
          finish_expand = {
            type = "execute",
            order = 34,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"actions", "finish", "custom"}, true)
            end,
            hidden = function() return not data.actions.finish.do_custom end
          },
          finish_customError = {
            type = "description",
            name = function()
              if not(data.actions.finish.custom) then
                return "";
              end
              local _, errorString = loadstring("return function() "..data.actions.finish.custom.."\n end");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 35,
            hidden = function()
              if not(data.actions.finish.do_custom and data.actions.finish.custom) then
                return true;
              else
                local loadedFunction, errorString = loadstring("return function() "..data.actions.finish.custom.."\n end");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          }
        }
      },
      animation = {
        type = "group",
        name = L["Animations"],
        order = 60,
        get = function(info)
          local split = info[#info]:find("_");
          if(split) then
            local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);

            if(data.animation and data.animation[field]) then
              return data.animation[field][value];
            else
              if(value == "scalex" or value == "scaley") then
                return 1;
              else
                return nil;
              end
            end
          end
        end,
        set = function(info, v)
          local split = info[#info]:find("_");
          local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
          data.animation = data.animation or {};
          data.animation[field] = data.animation[field] or {};
          data.animation[field][value] = v;
          if(field == "main" and not WeakAuras.IsAnimating("display", id)) then
            WeakAuras.Animate("display", id, "main", data.animation.main, WeakAuras.regions[id].region, false, nil, true);
            if(WeakAuras.clones[id]) then
              for cloneId, cloneRegion in pairs(WeakAuras.clones[id]) do
                WeakAuras.Animate("display", id, "main", data.animation.main, cloneRegion, false, nil, true, cloneId);
              end
            end
          end
          WeakAuras.Add(data);
        end,
        disabled = function(info, v)
          local split = info[#info]:find("_");
          local valueToType = {
            alphaType = "use_alpha",
            alpha = "use_alpha",
            translateType = "use_translate",
            x = "use_translate",
            y = "use_translate",
            scaleType = "use_scale",
            scalex = "use_scale",
            scaley = "use_scale",
            rotateType = "use_rotate",
            rotate = "use_rotate",
            colorType = "use_color",
            color = "use_color"
          }
          if(split) then
            local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
            if(data.animation and data.animation[field]) then
              if(valueToType[value]) then
                return not data.animation[field][valueToType[value]];
              else
                return false;
              end
            else
              return true;
            end
          else
            return false;
          end
        end,
        args = {
          start_header = {
            type = "header",
            name = L["Start"],
            order = 30
          },
          start_type = {
            type = "select",
            name = L["Type"],
            order = 32,
            values = anim_types,
            disabled = false
          },
          start_preset = {
            type = "select",
            name = L["Preset"],
            order = 33,
            values = function() return filterAnimPresetTypes(anim_start_preset_types, id) end,
            hidden = function() return data.animation.start.type ~= "preset" end
          },
          start_duration_type_no_choice = {
            type = "select",
            name = L["Time in"],
            order = 33,
            width = "half",
            values = duration_types_no_choice,
            disabled = true,
            hidden = function() return data.animation.start.type ~= "custom" or WeakAuras.CanHaveDuration(data) end,
            get = function() return "seconds" end
          },
          start_duration_type = {
            type = "select",
            name = L["Time in"],
            order = 33,
            width = "half",
            values = duration_types,
            hidden = function() return data.animation.start.type ~= "custom" or not WeakAuras.CanHaveDuration(data) end
          },
          start_duration = {
            type = "input",
            name = function()
              if(data.animation.start.duration_type == "relative") then
                return L["% of Progress"];
              else
                return L["Duration (s)"];
              end
            end,
            desc = function()
              if(data.animation.start.duration_type == "relative") then
                return L["Animation relative duration description"];
              else
                return L["The duration of the animation in seconds."];
              end
            end,
            order = 33.5,
            width = "half",
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_use_alpha = {
            type = "toggle",
            name = L["Fade In"],
            order = 34,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_alphaType = {
            type = "select",
            name = L["Type"],
            order = 35,
            values = anim_alpha_types,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_alphaFunc = {
            type = "input",
            width = "normal",
            multiline = true,
            name = L["Custom Function"],
            order = 35.3,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha end,
            get = function() return data.animation.start.alphaFunc and data.animation.start.alphaFunc:sub(8); end,
            set = function(info, v) data.animation.start.alphaFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          start_alphaFunc_expand = {
            type = "execute",
            order = 35.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "start", "alphaFunc"}, nil, true)
            end,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha end
          },
          start_alphaFuncError = {
            type = "description",
            name = function()
              if not(data.animation.start.alphaFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.start.alphaFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 35.6,
            hidden = function()
              if(data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.start.alphaFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_alpha = {
            type = "range",
            name = L["Alpha"],
            width = "double",
            order = 36,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_use_translate = {
            type = "toggle",
            name = L["Slide In"],
            order = 38,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_translateType = {
            type = "select",
            name = L["Type"],
            order = 39,
            values = anim_translate_types,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_translateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 39.3,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate end,
            get = function() return data.animation.start.translateFunc and data.animation.start.translateFunc:sub(8); end,
            set = function(info, v) data.animation.start.translateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          start_translateFunc_expand = {
            type = "execute",
            order = 39.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "start", "translateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate end,
          },
          start_translateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.start.translateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.start.translateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 39.6,
            hidden = function()
              if(data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.start.translateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_x = {
            type = "range",
            name = L["X Offset"],
            order = 40,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_y = {
            type = "range",
            name = L["Y Offset"],
            order = 41,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.start.type ~= "custom" end
          },
          start_use_scale = {
            type = "toggle",
            name = L["Zoom In"],
            order = 42,
            hidden = function()
              return (
                data.animation.start.type ~= "custom"
                or not WeakAuras.regions[id].region.Scale
                ) end
          },
          start_scaleType = {
            type = "select",
            name = L["Type"],
            order = 43,
            values = anim_scale_types,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          start_scaleFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 43.3,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale) end,
            get = function() return data.animation.start.scaleFunc and data.animation.start.scaleFunc:sub(8); end,
            set = function(info, v) data.animation.start.scaleFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          start_scaleFunc_expand = {
            type = "execute",
            order = 43.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "start", "scaleFunc"}, nil, true)
            end,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale) end,
          },
          start_scaleFuncError = {
            type = "description",
            name = function()
              if not(data.animation.start.scaleFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.start.scaleFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 43.6,
            hidden = function()
              if(data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.start.scaleFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_scalex = {
            type = "range",
            name = L["X Scale"],
            order = 44,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          start_scaley = {
            type = "range",
            name = L["Y Scale"],
            order = 45,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          start_use_rotate = {
            type = "toggle",
            name = L["Rotate In"],
            order = 46,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          start_rotateType = {
            type = "select",
            name = L["Type"],
            order = 47,
            values = anim_rotate_types,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          start_rotateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 47.3,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate) end,
            get = function() return data.animation.start.rotateFunc and data.animation.start.rotateFunc:sub(8); end,
            set = function(info, v) data.animation.start.rotateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          start_rotateFunc_expand = {
            type = "execute",
            order = 47.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "start", "rotateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate) end,
          },
          start_rotateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.start.rotateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.start.rotateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 47.6,
            hidden = function()
              if(data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.start.rotateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_rotate = {
            type = "range",
            name = L["Angle"],
            width = "double",
            order = 48,
            softMin = 0,
            softMax = 360,
            bigStep = 3,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          start_use_color = {
            type = "toggle",
            name = L["Color"],
            order = 48.2,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          start_colorType = {
            type = "select",
            name = L["Type"],
            order = 48.5,
            values = anim_color_types,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          start_colorFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 48.7,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color) end,
            get = function() return data.animation.start.colorFunc and data.animation.start.colorFunc:sub(8); end,
            set = function(info, v) data.animation.start.colorFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          start_colorFunc_expand = {
            type = "execute",
            order = 48.8,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "start", "colorFunc"}, nil, true)
            end,
            hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color) end,
          },
          start_colorFuncError = {
            type = "description",
            name = function()
              if not(data.animation.start.colorFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.start.colorFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 49,
            hidden = function()
              if(data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.start.colorFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          start_color = {
            type = "color",
            name = L["Color"],
            width = "double",
            order = 49.5,
            hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
            get = function()
              return data.animation.start.colorR,
                data.animation.start.colorG,
                data.animation.start.colorB,
                data.animation.start.colorA;
            end,
            set = function(info, r, g, b, a)
              data.animation.start.colorR = r;
              data.animation.start.colorG = g;
              data.animation.start.colorB = b;
              data.animation.start.colorA = a;
            end
          },
          main_header = {
            type = "header",
            name = L["Main"],
            order = 50
          },
          main_type = {
            type = "select",
            name = L["Type"],
            order = 52,
            values = anim_types,
            disabled = false
          },
          main_preset = {
            type = "select",
            name = L["Preset"],
            order = 53,
            values = function() return filterAnimPresetTypes(anim_main_preset_types, id) end,
            hidden = function() return data.animation.main.type ~= "preset" end
          },
          main_duration_type_no_choice = {
            type = "select",
            name = L["Time in"],
            order = 53,
            width = "half",
            values = duration_types_no_choice,
            disabled = true,
            hidden = function() return data.animation.main.type ~= "custom" or WeakAuras.CanHaveDuration(data) end,
            get = function() return "seconds" end
          },
          main_duration_type = {
            type = "select",
            name = L["Time in"],
            order = 53,
            width = "half",
            values = duration_types,
            hidden = function() return data.animation.main.type ~= "custom" or not WeakAuras.CanHaveDuration(data) end
          },
          main_duration = {
            type = "input",
            name = function()
              if(data.animation.main.duration_type == "relative") then
                return L["% of Progress"];
              else
                return L["Duration (s)"];
              end
            end,
            desc = function()
              if(data.animation.main.duration_type == "relative") then
                return L["Animation relative duration description"];
              else
                local ret = "";
                ret = ret..L["The duration of the animation in seconds."].."\n";
                ret = ret..L["Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."]
                return ret;
              end
            end,
            order = 53.5,
            width = "half",
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_use_alpha = {
            type = "toggle",
            name = L["Fade"],
            order = 54,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_alphaType = {
            type = "select",
            name = L["Type"],
            order = 55,
            values = anim_alpha_types,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_alphaFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 55.3,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha end,
            get = function() return data.animation.main.alphaFunc and data.animation.main.alphaFunc:sub(8); end,
            set = function(info, v) data.animation.main.alphaFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          main_alphaFunc_expand = {
            type = "execute",
            order = 55.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "main", "alphaFunc"}, nil, true)
            end,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha end,
          },
          main_alphaFuncError = {
            type = "description",
            name = function()
              if not(data.animation.main.alphaFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.main.alphaFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 55.6,
            hidden = function()
              if(data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.main.alphaFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          main_alpha = {
            type = "range",
            name = L["Alpha"],
            width = "double",
            order = 56,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_use_translate = {
            type = "toggle",
            name = L["Slide"],
            order = 58,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_translateType = {
            type = "select",
            name = L["Type"],
            order = 59,
            values = anim_translate_types,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_translateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 59.3,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate end,
            get = function() return data.animation.main.translateFunc and data.animation.main.translateFunc:sub(8); end,
            set = function(info, v) data.animation.main.translateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          main_translateFunc_expand = {
            type = "execute",
            order = 59.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "main", "translateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate end,
          },
          main_translateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.main.translateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.main.translateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 59.6,
            hidden = function()
              if(data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.main.translateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          main_x = {
            type = "range",
            name = L["X Offset"],
            order = 60,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_y = {
            type = "range",
            name = L["Y Offset"],
            order = 61,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.main.type ~= "custom" end
          },
          main_use_scale = {
            type = "toggle",
            name = L["Zoom"],
            order = 62,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          main_scaleType = {
            type = "select",
            name = L["Type"],
            order = 63,
            values = anim_scale_types,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          main_scaleFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 63.3,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale) end,
            get = function() return data.animation.main.scaleFunc and data.animation.main.scaleFunc:sub(8); end,
            set = function(info, v) data.animation.main.scaleFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          main_scaleFunc_expand = {
            type = "execute",
            order = 63.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "main", "scaleFunc"}, nil, true)
            end,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale) end,
          },
          main_scaleFuncError = {
            type = "description",
            name = function()
              if not(data.animation.main.scaleFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.main.scaleFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 63.6,
            hidden = function()
              if(data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.main.scaleFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          main_scalex = {
            type = "range",
            name = L["X Scale"],
            order = 64,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          main_scaley = {
            type = "range",
            name = L["Y Scale"],
            order = 65,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          main_use_rotate = {
            type = "toggle",
            name = L["Rotate"],
            order = 66,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          main_rotateType = {
            type = "select",
            name = L["Type"],
            order = 67,
            values = anim_rotate_types,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          main_rotateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 67.3,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate) end,
            get = function() return data.animation.main.rotateFunc and data.animation.main.rotateFunc:sub(8); end,
            set = function(info, v) data.animation.main.rotateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          main_rotateFunc_expand = {
            type = "execute",
            order = 67.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "main", "rotateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate) end,
          },
          main_rotateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.main.rotateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.main.rotateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 67.6,
            hidden = function()
              if(data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.main.rotateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          main_rotate = {
            type = "range",
            name = L["Angle"],
            width = "double",
            order = 68,
            softMin = 0,
            softMax = 360,
            bigStep = 3,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          main_use_color = {
            type = "toggle",
            name = L["Color"],
            order = 68.2,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          main_colorType = {
            type = "select",
            name = L["Type"],
            order = 68.5,
            values = anim_color_types,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          main_colorFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 68.7,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color) end,
            get = function() return data.animation.main.colorFunc and data.animation.main.colorFunc:sub(8); end,
            set = function(info, v) data.animation.main.colorFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          main_colorFunc_expand = {
            type = "execute",
            order = 68.8,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "main", "colorFunc"}, nil, true)
            end,
            hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color) end,
          },
          main_colorFuncError = {
            type = "description",
            name = function()
              if not(data.animation.main.colorFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.main.colorFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 69,
            hidden = function()
              if(data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.main.colorFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          main_color = {
            type = "color",
            name = L["Color"],
            width = "double",
            order = 69.5,
            hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
            get = function()
              return data.animation.main.colorR,
                data.animation.main.colorG,
                data.animation.main.colorB,
                data.animation.main.colorA;
            end,
            set = function(info, r, g, b, a)
              data.animation.main.colorR = r;
              data.animation.main.colorG = g;
              data.animation.main.colorB = b;
              data.animation.main.colorA = a;
            end
          },
          finish_header = {
            type = "header",
            name = L["Finish"],
            order = 70
          },
          finish_type = {
            type = "select",
            name = L["Type"],
            order = 72,
            values = anim_types,
            disabled = false
          },
          finish_preset = {
            type = "select",
            name = L["Preset"],
            order = 73,
            values = function() return filterAnimPresetTypes(anim_finish_preset_types, id) end,
            hidden = function() return data.animation.finish.type ~= "preset" end
          },
          finish_duration_type_no_choice = {
            type = "select",
            name = L["Time in"],
            order = 73,
            width = "half",
            values = duration_types_no_choice,
            disabled = true,
            hidden = function() return data.animation.finish.type ~= "custom" end,
            get = function() return "seconds" end
          },
          finish_duration = {
            type = "input",
            name = L["Duration (s)"],
            desc = "The duration of the animation in seconds.\n\nThe finish animation does not start playing until after the display would normally be hidden.",
            order = 73.5,
            width = "half",
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_use_alpha = {
            type = "toggle",
            name = L["Fade Out"],
            order = 74,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_alphaType = {
            type = "select",
            name = L["Type"],
            order = 75,
            values = anim_alpha_types,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_alphaFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 75.3,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha end,
            get = function() return data.animation.finish.alphaFunc and data.animation.finish.alphaFunc:sub(8); end,
            set = function(info, v) data.animation.finish.alphaFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          finish_alphaFunc_expand = {
            type = "execute",
            order = 75.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "finish", "alphaFunc"}, nil, true)
            end,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha end,
          },
          finish_alphaFuncError = {
            type = "description",
            name = function()
              if not(data.animation.finish.alphaFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.finish.alphaFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 75.6,
            hidden = function()
              if(data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.finish.alphaFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_alpha = {
            type = "range",
            name = L["Alpha"],
            width = "double",
            order = 76,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_use_translate = {
            type = "toggle",
            name = L["Slide Out"],
            order = 78,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_translateType = {
            type = "select",
            name = L["Type"],
            order = 79,
            values = anim_translate_types,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_translateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 79.3,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate end,
            get = function() return data.animation.finish.translateFunc and data.animation.finish.translateFunc:sub(8); end,
            set = function(info, v) data.animation.finish.translateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          finish_translateFunc_expand = {
            type = "execute",
            order = 79.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "finish", "translateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate end,
          },
          finish_translateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.finish.translateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.finish.translateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 79.6,
            hidden = function()
              if(data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.finish.translateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_x = {
            type = "range",
            name = L["X Offset"],
            order = 80,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_y = {
            type = "range",
            name = L["Y Offset"],
            order = 81,
            softMin = -200,
            softMax = 200,
            step = 1,
            bigStep = 5,
            hidden = function() return data.animation.finish.type ~= "custom" end
          },
          finish_use_scale = {
            type = "toggle",
            name = L["Zoom Out"],
            order = 82,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          finish_scaleType = {
            type = "select",
            name = L["Type"],
            order = 83,
            values = anim_scale_types,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          finish_scaleFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 83.3,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale) end,
            get = function() return data.animation.finish.scaleFunc and data.animation.finish.scaleFunc:sub(8); end,
            set = function(info, v) data.animation.finish.scaleFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          finish_scaleFunc_expand = {
            type = "execute",
            order = 83.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "finish", "scaleFunc"}, nil, true)
            end,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale) end,
          },
          finish_scaleFuncError = {
            type = "description",
            name = function()
              if not(data.animation.finish.scaleFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.finish.scaleFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 83.6,
            hidden = function()
              if(data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.finish.scaleFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_scalex = {
            type = "range",
            name = L["X Scale"],
            order = 84,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          finish_scaley = {
            type = "range",
            name = L["Y Scale"],
            order = 85,
            softMin = 0,
            softMax = 5,
            step = 0.01,
            bigStep = 0.1,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
          },
          finish_use_rotate = {
            type = "toggle",
            name = L["Rotate Out"],
            order = 86,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          finish_rotateType = {
            type = "select",
            name = L["Type"],
            order = 87,
            values = anim_rotate_types,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          finish_rotateFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 87.3,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate) end,
            get = function() return data.animation.finish.rotateFunc and data.animation.finish.rotateFunc:sub(8); end,
            set = function(info, v) data.animation.finish.rotateFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          finish_rotateFunc_expand = {
            type = "execute",
            order = 87.4,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "finish", "rotateFunc"}, nil, true)
            end,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate) end,
          },
          finish_rotateFuncError = {
            type = "description",
            name = function()
              if not(data.animation.finish.rotateFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.finish.rotateFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 87.6,
            hidden = function()
              if(data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.finish.rotateFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_rotate = {
            type = "range",
            name = L["Angle"],
            width = "double",
            order = 88,
            softMin = 0,
            softMax = 360,
            bigStep = 3,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
          },
          finish_use_color = {
            type = "toggle",
            name = L["Color"],
            order = 88.2,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          finish_colorType = {
            type = "select",
            name = L["Type"],
            order = 88.5,
            values = anim_color_types,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
          },
          finish_colorFunc = {
            type = "input",
            multiline = true,
            name = L["Custom Function"],
            width = "normal",
            order = 88.7,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color) end,
            get = function() return data.animation.finish.colorFunc and data.animation.finish.colorFunc:sub(8); end,
            set = function(info, v) data.animation.finish.colorFunc = "return "..(v or ""); WeakAuras.Add(data); end
          },
          finish_colorFunc_expand = {
            type = "execute",
            order = 88.8,
            name = L["Expand Text Editor"],
            func = function()
              WeakAuras.OpenTextEditor(data, {"animation", "finish", "colorFunc"}, nil, true)
            end,
            hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color) end,
          },
          finish_colorFuncError = {
            type = "description",
            name = function()
              if not(data.animation.finish.colorFunc) then
                return "";
              end
              local _, errorString = loadstring(data.animation.finish.colorFunc or "");
              return errorString and "|cFFFF0000"..errorString or "";
            end,
            width = "double",
            order = 89,
            hidden = function()
              if(data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color)) then
                return true;
              else
                local loadedFunction, errorString = loadstring(data.animation.finish.colorFunc or "");
                if(errorString and not loadedFunction) then
                  return false;
                else
                  return true;
                end
              end
            end
          },
          finish_color = {
            type = "color",
            name = L["Color"],
            width = "double",
            order = 89.5,
            hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
            get = function()
              return data.animation.finish.colorR,
                data.animation.finish.colorG,
                data.animation.finish.colorB,
                data.animation.finish.colorA;
            end,
            set = function(info, r, g, b, a)
              data.animation.finish.colorR = r;
              data.animation.finish.colorG = g;
              data.animation.finish.colorB = b;
              data.animation.finish.colorA = a;
            end
          }
        }
      }
    }
  };

  WeakAuras.ReloadTriggerOptions(data);
end

function WeakAuras.EnsureOptions(id)
  if not(displayOptions[id]) then
    WeakAuras.AddOption(id, WeakAuras.GetData(id));
  end
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

function WeakAuras.ReloadTriggerOptions(data)
  local id = data.id;
  local iconCache = spellCache.Get();
  WeakAuras.EnsureOptions(id);

  local trigger, untrigger, appendToTriggerPath, appendToUntriggerPath;
  if(data.controlledChildren) then
    optionTriggerChoices[id] = nil;
    for index, childId in pairs(data.controlledChildren) do
      if not(optionTriggerChoices[id]) then
        optionTriggerChoices[id] = optionTriggerChoices[childId];
        trigger = WeakAuras.GetData(childId).trigger;
        untrigger = WeakAuras.GetData(childId).untrigger;
      else
        if(optionTriggerChoices[id] ~= optionTriggerChoices[childId]) then
          trigger, untrigger = {}, {};
          optionTriggerChoices[id] = -1;
          break;
        end
      end
    end

    optionTriggerChoices[id] = optionTriggerChoices[id] or 0;

    if(optionTriggerChoices[id] >= 0) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          optionTriggerChoices[childId] = optionTriggerChoices[id];
          WeakAuras.ReloadTriggerOptions(childData);
        end
      end
    end
  else
    optionTriggerChoices[id] = optionTriggerChoices[id] or 0;
    if(optionTriggerChoices[id] == 0) then
      trigger = data.trigger;
      untrigger = data.untrigger;
    else
      trigger = data.additional_triggers and data.additional_triggers[optionTriggerChoices[id]].trigger or data.trigger;
      untrigger = data.additional_triggers and data.additional_triggers[optionTriggerChoices[id]].untrigger or data.untrigger;
    end
  end

  if(optionTriggerChoices[id] == 0) then
    function appendToTriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "trigger");
      return ret;
    end

    function appendToUntriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "untrigger");
      return ret;
    end
  elseif (optionTriggerChoices[id] > 0) then
    function appendToTriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "trigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "additional_triggers");
      return ret;
    end

    function appendToUntriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "untrigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "additional_triggers");
      return ret;
    end
  else
    function appendToTriggerPath(...) end
    function appendToUntriggerPath(...) end
  end

  local function getAuraMatchesLabel(name)
    local ids = iconCache[name]
    if(ids) then
      local descText = "";
      local numMatches = 0;
      for id, _ in pairs(ids) do
        numMatches = numMatches + 1;
      end
      if(numMatches == 1) then
        return L["1 Match"];
      else
        return L["%i Matches"]:format(numMatches);
      end
    else
      return "";
    end
  end

  -- the spell id table is sparse, so tremove doesn't work
  local function spellId_tremove(tbl, pos)
    for i = pos, 9, 1 do
      tbl[i] = tbl[i + 1]
    end
  end

  local function getAuraMatchesList(name)
    local ids = iconCache[name]
    if(ids) then
      local descText = "";
      for id, _ in pairs(ids) do
        local name, _, icon = GetSpellInfo(id);
        if(icon) then
          if(descText == "") then
            descText = "|T"..icon..":0|t: "..id;
          else
            descText = descText.."\n|T"..icon..":0|t: "..id;
          end
        end
      end
      return descText;
    else
      return "";
    end
  end

  local aura_options = {
    fullscan = {
      type = "toggle",
      name = L["Use Full Scan (High CPU)"],
      width = "double",
      order = 9,
    },
    autoclone = {
      type = "toggle",
      name = L["Show all matches (Auto-clone)"],
      width = "double",
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      set = function(info, v)
        trigger.autoclone = v;
        if(v == true) then
          WeakAuras.ShowCloneDialog(data);
          WeakAuras.UpdateCloneConfig(data);
        else
          WeakAuras.CollapseAllClones(data.id);
        end
        WeakAuras.Add(data);
      end,
      order = 9.5
    },
    useName = {
      type = "toggle",
      name = L["Aura(s)"],
      width = "half",
      order = 10,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      disabled = true,
      get = function() return true end
    },
    use_name = {
      type = "toggle",
      name = L["Aura Name"],
      order = 10,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end
    },
    name_operator = {
      type = "select",
      name = L["Operator"],
      order = 11,
      disabled = function() return not trigger.use_name end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      values = WeakAuras.string_operator_types
    },
    name = {
      type = "input",
      name = L["Aura Name"],
      width = "double",
      order = 12,
      disabled = function() return not trigger.use_name end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      set = function(info, v)
        if (tonumber(v)) then
          trigger.spellId = tonumber(v);
          trigger.name = nil;
        else
          trigger.spellId = nil;
          trigger.name = v;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    use_tooltip = {
      type = "toggle",
      name = L["Tooltip"],
      order = 13,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    tooltip_operator = {
      type = "select",
      name = L["Operator"],
      order = 14,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end,
      values = WeakAuras.string_operator_types
    },
    tooltip = {
      type = "input",
      name = L["Tooltip"],
      width = "double",
      order = 15,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    use_stealable = {
      type = "toggle",
      name = function(input)
        local value = trigger.use_stealable;
        if(value == nil) then return L["Stealable"];
        elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..L["Stealable"];
        else return "|cFF00FF00"..L["Stealable"]; end
      end,
      width = "double",
      order = 16,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function()
        local value = trigger.use_stealable;
        if(value == nil) then return false;
        elseif(value == false) then return "false";
        else return "true"; end
      end,
      set = function(info, v)
        if(v) then
          trigger.use_stealable = true;
        else
          local value = trigger.use_stealable;
          if(value == false) then trigger.use_stealable = nil;
          else trigger.use_stealable = false end
        end
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
      end
    },
    use_spellId = {
      type = "toggle",
      name = L["Spell ID"],
      order = 17,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    spellId = {
      type = "input",
      name = L["Spell ID"],
      order = 18,
      disabled = function() return not trigger.use_spellId end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    use_debuffClass = {
      type = "toggle",
      name = L["Debuff Type"],
      order = 19,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end
    },
    debuffClass = {
      type = "select",
      name = L["Debuff Type"],
      order = 20,
      disabled = function() return not trigger.use_debuffClass end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      values = WeakAuras.debuff_class_types
    },
    multiuse_name = {
      type = "toggle",
      name = L["Aura Name"],
      width = "half",
      order = 10,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end,
      disabled = true,
      get = function() return true end
    },
    multiicon = {
      type = "execute",
      name = "",
      width = "half",
      image = function()
        if (not trigger.name) then return "" end;
        local icon =  spellCache.GetIcon(trigger.name);
        return icon and tostring(icon) or "", 18, 18 end,
      order = 11,
      disabled = function() return not trigger.name and spellCache.GetIcon(trigger.name) end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end
    },
    multiname = {
      type = "input",
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = 12,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end,
      get = function(info) return trigger.spellId and tostring(trigger.spellId) or trigger.name end,
      set = function(info, v)
        if(v == "") then
          trigger.name = nil;
          trigger.spellId = nil;
        else
          trigger.name, trigger.spellId = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name1icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[1]) end,
      desc = function() return getAuraMatchesList(trigger.names[1]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[1]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 11,
      disabled = function() return not spellCache.GetIcon(trigger.names[1]) end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end
    },
    name1 = {
      type = "input",
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = 12,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[1] and tostring(trigger.spellIds[1]) or trigger.names[1] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[1]) then
            tremove(trigger.names, 1);
            spellId_tremove(trigger.spellIds, 1);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[1], trigger.spellIds[1] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name2space = {
      type = "execute",
      name = L["or"],
      width = "half",
      image = function() return "", 0, 0 end,
      order = 13,
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name2icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[2]) end,
      desc = function() return getAuraMatchesList(trigger.names[2]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[2]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 14,
      disabled = function() return not spellCache.GetIcon(trigger.names[2]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name2 = {
      type = "input",
      order = 15,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[2] and tostring(trigger.spellIds[2]) or trigger.names[2] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[2]) then
            tremove(trigger.names, 2);
            spellId_tremove(trigger.spellIds, 2);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[2], trigger.spellIds[2] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name3space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 16,
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name3icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[3]) end,
      desc = function() return getAuraMatchesList(trigger.names[3]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[3]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 17,
      disabled = function() return not spellCache.GetIcon(trigger.names[3]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name3 = {
      type = "input",
      order = 18,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[3] and tostring(trigger.spellIds[3]) or trigger.names[3] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[3]) then
            tremove(trigger.names, 3);
            spellId_tremove(trigger.spellIds, 3);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[3], trigger.spellIds[3] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name4space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 19,
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name4icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[4]) end,
      desc = function() return getAuraMatchesList(trigger.names[4]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[4]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 20,
      disabled = function() return not spellCache.GetIcon(trigger.names[4]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name4 = {
      type = "input",
      order = 21,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[4] and tostring(trigger.spellIds[4]) or trigger.names[4] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[4]) then
            tremove(trigger.names, 4);
            spellId_tremove(trigger.spellIds, 4);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[4], trigger.spellIds[4] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name5space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 22,
      disabled = function() return not spellCache.GetIcon(trigger.names[5]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name5icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[5]) end,
      desc = function() return getAuraMatchesList(trigger.names[5]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[5]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 23,
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name5 = {
      type = "input",
      order = 24,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[5] and tostring(trigger.spellIds[5]) or trigger.names[5] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[5]) then
            tremove(trigger.names, 5);
            spellId_tremove(trigger.spellIds, 5);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[5], trigger.spellIds[5] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name6space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 25,
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name6icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[6]) end,
      desc = function() return getAuraMatchesList(trigger.names[6]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[6]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 26,
      disabled = function() return not spellCache.GetIcon(trigger.names[6]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name6 = {
      type = "input",
      order = 27,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[6] and tostring(trigger.spellIds[6]) or trigger.names[6] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[6]) then
            tremove(trigger.names, 6);
            spellId_tremove(trigger.spellIds, 6);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[6], trigger.spellIds[6] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name7space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 28,
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name7icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[7]) end,
      desc = function() return getAuraMatchesList(trigger.names[7]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[7]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 29,
      disabled = function() return not spellCache.GetIcon(trigger.names[7]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name7 = {
      type = "input",
      order = 30,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[7] and tostring(trigger.spellIds[7]) or trigger.names[7] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[7]) then
            tremove(trigger.names, 7);
            spellId_tremove(trigger.spellIds, 7);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[7], trigger.spellIds[7] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name8space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 31,
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name8icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[8]) end,
      desc = function() return getAuraMatchesList(trigger.names[8]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[8]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 32,
      disabled = function() return not spellCache.GetIcon(trigger.names[8]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name8 = {
      type = "input",
      order = 33,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[8] and tostring(trigger.spellIds[8]) or trigger.names[8] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[8]) then
            tremove(trigger.names, 8);
            spellId_tremove(trigger.spellIds, 8);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[8], trigger.spellIds[8] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name9space = {
      type = "execute",
      name = "",
      width = "half",
      image = function() return "", 0, 0 end,
      order = 34,
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name9icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[9]) end,
      desc = function() return getAuraMatchesList(trigger.names[9]) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.names[9]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 35,
      disabled = function() return not spellCache.GetIcon(trigger.names[9]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name9 = {
      type = "input",
      order = 36,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[9] and tostring(trigger.spellIds[9]) or trigger.names[9] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[9]) then
            tremove(trigger.names, 9);
            spellId_tremove(trigger.spellIds, 9);
          end
        else
          if(tonumber(v)) then
            WeakAuras.ShowSpellIDDialog(trigger, v);
          end
          trigger.names[9], trigger.spellIds[9] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    useUnit = {
      type = "toggle",
      name = L["Unit"],
      order = 40,
      disabled = true,
      hidden = function() return not (trigger.type == "aura"); end,
      get = function() return true end
    },
    unit = {
      type = "select",
      name = L["Unit"],
      order = 41,
      values = function()
        if(trigger.fullscan) then
          return actual_unit_types_with_specific;
        else
          return unit_types;
        end
      end,
      hidden = function() return not (trigger.type == "aura"); end,
      set = function(info, v)
        trigger.unit = v;
        trigger.use_specific_unit = (v == "member");
        if(v == "multi") then
          WeakAuras.ShowCloneDialog(data);
          WeakAuras.UpdateCloneConfig(data);
        else
          WeakAuras.CollapseAllClones(data.id);
        end
        WeakAuras.Add(data);
      end,
      get = function()
        if(trigger.fullscan and (trigger.unit == "group" or trigger.unit == "multi")) then
          trigger.unit = "player";
        end
        return trigger.unit;
      end
    },
    useSpecificUnit = {
      type = "toggle",
      name = L["Specific Unit"],
      order = 42,
      disabled = true,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "member") end,
      get = function() return true end
    },
    specificUnit = {
      type = "input",
      name = L["Specific Unit"],
      order = 43,
      desc = L["Can be a name or a UID (e.g., party1). Only works on friendly players in your group."],
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "member") end
    },
    useGroup_count = {
      type = "toggle",
      name = L["Group Member Count"],
      disabled = true,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return true; end,
      order = 45
    },
    group_countOperator = {
      type = "select",
      name = L["Operator"],
      order = 46,
      width = "half",
      values = operator_types,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return trigger.group_countOperator; end
    },
    group_count = {
      type = "input",
      name = L["Count"],
      desc = function()
        local groupType = unit_types[trigger.unit or "group"] or "|cFFFF0000error|r";
        return L["Group aura count description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType);
      end,
      order = 47,
      width = "half",
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return trigger.group_count; end,
      set = function(info, v)
        if(WeakAuras.ParseNumber(v)) then
          trigger.group_count = v;
        else
          trigger.group_count = "";
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    groupclone = {
      type = "toggle",
      name = L["Show all matches (Auto-clone)"],
      width = "double",
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      set = function(info, v)
        trigger.groupclone = v;
        if(v == true) then
          WeakAuras.ShowCloneDialog(data);
          WeakAuras.UpdateCloneConfig(data);
        else
          WeakAuras.CollapseAllClones(data.id);
        end
        WeakAuras.Add(data);
      end,
      order = 47.1
    },
    name_info = {
      type = "select",
      name = L["Name Info"],
      order = 47.3,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group" and not trigger.groupclone); end,
      disabled = function() return not WeakAuras.CanShowNameInfo(data); end,
      get = function()
        if(WeakAuras.CanShowNameInfo(data)) then
          return trigger.name_info;
        else
          return nil;
        end
      end,
      values = group_aura_name_info_types
    },
    stack_info = {
      type = "select",
      name = L["Stack Info"],
      order = 47.6,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group" and not trigger.groupclone); end,
      disabled = function() return not WeakAuras.CanShowStackInfo(data); end,
      get = function()
        if(WeakAuras.CanShowStackInfo(data)) then
          return trigger.stack_info;
        else
          return nil;
        end
      end,
      values = group_aura_stack_info_types
    },
    hideAlone = {
      type = "toggle",
      name = L["Hide When Not In Group"],
      order = 48,
      width = "double",
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
    },
    useDebuffType = {
      type = "toggle",
      name = L["Aura Type"],
      order = 50,
      disabled = true,
      hidden = function() return not (trigger.type == "aura"); end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      name = L["Aura Type"],
      order = 51,
      values = debuff_types,
      hidden = function() return not (trigger.type == "aura"); end
    },
    subcount = {
      type = "toggle",
      width = "double",
      name = L["Use tooltip \"size\" instead of stacks"],
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan) end,
      order = 55
    },
    useRem = {
      type = "toggle",
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      order = 56
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 57,
      width = "half",
      values = operator_types,
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function() return trigger.useRem and trigger.remOperator or nil end
    },
    rem = {
      type = "input",
      name = L["Remaining Time"],
      validate = ValidateNumeric,
      order = 58,
      width = "half",
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    useCount = {
      type = "toggle",
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      order = 60
    },
    countOperator = {
      type = "select",
      name = L["Operator"],
      order = 62,
      width = "half",
      values = operator_types,
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useCount and trigger.countOperator or nil end
    },
    count = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 65,
      width = "half",
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useCount and trigger.count or nil end
    },
    ownOnly = {
      type = "toggle",
      name = function()
        local value = trigger.ownOnly;
        if(value == nil) then return L["Own Only"];
        elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..L["Own Only"];
        else return "|cFF00FF00"..L["Own Only"]; end
      end,
      desc = function()
        local value = trigger.ownOnly;
        if(value == nil) then return L["Only match auras cast by the player"];
        elseif(value == false) then return L["Only match auras cast by people other than the player"];
        else return L["Only match auras cast by the player"]; end
      end,
      get = function()
        local value = trigger.ownOnly;
        if(value == nil) then return false;
        elseif(value == false) then return "false";
        else return "true"; end
      end,
      set = function(info, v)
        if(v) then
          trigger.ownOnly = true;
        else
          local value = trigger.ownOnly;
          if(value == false) then trigger.ownOnly = nil;
          else trigger.ownOnly = false end
        end
        WeakAuras.Add(data);
      end,
      order = 70,
      hidden = function() return not (trigger.type == "aura"); end
    },
    inverse = {
      type = "toggle",
      name = L["Inverse"],
      desc = function()
        if(trigger.unit == "group") then
          return L["Show players that are |cFFFF0000not affected"];
        else
          return L["Activate when the given aura(s) |cFFFF0000can't|r be found"];
        end
      end,
      order = 75,
      hidden = function() return not (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.autoclone) and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone)); end
    }
  };

  local function deleteTrigger()
    if(data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          if (optionTriggerChoices[childId] == 0) then
            childData.trigger = childData.additional_triggers[1].trigger;
            childData.untrigger = childData.additional_triggers[1].untrigger;
            tremove(childData.additional_triggers, 1);
          else
            tremove(childData.additional_triggers, optionTriggerChoices[childId]);
            optionTriggerChoices[childId] = optionTriggerChoices[childId] - 1;
          end
          childData.numTriggers = 1 + (childData.additional_triggers and #childData.additional_triggers or 0)
          WeakAuras.ReloadTriggerOptions(childData);
        end
      end
    else
      if (optionTriggerChoices[id] == 0) then
        data.trigger = data.additional_triggers[1].trigger;
        data.untrigger = data.additional_triggers[1].untrigger;
        tremove(data.additional_triggers, 1);
      else
        tremove(data.additional_triggers, optionTriggerChoices[id]);
        optionTriggerChoices[id] = optionTriggerChoices[id] - 1;
      end
      data.numTriggers = 1 + (data.additional_triggers and #data.additional_triggers or 0)
    end
    WeakAuras.Add(data);
    WeakAuras.ReloadTriggerOptions(data);
  end

  local trigger_options = {
    disjunctive = {
      type = "select",
      name = L["Required For Activation"],
      width = "double",
      order = 0,
      hidden = function() return not (data.additional_triggers and #data.additional_triggers > 0) end,
      values = WeakAuras.trigger_require_types,
      get = function() return data.disjunctive or "all" end,
      set = function(info, v) data.disjunctive = v end
    },
    custom_trigger_combination = {
      type = "input",
      name = L["Custom"],
      order = 0.1,
      multiline = true,
      width = "normal",
      hidden = function() return not (data.disjunctive == "custom") end,
      get = function() return data.customTriggerLogic end,
      set = function(info, v)
        data.customTriggerLogic = v;
        WeakAuras.Add(data);
      end
    },
    custom_trigger_combination_expand = {
      type = "execute",
      order = 0.15,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, {"customTriggerLogic"})
      end,
      hidden = function() return not (data.disjunctive == "custom") end,
    },
    custom_trigger_combination_error = {
      type = "description",
      name = function()
        if not(data.customTriggerLogic) then
          return "";
        end
        local _, errorString = loadstring("return "..data.customTriggerLogic);
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 0.2,
      hidden = function()
        if not(data.disjunctive == "custom" and data.customTriggerLogic) then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..data.customTriggerLogic);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    activeTriggerMode = {
      type = "select",
      name = L["Dynamic information"],
      width = "double",
      order = 0.3,
      values = function()
        local vals = {};
        vals[WeakAuras.trigger_modes.first_active] = L["Dynamic information from first Active Trigger"];
        local numTriggers = data.additional_triggers and #data.additional_triggers or 0;
        for i=0,numTriggers do
          vals[i] = L["Dynamic information from Trigger %i"]:format(i + 1);
        end
        return vals;
      end,
      get = function()
        return data.activeTriggerMode or WeakAuras.trigger_modes.first_active;
      end,
      set = function(info, v)
        data.activeTriggerMode = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      hidden = function() return data.numTriggers <= 1 end
    },
    chooseTrigger = {
      type = "select",
      name = L["Choose Trigger"],
      order = 0.5,
      values = function()
        local ret = {[0] = L["Trigger %d"]:format(1)};
        if(data.controlledChildren) then
          for index=1,(data.numTriggers and data.numTriggers + 1 or 9) do
            local all, none, any = true, true, false;
            for _, childId in pairs(data.controlledChildren) do
              local childData = WeakAuras.GetData(childId);
              if(childData) then
                none = false;
                if(childData.additional_triggers and childData.additional_triggers[index]) then
                  any = true;
                else
                  all = false;
                end
              end
            end
            if not(none) then
              if(all) then
                ret[index] = L["Trigger %d"]:format(index + 1);
              elseif(any) then
                ret[index] = "|cFF777777"..L["Trigger %d"]:format(index + 1);
              end
            end
          end
        elseif(data.additional_triggers) then
          for index, trigger in pairs(data.additional_triggers) do
            ret[index] = L["Trigger %d"]:format(index + 1);
          end
        end
        return ret;
      end,
      get = function() return optionTriggerChoices[id]; end,
      set = function(info, v)
        if(v == 0 or (data.additional_triggers and data.additional_triggers[v])) then
          optionTriggerChoices[id] = v;

          WeakAuras.ReloadTriggerOptions(data);
        end
      end
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
              childData.additional_triggers = childData.additional_triggers or {};
              tinsert(childData.additional_triggers, {trigger = {}, untrigger = {}});
              childData.numTriggers = 1 + (childData.additional_triggers and #childData.additional_triggers or 0)
              optionTriggerChoices[childId] = #childData.additional_triggers;
              WeakAuras.ReloadTriggerOptions(childData);
            end
          end
        else
          data.additional_triggers = data.additional_triggers or {};
          tinsert(data.additional_triggers, {trigger = {}, untrigger = {}});
          data.numTriggers = 1 + (data.additional_triggers and #data.additional_triggers or 0)
          optionTriggerChoices[id] = #data.additional_triggers;
        end
        WeakAuras.ReloadTriggerOptions(data);
      end
    },
    triggerHeader = {
      type = "header",
      name = function(info)
        if(info == "default") then
          return L["Multiple Triggers"];
        else
          if(optionTriggerChoices[id] == 0) then
            return L["Trigger %d"]:format(1);
          else
            return L["Trigger %d"]:format(optionTriggerChoices[id] + 1);
          end
        end
      end,
      order = 2
    },
    applyTemplate = {
      type = "execute",
      name = L["Apply Template"],
      order = 2.5,
      func = function()
        WeakAuras.OpenTriggerTemplate(data);
      end,
      hidden = function()
        return GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") == 0
      end
    },
    deleteTriggerHalf = {
      type = "execute",
      name = L["Delete Trigger"],
      order = 3,
      func = deleteTrigger,
      hidden = function()
        return data.numTriggers == 1 or GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") == 0
      end
    },
    deleteTriggerSpace = {
      type = "execute",
      name = "",
      order = 3.1,
      image = function() return "", 0, 0 end,
      hidden = function()
        return data.numTriggers ~= 1 or GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") == 0
      end,
    },
    deleteTriggerFull = {
      type = "execute",
      name = L["Delete Trigger"],
      order = 3,
      width = "double",
      func = deleteTrigger,
      hidden = function() return data.numTriggers == 1 or GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0 end
    },
    typedesc = {
      type = "toggle",
      name = L["Type"],
      order = 5,
      disabled = true,
      get = function() return true end
    },
    type = {
      type = "select",
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
    event = {
      type = "select",
      name = function()
        if(trigger.type == "event") then
          return L["Event"];
        elseif(trigger.type == "status") then
          return L["Status"];
        end
      end,
      order = 7,
      width = "double",
      values = function()
        local type;
        if (data.controlledChildren) then
          type = getAll(data, {"trigger", "type"});
        else
          type = trigger.type;
        end
        if(type == "event") then
          return event_types;
        elseif(type == "status") then
          return status_types;
        end
      end,
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (trigger.type == "event" or trigger.type == "status"); end
    },
    subeventPrefix = {
      type = "select",
      name = L["Message Prefix"],
      order = 8,
      values = subevent_prefix_types,
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
    subeventSuffix = {
      type = "select",
      name = L["Message Suffix"],
      order = 9,
      values = subevent_suffix_types,
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log" and subevent_actual_prefix_types[trigger.subeventPrefix]); end
    },
    spacer_suffix = {
      type = "description",
      name = "",
      order = 9.1,
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
    custom_type = {
      type = "select",
      name = L["Event Type"],
      order = 7,
      width = "double",
      values = custom_trigger_types,
      hidden = function() return not (trigger.type == "custom") end
    },
    check = {
      type = "select",
      name = L["Check On..."],
      order = 8,
      values = check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check ~= "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    check2 = {
      type = "select",
      name = L["Check On..."],
      order = 8,
      width = "double",
      values = check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check == "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events = {
      type = "input",
      name = L["Event(s)"],
      desc = L["Custom trigger status tooltip"],
      order = 9,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check ~= "update") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events2 = {
      type = "input",
      name = L["Event(s)"],
      desc = L["Custom trigger event tooltip"],
      width = "double",
      order = 9,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.check ~= "update") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_trigger = {
      type = "input",
      name = L["Custom Trigger"],
      order = 10,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom") end,
      get = function() return trigger.custom end,
      set = function(info, v)
        trigger.custom = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_trigger_expand = {
      type = "execute",
      order = 10.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("custom"))
      end,
      hidden = function() return not (trigger.type == "custom") end,
    },
    custom_trigger_error = {
      type = "description",
      name = function()
        if not(trigger.custom) then
          return "";
        end
        local _, errorString = loadstring("return "..trigger.custom);
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 11,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom) then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..trigger.custom);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_hide = {
      type = "select",
      name = L["Hide"],
      order = 12,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      values = eventend_types,
      get = function() trigger.custom_hide = trigger.custom_hide or "timed"; return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_hide2 = {
      type = "select",
      name = L["Hide"],
      order = 12,
      width = "double",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide == "custom") end,
      values = eventend_types,
      get = function() return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    duration = {
      type = "input",
      name = L["Duration (s)"],
      order = 13,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end
    },
    custom_untrigger = {
      type = "input",
      name = L["Custom Untrigger"],
      order = 14,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom"))) end,
      get = function() return untrigger and untrigger.custom end,
      set = function(info, v)
        if(untrigger) then
          untrigger.custom = v;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_untrigger_expand = {
      type = "execute",
      order = 14.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToUntriggerPath("custom"))
      end,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom"))) end,
    },
    custom_untrigger_error = {
      type = "description",
      name = function()
        if not(untrigger and untrigger.custom) then
          return "";
        end
        local _, errorString = loadstring("return "..(untrigger and untrigger.custom or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 15,
      hidden = function()
        if not(trigger.type == "custom" and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom")) and untrigger and untrigger.custom) then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(untrigger and untrigger.custom or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_duration = {
      type = "input",
      name = L["Duration Info"],
      order = 16,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed")))
      end,
      get = function() return trigger.customDuration end,
      set = function(info, v)
        trigger.customDuration = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_duration_expand = {
      type = "execute",
      order = 16.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customDuration"))
      end,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed")))
      end,
    },
    custom_duration_error = {
      type = "description",
      name = function()
        if not(trigger.type == "custom"
          and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed"))
          and trigger.customDuration and trigger.customDuration ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customDuration or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 17,
      hidden = function()
        if not(trigger.type == "custom"
          and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed"))
          and trigger.customDuration and trigger.customDuration ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customDuration or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_name = {
      type = "input",
      name = L["Name Info"],
      order = 18,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customName end,
      set = function(info, v)
        trigger.customName = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_name_expand = {
      type = "execute",
      order = 18.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customName"))
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_name_error = {
      type = "description",
      name = function()
        if not(trigger.customName and trigger.customName ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customName or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 19,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customName and trigger.customName ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customName or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_icon = {
      type = "input",
      name = L["Icon Info"],
      order = 20,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customIcon end,
      set = function(info, v)
        trigger.customIcon = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_icon_expand = {
      type = "execute",
      order = 20.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customIcon"))
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_icon_error = {
      type = "description",
      name = function()
        if not(trigger.customIcon and trigger.customIcon ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customIcon or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 21,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customIcon and trigger.customIcon ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customIcon or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_texture = {
      type = "input",
      name = L["Texture Info"],
      order = 21.5,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customTexture end,
      set = function(info, v)
        trigger.customTexture = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_texture_expand = {
      type = "execute",
      order = 22,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customTexture"))
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_texture_error = {
      type = "description",
      name = function()
        if not(trigger.customTexture and trigger.custom_type ~= "stateupdate" and trigger.customTexture ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customTexture or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 22.5,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customTexture and trigger.customTexture ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customTexture or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_stacks = {
      type = "input",
      name = L["Stack Info"],
      order = 23,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customStacks end,
      set = function(info, v)
        trigger.customStacks = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_stacks_expand = {
      type = "execute",
      order = 23.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customStacks"))
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_stacks_error = {
      type = "description",
      name = function()
        if not(trigger.customStacks and trigger.custom_type ~= "stateupdate" and trigger.customStacks ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customStacks or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 24,
      hidden = function()
        if not(trigger.type == "custom" and trigger.customStacks and trigger.customStacks ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customStacks or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    }
  };

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

    removeFuncs(displayOptions[id]);

    if(optionTriggerChoices[id] >= 0 and getAll(data, {"trigger", "type"}) == "aura") then
      displayOptions[id].args.trigger.args = union(trigger_options, aura_options);
      removeFuncs(displayOptions[id].args.trigger);
      displayOptions[id].args.trigger.args.type.set = options_set;
    elseif(optionTriggerChoices[id] >= 0 and (getAll(data, {"trigger", "type"}) == "event" or getAll(data, {"trigger", "type"}) == "status")) then
      local event = getAll(data, {"trigger", "event"});
      local unevent = getAll(data, {"trigger", "unevent"});
      if(event and WeakAuras.event_prototypes[event]) then
        local trigger_options_created;
        if(event == "Combat Log") then
          local subeventPrefix = getAll(data, {"trigger", "subeventPrefix"});
          local subeventSuffix = getAll(data, {"trigger", "subeventSuffix"});
          if(subeventPrefix and subeventSuffix) then
            trigger_options_created = true;
            displayOptions[id].args.trigger.args = union(trigger_options, WeakAuras.ConstructOptions(WeakAuras.event_prototypes[event], data, 10, subeventPrefix, subeventSuffix, optionTriggerChoices[id], nil, unevent));
          end
        end

        if not(trigger_options_created) then
          displayOptions[id].args.trigger.args = union(trigger_options, WeakAuras.ConstructOptions(WeakAuras.event_prototypes[event], data, 10, nil, nil, optionTriggerChoices[id], nil, unevent));
        end
      else
        displayOptions[id].args.trigger.args = union(trigger_options, {});
        removeFuncs(displayOptions[id].args.trigger);
      end
      removeFuncs(displayOptions[id].args.trigger);
      replaceNameDescFuncs(displayOptions[id].args.trigger, data);
      replaceImageFuncs(displayOptions[id].args.trigger, data);
      replaceValuesFuncs(displayOptions[id].args.trigger, data);

      if(displayOptions[id].args.trigger.args.unevent) then
        displayOptions[id].args.trigger.args.unevent.set = options_set;
      end
      if(displayOptions[id].args.trigger.args.subeventPrefix) then
        displayOptions[id].args.trigger.args.subeventPrefix.set = function(info, v)
          if not(subevent_actual_prefix_types[v]) then
            data.trigger.subeventSuffix = "";
          end
          options_set(info, v);
        end
      end
      if(displayOptions[id].args.trigger.args.subeventSuffix) then
        displayOptions[id].args.trigger.args.subeventSuffix.set = options_set;
      end

      if(displayOptions[id].args.trigger.args.type) then
        displayOptions[id].args.trigger.args.type.set = options_set;
      end
      if(displayOptions[id].args.trigger.args.event) then
        displayOptions[id].args.trigger.args.event.set = options_set;
      end
    else
      displayOptions[id].args.trigger.args = trigger_options;
      removeFuncs(displayOptions[id].args.trigger);
    end

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
    displayOptions[id].args.trigger.args.type.set = options_set;
    displayOptions[id].args.trigger.args.event.set = options_set;

    replaceNameDescFuncs(displayOptions[id], data);
    replaceImageFuncs(displayOptions[id], data);
    replaceValuesFuncs(displayOptions[id], data);

    local regionOption;
    if (regionOptions[data.regionType]) then
      regionOption = regionOptions[data.regionType].create(id, data);
    else
      regionOption = {
        unsupported = {
          type = "description",
          name = L["This region of type \"%s\" is not supported."]:format(data.regionType)
        }
      };
    end
    displayOptions[id].args.group = {
      type = "group",
      name = L["Group"],
      order = 0,
      get = function(info)
        if(info.type == "color") then
          data[info[#info]] = data[info[#info]] or {};
          local c = data[info[#info]];
          return c[1], c[2], c[3], c[4];
        else
          return data[info[#info]];
        end
      end,
      set = function(info, v, g, b, a)
        if(info.type == "color") then
          data[info[#info]] = data[info[#info]] or {};
          local c = data[info[#info]];
          c[1], c[2], c[3], c[4] = v, g, b, a;
        elseif(info.type == "toggle") then
          data[info[#info]] = v;
        else
          data[info[#info]] = (v ~= "" and v) or nil;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.ResetMoverSizer();
      end,
      hidden = function() return false end,
      disabled = function() return false end,
      args = regionOption
    };

    data.load.use_class = getAll(data, {"load", "use_class"});
    local single_class = getAll(data, {"load", "class"});
    data.load.class = {}
    data.load.class.single = single_class;

    displayOptions[id].args.load.args = WeakAuras.ConstructOptions(WeakAuras.load_prototype, data, 10, nil, nil, optionTriggerChoices[id], "load");
    removeFuncs(displayOptions[id].args.load);
    replaceNameDescFuncs(displayOptions[id].args.load, data);
    replaceImageFuncs(displayOptions[id].args.load, data);
    replaceValuesFuncs(displayOptions[id].args.load, data);

    WeakAuras.ReloadGroupRegionOptions(data);
  else -- One aura selected
    local function options_set(info, v)
      trigger[info[#info]] = v;
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ReloadTriggerOptions(data);
    end
    local triggernum = optionTriggerChoices[id];
    if(trigger.type == "aura") then
      displayOptions[id].args.trigger.args = union(trigger_options, aura_options);
    elseif(trigger.type == "event" or trigger.type == "status") then
      if(WeakAuras.event_prototypes[trigger.event]) then
        if(trigger.event == "Combat Log") then
          displayOptions[id].args.trigger.args = union(trigger_options, WeakAuras.ConstructOptions(WeakAuras.event_prototypes[trigger.event], data, 10, (trigger.subeventPrefix or ""), (trigger.subeventSuffix or ""), optionTriggerChoices[id]));
        else
          displayOptions[id].args.trigger.args = union(trigger_options, WeakAuras.ConstructOptions(WeakAuras.event_prototypes[trigger.event], data, 10, nil, nil, optionTriggerChoices[id]));
        end
        if(displayOptions[id].args.trigger.args.unevent) then
          displayOptions[id].args.trigger.args.unevent.set = options_set;
        end
        if(displayOptions[id].args.trigger.args.subeventPrefix) then
          displayOptions[id].args.trigger.args.subeventPrefix.set = function(info, v)
            if not(subevent_actual_prefix_types[v]) then
              trigger.subeventSuffix = "";
            end
            options_set(info, v);
          end
        end
        if(displayOptions[id].args.trigger.args.subeventSuffix) then
          displayOptions[id].args.trigger.args.subeventSuffix.set = options_set;
        end
      else
        print("No prototype for", trigger.event);
        displayOptions[id].args.trigger.args = union(trigger_options, {});
      end
    else
      displayOptions[id].args.trigger.args = union(trigger_options, {});
    end

    displayOptions[id].args.load.args = WeakAuras.ConstructOptions(WeakAuras.load_prototype, data, 10, nil, nil, optionTriggerChoices[id], "load");

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

    displayOptions[id].args.trigger.get = function(info) return trigger[info[#info]] end;
    displayOptions[id].args.trigger.set = function(info, v)
      trigger[info[#info]] = (v ~= "" and v) or nil;
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
    end;
  end
  if(type(id) ~= "string") then
    displayOptions[id].args.group = nil;
  end
end

function WeakAuras.ReloadGroupRegionOptions(data)
  local regionType;
  local first = true;
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      if(first) then
        regionType = childData.regionType;
        first = false;
      else
        if(childData.regionType ~= regionType) then
          regionType = false;
        end
      end
    end
  end

  local id = data.id;
  WeakAuras.EnsureOptions(id);
  local options = displayOptions[id];
  local regionOption;
  if(regionType) then
    if(regionOptions[regionType]) then
      regionOption = regionOptions[regionType].create(id, data);
    else
      regionOption = {
        unsupported = {
          type = "description",
          name = L["This region of type \"%s\" is not supported."]:format(data.regionType)
        }
      };
    end
  end
  if(regionOption) then
    if(data.regionType == "dynamicgroup") then
      regionOption.selfPoint = nil;
      regionOption.anchorPoint = nil;
      regionOption.anchorPointGroup = nil;
      regionOption.xOffset1 = nil;
      regionOption.xOffset2 = nil;
      regionOption.xOffset3 = nil;
      regionOption.yOffset1 = nil;
      regionOption.yOffset2 = nil;
      regionOption.yOffset3 = nil;
    end
    replaceNameDescFuncs(regionOption, data);
    replaceImageFuncs(regionOption, data);
    replaceValuesFuncs(regionOption, data);
  else
    regionOption = {
      invalid = {
        type = "description",
        name = L["The children of this group have different display types, so their display options cannot be set as a group."],
        fontSize = "large"
      }
    };
  end
  removeFuncs(regionOption);
  options.args.region.args = regionOption;
end

function WeakAuras.AddPositionOptions(input, id, data)
  local function IsParentDynamicGroup()
    return data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup";
  end

  local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
  local positionOptions = {
    width = {
      type = "range",
      name = L["Width"],
      order = 60,
      min = 1,
      softMax = screenWidth,
      bigStep = 1
    },
    height = {
      type = "range",
      name = L["Height"],
      order = 65,
      min = 1,
      softMax = screenHeight,
      bigStep = 1
    },
    selfPoint = {
      type = "select",
      name = L["Anchor"],
      order = 70,
      hidden = IsParentDynamicGroup,
      values = point_types
    },
    anchorFrameType = {
      type = "select",
      name = L["anchored to"],
      order = 72,
      hidden = IsParentDynamicGroup,
      values = WeakAuras.anchor_frame_types
    },
    -- Input field to select frame to anchor on
    anchorFrameFrame = {
      type = "input",
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
      name = function()
        if (data.anchorFrameType == "SCREEN") then
          return L["to screen's"]
        elseif (data.anchorFrameType == "PRD") then
          return L["to Personal Ressource Display's"];
        elseif (data.anchorFrameType == "SELECTFRAME") then
          return L["frame's"];
        end
      end,
      order = 75,
      hidden = function()
        if (data.parent) then
          if (IsParentDynamicGroup()) then
            return true;
          end
          return data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE";
        else
          return data.anchorFrameType == "MOUSE";
        end
      end,
      values = point_types
    },
    anchorPointGroup = {
      type = "select",
      name = function() return L["to group's"] end,
      order = 75,
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
      name = L["Set Parent to Anchor"],
      order = 77,
      get = function()
        return data.anchorFrameParent or data.anchorFrameParent == nil;
      end,
      hidden = function()
        return (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE");
      end,
    },
    frameStrata = {
      type = "select",
      name = L["Frame Strata"],
      order = 78,
      values = WeakAuras.frame_strata_types
    },
    anchorFrameSpace = {
      type = "execute",
      name = "",
      order = 79,
      image = function() return "", 0, 0 end,
      hidden = function()
        return not (data.anchorFrameType ~= "SCREEN");
      end
    },
    -- IsParentDynamicGroup => none
    -- InGroup/Attached to mouse/PRD/SELECTFRAME => -screen -- +screen
    -- Attached to Screen => depends on anchorPoint
    --   LEFT/BOTTOM => 0 -- +screen
    --   CENTER => -screen/2 -- +screen / 2
    --   RIGHT/TOP => -screen -- +screen
    xOffset1 = {
      type = "range",
      name = L["X Offset"],
      order = 80,
      softMin = 0,
      softMax = screenWidth,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return not data.anchorPoint:find("LEFT")
      end,
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
    xOffset2 = {
      type = "range",
      name = L["X Offset"],
      order = 80,
      softMin = ((-1/2) * screenWidth),
      softMax = ((1/2) * screenWidth),
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return (data.anchorPoint:find("LEFT") or data.anchorPoint:find("RIGHT"));
      end,
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
    xOffset3 = {
      type = "range",
      name = L["X Offset"],
      order = 80,
      softMin = (-1 * screenWidth),
      softMax = 0,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return not data.anchorPoint:find("RIGHT");
      end,
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
    xOffset4 = {
      type = "range",
      name = L["X Offset"],
      order = 80,
      softMin = (-1 * screenWidth),
      softMax = screenWidth,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return false;
        end
        return true;
      end,
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
    yOffset1 = {
      type = "range",
      name = L["Y Offset"],
      order = 85,
      softMin = 0,
      softMax = screenHeight,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return not data.anchorPoint:find("BOTTOM");
      end,
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
    yOffset2 = {
      type = "range",
      name = L["Y Offset"],
      order = 85,
      softMin = ((-1/2) * screenHeight),
      softMax = ((1/2) * screenHeight),
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return data.anchorPoint:find("BOTTOM") or data.anchorPoint:find("TOP");
      end,
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
    yOffset3 = {
      type = "range",
      name = L["Y Offset"],
      order = 85,
      softMin = (-1 * screenHeight),
      softMax = 0,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        return not data.anchorPoint:find("TOP");
      end,
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
    yOffset4 = {
      type = "range",
      name = L["Y Offset"],
      order = 85,
      softMin = (-1 * screenHeight),
      softMax = screenHeight,
      bigStep = 10,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        if (data.parent or data.anchorFrameType ~= "SCREEN") then
          return false;
        end
        return true;
      end,
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
  };

  return union(input, positionOptions);
end

function WeakAuras.AddBorderOptions(input, id, data)
  local borderOptions = {
    border = {
      type = "toggle",
      name = L["Border"],
      order = 46.05
    },
    borderEdge = {
      type = "select",
      dialogControl = "LSM30_Border",
      name = L["Border Style"],
      order = 46.1,
      values = AceGUIWidgetLSMlists.border,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    borderBackdrop = {
      type = "select",
      dialogControl = "LSM30_Background",
      name = L["Backdrop Style"],
      order = 46.2,
      values = AceGUIWidgetLSMlists.background,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    borderOffset = {
      type = "range",
      name = L["Border Offset"],
      order = 46.3,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    borderSize = {
      type = "range",
      name = L["Border Size"],
      order = 46.4,
      softMin = 1,
      softMax = 64,
      bigStep = 1,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    borderInset = {
      type = "range",
      name = L["Border Inset"],
      order = 46.5,
      softMin = 1,
      softMax = 32,
      bigStep = 1,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    borderColor = {
      type = "color",
      name = L["Border Color"],
      hasAlpha = true,
      order = 46.6,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
    backdropColor = {
      type = "color",
      name = L["Backdrop Color"],
      hasAlpha = true,
      order = 46.8,
      disabled = function() return not data.border end,
      hidden = function() return not data.border end,
    },
  }

  return union(input, borderOptions);
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

  WeakAuras.Convert(data, newType);
  displayButtons[id]:SetViewRegion(WeakAuras.regions[id].region);
  displayButtons[id]:Initialize();
  displayOptions[id] = nil;
  WeakAuras.AddOption(id, data);
  frame:FillOptions(displayOptions[id]);
  WeakAuras.UpdateDisplayButton(data);
  frame.mover.moving.region = WeakAuras.regions[id].region;
  WeakAuras.ResetMoverSizer();
end

function WeakAuras.NewDisplayButton(data)
  local id = data.id;
  WeakAuras.ScanForLoads();
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
      print("No data for", id);
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

function WeakAuras.PickDisplay(id)
  frame:PickDisplay(id);
end

function WeakAuras.PickAndEditDisplay(id)
  frame:PickDisplay(id);
  displayButtons[id].callbacks.OnRenameClick();
end

function WeakAuras.PickDisplayMultiple(id)
  frame:PickDisplayMultiple(id);
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
      print("Error creating button for", id);
    end
  end
end

function WeakAuras.SetCopying(data)
  for id, button in pairs(displayButtons) do
    button:SetCopying(data);
  end
end

function WeakAuras.SetGrouping(data)
  for id, button in pairs(displayButtons) do
    button:SetGrouping(data);
  end
end

function WeakAuras.SetDragging(data, drop)
  WeakAuras_DropDownMenu:Hide()
  for id, button in pairs(displayButtons) do
    button:SetDragging(data, drop)
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

    return thumbnail;
  end
end

function WeakAuras.OpenTexturePicker(data, field, textures, stopMotion)
  frame.texturePicker:Open(data, field, textures, stopMotion);
end

function WeakAuras.OpenIconPicker(data, field)
  frame.iconPicker:Open(data, field);
end

function WeakAuras.OpenModelPicker(data, field)
  if not(IsAddOnLoaded("WeakAurasModelPaths")) then
    local loaded, reason = LoadAddOn("WeakAurasModelPaths");
    if not(loaded) then
      print("|cff9900FF".."WeakAurasModelPaths"..FONT_COLOR_CODE_CLOSE.." could not be loaded: "..RED_FONT_COLOR_CODE.._G["ADDON_"..reason]);
      WeakAuras.ModelPaths = {};
    end
    frame.modelPicker.modelTree:SetTree(WeakAuras.ModelPaths);
  end
  frame.modelPicker:Open(data, field);
end

function WeakAuras.OpenCodeReview(data)
  frame.codereview:Open(data);
end

function WeakAuras.CloseCodeReview(data)
  frame.codereview:Close();
end

function WeakAuras.OpenTriggerTemplate(data)
  if not(IsAddOnLoaded("WeakAurasTemplates")) then
    local loaded, reason = LoadAddOn("WeakAurasTemplates");
    if not(loaded) then
      print("|cff9900FF".."WeakAurasTemplates"..FONT_COLOR_CODE_CLOSE.." could not be loaded: "..RED_FONT_COLOR_CODE.._G["ADDON_"..reason]);
      return;
    end
    frame.newView = WeakAuras.CreateTemplateView(frame);
  end
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
        local new_id = data.id.." Group";
        local num = 2;
        while(WeakAuras.GetData(new_id)) do
          new_id = "New "..num;
          num = num + 1;
        end

        local parentData = {
          id = new_id,
          regionType = "dynamicgroup",
          trigger = {},
          load = {}
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

function WeakAuras.ShowSpellIDDialog(trigger, id)
  if not(odb.preventSpellIDDialog) then
    StaticPopupDialogs["WEAKAURAS_SPELLID_CHECK"] = {
      text = L["Spell ID dialog"],
      button1 = L["Yes"],
      button2 = L["No"],
      button3 = L["Never"],
      OnAccept = function()
        trigger.fullscan = true;
        trigger.use_spellId = true;
        trigger.spellId = id;

        AceConfigDialog:Open("WeakAuras", frame.container);
      end,
      OnCancel = function()
      -- do nothing
      end,
      OnAlt = function()
        odb.preventSpellIDDialog = true
      end,
      hideOnEscape = true,
      whileDead = true,
      timeout = 0,
      preferredindex = STATICPOPUP_NUMDIALOGS
    };

    StaticPopup_Show("WEAKAURAS_SPELLID_CHECK");
  end
end
