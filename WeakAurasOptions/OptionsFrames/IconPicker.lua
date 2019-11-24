if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local pairs  = pairs

-- WoW APIs
local CreateFrame, GetSpellInfo = CreateFrame, GetSpellInfo

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local iconPicker

local spellCache = WeakAuras.spellCache

local function ConstructIconPicker(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 30); -- 12
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -50);
  group.frame:Hide();
  group:SetLayout("flow");

  local scroll = AceGUI:Create("ScrollFrame");
  scroll:SetLayout("flow");
  scroll.frame:SetClipsChildren(true);
  group:AddChild(scroll);

  local function iconPickerFill(subname, doSort)
    scroll:ReleaseChildren();

    local distances = {};
    local names = {};

    -- Work around special numbers such as inf and nan
    if (tonumber(subname)) then
      local spellId = tonumber(subname);
      if (abs(spellId) < math.huge and tostring(spellId) ~= "nan") then
        subname = GetSpellInfo(spellId)
      end
    end

    if subname then
      subname = subname:lower();
    end

    local usedIcons = {};
    local num = 0;
    if(subname and subname ~= "") then
      for name, icons in pairs(spellCache.Get()) do
        local bestDistance = math.huge;
        local bestName;
        if(name:lower():find(subname, 1, true)) then

          for spellId, icon in pairs(icons) do
            if (not usedIcons[icon]) then
              local button = AceGUI:Create("WeakAurasIconButton");
              button:SetName(name);
              button:SetTexture(icon);
              button:SetClick(function()
                group:Pick(icon);
              end);
              scroll:AddChild(button);

              usedIcons[icon] = true;
              num = num + 1;
              if(num >= 500) then
                break;
              end
            end
          end
        end

        if(num >= 500) then
          break;
        end
      end
    end
  end

  local input = CreateFrame("EDITBOX", nil, group.frame, "InputBoxTemplate");
  input:SetScript("OnTextChanged", function(...) iconPickerFill(input:GetText(), false); end);
  input:SetScript("OnEnterPressed", function(...) iconPickerFill(input:GetText(), true); end);
  input:SetScript("OnEscapePressed", function(...) input:SetText(""); iconPickerFill(input:GetText(), true); end);
  input:SetWidth(170);
  input:SetHeight(15);
  input:SetPoint("BOTTOMRIGHT", group.frame, "TOPRIGHT", -12, -5);
  WeakAuras.input = input;

  local inputLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  inputLabel:SetText(L["Search"]);
  inputLabel:SetJustifyH("RIGHT");
  inputLabel:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 5);

  local icon = AceGUI:Create("WeakAurasIconButton");
  icon.frame:Disable();
  icon.frame:SetParent(group.frame);
  icon.frame:SetPoint("BOTTOMLEFT", group.frame, "TOPLEFT", 15, -15);

  local iconLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
  iconLabel:SetNonSpaceWrap("true");
  iconLabel:SetJustifyH("LEFT");
  iconLabel:SetPoint("LEFT", icon.frame, "RIGHT", 5, 0);
  iconLabel:SetPoint("RIGHT", input, "LEFT", -50, 0);

  function group.Pick(self, texturePath)
    if(not self.groupIcon and self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[self.field] = texturePath;
          WeakAuras.Add(childData);
          WeakAuras.UpdateThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data[self.field] = texturePath;
      WeakAuras.Add(self.data);
      WeakAuras.UpdateThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
    local success = icon:SetTexture(texturePath) and texturePath;
    if(success) then
      iconLabel:SetText(texturePath);
    else
      iconLabel:SetText();
    end
  end

  function group.Open(self, data, field, groupIcon)
    self.data = data;
    self.field = field;
    self.groupIcon = groupIcon
    if(not groupIcon and data.controlledChildren) then
      self.givenPath = {};
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenPath[childId] = childData[field];
        end
      end
    else
      self.givenPath = self.data[self.field];
    end
    -- group:Pick(self.givenPath);
    frame.window = "icon";
    frame:UpdateFrameVisible()
    input:SetText("");
  end

  function group.Close()
    frame.window = "default";
    frame:UpdateFrameVisible()
    AceConfigDialog:Open("WeakAuras", frame.container);
  end

  function group.CancelClose()
    if(not group.groupIcon and group.data.controlledChildren) then
      for index, childId in pairs(group.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[group.field] = group.givenPath[childId] or childData[group.field];
          WeakAuras.Add(childData);
          WeakAuras.UpdateThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      group:Pick(group.givenPath);
    end
    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", group.CancelClose);
  cancel:SetPoint("bottomright", frame, "bottomright", -27, 11);
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Cancel"]);

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", group.Close);
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0);
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText(L["Okay"]);

  scroll.frame:SetPoint("BOTTOM", close, "TOP", 0, 10);
  return group
end

function WeakAuras.IconPicker(frame)
  iconPicker = iconPicker or ConstructIconPicker(frame)
  return iconPicker
end
