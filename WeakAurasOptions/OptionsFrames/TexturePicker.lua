if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...
local GetAtlasInfo = C_Texture and  C_Texture.GetAtlasInfo or GetAtlasInfo

-- Lua APIs
local wipe = wipe
local pairs, next, type = pairs, next, type

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local function CompareValues(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) == "table" then
    for k, v in pairs(a) do
      if v ~= b[k] then
        return false
      end
    end

    for k, v in pairs(b) do
      if v ~= a[k] then
        return false
      end
    end

    return true
  else
    return a == b
  end
end

local function GetAll(baseObject, path, property, default)
  local valueFromPath = OptionsPrivate.Private.ValueFromPath
  if not property then
    return default
  end

  local result = default
  local first = true
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(baseObject) do
    local childObject = valueFromPath(child, path)
    if childObject and childObject[property] then
      if first then
        result = childObject[property]
        first = false
      else
        if not CompareValues(result, childObject[property]) then
          return default
        end
      end
    end
  end
  return result
end

local function SetAll(baseObject, path, property, value, width, height)
  local valueFromPath = OptionsPrivate.Private.ValueFromPath
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(baseObject) do
    local object = valueFromPath(child, path)
      if object then
        object[property] = value
        if width and height then
          child.width = width
          child.height = height
        end
        WeakAuras.Add(child)
        WeakAuras.ClearAndUpdateOptions(child.id)
        WeakAuras.UpdateThumbnail(child)
      end
  end
end

local texturePicker

