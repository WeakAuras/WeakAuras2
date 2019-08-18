if not WeakAuras.IsCorrectVersion() then return end

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

local editor_themes = {
  ["Standard"] = {
    ["Table"] = "|c00ff3333",
    ["Arithmetic"] = "|c00ff3333",
    ["Relational"] = "|c00ff3333",
    ["Logical"] = "|c004444ff",
    ["Special"] = "|c00ff3333",
    ["Keyword"] =  "|c004444ff",
    ["Comment"] = "|c0000aa00",
    ["Number"] = "|c00ff9900",
    ["String"] = "|c00999999"
  },
  ["Monokai"] = {
    ["Table"] = "|c00ffffff",
    ["Arithmetic"] = "|c00f92672",
    ["Relational"] = "|c00ff3333",
    ["Logical"] = "|c00f92672",
    ["Special"] = "|c0066d9ef",
    ["Keyword"] =  "|c00f92672",
    ["Comment"] = "|c0075715e",
    ["Number"] = "|c00ae81ff",
    ["String"] = "|c00e6db74"
  },
  ["Obsidian"] = {
    ["Table"] = "|c00AFC0E5",
    ["Arithmetic"] = "|c00E0E2E4",
    ["Relational"] = "|c00B3B689",
    ["Logical"] = "|c0093C763",
    ["Special"] = "|c00AFC0E5",
    ["Keyword"] =  "|c0093C763",
    ["Comment"] = "|c0066747B",
    ["Number"] = "|c00FFCD22",
    ["String"] = "|c00EC7600"
  },
}

local color_scheme = { [0] = "|r" }
local function set_scheme()
  if not WeakAurasSaved.editor_theme then
    WeakAurasSaved.editor_theme = "Monokai"
  end
  local theme = editor_themes[WeakAurasSaved.editor_theme]
  color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
  color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
  color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
  color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
  color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
  color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

  color_scheme["..."] = theme["Table"]
  color_scheme["{"] = theme["Table"]
  color_scheme["}"] = theme["Table"]
  color_scheme["["] = theme["Table"]
  color_scheme["]"] = theme["Table"]

  color_scheme["+"] = theme["Arithmetic"]
  color_scheme["-"] = theme["Arithmetic"]
  color_scheme["/"] = theme["Arithmetic"]
  color_scheme["*"] = theme["Arithmetic"]
  color_scheme[".."] = theme["Arithmetic"]

  color_scheme["=="] = theme["Relational"]
  color_scheme["<"] = theme["Relational"]
  color_scheme["<="] = theme["Relational"]
  color_scheme[">"] = theme["Relational"]
  color_scheme[">="] = theme["Relational"]
  color_scheme["~="] = theme["Relational"]

  color_scheme["and"] = theme["Logical"]
  color_scheme["or"] = theme["Logical"]
  color_scheme["not"] = theme["Logical"]
end

local function settings_dropdown_initialize(frame, level, menu)
  for k, v in pairs(editor_themes) do
    local item = {
      text = k,
      isNotRadio = false,
      checked = function()
        return WeakAurasSaved.editor_theme == k
      end,
      func = function()
        WeakAurasSaved.editor_theme = k
        set_scheme()
        WeakAuras.editor.editBox:SetText(WeakAuras.editor.editBox:GetText())
      end
    }
    UIDropDownMenu_AddButton(item)
  end
  UIDropDownMenu_AddButton({
    text = L["Bracket Matching"],
    isNotRadio = true,
    checked = function()
      return WeakAurasSaved.editor_bracket_matching
    end,
    func = function()
      WeakAurasSaved.editor_bracket_matching = not WeakAurasSaved.editor_bracket_matching
    end
  })
