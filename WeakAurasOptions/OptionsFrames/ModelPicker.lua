if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local pairs, rad = pairs, rad

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local modelPicker

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
  group.frame:SetScript("OnUpdate", function()
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
      if (group.givenApi) then
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

  function group.PickSt(self, model_path, model_fileId, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    model_path = model_path or self.data.model_path;
    model_fileId = model_fileId or self.data.model_fileId;
    model_tx = model_tx or self.data.model_st_tx;
    model_ty = model_ty or self.data.model_st_ty;
    model_tz = model_tz or self.data.model_st_tz;

    model_rx = model_rx or self.data.model_st_rx;
    model_ry = model_ry or self.data.model_st_ry;
    model_rz = model_rz or self.data.model_st_rz;

    model_us = model_us or self.data.model_st_us;

    WeakAuras.SetModel(self.model, model_path, model_fileId)
    self.model:SetTransform(model_tx / 1000, model_ty / 1000, model_tz / 1000,
      rad(model_rx), rad(model_ry), rad(model_rz),
      model_us / 1000);
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
          childData.model_fileId = model_fileId;
          childData.model_st_tx = model_tx;
          childData.model_st_ty = model_ty;
          childData.model_st_tz = model_tz;
          childData.model_st_rx = model_rx;
          childData.model_st_ry = model_ry;
          childData.model_st_rz = model_rz;
          childData.model_st_us = model_us;
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data.model_path = model_path;
      self.data.model_fileId = model_fileId;
      self.data.model_st_tx = model_tx;
      self.data.model_st_ty = model_ty;
      self.data.model_st_tz = model_tz;
      self.data.model_st_rx = model_rx;
      self.data.model_st_ry = model_ry;
      self.data.model_st_rz = model_rz;
      self.data.model_st_us = model_us;
      if self.parentData then
        WeakAuras.Add(self.parentData);
      else
        WeakAuras.Add(self.data);
        WeakAuras.SetThumbnail(self.data);
        WeakAuras.SetIconNames(self.data);
      end
    end
  end

  function group.Pick(self, model_path, model_fileId, model_z, model_x, model_y)
    model_path = model_path or self.data.model_path;
    model_fileId = model_fileId or self.data.model_fileId;

    model_z = model_z or self.data.model_z;
    model_x = model_x or self.data.model_x;
    model_y = model_y or self.data.model_y;

    WeakAuras.SetModel(self.model, model_path, model_fileId)

    self.model:ClearTransform();
    self.model:SetPosition(model_z, model_x, model_y);
    self.model:SetFacing(rad(self.data.rotation));

    if(not self.parentData and self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
          childData.model_fileId = model_fileId;
          childData.model_z = model_z;
          childData.model_x = model_x;
          childData.model_y = model_y;
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data.model_path = model_path;
      self.data.model_fileId = model_fileId;
      self.data.model_z = model_z;
      self.data.model_x = model_x;
      self.data.model_y = model_y;

      if self.parentData then
        WeakAuras.Add(self.parentData)
      else
        WeakAuras.Add(self.data);
        WeakAuras.SetThumbnail(self.data);
        WeakAuras.SetIconNames(self.data);
      end
    end
  end

  function group.Open(self, data, parentData)
    self.data = data;
    self.parentData = parentData
    WeakAuras.SetModel(self.model, data.model_path, data.model_fileId)
    if (data.api) then
      self.model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
        rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
        data.model_st_us / 1000);

      modelPickerTX:SetValue(data.model_st_tx);
      modelPickerTX.editbox:SetText(("%.2f"):format(data.model_st_tx));
      modelPickerTY:SetValue(data.model_st_ty);
      modelPickerTY.editbox:SetText(("%.2f"):format(data.model_st_ty));
      modelPickerTZ:SetValue(data.model_st_tz);
      modelPickerTZ.editbox:SetText(("%.2f"):format(data.model_st_tz));

      modelPickerRX:SetValue(data.model_st_rx);
      modelPickerRX.editbox:SetText(("%.2f"):format(data.model_st_rx));
      modelPickerRY:SetValue(data.model_st_ry);
      modelPickerRY.editbox:SetText(("%.2f"):format(data.model_st_ry));
      modelPickerRZ:SetValue(data.model_st_rz);
      modelPickerRZ.editbox:SetText(("%.2f"):format(data.model_st_rz));

      modelPickerUS:SetValue(data.model_st_us);
      modelPickerUS.editbox:SetText(("%.2f"):format(data.model_st_us));

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
      self.model:SetPosition(data.model_z, data.model_x, data.model_y);
      self.model:SetFacing(rad(data.rotation));
      modelPickerZ:SetValue(data.model_z);
      modelPickerZ.editbox:SetText(("%.2f"):format(data.model_z));
      modelPickerX:SetValue(data.model_x);
      modelPickerX.editbox:SetText(("%.2f"):format(data.model_x));
      modelPickerY:SetValue(data.model_y);
      modelPickerY.editbox:SetText(("%.2f"):format(data.model_y));

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

    if(not parentData and data.controlledChildren) then
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
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenModel[childId] = childData.model_path;
          self.givenApi[childId] = childData.api;
          if (childData.api) then
            self.givenTX[childId] = childData.model_st_tx;
            self.givenTY[childId] = childData.model_st_ty;
            self.givenTZ[childId] = childData.model_st_tz;
            self.givenRX[childId] = childData.model_st_rx;
            self.givenRY[childId] = childData.model_st_ry;
            self.givenRZ[childId] = childData.model_st_rz;
            self.givenUS[childId] = childData.model_st_us;
          else
            self.givenZ[childId] = childData.model_z;
            self.givenX[childId] = childData.model_x;
            self.givenY[childId] = childData.model_y;
          end
        end
      end
    else
      self.givenModel = data.model_path;
      self.givenModelId = data.model_fileId;
      self.givenApi = data.api;

      if (data.api) then
        self.givenTX = data.model_st_tx;
        self.givenTY = data.model_st_ty;
        self.givenTZ = data.model_st_tz;
        self.givenRX = data.model_st_rx;
        self.givenRY = data.model_st_ry;
        self.givenRZ = data.model_st_rz;
        self.givenUS = data.model_st_us;
      else
        self.givenZ = data.model_z;
        self.givenX = data.model_x;
        self.givenY = data.model_y;
      end
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "model";
  end

  function group.Close()
    group.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
    AceConfigDialog:Open("WeakAuras", frame.container);
  end

  function group.CancelClose(self)
    if(not group.parentData and group.data.controlledChildren) then
      for index, childId in pairs(group.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = group.givenModel[childId];
          childData.model_fileId = group.givenModelId[childId];
          childData.api = group.givenApi[childId];
          if (childData.api) then
            childData.model_st_tx = group.givenTX[childId];
            childData.model_st_ty = group.givenTY[childId];
            childData.model_st_tz = group.givenTZ[childId];
            childData.model_st_rx = group.givenRX[childId];
            childData.model_st_ry = group.givenRY[childId];
            childData.model_st_rz = group.givenRZ[childId];
            childData.model_st_us = group.givenUS[childId];
          else
            childData.model_z = group.givenZ[childId];
            childData.model_x = group.givenX[childId];
            childData.model_y = group.givenY[childId];
          end
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      if (group.givenApi) then
        group:PickSt(group.givenPath, group.givenPathId, group.givenTX, group.givenTY, group.givenTZ,
          group.givenRX, group.givenRY, group.givenRZ, group.givenUS );
      else
        group:Pick(group.givenPath, group.givenPathId, group.givenZ, group.givenX, group.givenY);
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

function WeakAuras.ModelPicker(frame)
  modelPicker = modelPicker or ConstructModelPicker(frame)
  return modelPicker
end
