if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local profileData = {}
profileData.systems = {}
profileData.auras = {}

local currentProfileState, ProfilingTimer

local RealTimeProfilingWindow = CreateFrame("Frame", nil, UIParent)
WeakAuras.frames["RealTime Profiling Window"] = RealTimeProfilingWindow
RealTimeProfilingWindow.width = 500
RealTimeProfilingWindow.height = 300
RealTimeProfilingWindow.barHeight = 20
RealTimeProfilingWindow.titleHeight = 20
RealTimeProfilingWindow.statsHeight = 15
RealTimeProfilingWindow.buttonsHeight = 22
RealTimeProfilingWindow.bars = {}
RealTimeProfilingWindow:SetMovable(true)
RealTimeProfilingWindow:Hide()
WeakAuras.RealTimeProfilingWindow = RealTimeProfilingWindow

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
  deco1:SetSize(140, 40)

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
  popupFrame:SetScript("OnChar", function() popupFrame:SetText(popupFrame.originalText) end);
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
    popupFrame.originalText = m .. v
    popupFrame:SetText(popupFrame.originalText)
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
  if WeakAurasSaved.ProfilingWindow then
    scrollFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", WeakAurasSaved.ProfilingWindow.xOffset or 0, WeakAurasSaved.ProfilingWindow.yOffset or 0)
  else
    scrollFrame:SetPoint("CENTER")
  end
  scrollFrame:SetHitRectInsets(-8, -8, -8, -8)
  scrollFrame:SetScrollChild(popupFrame)
  scrollFrame:Hide()

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

  local title = CreateFrame("Frame", nil, bg)
  title:SetSize(200, 40)
  title:SetPoint("TOP", 0, 12)
  title:EnableMouse(true)

  local titlebg = CreateDecorationWide(bg)
  titlebg:SetPoint("TOP", 0, 12)

  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)
  titletext:SetText(L["WeakAuras Profiling Report"])

  local close = CreateDecoration(bg)
  close:SetPoint("RIGHT", titlebg, 50, 0)

  local closeButton = CreateFrame("Button", nil, close, "UIPanelCloseButton")
  closeButton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closeButton:SetScript("OnClick", function()
    popupFrame:Hide()
  end)

  popupFrame.ScrollFrame = scrollFrame
  popupFrame.Background = bg

  title:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not scrollFrame.is_moving then
      scrollFrame:StartMoving()
      scrollFrame.is_moving = true
    end
  end)

  title:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and scrollFrame.is_moving then
      scrollFrame:StopMovingOrSizing()
      local xOffset = scrollFrame:GetLeft()
      local yOffset = scrollFrame:GetTop() - GetScreenHeight()
      WeakAurasSaved.ProfilingWindow = WeakAurasSaved.ProfilingWindow or {}
      WeakAurasSaved.ProfilingWindow.xOffset = xOffset
      WeakAurasSaved.ProfilingWindow.yOffset = yOffset
      scrollFrame.is_moving = nil
    end
  end)

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

local function StartProfiling(map, id)
  if not map[id] then
    map[id] = {}
    map[id].count = 1
    map[id].start = debugprofilestop()
    map[id].elapsed = 0
    map[id].spike = 0
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
    local elapsed = debugprofilestop() - map[id].start
    map[id].elapsed = map[id].elapsed + elapsed
    if elapsed > map[id].spike then
      map[id].spike = elapsed
    end
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

local RegisterProfile = function(startType)
  if startType == "boss" then startType = "encounter" end
  local delayedStart
  if startType == "encounter" then
    RealTimeProfilingWindow:UnregisterAllEvents()
    prettyPrint(L["Your next encounter will automatically be profiled."])
    RealTimeProfilingWindow:RegisterEvent("ENCOUNTER_START")
    RealTimeProfilingWindow:RegisterEvent("ENCOUNTER_END")
    currentProfileState = startType
    delayedStart = true
  elseif startType == "combat" then
    RealTimeProfilingWindow:UnregisterAllEvents()
    prettyPrint(L["Your next instance of combat will automatically be profiled."])
    RealTimeProfilingWindow:RegisterEvent("PLAYER_REGEN_DISABLED")
    RealTimeProfilingWindow:RegisterEvent("PLAYER_REGEN_ENABLED")
    currentProfileState = startType
    delayedStart = true
  elseif startType == "autostart" then
    prettyPrint(L["Profiling automatically started."])
    currentProfileState = "profiling"
  elseif startType and startType:match("%d") then
    RealTimeProfilingWindow:UnregisterAllEvents()
    local time = startType + 0
    prettyPrint(L["Profiling started. It will end automatically in %d seconds"]:format(time))
    ProfilingTimer = WeakAuras.timer:ScheduleTimer(WeakAuras.StopProfile, time)
    currentProfileState = "profiling"
  else
    RealTimeProfilingWindow:UnregisterAllEvents()
    prettyPrint(L["Profiling started."])
    currentProfileState = "profiling"
  end
  RealTimeProfilingWindow:UpdateButtons()
  return delayedStart
