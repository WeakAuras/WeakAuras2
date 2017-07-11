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

if not WeakAurasSaved["editor_themes"] then
WeakAurasSaved["editor_themes"] = {
    ["selected"] = "Monokai",
    ["themes"] = {
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
      }
    }
  }
end
if not WeakAurasSaved["bracket_matching"] then
  WeakAurasSaved["bracket_matching"] = true
end

local function get_scheme(theme_name)
  local color_scheme = {
    [IndentationLib.tokens.TOKEN_SPECIAL] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Special"],
    [IndentationLib.tokens.TOKEN_KEYWORD] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Keyword"],
    [IndentationLib.tokens.TOKEN_COMMENT_SHORT] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Comment"],
    [IndentationLib.tokens.TOKEN_COMMENT_LONG] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Comment"],
    [IndentationLib.tokens.TOKEN_NUMBER] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Number"],

    [IndentationLib.tokens.TOKEN_STRING] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["String"],
    [".."] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["String"],

    ["..."] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Table"],
    ["{"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Table"],
    ["}"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Table"],
    ["["] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Table"],
    ["]"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Table"],

    ["+"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Arithmetic"],
    ["-"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Arithmetic"],
    ["/"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Arithmetic"],
    ["*"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Arithmetic"],

    ["=="] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],
    ["<"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],
    ["<="] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],
    [">"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],
    [">="] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],
    ["~="] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Relational"],

    ["and"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Logical"],
    ["or"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Logical"],
    ["not"] = WeakAurasSaved["editor_themes"]["themes"][theme_name]["Logical"],
    [0] = "|r",
  }
  return color_scheme
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

  IndentationLib.enable(editor.editBox, get_scheme(WeakAurasSaved["editor_themes"]["selected"]), 4)
  local is_settings_open = false
  local settings_frame = CreateFrame("Button", "WASettingsButton", close, "UIPanelButtonTemplate")
  settings_frame:SetPoint("RIGHT", close, "LEFT", -10, 0)
  settings_frame:SetHeight(20)
  settings_frame:SetWidth(100)
  settings_frame:SetText("Settings")
  settings_frame:EnableMouse(true)
  settings_frame:RegisterForClicks("AnyDown")

  local menu_frame = CreateFrame("Frame", "SettingsMenuFrame", settings_frame, "UIDropDownMenuTemplate")
  menu_frame:SetPoint("CENTER", settings_frame, "Center")
  menu_frame:Hide()

  local function settings_menu()
    local menu = {}
    -- themes options
    for k, v in pairs(WeakAurasSaved["editor_themes"]["themes"]) do
      local item = {
        text = k,
        isNotRadio = false,
        checked = (WeakAurasSaved["editor_themes"]["selected"] == k and true) or false,
        func = function()
          is_settings_open = false
          WeakAurasSaved["editor_themes"]["selected"] = k
          IndentationLib.enable(editor.editBox, get_scheme(k), 4)
          editor.editBox:SetText(editor.editBox:GetText())
        end
    }
    table.insert(menu, item)
    end
    -- bracket matching option
    table.insert(menu, {
      text = "Bracket Matching",
      isNotRadio = true,
      checked = WeakAurasSaved["bracket_matching"],
      func = function()
        is_settings_open = false
        WeakAurasSaved["bracket_matching"] = not WeakAurasSaved["bracket_matching"]
      end
    })
    return menu
  end


  settings_frame:SetScript("OnClick", function(self, button, down)
    if button == "LeftButton" then
        if is_settings_open then
          ToggleDropDownMenu(1, nil, menu_frame, settings_frame, 0, 0, settings_menu(), nil, 0)
          is_settings_open = false
        else
          EasyMenu(settings_menu(), menu_frame, settings_frame, 0, 0, "MENU")
          is_settings_open = true
      end
    end
  end)

  -- bracket mathcing, saving (ctrl + s) and closing (esc)
  editor.editBox:HookScript("OnKeyDown", function(_, key)
    if IsControlKeyDown() and key == "S" then
      close:Click("LeftButton", true)
      close:Click("LeftButton", false)
    end
    if key == "ESCAPE" then
      cancel:Click("LeftButton", true)
      cancel:Click("LeftButton", false)
    end
  end)

  editor.editBox:HookScript("OnChar", function(_, char)
    if not IsControlKeyDown() and WeakAurasSaved["bracket_matching"] then
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

  -- bracket mathcing, saving (ctrl + s) and closing (esc)
  editor.editBox:HookScript("OnKeyDown", function(_, key)
    if IsControlKeyDown() and key == "S" then
      close:Click("LeftButton", true)
      close:Click("LeftButton", false)
    end
    if key == "ESCAPE" then
      cancel:Click("LeftButton", true)
      cancel:Click("LeftButton", false)
    end
  end)

  editor.editBox:HookScript("OnChar", function(_, char)
    if not IsControlKeyDown() then
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
