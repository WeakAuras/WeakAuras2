if not WeakAuras.IsLibsOK() then
  return
end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint
local LGF = LibStub("LibGetFrame-1.0")

local profileData = {}
profileData.systems = {}
profileData.auras = {}

local currentProfileState, ProfilingTimer

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
        v = '"' .. v .. '"'
      end

      if type(k) == "string" then
        k = '"' .. k .. '"'
      end

      str = (str and str .. "|cff999999,|r " or "|cff999999{|r ") .. "|cffffff99[" .. tostring(k) .. "]|r |cff999999=|r |cffffffff" .. tostring(v) .. "|r"
    end
  end
  return (str or "{ ") .. " }"
end

WeakAurasProfilingReportMixin = {}
function WeakAurasProfilingReportMixin:OnShow()
  if self.initialised then
    return
  end
  self.initialised = true

  ButtonFrameTemplate_HidePortrait(self)
  self:SetTitle(L["WeakAuras Profiling Report"])
  self:SetSize(500, 300)
end

function WeakAurasProfilingReportMixin:ClearText()
  self.ScrollBox.messageFrame:SetText("")
end

function WeakAurasProfilingReportMixin:AddText(v)
  if not v then
    return
  end
  --- @type string?
  local m = self.ScrollBox.messageFrame:GetText()
  if m ~= "" then
    m = m .. "|n"
  end
  if type(v) == "table" then
    v = table_to_string(v)
  end
  self.ScrollBox.messageFrame.originalText = m .. v
  self.ScrollBox.messageFrame:SetText(self.ScrollBox.messageFrame.originalText)
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
  if startType == "boss" then
    startType = "encounter"
  end
  local delayedStart
  if startType == "encounter" then
    WeakAurasProfilingFrame:UnregisterAllEvents()
    prettyPrint(L["Your next encounter will automatically be profiled."])
    WeakAurasProfilingFrame:RegisterEvent("ENCOUNTER_START")
    WeakAurasProfilingFrame:RegisterEvent("ENCOUNTER_END")
    currentProfileState = startType
    delayedStart = true
  elseif startType == "combat" then
    WeakAurasProfilingFrame:UnregisterAllEvents()
    prettyPrint(L["Your next instance of combat will automatically be profiled."])
    WeakAurasProfilingFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    WeakAurasProfilingFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    currentProfileState = startType
    delayedStart = true
  elseif startType == "autostart" then
    prettyPrint(L["Profiling automatically started."])
    currentProfileState = "profiling"
  elseif startType and startType:match("%d") then
    WeakAurasProfilingFrame:UnregisterAllEvents()
    local time = startType + 0
    prettyPrint(L["Profiling started. It will end automatically in %d seconds"]:format(time))
    ProfilingTimer = WeakAuras.timer:ScheduleTimer(WeakAuras.StopProfile, time)
    currentProfileState = "profiling"
  else
    WeakAurasProfilingFrame:UnregisterAllEvents()
    prettyPrint(L["Profiling started."])
    currentProfileState = "profiling"
  end
  WeakAurasProfilingFrame:UpdateButtons()
  return delayedStart
end

---@diagnostic disable-next-line: duplicate-set-field
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
  profileData.systems.time.elapsed = nil
  profileData.systems.time.count = 1

  Private.StartProfileSystem = StartProfileSystem
  Private.StartProfileAura = StartProfileAura
  Private.StartProfileUID = StartProfileUID
  Private.StopProfileSystem = StopProfileSystem
  Private.StopProfileAura = StopProfileAura
  Private.StopProfileUID = StopProfileUID
  LGF.StartProfile()
end

local function doNothing() end

---@diagnostic disable-next-line: duplicate-set-field
function WeakAuras.StopProfile()
  if currentProfileState ~= "profiling" then
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
  if WeakAurasProfilingFrame then
    WeakAurasProfilingFrame:UnregisterAllEvents()
    WeakAurasProfilingFrame:UpdateButtons()
  end

  if ProfilingTimer then
    WeakAuras.timer:CancelTimer(ProfilingTimer)
    ProfilingTimer = nil
  end