end

function WeakAuras.StartProfile(startType)
  if currentProfileState == "profiling" then
    prettyPrint(L["Profiling already started."])
    return
  end

  if RegisterProfile(startType) then
    -- Scheduled for later
    return
  end

  profileData.systems = {}
  profileData.auras = {}
  profileData.systems.time = {}
  profileData.systems.time.start = debugprofilestop()
  profileData.systems.time.count = 1

  WeakAuras.StartProfileSystem = StartProfileSystem
  WeakAuras.StartProfileAura = StartProfileAura
  WeakAuras.StopProfileSystem = StopProfileSystem
  WeakAuras.StopProfileAura = StopProfileAura
end

local function doNothing()
end

function WeakAuras.StopProfile()
  if (currentProfileState ~= "profiling") then
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

  currentProfileState = nil
  RealTimeProfilingWindow:UnregisterAllEvents()
  RealTimeProfilingWindow:UpdateButtons()
  if ProfilingTimer then
    WeakAuras.timer:CancelTimer(ProfilingTimer)
    ProfilingTimer = nil
  end
end

function WeakAuras.ToggleProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    WeakAuras.StartProfile()
  else
    WeakAuras.StopProfile()
  end
end

local function CancelScheduledProfile()
  prettyPrint(L["Your scheduled automatic profile has been cancelled."])
  currentProfileState = nil
  RealTimeProfilingWindow:UnregisterAllEvents()
  RealTimeProfilingWindow:UpdateButtons()
end

WeakAuras.CancelScheduledProfile = CancelScheduledProfile

local function AutoStartStopProfiling(frame, event)
  if event == "ENCOUNTER_START" or event == "PLAYER_REGEN_DISABLED" then
    WeakAuras.StartProfile("autostart")
  elseif event == "ENCOUNTER_END" or event == "PLAYER_REGEN_ENABLED" then
    WeakAuras.StopProfile()
  end
end
RealTimeProfilingWindow:SetScript("OnEvent", AutoStartStopProfiling)

local function PrintOneProfile(popup, name, map, total)
  if map.count ~= 0 then
    popup:AddText(name .. "  ERROR: count is not zero:" .. " " .. map.count)
  end
  local percent = ""
  if total then
    percent = ", " .. string.format("%.2f", 100 * map.elapsed / total) .. "%"
  end
  local spikeInfo = ""
  if map.spike then
    spikeInfo = string.format("(%.2fms)", map.spike)
  end
  popup:AddText(string.format("%s |cff999999%.2fms%s %s|r", name, map.elapsed, percent, spikeInfo))
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
  local popup = ProfilePopup()
  if not profileData.systems.time then
    prettyPrint(L["No Profiling information saved."])
    return
  end

  if profileData.systems.time.count == 1 then
    prettyPrint(L["Profiling still running, stop before trying to print."])
    return
  end

  popup:SetText("")

  PrintOneProfile(popup, "|cff9900ffTotal time:|r", profileData.systems.time)
  PrintOneProfile(popup, "|cff9900ffTime inside WA:|r", profileData.systems.wa)
  popup:AddText(string.format("|cff9900ffTime spent inside WA:|r %.2f%%", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))
  popup:AddText("")
  popup:AddText("|cff9900ffSystems:|r")

  for i, k in ipairs(SortProfileMap(profileData.systems)) do
    if (k ~= "time" and k ~= "wa") then
      PrintOneProfile(popup, k, profileData.systems[k], profileData.systems.wa.elapsed)
    end
  end

  popup:AddText("")
  popup:AddText("|cff9900ffAuras:|r")
  local total = TotalProfileTime(profileData.auras)
  popup:AddText("Total time attributed to auras: ", floor(total) .."ms")
  for i, k in ipairs(SortProfileMap(profileData.auras)) do
    PrintOneProfile(popup, k, profileData.auras[k], total)
  end
  popup:Show()
end