end

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
  set_scheme()
  IndentationLib.enable(editor.editBox, color_scheme, 4)

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", function() group:CancelClose() end);
  cancel:SetPoint("BOTTOMRIGHT", -27, 13);
  cancel:SetFrameLevel(cancel:GetFrameLevel() + 1)
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Cancel"]);

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", function() group:Close() end);
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
  close:SetFrameLevel(close:GetFrameLevel() + 1)
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText(L["Done"]);

  local settings_frame = CreateFrame("Button", "WASettingsButton", close, "UIPanelButtonTemplate")
  settings_frame:SetPoint("RIGHT", close, "LEFT", -10, 0)
  settings_frame:SetHeight(20)
  settings_frame:SetWidth(100)
  settings_frame:SetText(L["Settings"])
  settings_frame:RegisterForClicks("LeftButtonUp")

  local dropdown = CreateFrame("Frame", "SettingsMenuFrame", settings_frame, "UIDropDownMenuTemplate")
  UIDropDownMenu_Initialize(dropdown, settings_dropdown_initialize, "MENU")

  settings_frame:SetScript("OnClick", function(self, button, down)
    ToggleDropDownMenu(1, nil, dropdown, settings_frame, 0, 0)
  end)

  -- CTRL + S saves and closes, ESC cancels and closes
  editor.editBox:HookScript("OnKeyDown", function(_, key)
    if IsControlKeyDown() and key == "S" then
      group:Close()
    end
    if key == "ESCAPE" then
      group:CancelClose()
    end
  end)

  -- bracket matching
  editor.editBox:HookScript("OnChar", function(_, char)
    if not IsControlKeyDown() and WeakAurasSaved.editor_bracket_matching then
      if char == "(" then
        editor.editBox:Insert(")")
        editor.editBox:SetCursorPosition(editor.editBox:GetCursorPosition() - 1)
      elseif char == "{" then
        editor.editBox:Insert("}")
        editor.editBox:SetCursorPosition(editor.editBox:GetCursorPosition() - 1)
      elseif char == "[" then
        editor.editBox:Insert("]")
        editor.editBox:SetCursorPosition(editor.editBox:GetCursorPosition() - 1)
      end
    end
  end)

  local editorError = group.frame:CreateFontString(nil, "OVERLAY");
  editorError:SetFont(STANDARD_TEXT_FONT, 10)
  editorError:SetJustifyH("LEFT");
  editorError:SetJustifyV("TOP");
  editorError:SetTextColor(1, 0, 0);
  editorError:SetPoint("TOPLEFT", editor.frame, "BOTTOMLEFT", 5, 25);
  editorError:SetPoint("BOTTOMRIGHT", close, "BOTTOMLEFT");

  local editorLine = CreateFrame("Editbox", nil, group.frame);
  -- Set script on enter pressed..
  editorLine:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", -10, -15);
  editorLine:SetFont(STANDARD_TEXT_FONT, 10)
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

  function group.Open(self, data, path, enclose, multipath, reloadOptions, setOnParent)
    self.data = data;
    self.path = path;
    self.multipath = multipath;
    self.reloadOptions = reloadOptions;
    self.setOnParent = setOnParent;
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
    if(data.controlledChildren and not setOnParent) then
      local singleText;
      local sameTexts = true;
      local combinedText = "";
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        local text = valueFromPath(childData, multipath and path[childId] or path);
        if text then
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
    if(self.data.controlledChildren and not self.setOnParent) then
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
    if (self.reloadOptions) then
      if(self.data.controlledChildren) then
        for index, childId in pairs(self.data.controlledChildren) do
          WeakAuras.ScheduleReloadOptions(WeakAuras.GetData(childId));
        end
        WeakAuras.ScheduleReloadOptions(self.data);
      else
        WeakAuras.ScheduleReloadOptions(self.data);
      end
    else
      WeakAuras.ScheduleReloadOptions(self.data);
    end

    editor.editBox:SetScript("OnTextChanged", self.oldOnTextChanged);
    editor:ClearFocus();
    self.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";

    frame:RefreshPick();
  end
  WeakAuras.editor = editor

  return group
end

function WeakAuras.TextEditor(frame)
  textEditor = textEditor or ConstructTextEditor(frame)
  return textEditor
end
