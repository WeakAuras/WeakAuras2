if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local profileData = {}
profileData.systems = {}
profileData.auras = {}

local RealTimeProfilingWindow

WeakAuras.profileData = profileData

WeakAuras.table_to_string = function(tbl, depth)
  if depth and depth >= 3 then
    return "{ ... }"
  end
  local str
  for k, v in pairs(tbl) do
    if type(v) ~= "userdata" then
      if type(v) == "table" then
        v = WeakAuras.table_to_string(v, (depth and depth + 1 or 1))
      elseif type(v) == "function" then
        v = "function"
      elseif type(v) == "string" then
        v = '"'.. v ..'"'
      end

      if type(k) == "string" then
        k = '"' .. k ..'"'
      end

      str = (str and str .. "|cff999999,|r " or "|cff999999{|r ") .. "|cffffff99[" .. tostring(k) .. "]|r |cff999999=|r |cffffffff" .. tostring(v) .. "|r"
    end
  end
  return (str or "{ ") .. " }"
end

local function CreateDecoration(frame)
  local deco = CreateFrame("Frame", nil, frame)
  deco:SetSize(17, 40)

  local bg1 = deco:CreateTexture(nil, "BACKGROUND")
  bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
  bg1:SetAllPoints(deco)

  local bg2 = deco:CreateTexture(nil, "BACKGROUND")
  bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
  bg2:SetPoint("RIGHT", bg1, "LEFT")
  bg2:SetSize(10, 40)

  local bg3 = deco:CreateTexture(nil, "BACKGROUND")
  bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
  bg3:SetPoint("LEFT", bg1, "RIGHT")
  bg3:SetSize(10, 40)

  return deco
end

local function CreateDecorationWide(frame)
  local deco1 = frame:CreateTexture(nil, "OVERLAY")
  deco1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco1:SetTexCoord(0.31, 0.67, 0, 0.63)
  deco1:SetSize(120, 40)

  local deco2 = frame:CreateTexture(nil, "OVERLAY")
  deco2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco2:SetTexCoord(0.21, 0.31, 0, 0.63)
  deco2:SetPoint("RIGHT", deco1, "LEFT")
  deco2:SetSize(30, 40)

  local deco3 = frame:CreateTexture(nil, "OVERLAY")
  deco3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco3:SetTexCoord(0.67, 0.77, 0, 0.63)
  deco3:SetPoint("LEFT", deco1, "RIGHT")
  deco3:SetSize(30, 40)

  return deco1
end

local profilePopup
local function CreateProfilePopup()
  local popupFrame = CreateFrame("EditBox", "WADebugEditBox", UIParent)
  popupFrame:SetFrameStrata("DIALOG")
  popupFrame:SetMultiLine(true)
  popupFrame:SetAutoFocus(false)
  popupFrame:SetFontObject(ChatFontNormal)
  popupFrame:SetSize(450, 300)
  popupFrame:Hide()

  popupFrame.orig_Hide = popupFrame.Hide
  function popupFrame:Hide()
    self:SetText("")
    self.ScrollFrame:Hide()
    self.Background:Hide()
    self:orig_Hide()
  end

  popupFrame.orig_Show = popupFrame.Show
  function popupFrame:Show()
    self.ScrollFrame:Show()
    self.Background:Show()
    self:orig_Show()
  end

  function popupFrame:AddText(v)
    if not v then return end
    local m = popupFrame:GetText()
    if m ~= "" then
      m = m .. "|n"
    end
    if type(v) == "table" then
      v = WeakAuras.table_to_string(v)
    end
    popupFrame:SetText(m .. v)
  end

  popupFrame:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    if IsModifierKeyDown() then
      popupFrame:Hide()
    end
  end)

  local scrollFrame = CreateFrame("ScrollFrame", "WADebugEditBoxScrollFrame", UIParent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetMovable(true)
  scrollFrame:SetFrameStrata("DIALOG")
  scrollFrame:SetSize(450, 300)
  scrollFrame:SetPoint("CENTER")
  scrollFrame:SetHitRectInsets(-8, -8, -8, -8)
  scrollFrame:SetScrollChild(popupFrame)
  scrollFrame:Hide()

  scrollFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.is_moving then
      self:StartMoving()
      self.is_moving = true
    elseif button == "RightButton" then
      self:GetScrollChild():SetFocus()
    end
  end)

  scrollFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.is_moving then
      self:StopMovingOrSizing()
      self.is_moving = nil
    end
  end)

  local bg = CreateFrame("Frame", nil, UIParent)
  bg:SetFrameStrata("DIALOG")
  bg:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  bg:SetPoint("TOPLEFT", scrollFrame, -20, 20)
  bg:SetPoint("BOTTOMRIGHT", scrollFrame, 35, -25)
  bg:Hide()

  local titlebg = CreateDecorationWide(bg)
  titlebg:SetPoint("TOP", 0, 12)

  local title = CreateFrame("Frame", nil, bg)
  title:EnableMouse(true)

  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)
  titletext:SetText(L["WeakAuras Profiling Data"])

  local close = CreateDecoration(bg)
  close:SetPoint("RIGHT", titlebg, 50, 0)

  local closeButton = CreateFrame("Button", nil, close, "UIPanelCloseButton")
  closeButton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closeButton:SetScript("OnClick", function()
    popupFrame:Hide()
  end)

  popupFrame.ScrollFrame = scrollFrame
  popupFrame.Background = bg

  profilePopup = popupFrame
