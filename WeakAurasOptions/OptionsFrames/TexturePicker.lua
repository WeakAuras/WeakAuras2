if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local wipe = wipe
local pairs, next, type = pairs, next, type

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L
local getAll = WeakAuras.getAll
local setAll = WeakAuras.setAll

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
    group:Pick(group.data[group.field]);
  end

  dropdown:SetCallback("OnGroupSelected", texturePickerGroupSelected)

  function group.UpdateList(self)
    wipe(dropdown.list);
    for categoryName, category in pairs(self.textures) do
      local match = false;
      for texturePath, textureName in pairs(category) do
        if(texturePath == self.data[self.field]) then
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

    if(self.data.controlledChildren) then
      setAll(self.data, {"region", self.field}, texturePath);
    else
      self.data[self.field] = texturePath;
    end
    if(type(self.data.id) == "string") then
      WeakAuras.Add(self.data);
      WeakAuras.SetIconNames(self.data);
      WeakAuras.SetThumbnail(self.data);
    end
    group:UpdateList();
    local status = dropdown.status or dropdown.localstatus
    dropdown.dropdown:SetText(dropdown.list[status.selected]);
  end

  function group.Open(self, data, field, textures, SetTextureFunc)
    self.data = data;
    self.field = field;
    self.textures = textures;
    self.SetTextureFunc = SetTextureFunc
    if(data.controlledChildren) then
      self.givenPath = {};
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenPath[childId] = childData[field];
        end
      end
      local colorAll = getAll(data, {"region", "color"}) or {1, 1, 1, 1};
      self.textureData = {
        r = colorAll[1] or 1,
        g = colorAll[2] or 1,
        b = colorAll[3] or 1,
        a = colorAll[4] or 1,
        rotate = getAll(data, {"region", "rotate"}),
        discrete_rotation = getAll(data, {"region", "discrete_rotation"}) or 0,
        rotation = getAll(data, {"region", "rotation"}) or 0,
        mirror = getAll(data, {"region", "mirror"}),
        blendMode = getAll(data, {"region", "blendMode"}) or "ADD"
      };
    else
      self.givenPath = data[field];
      data.color = data.color or {};
      self.textureData = {
        r = data.color[1] or 1,
        g = data.color[2] or 1,
        b = data.color[3] or 1,
        a = data.color[4] or 1,
        rotate = data.rotate,
        discrete_rotation = data.discrete_rotation or 0,
        rotation = data.rotation or 0,
        mirror = data.mirror,
        blendMode = data.blendMode or "ADD"
      };
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "texture";
    local picked = false;
    local _, givenPath
    if type(self.givenPath) == "string" then
      givenPath = self.givenPath;
    else
      _, givenPath = next(self.givenPath);
    end
    WeakAuras.debug(givenPath, 3);
    for categoryName, category in pairs(self.textures) do
      if not(picked) then
        for texturePath, textureName in pairs(category) do
          if(texturePath == givenPath) then
            dropdown:SetGroup(categoryName);
            self:Pick(givenPath);
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
    group.frame:Hide();
    frame.buttonsContainer.frame:Show();
    frame.container.frame:Show();
    frame.window = "default";
    AceConfigDialog:Open("WeakAuras", frame.container);
  end

  function group.CancelClose()
    if(group.data.controlledChildren) then
      for index, childId in pairs(group.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[group.field] = group.givenPath[childId];
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      group:Pick(group.givenPath);
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

function WeakAuras.TexturePicker(frame)
  texturePicker = texturePicker or ConstructTexturePicker(frame)
  return texturePicker
end
