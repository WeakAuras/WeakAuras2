if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L;

local function createOptions(id, data)
  local options = {
    __title = L["Model Settings"],
    __order = 1,
    modelIsUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show model of unit "],
      order = 0.5,
      hidden = function() return data.modelDisplayInfo and WeakAuras.BuildInfo > 80100 end
    },
    modelDisplayInfo = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Use Display Info Id"],
      order = 0.6,
      hidden = function() return data.modelIsUnit end
    },
    model_fileId = {
      type = "input",
      width = WeakAuras.doubleWidth - 0.15,
      name = L["Model"],
      order = 1
    },
    chooseModel = {
      type = "execute",
      width = 0.15,
      name = L["Choose"],
      order = 2,
      func = function()
        OptionsPrivate.OpenModelPicker(data, {});
      end,
      disabled = function() return data.modelIsUnit or (WeakAuras.BuildInfo > 80100 and data.modelDisplayInfo) end,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    advance = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Animate"],
      order = 5,
    },
    sequence = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Animation Sequence"],
      min = 0,
      softMax = 1499,
      step = 1,
      bigStep = 1,
      order = 6,
      disabled = function() return not data.advance end
    },
    api = {
      type = "toggle",
      name = L["Use SetTransform"],
      order = 7,
      width = WeakAuras.normalWidth,
    },
    portraitZoom = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Portrait Zoom"],
      order = 8,
    },
    -- old settings
    model_z = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Z Offset"],
      softMin = -20,
      softMax = 20,
      step = .001,
      bigStep = 0.05,
      order = 20,
      hidden = function() return data.api end
    },
    model_x = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["X Offset"],
      softMin = -20,
      softMax = 20,
      step = .001,
      bigStep = 0.05,
      order = 30,
      hidden = function() return data.api end
    },
    model_y = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Y Offset"],
      softMin = -20,
      softMax = 20,
      step = .001,
      bigStep = 0.05,
      order = 40,
      hidden = function() return data.api end
    },
    rotation = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      min = 0,
      max = 360,
      step = 1,
      bigStep = 3,
      order = 45,
      hidden = function() return data.api end
    },
    -- New Settings
    model_st_tx = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["X Offset"],
      softMin = -1000,
      softMax = 1000,
      step = 1,
      bigStep = 5,
      order = 20,
      hidden = function() return not data.api end
    },
    model_st_ty = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Y Offset"],
      softMin = -1000,
      softMax = 1000,
      step = 1,
      bigStep = 5,
      order = 21,
      hidden = function() return not data.api end
    },
    model_st_tz = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Z Offset"],
      softMin = -1000,
      softMax = 1000,
      step = 1,
      bigStep = 5,
      order = 22,
      hidden = function() return not data.api end
    },
    model_st_rx = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["X Rotation"],
      min = 0,
      max = 360,
      step = 1,
      bigStep = 3,
      order = 23,
      hidden = function() return not data.api end
    },
    model_st_ry = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Y Rotation"],
      min = 0,
      max = 360,
      step = 1,
      bigStep = 3,
      order = 24,
      hidden = function() return not data.api end
    },
    model_st_rz = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Z Rotation"],
      min = 0,
      max = 360,
      step = 1,
      bigStep = 3,
      order = 25,
      hidden = function() return not data.api end
    },
    model_st_us = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Scale"],
      min = 5,
      max = 1000,
      step = 0.1,
      bigStep = 5,
      order = 26,
      hidden = function() return not data.api end
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  for k, v in pairs(OptionsPrivate.commonOptions.BorderOptions(id, data, nil, nil, 70)) do
    options[k] = v
  end

  return {
    model = options,
    position = OptionsPrivate.commonOptions.PositionOptions(id, data, nil, nil, nil),
  };
end

-- Duplicated because Private does not exist when we want to create the first thumbnail
local function ModelSetTransformFixed(self, tx, ty, tz, rx, ry, rz, s)
  -- In Dragonflight the api changed, this converts to the new api
  self:SetTransform(CreateVector3D(tx, ty, tz), CreateVector3D(rx, ry, rz), -s)
end

