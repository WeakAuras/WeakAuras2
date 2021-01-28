local L = WeakAuras.L
local AddonName, OptionsPrivate = ...

local texture_types = WeakAuras.StopMotion.texture_types;
local texture_data = WeakAuras.StopMotion.texture_data;
local animation_types = WeakAuras.StopMotion.animation_types;
local setTile = WeakAuras.setTile;

local function setTextureFunc(textureWidget, texturePath, textureName)
  local data = texture_data[texturePath];
  textureWidget.frameNr = 0;
  if (data) then
      if (data.rows and data.columns) then
        -- Texture Atlas
        textureWidget:SetTexture(texturePath, textureName);

        setTile(textureWidget, data.count, data.rows, data.columns);

        textureWidget:SetOnUpdate(function()
          textureWidget.frameNr = textureWidget.frameNr + 1;
          if (textureWidget.frameNr == data.count) then
            textureWidget.frameNr = 1;
          end
          setTile(textureWidget, textureWidget.frameNr, data.rows, data.columns);
        end);
      else
        -- Numbered Textures
        local texture = texturePath .. format("%03d", texture_data[texturePath].count)
        textureWidget:SetTexture(texture, textureName)
        textureWidget:SetTexCoord(0, 1, 0, 1);

        textureWidget:SetOnUpdate(function()
          textureWidget.frameNr = textureWidget.frameNr + 1;
          if (textureWidget.frameNr == data.count) then
            textureWidget.frameNr = 1;
          end
          local texture = texturePath .. format("%03d", textureWidget.frameNr)
          textureWidget:SetTexture(texture, textureName);
        end);
      end
  else
    local texture = texturePath .. format("%03d", 1)
    textureWidget:SetTexture(texture, textureName);
  end
end

local function textureNameHasData(textureName)
  local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
  local rows, columns, frames = textureName:lower():match(pattern)
  return rows and columns and frames
end

