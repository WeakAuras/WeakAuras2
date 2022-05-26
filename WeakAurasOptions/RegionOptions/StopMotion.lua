local L = WeakAuras.L
local AddonName, OptionsPrivate = ...

local texture_types = WeakAuras.StopMotion.texture_types;
local texture_data = WeakAuras.StopMotion.texture_data;
local animation_types = WeakAuras.StopMotion.animation_types;
local setTile = WeakAuras.setTile;

local function setTextureFunc(textureWidget, texturePath, textureName)
  local data = texture_data[texturePath];
  if not(data) then
    local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
    local pattern2 = "%.x(%d+)y(%d+)f(%d+)w(%d+)h(%d+)W(%d+)H(%d+)%.[tb][gl][ap]"
    local rows, columns, frames = texturePath:lower():match(pattern)
    if rows then
      data = {
        count = tonumber(frames),
        rows = tonumber(rows),
        columns = tonumber(columns)
      }
    else
      local rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight = texturePath:match(pattern2)
      if rows then
        rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight = tonumber(rows), tonumber(columns), tonumber(frames), tonumber(frameWidth), tonumber(frameHeight), tonumber(fileWidth), tonumber(fileHeight)
        local frameScaleW = 1
        local frameScaleH = 1
        if fileWidth > 0 and frameWidth > 0 then
          frameScaleW = (frameWidth * columns) / fileWidth
        end
        if fileHeight > 0 and frameHeight > 0 then
          frameScaleH = (frameHeight * rows) / fileHeight
        end
        data = {
          count = frames,
          rows = rows,
          columns = columns,
          frameScaleW = frameScaleW,
          frameScaleH = frameScaleH
        }
      end
    end
  end
  textureWidget.frameNr = 0;
  if (data) then
      if (data.rows and data.columns) then
        -- Texture Atlas
        textureWidget:SetTexture(texturePath, textureName);

        setTile(textureWidget, data.count, data.rows, data.columns, data.frameScaleW or 1, data.frameScaleH or 1);

        textureWidget:SetOnUpdate(function(self, elapsed)
          self.elapsed = (self.elapsed or 0) + elapsed
          if(self.elapsed > 0.1) then
            self.elapsed = self.elapsed - 0.1;
            textureWidget.frameNr = textureWidget.frameNr + 1;
            if (textureWidget.frameNr == data.count) then
              textureWidget.frameNr = 1;
            end
            setTile(textureWidget, textureWidget.frameNr, data.rows, data.columns, data.frameScaleW or 1, data.frameScaleH or 1);
          end
        end)
      else
        -- Numbered Textures
        local texture = texturePath .. format("%03d", texture_data[texturePath].count)
        textureWidget:SetTexture(texture, textureName)
        textureWidget:SetTexCoord(0, 1, 0, 1);

        textureWidget:SetOnUpdate(function(self, elapsed)
          self.elapsed = (self.elapsed or 0) + elapsed
          if(self.elapsed > 0.1) then
            self.elapsed = self.elapsed - 0.1;
            textureWidget.frameNr = textureWidget.frameNr + 1;
            if (textureWidget.frameNr == data.count) then
              textureWidget.frameNr = 1;
            end
            local texture = texturePath .. format("%03d", textureWidget.frameNr)
            textureWidget:SetTexture(texture, textureName);
          end
        end);
      end
  else
    local texture = texturePath .. format("%03d", 1)
    textureWidget:SetTexture(texture, textureName);
  end
end

local function textureNameHasData(textureName)
  local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]$"
  local pattern2 = "%.x(%d+)y(%d+)f(%d+)w(%d+)h(%d+)W(%d+)H(%d+)%.[tb][gl][ap]$"
  local ok = textureName:lower():match(pattern)
  if ok then return true end
  local ok2 = textureName:match(pattern2)
  if ok2 then
     return true
  else
     return false
  end
end

