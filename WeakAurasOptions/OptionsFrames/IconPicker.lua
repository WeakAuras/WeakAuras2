if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local pairs  = pairs

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

local iconPicker

local spellCache = WeakAuras.spellCache

local function ConstructIconPicker(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 46);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -50);
  group.frame:Hide();
  group:SetLayout("fill");

  local scroll = AceGUI:Create("ScrollFrame");
  scroll:SetLayout("flow");
  scroll.frame:SetClipsChildren(true);
  group:AddChild(scroll);

  local function iconPickerFill(subname, doSort)
    scroll:ReleaseChildren();

    local usedIcons = {};
    local AddButton = function(name, icon)
      local button = AceGUI:Create("WeakAurasIconButton");
      button:SetName(name);
      button:SetTexture(icon);
      button:SetClick(function()
        group:Pick(icon);
      end);
      scroll:AddChild(button);

      usedIcons[icon] = true;
    end

    -- Work around special numbers such as inf and nan
    if (tonumber(subname)) then
      local spellId = tonumber(subname);
      if (abs(spellId) < math.huge and tostring(spellId) ~= "nan") then
        local name, _, icon = OptionsPrivate.Private.ExecEnv.GetSpellInfo(spellId)
        if name and icon then
          AddButton(name, icon)
        end
        return;
      end
    end

    if subname then
      subname = subname:lower();
    end



    local num = 0;
    if(subname and subname ~= "") then
      for name, icons in pairs(spellCache.Get()) do
        if(name:lower():find(subname, 1, true)) then
          if icons.spells then
            for spell, icon in icons.spells:gmatch("(%d+)=(%d+)") do
              local iconId = tonumber(icon)
              if (not usedIcons[iconId]) then
                AddButton(name, iconId)
                num = num + 1;
                if(num >= 500) then
                  break;
                end
              end
            end
          elseif icons.achievements then
            for _, icon in icons.achievements:gmatch("(%d+)=(%d+)") do
              local iconId = tonumber(icon)
              if (not usedIcons[iconId]) then
                AddButton(name, iconId)
                num = num + 1;
                if(num >= 500) then
                  break;
                end
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

  local input = CreateFrame("EditBox", "WeakAurasFilterInput", group.frame, "SearchBoxTemplate")
  input:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    iconPickerFill(input:GetText(), false)
  end);
  input:SetScript("OnEnterPressed", function(...) iconPickerFill(input:GetText(), true); end);
  input:SetScript("OnEscapePressed", function(...) input:SetText(""); iconPickerFill(input:GetText(), true); end);
  input:SetWidth(200);
  input:SetHeight(15);
  input:SetFont(STANDARD_TEXT_FONT, 10, "")
  input:SetPoint("BOTTOMRIGHT", group.frame, "TOPRIGHT", -3, -10);

  local icon = AceGUI:Create("WeakAurasIconButton");
  icon.frame:Disable();
  icon.frame:SetParent(group.frame);
  icon.frame:SetPoint("BOTTOMLEFT", group.frame, "TOPLEFT", 44, -15);
  icon:SetHeight(36)
  icon:SetWidth(36)

  local iconLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
  iconLabel:SetNonSpaceWrap("true");
  iconLabel:SetJustifyH("LEFT");
  iconLabel:SetPoint("LEFT", icon.frame, "RIGHT", 5, 0);
  iconLabel:SetPoint("RIGHT", input, "LEFT", -50, 0);

  function group.Pick(self, texturePath)
    local valueToPath = OptionsPrivate.Private.ValueToPath
    if self.groupIcon then
      valueToPath(self.baseObject, self.paths[self.baseObject.id], texturePath)
      WeakAuras.Add(self.baseObject)
      WeakAuras.ClearAndUpdateOptions(self.baseObject.id)
      WeakAuras.UpdateThumbnail(self.baseObject)
    else
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(self.baseObject) do
        valueToPath(child, self.paths[child.id], texturePath)
        WeakAuras.Add(child)
        WeakAuras.ClearAndUpdateOptions(child.id)
        WeakAuras.UpdateThumbnail(child);
      end
    end
    local success = icon:SetTexture(texturePath) and texturePath;
    if(success) then
      iconLabel:SetText(texturePath);
    else
      iconLabel:SetText();
    end
  end

  function group.Open(self, baseObject, paths, groupIcon)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    self.baseObject = baseObject
    self.paths = paths
    self.groupIcon = groupIcon
    if groupIcon then
      local value = valueFromPath(self.baseObject, paths[self.baseObject.id])
      self.givenPath = value
    else
      self.givenPath = {};
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(baseObject) do
        if(child) then
          local value = valueFromPath(child, paths[child.id])
          self.givenPath[child.id] = value or "";
        end
      end
    end
    -- group:Pick(self.givenPath);
    frame.window = "icon";
    frame:UpdateFrameVisible()
    input:SetText("");
  end

  function group.Close()
    frame.window = "default";
    frame:UpdateFrameVisible()
    WeakAuras.FillOptions()
  end

  function group.CancelClose()
    local valueToPath = OptionsPrivate.Private.ValueToPath
    if group.groupIcon then
      valueToPath(group.baseObject, group.paths[group.baseObject.id], group.givenPath)
      WeakAuras.Add(group.baseObject)
      WeakAuras.ClearAndUpdateOptions(group.baseObject.id)
      WeakAuras.UpdateThumbnail(group.baseObject)
    else
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(group.baseObject) do
        if (group.givenPath[child.id]) then
          valueToPath(child, group.paths[child.id], group.givenPath[child.id])
          WeakAuras.Add(child);
          WeakAuras.ClearAndUpdateOptions(child.id)
          WeakAuras.UpdateThumbnail(child);
        end
      end
    end

    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", group.CancelClose);
  cancel:SetPoint("BOTTOMRIGHT", -20, -24)
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Cancel"]);

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", group.Close);
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0);
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText(L["Okay"]);

  return group
end

function OptionsPrivate.IconPicker(frame, noConstruct)
  iconPicker = iconPicker or (not noConstruct and ConstructIconPicker(frame))
  return iconPicker
end