local function createThumbnail()
    ---@class frame
  local borderframe = CreateFrame("Frame", nil, UIParent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  local border = borderframe:CreateTexture(nil, "Overlay");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  ---@class Model
  local model = CreateFrame("PlayerModel", nil, borderframe);
  borderframe.model = model;
  model.SetTransformFixed = ModelSetTransformFixed
  model:SetFrameStrata("FULLSCREEN");

  return borderframe;
end

local function modifyThumbnail(parent, region, data)
  region:SetParent(parent)

  local model = region.model

  model:SetAllPoints(region);
  model:SetFrameStrata(region:GetParent():GetFrameStrata());
  model:SetWidth(region:GetWidth() - 2);
  model:SetHeight(region:GetHeight() - 2);
  model:SetPoint("center", region, "center");
  WeakAuras.SetModel(model, nil, data.model_fileId, data.modelIsUnit, data.modelDisplayInfo)
  model:SetScript("OnShow", function()
    WeakAuras.SetModel(model, nil, data.model_fileId, data.modelIsUnit, data.modelDisplayInfo)
    model:SetPortraitZoom(data.portraitZoom and 1 or 0)
    if data.api then
      model:SetTransformFixed(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
        rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
        data.model_st_us / 1000);
    else
      model:ClearTransform();
      model:SetPosition(data.model_z, data.model_x, data.model_y);
      model:SetFacing(rad(data.rotation));
    end
  end);

  if data.api then
    model:SetTransformFixed(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
      rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
      data.model_st_us / 1000);
  else
    model:SetPosition(data.model_z, data.model_x, data.model_y);
    model:SetFacing(rad(data.rotation));
  end
end

local function createIcon()
  local data = {
    model_fileId = WeakAuras.IsClassic() and "165589" or "122968", -- spells/arcanepower_state_chest.m2 & Creature/Arthaslichking/arthaslichking.m2
    modelIsUnit = false,
    model_x = 0,
    model_y = 0,
    model_z = 0.35,
    sequence = 1,
    advance = false,
    rotation = 0,
    scale = 1,
    height = 40,
    width = 40
  };

  local thumbnail = createThumbnail();
  modifyThumbnail(UIParent, thumbnail, data);

  return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    data = {
    };
  }
}

if WeakAuras.IsRetail() then
  tinsert(templates, {
    title = L["Fire Orb"],
    description = "",
    data = {
      width = 100,
      height = 100,
      model_fileId = "937416", -- spells/6fx_smallfire.m2
      model_x = 0,
      model_y = -0.5,
      model_z = -1.5
    },
  })
  tinsert(templates, {
    title = L["Blue Sparkle Orb"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1322288", -- spells/7fx_druid_halfmoon_missile.m2
      model_x = 0,
      model_y = 0.7,
      model_z = 1.5
    },
  })
  tinsert(templates, {
    title = L["Arcane Orb"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1042743", -- spells/proc_arcane_impact_low.m2
      model_x = 0,
      model_y = 0.8,
      model_z = 2
    },
  })
  tinsert(templates, {
    title = L["Orange Rune"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1307356", -- spells/7fx_godking_orangerune_state.m2
    },
  })
  tinsert(templates, {
    title = L["Blue Rune"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1307354", -- spells/7fx_godking_bluerune_state.m2
    }
  })
  tinsert(templates, {
    title = L["Yellow Rune"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1307358", -- spells/7fx_godking_yellowrune_state.m2
    }
  })
  tinsert(templates, {
    title = L["Purple Rune"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1307355", -- spells/7fx_godking_purplerune_state.m2
    }
  })
  tinsert(templates, {
    title = L["Green Rune"],
    description = "",
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_fileId = "1307357", -- spells/7fx_godking_greenrune_state.m2
    }
  })
end

OptionsPrivate.registerRegions = OptionsPrivate.registerRegions or {}
table.insert(OptionsPrivate.registerRegions, function()
  OptionsPrivate.Private.RegisterRegionOptions("model", createOptions, createIcon, L["Model"], createThumbnail, modifyThumbnail,
                                  L["Shows a 3D model from the game files"], templates);
end)