end

function WeakAuras.ToggleProfile()
  if not profileData.systems.time or profileData.systems.time.count ~= 1 then
    WeakAuras.StartProfile()
  else
    WeakAuras.StopProfile()
  end
end

local function CancelScheduledProfile()
  prettyPrint(L["Your scheduled automatic profile has been cancelled."])
  currentProfileState = nil
  WeakAurasProfilingFrame:UnregisterAllEvents()
  WeakAurasProfilingFrame:UpdateButtons()
end

WeakAuras.CancelScheduledProfile = CancelScheduledProfile

local function AutoStartStopProfiling(frame, event)
  if event == "ENCOUNTER_START" or event == "PLAYER_REGEN_DISABLED" then
    WeakAuras.StartProfile("autostart")
  elseif event == "ENCOUNTER_END" or event == "PLAYER_REGEN_ENABLED" then
    WeakAuras.StopProfile()
  end
end

local function ColoredSpike(spike)
  local r, g, b
  if spike < 2 then
    r, g, b = WeakAuras.GetHSVTransition(spike / 2, 0, 1, 0, 1, 1, 1, 0, 1)
  elseif spike < 2.5 then
    r, g, b = WeakAuras.GetHSVTransition((spike - 2) * 2, 1, 1, 0, 1, 1, 0.65, 0, 1)
  elseif spike < 3 then
    r, g, b = WeakAuras.GetHSVTransition((spike - 2.5) * 2, 1, 0.65, 0, 1, 1, 0, 0, 1)
  else
    r, g, b = 1, 0, 0
  end
  return ("|cff%02x%02x%02x%.2fms|r"):format(r * 255, g * 255, b * 255, spike)
end

local function PrintOneProfile(popup, name, map, total)
  if map.count ~= 0 then
    popup:AddText(name .. "  ERROR: count is not zero:" .. " " .. map.count)
  end

  local percent = ""
  if total then
    percent = (", %.2f%%"):format(100 * map.elapsed / total)
  end

  local spikeInfo = ""
  if map.spike then
    spikeInfo = ColoredSpike(map.spike)
  end

  popup:AddText(("%s |cff999999%.2fms%s (%s)|r"):format(name, map.elapsed, percent, spikeInfo))
end

local function SortProfileMap(map, sortField)
  local result = {}
  for k in pairs(map) do
    tinsert(result, k)
  end

  sort(result, function(a, b)
    if sortField then
      local x, y = map[a][sortField], map[b][sortField]
      if x and y then
        return x > y
      end
    end

    return map[a].elapsed > map[b].elapsed
  end)

  return result
end

local function TotalProfileTime(map)
  local total = 0
  for k, v in pairs(map) do
    if k ~= "time" and k ~= "wa" then
      total = total + v.elapsed
    end
  end
  return total
end

local function unitEventToMultiUnit(event)
  local count
  event, count = event:gsub("nameplate%d+$", "nameplate")
  if count == 1 then
    return event
  end
  event, count = event:gsub("boss%d$", "boss")
  if count == 1 then
    return event
  end
  event, count = event:gsub("arena%d$", "arena")
  if count == 1 then
    return event
  end
  event, count = event:gsub("raid%d+$", "group")
  if count == 1 then
    return event
  end
  event, count = event:gsub("raidpet%d+$", "group")
  if count == 1 then
    return event
  end
  event, count = event:gsub("party%d$", "party")
  if count == 1 then
    return event
  end
  event, count = event:gsub("partypet%d$", "party")
  return event
end

