if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

-- Lua APIs
local pairs, rad = pairs, rad

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local modelPicker

local function GetAll(baseObject, path, property, default)
  local valueFromPath = OptionsPrivate.Private.ValueFromPath
  if not property then
    return default
  end
  if baseObject.controlledChildren then
    local result
    local first = true
    for index, childId in pairs(baseObject.controlledChildren) do
      local childData = WeakAuras.GetData(childId)
      local childObject = valueFromPath(childData, path)
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
  else
    local object = valueFromPath(baseObject, path)
    if object and object[property] then
      return object[property]
    end
    return default
  end
end

local function ConstructModelPicker(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 87);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group:SetLayout("flow");

  -- Old X Y Z controls
  local modelPickerZ = AceGUI:Create("Slider");
  modelPickerZ:SetSliderValues(-20, 20, 0.05);
  modelPickerZ:SetLabel(L["Z Offset"]);
  modelPickerZ.frame:SetParent(group.frame);
  modelPickerZ:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, modelPickerZ:GetValue());
  end);

  local modelPickerX = AceGUI:Create("Slider");
  modelPickerX:SetSliderValues(-20, 20, 0.05);
  modelPickerX:SetLabel(L["X Offset"]);
  modelPickerX.frame:SetParent(group.frame);
  modelPickerX:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, nil, modelPickerX:GetValue());
  end);

  local modelPickerY = AceGUI:Create("Slider");
  modelPickerY:SetSliderValues(-20, 20, 0.05);
  modelPickerY:SetLabel(L["Y Offset"]);
  modelPickerY.frame:SetParent(group.frame);
  modelPickerY:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, nil, nil, modelPickerY:GetValue());
  end);

  -- New TX TY TZ, RX, RY, RZ, US controls
  local modelPickerTX = AceGUI:Create("Slider");
  modelPickerTX:SetSliderValues(-1000, 1000, 1);
  modelPickerTX:SetLabel(L["X Offset"]);
  modelPickerTX.frame:SetParent(group.frame);
  modelPickerTX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, modelPickerTX:GetValue());
  end);

  local modelPickerTY = AceGUI:Create("Slider");
  modelPickerTY:SetSliderValues(-1000, 1000, 1);
  modelPickerTY:SetLabel(L["Y Offset"]);
  modelPickerTY.frame:SetParent(group.frame);
  modelPickerTY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, modelPickerTY:GetValue());
  end);

  local modelPickerTZ = AceGUI:Create("Slider");
  modelPickerTZ:SetSliderValues(-1000, 1000, 1);
  modelPickerTZ:SetLabel(L["Z Offset"]);
  modelPickerTZ.frame:SetParent(group.frame);
  modelPickerTZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, modelPickerTZ:GetValue());
  end);

  local modelPickerRX = AceGUI:Create("Slider");
  modelPickerRX:SetSliderValues(0, 360, 1);
  modelPickerRX:SetLabel(L["X Rotation"]);
  modelPickerRX.frame:SetParent(group.frame);
  modelPickerRX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, modelPickerRX:GetValue());
  end);

  local modelPickerRY = AceGUI:Create("Slider");
  modelPickerRY:SetSliderValues(0, 360, 1);
  modelPickerRY:SetLabel(L["Y Rotation"]);
  modelPickerRY.frame:SetParent(group.frame);
  modelPickerRY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, modelPickerRY:GetValue());
  end);

  local modelPickerRZ = AceGUI:Create("Slider");
  modelPickerRZ:SetSliderValues(0, 360, 1);
  modelPickerRZ:SetLabel(L["Z Rotation"]);
  modelPickerRZ.frame:SetParent(group.frame);
  modelPickerRZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, nil, modelPickerRZ:GetValue());
  end);

  local modelPickerUS = AceGUI:Create("Slider");
  modelPickerUS:SetSliderValues(5, 1000, 1);
  modelPickerUS:SetLabel(L["Scale"]);
  modelPickerUS.frame:SetParent(group.frame);
  modelPickerUS:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, nil, nil, modelPickerUS:GetValue());
  end);

  local modelTree = AceGUI:Create("WeakAurasTreeGroup");
  group.modelTree = modelTree;
  group.frame:SetScript("OnSizeChanged", function()
    local frameWidth = frame:GetWidth();
    local sliderWidth = (frameWidth - 50) / 3;
    local narrowSliderWidth = (frameWidth - 50) / 7;

    modelTree:SetTreeWidth(frameWidth - 370);

    modelPickerZ.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickerZ.frame:SetPoint("bottomright", frame, "bottomleft", 15 + sliderWidth, 43);

    modelPickerX.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + sliderWidth, 43);
    modelPickerX.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (2 * sliderWidth), 43);

    modelPickerY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (2 * sliderWidth), 43);
    modelPickerY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (3 * sliderWidth), 43);

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
      local model_path = path;
      if (group.selectedValues.api) then
        group:PickSt(model_path, fileId);
      else
        group:Pick(model_path, fileId);
      end
    end
  end);
  group:AddChild(modelTree);

  local model = CreateFrame("PlayerModel", nil, group.content);
  model:SetAllPoints(modelTree.content);
  model:SetFrameStrata("FULLSCREEN");
  group.model = model;

  local function SetStOnObject(object, model_path, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    if model_path then
      object.model_path = model_path
    end
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

  function group.PickSt(self, model_path, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    self.selectedValues.model_path = model_path or self.selectedValues.model_path
    self.selectedValues.model_fileId = model_fileId or self.selectedValues.model_fileId
    self.selectedValues.model_st_tx = model_tx or self.selectedValues.model_st_tx
    self.selectedValues.model_st_ty = model_ty or self.selectedValues.model_st_ty
    self.selectedValues.model_st_tz = model_tz or self.selectedValues.model_st_tz

    self.selectedValues.model_st_rx = model_rx or self.selectedValues.model_st_rx;
    self.selectedValues.model_st_ry = model_ry or self.selectedValues.model_st_ry;
    self.selectedValues.model_st_rz = model_rz or self.selectedValues.model_st_rz;

    self.selectedValues.model_st_us = model_us or self.selectedValues.model_st_us;

    WeakAuras.SetModel(self.model, self.selectedValues.model_path, self.selectedValues.model_fileId)
    self.model:SetTransform(self.selectedValues.model_st_tx / 1000, self.selectedValues.model_st_ty / 1000, self.selectedValues.model_st_tz / 1000,
      rad(self.selectedValues.model_st_rx), rad(self.selectedValues.model_st_ry), rad(self.selectedValues.model_st_rz),
      self.selectedValues.model_st_us / 1000);
    if(self.baseObject.controlledChildren) then
      for index, childId in pairs(self.baseObject.controlledChildren) do
        local childData = WeakAuras.GetData(childId)
        local object = valueFromPath(childData, self.path)
        if(object) then
          SetStOnObject(object, model_path, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
          WeakAuras.Add(childData);
          WeakAuras.UpdateThumbnail(childData);
        end
      end
    else
      local object = valueFromPath(self.baseObject, self.path)
      if object then
        SetStOnObject(object, model_path, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
        WeakAuras.Add(self.baseObject)
        WeakAuras.UpdateThumbnail(self.baseObject)
      end
    end
  end

  local function SetOnObject(object, model_path, model_fileId, model_z, model_x, model_y)
    if model_path then
      object.model_path = model_path
    end
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
  end

  function group.Pick(self, model_path, model_fileId, model_z, model_x, model_y)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath

    self.selectedValues.model_path = model_path or self.selectedValues.model_path
    self.selectedValues.model_fileId = model_fileId or self.selectedValues.model_fileId
    self.selectedValues.model_x = model_x or self.selectedValues.model_x
    self.selectedValues.model_y = model_y or self.selectedValues.model_y
    self.selectedValues.model_z = model_z or self.selectedValues.model_z

    WeakAuras.SetModel(self.model, self.selectedValues.model_path, self.selectedValues.model_fileId)

    self.model:ClearTransform();
    self.model:SetPosition(self.selectedValues.model_z, self.selectedValues.model_x, self.selectedValues.model_y);
    self.model:SetFacing(rad(self.selectedValues.rotation));

    if(self.baseObject.controlledChildren) then
      for index, childId in pairs(self.baseObject.controlledChildren) do
        local childData = WeakAuras.GetData(childId)
        local object = valueFromPath(childData, self.path)
        if(object) then
          SetOnObject(object, model_path, model_fileId, model_z, model_x, model_y)
          WeakAuras.Add(childData)
          WeakAuras.UpdateThumbnail(childData)
        end
      end
    else
      local object = valueFromPath(self.baseObject, self.path)
      if object then
        SetOnObject(object, model_path, model_fileId, model_z, model_x, model_y)
        WeakAuras.Add(self.baseObject)
        WeakAuras.UpdateThumbnail(self.baseObject)
      end
    end
  end

  function group.Open(self, baseObject, path)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath

    self.baseObject = baseObject
    self.path = path
    self.selectedValues = {}

    self.selectedValues.model_path = GetAll(baseObject, path, "model_path", "spells/arcanepower_state_chest.m2")
    self.selectedValues.model_fileId = GetAll(baseObject, path, "model_fileId", "122968")

    WeakAuras.SetModel(self.model, self.selectedValues.model_path, self.selectedValues.model_fileId)

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
      self.model:SetTransform(self.selectedValues.model_st_tx / 1000, self.selectedValues.model_st_ty / 1000, self.selectedValues.model_st_tz / 1000,
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

      modelPickerZ.frame:Show();
      modelPickerY.frame:Show();
      modelPickerX.frame:Show();

      modelPickerTX.frame:Hide();
      modelPickerTY.frame:Hide();
      modelPickerTZ.frame:Hide();
      modelPickerRX.frame:Hide();
      modelPickerRY.frame:Hide();
      modelPickerRZ.frame:Hide();
      modelPickerUS.frame:Hide();
    end

    if(baseObject.controlledChildren) then
      self.givenModel = {};
      self.givenApi = {};
      self.givenZ = {};
      self.givenX = {};
      self.givenY = {};
      self.givenTX = {};
      self.givenTY = {};
      self.givenTZ = {};
      self.givenRX = {};
      self.givenRY = {};
      self.givenRZ = {};
      self.givenUS = {};
      for index, childId in pairs(baseObject.controlledChildren) do
        local childData = WeakAuras.GetData(childId)
        local object = valueFromPath(childData, path)
        if(object) then
          self.givenModel[childId] = object.model_path;
          self.givenApi[childId] = object.api;
          if (object.api) then
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
          end
        end
      end
    else
      local object = valueFromPath(baseObject, path)

      self.givenModel = object.model_path;
      self.givenModelId = object.model_fileId;
      self.givenApi = object.api;

      if (object.api) then
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

  function group.CancelClose(self)
    local valueFromPath = OptionsPrivate.Private.ValueFromPath
    if(group.baseObject.controlledChildren) then
      for index, childId in pairs(group.baseObject.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        local object = valueFromPath(childData, self.path)
        if(object) then
          object.model_path = group.givenModel[childId];
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
          end
          WeakAuras.Add(childData);
          WeakAuras.UpdateThumbnail(childData);
        end
      end
    else
      local object = valueFromPath(self.baseObject, self.path)

      if(object) then
        object.model_path = group.givenModel
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
        end
        WeakAuras.Add(self.baseObject);
        WeakAuras.UpdateThumbnail(self.baseObject);
      end
    end
    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", group.CancelClose);
  cancel:SetPoint("bottomright", frame, "bottomright", -27, 16);
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

function OptionsPrivate.ModelPicker(frame)
  modelPicker = modelPicker or ConstructModelPicker(frame)
  return modelPicker
end
