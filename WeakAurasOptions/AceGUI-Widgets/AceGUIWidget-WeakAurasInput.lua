if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasInput", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local OnEditFocusGained = function(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.callbacks and option.callbacks.OnEditFocusGained then
    option.callbacks.OnEditFocusGained(self)
  end
end

local OnShow = function(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.callbacks and option.callbacks.OnShow then
    option.callbacks.OnShow(self)
  end
end

local function Constructor()
  local widget = AceGUI:Create("EditBox")
  widget.type = Type
  widget.editbox:HookScript("OnEditFocusGained", OnEditFocusGained)
  widget.editbox:HookScript("OnShow", OnShow)
  return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
