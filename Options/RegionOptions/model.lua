local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- GLOBALS: WeakAuras UIParent AceGUIWidgetLSMlists

-- Create region options table
local function createOptions(id, data)
    local options = {
        model_path = {
            type = "input",
            width = "double",
            name = L["Model"],
            order = 0
        },
        modelIsUnit = {
            type = "toggle",
            name = L["Show model of unit "],
            order = 3
        },
        portraitZoom = {
            type = "toggle",
            name = L["Portrait Zoom"],
            order = 4,
            hidden = function() return not data.modelIsUnit end
        },
        space2 = {
            type = "execute",
            name = "",
            width = "half",
            order = 5,
            image = function() return "", 0, 0 end,
            hidden = function() return data.modelIsUnit end
        },
        chooseModel = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 7,
            func = function()
                WeakAuras.OpenModelPick(data, "model_path");
            end,
            hidden = function() return data.modelIsUnit end
        },
        model_z = {
            type = "range",
            name = L["Z Offset"],
            softMin = -20,
            softMax = 20,
            step = .001,
            bigStep = 0.05,
            order = 20,
        },
        model_x = {
            type = "range",
            name = L["X Offset"],
            softMin = -20,
            softMax = 20,
            step = .001,
            bigStep = 0.05,
            order = 30,
        },
        model_y = {
            type = "range",
            name = L["Y Offset"],
            softMin = -20,
            softMax = 20,
            step = .001,
            bigStep = 0.05,
            order = 40,
        },
        advance = {
            type = "toggle",
            name = L["Animate"],
            order = 25,
        },
        sequence = {
            type = "range",
            name = L["Animation Sequence"],
            min = 0,
            max = 150,
            step = 1,
            bigStep = 1,
            order = 35,
            disabled = function() return not data.advance end
        },
        rotation = {
            type = "range",
            name = L["Rotation"],
            min = 0,
            max = 360,
            step = 1,
            bigStep = 3,
            order = 45
        },
		border_header = {
			type = "header",
			name = L["Border Settings"],
			order = 46
		},
        spacer = {
            type = "header",
            name = "",
            order = 50
        }
    };

	--
    options = WeakAuras.AddPositionOptions(options, id, data);

	--
	options = WeakAuras.AddBorderOptions(options, id, data);

	--
    return options;
end

local function createThumbnail(parent, fullCreate)
    local borderframe = CreateFrame("FRAME", nil, parent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);

    local border = borderframe:CreateTexture(nil, "Overlay");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

    local model = CreateFrame("PlayerModel", nil, WeakAuras.OptionsFrame() or UIParent);
    borderframe.model = model;
    model:SetFrameStrata("FULLSCREEN");

    return borderframe;
end

local function modifyThumbnail(parent, region, data, fullModify, size)
    local model = region.model
    model:SetParent(region);
    model:SetAllPoints(region);
    model:SetFrameStrata(region:GetParent():GetFrameStrata());
    model:SetWidth(region:GetWidth() - 2);
    model:SetHeight(region:GetHeight() - 2);
    model:SetPoint("center", region, "center");
	if tonumber(data.model_path) then
		model:SetDisplayInfo(tonumber(data.model_path))
	else
		if (data.modelIsUnit) then
			model:SetUnit(data.model_path)
		else
			pcall(function() model:SetModel(data.model_path) end);
		end
	end
    model:SetScript("OnShow", function()
		if tonumber(data.model_path) then
			model:SetDisplayInfo(tonumber(data.model_path))
		else
			if (data.modelIsUnit) then
				model:SetUnit(data.model_path)
			else
				pcall(function() model:SetModel(data.model_path) end);
			end
		end
    end);
    model:SetPosition(data.model_z, data.model_x, data.model_y);
    model:SetFacing(rad(data.rotation));
end

local function createIcon()
    local data = {
        model_path = "Creature/Arthaslichking/arthaslichking.m2",
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

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 50);

    return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    data = {
    };
  },
  {
    title = L["Fire Orb"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      model_path = "spells/6fx_smallfire.m2",
      model_x = 0,
      model_y = -0.5,
      model_z = -1.5
    },
  },
  {
    title = L["Blue Sparkle Orb"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_druid_halfmoon_missile.m2",
      model_x = 0,
      model_y = 0.7,
      model_z = 1.5
    },
  },
  {
    title = L["Arcane Orb"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/proc_arcane_impact_low.m2",
      model_x = 0,
      model_y = 0.8,
      model_z = 2
    },
  },
  {
    title = L["Orange Rune"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_godking_orangerune_state.m2",
    },
  },
  {
    title = L["Blue Rune"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_godking_bluerune_state.m2",
    }
  },
  {
    title = L["Yellow Rune"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_godking_yellowrune_state.m2",
    }
  },
  {
    title = L["Purple Rune"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_godking_purplerune_state.m2",
    }
  },
  {
    title = L["Green Rune"],
    description = L[""],
    data = {
      width = 100,
      height = 100,
      advance = true,
      sequence = 1,
      model_path = "spells/7fx_godking_greenrune_state.m2",
    }
  },
}

WeakAuras.RegisterRegionOptions("model", createOptions, createIcon, L["Model"], createThumbnail, modifyThumbnail, L["Shows a 3D model from the game files"], templates);
