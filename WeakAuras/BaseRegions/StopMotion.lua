if not WeakAuras.IsLibsOK() then return end

---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L
local texture_data = WeakAuras.StopMotion.texture_data

--- @class StopMotionBase
Private.StopMotionBase = {}

--- @alias StopMotionAnimationType "progress"|"timed"|"background"

--- @class StopMotionBaseInstance
--- @field texture Texture
--- @field startTime number?
--- @field currentFrame number?
--- @field inverseDirection boolean?
--- @field frameRate number
--- @field animationType StopMotionAnimationType
--- @field textureFile number
--- @field startFrame number
--- @field endFrame number
--- @field lastFrame number
--- @field rows number
--- @field columns number
--- @field fileWidth number
--- @field fileHeight number
--- @field frameWidth number
--- @field frameHeight number
--- @field SetBaseTexture fun(self: StopMotionBaseInstance, texture: string)
--- @field SetFrame fun(self: StopMotionBaseInstance, texture: string, frame: number)

--- @class StopMotionOptions
--- @field frameRate number?
--- @field inverseDirection boolean?
--- @field animationType StopMotionAnimationType
--- @field startPercent number
--- @field endPercent number
--- @field texture string|number
--- @field blendMode BlendMode
--- @field customFrames number?
--- @field customRows number?
--- @field customColumns number?
--- @field customFileWidth number?
--- @field customFrameWidth number?
--- @field customFrameHeight number?

-- Helper method for Options

--- @type fun(textureName: string): boolean
function Private.StopMotionBase.textureNameHasData(textureName)
  if not textureName then
    return false
  end
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

--- @type fun(texture: string, frame: number, rows: number, columns: number, frameScaleW: number, frameScaleH: number)
local function setTile(texture, frame, rows, columns, frameScaleW, frameScaleH)
  frame = frame - 1
  local row = floor(frame / columns)
  local column = frame % columns

  local deltaX = frameScaleW / columns
  local deltaY = frameScaleH / rows

  local left = deltaX * column
  local right = left + deltaX

  local top = deltaY * row
  local bottom = top + deltaY
  pcall(function() texture:SetTexCoord(left, right, top, bottom) end)
end

WeakAuras.setTile = setTile

-- Helper method for Options
--- @type fun(textureWidget: table, texturePath: string, textureName: string)
function Private.StopMotionBase.setTextureFunc(textureWidget, texturePath, textureName)
  local data = texture_data[texturePath]
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
        rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight
          = tonumber(rows), tonumber(columns), tonumber(frames), tonumber(frameWidth), tonumber(frameHeight),
            tonumber(fileWidth), tonumber(fileHeight)
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
  textureWidget.frameNr = 0
  if (data) then
      if (data.rows and data.columns) then
        -- Texture Atlas
        textureWidget:SetTexture(texturePath, textureName, true)

        setTile(textureWidget, data.count, data.rows, data.columns, data.frameScaleW or 1, data.frameScaleH or 1)

        textureWidget:SetOnUpdate(function(self, elapsed)
          self.elapsed = (self.elapsed or 0) + elapsed
          if(self.elapsed > 0.1) then
            self.elapsed = self.elapsed - 0.1
            textureWidget.frameNr = textureWidget.frameNr + 1
            if (textureWidget.frameNr == data.count) then
              textureWidget.frameNr = 1
            end
            setTile(textureWidget, textureWidget.frameNr, data.rows, data.columns, data.frameScaleW or 1, data.frameScaleH or 1)
          end
        end)
      else
        -- Numbered Textures
        local texture = texturePath .. format("%03d", texture_data[texturePath].count)
        textureWidget:SetTexture(texture, textureName, true)
        textureWidget:SetTexCoord(0, 1, 0, 1)

        textureWidget:SetOnUpdate(function(self, elapsed)
          self.elapsed = (self.elapsed or 0) + elapsed
          if(self.elapsed > 0.1) then
            self.elapsed = self.elapsed - 0.1
            textureWidget.frameNr = textureWidget.frameNr + 1
            if (textureWidget.frameNr == data.count) then
              textureWidget.frameNr = 1
            end
            local texture = texturePath .. format("%03d", textureWidget.frameNr)
            textureWidget:SetTexture(texture, textureName)
          end
        end)
      end
  else
    local texture = texturePath .. format("%03d", 1)
    textureWidget:SetTexture(texture, textureName, true)
  end
end

local GetAtlasInfo = WeakAuras.IsClassicEra() and GetAtlasInfo or C_Texture.GetAtlasInfo

--- @type fun(self: StopMotionBaseInstance, texture: string)
local function SetTextureViaAtlas(self, texture)
  if type(texture) == "string" and GetAtlasInfo(texture) then
    self.texture:SetAtlas(texture)
  else
    self.texture:SetTexture(texture)
  end
