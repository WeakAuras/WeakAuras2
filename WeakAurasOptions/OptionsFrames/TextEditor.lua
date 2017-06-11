-- Lua APIs
local pairs, type = pairs, type
local loadstring = loadstring

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local IndentationLib = IndentationLib

local WeakAuras = WeakAuras
local L = WeakAuras.L

local textEditor

local valueFromPath = WeakAuras.ValueFromPath;
local valueToPath = WeakAuras.ValueToPath;

local tableColor = "|c00ff3333"
local arithmeticColor = "|c00ff3333"
local relationColor = "|c00ff3333"
local logicColor = "|c004444ff"

local colorScheme = {
  [IndentationLib.tokens.TOKEN_SPECIAL] = "|c00ff3333",
  [IndentationLib.tokens.TOKEN_KEYWORD] = "|c004444ff",
  [IndentationLib.tokens.TOKEN_COMMENT_SHORT] = "|c0000aa00",
  [IndentationLib.tokens.TOKEN_COMMENT_LONG] = "|c0000aa00",
  [IndentationLib.tokens.TOKEN_NUMBER] = "|c00ff9900",
  [IndentationLib.tokens.TOKEN_STRING] = "|c00999999",
  -- ellipsis, curly braces, table acces
  ["..."] = tableColor,
  ["{"] = tableColor,
  ["}"] = tableColor,
  ["["] = tableColor,
  ["]"] = tableColor,
  -- arithmetic operators
  ["+"] = arithmeticColor,
  ["-"] = arithmeticColor,
  ["/"] = arithmeticColor,
  ["*"] = arithmeticColor,
  [".."] = arithmeticColor,
  -- relational operators
  ["=="] = relationColor,
  ["<"] = relationColor,
  ["<="] = relationColor,
  [">"] = relationColor,
  [">="] = relationColor,
  ["~="] = relationColor,
  -- logical operators
  ["and"] = logicColor,
  ["or"] = logicColor,
  ["not"] = logicColor,
  -- misc
  [0] = "|r",
}

