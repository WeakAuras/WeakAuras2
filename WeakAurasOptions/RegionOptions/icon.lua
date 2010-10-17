local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L

local function createOptions(id, data)
  local options = {
    cooldown = {
      type = "toggle",
      name = L["Cooldown"],
      order = 4,
      disabled = function() return not WeakAuras.CanHaveDuration(data); end,
      get = function() return WeakAuras.CanHaveDuration(data) and data.cooldown; end
    },
    auto = {
      type = "toggle",
      name = L["Automatic Icon"],
      order = 8,
      disabled = function() return not WeakAuras.CanHaveAuto(data); end,
      get = function() return WeakAuras.CanHaveAuto(data) and data.auto; end
    },
    displayIcon = {
      type = "input",
      name = L["Display Icon"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
      disabled = function() return not data.icon end,
      order = 12,
      get = function()
        if(data.displayIcon) then
          return data.displayIcon:sub(17);
        else
          return nil;
        end
      end,
      set = function(info, v)
        data.displayIcon = "Interface\\Icons\\"..v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
      end
    },
    chooseIcon = {
      type = "execute",
      name = L["Choose"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
      disabled = function() return not data.icon end,
      order = 18,
      func = function() WeakAuras.OpenIconPick(data, "displayIcon"); end
    },
    inverse = {
      type = "toggle",
      name = L["Inverse"],
      order = 6,
      disabled = function() return not (WeakAuras.CanHaveDuration(data) and data.cooldown); end,
      get = function() return data.inverse and WeakAuras.CanHaveDuration(data) and data.cooldown; end
    },
    textColor = {
      type = "color",
      name = L["Color"],
      hasAlpha = true,
      order = 42
    },
    stacksPoint = {
      type = "select",
      name = L["Stack Count Position"],
      order = 41,
      values = WeakAuras.point_types
    },
    alpha = {
      type = "range",
      name = L["Alpha"],
      order = 7,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    font = {
      type = "select",
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 45,
      values = AceGUIWidgetLSMlists.font
    },
    fontSize = {
      type = "range",
      name = L["Size"],
      order = 47,
      min = 6,
      max = 24,
      step = 1
    },
    zoom = {
      type = "range",
      name = L["Zoom"],
      order = 48,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    stickyDuration = {
      type = "toggle",
      name = L["Sticky Duration"],
      desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
      order = 49
    },
    spacer = {
      type = "header",
      name = "",
      order = 50
    }
  };
  options = WeakAuras.AddPositionOptions(options, id, data);
  
  return options;
end

local function createThumbnail(parent, fullCreate)
  local icon = parent:CreateTexture();
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
  
  return icon;
end

local function modifyThumbnail(parent, icon, data, fullModify)
  icon:SetAlpha(data.alpha);
  local texWidth = 0.25 * data.zoom;
  icon:SetTexCoord(texWidth, 1 - texWidth, texWidth, 1 - texWidth);
  
  function icon:SetIcon(path)
    local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
    if not(success) then
      icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    end
  end
end

WeakAuras.RegisterRegionOptions("icon", createOptions, "Interface\\ICONS\\Temp.blp", L["Icon"], createThumbnail, modifyThumbnail, L["Shows a spell icon with an optional a cooldown overlay"]);