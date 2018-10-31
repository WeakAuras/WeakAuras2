local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local profileData = {}
profileData.systems = {}
profileData.auras = {}

WeakAuras.table_to_string = function(tbl, depth)
  if depth and depth >= 3 then
    return "{ ... }"
  end
  local str
  for k,v in pairs(tbl) do
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

local profilePopup
local function CreateProfilePopup()
  local popupFrame = CreateFrame("EditBox", "WADebugEditBox", UIParent)
  popupFrame:SetFrameStrata("DIALOG")
  popupFrame:SetMultiLine(true)
  popupFrame:SetAutoFocus(true)
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
    self:Hide()
    self.ScrollFrame:Hide()
    self.Background:Hide()
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
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  bg:SetBackdropColor(.05, .05, .05, .8)
  bg:SetBackdropBorderColor(.5, .5, .5)
  bg:SetPoint("TOPLEFT", scrollFrame, -10, 10)
  bg:SetPoint("BOTTOMRIGHT", scrollFrame, 30, -10)
  bg:Hide()

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
  if (not map[id]) then
    map[id] = {}
    map[id].count = 1
    map[id].start = debugprofilestop()
    map[id].elapsed = 0
    return
  end

  if (map[id].count == 0) then
    map[id].count = 1
    map[id].start = debugprofilestop()
  else
    map[id].count = map[id].count + 1
  end
end

local function StopProfiling(map, id)
  map[id].count = map[id].count - 1
  if (map[id].count == 0) then
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
end

function WeakAuras.ToggleProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    WeakAuras.StartProfile()
  else
    WeakAuras.StopProfile()
  end
end

local function PrintOneProfile(name, map, total)
  if (map.count ~= 0) then
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
  if (not profileData.systems.time) then
    prettyPrint(L["No Profiling information saved."])
    return
  end

  if (profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling still running, stop before trying to print."])
    return
  end

  popup:AddText(L["|cff9900ffWeakAuras EXPERIMENTAL Profiling Data:|r"])
  popup:AddText("")
  PrintOneProfile("|cff9900ffTotal time:|r", profileData.systems.time)
  PrintOneProfile("|cff9900ffTime inside WA:|r", profileData.systems.wa)
  popup:AddText(string.format("|cff9900ff%% Time spent inside WA:|r %.2f", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))
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
