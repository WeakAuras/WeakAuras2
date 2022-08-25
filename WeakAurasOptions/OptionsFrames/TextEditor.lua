if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

-- Lua APIs
local pairs, type, ipairs = pairs, type, ipairs
local loadstring = loadstring
local gsub = gsub

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local IndentationLib = IndentationLib

local WeakAuras = WeakAuras
local L = WeakAuras.L

local textEditor

local editor_themes = {
  ["Standard"] = {
    ["Table"] = "|c00ff3333",
    ["Arithmetic"] = "|c00ff3333",
    ["Relational"] = "|c00ff3333",
    ["Logical"] = "|c004444ff",
    ["Special"] = "|c00ff3333",
    ["Keyword"] = "|c004444ff",
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
    ["Keyword"] = "|c00f92672",
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
    ["Keyword"] = "|c0093C763",
    ["Comment"] = "|c0066747B",
    ["Number"] = "|c00FFCD22",
    ["String"] = "|c00EC7600"
  }
}

if not WeakAurasSaved.editor_tab_spaces then WeakAurasSaved.editor_tab_spaces = 4 end
if not WeakAurasSaved.editor_font_size then WeakAurasSaved.editor_font_size = 12 end -- set default font size if missing
local color_scheme = {[0] = "|r"}
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

-- Define the premade snippets
local premadeSnippets = {
  {
    name = "Basic function",
    snippet = [=[
function()

    return
end]=]
  },
  {
    name = "Custom Activation",
    snippet = [=[
function(trigger)
    return trigger[1] and (trigger[2] or trigger[3])
end]=]
  },
  {
    name = "Trigger: CLEU",
    snippet = [=[
function(event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)

    return
end]=]
  },
  {
    name = "Simple throttle",
    snippet = [=[
if not aura_env.last or aura_env.last < GetTime() - 1 then
    aura_env.last = GetTime()

end]=]
  },
  {
    name = "Trigger State Updater",
    snippet = [=[
function(allstates, event, ...)
    allstates[""] = {
        show = true,
        changed = true,
        progressType = "static"||"timed",
        value = ,
        total = ,
        duration = ,
        expirationTime = ,
        autoHide = true,
        name = ,
        icon = ,
        stacks = ,
        index = ,
    }
    return true
end]=]
  },
}

