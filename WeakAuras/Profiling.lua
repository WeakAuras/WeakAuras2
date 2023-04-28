if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint
local LGF = LibStub("LibGetFrame-1.0")

local profileData = {}
profileData.systems = {}
profileData.auras = {}

local currentProfileState, ProfilingTimer

local RealTimeProfilingWindow = CreateFrame("Frame", "WeakAurasRealTimeProfiling", UIParent, "PortraitFrameTemplate")
ButtonFrameTemplate_HidePortrait(RealTimeProfilingWindow)
Private.frames["RealTime Profiling Window"] = RealTimeProfilingWindow
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

local table_to_string
table_to_string = function(tbl, depth)
  if depth and depth >= 3 then
    return "{ ... }"
  end
  local str
  for k, v in pairs(tbl) do
    if type(v) ~= "userdata" then
      if type(v) == "table" then
        v = table_to_string(v, (depth and depth + 1 or 1))
      elseif type(v) == "function" then
        v = "function"
      elseif type(v) == "string" then
        v = '"'.. v ..'"'
      end

      if type(k) == "string" then
        k = '"' .. k ..'"'
      end

      str = (str and str .. "|cff999999,|r " or "|cff999999{|r ") .. "|cffffff99["
            .. tostring(k) .. "]|r |cff999999=|r |cffffffff" .. tostring(v) .. "|r"
    end
  end
  return (str or "{ ") .. " }"
end

local profilePopup
local function CreateProfilePopup()
  local frame = CreateFrame("Frame", "WeakAurasProfilingReport", UIParent, "PortraitFrameTemplate")
  ButtonFrameTemplate_HidePortrait(frame)
  WeakAurasProfilingReportTitleText:SetText(L["WeakAuras Profiling Report"])
  frame:SetMovable(true)
  frame:SetSize(450, 300)

  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.is_moving then
      self:StartMoving()
      self.is_moving = true
    elseif button == "RightButton" then
      self:Stop()
    end
  end)

  frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.is_moving then
      self:StopMovingOrSizing()
      local xOffset = self:GetLeft()
      local yOffset = self:GetTop() - GetScreenHeight()
      WeakAurasSaved.ProfilingWindow = WeakAurasSaved.ProfilingWindow or {}
      WeakAurasSaved.ProfilingWindow.xOffset = xOffset
      WeakAurasSaved.ProfilingWindow.yOffset = yOffset
      self.is_moving = nil
    end
  end)

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
  scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -27, 15)

  local messageFrame = CreateFrame("EditBox", nil, scrollFrame)
  frame.messageFrame = messageFrame
  messageFrame:SetMultiLine(true)
  messageFrame:SetAutoFocus(false)
  messageFrame:SetFontObject(ChatFontNormal)
  messageFrame:SetSize(440, 260)
  messageFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -5)
  messageFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT")
  messageFrame:Show()
  messageFrame:SetScript("OnChar", function() messageFrame:SetText(messageFrame.originalText) end)

  --editbox.orig_Hide = editbox.Hide
  --function editbox:Hide()
  --  self:SetText("")
  --  self:orig_Hide()
  --end

  function frame:AddText(v)
    if not v then return end
    --- @type string?
    local m = self.messageFrame:GetText()
    if m ~= "" then
      m = m .. "|n"
    end
    if type(v) == "table" then
      v = table_to_string(v)
    end
    self.messageFrame.originalText = m .. v
    self.messageFrame:SetText(self.messageFrame.originalText)
  end

  scrollFrame:SetHitRectInsets(-8, -8, -8, -8)
  scrollFrame:SetScrollChild(messageFrame)

  profilePopup = frame
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

local function StartProfileUID(uid)
  StartProfiling(profileData.auras, Private.UIDtoID(uid))
end

local function StopProfileUID(uid)
  StopProfiling(profileData.auras, Private.UIDtoID(uid))
end

function Private.ProfileRenameAura(oldid, id)
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

  Private.StartProfileSystem = StartProfileSystem
  Private.StartProfileAura = StartProfileAura
  Private.StartProfileUID = StartProfileUID
  Private.StopProfileSystem = StopProfileSystem
  Private.StopProfileAura = StopProfileAura
  Private.StopProfileUID = StopProfileUID
  LGF.StartProfile()
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

  Private.StartProfileSystem = doNothing
  Private.StartProfileAura = doNothing
  Private.StartProfileUID = doNothing
  Private.StopProfileSystem = doNothing
  Private.StopProfileAura = doNothing
  Private.StopProfileUID = doNothing
  LGF.StopProfile()

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

  if WeakAurasRealTimeProfiling and WeakAurasRealTimeProfiling:IsShown() then
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", WeakAurasRealTimeProfiling, "TOPRIGHT", 5, 0)
  else
    if WeakAurasSaved.ProfilingWindow then
      popup:SetPoint("TOPLEFT", UIParent, "TOPLEFT", WeakAurasSaved.ProfilingWindow.xOffset or 0,
                                                     WeakAurasSaved.ProfilingWindow.yOffset or 0)
    else
      popup:SetPoint("CENTER")
    end
  end

  popup.messageFrame:SetText("")

  PrintOneProfile(popup, "|cff9900ffTotal time:|r", profileData.systems.time)
  PrintOneProfile(popup, "|cff9900ffTime inside WA:|r", profileData.systems.wa)
  popup:AddText(string.format("|cff9900ffTime spent inside WA:|r %.2f%%",
                              100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))

  popup:AddText("")
  popup:AddText("Note: Not every aspect of each aura can be tracked.")
  popup:AddText("You can ask on our discord https://discord.gg/weakauras for help interpreting this output.")

  popup:AddText("")
  popup:AddText("|cff9900ffAuras:|r")
  local total = TotalProfileTime(profileData.auras)
  popup:AddText("Total time attributed to auras: ", floor(total) .."ms")
  for i, k in ipairs(SortProfileMap(profileData.auras)) do
    PrintOneProfile(popup, k, profileData.auras[k], total)
  end

  popup:AddText("")
  popup:AddText("|cff9900ffSystems:|r")

  for i, k in ipairs(SortProfileMap(profileData.systems)) do
    if (k ~= "time" and k ~= "wa") then
      PrintOneProfile(popup, k, profileData.systems[k], profileData.systems.wa.elapsed)
    end
  end

  popup:AddText("")
  popup:AddText("|cff9900ffLibGetFrame:|r")
  for id, map in pairs(LGF.GetProfileData()) do
    PrintOneProfile(popup, id, map)
  end

  popup:Show()