end

local function ProfilePopup()
  -- create/get and return reference to profile EditBox
  if not profilePopup then
    CreateProfilePopup()
  end

  profilePopup:Hide()
  return profilePopup
end

local popup = ProfilePopup()

local function StartProfiling(map, id)
  if not map[id] then
    map[id] = {}
    map[id].count = 1
    map[id].start = debugprofilestop()
    map[id].elapsed = 0
    return
  end

  if map[id].count == 0 then
    map[id].count = 1
    map[id].start = debugprofilestop()
  else
    map[id].count = map[id].count + 1
  end
end

local function StopProfiling(map, id)
  map[id].count = map[id].count - 1
  if map[id].count == 0 then
    map[id].elapsed = map[id].elapsed + debugprofilestop() - map[id].start
  end
end

local function StartProfileSystem(system)
  StartProfiling(profileData.systems, "wa")
  StartProfiling(profileData.systems, system)
end

local function StartProfileAura(id)
  StartProfiling(profileData.auras, id)
end

local function StopProfileSystem(system)
  StopProfiling(profileData.systems, "wa")
  StopProfiling(profileData.systems, system)
end

local function StopProfileAura(id)
  StopProfiling(profileData.auras, id)
end

function WeakAuras.ProfileRenameAura(oldid, id)
  profileData.auras[id] = profileData.auras[id]
  profileData.auras[oldid] = nil
end

