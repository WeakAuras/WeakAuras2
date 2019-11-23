if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local strtrim, strsub = strtrim, strsub

-- WoW APIs
local GetTime, CreateFrame = GetTime, CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local importexport

local function ConstructImportExport(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group:SetLayout("fill");

  local input = AceGUI:Create("MultiLineEditBox");
  input:SetWidth(400);
  input.button:Hide();
  input.frame:SetClipsChildren(true);
  group:AddChild(input);

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", function() group:Close() end);
  close:SetPoint("BOTTOMRIGHT", -27, 13);
  close:SetFrameLevel(close:GetFrameLevel() + 1)
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText(L["Done"])

  function group.Open(self, mode, id)
    if(frame.window == "texture") then
      frame.texturePicker:CancelClose();
    elseif(frame.window == "icon") then
      frame.iconPicker:CancelClose();
    elseif(frame.window == "model") then
      frame.modelPicker:CancelClose();
    end
    frame.window = "importexport";
    frame:UpdateFrameVisible()
    if(mode == "export" or mode == "table") then
      if(id) then
        local displayStr;
        if(mode == "export") then
          displayStr = WeakAuras.DisplayToString(id, true);
        elseif(mode == "table") then
          displayStr = WeakAuras.DataToString(id);
        end
        input.editBox:SetMaxBytes(nil);
        input.editBox:SetScript("OnEscapePressed", function() group:Close(); end);
        input.editBox:SetScript("OnChar", function() input:SetText(displayStr); input.editBox:HighlightText(); end);
        input.editBox:SetScript("OnMouseUp", function() input.editBox:HighlightText(); end);
        input:SetLabel(id.." - "..#displayStr);
        input.button:Hide();
        input:SetText(displayStr);
        input.editBox:HighlightText();
        input:SetFocus();
      end
    elseif(mode == "import") then
      local textBuffer, i, lastPaste = {}, 0, 0
      local function clearBuffer(self)
        self:SetScript('OnUpdate', nil)
        local pasted = strtrim(table.concat(textBuffer))
        input.editBox:ClearFocus();
        pasted = pasted:match( "^%s*(.-)%s*$" );
        if (#pasted > 20) then
          WeakAuras.Import(pasted);
          input:SetLabel(L["Processed %i chars"]:format(i));
          input.editBox:SetMaxBytes(2500);
          input.editBox:SetText(strsub(pasted, 1, 2500));
        end
      end

      input.editBox:SetScript('OnChar', function(self, c)
        if lastPaste ~= GetTime() then
          textBuffer, i, lastPaste = {}, 0, GetTime()
          self:SetScript('OnUpdate', clearBuffer)
        end
        i = i + 1
        textBuffer[i] = c
      end)

      input.editBox:SetText("");
      input.editBox:SetMaxBytes(2500);
      input.editBox:SetScript("OnEscapePressed", function() group:Close(); end);
      input.editBox:SetScript("OnMouseUp", nil);
      input:SetLabel(L["Paste text below"]);
      input:SetFocus();
    end
  end

  function group.Close(self)
    input:ClearFocus();
    frame.window = "default";
    frame:UpdateFrameVisible()
  end

  return group
end

function WeakAuras.ImportExport(frame)
  importexport = importexport or ConstructImportExport(frame)
  return importexport
end