end

local texture = "Interface\\DialogFrame\\UI-DialogBox-Background"
local margin = 5
function RealTimeProfilingWindow:GetBar(name)
  if self.bars[name] then
    return self.bars[name]
  else
    local bar = CreateFrame("Frame", nil, self.barsFrame)
    self.bars[name] = bar
    Mixin(bar, SmoothStatusBarMixin)
    bar.name = name
    bar.parent = self
    bar:SetHeight(self.barHeight)

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
      if self.parent.barHeight * pos >
         self.parent.height - self.parent.titleHeight - self.parent.statsHeight - self.parent.buttonsHeight
      then
        self:Hide()
      else
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", self.parent.barsFrame, "TOPLEFT", 0, - (pos - 1) * self.parent.barHeight)
        self:SetPoint("RIGHT", self.parent.barsFrame, "RIGHT")
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
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                  WeakAurasSaved.RealTimeProfilingWindow.xOffset or 0,
                  WeakAurasSaved.RealTimeProfilingWindow.yOffset or 0)
  else
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
  end
  self:Show()

  WeakAurasRealTimeProfilingTitleText:SetText(L["WeakAuras Profiling"])

  local barsFrame = CreateFrame("Frame", nil, self)
  self.barsFrame = barsFrame
  barsFrame:SetPoint("TOPLEFT", 7, -20)
  barsFrame:SetPoint("BOTTOMRIGHT", -3, 30)
  barsFrame:Show()

  local statsFrameText = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.statsFrameText = statsFrameText
  statsFrameText:SetPoint("BOTTOMLEFT", 15, 25)

  local minimizeButton = CreateFrame("Button", nil, self, "MaximizeMinimizeButtonFrameTemplate")
  minimizeButton:SetPoint("RIGHT", self.CloseButton, "LEFT")
  minimizeButton:SetOnMaximizedCallback(function()
    self.minimized = false
    self.barsFrame:Show()
    self.toggleButton:Show()
    self.reportButton:Show()
    self.combatButton:Show()
    self.encounterButton:Show()
    self.statsFrameText:Show()
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", self.right, self.top)
    self:SetHeight(self.prevHeight)
  end)
  minimizeButton:SetOnMinimizedCallback(function()
    self.minimized = true
    self.barsFrame:Hide()
    self.toggleButton:Hide()
    self.reportButton:Hide()
    self.combatButton:Hide()
    self.encounterButton:Hide()
    self.statsFrameText:Hide()
    self.right, self.top = self:GetRight(), self:GetTop()
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", self.right, self.top)
    self.prevHeight = self:GetHeight()
    self:SetHeight(60)
  end)

  local width = 120
  local spacing = 2

  local toggleButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.toggleButton = toggleButton
  toggleButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -spacing, spacing)
  toggleButton:SetFrameLevel(self:GetFrameLevel() + 1)
  toggleButton:SetHeight(20)
  toggleButton:SetWidth(width)
  toggleButton:SetText(L["Start Now"])
  toggleButton:SetScript("OnClick", function(self)
    local parent = self:GetParent()
    if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
      parent:ResetBars()
      WeakAuras.StartProfile()
    else
      WeakAuras.StopProfile()
    end
  end)


  local reportButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.reportButton = reportButton
  reportButton:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", spacing, spacing)
  reportButton:SetFrameLevel(self:GetFrameLevel() + 1)
  reportButton:SetHeight(20)
  reportButton:SetWidth(width)
  reportButton:SetText(L["Report Summary"])
  reportButton:SetScript("OnClick", function(self)
    WeakAuras.PrintProfile()
  end)
  reportButton:Hide()

  local combatButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.combatButton = combatButton
  combatButton:SetPoint("BOTTOMRIGHT", -spacing - width , spacing)
  combatButton:SetFrameLevel(self:GetFrameLevel() + 1)
  combatButton:SetHeight(20)
  combatButton:SetWidth(width)
  combatButton:SetScript("OnClick", function(self)
    local parent = self:GetParent()
    parent:ResetBars()
    if currentProfileState ~= "combat" then
      WeakAuras.StartProfile("combat")
    else
      CancelScheduledProfile()
    end
  end)

  local encounterButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.encounterButton = encounterButton
  encounterButton:SetPoint("BOTTOMRIGHT", -spacing - 2 * width, spacing)
  encounterButton:SetFrameLevel(self:GetFrameLevel() + 1)
  encounterButton:SetHeight(20)
  encounterButton:SetWidth(width)
  encounterButton:SetScript("OnClick", function(self)
    local parent = self:GetParent()
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
  self.toggleButton:SetText(L["Start Now"])
end

function RealTimeProfilingWindow:Toggle()
  if self:IsShown() then
    self:Stop()
  else
    self:Start()
  end
end