local texture = "Interface\\DialogFrame\\UI-DialogBox-Background"
local margin = 5
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
    txtName:SetPoint("TOPLEFT", bar, "TOPLEFT", margin, 0)
    txtName:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -30, 0)
    txtName:SetJustifyH("LEFT")

    local txtPct = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.txtPct = txtPct
    txtPct:SetPoint("TOPLEFT", bar, "TOPRIGHT", -55, 0)
    txtPct:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", - margin, 0)
    txtPct:SetJustifyH("RIGHT")

    function bar:SetValue(value)
      self.fg:SetWidth(self.parent.width / 100 * value)
    end

    function bar:SetText(time, pct, spike)
      self.txtName:SetText(("%s (%.2fms||%.2fms)"):format(self.name, time, spike))
      self.txtPct:SetText(("%.2f%%"):format(pct))
    end

    function bar:GetMinMaxValues()
      return 0, 100
    end

    function bar:GetValue()
      return self.value
    end

    function bar:SetProgress(value)
      self.value = value
      self:SetSmoothedValue(value)
    end

    function bar:SetPosition(pos)
      if self.parent.barHeight * pos > self.parent.height - self.parent.titleHeight - self.parent.statsHeight - self.parent.buttonsHeight then
        self:Hide()
      else
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", self.parent.barsFrame, "TOPLEFT", 0, - (pos - 1) * self.parent.barHeight)
        if pos % 2 == 0 then
          bar.fg:SetColorTexture(0.7, 0.7, 0.7, 0.7)
          bar.bg:SetColorTexture(0, 0, 0, 0.2)
        else
          bar.fg:SetColorTexture(0.5, 0.5, 0.5, 0.7)
          bar.bg:SetColorTexture(0, 0, 0, 0.4)
        end
        self:Show()
      end
    end

    return bar
  end
end

function RealTimeProfilingWindow:RefreshBars()
  if not profileData.systems.time or profileData.systems.time.count == 0 then
    return
  end

  local total = TotalProfileTime(profileData.auras)
  for i, name in ipairs(SortProfileMap(profileData.auras)) do
    if (name ~= "time" and name ~= "wa") then
      local bar = self:GetBar(name)
      local elapsed = profileData.auras[name].elapsed
      local pct = 100 * elapsed / total
      local spike = profileData.auras[name].spike
      bar:SetPosition(i)
      bar:SetProgress(pct)
      bar:SetText(elapsed, pct, spike)
    end
  end
  if profileData.systems.wa then
    local timespent = debugprofilestop() - profileData.systems.time.start
    self.statsFrameText:SetText(("|cFFFFFFFFTime in WA: %.2fs / %ds (%.1f%%)"):format(
      profileData.systems.wa.elapsed / 1000,
      timespent / 1000,
      100 * profileData.systems.wa.elapsed / timespent
    ))
  end
end

function RealTimeProfilingWindow:ResetBars()
  for k, v in pairs(self.bars) do
    v:Hide()
  end
end