local function ConstructTextEditor(frame)
  local group = AceGUI:Create("WeakAurasInlineGroup")
  group.frame:SetParent(frame)
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 46);
  group.frame:Hide()
  group:SetLayout("flow")

  local title = AceGUI:Create("Label")
  title:SetFontObject(GameFontNormalHuge)
  title:SetFullWidth(true)
  title:SetText(L["Code Editor"])
  group:AddChild(title)

  local editor = AceGUI:Create("MultiLineEditBox")
  editor:SetFullWidth(true)
  editor:SetFullHeight(true)
  editor:DisableButton(true)
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium")
  if (fontPath) then
    editor.editBox:SetFont(fontPath, WeakAurasSaved.editor_font_size)
  end
  group:AddChild(editor)
  editor.frame:SetClipsChildren(true)

  local originalOnCursorChanged = editor.editBox:GetScript("OnCursorChanged")
  editor.editBox:SetScript("OnCursorChanged", function(self, ...)
    -- WORKAROUND the editbox sends spurious OnCursorChanged events if its resized
    -- That makes AceGUI scroll the editbox to make the cursor visible, leading to unintended
    -- movements. Prevent all of that by checking if the edit box has focus, as otherwise the cursor
    -- is invisible, and we don't care about making it visible
    if not self:HasFocus() then
      return
    end
    originalOnCursorChanged(self, ...)
  end)

  -- The indention lib overrides GetText, but for the line number
  -- display we ned the original, so save it here.
  local originalGetText = editor.editBox.GetText
  set_scheme()
  IndentationLib.enable(editor.editBox, color_scheme, WeakAurasSaved.editor_tab_spaces)

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  cancel:SetScript(
    "OnClick",
    function()
      group:CancelClose()
    end
  )
  cancel:SetPoint("BOTTOMRIGHT", -20, -24)
  cancel:SetFrameLevel(cancel:GetFrameLevel() + 1)
  cancel:SetHeight(20)
  cancel:SetWidth(100)
  cancel:SetText(L["Cancel"])

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  close:SetScript(
    "OnClick",
    function()
      group:Close()
    end
  )
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
  close:SetFrameLevel(close:GetFrameLevel() + 1)
  close:SetHeight(20)
  close:SetWidth(100)
  close:SetText(L["Done"])

  local settings_frame = CreateFrame("Button", "WASettingsButton", close, "UIPanelButtonTemplate")
  settings_frame:SetPoint("RIGHT", close, "LEFT", -10, 0)
  settings_frame:SetHeight(20)
  settings_frame:SetWidth(100)
  settings_frame:SetText(L["Settings"])
  settings_frame:RegisterForClicks("LeftButtonUp")

  local helpButton = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  helpButton:SetPoint("BOTTOMLEFT", 12, -24)
  helpButton:SetFrameLevel(cancel:GetFrameLevel() + 1)
  helpButton:SetHeight(20)
  helpButton:SetWidth(100)
  helpButton:SetText(L["Help"])

  local urlText = CreateFrame("EditBox", nil, group.frame)
  urlText:SetFrameLevel(cancel:GetFrameLevel() + 1)
  urlText:SetFont(STANDARD_TEXT_FONT, 12)
  urlText:EnableMouse(true)
  urlText:SetAutoFocus(false)
  urlText:SetCountInvisibleLetters(false)
  urlText:Hide()

  local urlCopyLabel = urlText:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  urlCopyLabel:SetPoint("BOTTOMLEFT", group.frame, "BOTTOMLEFT", 12, -20)
  urlCopyLabel:SetText(L["Press Ctrl+C to copy"])
  urlCopyLabel:Hide()

  urlText:SetPoint("TOPLEFT", urlCopyLabel, "TOPRIGHT", 12, 0)
  urlText:SetPoint("RIGHT", settings_frame, "LEFT")

  local dropdown = CreateFrame("Frame", "SettingsMenuFrame", settings_frame, "UIDropDownMenuTemplate")

  local function settings_dropdown_initialize(frame, level, menu)
    if level == 1 then
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
            editor.editBox:SetText(editor.editBox:GetText())
          end
        }
        UIDropDownMenu_AddButton(item, level)
      end
      UIDropDownMenu_AddButton(
        {
          text = L["Bracket Matching"],
          isNotRadio = true,
          checked = function()
            return WeakAurasSaved.editor_bracket_matching
          end,
          func = function()
            WeakAurasSaved.editor_bracket_matching = not WeakAurasSaved.editor_bracket_matching
          end
        },
      level)
      UIDropDownMenu_AddButton(
        {
          text = L["Indent Size"],
          hasArrow = true,
          notCheckable = true,
          menuList = "spaces"
        },
      level)
      UIDropDownMenu_AddButton(
        {
          text = WeakAuras.newFeatureString .. L["Font Size"],
          hasArrow = true,
          notCheckable = true,
          menuList = "sizes"
        },
      level)
    elseif menu == "spaces" then
      local spaces = {2,4}
      for _, i in pairs(spaces) do
        UIDropDownMenu_AddButton(
          {
            text = i,
            isNotRadio = false,
            checked = function()
              return WeakAurasSaved.editor_tab_spaces == i
            end,
            func = function()
              WeakAurasSaved.editor_tab_spaces = i
              IndentationLib.enable(editor.editBox, color_scheme, WeakAurasSaved.editor_tab_spaces)
              editor.editBox:SetText(editor.editBox:GetText().."\n")
              IndentationLib.indentEditbox(editor.editBox)
            end
          },
        level)
      end
    elseif menu == "sizes" then
      local sizes = {10, 12, 14, 16}
      for _, i in pairs(sizes) do
        UIDropDownMenu_AddButton(
          {
            text = i,
            isNotRadio = false,
            checked = function()
              return WeakAurasSaved.editor_font_size == i
            end,
            func = function()
              WeakAurasSaved.editor_font_size = i
              editor.editBox:SetFont(fontPath, WeakAurasSaved.editor_font_size)
            end
          },
        level)
      end
    end
  end
  UIDropDownMenu_Initialize(dropdown, settings_dropdown_initialize, "MENU")

  settings_frame:SetScript(
    "OnClick",
    function(self, button, down)
      ToggleDropDownMenu(1, nil, dropdown, settings_frame, 0, 0)
    end
  )

  -- Make Snippets button (top right, near the line number)
  local snippetsButton = CreateFrame("Button", "WASnippetsButton", group.frame, "UIPanelButtonTemplate")
  snippetsButton:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", 0, -15)
  snippetsButton:SetFrameLevel(group.frame:GetFrameLevel() + 2)
  snippetsButton:SetHeight(20)
  snippetsButton:SetWidth(100)
  snippetsButton:SetText(L["Snippets"])
  snippetsButton:RegisterForClicks("LeftButtonUp")

  -- Get the saved snippets from SavedVars
  WeakAurasOptionsSaved.savedSnippets = WeakAurasOptionsSaved.savedSnippets or {}
  local savedSnippets = WeakAurasOptionsSaved.savedSnippets

  -- function to build snippet selection list
  local function UpdateSnippets(frame)
    -- release first before rebuilding
    frame:ReleaseChildren()
    table.sort(
      savedSnippets,
      function(a, b)
        return a.name < b.name
      end
    )

    local heading1 = AceGUI:Create("Heading")
    heading1:SetText(L["Premade Snippets"])
    heading1:SetRelativeWidth(0.7)
    frame:AddChild(heading1)

    -- Iterate premade snippets and make buttons for them
    for order, snippet in ipairs(premadeSnippets) do
      local button = AceGUI:Create("WeakAurasSnippetButton")
      button:SetTitle(snippet.name)
      button:SetDescription(snippet.snippet)
      button:SetCallback(
        "OnClick",
        function()
          editor.editBox:Insert(snippet.snippet)
          editor:SetFocus()
        end
      )
      button:SetRelativeWidth(1)
      frame:AddChild(button)
    end

    local heading2 = AceGUI:Create("Heading")
    heading2:SetText(L["Your Saved Snippets"])
    heading2:SetRelativeWidth(1)
    frame:AddChild(heading2)

    -- iterate saved snippets and make buttons
    for order, snippet in ipairs(savedSnippets) do
      local button = AceGUI:Create("WeakAurasSnippetButton")
      local snippetInsert = gsub(snippet.snippet, "|", "||")
      button:SetTitle(snippet.name)
      button:SetDescription(snippetInsert)
      button:SetEditable(true)
      button:SetRelativeWidth(1)
      button:SetNew(snippet.new)
      snippet.new = false
      button:SetCallback(
        "OnClick",
        function()
          editor.editBox:Insert(snippetInsert)
          editor:SetFocus()
        end
      )
      button.deleteButton:SetScript(
        "OnClick",
        function()
          table.remove(savedSnippets, order)
          UpdateSnippets(frame)
        end
      )
      button:SetCallback(
        "OnEnterPressed",
        function()
          local newName = button.renameEditBox:GetText()
          if newName and #newName > 0 then
            local found = false
            for _, snippet in ipairs(savedSnippets) do
              if snippet.name == newName then
                found = true
                break
              end
            end
            if not found then
              savedSnippets[order].name = newName
              UpdateSnippets(frame)
            end
          end
        end
      )
      frame:AddChild(button)
    end
  end

  -- Make sidebar for snippets
  local snippetsFrame = CreateFrame("Frame", "WeakAurasSnippets", group.frame, "BackdropTemplate")
  snippetsFrame:SetPoint("TOPLEFT", group.frame, "TOPRIGHT", 20, 0)
  snippetsFrame:SetPoint("BOTTOMLEFT", group.frame, "BOTTOMRIGHT", 20, 0)
  snippetsFrame:SetWidth(250)
  snippetsFrame:SetBackdrop(
    {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = {left = 8, right = 8, top = 8, bottom = 8}
    }
  )
  snippetsFrame:SetBackdropColor(0, 0, 0, 1)

  -- Add button to save new snippet
  local AddSnippetButton = CreateFrame("Button", nil, snippetsFrame, "UIPanelButtonTemplate")
  AddSnippetButton:SetPoint("TOPLEFT", snippetsFrame, "TOPLEFT", 13, -10)
  AddSnippetButton:SetPoint("TOPRIGHT", snippetsFrame, "TOPRIGHT", -13, -10)
  AddSnippetButton:SetHeight(20)
  AddSnippetButton:SetText(L["Add Snippet"])
  AddSnippetButton:RegisterForClicks("LeftButtonUp")

  -- house the buttons in a scroll frame
  -- All AceGUI from this point, so that buttons can be released and reused
  local snippetsScrollContainer = AceGUI:Create("SimpleGroup")
  snippetsScrollContainer:SetFullWidth(true)
  snippetsScrollContainer:SetFullHeight(true)
  snippetsScrollContainer:SetLayout("Fill")
  snippetsScrollContainer.frame:SetParent(snippetsFrame)
  snippetsScrollContainer.frame:SetPoint("TOPLEFT", snippetsFrame, "TOPLEFT", 17, -35)
  snippetsScrollContainer.frame:SetPoint("BOTTOMRIGHT", snippetsFrame, "BOTTOMRIGHT", -10, 10)
  local snippetsScroll = AceGUI:Create("ScrollFrame")
  snippetsScroll:SetLayout("List")
  snippetsScrollContainer:AddChild(snippetsScroll)
  snippetsScroll:FixScroll(true)
  snippetsScroll.scrollframe:SetScript(
    "OnScrollRangeChanged",
    function(frame)
      frame.obj:DoLayout()
    end
  )

  snippetsFrame:Hide()

  -- Toggle the side bar on click
  snippetsButton:SetScript(
    "OnClick",
    function(self, button, down)
      if not snippetsFrame:IsShown() then
        snippetsFrame:Show()
        UpdateSnippets(snippetsScroll)
      else
        snippetsFrame:Hide()
      end
    end
  )

  AddSnippetButton:SetScript(
    "OnClick",
    function(self)
      local snippet = editor.editBox:GetText()
      if snippet and #snippet > 0 then
        local baseName, name, index = "New Snippet", "New Snippet", 0
        local snippetExists = function(name)
          for _, snippet in ipairs(savedSnippets) do
            if snippet.name == name then
              return true
            end
          end
        end
        while snippetExists(name) do
          index = index + 1
          name = format("%s %d", baseName, index)
        end
        table.insert(savedSnippets, {name = name, snippet = snippet, new = true})
        UpdateSnippets(snippetsScroll)
        end
      end
  )

  -- CTRL + S saves and closes
  editor.editBox:HookScript(
    "OnKeyDown",
    function(_, key)
      if IsControlKeyDown() and key == "S" then
        group:Close()
      end
    end
  )

  -- bracket matching
  editor.editBox:HookScript(
    "OnChar",
    function(_, char)
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
    end
  )

  local editorError = group.frame:CreateFontString(nil, "OVERLAY")
  editorError:SetFont(STANDARD_TEXT_FONT, 12)
  editorError:SetJustifyH("LEFT")
  editorError:SetJustifyV("TOP")
  editorError:SetTextColor(1, 0, 0)
  editorError:SetPoint("LEFT", helpButton, "RIGHT", 0, 4)
  editorError:SetPoint("RIGHT", settings_frame, "LEFT")

  local editorLine = CreateFrame("EditBox", nil, group.frame)
  -- Set script on enter pressed..
  editorLine:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", -100, -15)
  editorLine:SetFont(STANDARD_TEXT_FONT, 10)
  editorLine:SetJustifyH("RIGHT")
  editorLine:SetWidth(80)
  editorLine:SetHeight(20)
  editorLine:SetNumeric(true)
  editorLine:SetTextInsets(10, 10, 0, 0)
  editorLine:SetAutoFocus(false)

  urlText:SetScript(
    "OnChar",
    function(self)
      self:SetText(group.url)
      self:HighlightText()
    end
  )
  urlText:SetScript(
    "OnEscapePressed",
    function()
      urlText:ClearFocus()
      urlText:Hide()
      urlCopyLabel:Hide()
      helpButton:Show()
      editor:SetFocus()
    end
  )

  helpButton:SetScript(
    "OnClick",
    function()
      urlText:Show()
      urlText:SetFocus()
      urlText:HighlightText()
      urlCopyLabel:Show()
      helpButton:Hide()
      editorError:Hide()
    end
  )

  local oldOnCursorChanged = editor.editBox:GetScript("OnCursorChanged")
  editor.editBox:SetScript(
    "OnCursorChanged",
    function(...)
      oldOnCursorChanged(...)
      local cursorPosition = editor.editBox:GetCursorPosition()
      local next = -1
      local line = 0
      while (next and cursorPosition >= next) do
        next = originalGetText(editor.editBox):find("[\n]", next + 1)
        line = line + 1
      end
      editorLine:SetNumber(line)
    end
  )

  editorLine:SetScript(
    "OnEnterPressed",
    function()
      local newLine = editorLine:GetNumber()
      local newPosition = 0
      while (newLine > 1 and newPosition) do
        newPosition = originalGetText(editor.editBox):find("[\n]", newPosition + 1)
        newLine = newLine - 1
      end

      if (newPosition) then
        editor.editBox:SetCursorPosition(newPosition)
        editor.editBox:SetFocus()
      end
    end
  )

  function group.Open(self, data, path, enclose, multipath, reloadOptions, setOnParent, url, validator)
    self.data = data
    self.path = path
    self.multipath = multipath
    self.reloadOptions = reloadOptions
    self.setOnParent = setOnParent
    self.url = url
    urlText:SetText(url or "")
    urlText:Hide()
    urlCopyLabel:Hide()
    if url then
      helpButton:Show()
    else
      helpButton:Hide()
    end
    if (frame.window == "texture") then
      frame.texturePicker:CancelClose()
    elseif (frame.window == "icon") then
      frame.iconPicker:CancelClose()
    end
    frame.window = "texteditor"
    frame:UpdateFrameVisible()
    local title = (type(data.id) == "string" and data.id or L["Temporary Group"]) .. " -"
    if (not multipath) then
      for index, field in pairs(path) do
        if (type(field) == "number") then
          field = "Trigger " .. field
        end
        title = title .. " " .. field:sub(1, 1):upper() .. field:sub(2)
      end
    end
    editor:SetLabel(title)
    editor.editBox:SetScript(
      "OnEscapePressed",
      function()
        -- catch it so that escape doesn't default to losing focus (after which another escape would close config)
      end
    )
    self.oldOnTextChanged = editor.editBox:GetScript("OnTextChanged")
    editor.editBox:SetScript(
      "OnTextChanged",
      function(...)
        local str = editor.editBox:GetText()
        if not str or str:trim() == "" or editor.combinedText == true then
          editorError:SetText("")
        else
          local func, errorString
          if (enclose) then
            func, errorString = loadstring("return function() " .. str .. "\n end")
          else
            func, errorString = loadstring("return " .. str)
          end
          if not errorString and validator then
            local ok, validate = xpcall(func, function(err) errorString = err end)
            if ok then
              errorString = validator(validate)
            end
          end
          if errorString then
            urlText:Hide()
            urlCopyLabel:Hide()
            if self.url then
              helpButton:Show()
            end
            editorError:Show()
            editorError:SetText(errorString)
          else
            editorError:SetText("")
          end
        end
        self.oldOnTextChanged(...)
      end
    )

    if setOnParent then
      editor:SetText(OptionsPrivate.Private.ValueFromPath(data, path) or "")
    else
      local singleText
      local sameTexts = true
      local combinedText = ""
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
        local text
        if multipath then
          text = path[child.id] and OptionsPrivate.Private.ValueFromPath(child, path[child.id])
        else
          text = OptionsPrivate.Private.ValueFromPath(child, path)
        end
        if text then
          if not (singleText) then
            singleText = text
          else
            if singleText ~= text then
              sameTexts = false
            end
          end
          if combinedText ~= "" then
            combinedText = combinedText .. "\n\n"
          end

          combinedText =
            combinedText .. L["-- Do not remove this comment, it is part of this aura: "] .. child.id .. "\n"
          combinedText = combinedText .. (text or "")
        end
      end
      if (sameTexts) then
        editor:SetText(singleText or "")
        editor.combinedText = false
      else
        editor:SetText(combinedText)
        editor.combinedText = true
      end
    end
    editor:SetFocus()
  end

  function group.CancelClose(self)
    editor.editBox:SetScript("OnTextChanged", self.oldOnTextChanged)
    editor:ClearFocus()
    frame.window = "default"
    frame:UpdateFrameVisible()
  end

  local function extractTexts(input)
    local texts = {}

    local currentPos, id, startIdLine, startId, endId, endIdLine
    while (true) do
      startIdLine, startId =
        string.find(input, L["-- Do not remove this comment, it is part of this aura: "], currentPos, true)
      if (not startId) then
        break
      end

      endId, endIdLine = string.find(input, "\n", startId, true)
      if (not endId) then
        break
      end

      if (currentPos) then
        local trimmedPosition = startIdLine - 1
        while (string.sub(input, trimmedPosition, trimmedPosition) == "\n") do
          trimmedPosition = trimmedPosition - 1
        end

        texts[id] = string.sub(input, currentPos, trimmedPosition)
      end

      id = string.sub(input, startId + 1, endId - 1)

      currentPos = endIdLine + 1
    end

    if (id) then
      texts[id] = string.sub(input, currentPos, string.len(input))
    end

    return texts
  end

  function group.Close(self)
    if self.setOnParent then
      OptionsPrivate.Private.ValueToPath(self.data, self.path, editor:GetText())
      WeakAuras.Add(self.data)
    else
      local textById = editor.combinedText and extractTexts(editor:GetText())
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(self.data) do
        local text = editor.combinedText and (textById[child.id] or "") or editor:GetText()
        OptionsPrivate.Private.ValueToPath(child, self.multipath and self.path[child.id] or self.path, text)
        WeakAuras.Add(child)
        OptionsPrivate.ClearOptions(child.id)
      end
    end

    WeakAuras.ClearAndUpdateOptions(self.data.id)

    editor.editBox:SetScript("OnTextChanged", self.oldOnTextChanged)
    editor:ClearFocus()
    frame.window = "default"
    frame:UpdateFrameVisible()
    WeakAuras.FillOptions()
  end

  return group
end

function OptionsPrivate.TextEditor(frame)
  textEditor = textEditor or ConstructTextEditor(frame)
  return textEditor
end