---@diagnostic disable-next-line: duplicate-set-field
function WeakAuras.PrintProfile()
  local popup = WeakAurasProfilingReport
  if not profileData.systems.time then
    prettyPrint(L["No Profiling information saved."])
    return
  end

  if profileData.systems.time.count == 1 then
    prettyPrint(L["Profiling still running, stop before trying to print."])
    return
  end

  popup:ClearAllPoints()
  if WeakAurasProfilingFrame and WeakAurasProfilingFrame:IsShown() then
    popup:SetParent(WeakAurasProfilingFrame)
    popup:SetPoint("TOPLEFT", WeakAurasProfilingFrame, "TOPRIGHT", 5, 0)
  else
    popup:SetParent(UIParent)
    if WeakAurasSaved.ProfilingWindow then
      popup:SetPoint("TOPLEFT", UIParent, "TOPLEFT", WeakAurasSaved.ProfilingWindow.xOffset or 0, WeakAurasSaved.ProfilingWindow.yOffset or 0)
    else
      popup:SetPoint("CENTER")
    end
  end

  popup:ClearText()

  PrintOneProfile(popup, "|cff9900ffTotal time:|r", profileData.systems.time)
  PrintOneProfile(popup, "|cff9900ffTime inside WA:|r", profileData.systems.wa)
  popup:AddText(string.format("|cff9900ffTime spent inside WA:|r %.2f%%", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))

  popup:AddText("")
  popup:AddText("Note: Not every aspect of each aura can be tracked.")
  popup:AddText("You can ask on our discord https://discord.gg/weakauras for help interpreting this output.")

  popup:AddText("")
  popup:AddText("|cff9900ffAuras:|r")
  local total = TotalProfileTime(profileData.auras)
  popup:AddText("Total time attributed to auras: ", floor(total) .. "ms")
  for _, k in ipairs(SortProfileMap(profileData.auras), "spike") do
    PrintOneProfile(popup, k, profileData.auras[k], total)
  end

  popup:AddText("")
  popup:AddText("|cff9900ffSystems:|r")

  -- make a new table for system data with multiUnits grouped
  local systemRegrouped = {}
  for k, v in pairs(profileData.systems) do
    local event = unitEventToMultiUnit(k)
    if systemRegrouped[event] == nil then
      systemRegrouped[event] = CopyTable(v)
    else
      if v.elapsed then
        systemRegrouped[event].elapsed = (systemRegrouped[event].elapsed or 0) + v.elapsed
      end
      if v.spike then
        systemRegrouped[event].spike = (systemRegrouped[event].spike or 0) + v.spike
      end
    end
  end

  for i, k in ipairs(SortProfileMap(systemRegrouped)) do
    if k ~= "time" and k ~= "wa" then
      PrintOneProfile(popup, k, systemRegrouped[k], profileData.systems.wa.elapsed)
    end
  end

  popup:AddText("")
  popup:AddText("|cff9900ffLibGetFrame:|r")
  for id, map in pairs(LGF.GetProfileData()) do
    PrintOneProfile(popup, id, map)
  end

  popup:Show()
end

WeakAurasProfilingLineMixin = {
  spikeTooltip = L["Maximum time used on a single frame"],
  timeTooltip = L["Cumulated time used during profiling"],
}

function WeakAurasProfilingLineMixin:Init(e)
  -- button.pct:SetText(pct)
  self.progressBar.name:SetText(e.name)
  self.time:SetText(("%.2fms"):format(e.time))
  self.spike:SetText(ColoredSpike(e.spike))
  self.progressBar:SetValue(e.pct)
end

local COLUMN_INFO = {
  {
    title = L["Name"],
    width = 1,
    attribute = "name",
  },
  {
    title = L["Time"],
    width = 100,
    attribute = "time",
  },
  {
    title = L["Spike"],
    width = 100,
    attribute = "spike",
  },
}

local function ApplyAlternateState(frame, alternate)
  if alternate then
    frame.progressBar:SetStatusBarColor(0.7, 0.7, 0.7, 0.7)
  else
    frame.progressBar:SetStatusBarColor(0.5, 0.5, 0.5, 0.7)
  end
end

local modes = {
  L["Auras"],
  L["Systems"],
}
WeakAurasProfilingMixin = {}