end

--- @type fun(self: StopMotionBaseInstance, texture: string, frame: number)
local function SetFrameViaAtlas(self, texture, frame)
  local frameScaleW = 1
  local frameScaleH = 1
  if self.fileWidth and self.frameWidth and self.fileWidth > 0 and self.frameWidth > 0 then
    frameScaleW = (self.frameWidth * self.columns) / self.fileWidth
  end
  if self.fileHeight and self.frameHeight and self.fileHeight > 0 and self.frameHeight > 0 then
    frameScaleH = (self.frameHeight * self.rows) / self.fileHeight
  end
  setTile(self.texture, frame, self.rows, self.columns, frameScaleW, frameScaleH)
end

--- @type fun(self: StopMotionBaseInstance, texture: string)
local function SetTextureViaFrames(self, texture)
  self.texture:SetTexture(texture .. format("%03d", 0))
  self.texture:SetTexCoord(0, 1, 0, 1)
end

--- @type fun(self: StopMotionBaseInstance, texture: string, frame: number)
local function SetFrameViaFrames(self, texture, frame)
  self.texture:SetTexture(texture .. format("%03d", frame))
end

  --- @class StopMotionBaseInstance
local funcs = {
  --- @type fun(self: StopMotionBaseInstance, b: boolean)
  SetDesaturated = function(self, b)
    self.texture:SetDesaturated(b)
  end,
  --- @type fun(self: StopMotionBaseInstance, r: number, g: number, b: number, a: number?)
  SetColor = function(self, r, g, b, a)
    self.texture:SetVertexColor(r, g, b, a)
  end,

  --- @type fun(self: StopMotionBaseInstance) : number, number, number, number
  GetColor = function(self)
    return self.texture:GetVertexColor()
  end,

  --- @type fun(self: StopMotionBaseInstance, time: number)
  SetStartTime = function(self, time)
    self.startTime = time
  end,

  --- @type fun(self: StopMotionBaseInstance)
  TimedUpdate = function(self)
    local timeSinceStart = (GetTime() - self.startTime)
    local newCurrentFrame = floor(timeSinceStart * (self.frameRate or 15))
    if (newCurrentFrame == self.currentFrame) then
      return
    end

    self.currentFrame = newCurrentFrame

    local frames
    local startFrame = self.startFrame
    local endFrame = self.endFrame
    local inverse = self.inverseDirection
    if (endFrame >= startFrame) then
      frames = endFrame - startFrame + 1
    else
      frames = startFrame - endFrame + 1
      startFrame, endFrame = endFrame, startFrame
      inverse = not inverse
    end

    local frame = 0
    if (self.animationType == "loop") then
      frame = (newCurrentFrame % frames) + startFrame
    elseif (self.animationType == "bounce") then
      local direction = floor(newCurrentFrame / frames) % 2
      if (direction == 0) then
          frame = (newCurrentFrame % frames) + startFrame
      else
          frame = endFrame - (newCurrentFrame % frames)
      end
    elseif (self.animationType == "once") then
      frame = newCurrentFrame + startFrame
      if (frame > endFrame) then
        frame = endFrame
      end
    end
    if (inverse) then
      frame = endFrame - frame + startFrame
    end

    if (frame > endFrame) then
      frame = endFrame
      end
    if (frame < startFrame) then
      frame = startFrame
    end
    self:SetFrame(self.textureFile, frame)
  end,

  --- @type fun(self: StopMotionBaseInstance, progress: number)
  SetProgress = function(self, progress)
    local frames
    local startFrame = self.startFrame
    local endFrame = self.endFrame
    local inverse = self.inverseDirection
    if (endFrame >= startFrame) then
      frames = endFrame - startFrame + 1
    else
      frames = startFrame - endFrame + 1
      startFrame, endFrame = endFrame, startFrame
      inverse = not inverse
    end

    local frame = floor( (frames - 1) * progress) + startFrame

    if (inverse) then
      frame = endFrame - frame + startFrame
    end

    if (frame > endFrame) then
      frame = endFrame
       end
    if (frame < startFrame) then
      frame = startFrame
    end
    self:SetFrame(self.textureFile, frame)
  end,

  --- @type fun(self: StopMotionBaseInstance)
  ClearAllPoints = function(self)
    self.texture:ClearAllPoints()
  end,

  --- @type fun(self: StopMotionBaseInstance, ... : any)
  SetAllPoints = function(self, ...)
    self.texture:SetAllPoints(...)
  end,

  --- @type fun(self: StopMotionBaseInstance, ... : any)
  SetPoint = function(self, ...)
    self.texture:SetPoint(...)
  end,

  --- @type fun(self: StopMotionBaseInstance, w: number, h: number)
  SetSize = function(self, w, h)
    self.texture:SetSize(w, h)
  end,

  --- @type fun(self: StopMotionBaseInstance, b: boolean)
  SetVisible = function(self, b)
    if b then
      self.texture:Show()
    else
      self.texture:Hide()
    end
  end
}

