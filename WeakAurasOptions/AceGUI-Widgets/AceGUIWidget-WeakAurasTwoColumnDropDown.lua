if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasTwoColumnDropdown", 6
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local secondLevelMt = {} -- Tag for our tables
local function CreateSecondLevelTable()
  local t = {}
  setmetatable(t, secondLevelMt)
  return t
end

local function IsSecondLevelTable(t)
  return getmetatable(t) == secondLevelMt
end

local function CompareValues(a, b)
  if type(a) == "table" and type(b) == "table" then
    for ak, av in pairs(a) do
      if b[ak] ~= av then
        return false
      end
    end
    for bk, bv in pairs(b) do
      if a[bk] ~= bv then
        return false
      end
    end
    return true
  else
    return a == b
  end
end

local methods = {
  ["DoLayout"] = function(self, mode)
    self.mode = mode
    if mode == "one" then
      self.firstDropdown.frame:Show()
      self.secondDropDown.frame:Hide()
      self.firstDropdown.frame:ClearAllPoints()
      self.firstDropdown.frame:SetPoint("TOPLEFT", self.frame)
      self.firstDropdown.frame:SetPoint("TOPRIGHT", self.frame)
    else
      local halfWidth = self.frame:GetWidth() / 2
      self.firstDropdown.frame:Show()
      self.secondDropDown.frame:Show()
      self.firstDropdown.frame:ClearAllPoints()
      self.firstDropdown.frame:SetPoint("TOPLEFT", self.frame)
      self.firstDropdown.frame:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", halfWidth, 0)
      self.secondDropDown.frame:SetPoint("TOPLEFT", self.frame, halfWidth, 0)
      self.secondDropDown.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
    end
  end,
  ["OnAcquire"] = function(widget)
    local firstDropdown = AceGUI:Create("Dropdown")
    local secondDropDown = AceGUI:Create("Dropdown")

    firstDropdown:SetParent(widget)
    secondDropDown:SetParent(widget)
    firstDropdown:SetPulloutWidth(200)

    secondDropDown:SetLabel(" ")
    secondDropDown:SetPulloutWidth(200)
    secondDropDown.userdata.defaultSelection = {}

    widget.firstDropdown = firstDropdown
    widget.secondDropDown = secondDropDown

    local OnFirstDropdownValueChanged = function(self, event, value)
      local displayName = widget.userdata.firstList[value]
      local treeValue = widget.userdata.tree[displayName]
      if IsSecondLevelTable(treeValue) then
        local oldValue
        if widget.userdata.secondList then
          local v = widget.secondDropDown:GetValue()
          if v then
            oldValue = widget.userdata.secondList[v]
          end
        end
        local secondList = {}
        for displayName, _ in pairs(treeValue) do
          tinsert(secondList, displayName)
        end
        table.sort(secondList)

        local oldValueIndex = tIndexOf(secondList, oldValue)
        widget.userdata.secondList = secondList
        widget.secondDropDown:SetList(secondList)
        widget:DoLayout("two")

        if (oldValueIndex) then
          widget.secondDropDown:SetValue(oldValueIndex)

          local v = widget:GetValue()
          if (v) then
            widget:Fire("OnValueChanged", v)
          end
        else
          local default = widget.secondDropDown.userdata.defaultSelection[displayName]
          if default then
            local index = tIndexOf(secondList, default)
            widget.secondDropDown:SetValue(index)
            local v = widget:GetValue()
            if (v) then
              widget:Fire("OnValueChanged", v)
            end
          else
            widget.secondDropDown:SetValue()
          end
        end
      else
        widget.userdata.secondList = nil
        widget:DoLayout("one")
        widget:Fire("OnValueChanged", treeValue)
      end
    end

    firstDropdown.OnFirstDropdownValueChanged = OnFirstDropdownValueChanged

    local OnSecondDropdownValueChanged = function(self, event, value)
      widget:Fire("OnValueChanged", widget:GetValue())
    end

    firstDropdown:SetCallback("OnValueChanged", OnFirstDropdownValueChanged)
    secondDropDown:SetCallback("OnValueChanged", OnSecondDropdownValueChanged)

    local function FireOnEnter(self, event)
      widget:Fire("OnEnter")
    end

    local function FireOnLeave(self, event)
      widget:Fire("OnLeave")
    end

    firstDropdown:SetCallback("OnEnter", FireOnEnter)
    firstDropdown:SetCallback("OnLeave", FireOnLeave)
    secondDropDown:SetCallback("OnEnter", FireOnEnter)
    secondDropDown:SetCallback("OnLeave", FireOnLeave)


    widget:DoLayout("two")
  end,
  ["OnRelease"] = function(self)
    self.firstDropdown:SetCallback("OnValueChanged", nil)
    self.secondDropDown:SetCallback("OnValueChanged", nil)
    self.firstDropdown:SetCallback("OnEnter", nil)
    self.firstDropdown:SetCallback("OnLeave", nil)
    self.secondDropDown:SetCallback("OnEnter", nil)
    self.secondDropDown:SetCallback("OnLeave", nil)

    AceGUI:Release(self.firstDropdown)
    AceGUI:Release(self.secondDropDown)

    self.firstDropdown = nil
    self.secondDropDown = nil
  end,
  ["SetLabel"] = function(self, v)
    if v == "" then
      v = " "
    end
    self.firstDropdown:SetLabel(v)
  end,
  ["SetValue"] = function(self, value)
    for displayName, treeValue in pairs(self.userdata.tree) do
      if CompareValues(treeValue, value) then
        self:DoLayout("one")
        self.firstDropdown:SetValue(tIndexOf(self.userdata.firstList, displayName))
        return
      elseif IsSecondLevelTable(treeValue) then
        for displayName2, key in pairs(treeValue) do
          if CompareValues(key, value) then
            self:DoLayout("two")
            local index = tIndexOf(self.userdata.firstList, displayName);
            self.firstDropdown:SetValue(index)
            self.firstDropdown:OnFirstDropdownValueChanged("", index)
            self.secondDropDown:SetValue(tIndexOf(self.userdata.secondList, displayName2))
            return
          end
        end
      end
    end
    self:DoLayout("one")
    self.firstDropdown:SetValue(nil)
  end,
  ["GetValue"] = function(self)
    local displayName1 = self.userdata.firstList[self.firstDropdown:GetValue()]

    local treeValue = self.userdata.tree[displayName1]
    if not treeValue then
      return nil
    end
    if not IsSecondLevelTable(treeValue) then
      return treeValue
    end

    local displayName2 = self.userdata.secondList[self.secondDropDown:GetValue()]
    treeValue = treeValue[displayName2]
    if not treeValue then
      return nil
    end
    return treeValue
  end,
  ["SetList"] = function(self, list, order, itemType)
    local tree = {}
    for key, displayName in pairs(list) do
      if type(displayName) == "table" then
        local base = displayName[1]
        local suffix = displayName[2]
        tree[base] = tree[base] or CreateSecondLevelTable()
        tree[base][suffix] = key
        if displayName[3] == true then
          self.secondDropDown.userdata.defaultSelection[base] = suffix
        end
      else
        tree[displayName] = key
      end
    end
    self.userdata.tree = tree

    local firstList = {}
    for displayName, _ in pairs(tree) do
      tinsert(firstList, displayName)
    end
    table.sort(firstList)
    self.userdata.firstList = firstList
    self.firstDropdown:SetList(firstList, order, itemType)
  end,
  ["OnWidthSet"] = function(self)
    self:DoLayout(self.mode)
  end
}

local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetHeight(50)
  frame:SetWidth(50)

  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", 0, 0)
  content:SetPoint("BOTTOMRIGHT", 0, 0)

  local widget = {
    frame = frame,
    content = content,
    type = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
