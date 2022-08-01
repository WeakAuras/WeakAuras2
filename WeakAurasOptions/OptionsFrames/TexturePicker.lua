if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

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

local function SetAll(baseObject, path, property, value)
  local valueFromPath = OptionsPrivate.Private.ValueFromPath
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(baseObject) do
    local object = valueFromPath(child, path)
      if object then
        object[property] = value
        WeakAuras.Add(child)
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

  local dropdown = AceGUI:Create("DropdownGroup");
  dropdown:SetLayout("fill");
  dropdown.width = "fill";
  dropdown:SetHeight(390);
  group:SetLayout("fill");
  group:AddChild(dropdown);
  dropdown.list = {};
  dropdown:SetGroupList(dropdown.list);

  local scroll = AceGUI:Create("ScrollFrame");
  scroll:SetWidth(540);
  scroll:SetLayout("flow");
  scroll.frame:SetClipsChildren(true);
  dropdown:AddChild(scroll);

  local function texturePickerGroupSelected(widget, event, uniquevalue)
    scroll:ReleaseChildren();
    for texturePath, textureName in pairs(group.textures[uniquevalue]) do
      local textureWidget = AceGUI:Create("WeakAurasTextureButton");
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
      scroll:AddChild(textureWidget);
      table.sort(scroll.children, function(a, b)
        local aPath, bPath = a:GetTexturePath(), b:GetTexturePath();
        local aNum, bNum = tonumber(aPath:match("%d+")), tonumber(bPath:match("%d+"));
        local aNonNumber, bNonNumber = aPath:match("[^%d]+"), bPath:match("[^%d]+")
        if(aNum and bNum and aNonNumber == bNonNumber) then
          return aNum < bNum;
        else
          return aPath < bPath;
        end
      end);
    end
  end

  dropdown:SetCallback("OnGroupSelected", texturePickerGroupSelected)

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
    for index, widget in ipairs(scroll.children) do
      widget:ClearPick();
      if(widget:GetTexturePath() == texturePath) then
        pickedwidget = widget;
      end
    end
    if(pickedwidget) then
      pickedwidget:Pick();
    end

    wipe(group.selectedTextures)
    group.selectedTextures[texturePath] = true

    SetAll(self.baseObject, self.path, self.properties.texture, texturePath)

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