local function createOptions(id, data)
    local options = {
        __title = L["Stop Motion Settings"],
        __order = 1,
        foregroundTexture = {
            type = "input",
            width = WeakAuras.normalWidth - 0.15,
            name = L["Texture"],
            order = 1,
        },
        chooseForegroundTexture = {
            type = "execute",
            width = 0.15,
            name = L["Choose"],
            order = 2,
            func = function()
                OptionsPrivate.OpenTexturePicker(data, {}, {
                  texture = "foregroundTexture",
                  color = "foregroundColor",
                  rotation = "rotation",
                  mirror = "mirror",
                  blendMode = "blendMode"
                }, texture_types, setTextureFunc);
            end,
            imageWidth = 24,
            imageHeight = 24,
            control = "WeakAurasIcon",
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
        },
        backgroundTexture = {
            type = "input",
            width = WeakAuras.normalWidth - 0.15,
            name = L["Background Texture"],
            order = 5,
            disabled = function() return data.sameTexture or data.hideBackground  end,
            get = function() return data.sameTexture and data.foregroundTexture or data.backgroundTexture; end,
        },
        chooseBackgroundTexture = {
            type = "execute",
            width = 0.15,
            name = L["Choose"],
            order = 6,
            func = function()
                OptionsPrivate.OpenTexturePicker(data, {}, {
                  texture = "backgroundTexture",
                  color = "backgroundColor",
                  rotation = "rotation",
                  mirror = "mirror",
                  blendMode = "blendMode"
                }, texture_types, setTextureFunc);
            end,
            disabled = function() return data.sameTexture or data.hideBackground; end,
            imageWidth = 24,
            imageHeight = 24,
            control = "WeakAurasIcon",
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
        },
        sameTextureSpace = {
            type = "description",
            width = WeakAuras.normalWidth,
            name = "",
            order = 13,
        },
        hideBackground = {
          type = "toggle",
          name = L["Hide"],
          order = 14,
          width = WeakAuras.halfWidth,
        },
        sameTexture = {
            type = "toggle",
            width = WeakAuras.halfWidth,
            name = L["Same"],
            order = 15,
            disabled = function() return data.hideBackground; end
        },
        desaturateForeground = {
            type = "toggle",
            width = WeakAuras.normalWidth,
            name = L["Desaturate"],
            order = 17.5,
        },
        desaturateBackground = {
            type = "toggle",
            name = L["Desaturate"],
            order = 17.6,
            width = WeakAuras.normalWidth,
            disabled = function() return data.hideBackground; end
        },
        -- Foreground options for custom textures
        customForegroundHeader = {
            type = "header",
            name = L["Custom Foreground"],
            order = 17.70,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundRows = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Rows"],
            min = 1,
            max = 64,
            order = 17.71,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundColumns = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Columns"],
            min = 1,
            max = 64,
            order = 17.72,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFrames = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Frame Count"],
            min = 0,
            max = 4096,
            --bigStep = 0.01,
            order = 17.73,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundSpace = {
            type = "execute",
            width = WeakAuras.normalWidth,
            name = "",
            order = 17.74,
            image = function() return "", 0, 0 end,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        -- Background options for custom textures
        customBackgroundHeader = {
            type = "header",
            name = L["Custom Background"],
            order = 18.00,
            hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture)
                                       or data.hideBackground end
        },
        customBackgroundRows = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Rows"],
            min = 1,
            max = 64,
            order = 18.01,
            hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture)
                                       or data.hideBackground end
        },
        customBackgroundColumns = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Columns"],
            min = 1,
            max = 64,
            order = 18.02,
            hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture)
                                       or data.hideBackground end
        },
        customBackgroundFrames = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Frame Count"],
            min = 0,
            max = 4096,
            step = 1,
            order = 18.03,
            hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture)
                                       or data.hideBackground end
        },
        customBackgroundSpace = {
            type = "execute",
            width = WeakAuras.normalWidth,
            name = "",
            order = 18.04,
            image = function() return "", 0, 0 end,
            hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture)
                                       or data.hideBackground end
        },
        blendMode = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = L["Blend Mode"],
            order = 20,
            values = OptionsPrivate.Private.blend_types
        },
        animationType = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = L["Animation Mode"],
            order = 21,
            values = animation_types
        },
        startPercent = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Animation Start"],
            min = 0,
            max = 1,
            --bigStep = 0.01,
            order = 22,
            isPercent = true
        },
        endPercent = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Animation End"],
            min = 0,
            max = 1,
            --bigStep  = 0.01,
            order = 23,
            isPercent = true
        },
        frameRate = {
           type = "range",
           width = WeakAuras.normalWidth,
           name = L["Frame Rate"],
           min = 3,
           max = 120,
           step = 1,
           bigStep = 3,
           order = 24,
           disabled = function() return data.animationType == "progress" end;
        },
        backgroundPercent = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Background"],
            min = 0,
            max = 1,
            order = 25,
            isPercent = true,
            disabled = function() return data.hideBackground; end
        },
        foregroundColor = {
            type = "color",
            width = WeakAuras.normalWidth,
            name = L["Foreground Color"],
            hasAlpha = true,
            order = 30
        },
        backgroundColor = {
            type = "color",
            width = WeakAuras.normalWidth,
            name = L["Background Color"],
            hasAlpha = true,
            order = 32,
            disabled = function() return data.hideBackground; end
        },
        inverse = {
            type = "toggle",
            width = WeakAuras.normalWidth,
            name = L["Inverse"],
            order = 33
        },
        space3 = {
            type = "execute",
            width = WeakAuras.normalWidth,
            name = "",
            order = 36,
            image = function() return "", 0, 0 end,
        },
    };

    if OptionsPrivate.commonOptions then
      return {
        stopmotion = options,
        position = OptionsPrivate.commonOptions.PositionOptions(id, data, 2),
      };
    else
      return {
        stopmotion = options,
        position = WeakAuras.PositionOptions(id, data, 2),
      };
    end