function WeakAuras.StartProfile()
  if (profileData.systems.time and profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling already started."])
    return
  end

  prettyPrint(L["Profiling started."])

  profileData.systems = {}
  profileData.auras = {}
  profileData.systems.time = {}
  profileData.systems.time.start = debugprofilestop()
  profileData.systems.time.count = 1

  WeakAuras.StartProfileSystem = StartProfileSystem
  WeakAuras.StartProfileAura = StartProfileAura
  WeakAuras.StopProfileSystem = StopProfileSystem
  WeakAuras.StopProfileAura = StopProfileAura
  popup:SetText("")

  RealTimeProfilingWindow:Start()
end

local function doNothing()
end

function WeakAuras.StopProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    prettyPrint(L["Profiling not running."])
    return
  end

  prettyPrint(L["Profiling stopped."])

  profileData.systems.time.elapsed = debugprofilestop() - profileData.systems.time.start
  profileData.systems.time.count = 0

  WeakAuras.StartProfileSystem = doNothing
  WeakAuras.StartProfileAura = doNothing
  WeakAuras.StopProfileSystem = doNothing
  WeakAuras.StopProfileAura = doNothing

  RealTimeProfilingWindow:Stop()
end

function WeakAuras.ToggleProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    WeakAuras.StartProfile()
  else
    WeakAuras.StopProfile()
  end
end

local function PrintOneProfile(name, map, total)
  if map.count ~= 0 then
    popup:AddText(name .. "  ERROR: count is not zero:" .. " " .. map.count)
  end
  local percent = ""
  if total then
    percent = ", " .. string.format("%.2f", 100 * map.elapsed / total) .. "%"
  end
  popup:AddText(string.format("%s |cff999999%.2fms%s|r", name, map.elapsed, percent))
end

local function SortProfileMap(map)
  local result = {}
  for k, v in pairs(map) do
    tinsert(result, k)
  end

  sort(result, function(a, b)
    return map[a].elapsed > map[b].elapsed
  end)

  return result
end

local function TotalProfileTime(map)
  local total = 0
  for k, v in pairs(map) do
    total = total + v.elapsed
  end
  return total
end

function WeakAuras.PrintProfile()
  if not profileData.systems.time then
    prettyPrint(L["No Profiling information saved."])
    return
  end

  if profileData.systems.time.count == 1 then
    prettyPrint(L["Profiling still running, stop before trying to print."])
    return
  end

  PrintOneProfile("|cff9900ffTotal time:|r", profileData.systems.time)
  PrintOneProfile("|cff9900ffTime inside WA:|r", profileData.systems.wa)
  popup:AddText(string.format("|cff9900ffTime spent inside WA:|r %.2f%%", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))
  popup:AddText("")
  popup:AddText("|cff9900ffSystems:|r")

  for i, k in ipairs(SortProfileMap(profileData.systems)) do
    if (k ~= "time" and k ~= "wa") then
      PrintOneProfile(k, profileData.systems[k], profileData.systems.wa.elapsed)
    end
  end

  popup:AddText("")
  popup:AddText("|cff9900ffAuras:|r")
  local total = TotalProfileTime(profileData.auras)
  popup:AddText("Total time attributed to auras: ", floor(total) .."ms")
  for i, k in ipairs(SortProfileMap(profileData.auras)) do
    PrintOneProfile(k, profileData.auras[k], total)
  end
  popup:Show()
end

RealTimeProfilingWindow = CreateFrame("Frame", nil, UIParent)
WeakAuras.frames["RealTime Profiling Window"] = RealTimeProfilingWindow
RealTimeProfilingWindow.width = 400
RealTimeProfilingWindow.height = 300
RealTimeProfilingWindow.barHeight = 20
RealTimeProfilingWindow.titleHeight = 15
RealTimeProfilingWindow.statsHeight = 15
RealTimeProfilingWindow.bars = {}
RealTimeProfilingWindow:SetMovable(true)

local texture = "Interface\\DialogFrame\\UI-DialogBox-Background"

function RealTimeProfilingWindow:GetBar(name)
  if self.bars[name] then
    return self.bars[name]
  else
    local bar = CreateFrame("FRAME", nil, self.barsFrame)
    self.bars[name] = bar
    Mixin(bar, SmoothStatusBarMixin)
    bar.name = name
    bar.parent = self
    bar:SetSize(self.width, self.barHeight)

    local fg = bar:CreateTexture(nil, "ARTWORK")
    fg:SetSnapToPixelGrid(false)
    fg:SetTexelSnappingBias(0)
    fg:SetTexture(texture)
    fg:SetDrawLayer("ARTWORK", 0)
    fg:ClearAllPoints()
    fg:SetPoint("TOPLEFT", bar)
    fg:SetHeight(self.barHeight)
    fg:Show()
    bar.fg = fg

    local bg = bar:CreateTexture(nil, "ARTWORK")
    bg:SetSnapToPixelGrid(false)
    bg:SetTexelSnappingBias(0)
    bg:SetTexture(texture)
    bg:SetDrawLayer("ARTWORK", -1)
    bg:SetAllPoints()
    bg:Show()
    bar.bg = bg

    local txtName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.txtName = txtName
    txtName:SetPoint("TOPLEFT", bar, "TOPLEFT")
    txtName:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -30)
    txtName:SetJustifyH("LEFT")

    local txtPct = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.txtPct = txtPct
    txtPct:SetPoint("TOPLEFT", bar, "TOPRIGHT", -50, 0)
    txtPct:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    txtPct:SetJustifyH("RIGHT")

    function bar:SetValue(time, pct)
      self.fg:SetWidth(self.parent.width / 100 * pct)
      self.txtName:SetText(("%s (%.2fms)"):format(self.name, time))
      self.txtPct:SetText(("%.2f%%"):format(pct))
    end

    function bar:SetPosition(pos)
      if self.parent.barHeight * pos > self.parent.height - self.parent.titleHeight - self.parent.statsHeight then
        self:Hide()
      else
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", self.parent.barsFrame, "TOPLEFT", 0, - (pos - 1) * self.parent.barHeight)
        if pos % 2 == 0 then
          bar.fg:SetColorTexture(1, 1, 1, 0.7)
          bar.bg:SetColorTexture(0, 0, 0, 0.2)
        else
          bar.fg:SetColorTexture(1, 1, 1, 0.9)
          bar.bg:SetColorTexture(0, 0, 0, 0.4)
        end
        self:Show()
      end
    end

    return bar
  end