local MinPanelWidth, MinPanelHeight = 500, 300
local MinPanelMinimizedWidth, MinPanelMinimizedHeight = 250, 80
function WeakAurasProfilingMixin:OnShow()
  if self.initialised then
    return
  end
  self.initialised = true

  ButtonFrameTemplate_HidePortrait(self)
  self:SetTitle(L["WeakAuras Profiling"])
  self:SetSize(MinPanelWidth, MinPanelHeight)
  self.ResizeButton:Init(self, MinPanelMinimizedWidth, MinPanelMinimizedHeight)
  self:SetResizeBounds(MinPanelWidth, MinPanelHeight)
  self.mode = 1
  UIDropDownMenu_SetText(self.buttons.modeDropDown, modes[1])

  self.buttons.report:SetText(L["Report Summary"])
  self.buttons.report.tooltip = L["A detailed overview of your auras and WeakAuras systems\nCopy the whole text to Weakaura's Discord if you need assistance."]

  local minimizeButton = CreateFrame("Button", nil, self, "MaximizeMinimizeButtonFrameTemplate")
  minimizeButton:SetPoint("RIGHT", self.CloseButton, "LEFT")
  minimizeButton:SetOnMaximizedCallback(function()
    self.minimized = false
    self.buttons:Show()
    self.ResizeButton:Show()
    self.ColumnDisplay:Show()
    self.ScrollBox:Show()
    self.ScrollBar:Show()
    self.stats:Show()
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", self.right, self.top)
    self:SetHeight(self.prevHeight > MinPanelHeight and self.prevHeight or MinPanelHeight)
    self:SetWidth(self.prevWidth > MinPanelWidth and self.prevWidth or MinPanelWidth)
  end)
  minimizeButton:SetOnMinimizedCallback(function()
    self.minimized = true
    self.buttons:Hide()
    self.ResizeButton:Hide()
    self.ColumnDisplay:Hide()
    self.ScrollBox:Hide()
    self.ScrollBar:Hide()
    self.stats:Hide()
    self.right, self.top = self:GetRight(), self:GetTop()
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", self.right, self.top)
    self.prevHeight = self:GetHeight()
    self.prevWidth = self:GetWidth()
    self:SetHeight(MinPanelMinimizedHeight)
    self:SetWidth(MinPanelMinimizedWidth)
  end)

  self.ColumnDisplay:LayoutColumns(COLUMN_INFO)

  -- LayoutColumns doesn't handle resizable columns, fix it
  local headers = {}
  for header in self.ColumnDisplay.columnHeaders:EnumerateActive() do
    headers[header:GetID()] = header
  end
  local prevHeader
  for i, header in ipairs_reverse(headers) do
    header:ClearAllPoints()
    local info = COLUMN_INFO[i]
    if info.width ~= 1 then
      header:SetWidth(info.width)
    end
    if prevHeader == nil then
      header:SetPoint("BOTTOMRIGHT", -25, 1)
    else
      header:SetPoint("BOTTOMRIGHT", prevHeader, "BOTTOMLEFT", 2, 0)
    end
    if i == 1 then
      header:SetPoint("BOTTOMLEFT", 3, 0)
    end
    prevHeader = header
  end

  local view = CreateScrollBoxListLinearView()
  view:SetElementInitializer("WeakAurasProfilingLineTemplate", function(frame, elementData)
    frame:Init(elementData)
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
  ScrollUtil.RegisterAlternateRowBehavior(self.ScrollBox, ApplyAlternateState)

  self.sortField = "time"
  self.bars = CreateDataProvider()
  self:SortByColumnIndex(2)
  self.ScrollBox:SetDataProvider(self.bars)

  self:InitDropDown()
  self:InitModeDropDown()
  self:SetScript("OnEvent", AutoStartStopProfiling)

  self:SetScript("OnUpdate", function()
    if profileData.systems.time and profileData.systems.time.count > 0 then
      self:RefreshBars()
    end
  end)
  self:UpdateButtons()
end

function WeakAurasProfilingResultButton_OnClick(self)
  WeakAuras.PrintProfile()
end

local function nextEncounterButton_OnClick(self)
  if currentProfileState ~= "encounter" then
    WeakAuras.StartProfile("encounter")
  end
  local parent = self:GetParent()
  local profilingFrame = parent.dropdown.Button:GetParent():GetParent():GetParent()
  profilingFrame:ResetBars()
  profilingFrame:UpdateButtons()
end

local function nextCombatButton_OnClick(self)
  if currentProfileState ~= "combat" then
    WeakAuras.StartProfile("combat")
  end
  local parent = self:GetParent()
  local profilingFrame = parent.dropdown.Button:GetParent():GetParent():GetParent()
  profilingFrame:ResetBars()
  profilingFrame:UpdateButtons()
end

local function startNowButton_OnClick(self)
  WeakAuras.StartProfile()
  local parent = self:GetParent()
  local profilingFrame = parent.dropdown.Button:GetParent():GetParent():GetParent()
  profilingFrame:ResetBars()
  profilingFrame:UpdateButtons()
end

function WeakAurasProfilingStopButton_OnClick(self)
  if currentProfileState == "profiling" then
    WeakAuras.StopProfile()
  else
    CancelScheduledProfile()
  end
  self:GetParent():GetParent():UpdateButtons()
end

function WeakAurasProfilingMixin:InitDropDown()
  local function Initializer(dropDown, level)
    local entries = {
      {
        text = L["Start Now"],
        func = startNowButton_OnClick,
      },
      {
        text = L["Next Encounter"],
        func = nextEncounterButton_OnClick,
      },
      {
        text = L["Next Combat"],
        func = nextCombatButton_OnClick,
      },
    }
    for _, entry in ipairs(entries) do
      local info = UIDropDownMenu_CreateInfo()
      info.notCheckable = true
      info.text = entry.text
      info.func = entry.func
      UIDropDownMenu_AddButton(info)
    end
  end

  local dropDown = self.buttons.startDropDown
  local dropDownButton = self.buttons.start
  UIDropDownMenu_SetInitializeFunction(dropDown, Initializer)
  UIDropDownMenu_SetDisplayMode(dropDown, "MENU")

  dropDownButton.Text:SetText(L["Start Profiling"])
  dropDownButton:SetScript("OnMouseDown", function(o, button)
    UIMenuButtonStretchMixin.OnMouseDown(dropDownButton, button)
    ToggleDropDownMenu(1, nil, dropDown, dropDownButton, 130, 20)
  end)
end

local function selectMode(self, mode)
  local parent = self:GetParent()
  local profilingFrame = parent.dropdown.Button:GetParent():GetParent():GetParent()
  profilingFrame.mode = mode
  UIDropDownMenu_SetText(profilingFrame.buttons.modeDropDown, modes[mode])
  profilingFrame:ResetBars()
  profilingFrame:RefreshBars(nil, true)
end

function WeakAurasProfilingMixin:InitModeDropDown()
  local function Initializer(dropDown, level)
    for i = 1, 2 do
      local info = UIDropDownMenu_CreateInfo()
      info.text = modes[i]
      info.func = selectMode
      info.checked = i == self.mode
      info.arg1 = i
      UIDropDownMenu_AddButton(info)
    end
  end

  local dropDown = self.buttons.modeDropDown
  UIDropDownMenu_SetWidth(dropDown, 120)
  UIDropDownMenu_JustifyText(dropDown, "LEFT")
  UIDropDownMenu_Initialize(dropDown, Initializer)
end


local lastRefresh
function WeakAurasProfilingMixin:RefreshBars(_, force)
  if force or (not lastRefresh or lastRefresh < GetTime() - 1) then
    lastRefresh = GetTime()
  else
    return
  end

  if not profileData.systems.time then
    return
  end

  local data
  if self.mode == 1 then -- auras
    data = profileData.auras
  elseif self.mode == 2 then -- systems
    data = {}
    for k, v in pairs(profileData.systems) do
      if k ~= "time" and k ~= "wa" then
        local event = unitEventToMultiUnit(k)
        if data[event] == nil then
          data[event] = CopyTable(v)
        else
          if v.elapsed then
            data[event].elapsed = (data[event].elapsed or 0) + v.elapsed
          end
          if v.spike then
            data[event].spike = (data[event].spike or 0) + v.spike
          end
        end
      end
    end
  end

  local total = TotalProfileTime(data)
  for _, name in ipairs(SortProfileMap(data)) do
    if name ~= "time" and name ~= "wa" then
      local elapsed = data[name].elapsed
      local pct = 100 * elapsed / total
      local spike = data[name].spike
      self:UpdateBar(name, elapsed, pct, spike)
    end
  end

  self.bars:Sort()
  if profileData.systems.wa then
    local timespent = profileData.systems.time.elapsed or (debugprofilestop() - profileData.systems.time.start)
    self.stats:SetText(
      ("|cFFFFFFFFTime in WA: %.2fs / %ds (%.1f%%)"):format(profileData.systems.wa.elapsed / 1000, timespent / 1000, 100 * profileData.systems.wa.elapsed / timespent)
    )
  end
end

function WeakAurasProfilingMixin:ResetBars()
  self.bars:Flush()
end

function WeakAurasProfilingMixin:UpdateBar(name, time, pct, spike)
  local elementData = self.bars:FindElementDataByPredicate(function(elementData)
    return elementData.name == name
  end)
  if elementData then
    elementData.time = time
    elementData.pct = pct
    elementData.spike = spike
    local button = WeakAurasProfilingFrame.ScrollBox:FindFrame(elementData)
    if button then
      button.time:SetText(("%.2fms"):format(time))
      button.spike:SetText(ColoredSpike(spike))
      button.progressBar:SetValue(pct)
    end
  else
    self.bars:Insert({ name = name, time = time, pct = pct, spike = spike })
  end
end

function WeakAurasProfilingMixin:SortByColumnIndex(index)
  local previousField = self.sortField
  self.sortField = COLUMN_INFO[index].attribute
  if previousField == self.sortField then
    self.sortDirection = not self.sortDirection
  else
    self.sortDirection = true
  end
  self.bars:SetSortComparator(function(lhs, rhs)
    local field = self.sortField
    local lhsF, rhsF = lhs[field] or 0, rhs[field] or 0
    if type(lhsF) == "string" then
      lhsF = lhsF:lower()
    end
    if type(rhsF) == "string" then
      rhsF = rhsF:lower()
    end
    if lhsF == rhsF then
      return lhs.name < rhs.name
    end
    if self.sortDirection then
      return lhsF > rhsF
    else
      return lhsF < rhsF
    end
  end)
end

function WeakAurasProfilingMixin:UpdateButtons()
  local b = self.buttons
  if currentProfileState == "combat" or currentProfileState == "encounter" then
    b.stop:SetText(L["Cancel"])
    b.stop:Show()
    b.start:Hide()
  elseif currentProfileState == "profiling" then
    b.stop:SetText(L["Stop"])
    b.stop:Show()
    b.start:Hide()
  else
    b.start:Show()
    b.stop:Hide()
    if profileData.systems.time then
      b.report:Show()
    end
  end
end

function WeakAurasProfilingMixin:Start()
  self:Show()
end

function WeakAurasProfilingMixin:Stop()
  WeakAuras.StopProfile()
  self:UpdateButtons()
  self:ResetBars()
end

function WeakAurasProfilingMixin:Toggle()
  if self:IsShown() then
    if currentProfileState == "profiling" then
      self:Stop()
    end
    self:Hide()
  else
    self:Start()
  end
end

function WeakAurasProfilingColumnDisplay_OnClick(self, columnIndex)
  self:GetParent():SortByColumnIndex(columnIndex)
end
