if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local rad = rad

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

local modelPicker

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
        if result ~= childObject[property] then
          return default
        end
      end
    end
  end
  return result
end

local function ConstructModelPicker(frame)
  local function RecurseSetFilter(tree, filter)
    for k, v in ipairs(tree) do
      if v.children == nil and v.text then
        v.visible = not filter or filter == "" or v.text:find(filter, 1, true) ~= nil
      else
        RecurseSetFilter(v.children, filter)
      end
    end
  end

  local group = AceGUI:Create("SimpleGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 87);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -63);
  group.frame:Hide();
  group:SetLayout("flow");

  local filterInput = CreateFrame("EditBox", "WeakAurasFilterInput", group.frame, "SearchBoxTemplate")
  filterInput:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    local filterText = filterInput:GetText()
    RecurseSetFilter(group.modelTree.tree, filterText)
    group.modelTree.filter = filterText ~= nil and filterText ~= ""
    group.modelTree:RefreshTree()
  end)
  filterInput:SetHeight(15)
  filterInput:SetPoint("BOTTOMRIGHT", group.frame, "TOPRIGHT", -3, 5)
  filterInput:SetWidth(200)
  filterInput:SetFont(STANDARD_TEXT_FONT, 10, "")
  group.frame.filterInput = filterInput

  -- Old X Y Z controls
  local modelPickerZ = AceGUI:Create("Slider");
  modelPickerZ:SetSliderValues(-20, 20, 0.05);
  modelPickerZ:SetLabel(L["Z Offset"]);
  modelPickerZ.frame:SetParent(group.frame);
  modelPickerZ:SetCallback("OnValueChanged", function()
    group:Pick(nil, modelPickerZ:GetValue());
  end);

  local modelPickerX = AceGUI:Create("Slider");
  modelPickerX:SetSliderValues(-20, 20, 0.05);
  modelPickerX:SetLabel(L["X Offset"]);
  modelPickerX.frame:SetParent(group.frame);
  modelPickerX:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, modelPickerX:GetValue());
  end);

  local modelPickerY = AceGUI:Create("Slider");
  modelPickerY:SetSliderValues(-20, 20, 0.05);
  modelPickerY:SetLabel(L["Y Offset"]);
  modelPickerY.frame:SetParent(group.frame);
  modelPickerY:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, nil, modelPickerY:GetValue());
  end);

  local modelPickerRotation = AceGUI:Create("Slider");
  modelPickerRotation:SetSliderValues(0, 360, 0.05);
  modelPickerRotation:SetLabel(L["Rotation"]);
  modelPickerRotation.frame:SetParent(group.frame);
  modelPickerRotation:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, nil, nil, modelPickerRotation:GetValue());
  end);

  -- New TX TY TZ, RX, RY, RZ, US controls
  local modelPickerTX = AceGUI:Create("Slider");
  modelPickerTX:SetSliderValues(-1000, 1000, 1);
  modelPickerTX:SetLabel(L["X Offset"]);
  modelPickerTX.frame:SetParent(group.frame);
  modelPickerTX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, modelPickerTX:GetValue());
  end);

  local modelPickerTY = AceGUI:Create("Slider");
  modelPickerTY:SetSliderValues(-1000, 1000, 1);
  modelPickerTY:SetLabel(L["Y Offset"]);
  modelPickerTY.frame:SetParent(group.frame);
  modelPickerTY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, modelPickerTY:GetValue());
  end);

  local modelPickerTZ = AceGUI:Create("Slider");
  modelPickerTZ:SetSliderValues(-1000, 1000, 1);
  modelPickerTZ:SetLabel(L["Z Offset"]);
  modelPickerTZ.frame:SetParent(group.frame);
  modelPickerTZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, modelPickerTZ:GetValue());
  end);

  local modelPickerRX = AceGUI:Create("Slider");
  modelPickerRX:SetSliderValues(0, 360, 1);
  modelPickerRX:SetLabel(L["X Rotation"]);
  modelPickerRX.frame:SetParent(group.frame);
  modelPickerRX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, modelPickerRX:GetValue());
  end);

  local modelPickerRY = AceGUI:Create("Slider");
  modelPickerRY:SetSliderValues(0, 360, 1);
  modelPickerRY:SetLabel(L["Y Rotation"]);
  modelPickerRY.frame:SetParent(group.frame);
  modelPickerRY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, modelPickerRY:GetValue());
  end);

  local modelPickerRZ = AceGUI:Create("Slider");
  modelPickerRZ:SetSliderValues(0, 360, 1);
  modelPickerRZ:SetLabel(L["Z Rotation"]);
  modelPickerRZ.frame:SetParent(group.frame);
  modelPickerRZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, modelPickerRZ:GetValue());
  end);

  local modelPickerUS = AceGUI:Create("Slider");
  modelPickerUS:SetSliderValues(5, 1000, 1);
  modelPickerUS:SetLabel(L["Scale"]);
  modelPickerUS.frame:SetParent(group.frame);
  modelPickerUS:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, nil, modelPickerUS:GetValue());
  end);

  local modelTree = AceGUI:Create("WeakAurasTreeGroup");
  group.modelTree = modelTree;
  group.frame:SetScript("OnSizeChanged", function()
    local frameWidth = frame:GetWidth();
    local sliderWidth = (frameWidth - 50) / 4;
    local narrowSliderWidth = (frameWidth - 50) / 7;

    modelTree:SetTreeWidth(frameWidth - 370);

    modelPickerZ.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickerZ.frame:SetPoint("bottomright", frame, "bottomleft", 15 + sliderWidth, 43);

    modelPickerX.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + sliderWidth, 43);
    modelPickerX.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (2 * sliderWidth), 43);

    modelPickerY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (2 * sliderWidth), 43);
    modelPickerY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (3 * sliderWidth), 43);

    modelPickerRotation.frame:SetPoint("bottomleft", frame, "bottomleft", 45 + (3 * sliderWidth), 43);
    modelPickerRotation.frame:SetPoint("bottomright", frame, "bottomleft", 45 + (4 * sliderWidth), 43);

    -- New controls
    modelPickerTX.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickerTX.frame:SetPoint("bottomright", frame, "bottomleft", 15 + narrowSliderWidth, 43);

    modelPickerTY.frame:SetPoint("bottomleft", frame, "bottomleft", 20 + narrowSliderWidth, 43);
    modelPickerTY.frame:SetPoint("bottomright", frame, "bottomleft", 20 + (2 * narrowSliderWidth), 43);

    modelPickerTZ.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + (2 * narrowSliderWidth), 43);
    modelPickerTZ.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (3 * narrowSliderWidth), 43);

    modelPickerRX.frame:SetPoint("bottomleft", frame, "bottomleft", 30 + (3 * narrowSliderWidth), 43);
    modelPickerRX.frame:SetPoint("bottomright", frame, "bottomleft", 30 + (4 * narrowSliderWidth), 43);

    modelPickerRY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (4 * narrowSliderWidth), 43);
    modelPickerRY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (5 * narrowSliderWidth), 43);

    modelPickerRZ.frame:SetPoint("bottomleft", frame, "bottomleft", 40 + (5 * narrowSliderWidth), 43);
    modelPickerRZ.frame:SetPoint("bottomright", frame, "bottomleft", 40 + (6 * narrowSliderWidth), 43);

    modelPickerUS.frame:SetPoint("bottomleft", frame, "bottomleft", 45 + (6 * narrowSliderWidth), 43);
    modelPickerUS.frame:SetPoint("bottomright", frame, "bottomleft", 45 + (7 * narrowSliderWidth), 43);

  end);
  group:SetLayout("fill");
  modelTree:SetTree(WeakAuras.ModelPaths);
  modelTree:SetCallback("OnGroupSelected", function(self, event, value, fileId)
    local path = string.gsub(value, "\001", "/");
    if(string.lower(string.sub(path, -3, -1)) == ".m2") then
      if (group.selectedValues.api) then
        group:PickSt(fileId);
      else
        group:Pick(fileId);
      end
    end
  end);
  group:AddChild(modelTree);

  local model = CreateFrame("PlayerModel", nil, group.content);
  model.SetTransformFixed = OptionsPrivate.Private.ModelSetTransformFixed
  model:SetAllPoints(modelTree.content);
  model:SetFrameStrata("FULLSCREEN");
  group.model = model;

  local startX, rotation
  local function OnUpdateScript()
    local uiScale, x = UIParent:GetEffectiveScale(), GetCursorPosition()
    local screenW, screenH = GetScreenWidth(), GetScreenHeight()
    local diffX = startX/uiScale - x/uiScale
    rotation = (rotation + 180 / screenW * diffX) % 360
    model:SetFacing(rad(rotation))
  end
  model:EnableMouse()
  model:SetScript("OnMouseDown", function(self)
    if not group.selectedValues.api then
      startX = GetCursorPosition()
      rotation = group.selectedValues.rotation or 0
      self:SetScript("OnUpdate", OnUpdateScript)
    end
  end)
  model:SetScript("OnMouseUp", function(self)
    if not group.selectedValues.api then
      self:SetScript("OnUpdate", nil)
      group:Pick(nil, nil, nil, nil, rotation)
    end
  end)

  local function SetStOnObject(object, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    if model_fileId then
      object.model_fileId = model_fileId
    end
    if model_tx then
      object.model_st_tx = model_tx
    end
    if model_ty then
      object.model_st_ty = model_ty
    end
    if model_tz then
      object.model_st_tz = model_tz
    end
    if model_rx then
      object.model_st_rx = model_rx
    end
    if model_ry then
      object.model_st_ry = model_ry
    end
    if model_rz then
      object.model_st_rz = model_rz
    end
    if model_us then
      object.model_st_us = model_us
    end
  end

  function group.PickSt(self, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    self.selectedValues.model_fileId = model_fileId or self.selectedValues.model_fileId
    self.selectedValues.model_st_tx = model_tx or self.selectedValues.model_st_tx
    self.selectedValues.model_st_ty = model_ty or self.selectedValues.model_st_ty
    self.selectedValues.model_st_tz = model_tz or self.selectedValues.model_st_tz

    self.selectedValues.model_st_rx = model_rx or self.selectedValues.model_st_rx;
    self.selectedValues.model_st_ry = model_ry or self.selectedValues.model_st_ry;
    self.selectedValues.model_st_rz = model_rz or self.selectedValues.model_st_rz;

    self.selectedValues.model_st_us = model_us or self.selectedValues.model_st_us;

    WeakAuras.SetModel(self.model, nil, self.selectedValues.model_fileId)
    self.model:SetTransformFixed(self.selectedValues.model_st_tx / 1000, self.selectedValues.model_st_ty / 1000, self.selectedValues.model_st_tz / 1000,
      rad(self.selectedValues.model_st_rx), rad(self.selectedValues.model_st_ry), rad(self.selectedValues.model_st_rz),
      self.selectedValues.model_st_us / 1000);

    for child in OptionsPrivate.Private.TraverseLeafsOrAura(self.baseObject) do
      local object = valueFromPath(child, self.path)
      if(object) then
        SetStOnObject(object, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
        WeakAuras.Add(child);
        WeakAuras.UpdateThumbnail(child);
      end
    end
  end

  local function SetOnObject(object, model_fileId, model_z, model_x, model_y, rotation)
    if model_fileId then
      object.model_fileId = model_fileId
    end
    if model_z then
      object.model_z = model_z
    end
    if model_x then
      object.model_x = model_x
    end
    if model_y then
      object.model_y = model_y
    end
    if rotation then
      object.rotation = rotation
    end
  end

  function group.Pick(self, model_fileId, model_z, model_x, model_y, rotation)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath

    self.selectedValues.model_fileId = model_fileId or self.selectedValues.model_fileId
    self.selectedValues.model_x = model_x or self.selectedValues.model_x
    self.selectedValues.model_y = model_y or self.selectedValues.model_y
    self.selectedValues.model_z = model_z or self.selectedValues.model_z
    self.selectedValues.rotation = rotation or self.selectedValues.rotation

    WeakAuras.SetModel(self.model, nil, self.selectedValues.model_fileId)

    self.model:ClearTransform();
    self.model:SetPosition(self.selectedValues.model_z, self.selectedValues.model_x, self.selectedValues.model_y);
    self.model:SetFacing(rad(self.selectedValues.rotation));

    for child in OptionsPrivate.Private.TraverseLeafsOrAura(self.baseObject) do
      local object = valueFromPath(child, self.path)
      if(object) then
        SetOnObject(object, model_fileId, model_z, model_x, model_y, rotation)
        WeakAuras.Add(child)
        WeakAuras.UpdateThumbnail(child)
      end
    end
  end

  function group.Open(self, baseObject, path)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath

    self.baseObject = baseObject
    self.path = path
    self.selectedValues = {}

    self.selectedValues.model_fileId = GetAll(baseObject, path, "model_fileId", "122968")

    WeakAuras.SetModel(self.model, nil, self.selectedValues.model_fileId)

    self.selectedValues.api = GetAll(baseObject, path, "api", false)
    self.selectedValues.model_st_tx = GetAll(baseObject, path, "model_st_tx", 0)
    self.selectedValues.model_st_ty = GetAll(baseObject, path, "model_st_ty", 0)
    self.selectedValues.model_st_tz = GetAll(baseObject, path, "model_st_tz", 0)

    self.selectedValues.model_st_rx = GetAll(baseObject, path, "model_st_rx", 0)
    self.selectedValues.model_st_ry = GetAll(baseObject, path, "model_st_ry", 0)
    self.selectedValues.model_st_rz = GetAll(baseObject, path, "model_st_rz", 0)

    self.selectedValues.model_st_us = GetAll(baseObject, path, "model_st_us", 0)

    self.selectedValues.model_x = GetAll(baseObject, path, "model_x", 0)
    self.selectedValues.model_y = GetAll(baseObject, path, "model_y", 0)
    self.selectedValues.model_z = GetAll(baseObject, path, "model_z", 0)
    self.selectedValues.rotation = GetAll(baseObject, path, "rotation", 0)


    if (self.selectedValues.api) then
      self.model:SetTransformFixed(self.selectedValues.model_st_tx / 1000, self.selectedValues.model_st_ty / 1000, self.selectedValues.model_st_tz / 1000,
        rad(self.selectedValues.model_st_rx), rad(self.selectedValues.model_st_ry), rad(self.selectedValues.model_st_rz),
        self.selectedValues.model_st_us / 1000);

      modelPickerTX:SetValue(self.selectedValues.model_st_tx);
      modelPickerTX.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_tx));

      modelPickerTY:SetValue(self.selectedValues.model_st_ty);
      modelPickerTY.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_ty));
      modelPickerTZ:SetValue(self.selectedValues.model_st_tz);
      modelPickerTZ.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_tz));

      modelPickerRX:SetValue(self.selectedValues.model_st_rx);
      modelPickerRX.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_rx));
      modelPickerRY:SetValue(self.selectedValues.model_st_ry);
      modelPickerRY.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_ry));
      modelPickerRZ:SetValue(self.selectedValues.model_st_rz);
      modelPickerRZ.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_rz));

      modelPickerUS:SetValue(self.selectedValues.model_st_us);
      modelPickerUS.editbox:SetText(("%.2f"):format(self.selectedValues.model_st_us));

      modelPickerZ.frame:Hide();
      modelPickerY.frame:Hide();
      modelPickerX.frame:Hide();
      modelPickerRotation.frame:Hide();

      modelPickerTX.frame:Show();
      modelPickerTY.frame:Show();
      modelPickerTZ.frame:Show();
      modelPickerRX.frame:Show();
      modelPickerRY.frame:Show();
      modelPickerRZ.frame:Show();
      modelPickerUS.frame:Show();
    else
      self.model:ClearTransform();
      self.model:SetPosition(self.selectedValues.model_z, self.selectedValues.model_x, self.selectedValues.model_y);
      self.model:SetFacing(rad(self.selectedValues.rotation));
      modelPickerZ:SetValue(self.selectedValues.model_z);
      modelPickerZ.editbox:SetText(("%.2f"):format(self.selectedValues.model_z));
      modelPickerX:SetValue(self.selectedValues.model_x);
      modelPickerX.editbox:SetText(("%.2f"):format(self.selectedValues.model_x));
      modelPickerY:SetValue(self.selectedValues.model_y);
      modelPickerY.editbox:SetText(("%.2f"):format(self.selectedValues.model_y));
      modelPickerRotation:SetValue(self.selectedValues.rotation);
      modelPickerRotation.editbox:SetText(("%.2f"):format(self.selectedValues.rotation));

      modelPickerZ.frame:Show();
      modelPickerY.frame:Show();
      modelPickerX.frame:Show();
      modelPickerRotation.frame:Show();

      modelPickerTX.frame:Hide();
      modelPickerTY.frame:Hide();
      modelPickerTZ.frame:Hide();
      modelPickerRX.frame:Hide();
      modelPickerRY.frame:Hide();
      modelPickerRZ.frame:Hide();
      modelPickerUS.frame:Hide();
    end

    if(baseObject.controlledChildren) then
      self.givenModelId = {};
      self.givenApi = {};
      self.givenZ = {};
      self.givenX = {};
      self.givenY = {};
      self.givenRotation = {};
      self.givenTX = {};
      self.givenTY = {};
      self.givenTZ = {};
      self.givenRX = {};
      self.givenRY = {};
      self.givenRZ = {};
      self.givenUS = {};
      for child in OptionsPrivate.Private.TraverseLeafs(baseObject) do
        local childId = child.id
        local object = valueFromPath(child, path)
        if(object) then
          self.givenModelId[childId] = object.model_fileId;
          self.givenApi[childId] = object.api
          if object.api then
            self.givenTX[childId] = object.model_st_tx;
            self.givenTY[childId] = object.model_st_ty;
            self.givenTZ[childId] = object.model_st_tz;
            self.givenRX[childId] = object.model_st_rx;
            self.givenRY[childId] = object.model_st_ry;
            self.givenRZ[childId] = object.model_st_rz;
            self.givenUS[childId] = object.model_st_us;
          else
            self.givenZ[childId] = object.model_z;
            self.givenX[childId] = object.model_x;
            self.givenY[childId] = object.model_y;
            self.givenRotation[childId] = object.rotation;
          end
        end
      end
    else
      local object = valueFromPath(baseObject, path)

      self.givenModelId = object.model_fileId;
      self.givenApi = object.api

      if object.api then
        self.givenTX = object.model_st_tx;
        self.givenTY = object.model_st_ty;
        self.givenTZ = object.model_st_tz;
        self.givenRX = object.model_st_rx;
        self.givenRY = object.model_st_ry;
        self.givenRZ = object.model_st_rz;
        self.givenUS = object.model_st_us;
      else
        self.givenZ = object.model_z;
        self.givenX = object.model_x;
        self.givenY = object.model_y;
        self.givenRotation = object.rotation;
      end
    end
    frame.window = "model";
    frame:UpdateFrameVisible()
  end

  function group.Close()
    frame.window = "default"
    frame:UpdateFrameVisible()
    WeakAuras.FillOptions()
  end

  function group.CancelClose()
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    if(group.baseObject.controlledChildren) then
      for child in OptionsPrivate.Private.TraverseLeafs(group.baseObject) do
        local childId = child.id
        local object = valueFromPath(child, group.path)
        if(object) then
          object.model_fileId = group.givenModelId[childId];
          object.api = group.givenApi[childId];
          if (object.api) then
            object.model_st_tx = group.givenTX[childId];
            object.model_st_ty = group.givenTY[childId];
            object.model_st_tz = group.givenTZ[childId];
            object.model_st_rx = group.givenRX[childId];
            object.model_st_ry = group.givenRY[childId];
            object.model_st_rz = group.givenRZ[childId];
            object.model_st_us = group.givenUS[childId];
          else
            object.model_z = group.givenZ[childId];
            object.model_x = group.givenX[childId];
            object.model_y = group.givenY[childId];
            object.rotation = group.givenRotation[childId];
          end
          WeakAuras.Add(child);
          WeakAuras.UpdateThumbnail(child);
        end
      end
    else
      local object = valueFromPath(group.baseObject, group.path)

      if(object) then
        object.model_fileId = group.givenModelId
        object.api = group.givenApi
        if (object.api) then
          object.model_st_tx = group.givenTX
          object.model_st_ty = group.givenTY
          object.model_st_tz = group.givenTZ
          object.model_st_rx = group.givenRX
          object.model_st_ry = group.givenRY
          object.model_st_rz = group.givenRZ
          object.model_st_us = group.givenUS
        else
          object.model_z = group.givenZ
          object.model_x = group.givenX
          object.model_y = group.givenY
          object.rotation = group.givenRotation
        end
        WeakAuras.Add(group.baseObject);
        WeakAuras.UpdateThumbnail(group.baseObject);
      end
    end
    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", group.CancelClose);
  cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -27, 20);
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

function OptionsPrivate.ModelPicker(frame, noConstruct)
  modelPicker = modelPicker or (not noConstruct and ConstructModelPicker(frame))
  return modelPicker
end