function RealTimeProfilingWindow:Init()
  self:ClearAllPoints()
  self:SetSize(self.width, self.height)
  self:SetClampedToScreen(true)

  if WeakAurasSaved.RealTimeProfilingWindow then
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", WeakAurasSaved.RealTimeProfilingWindow.xOffset or 0, WeakAurasSaved.RealTimeProfilingWindow.yOffset or 0)
  else
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
  end
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
  barsFrame:SetSize(self.width, self.height - self.titleHeight - self.statsHeight - self.buttonsHeight)
  barsFrame:SetPoint("TOPLEFT", self.titleFrame, "BOTTOMLEFT")
  barsFrame:Show()

  local statsFrame = CreateFrame("Frame", nil, self)
  self.statsFrame = statsFrame
  statsFrame:SetSize(self.width, self.statsHeight)
  statsFrame:SetPoint("TOPLEFT", self.barsFrame, "BOTTOMLEFT")
  statsFrame:Show()

  local statsFrameText = self.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.statsFrameText = statsFrameText
  statsFrameText:SetPoint("LEFT", self.statsFrame, "LEFT", margin, 2)

  local closeButton = CreateFrame("Button", nil, self.titleFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", self.titleFrame, "TOPRIGHT", 1, 5)
  closeButton:SetScript("OnClick", function(self)
    self:GetParent():GetParent():Stop()
  end)

  local minimizeButton = CreateFrame("Button", nil, self.titleFrame)
  minimizeButton:SetSize(30, 30)
  minimizeButton:SetPoint("TOPRIGHT", self.titleFrame, "TOPRIGHT", -25, 5)
  minimizeButton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp")
  minimizeButton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp")
  minimizeButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
  minimizeButton:SetScript("OnClick", function(self)
    local parent = self:GetParent():GetParent()
    if parent.minimized then
      parent.minimized = nil
      parent.barsFrame:Show()
      parent.statsFrame:Show()
      parent:SetHeight(parent.height)
      self:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp")
      self:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp")
    else
      parent.minimized = true
      parent.barsFrame:Hide()
      parent.statsFrame:Hide()
      parent:SetHeight(parent.titleHeight)
      self:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Up.blp")
      self:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Down.blp")
    end
  end)

  local width = 120
  local spacing = 2

  local toggleButton = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
  self.toggleButton = toggleButton
  toggleButton:SetPoint("TOPRIGHT", statsFrame, "BOTTOMRIGHT", -spacing, spacing)
  toggleButton:SetFrameLevel(statsFrame:GetFrameLevel() + 1)
  toggleButton:SetHeight(20)
  toggleButton:SetWidth(width)
  toggleButton:SetText(L["Start"])
  toggleButton:SetScript("OnClick", function(self)
    local parent = self:GetParent():GetParent()
    if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
      parent:ResetBars()
      WeakAuras.StartProfile()
    else
      WeakAuras.StopProfile()
    end
  end)


  local reportButton = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
  self.reportButton = reportButton
  reportButton:SetPoint("TOPLEFT", statsFrame, "BOTTOMLEFT", spacing, spacing)
  reportButton:SetFrameLevel(statsFrame:GetFrameLevel() + 1)
  reportButton:SetHeight(20)
  reportButton:SetWidth(width)
  reportButton:SetText(L["Report Summary"])
  reportButton:SetScript("OnClick", function(self)
    WeakAuras.PrintProfile()
  end)
  reportButton:Hide()

  local combatButton = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
  self.combatButton = combatButton
  combatButton:SetPoint("TOPRIGHT", statsFrame, "BOTTOMRIGHT", -spacing - width , spacing)
  combatButton:SetFrameLevel(statsFrame:GetFrameLevel() + 1)
  combatButton:SetHeight(20)
  combatButton:SetWidth(width)
  combatButton:SetScript("OnClick", function(self)
    local parent = self:GetParent():GetParent()
    parent:ResetBars()
    if currentProfileState ~= "combat" then
      WeakAuras.StartProfile("combat")
    else
      CancelScheduledProfile()
    end
  end)

  local encounterButton = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
  self.encounterButton = encounterButton
  encounterButton:SetPoint("TOPRIGHT", statsFrame, "BOTTOMRIGHT", -spacing - 2 * width, spacing)
  encounterButton:SetFrameLevel(statsFrame:GetFrameLevel() + 1)
  encounterButton:SetHeight(20)
  encounterButton:SetWidth(width)
  encounterButton:SetScript("OnClick", function(self)
    local parent = self:GetParent():GetParent()
    parent:ResetBars()
    if currentProfileState ~= "encounter" then
      WeakAuras.StartProfile("encounter")
    else
      CancelScheduledProfile()
    end
  end)

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
      local xOffset = self:GetLeft()
      local yOffset = self:GetTop() - GetScreenHeight()
      WeakAurasSaved.RealTimeProfilingWindow = WeakAurasSaved.RealTimeProfilingWindow or {}
      WeakAurasSaved.RealTimeProfilingWindow.xOffset = xOffset
      WeakAurasSaved.RealTimeProfilingWindow.yOffset = yOffset
      self.is_moving = nil
    end
  end)

  self:SetScript("OnUpdate", self.RefreshBars)
  self.init = true
  self:UpdateButtons()
end

function RealTimeProfilingWindow:UpdateButtons()
  if not self.init then
    return
  end
  if currentProfileState == "combat" then
    self.combatButton:SetText(L["Cancel"])
  else
    self.combatButton:SetText(L["Next Combat"])
  end
  if currentProfileState == "encounter" then
    self.encounterButton:SetText(L["Cancel"])
  else
    self.encounterButton:SetText(L["Next Encounter"])
  end
  if currentProfileState == "profiling" then
    self.toggleButton:SetText(L["Stop"])
    self.combatButton:Hide()
    self.encounterButton:Hide()
    self.reportButton:Hide()
  else
    self.toggleButton:SetText(L["Start Now"])
    self.combatButton:Show()
    self.encounterButton:Show()
    if profileData.systems.time then
      self.reportButton:Show()
    end
  end
end

function RealTimeProfilingWindow:Start()
  if not self.init then
    self:Init()
  end
  self:Show()
end

function RealTimeProfilingWindow:Stop()
  self.reportButton:Show()
  self:Hide()
  self:ResetBars()
  WeakAuras.StopProfile()
  self.toggleButton:SetText(L["Start"])
end

function RealTimeProfilingWindow:Toggle()
  if self:IsShown() then
    self:Stop()
  else
    self:Start()
  end
end
