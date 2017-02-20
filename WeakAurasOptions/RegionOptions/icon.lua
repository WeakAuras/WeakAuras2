local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- GLOBALS: WeakAuras UIParent AceGUIWidgetLSMlists

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
            order = 12,
            get = function()
                return data.displayIcon and tostring(data.displayIcon) or "";
            end,
            set = function(info, v)
                data.displayIcon = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
            end
        },
        chooseIcon = {
            type = "execute",
            name = L["Choose"],
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            order = 18,
            func = function() WeakAuras.OpenIconPicker(data, "displayIcon"); end
        },

        desaturate = {
            type = "toggle",
            name = L["Desaturate"],
            order = 18.5,
        },
        inverse = {
            type = "toggle",
            name = L["Inverse"],
            order = 6,
            disabled = function() return not (WeakAuras.CanHaveDuration(data) and data.cooldown); end,
            get = function() return data.inverse and WeakAuras.CanHaveDuration(data) and data.cooldown; end
        },
        displayStacks = {
            type = "input",
            name = L["Text"],
            desc = function()
                 local ret = L["Dynamic text tooltip"];
                 ret = ret .. WeakAuras.GetAdditionalProperties(data);
                 return ret
            end,
            order = 40
        },
        textColor = {
            type = "color",
            name = L["Color"],
            hasAlpha = true,
            order = 42
        },
        stacksPoint = {
            type = "select",
            name = L["Text Position"],
            order = 41,
            values = WeakAuras.point_types
        },
        customTextUpdate = {
            type = "select",
            width = "double",
            hidden = function() return not data.displayStacks:find("%%c"); end,
            name = L["Update Custom Text On..."],
            values = WeakAuras.text_check_types,
            order = 41.1
        },
        customText = {
            type = "input",
            width = "normal",
            hidden = function()
                return not data.displayStacks:find("%%c")
            end,
            multiline = true,
            name = L["Custom Function"],
            order = 41.2
        },
        customText_expand = {
            type = "execute",
            order = 41.2,
            name = L["Expand Text Editor"],
            func = function()
                WeakAuras.OpenTextEditor(data, {"customText"})
            end,
            hidden = function()
                return not data.displayStacks:find("%%c")
            end,
        },
        stacksContainment = {
            type = "select",
            name = " ",
            order = 43,
            values = WeakAuras.containment_types
        },
        progressPrecision = {
            type = "select",
            order = 44,
            name = L["Remaining Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.progressPrecision or 1 end,
            hidden = function()
                return not (data.displayStacks:find("%%p") or data.displayStacks:find("%%t"));
            end,
            disabled = function()
                return not data.displayStacks:find("%%p");
            end
        },
        totalPrecision = {
            type = "select",
            order = 44.5,
            name = L["Total Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.totalPrecision or 1 end,
            hidden = function()
                return not (data.displayStacks:find("%%p") or data.displayStacks:find("%%t"));
            end,
            disabled = function()
                return not data.displayStacks:find("%%t");
            end
        },
        color = {
            type = "color",
            name = L["Color"],
            hasAlpha = true,
            order = 7
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
            softMax = 72,
            step = 1
        },
        zoom = {
            type = "range",
            name = L["Zoom"],
            order = 49,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true
        },
        fontFlags = {
            type = "select",
            name = L["Outline"],
            order = 48,
            values = WeakAuras.font_flags
        },
		iconInset = {
            type = "range",
            name = L["Icon Inset"],
            order = 49.25,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true,
			hidden = function()
                return not LBF;
            end
        },
        stickyDuration = {
            type = "toggle",
            name = L["Sticky Duration"],
            desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
            order = 49
        },
        useTooltip = {
            type = "toggle",
            name = L["Tooltip on Mouseover"],
            hidden = function() return not WeakAuras.CanHaveTooltip(data) end,
            order = 49.5
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
    local texWidth = 0.25 * data.zoom;
    icon:SetTexCoord(texWidth, 1 - texWidth, texWidth, 1 - texWidth);

    function icon:SetIcon(path)
        local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
        if not(success) then
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
        end
    end
end

local templates = {
  {
    title = L["Default"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
    };
  },
  {
    title = L["Tiny Icon"],
    description = L["A 20x20 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 20,
      height = 20,
      cooldown = true
    };
  },
  {
    title = L["Small Icon"],
    description = L["A 32x32 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 32,
      height = 32,
      cooldown = true
    };
  },
  {
    title = L["Medium Icon"],
    description = L["A 40x40 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 40,
      height = 40,
      cooldown = true
    };
  },
  {
    title = L["Big Icon"],
    description = L["A 48x48 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 48,
      height = 48,
      cooldown = true
    };
  },
  {
    title = L["Huge Icon"],
    description = L["A 64x64 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 64,
      height = 64,
      cooldown = true
    };
  }
}

WeakAuras.RegisterRegionOptions("icon", createOptions, "Interface\\ICONS\\Temp.blp", L["Icon"], createThumbnail, modifyThumbnail, L["Shows a spell icon with an optional cooldown overlay"], templates);