end

function RealTimeProfilingWindow:RefreshBars()
  if not profileData.systems.time then
    return
  end

  local total = TotalProfileTime(profileData.auras)
  for i, name in ipairs(SortProfileMap(profileData.auras)) do
    if (name ~= "time" and name ~= "wa") then
      local bar = self:GetBar(name)
      local value = profileData.auras[name].elapsed
      bar:SetPosition(i)
      bar:SetValue(value, 100 * value / total)
    end
  end
  if profileData.systems.wa then
    local timespent = debugprofilestop() - profileData.systems.time.start
    self.statsFrameText:SetText(("Time in WeakAuras: %.2f%%"):format(100 * profileData.systems.wa.elapsed / timespent))
  end
end

function RealTimeProfilingWindow:Init()
  self:ClearAllPoints()
  self:SetSize(self.width, self.height)
  self:SetClampedToScreen(true)
  self:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
  self:Show()

  local bg = self:CreateTexture(nil, "BACKGROUND")
  self.bg = bg
  bg:SetTexture(texture)
  bg:SetAllPoints()
  bg:Show()

  local titleFrame = CreateFrame("Frame", nil, self)
  self.titleFrame = titleFrame
  titleFrame:SetSize(self.width, self.titleHeight)
  titleFrame:SetPoint("TOPLEFT", self)
  titleFrame:Show()

  local titleText = self.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.titleFrameText = titleText
  titleText:SetText(L["WeakAuras Profiling"])
  titleText:SetPoint("CENTER", self.titleFrame)

  local barsFrame = CreateFrame("Frame", nil, self)
  self.barsFrame = barsFrame
  barsFrame:SetSize(self.width, self.height - self.titleHeight - self.statsHeight)
  barsFrame:SetPoint("TOPLEFT", self.titleFrame, "BOTTOMLEFT")
  barsFrame:Show()

  local statsFrame = CreateFrame("Frame", nil, self)
  self.statsFrame = statsFrame
  statsFrame:SetSize(self.width, self.statsHeight)
  statsFrame:SetPoint("TOPLEFT", self.barsFrame, "BOTTOMLEFT")
  statsFrame:Show()

  local statsFrameText = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.statsFrameText = statsFrameText
  statsFrameText:SetPoint("LEFT", self.statsFrame)

  self:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.is_moving then
      self:StartMoving()
      self.is_moving = true
    elseif button == "RightButton" then
      self:Stop()
    end
  end)

  self:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.is_moving then
      self:StopMovingOrSizing()
      self.is_moving = nil
    end
  end)

  self:SetScript("OnUpdate", self.RefreshBars)
  self.init = true
end

function RealTimeProfilingWindow:Start()
  if not self.init then
    self:Init()
  end
  self:Show()
end

function RealTimeProfilingWindow:Stop()
  self:Hide()
end