--- @type fun(frame:Frame, drawLayer: DrawLayer) : StopMotionBaseInstance
function Private.StopMotionBase.create(frame, drawLayer)
  local stopMotion = {}

  local texture = frame:CreateTexture(nil, "ARTWORK")
  stopMotion.texture = texture
  texture:SetAllPoints(frame)
  texture:SetSnapToPixelGrid(false)
  texture:SetTexelSnappingBias(0)

  for funcName, func in pairs(funcs) do
    stopMotion[funcName] = func
  end

  --- @cast stopMotion StopMotionBaseInstance
  return stopMotion
end

--- @type fun(stopMotion: StopMotionBaseInstance, options: StopMotionOptions)
function Private.StopMotionBase.modify(stopMotion, options)
  stopMotion.frameRate = options.frameRate
  stopMotion.inverseDirection = options.inverseDirection
  stopMotion.animationType = options.animationType
  stopMotion.textureFile = options.texture

  local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
  local pattern2 = "%.x(%d+)y(%d+)f(%d+)w(%d+)h(%d+)W(%d+)H(%d+)%.[tb][gl][ap]"

  do -- setup texture
    local tdata = texture_data[stopMotion.textureFile]
    if (tdata) then
      local lastFrame = tdata.count - 1
      stopMotion.lastFrame = lastFrame
      stopMotion.startFrame = floor( (options.startPercent or 0) * lastFrame) + 1
      stopMotion.endFrame = floor( (options.endPercent or 1) * lastFrame) + 1
      stopMotion.rows = tdata.rows
      stopMotion.columns = tdata.columns
      stopMotion.fileWidth = 0
      stopMotion.fileHeight = 0
      stopMotion.frameWidth = 0
      stopMotion.frameHeight = 0
    else
      local rows, columns, frames = stopMotion.textureFile:lower():match(pattern)
      if rows then
        local lastFrame = tonumber(frames) - 1
        stopMotion.lastFrame = lastFrame
        stopMotion.startFrame = floor( (options.startPercent or 0) * lastFrame) + 1
        stopMotion.endFrame = floor( (options.endPercent or 1) * lastFrame) + 1
        stopMotion.rows = tonumber(rows)
        stopMotion.columns = tonumber(columns)
        stopMotion.fileWidth = 0
        stopMotion.fileHeight = 0
        stopMotion.frameWidth = 0
        stopMotion.frameHeight = 0
      else
        local rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight
              = stopMotion.textureFile:match(pattern2)
        if rows then
          local lastFrame = tonumber(frames) - 1
          stopMotion.lastFrame = lastFrame
          stopMotion.startFrame = floor( (options.startPercent or 0) * lastFrame) + 1
          stopMotion.endFrame = floor( (options.endPercent or 1) * lastFrame) + 1
          stopMotion.rows = tonumber(rows)
          stopMotion.columns = tonumber(columns)
          stopMotion.fileWidth = tonumber(fileWidth)
          stopMotion.fileHeight = tonumber(fileHeight)
          stopMotion.frameWidth = tonumber(frameWidth)
          stopMotion.frameHeight = tonumber(frameHeight)
        else
          local lastFrame = (options.customFrames or 256) - 1
          stopMotion.lastFrame = lastFrame
          stopMotion.startFrame = floor( (options.startPercent or 0) * lastFrame) + 1
          stopMotion.endFrame = floor( (options.endPercent or 1) * lastFrame) + 1
          stopMotion.rows = options.customRows
          stopMotion.columns = options.customColumns
          stopMotion.fileWidth = options.customFileWidth
          stopMotion.fileHeight = options.customFileHeight
          stopMotion.frameWidth = options.customFrameWidth
          stopMotion.frameHeight = options.customFrameHeight
        end
      end
    end
  end

  if (stopMotion.rows and stopMotion.columns) then
    stopMotion.SetBaseTexture = SetTextureViaAtlas
    stopMotion.SetFrame = SetFrameViaAtlas
  else
    stopMotion.SetBaseTexture = SetTextureViaFrames
    stopMotion.SetFrame = SetFrameViaFrames
  end

  stopMotion:SetBaseTexture(options.texture)
  if stopMotion.animationType == "background" then
    stopMotion:SetFrame(options.texture, stopMotion.endFrame or 1)
  else
    stopMotion:SetFrame(options.texture, 1)
  end
  stopMotion.texture:SetBlendMode(options.blendMode)
end
