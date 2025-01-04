if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L;

--- @class StopMotionRegion : WARegion
--- @field background StopMotionBaseInstance
--- @field foreground StopMotionBaseInstance
--- @field width number
--- @field height number
--- @field scalex number
--- @field scaley number
--- @field mirror_h boolean
--- @field mirror_v boolean
--- @field color_r number
--- @field color_g number
--- @field color_b number
--- @field color_a number
--- @field color_anim_r number
--- @field color_anim_g number
--- @field color_anim_b number
--- @field color_anim_a number

local default = {
    progressSource = {-1, "" },
    adjustedMax = "",
    adjustedMin = "",
    foregroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
    backgroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
    desaturateBackground = false,
    desaturateForeground = false,
    sameTexture = true,
    width = 128,
    height = 128,
    foregroundColor = {1, 1, 1, 1},
    backgroundColor = {0.5, 0.5, 0.5, 0.5},
    blendMode = "BLEND",
    mirror = false,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    anchorFrameType = "SCREEN",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1,
    startPercent = 0,
    endPercent = 1,
    backgroundPercent = 1,
    frameRate = 15,
    animationType = "loop",
    inverse = false,
    customForegroundFrames = 0,
    customForegroundRows = 16,
    customForegroundColumns = 16,
    customBackgroundFrames = 0,
    customForegroundFileWidth = 0,
    customForegroundFileHeight = 0,
    customForegroundFrameWidth = 0,
    customForegroundFrameHeight = 0,
    customBackgroundRows = 16,
    customBackgroundColumns = 16,
    hideBackground = true
};

Private.regionPrototype.AddProgressSourceToDefault(default)

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  desaturateForeground = {
    display = L["Desaturate Foreground"],
    setter = "SetForegroundDesaturated",
    type = "bool",
  },
  desaturateBackground = {
    display = L["Desaturate Background"],
    setter = "SetBackgroundDesaturated",
    type = "bool",
  },
  foregroundColor = {
    display = L["Foreground Color"],
    setter = "Color",
    type = "color"
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
}

Private.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local result = CopyTable(properties)
  result.progressSource.values = Private.GetProgressSourcesForUi(data)
  return result
end

---@type fun(parent: WARegion) : StopMotionRegion
local function create(parent)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetMovable(true)
  frame:SetResizable(true)
  frame:SetResizeBounds(1, 1)

  --- @cast frame StopMotionRegion
  frame.background = Private.StopMotionBase.create(frame, "BACKGROUND")
  frame.foreground = Private.StopMotionBase.create(frame, "ARTWORK")

  frame.regionType = "stopmotion"
  Private.regionPrototype.create(frame)

  return frame
end

local FrameTickFunctions = {
  --- @type fun(self: StopMotionRegion)
  progressTimer = function(self)
    Private.StartProfileSystem("stopmotion")
    Private.StartProfileAura(self.id)

    local remaining = self.expirationTime - GetTime()
    local progress = 1 - (remaining / self.duration)

    self.foreground:SetProgress(progress)

    Private.StopProfileAura(self.id)
    Private.StopProfileSystem("stopmotion")
  end,
  --- @type fun(self: StopMotionRegion)
  timed = function(self)
    if (not self.foreground.startTime) then return end

    Private.StartProfileSystem("stopmotion")
    Private.StartProfileAura(self.id)

    self.foreground:TimedUpdate()

    Private.StopProfileAura(self.id)
    Private.StopProfileSystem("stopmotion")
  end,
}

