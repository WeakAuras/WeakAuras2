if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

OptionsPrivate.TTSFocus = {
  focusFrame = nil,
  voiceId = 0,

  SpeakText = function(self, text)
    print("SpeakText", text)
    if text and type(text) == "string" then
      C_VoiceChat.SpeakText(self.voiceId, text, 1, C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0, C_TTSSettings and C_TTSSettings.GetSpeechVolume() or 100)
    end
  end,

  SetFocus = function(self, frame, silent)
    print("SetFocus")
    if self.focusFrame and self.focusFrame.ClearFocus then
      self.focusFrame:ClearFocus()
    end
    self.focusFrame = frame
    if self.focusFrame and self.focusFrame.SetFocus then
      self.focusFrame:SetFocus()
    end
    if not silent then
      self:ReadFocus()
    end
  end,

  MoveFocus = function(self, backward)
    print("MoveFocus", backward)
    if self.focusFrame then
      local next = backward and self.focusFrame.prevFocus or self.focusFrame.nextFocus
      if next then
        if self.focusFrame.ClearFocus then
          self.focusFrame:ClearFocus()
        end

        self.focusFrame = next
        if self.focusFrame.SetFocus then
          self.focusFrame:SetFocus()
        end
        self:ReadFocus()
      end
    end
  end,

  ReadFocus = function(self)
    print("ReadFocus")
    if not self.focusFrame then
      return
    end
    local ttsDescription = self.focusFrame.ttsDescription
    if not ttsDescription and self.focusFrame.GetText then
      ttsDescription = self.focusFrame:GetText()
    end
    if not ttsDescription and self.focusFrame.text and self.focusFrame.text.GetText then
      ttsDescription = self.focusFrame.text:GetText()
    end
    if ttsDescription then
      if type(ttsDescription) == "function" then
        ttsDescription = ttsDescription()
      end
      self:SpeakText(ttsDescription)
    end
  end,

  ForwardKeyToFocus = function(self, key)
    print("ForwardKeyToFocus", key)
    if self.focusFrame then
      if self.focusFrame.ttsKeyHandler then
        self.focusFrame:ttsKeyHandler(key)
      elseif key == "SPACE" then
        if self.focusFrame.events and self.focusFrame.events.OnClick then
          self.focusFrame:Fire("OnClick")
        elseif self.focusFrame.ToggleChecked then
          self.focusFrame:ToggleChecked()
        end

      end
    end
  end,

  SetNextFocus = function(self, frame1, frame2)
    frame1.nextFocus = frame2
    frame2.prevFocus = frame1
  end,

  HasFocus = function(self)
    return self.focusFrame
  end


}
