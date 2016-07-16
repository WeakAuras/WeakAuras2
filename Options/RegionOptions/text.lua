local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;
local dynamics = WeakAuras.dynamic_texts;

-- GLOBALS: WeakAuras UIParent AceGUIWidgetLSMlists

local function createOptions(id, data)
    local options = {
        displayText = {
            type = "input",
            width = "double",
            desc = function()
                 local ret = L["Dynamic text tooltip"];
                 ret = ret .. WeakAuras.GetAdditionalProperties(data);
                 return ret
            end,
            multiline = true,
            name = L["Display Text"],
            order = 10,
            get = function()
                local ret = data.displayText;
                for symbol, v in pairs(WeakAuras.dynamic_texts) do
                    ret = ret:gsub("("..symbol..")", "|cFFFF0000%1|r");
                end
                return ret;
            end,
            set = function(info, v)
                v = v:gsub("|cFFFF0000", "");
                v = v:gsub("|r", "");
                data.displayText = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
                WeakAuras.ResetMoverSizer();
            end
        },
        customTextUpdate = {
            type = "select",
            width = "double",
            hidden = function() return not data.displayText:find("%%c"); end,
            name = L["Update Custom Text On..."],
            values = WeakAuras.text_check_types,
            order = 36
        },
        customText = {
            type = "input",
            width = "normal",
            hidden = function()
                return not data.displayText:find("%%c")
            end,
            multiline = true,
            name = L["Custom Function"],
            order = 37
        },
        customText_expand = {
            type = "execute",
            order = 38,
            name = L["Expand Text Editor"],
            func = function()
                WeakAuras.TextEditor(data, {"customText"})
            end,
            hidden = function()
                return not data.displayText:find("%%c")
            end,
        },
        progressPrecision = {
            type = "select",
            order = 39,
            name = L["Remaining Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.progressPrecision or 1 end,
            hidden = function()
                return not (data.displayText:find("%%p") or data.displayText:find("%%t"));
            end,
            disabled = function()
                return not data.displayText:find("%%p");
            end
        },
        totalPrecision = {
            type = "select",
            order = 39.5,
            name = L["Total Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.totalPrecision or 1 end,
            hidden = function()
                return not (data.displayText:find("%%p") or data.displayText:find("%%t"));
            end,
            disabled = function()
                return not data.displayText:find("%%t");
            end
        },
        color = {
            type = "color",
            name = L["Text Color"],
            hasAlpha = true,
            order = 40
        },
        outline = {
            type = "toggle",
            width = "half",
            name = L["Outline"],
            order = 42
        },
        justify = {
            type = "select",
            width = "half",
            name = L["Justify"],
            order = 43,
            values = WeakAuras.justify_types
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
        spacer = {
            type = "header",
            name = "",
            order = 50
        }
    };
    options = WeakAuras.AddPositionOptions(options, id, data);

    options.width = nil;
    options.height = nil;

    return options;
end

local function createThumbnail(parent, fullCreate)
    local borderframe = CreateFrame("FRAME", nil, parent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);

    local border = borderframe:CreateTexture(nil, "OVERLAY");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

    local mask = CreateFrame("ScrollFrame", nil, borderframe);
    borderframe.mask = mask;
    mask:SetPoint("BOTTOMLEFT", borderframe, "BOTTOMLEFT", 2, 2);
    mask:SetPoint("TOPRIGHT", borderframe, "TOPRIGHT", -2, -2);

    local content = CreateFrame("Frame", nil, mask);
    borderframe.content = content;
    content:SetPoint("CENTER", mask, "CENTER");
    mask:SetScrollChild(content);

    local text = content:CreateFontString(nil, "OVERLAY");
    borderframe.text = text;
    text:SetNonSpaceWrap(true);

    borderframe.values = {};

    return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
    local mask, content, text = borderframe.mask, borderframe.content, borderframe.text;

    size = size or 28;

    local fontPath = SharedMedia:Fetch("font", data.font) or data.font;
    text:SetFont(fontPath, data.fontSize, data.outline and "OUTLINE" or nil);
    text:SetTextHeight(data.fontSize);
    text:SetText(data.displayText);
    text:SetTextColor(data.color[1], data.color[2], data.color[3], data.color[4]);
    text:SetJustifyH(data.justify);

    text:ClearAllPoints();
    text:SetPoint("CENTER", UIParent, "CENTER");
    content:SetWidth(math.max(text:GetStringWidth(), size));
    content:SetHeight(math.max(text:GetStringHeight(), size));
    text:ClearAllPoints();
    text:SetPoint("CENTER", content, "CENTER");

    local function rescroll()
        content:SetWidth(math.max(text:GetStringWidth(), size));
        content:SetHeight(math.max(text:GetStringHeight(), size));
        local xo = 0;
        if(data.justify == "CENTER") then
            xo = mask:GetHorizontalScrollRange() / 2;
        elseif(data.justify == "RIGHT") then
            xo = mask:GetHorizontalScrollRange();
        end
        mask:SetHorizontalScroll(xo);
        mask:SetVerticalScroll(mask:GetVerticalScrollRange() / 2);
    end

    rescroll();
    mask:SetScript("OnScrollRangeChanged", rescroll);

    local function UpdateText()
        local textStr = data.displayText
        for symbol, v in pairs(WeakAuras.dynamic_texts) do
            if(v.static) then
                textStr = textStr:gsub(symbol, v.static);
            else
                textStr = textStr:gsub(symbol, borderframe.values[v.value] or "?");
            end
        end
        text:SetText(textStr);
        rescroll();
    end

    function borderframe:SetIcon(path)
        local icon = (
            WeakAuras.CanHaveAuto(data)
            and path ~= ""
            and path
            or data.displayIcon
            or "Interface\\Icons\\INV_Misc_QuestionMark"
        );
        borderframe.values.icon = "|T"..icon..":12:12:0:0:64:64:4:60:4:60|t";
        UpdateText();
    end

    function borderframe:SetName(name)
        borderframe.values.name = WeakAuras.CanHaveAuto(data) and name or data.id;
        UpdateText();
    end

    UpdateText();
end

local function createIcon()
    local data = {
        outline = true,
        color = {1, 1, 0, 1},
        justify = "CENTER",
        font = "Friz Quadrata TT",
        fontSize = 12,
        displayText = "World\nof\nWarcraft";
    };

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data);
    thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3);
    thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3);

    return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    description = L["Displays a text, works best in combination with other displays"],
    data = {
    };
  }
}

WeakAuras.RegisterRegionOptions("text", createOptions, createIcon, L["Text"], createThumbnail, modifyThumbnail, L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"], templates);