---@type fun(parent: Region, region: StopMotionRegion, data: table)
local function modify(parent, region, data)
    Private.regionPrototype.modify(parent, region, data)

    Private.StopMotionBase.modify(region.foreground, {
      blendMode = data.blendMode,
      -- Foreground Data
      frameRate = data.frameRate,
      inverseDirection = data.inverse,
      animationType = data.animationType,
      texture = data.foregroundTexture,
      startPercent = data.startPercent,
      endPercent = data.endPercent,
      customFrames = data.customForegroundFrames,
      customRows = data.customForegroundRows,
      customColumns = data.customForegroundColumns,
      customFileWidth = data.customForegroundFileWidth,
      customFileHeight = data.customForegroundFileHeight,
      customFrameWidth = data.customForegroundFrameWidth,
      customFrameHeight = data.customForegroundFrameHeight,
    })

    if data.sameTexture then
      Private.StopMotionBase.modify(region.background, {
        blendMode = data.blendMode,
        animationType = "background",
        -- Background Data
        texture = data.foregroundTexture,
        startPercent = data.backgroundPercent,
        endPercent = data.backgroundPercent,
        customFrames = data.customForegroundFrames,
        customRows = data.customForegroundRows,
        customColumns = data.customForegroundColumns,
        customFileWidth = data.customForegroundFileWidth,
        customFileHeight = data.customForegroundFileHeight,
        customFrameWidth = data.customForegroundFrameWidth,
        customFrameHeight = data.customForegroundFrameHeight,
      })
    else
      Private.StopMotionBase.modify(region.background, {
        blendMode = data.blendMode,
        animationType = "background",
        -- Background Data
        texture = data.backgroundTexture,
        startPercent = data.backgroundPercent,
        endPercent = data.backgroundPercent,
        customFrames = data.customBackgroundFrames,
        customRows = data.customBackgroundRows,
        customColumns = data.customBackgroundColumns,
        customFileWidth = data.customBackgroundFileWidth,
        customFileHeight = data.customBackgroundFileHeight,
        customFrameWidth = data.customBackgroundFrameWidth,
        customFrameHeight = data.customBackgroundFrameHeight,
      })
    end

    region.background:SetVisible(not data.hideBackground)

    region.background:SetDesaturated(data.desaturateBackground)
    region.foreground:SetDesaturated(data.desaturateForeground)

    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region.width = data.width;
    region.height = data.height;
    region.scalex = 1;
    region.scaley = 1;

    --- @class StopMotionRegion
    --- @field Scale fun(self: StopMotionRegion, scalex: number, scaley: number)
    function region:Scale(scalex, scaley)
      self.scalex = scalex
      self.scaley = scaley
      if(scalex < 0) then
        self.mirror_h = true
        scalex = scalex * -1
      else
        self.mirror_h = nil
      end
      self:SetWidth(self.width * scalex)
      if(scaley < 0) then
        scaley = scaley * -1
        self.mirror_v = true
      else
        self.mirror_v = nil
      end
      self:SetHeight(self.height * scaley)
    end

    -- Set colors
    region.background:SetColor(data.backgroundColor[1], data.backgroundColor[2],
                               data.backgroundColor[3], data.backgroundColor[4])

    --- @class StopMotionRegion
    --- @field SetBackgroundColor fun(self: StopMotionRegion, r: number, g: number, b: number, a: number)
    function region:SetBackgroundColor(r, g, b, a)
      self.background:SetColor(r, g, b, a)
    end

    --- @class StopMotionRegion
    --- @field GetColor fun(self: StopMotionRegion): number, number, number, number
    function region:GetColor()
      return region.color_r, region.color_g, region.color_b, region.color_a
    end

    --- @class StopMotionRegion
    --- @field Color fun(self: StopMotionRegion, r: number, g: number, b: number, a: number)
    function region:Color(r, g, b, a)
      region.color_r = r;
      region.color_g = g;
      region.color_b = b;
      region.color_a = a;
      if (r or g or b) then
        a = a or 1;
      end
      region.foreground:SetColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
    end

    --- @class StopMotionRegion
    --- @field ColorAnim fun(self: StopMotionRegion, r: number, g: number, b: number, a: number)
    function region:ColorAnim(r, g, b, a)
      region.color_anim_r = r;
      region.color_anim_g = g;
      region.color_anim_b = b;
      region.color_anim_a = a;
      if (r or g or b) then
        a = a or 1;
      end
      region.foreground:SetColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
    end

    region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

    --- @class StopMotionRegion
    --- @field PreShow fun(self: StopMotionRegion)
    function region:PreShow()
      region.foreground:SetStartTime(GetTime())
      if region.FrameTick then
        region:FrameTick()
      end
    end

    region.FrameTick = nil
    if data.animationType == "loop" or data.animationType == "bounce" or data.animationType == "once" then
      region.FrameTick = FrameTickFunctions.timed
      region.subRegionEvents:AddSubscriber("FrameTick", region, true)
      region.UpdateValue = nil
      region.UpdateTime = nil
      function region:Update()
        region:UpdateProgress()
      end
    elseif data.animationType == "progress" then
      function region:Update()
        region:UpdateProgress()
      end

      function region:UpdateValue()
        local progress = 0;
        if (self.total ~= 0) then
          progress = self.value / self.total
        end
        self.foreground:SetProgress(progress)
        if self.FrameTick then
          self.FrameTick = nil
          self.subRegionEvents:RemoveSubscriber("FrameTick", self)
        end
      end

      function region:UpdateTime()
        if self.paused  then
          if self.FrameTick then
            self.FrameTick = nil
            self.subRegionEvents:RemoveSubscriber("FrameTick", self)
          end
          local remaining = self.remaining
          local progress = 1 - (remaining / self.duration)
          self.foreground:SetProgress(progress)
        else
          if not self.FrameTick then
            self.FrameTick = FrameTickFunctions.progressTimer
            self.subRegionEvents:AddSubscriber("FrameTick", self)
          end

          self:FrameTick()
        end
      end
    end
    --- @class StopMotionRegion
    --- @field SetRegionWidth fun(self: StopMotionRegion, width: number)
    function region:SetRegionWidth(width)
      self.width = width
      self:Scale(self.scalex, self.scaley)
    end

    --- @class StopMotionRegion
    --- @field SetRegionHeight fun(self: StopMotionRegion, height: number)
    function region:SetRegionHeight(height)
      self.height = height
      self:Scale(self.scalex, self.scaley)
    end

    --- @class StopMotionRegion
    --- @field SetForegroundDesaturated fun(self: StopMotionRegion, b: boolean)
    function region:SetForegroundDesaturated(b)
      self.foreground:SetDesaturated(b)
    end

    --- @class StopMotionRegion
    --- @field SetBackgroundDesaturated fun(self: StopMotionRegion, b: boolean)
    function region:SetBackgroundDesaturated(b)
      self.background:SetDesaturated(b)
    end

    Private.regionPrototype.modifyFinish(parent, region, data)
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("stopmotion", create, modify, default, GetProperties, validate);
