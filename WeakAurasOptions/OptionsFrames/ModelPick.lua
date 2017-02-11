-- Lua APIs
local select, pairs, next, type, unpack, rad = select, pairs, next, type, unpack, rad

-- WoW APIs
local CreateFrame = CreateFrame

-- GLOBALS: WeakAuras

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local modelPick

local function ConstructModelPick(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 87);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group:SetLayout("flow");

  -- Old X Y Z controls
  local modelPickZ = AceGUI:Create("Slider");
  modelPickZ:SetSliderValues(-20, 20, 0.05);
  modelPickZ:SetLabel(L["Z Offset"]);
  modelPickZ.frame:SetParent(group.frame);
  modelPickZ:SetCallback("OnValueChanged", function()
    group:Pick(nil, modelPickZ:GetValue());
  end);

  local modelPickX = AceGUI:Create("Slider");
  modelPickX:SetSliderValues(-20, 20, 0.05);
  modelPickX:SetLabel(L["X Offset"]);
  modelPickX.frame:SetParent(group.frame);
  modelPickX:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, modelPickX:GetValue());
  end);

  local modelPickY = AceGUI:Create("Slider");
  modelPickY:SetSliderValues(-20, 20, 0.05);
  modelPickY:SetLabel(L["Y Offset"]);
  modelPickY.frame:SetParent(group.frame);
  modelPickY:SetCallback("OnValueChanged", function()
    group:Pick(nil, nil, nil, modelPickY:GetValue());
  end);

  -- New TX TY TZ, RX, RY, RZ, US controls
  local modelPickTX = AceGUI:Create("Slider");
  modelPickTX:SetSliderValues(-1000, 1000, 1);
  modelPickTX:SetLabel(L["X Offset"]);
  modelPickTX.frame:SetParent(group.frame);
  modelPickTX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, modelPickTX:GetValue());
  end);

  local modelPickTY = AceGUI:Create("Slider");
  modelPickTY:SetSliderValues(-1000, 1000, 1);
  modelPickTY:SetLabel(L["Y Offset"]);
  modelPickTY.frame:SetParent(group.frame);
  modelPickTY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, modelPickTY:GetValue());
  end);

  local modelPickTZ = AceGUI:Create("Slider");
  modelPickTZ:SetSliderValues(-1000, 1000, 1);
  modelPickTZ:SetLabel(L["Z Offset"]);
  modelPickTZ.frame:SetParent(group.frame);
  modelPickTZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, modelPickTZ:GetValue());
  end);

  local modelPickRX = AceGUI:Create("Slider");
  modelPickRX:SetSliderValues(0, 360, 1);
  modelPickRX:SetLabel(L["X Rotation"]);
  modelPickRX.frame:SetParent(group.frame);
  modelPickRX:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, modelPickRX:GetValue());
  end);

  local modelPickRY = AceGUI:Create("Slider");
  modelPickRY:SetSliderValues(0, 360, 1);
  modelPickRY:SetLabel(L["Y Rotation"]);
  modelPickRY.frame:SetParent(group.frame);
  modelPickRY:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, modelPickRY:GetValue());
  end);

  local modelPickRZ = AceGUI:Create("Slider");
  modelPickRZ:SetSliderValues(0, 360, 1);
  modelPickRZ:SetLabel(L["Z Rotation"]);
  modelPickRZ.frame:SetParent(group.frame);
  modelPickRZ:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, modelPickRZ:GetValue());
  end);

  local modelPickUS = AceGUI:Create("Slider");
  modelPickUS:SetSliderValues(5, 1000, 1);
  modelPickUS:SetLabel(L["Scale"]);
  modelPickUS.frame:SetParent(group.frame);
  modelPickUS:SetCallback("OnValueChanged", function()
    group:PickSt(nil, nil, nil, nil, nil, nil, nil, modelPickUS:GetValue());
  end);

  local modelTree = AceGUI:Create("TreeGroup");
  group.modelTree = modelTree;
  group.frame:SetScript("OnUpdate", function()
    local frameWidth = frame:GetWidth();
    local sliderWidth = (frameWidth - 50) / 3;
    local narrowSliderWidth = (frameWidth - 50) / 7;

    modelTree:SetTreeWidth(frameWidth - 370);

    modelPickZ.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickZ.frame:SetPoint("bottomright", frame, "bottomleft", 15 + sliderWidth, 43);

    modelPickX.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + sliderWidth, 43);
    modelPickX.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (2 * sliderWidth), 43);

    modelPickY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (2 * sliderWidth), 43);
    modelPickY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (3 * sliderWidth), 43);

    -- New controls
    modelPickTX.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickTX.frame:SetPoint("bottomright", frame, "bottomleft", 15 + narrowSliderWidth, 43);

    modelPickTY.frame:SetPoint("bottomleft", frame, "bottomleft", 20 + narrowSliderWidth, 43);
    modelPickTY.frame:SetPoint("bottomright", frame, "bottomleft", 20 + (2 * narrowSliderWidth), 43);

    modelPickTZ.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + (2 * narrowSliderWidth), 43);
    modelPickTZ.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (3 * narrowSliderWidth), 43);

    modelPickRX.frame:SetPoint("bottomleft", frame, "bottomleft", 30 + (3 * narrowSliderWidth), 43);
    modelPickRX.frame:SetPoint("bottomright", frame, "bottomleft", 30 + (4 * narrowSliderWidth), 43);

    modelPickRY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (4 * narrowSliderWidth), 43);
    modelPickRY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (5 * narrowSliderWidth), 43);

    modelPickRZ.frame:SetPoint("bottomleft", frame, "bottomleft", 40 + (5 * narrowSliderWidth), 43);
    modelPickRZ.frame:SetPoint("bottomright", frame, "bottomleft", 40 + (6 * narrowSliderWidth), 43);

    modelPickUS.frame:SetPoint("bottomleft", frame, "bottomleft", 45 + (6 * narrowSliderWidth), 43);
    modelPickUS.frame:SetPoint("bottomright", frame, "bottomleft", 45 + (7 * narrowSliderWidth), 43);

  end);
  group:SetLayout("fill");
  modelTree:SetTree(WeakAuras.ModelPaths);
  modelTree:SetCallback("OnGroupSelected", function(self, event, value)
    local path = string.gsub(value, "\001", "/");
    if(string.lower(string.sub(path, -3, -1)) == ".m2") then
      local model_path = path;
      if (group.givenApi) then
        group:PickSt(model_path);
      else
        group:Pick(model_path);
      end
    end
  end);
  group:AddChild(modelTree);

  local model = CreateFrame("PlayerModel", nil, group.content);
  model:SetAllPoints(modelTree.content);
  model:SetFrameStrata("FULLSCREEN");
  group.model = model;

  function group.PickSt(self, model_path, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    model_path = model_path or self.data.model_path;
    model_tx = model_tx or self.data.model_st_tx;
    model_ty = model_ty or self.data.model_st_ty;
    model_tz = model_tz or self.data.model_st_tz;

    model_rx = model_rx or self.data.model_st_rx;
    model_ry = model_ry or self.data.model_st_ry;
    model_rz = model_rz or self.data.model_st_rz;

    model_us = model_us or self.data.model_st_us;

    if tonumber(model_path) then
      self.model:SetDisplayInfo(tonumber(model_path))
    else
      self.model:SetModel(model_path);
    end
    self.model:SetTransform(model_tx / 1000, model_ty / 1000, model_tz / 1000,
                            rad(model_rx), rad(model_ry), rad(model_rz),
                            model_us / 1000);
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
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
      self.data.model_st_tx = model_tx;
      self.data.model_st_ty = model_ty;
      self.data.model_st_tz = model_tz;
      self.data.model_st_rx = model_rx;
      self.data.model_st_ry = model_ry;
      self.data.model_st_rz = model_rz;
      self.data.model_st_us = model_us;
      WeakAuras.Add(self.data);
      WeakAuras.SetThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
  end

  function group.Pick(self, model_path, model_z, model_x, model_y)
    model_path = model_path or self.data.model_path;
    model_z = model_z or self.data.model_z;
    model_x = model_x or self.data.model_x;
    model_y = model_y or self.data.model_y;

    if tonumber(model_path) then
      self.model:SetDisplayInfo(tonumber(model_path))
    else
      self.model:SetModel(model_path);
    end
    self.model:ClearTransform();
    self.model:SetPosition(model_z, model_x, model_y);
    self.model:SetFacing(rad(self.data.rotation));
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
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
      self.data.model_z = model_z;
      self.data.model_x = model_x;
      self.data.model_y = model_y;
      WeakAuras.Add(self.data);
      WeakAuras.SetThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
  end

  function group.Open(self, data)
    self.data = data;
    if tonumber(data.model_path) then
      model:SetDisplayInfo(tonumber(data.model_path))
    else
      model:SetModel(data.model_path);
    end
    if (data.api) then
      self.model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
                              rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
                              data.model_st_us / 1000);

      modelPickTX:SetValue(data.model_st_tx);
      modelPickTX.editbox:SetText(("%.2f"):format(data.model_st_tx));
      modelPickTY:SetValue(data.model_st_ty);
      modelPickTY.editbox:SetText(("%.2f"):format(data.model_st_ty));
      modelPickTZ:SetValue(data.model_st_tz);
      modelPickTZ.editbox:SetText(("%.2f"):format(data.model_st_tz));

      modelPickRX:SetValue(data.model_st_rx);
      modelPickRX.editbox:SetText(("%.2f"):format(data.model_st_rx));
      modelPickRY:SetValue(data.model_st_ry);
      modelPickRY.editbox:SetText(("%.2f"):format(data.model_st_ry));
      modelPickRZ:SetValue(data.model_st_rz);
      modelPickRZ.editbox:SetText(("%.2f"):format(data.model_st_rz));

      modelPickUS:SetValue(data.model_st_us);
      modelPickUS.editbox:SetText(("%.2f"):format(data.model_st_us));

      modelPickZ.frame:Hide();
      modelPickY.frame:Hide();
      modelPickX.frame:Hide();

      modelPickTX.frame:Show();
      modelPickTY.frame:Show();
      modelPickTZ.frame:Show();
      modelPickRX.frame:Show();
      modelPickRY.frame:Show();
      modelPickRZ.frame:Show();
      modelPickUS.frame:Show();

    else
      self.model:ClearTransform();
      self.model:SetPosition(data.model_z, data.model_x, data.model_y);
      self.model:SetFacing(rad(data.rotation));
      modelPickZ:SetValue(data.model_z);
      modelPickZ.editbox:SetText(("%.2f"):format(data.model_z));
      modelPickX:SetValue(data.model_x);
      modelPickX.editbox:SetText(("%.2f"):format(data.model_x));
      modelPickY:SetValue(data.model_y);
      modelPickY.editbox:SetText(("%.2f"):format(data.model_y));

      modelPickZ.frame:Show();
      modelPickY.frame:Show();
      modelPickX.frame:Show();

      modelPickTX.frame:Hide();
      modelPickTY.frame:Hide();
      modelPickTZ.frame:Hide();
      modelPickRX.frame:Hide();
      modelPickRY.frame:Hide();
      modelPickRZ.frame:Hide();
      modelPickUS.frame:Hide();
    end

    if(data.controlledChildren) then
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
    if(group.data.controlledChildren) then
      for index, childId in pairs(group.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = group.givenModel[childId];
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
        group:PickSt(group.givenPath, group.givenTX, group.givenTY, group.givenTZ,
                         group.givenRX, group.givenRY, group.givenRZ, group.givenUS );
      else
        group:Pick(group.givenPath, group.givenZ, group.givenX, group.givenY);
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

function WeakAuras.ModelPick(frame)
  modelPick = modelPick or ConstructModelPick(frame)
  return modelPick
end