local function ConstructTexturePicker(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 42);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group.children = {};
  group.categories = {};
  group.textureWidgets = {}

  local dropdown = AceGUI:Create("DropdownGroup");
  dropdown:SetLayout("fill");
  dropdown.width = "fill";
  dropdown:SetHeight(390);
  group:SetLayout("fill");
  group:AddChild(dropdown);
  dropdown.list = {};
  dropdown:SetGroupList(dropdown.list);

  local scroll = AceGUI:Create("WeakAurasScrollArea");
  scroll:SetWidth(540);
  dropdown:AddChild(scroll);

  local function UpdateShownWidgets()
    -- Acquires/Releases widgets based on the scroll position
    for _, widget in ipairs(group.textureWidgets) do
      widget.frame:Hide()
      widget:Release()
    end
    wipe(group.textureWidgets)
    local viewportWidth, viewportHeight = scroll:GetViewportSize()

    local texturesPerRow = floor(viewportWidth / 128)
    local topRow = floor(scroll:GetContentOffset() / 128)
    local bottomRow = topRow + ceil(viewportHeight / 128)

    local first = topRow * texturesPerRow + 1
    local last = first + (bottomRow - topRow + 1) * texturesPerRow - 1

    for i = first, last do
      local data = group.selectedGroupSorted[i]
      if data then
        local texturePath, textureName = data[1], data[2]
        local textureWidget = AceGUI:Create("WeakAurasTextureButton");
        tinsert(group.textureWidgets, textureWidget)
        if (group.SetTextureFunc) then
          group.SetTextureFunc(textureWidget, texturePath, textureName);
        else
          textureWidget:SetTexture(texturePath, textureName);
          local d = group.textureData;
          textureWidget:ChangeTexture(d.r, d.g, d.b, d.a, d.rotate, d.discrete_rotation, d.rotation, d.mirror, d.blendMode);
        end
        if group.selectedTextures[texturePath] then
          textureWidget:Pick()
        end
        textureWidget:SetClick(function()
          group:Pick(texturePath);
        end);

        local index = i - 1 -- Math is easier if we start counting at 0
        local textureY = floor(index / texturesPerRow) * -128
        local textureX = (index % texturesPerRow) * 128

        textureWidget.frame:Show()
        textureWidget.frame:SetParent(scroll.content)
        textureWidget.frame:SetPoint("TOPLEFT", textureX, textureY)
      end
    end
  end

  scroll:SetCallback("ContentScrolled", function(self)
    UpdateShownWidgets()
  end)

  local function texturePickerGroupSelected(widget, event, uniquevalue, filter)
    group.selectedGroupSorted = {}
    if filter then
      filter = filter:lower()
    end
    for texturePath, textureName in pairs(group.textures[uniquevalue]) do
      if filter == nil or filter == "" or textureName:lower():match(filter) then
        tinsert(group.selectedGroupSorted, {texturePath, textureName})
      end
    end

    table.sort(group.selectedGroupSorted, function(a, b)
      local aPath, bPath = a[1], b[1]
      local aNum, bNum = tonumber(aPath:match("%d+")), tonumber(bPath:match("%d+"));
      local aNonNumber, bNonNumber = aPath:match("[^%d]+"), bPath:match("[^%d]+")
      if(aNum and bNum and aNonNumber == bNonNumber) then
        return aNum < bNum;
      else
        return aPath < bPath;
        end
    end)

    local viewportWidth = scroll:GetViewportSize()
    local texturesPerRow = floor(viewportWidth / 128)
    if texturesPerRow == 0 then
      texturesPerRow = 1
    end
    local totalHeight = ceil(#group.selectedGroupSorted / texturesPerRow) * 128
    scroll:SetContentHeight(totalHeight)

    UpdateShownWidgets()
  end

  local input = CreateFrame("EditBox", nil, group.frame, "InputBoxTemplate");
  input:SetScript("OnTextChanged", function(...)
    local status = dropdown.status or dropdown.localstatus
    texturePickerGroupSelected(nil, nil, status.selected, input:GetText())
  end);
  input:SetScript("OnEnterPressed", function(...)
    local status = dropdown.status or dropdown.localstatus
    texturePickerGroupSelected(nil, nil, status.selected, input:GetText())
  end);
  input:SetScript("OnEscapePressed", function(...)
    input:SetText("");
    local status = dropdown.status or dropdown.localstatus
    texturePickerGroupSelected(nil, nil, status.selected, input:GetText())
  end);
  input:SetWidth(170);
  input:SetHeight(15);
  input:SetPoint("BOTTOMRIGHT", dropdown.frame, "TOPRIGHT", -12, -25);

  local inputLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  inputLabel:SetText(L["Search"]);
  inputLabel:SetJustifyH("RIGHT");
  inputLabel:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 5);

  dropdown:SetCallback("OnGroupSelected", function(widget, event, uniquevalue)
    texturePickerGroupSelected(widget, event, uniquevalue, input:GetText())
  end)

  function group.UpdateList(self)
    dropdown.dropdown.pullout:Close()
    wipe(dropdown.list);
    for categoryName, category in pairs(self.textures) do
      local match = false;
      for texturePath, textureName in pairs(category) do
        if(self.selectedTextures[texturePath]) then
          match = true;
          break;
        end
      end
      dropdown.list[categoryName] = (match and "|cFF80A0FF" or "")..categoryName;
    end
    dropdown:SetGroupList(dropdown.list);
  end

  function group.Pick(self, texturePath)
    local pickedwidget;
    for index, widget in ipairs(group.textureWidgets) do
      widget:ClearPick();
      if(widget:GetTexturePath() == texturePath) then
        pickedwidget = widget;
      end
    end
    local width, height
    if(pickedwidget) then
      pickedwidget:Pick();
      if not pickedwidget.texture.IsStopMotion then
        local atlasInfo = GetAtlasInfo(pickedwidget.texture.path)
        if atlasInfo then
          width = atlasInfo.width
          height = atlasInfo.height
        end
      end
    end

    wipe(group.selectedTextures)
    group.selectedTextures[texturePath] = true

    SetAll(self.baseObject, self.path, self.properties.texture, texturePath, width, height)

    group:UpdateList();
    local status = dropdown.status or dropdown.localstatus
    dropdown.dropdown:SetText(dropdown.list[status.selected]);
  end

  function group.Open(self, baseObject, path, properties, textures, SetTextureFunc)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    self.baseObject = baseObject
    self.path = path
    self.properties = properties
    self.textures = textures;
    self.SetTextureFunc = SetTextureFunc
    self.givenPath = {};
    self.selectedTextures = {}

    for child in OptionsPrivate.Private.TraverseLeafsOrAura(baseObject) do
      local object = valueFromPath(child, path)
      if object and object[properties.texture] then
        self.givenPath[child.id] = object[properties.texture]
        self.selectedTextures[object[properties.texture]] = true
      end
    end

    local colorAll = GetAll(baseObject, path, properties.color, {1, 1, 1, 1});
    self.textureData = {
      r = colorAll[1] or 1,
      g = colorAll[2] or 1,
      b = colorAll[3] or 1,
      a = colorAll[4] or 1,
      rotate = GetAll(baseObject, path, properties.rotate, true),
      discrete_rotation = GetAll(baseObject, path, properties.discrete_rotation, 0),
      rotation = GetAll(baseObject, path, properties.rotation, 0),
      mirror = GetAll(baseObject, path, properties.mirror, false),
      blendMode = GetAll(baseObject, path, properties.blendMode, "ADD")
    }

    frame.window = "texture";
    frame:UpdateFrameVisible()
    group:UpdateList()
    local _, givenPath = next(self.givenPath)
    local picked = false;
    for categoryName, category in pairs(self.textures) do
      if not(picked) then
        for texturePath, textureName in pairs(category) do
          if(self.selectedTextures[texturePath]) then
            dropdown:SetGroup(categoryName);
            picked = true;
            break;
          end
        end
      end
    end
    if not(picked) then
      local categoryName = next(self.textures)
      if(categoryName) then
        dropdown:SetGroup(categoryName);
      end
    end
    UpdateShownWidgets()
  end

  function group.Close()
    frame.window = "default";
    frame:UpdateFrameVisible()
    WeakAuras.FillOptions()
  end

  function group.CancelClose()
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(group.baseObject) do
      local childObject = valueFromPath(child, group.path)
      if childObject then
        childObject[group.properties.texture] = group.givenPath[child.id]
        WeakAuras.Add(child);
        WeakAuras.UpdateThumbnail(child);
      end
    end
    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  cancel:SetScript("OnClick", group.CancelClose)
  cancel:SetPoint("BOTTOMRIGHT", -27, -23)
  cancel:SetSize(100, 20)
  cancel:SetText(L["Cancel"])

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  close:SetScript("OnClick", group.Close)
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
  close:SetSize(100, 20)
  close:SetText(L["Okay"])

  return group
end

function OptionsPrivate.TexturePicker(frame)
  texturePicker = texturePicker or ConstructTexturePicker(frame)
  return texturePicker
end
