if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasInputWithIndentation", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local eventCallbacks = {
  OnEditFocusGained = "OnEditFocusGained",
  OnEditFocusLost = "OnEditFocusLost",
  OnEnterPressed = "OnEnterPressed",
  OnShow = "OnShow"
}

local function EventHandler(frame, event)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.callbacks and option.callbacks[event] then
    option.callbacks[event](self)
  end
end

local function Constructor()
  local widget = AceGUI:Create("EditBox")
  widget.type = Type

  for event, callback in pairs(eventCallbacks) do
    widget.editbox:HookScript(event, function(frame) EventHandler(frame, callback) end)
  end

  local GetText = widget.editbox.GetText
  widget.editbox.GetText = function(self)
    return IndentationLib.decode(GetText(self))
  end

  local SetText = widget.editbox.SetText
  widget.editbox.SetText = function(self, text)
    SetText(self, IndentationLib.encode(text))
  end

  return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