local function createOptions(id, data)
    local options = {
        __title = L["Stop Motion Settings"],
        __order = 1,
        foregroundTexture = {
            type = "input",
            width = WeakAuras.doubleWidth - 0.15,
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
        foregroundColor = {
          type = "color",
          width = WeakAuras.normalWidth,
          name = L["Color"],
          hasAlpha = true,
          order = 3
        },
        desaturateForeground = {
          type = "toggle",
          width = WeakAuras.normalWidth,
          name = L["Desaturate"],
          order = 3.5,
        },
        customForegroundRows = {
            type = "input",
            width = WeakAuras.doubleWidth / 3,
            name = L["Rows"],
            validate = WeakAuras.ValidateNumeric,
            get = function()
              return data.customForegroundRows and tostring(data.customForegroundRows) or "";
            end,
            set = function(info, v)
              data.customForegroundRows = v and tonumber(v) or 0
              WeakAuras.Add(data);
              WeakAuras.UpdateThumbnail(data);
            end,
            order = 4,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundColumns = {
            type = "input",
            width = WeakAuras.doubleWidth / 3,
            name = L["Columns"],
            validate = WeakAuras.ValidateNumeric,
            get = function()
              return data.customForegroundColumns and tostring(data.customForegroundColumns) or "";
            end,
            set = function(info, v)
              data.customForegroundColumns = v and tonumber(v) or 0
              WeakAuras.Add(data);
              WeakAuras.UpdateThumbnail(data);
            end,
            order = 5,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFrames = {
            type = "input",
            width = WeakAuras.doubleWidth / 3,
            name = L["Frame Count"],
            validate = WeakAuras.ValidateNumeric,
            get = function()
              return data.customForegroundFrames and tostring(data.customForegroundFrames) or "";
            end,
            set = function(info, v)
              data.customForegroundFrames = v and tonumber(v) or 0
              WeakAuras.Add(data);
              WeakAuras.UpdateThumbnail(data);
            end,
            order = 6,
            hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFileWidth = {
          type = "input",
          width = WeakAuras.normalWidth / 2,
          name = L["File Width"],
          desc = L["Must be a power of 2"],
          validate = function(info, val)
            if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31 or math.frexp(val) ~= 0.5) then
              return false;
            end
            return true
          end,
          get = function()
            return data.customForegroundFileWidth and tostring(data.customForegroundFileWidth) or "";
          end,
          set = function(info, v)
            data.customForegroundFileWidth = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 7,
          hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFileHeight = {
          type = "input",
          width = WeakAuras.normalWidth / 2,
          name = L["File Height"],
          desc = L["Must be a power of 2"],
          validate = function(info, val)
            if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31 or math.frexp(val) ~= 0.5) then
              return false;
            end
            return true
          end,
          get = function()
            return data.customForegroundFileHeight and tostring(data.customForegroundFileHeight) or "";
          end,
          set = function(info, v)
            data.customForegroundFileHeight = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 8,
          hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFrameWidth = {
          type = "input",
          width = WeakAuras.normalWidth / 2,
          name = L["Frame Width"],
          validate = WeakAuras.ValidateNumeric,
          desc = L["Can set to 0 if Columns * Width equal File Width"],
          get = function()
            return data.customForegroundFrameWidth and tostring(data.customForegroundFrameWidth) or "";
          end,
          set = function(info, v)
            data.customForegroundFrameWidth = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 9,
          hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        customForegroundFrameHeight = {
          type = "input",
          width = WeakAuras.normalWidth / 2,
          name = L["Frame Height"],
          validate = WeakAuras.ValidateNumeric,
          desc = L["Can set to 0 if Rows * Height equal File Height"],
          get = function()
            return data.customForegroundFrameHeight and tostring(data.customForegroundFrameHeight) or "";
          end,
          set = function(info, v)
            data.customForegroundFrameHeight = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 10,
          hidden = function() return texture_data[data.foregroundTexture] or textureNameHasData(data.foregroundTexture) end
        },
        blendMode = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = L["Blend Mode"],
            order = 11,
            values = OptionsPrivate.Private.blend_types
        },
        animationType = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = L["Animation Mode"],
            order = 12,
            values = animation_types
        },
        startPercent = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Animation Start"],
            min = 0,
            max = 1,
            --bigStep = 0.01,
            order = 13,
            isPercent = true
        },
        endPercent = {
            type = "range",
            width = WeakAuras.normalWidth,
            name = L["Animation End"],
            min = 0,
            max = 1,
            --bigStep  = 0.01,
            order = 14,
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
           order = 15,
           disabled = function() return data.animationType == "progress" end;
        },
        inverse = {
          type = "toggle",
          width = WeakAuras.normalWidth,
          name = L["Inverse"],
          order = 15.5
        },
        customBackgroundHeader = {
          type = "header",
          name = L["Background Texture"],
          order = 16,
        },
        hideBackground = {
          type = "toggle",
          name = L["Hide Background"],
          order = 17,
          width = WeakAuras.normalWidth,
        },
        sameTexture = {
          type = "toggle",
          width = WeakAuras.normalWidth,
          name = L["Same texture as Foreground"],
          order = 18,
          disabled = function() return data.hideBackground; end,
          hidden = function() return data.hideBackground; end
        },
        backgroundTexture = {
            type = "input",
            width = WeakAuras.doubleWidth - 0.15,
            name = L["Background Texture"],
            order = 19,
            disabled = function() return data.sameTexture or data.hideBackground end,
            hidden = function() return data.hideBackground end,
            get = function() return data.sameTexture and data.foregroundTexture or data.backgroundTexture; end,
        },
        chooseBackgroundTexture = {
            type = "execute",
            width = 0.15,
            name = L["Choose"],
            order = 20,
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
            hidden = function() return data.hideBackground end,
            imageWidth = 24,
            imageHeight = 24,
            control = "WeakAurasIcon",
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
        },
        backgroundColor = {
            type = "color",
            width = WeakAuras.normalWidth,
            name = L["Color"],
            hasAlpha = true,
            order = 21,
            disabled = function() return data.hideBackground; end,
            hidden = function() return data.hideBackground; end
        },
        desaturateBackground = {
          type = "toggle",
          name = L["Desaturate"],
          order = 22,
          width = WeakAuras.normalWidth,
          disabled = function() return data.hideBackground; end,
          hidden = function() return data.hideBackground; end
      },
        backgroundColorHiddenSpacer = {
          type = "execute",
          width = WeakAuras.normalWidth,
          name = "",
          order = 23,
          image = function() return "", 0, 0 end,
          hidden = function() return not data.hideBackground end
        },
        customBackgroundRows = {
          type = "input",
          width = WeakAuras.doubleWidth / 3,
          name = L["Rows"],
          validate = WeakAuras.ValidateNumeric,
          get = function()
            return data.customBackgroundRows and tostring(data.customBackgroundRows) or "";
          end,
          set = function(info, v)
            data.customBackgroundRows = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 24,
          hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundColumns = {
          type = "input",
          width = WeakAuras.doubleWidth / 3,
          name = L["Columns"],
          validate = WeakAuras.ValidateNumeric,
          get = function()
            return data.customBackgroundColumns and tostring(data.customBackgroundColumns) or "";
          end,
          set = function(info, v)
            data.customBackgroundColumns = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 25,
          hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundFrames = {
          type = "input",
          width = WeakAuras.doubleWidth / 3,
          name = L["Frame Count"],
          validate = WeakAuras.ValidateNumeric,
          get = function()
            return data.customBackgroundFrames and tostring(data.customBackgroundFrames) or "";
          end,
          set = function(info, v)
            data.customBackgroundFrames = v and tonumber(v) or 0
            WeakAuras.Add(data);
            WeakAuras.UpdateThumbnail(data);
          end,
          order = 26,
          hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundFileWidth = {
        type = "input",
        width = WeakAuras.normalWidth / 2,
        name = L["File Width"],
        desc = L["Must be a power of 2"],
        validate = function(info, val)
          if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31 or math.frexp(val) ~= 0.5) then
            return false;
          end
          return true
        end,
        get = function()
          return data.customBackgroundFileWidth and tostring(data.customBackgroundFileWidth) or "";
        end,
        set = function(info, v)
          data.customBackgroundFileWidth = v and tonumber(v) or 0
          WeakAuras.Add(data);
          WeakAuras.UpdateThumbnail(data);
        end,
        order = 27,
        hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundFileHeight = {
        type = "input",
        width = WeakAuras.normalWidth / 2,
        name = L["File Height"],
        desc = L["Must be a power of 2"],
        validate = function(info, val)
          if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31 or math.frexp(val) ~= 0.5) then
            return false;
          end
          return true
        end,
        get = function()
          return data.customBackgroundFileHeight and tostring(data.customBackgroundFileHeight) or "";
        end,
        set = function(info, v)
          data.customBackgroundFileHeight = v and tonumber(v) or 0
          WeakAuras.Add(data);
          WeakAuras.UpdateThumbnail(data);
        end,
        order = 28,
        hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundFrameWidth = {
        type = "input",
        width = WeakAuras.normalWidth / 2,
        name = L["Frame Width"],
        validate = WeakAuras.ValidateNumeric,
        desc = L["Can set to 0 if Columns * Width equal File Width"],
        get = function()
          return data.customBackgroundFrameWidth and tostring(data.customBackgroundFrameWidth) or "";
        end,
        set = function(info, v)
          data.customBackgroundFrameWidth = v and tonumber(v) or 0
          WeakAuras.Add(data);
          WeakAuras.UpdateThumbnail(data);
        end,
        order = 29,
        hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      customBackgroundFrameHeight = {
        type = "input",
        width = WeakAuras.normalWidth / 2,
        name = L["Frame Height"],
        validate = WeakAuras.ValidateNumeric,
        desc = L["Can set to 0 if Rows * Height equal File Height"],
        get = function()
          return data.customBackgroundFrameHeight and tostring(data.customBackgroundFrameHeight) or "";
        end,
        set = function(info, v)
          data.customBackgroundFrameHeight = v and tonumber(v) or 0
          WeakAuras.Add(data);
          WeakAuras.UpdateThumbnail(data);
        end,
        order = 30,
        hidden = function() return data.sameTexture or texture_data[data.backgroundTexture] or textureNameHasData(data.backgroundTexture) end
      },
      backgroundPercent = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Selected Frame"],
        min = 0,
        max = 1,
        order = 31,
        isPercent = true,
        hidden = function() return data.hideBackground; end
      }
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
    local borderframe = CreateFrame("Frame", nil, UIParent);
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
    region.foreground = region.foreground or {}
    local tdata = texture_data[data.foregroundTexture];
    if (tdata) then
      local lastFrame = tdata.count - 1;
      region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
      region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
      region.foreground.rows = tdata.rows;
      region.foreground.columns = tdata.columns;
      region.foreground.fileWidth = 0
      region.foreground.fileHeight = 0
      region.foreground.frameWidth = 0
      region.foreground.frameHeight = 0
    else
      local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
      local pattern2 = "%.x(%d+)y(%d+)f(%d+)w(%d+)h(%d+)W(%d+)H(%d+)%.[tb][gl][ap]"
      local rows, columns, frames = data.foregroundTexture:lower():match(pattern)
      if rows then
        local lastFrame = frames - 1;
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foreground.rows = tonumber(rows);
        region.foreground.columns = tonumber(columns);
        region.foreground.fileWidth = 0
        region.foreground.fileHeight = 0
        region.foreground.frameWidth = 0
        region.foreground.frameHeight = 0
      else
        local rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight = data.foregroundTexture:match(pattern2)
        if rows then
          local lastFrame = frames - 1;
          region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
          region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
          region.foreground.rows = tonumber(rows)
          region.foreground.columns = tonumber(columns)
          region.foreground.fileWidth = tonumber(fileWidth)
          region.foreground.fileHeight = tonumber(fileHeight)
          region.foreground.frameWidth = tonumber(frameWidth)
          region.foreground.frameHeight = tonumber(frameHeight)
        else
          local lastFrame = data.customForegroundFrames - 1;
          region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
          region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
          region.foreground.rows = data.customForegroundRows;
          region.foreground.columns = data.customForegroundColumns;
          region.foreground.fileWidth = data.customForegroundFileWidth
          region.foreground.fileHeight = data.customForegroundFileHeight
          region.foreground.frameWidth = data.customForegroundFrameWidth
          region.foreground.frameHeight = data.customForegroundFrameHeight
        end
      end
    end

    if (region.startFrame and region.endFrame) then
      frame = floor(region.startFrame + (region.endFrame - region.startFrame) * 0.75);
    end

    local texture = data.foregroundTexture or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion";

    if (region.foreground.rows and region.foreground.columns) then
      region.texture:SetTexture(texture);
      local frameScaleW, frameScaleH = 1, 1
      if region.foreground.fileWidth and region.foreground.frameWidth and region.foreground.fileWidth > 0 and region.foreground.frameWidth > 0 then
        frameScaleW = (region.foreground.frameWidth * region.foreground.columns) / region.foreground.fileWidth
      end
      if region.foreground.fileHeight and region.foreground.frameHeight and region.foreground.fileHeight > 0 and region.foreground.frameHeight > 0 then
        frameScaleH = (region.foreground.frameHeight * region.foreground.rows) / region.foreground.fileHeight
      end
      setTile(region.texture, frame, region.foreground.rows, region.foreground.columns, frameScaleW, frameScaleH);

      region.SetValue = function(self, percent)
        local frame = floor(percent * (region.endFrame - region.startFrame) + region.startFrame);
        setTile(self.texture, frame, region.foreground.rows, region.foreground.columns, frameScaleW, frameScaleH);
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

    local thumbnail = createThumbnail();
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
