-- Import SM for statusbar-textures, font-styles and border-types
local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Import translation
local L = WeakAuras.L;

-- Create region options table
local function createOptions(id, data)
    local options = {
        model_path = {
            type = "input",
            width = "double",
            name = L["Model"],
            order = 0
        },
        space1 = {
            type = "execute",
            name = "",
            order = 2,
            image = function() return "", 0, 0 end,
        },
        space2 = {
            type = "execute",
            name = "",
            width = "half",
            order = 5,
            image = function() return "", 0, 0 end,
        },
        chooseModel = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 7,
            func = function()
                WeakAuras.OpenModelPick(data, "model_path");
            end
        },
        model_z = {
            type = "range",
            name = L["Z Offset"],
            softMin = -2,
            softMax = 2,
            step = .001,
            bigStep = 0.05,
            order = 20,
        },
        model_x = {
            type = "range",
            name = L["X Offset"],
            softMin = -2,
            softMax = 2,
            step = .001,
            bigStep = 0.05,
            order = 30,
        },
        model_y = {
            type = "range",
            name = L["Y Offset"],
            softMin = -2,
            softMax = 2,
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
    
    if(region:GetFrameStrata() == "TOOLTIP") then
        model:SetParent(region);
        model:SetAllPoints(region);
        model:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        model:SetParent(WeakAuras.OptionsFrame() or UIParent);
        model:ClearAllPoints();
        region:SetScript("OnUpdate", function()
            local x, y = region:GetCenter();
            local optionsFrame = WeakAuras.OptionsFrame();
            if(optionsFrame) then
                model:ClearAllPoints();
                model:SetPoint("center", UIParent, "bottomleft", x, y);
                local scrollBottom = optionsFrame.buttonsContainer.frame:GetBottom();
                local scrollTop = optionsFrame.buttonsContainer.frame:GetTop() and (optionsFrame.buttonsContainer.frame:GetTop() - 16);
                if(
                    optionsFrame.buttonsContainer:IsVisible()
                    and region:GetTop() and scrollTop
                    and region:GetTop() < scrollTop
                    and region:GetBottom() and scrollBottom
                    and region:GetBottom() > scrollBottom
                ) then
                    model:Show();
                else
                    model:Hide();
                end
            else
                model:Hide();
            end
        end);
        region:SetScript("OnShow", function() model:Show() end);
        region:SetScript("OnHide", function() model:Hide() end);
    end
    
    model:SetWidth(region:GetWidth() - 2);
    model:SetHeight(region:GetHeight() - 2);
    model:SetPoint("center", region, "center");
	if tonumber(data.model_path) then
		model:SetDisplayInfo(tonumber(data.model_path))
	else
		model:SetModel(data.model_path);
	end
    model:SetScript("OnShow", function()
		if tonumber(data.model_path) then
			model:SetDisplayInfo(tonumber(data.model_path))
		else
			model:SetModel(data.model_path);
		end
    end);
    model:SetPosition(data.model_z, data.model_x, data.model_y);
    model:SetFacing(rad(data.rotation));
end

local function createIcon()
    local data = {
        model_path = "Creature/Arthaslichking/arthaslichking.m2",
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

WeakAuras.RegisterRegionOptions("model", createOptions, createIcon, L["Model"], createThumbnail, modifyThumbnail, L["Shows a 3D model from the game files"]);