end

local function createThumbnail()
    local borderframe = CreateFrame("FRAME", nil, UIParent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);

    local border = borderframe:CreateTexture(nil, "OVERLAY");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

    local texture = borderframe:CreateTexture();
    borderframe.texture = texture;
    texture:SetPoint("CENTER", borderframe, "CENTER");

    return borderframe;
end

local function modifyThumbnail(parent, region, data, fullModify, size)
    region:SetParent(parent)

    size = size or 30;
    local scale;
    if(data.height > data.width) then
        scale = size/data.height;
        region.texture:SetWidth(scale * data.width);
        region.texture:SetHeight(size);
    else
        scale = size/data.width;
        region.texture:SetWidth(size);
        region.texture:SetHeight(scale * data.height);
    end

    local frame = 1;

    local tdata = texture_data[data.foregroundTexture];
    if (tdata) then
      local lastFrame = tdata.count - 1;
      region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
      region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
      region.foregroundRows = tdata.rows;
      region.foregroundColumns = tdata.columns;
    else
      local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
      local rows, columns, frames = data.foregroundTexture:lower():match(pattern)
      if rows and columns and frames then
        local lastFrame = frames - 1;
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foregroundRows = rows;
        region.foregroundColumns = columns;
      else
        local lastFrame = data.customForegroundFrames - 1;
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foregroundRows = data.customForegroundRows;
        region.foregroundColumns = data.customForegroundColumns;
      end
    end

    if (region.startFrame and region.endFrame) then
      frame = floor(region.startFrame + (region.endFrame - region.startFrame) * 0.75);
    end

    local texture = data.foregroundTexture or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion";

    if (region.foregroundRows and region.foregroundColumns) then
      region.texture:SetTexture(texture);
      setTile(region.texture, frame, region.foregroundRows, region.foregroundColumns);

      region.SetValue = function(self, percent)
        local frame = floor(percent * (region.endFrame - region.startFrame) + region.startFrame);
        setTile(self.texture, frame, region.foregroundRows, region.foregroundColumns);
      end
    else
      region.texture:SetTexture(texture .. format("%03d", frame));
      region.texture:SetTexCoord(0, 1, 0, 1);

      region.SetValue = function(self, percent)
        local frame = floor(percent * (region.endFrame - region.startFrame) + region.startFrame);
        self.texture:SetTexture((data.foregroundTexture) .. format("%03d", frame));
      end
    end

    region.texture:SetVertexColor(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);
    region.texture:SetBlendMode(data.blendMode);

    region.elapsed = 0;
    region:SetScript("OnUpdate", function(self, elapsed)
        region.elapsed = region.elapsed + elapsed;
        if(region.elapsed > 4) then
            region.elapsed = region.elapsed - 4;
        end
        region:SetValue(region.elapsed / 4);
    end);
end

local function createIcon()
    local data = {
        height = 30,
        width = 30,
        foregroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
        foregroundColor = {1, 1, 1, 1},
        blendMode = "ADD",
        rotate = false,
        rotation = 0,
        startPercent = 0,
        endPercent = 1,
        backgroundPercent = 1,
        animationType = "progress"
    };

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 75);

    thumbnail.elapsed = 0;
    thumbnail:SetScript("OnUpdate", function(self, elapsed)
        thumbnail.elapsed = thumbnail.elapsed + elapsed;
        if(thumbnail.elapsed > 2) then
            thumbnail.elapsed = thumbnail.elapsed - 2;
        end
        thumbnail:SetValue(thumbnail.elapsed / 2);
    end);

    return thumbnail;
end

WeakAuras.RegisterRegionOptions("stopmotion", createOptions, createIcon, L["Stop Motion"], createThumbnail, modifyThumbnail, L["Shows a stop motion texture"]);
