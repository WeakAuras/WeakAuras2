if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- Create region options table
local function createOptions(id, data)
  -- Region options
  local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
  local options = {
    __title = L["Progress Bar Settings"],
    __order = 1,
    texture = {
      type = "select",
      dialogControl = "LSM30_Statusbar",
      order = 1,
      width = WeakAuras.doubleWidth,
      name = L["Bar Texture"],
      values = AceGUIWidgetLSMlists.statusbar
    },
    orientation = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Orientation"],
      order = 25,
      values = WeakAuras.orientation_types,
      set = function(info, v)
        if(
          (
          data.orientation:find("INVERSE")
          and not v:find("INVERSE")
          )
          or (
          v:find("INVERSE")
          and not data.orientation:find("INVERSE")
          )
          ) then
          data.icon_side = data.icon_side == "LEFT" and "RIGHT" or "LEFT";
        end

        if(
          (
          data.orientation:find("HORIZONTAL")
          and v:find("VERTICAL")
          )
          or (
          data.orientation:find("VERTICAL")
          and v:find("HORIZONTAL")
          )
          ) then
          local temp = data.width;
          data.width = data.height;
          data.height = temp;
          data.icon_side = data.icon_side == "LEFT" and "RIGHT" or "LEFT";

          if(data.rotateText == "LEFT" or data.rotateText == "RIGHT") then
            data.rotateText = "NONE";
          elseif(data.rotateText == "NONE") then
            data.rotateText = "LEFT"
          end
        end

        data.orientation = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    inverse = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Inverse"],
      order = 35
    },
    smoothProgress = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Smooth Progress"],
      desc = L["Animates progress changes"],
      order = 37
    },
    useTooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip on Mouseover"],
      hidden = function() return not WeakAuras.CanHaveTooltip(data) end,
      order = 38
    },
    bar_header = {
      type = "header",
      name = L["Bar Color Settings"],
      order = 39
    },
    barColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Bar Color"],
      hasAlpha = true,
      order = 39.1
    },
    backgroundColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Background Color"],
      hasAlpha = true,
      order = 39.2
    },
    alpha = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Bar Alpha"],
      order = 39.3,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    icon_header = {
      type = "header",
      name = L["Icon Settings"],
      order = 40.1
    },
    icon = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Icon"],
      order = 40.2,
    },
    auto = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Auto"],
      desc = L["Choose whether the displayed icon is automatic or defined manually"],
      order = 40.3,
      disabled = function() return not WeakAuras.CanHaveAuto(data); end,
      get = function() return WeakAuras.CanHaveAuto(data) and data.auto end,
      hidden = function() return not data.icon end,
    },
    displayIcon = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Display Icon"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto or not data.icon; end,
      disabled = function() return not data.icon end,
      order = 40.4,
      get = function()
        return data.displayIcon and tostring(data.displayIcon) or "";
      end,
      set = function(info, v)
        data.displayIcon = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
      end
    },
    chooseIcon = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Choose"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto or not data.icon; end,
      disabled = function() return not data.icon end,
      order = 40.5,
      func = function() WeakAuras.OpenIconPicker(data, "displayIcon"); end
    },
    icon_side = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Icon Position"],
      values = WeakAuras.icon_side_types,
      hidden = function() return data.orientation:find("VERTICAL") or not data.icon end,
      order = 40.6,
    },
    icon_side2 = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Icon Position"],
      values = WeakAuras.rotated_icon_side_types,
      hidden = function() return data.orientation:find("HORIZONTAL") or not data.icon end,
      order = 40.7,
      get = function()
        return data.icon_side;
      end,
      set = function(info, v)
        data.icon_side = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
      end
    },
    desaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 40.8,
      hidden = function() return not data.icon end,
    },
    icon_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 40.9,
      hidden = function() return not data.icon end,
    },
    zoom = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Zoom"],
      order = 40.91,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = function() return not data.icon end,
    },
    spark_header = {
      type = "header",
      name = L["Spark Settings"],
      order = 42
    },
    spark = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Spark"],
      order = 43
    },
    sparkTexture = {
      type = "input",
      name = L["Spark Texture"],
      order = 44,
      width = WeakAuras.doubleWidth,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkDesaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 44.1,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    spaceSpark = {
      type = "execute",
      name = "",
      width = WeakAuras.halfWidth,
      order = 44.2,
      image = function() return "", 0, 0 end,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkChooseTexture = {
      type = "execute",
      name = L["Choose"],
      width = WeakAuras.halfWidth,
      order = 44.3,
      func = function()
        WeakAuras.OpenTexturePicker(data, "sparkTexture", WeakAuras.texture_types);
      end,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 44.4,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkBlendMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 44.5,
      values = WeakAuras.blend_types,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkWidth = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Width"],
      order = 44.6,
      min = 1,
      softMax = screenWidth,
      bigStep = 1,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkHeight = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Height"],
      order = 44.7,
      min = 1,
      softMax = screenHeight,
      bigStep = 1,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkOffsetX = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["X Offset"],
      order = 44.8,
      min = -screenWidth,
      max = screenWidth,
      bigStep = 1,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkOffsetY = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Y Offset"],
      order = 44.9,
      min = -screenHeight,
      max = screenHeight,
      bigStep = 1,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkRotationMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = WeakAuras.spark_rotation_types,
      name = L["Rotation Mode"],
      order = 45,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkRotation = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      min = 0,
      max = 360,
      step = 90,
      order = 45.1,
      disabled = function() return not data.spark or data.sparkRotationMode == "AUTO" end,
      hidden = function() return not data.spark or data.sparkRotationMode == "AUTO" end,
    },
    sparkMirror = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Mirror"],
      order = 45.2,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    sparkHidden = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = WeakAuras.spark_hide_types,
      name = L["Hide on"],
      order = 45.3,
      disabled = function() return not data.spark end,
      hidden = function() return not data.spark end,
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  options = WeakAuras.regionPrototype.AddAdjustedDurationOptions(options, data, 36.5);

  local overlayInfo = WeakAuras.GetOverlayInfo(data);
  if (overlayInfo and next(overlayInfo)) then
    options["overlayheader"] = {
      type = "header",
      name = L["Overlays"],
      order = 58
    }
    local index = 0.01
    for id, display in ipairs(overlayInfo) do
      options["overlaycolor" .. id] = {
        type = "color",
        width = WeakAuras.normalWidth,
        name = string.format(L["%s Color"], display),
        hasAlpha = true,
        order = 58 + index,
        get = function()
          if (data.overlays and data.overlays[id]) then
            return unpack(data.overlays[id]);
          end
          return 1, 1, 1, 1;
        end,
        set = function(info, r, g, b, a)
          if (not data.overlays) then
            data.overlays = {};
          end
          data.overlays[id] = { r, g, b, a};
          WeakAuras.Add(data);
        end
      }
      index = index + 0.01
    end

    options["overlayclip"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Clip Overlays"],
      order = 58 + index;
    }

  end

  return {
    aurabar = options,
    position = WeakAuras.commonOptions.PositionOptions(id, data),
  };
end

-- Create preview thumbnail
local function createThumbnail()
  -- Preview frame
  local borderframe = CreateFrame("FRAME", nil, UIParent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  -- Preview border
  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  -- Main region
  local region = CreateFrame("FRAME", nil, borderframe);
  borderframe.region = region;
  region:SetWidth(32);
  region:SetHeight(32);

  -- Status-bar frame
  local bar = CreateFrame("FRAME", nil, region);
  borderframe.bar = bar;

  -- Fake status-bar
  local texture = bar:CreateTexture(nil, "OVERLAY");
  borderframe.texture = texture;

  -- Fake icon
  local icon = region:CreateTexture();
  borderframe.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  -- Return preview
  return borderframe;
end

-- Modify preview thumbnail
local function modifyThumbnail(parent, borderframe, data, fullModify, width, height)
  -- Localize
  local region, bar, texture, icon = borderframe.region, borderframe.bar, borderframe.texture, borderframe.icon;

  borderframe:SetParent(parent)

  -- Default size
  width  = width or 26;
  height = height or 15;

  -- Fake orientation (main region)
  if(data.orientation:find("HORIZONTAL")) then
    region:SetWidth(width);
    region:SetHeight(height);
    region:ClearAllPoints();
    if(data.orientation == "HORIZONTAL_INVERSE") then
      region:SetPoint("RIGHT", borderframe, "RIGHT", -2, 0);
    else
      region:SetPoint("LEFT", borderframe, "LEFT", 2, 0);
    end
  else
    region:SetWidth(height);
    region:SetHeight(width);
    region:ClearAllPoints();
    if(data.orientation == "VERTICAL_INVERSE") then
      region:SetPoint("TOP", borderframe, "TOP", 0, -2);
    else
      region:SetPoint("BOTTOM", borderframe, "BOTTOM", 0, 2);
    end
  end

  -- Fake status-bar style
  texture:SetTexture(SharedMedia:Fetch("statusbar", data.texture));
  texture:SetVertexColor(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);

  -- Fake icon size
  local iconsize = height;
  icon:SetWidth(iconsize);
  icon:SetHeight(iconsize);

  -- Fake layout variables
  local percent, length;
  if(data.icon) then
    length = width - height;
    percent = 1 - (width / 100);
  else
    length = width;
    percent = 1 - (width / 100);
  end

  -- Reset region members
  icon:ClearAllPoints();
  bar:ClearAllPoints();
  texture:ClearAllPoints();

  -- Fake orientation (region members)
  if(data.orientation == "HORIZONTAL_INVERSE") then
    icon:SetPoint("LEFT", region, "LEFT");
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    if(data.icon) then
      bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
    else
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
    texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
    texture:SetTexCoord(1, 0, 1, 1, percent, 0, percent, 1);
    texture:SetWidth(length);
  elseif(data.orientation == "HORIZONTAL") then
    icon:SetPoint("RIGHT", region, "RIGHT");
    bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
    if(data.icon) then
      bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
    else
      bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
    end
    texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
    texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
    texture:SetTexCoord(percent, 0, percent, 1, 1, 0, 1, 1);
    texture:SetWidth(length);
  elseif(data.orientation == "VERTICAL_INVERSE") then
    icon:SetPoint("BOTTOM", region, "BOTTOM");
    bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    if(data.icon) then
      bar:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT");
    else
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    end
    texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
    texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
    texture:SetTexCoord(percent, 0, 1, 0, percent, 1, 1, 1);
    texture:SetHeight(length);
  elseif(data.orientation == "VERTICAL") then
    icon:SetPoint("TOP", region, "TOP");
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    if(data.icon) then
      bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
    else
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
    texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
    texture:SetTexCoord(1, 0, percent, 0, 1, 1, percent, 1);
    texture:SetHeight(length);
  end

  -- Fake icon (code)
  if(data.icon) then
    function borderframe:SetIcon(path)
      local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
      if not(success) then
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
      end
    end

    icon:Show();
  else
    icon:Hide();
  end
end

-- Create "new region" preview
local function createIcon()
  -- Default data
  local data = {
    icon = true,
    auto = true,
    texture = "Runes",
    orientation = "HORIZONTAL",
    alpha = 1.0,
    barColor = {1, 0, 0, 1}
  };

  -- Create and configure thumbnail
  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail, data, nil, 32, 18);
  thumbnail:SetIcon("Interface\\Icons\\INV_Sword_62");

  -- Return thumbnail
  return thumbnail;
end

local templates = {
  {
    title = L["Horizontal Bar"],
    data = {
      width = 200,
      height = 30,
      barColor = { 0, 1, 0, 1},
      inverse = true,
      smoothProgress = true,
    }
  },
  {
    title = L["Vertical Bar"],
    data = {
      width = 30,
      height = 200,
      barColor = { 0, 1, 0, 1},
      rotateText = "LEFT",
      orientation = "VERTICAL_INVERSE",
      inverse = true,
      smoothProgress = true,
    }
  },
}

local anchorPoints = {
  BOTTOMLEFT = {
    display = { L["Bar"], L["Bottom Left"] },
    type = "point"
  },
  BOTTOM = {
    display = { L["Bar"], L["Bottom"] },
    type = "point"
  },
  BOTTOMRIGHT = {
    display = { L["Bar"], L["Bottom Right"] },
    type = "point"
  },
  RIGHT = {
    display = { L["Bar"], L["Right"] },
    type = "point"
  },
  TOPRIGHT = {
    display = { L["Bar"], L["Top Right"] },
    type = "point"
  },
  TOP = {
    display = { L["Bar"], L["Top"] },
    type = "point"
  },
  TOPLEFT = {
    display = { L["Bar"], L["Top Left"] },
    type = "point"
  },
  LEFT = {
    display = { L["Bar"], L["Left"] },
    type = "point"
  },
  CENTER = {
    display = { L["Bar"], L["Center"] },
    type = "point"
  },

  INNER_BOTTOMLEFT = {
    display = { L["Bar Inner"], L["Bottom Left"] },
    type = "point"
  },
  INNER_BOTTOM = {
    display = { L["Bar Inner"], L["Bottom"] },
    type = "point"
  },
  INNER_BOTTOMRIGHT = {
    display = { L["Bar Inner"], L["Bottom Right"] },
    type = "point"
  },
  INNER_RIGHT = {
    display = { L["Bar Inner"], L["Right"] },
    type = "point"
  },
  INNER_TOPRIGHT = {
    display = { L["Bar Inner"], L["Top Right"] },
    type = "point"
  },
  INNER_TOP = {
    display = { L["Bar Inner"], L["Top"] },
    type = "point"
  },
  INNER_TOPLEFT = {
    display = { L["Bar Inner"], L["Top Left"] },
    type = "point"
  },
  INNER_LEFT = {
    display = { L["Bar Inner"], L["Left"] },
    type = "point"
  },
  INNER_CENTER = {
    display = { L["Bar Inner"], L["Center"] },
    type = "point"
  },

  ICON_BOTTOMLEFT = {
    display = { L["Icon"], L["Bottom Left"] },
    type = "point"
  },
  ICON_BOTTOM = {
    display = { L["Icon"], L["Bottom"] },
    type = "point"
  },
  ICON_BOTTOMRIGHT = {
    display = { L["Icon"], L["Bottom Right"] },
    type = "point"
  },
  ICON_RIGHT = {
    display = { L["Icon"], L["Right"] },
    type = "point"
  },
  ICON_TOPRIGHT = {
    display = { L["Icon"], L["Top Right"] },
    type = "point"
  },
  ICON_TOP = {
    display = { L["Icon"], L["Top"] },
    type = "point"
  },
  ICON_TOPLEFT = {
    display = { L["Icon"], L["Top Left"] },
    type = "point"
  },
  ICON_LEFT = {
    display = { L["Icon"], L["Left"] },
    type = "point"
  },
  ICON_CENTER = {
    display = { L["Icon"], L["Center"] },
    type = "point"
  },

  SPARK = {
    display = L["Spark"],
    type = "point"
  },
  ALL = {
    display = L["Whole Area"],
    type = "area"
  },
}

local function GetAnchors(data)
  return anchorPoints;
end

local function subCreateOptions(parentData, data, index, subIndex)
  local order = 9
  local options = {
    __title = L["Foreground"],
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "aurabar_bar")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "aurabar_bar")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id, parentData)
      end
    end,
    __nooptions = true
  }
  return options
end

-- Register new region type options with WeakAuras
WeakAuras.RegisterRegionOptions("aurabar", createOptions, createIcon, L["Progress Bar"], createThumbnail, modifyThumbnail, L["Shows a progress bar with name, timer, and icon"], templates, GetAnchors);

WeakAuras.RegisterSubRegionOptions("aurabar_bar", subCreateOptions, L["Foreground"]);
