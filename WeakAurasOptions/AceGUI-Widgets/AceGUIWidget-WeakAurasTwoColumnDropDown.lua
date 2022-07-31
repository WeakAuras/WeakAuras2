if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasTwoColumnDropdown", 4
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function errorhandler(err)
  return geterrorhandler()(err)
end

local function safecall(func, ...)
  if func then
    return xpcall(func, errorhandler, ...)
  end
end

AceGUI:RegisterLayout("TwoColumn",
  function(content, children)
    local height = 0
    local width = content.width or content:GetWidth() or 0
    for i = 1, #children do
      local child = children[i]

      local frame = child.frame
      frame:ClearAllPoints()
      if child.userdata.hideMe then
        frame:Hide()
      else
        frame:Show()
      end
      if i == 1 then
        frame:SetPoint("TOPLEFT", content)
      else
        frame:SetPoint("TOPLEFT", children[i-1].frame, "TOPRIGHT")
      end

      if child.width == "relative" then
        child:SetWidth(width * child.relWidth)

        if child.DoLayout then
          child:DoLayout()
        end
      end

      height = max(height, frame.height or frame:GetHeight() or 0)
    end
    safecall(content.obj.LayoutFinished, content.obj, nil, height)
  end)

local methods = {
  ["OnAcquire"] = function(widget)
    local firstDropdown = AceGUI:Create("Dropdown")
    local secondDropDown = AceGUI:Create("Dropdown")

    firstDropdown:SetRelativeWidth(0.5)
    firstDropdown:SetPulloutWidth(200)
    secondDropDown:SetRelativeWidth(0.5)
    secondDropDown:SetLabel(" ")
    secondDropDown:SetPulloutWidth(200)
    secondDropDown.userdata.defaultSelection = {}

    widget.firstDropdown = firstDropdown
    widget.secondDropDown = secondDropDown

    widget:SetLayout("TwoColumn")
    widget.SetLayout = function()
      -- AceGui wants to set a default layout, but we don't want that
    end

    widget:AddChild(firstDropdown)
    widget:AddChild(secondDropDown)

    local OnFirstDropdownValueChanged = function(self, event, value)
      local displayName = widget.userdata.firstList[value]
      local treeValue = widget.userdata.tree[displayName]
      if type(treeValue) == "table" then
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
        widget.firstDropdown:SetRelativeWidth(0.5)
        widget.secondDropDown:SetRelativeWidth(0.5)
        widget.secondDropDown.userdata.hideMe = false
        widget:DoLayout()

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
        widget.firstDropdown:SetRelativeWidth(1)
        widget.secondDropDown.userdata.hideMe = true
        widget.userdata.secondList = nil
        widget:DoLayout()
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
  end,
  ["OnRelease"] = function(self)
  end,
  ["SetLabel"] = function(self, ...)
    self.firstDropdown:SetLabel(...)
  end,
  ["SetValue"] = function(self, value)
    for displayName, treeValue in pairs(self.userdata.tree) do
      if treeValue == value then
        self.firstDropdown:SetRelativeWidth(1)
        self.secondDropDown.userdata.hideMe = true
        self:DoLayout()
        self.firstDropdown:SetValue(tIndexOf(self.userdata.firstList, displayName))
        return
      elseif type(treeValue) == "table" then
        for displayName2, key in pairs(treeValue) do
          if (key == value) then
            self.firstDropdown:SetRelativeWidth(0.5)
            self.secondDropDown:SetRelativeWidth(0.5)
            self.secondDropDown.userdata.hideMe = false
            self:DoLayout()
            local index = tIndexOf(self.userdata.firstList, displayName);
            self.firstDropdown:SetValue(index)
            self.firstDropdown:OnFirstDropdownValueChanged("", index)
            self.secondDropDown:SetValue(tIndexOf(self.userdata.secondList, displayName2))
            return
          end
        end
      end
    end
    self.firstDropdown:SetRelativeWidth(1)
    self.secondDropDown.userdata.hideMe = true
    self:DoLayout()
    self.firstDropdown:SetValue(nil)
  end,
  ["GetValue"] = function(self)
    local displayName1 = self.userdata.firstList[self.firstDropdown:GetValue()]

    local treeValue = self.userdata.tree[displayName1]
    if not treeValue then
      return nil
    end
    if type(treeValue) ~= "table" then
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
        tree[base] = tree[base] or {}
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
  return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