local function ConstructTextEditor(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group:SetLayout("fill");

  local editor = AceGUI:Create("MultiLineEditBox");
  editor:SetWidth(400);
  editor.button:Hide();
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
  if(fontPath) then
    editor.editBox:SetFont(fontPath, 12);
  end
  group:AddChild(editor);
  editor.frame:SetClipsChildren(true);

  -- The indention lib overrides GetText, but for the line number
  -- display we ned the original, so save it here.
  local originalGetText = editor.editBox.GetText;
  IndentationLib.enable(editor.editBox, colorScheme, 4);

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", function() group:CancelClose() end);
  cancel:SetPoint("BOTTOMRIGHT", -27, 13);
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Cancel"]);

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", function() group:Close() end);
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText(L["Done"]);

  local editorError = group.frame:CreateFontString(nil, "OVERLAY");
  editorError:SetFont("Fonts\\FRIZQT__.TTF", 10)
  editorError:SetJustifyH("LEFT");
  editorError:SetJustifyV("TOP");
  editorError:SetTextColor(1, 0, 0);
  editorError:SetPoint("TOPLEFT", editor.frame, "BOTTOMLEFT", 5, 25);
  editorError:SetPoint("BOTTOMRIGHT", close, "BOTTOMLEFT");

  local editorLine = CreateFrame("Editbox", nil, group.frame);
  -- Set script on enter pressed..
  editorLine:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", -10, -15);
  editorLine:SetFont("Fonts\\FRIZQT__.TTF", 10)
  editorLine:SetJustifyH("RIGHT");
  editorLine:SetWidth(80);
  editorLine:SetHeight(20);
  editorLine:SetNumeric(true);
  editorLine:SetTextInsets(10, 10, 0, 0);

  local oldOnCursorChanged = editor.editBox:GetScript("OnCursorChanged");
  editor.editBox:SetScript("OnCursorChanged", function(...)
    oldOnCursorChanged(...);
    local cursorPosition = editor.editBox:GetCursorPosition();
    local next = -1;
    local line = 0;
    while (next and cursorPosition >= next) do
      next = originalGetText(editor.editBox):find("[\n]", next + 1);
      line = line + 1;
    end
    editorLine:SetNumber(line);
  end);

  editorLine:SetScript("OnEnterPressed", function()
    local newLine = editorLine:GetNumber();
    local newPosition = 0;
    while (newLine > 1 and newPosition) do
      newPosition = originalGetText(editor.editBox):find("[\n]", newPosition + 1);
      newLine = newLine - 1;
    end

    if (newPosition) then
      editor.editBox:SetCursorPosition(newPosition);
      editor.editBox:SetFocus();
    end
  end);

  function group.Open(self, data, path, enclose, multipath)
    self.data = data;
    self.path = path;
    self.multipath = multipath;
    if(frame.window == "texture") then
      frame.texturePicker:CancelClose();
    elseif(frame.window == "icon") then
      frame.iconPicker:CancelClose();
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "texteditor";
    local title = (type(data.id) == "string" and data.id or L["Temporary Group"]).." -";
    if (not multipath) then
      for index, field in pairs(path) do
        if(type(field) == "number") then
          field = "Trigger "..field+1
        end
        title = title.." "..field:sub(1, 1):upper()..field:sub(2);
      end
    end
    editor:SetLabel(title);
    editor.editBox:SetScript("OnEscapePressed", function() group:CancelClose(); end);
    self.oldOnTextChanged = editor.editBox:GetScript("OnTextChanged");
    editor.editBox:SetScript("OnTextChanged", function(...)
      local str = editor.editBox:GetText();
      if not(str) or editor.combinedText == true then
        editorError:SetText("");
      else
        local _, errorString
        if(enclose) then
          _, errorString = loadstring("return function() "..str.."\n end");
        else
          _, errorString = loadstring("return "..str);
        end
        editorError:SetText(errorString or "");
      end
      self.oldOnTextChanged(...);
    end);
    if(data.controlledChildren) then
      local singleText;
      local sameTexts = true;
      local combinedText = "";
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        local text = valueFromPath(childData, multipath and path[childId] or path);
        if not(singleText) then
          singleText = text;
        else
          if not(singleText == text) then
            sameTexts = false;
          end
        end
        if not(combinedText == "") then
          combinedText = combinedText.."\n\n";
        end

        combinedText = combinedText.. L["-- Do not remove this comment, it is part of this trigger: "] .. childId .. "\n";
        combinedText = combinedText..(text or "");
      end
      if(sameTexts) then
        editor:SetText(singleText or "");
        editor.combinedText = false;
      else
        editor:SetText(combinedText);
        editor.combinedText = true;
      end
    else
      editor:SetText(valueFromPath(data, path) or "");
    end
    editor:SetFocus();
  end

  function group.CancelClose(self)
    editor.editBox:SetScript("OnTextChanged", self.oldOnTextChanged);
    editor:ClearFocus();
    self.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
  end

  local function extractTexts(input, ids)
    local texts = {};

    local currentPos, id, startIdLine, startId, endId, endIdLine;
    while (true) do
      startIdLine, startId = string.find(input, L["-- Do not remove this comment, it is part of this trigger: "], currentPos, true);
      if (not startId) then break end

      endId, endIdLine = string.find(input, "\n", startId, true);
      if (not endId) then break end;

      if (currentPos) then
        local trimmedPosition = startIdLine - 1;
        while (string.sub(input, trimmedPosition, trimmedPosition) == "\n") do
          trimmedPosition = trimmedPosition - 1;
        end

        texts[id] = string.sub(input, currentPos, trimmedPosition);
      end

      id = string.sub(input, startId + 1, endId - 1);

      currentPos = endIdLine + 1;
    end

    if (id) then
      texts[id] = string.sub(input, currentPos, string.len(input));
    end

    return texts;
  end

  function group.Close(self)
    if(self.data.controlledChildren) then
      local textById = editor.combinedText and extractTexts(editor:GetText(), self.data.controlledChildren);
      for index, childId in pairs(self.data.controlledChildren) do
        local text = editor.combinedText and (textById[childId] or "") or editor:GetText();
        local childData = WeakAuras.GetData(childId);
        valueToPath(childData, self.multipath and self.path[childId] or self.path, text);
        WeakAuras.Add(childData);
      end
    else
      valueToPath(self.data, self.path, editor:GetText());
      WeakAuras.Add(self.data);
    end
    WeakAuras.ReloadTriggerOptions(self.data);

    editor.editBox:SetScript("OnTextChanged", self.oldOnTextChanged);
    editor:ClearFocus();
    self.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";

    frame:RefreshPick();
  end

  return group
end

function WeakAuras.TextEditor(frame)
  textEditor = textEditor or ConstructTextEditor(frame)
  return textEditor
end
