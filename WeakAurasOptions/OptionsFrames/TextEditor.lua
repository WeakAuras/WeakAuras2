if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local pairs, type, ipairs = pairs, type, ipairs
local gsub = gsub

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local LAAC = LibStub("LibAPIAutoComplete-1.0")

local IndentationLib = IndentationLib

---@class WeakAuras
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
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -63);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 46);
  group.frame:Hide()
  group:SetLayout("flow")

  local editor = AceGUI:Create("MultiLineEditBox")
  editor:SetFullWidth(true)
  editor:SetFullHeight(true)
  editor:DisableButton(true)
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium")
  if (fontPath) then
    editor.editBox:SetFont(fontPath, WeakAurasSaved.editor_font_size, "")
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
  local originalSetText = editor.editBox.SetText
  set_scheme()
  LAAC:enable(editor.editBox)
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
  helpButton:SetPoint("BOTTOMLEFT", 0, -24)
  helpButton:SetFrameLevel(cancel:GetFrameLevel() + 1)
  helpButton:SetHeight(20)
  helpButton:SetWidth(100)
  helpButton:SetText(L["Help"])

  local dropdown = LibDD:Create_UIDropDownMenu("SettingsMenuFrame", settings_frame)


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
        LibDD:UIDropDownMenu_AddButton(item, level)
      end
      LibDD:UIDropDownMenu_AddButton(
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
      LibDD:UIDropDownMenu_AddButton(
        {
          text = L["Indent Size"],
          hasArrow = true,
          notCheckable = true,
          menuList = "spaces"
        },
      level)
      LibDD:UIDropDownMenu_AddButton(
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
        LibDD:UIDropDownMenu_AddButton(
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
        LibDD:UIDropDownMenu_AddButton(
          {
            text = i,
            isNotRadio = false,
            checked = function()
              return WeakAurasSaved.editor_font_size == i
            end,
            func = function()
              WeakAurasSaved.editor_font_size = i
              editor.editBox:SetFont(fontPath, WeakAurasSaved.editor_font_size, "")
            end
          },
        level)
      end
    end
  end
  LibDD:UIDropDownMenu_Initialize(dropdown, settings_dropdown_initialize, "MENU")

  settings_frame:SetScript(
    "OnClick",
    function(self, button, down)
      LibDD:ToggleDropDownMenu(1, nil, dropdown, settings_frame, 0, 0)
    end
  )

  -- Make Snippets button (top right, near the line number)
  local snippetsButton = CreateFrame("Button", "WASnippetsButton", group.frame, "UIPanelButtonTemplate")
  snippetsButton:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", -20, -10)
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

  local apiSearchFrame

  -- Make sidebar for snippets
  local snippetsFrame = CreateFrame("Frame", "WeakAurasSnippets", group.frame, "PortraitFrameTemplate")
  ButtonFrameTemplate_HidePortrait(snippetsFrame)
  snippetsFrame:SetPoint("TOPLEFT", group.frame, "TOPRIGHT", 20, 0)
  snippetsFrame:SetPoint("BOTTOMLEFT", group.frame, "BOTTOMRIGHT", 20, 0)
  snippetsFrame:SetWidth(250)
  if snippetsFrame.Bg then
    local color = CreateColorFromHexString("ff1f1e21") -- PANEL_BACKGROUND_COLOR
    local r, g, b = color:GetRGB()
    snippetsFrame.Bg:SetColorTexture(r, g, b, 0.8)
  end

  -- Add button to save new snippet
  local AddSnippetButton = CreateFrame("Button", nil, snippetsFrame, "UIPanelButtonTemplate")
  AddSnippetButton:SetPoint("TOPLEFT", snippetsFrame, "TOPLEFT", 13, -25)
  AddSnippetButton:SetPoint("TOPRIGHT", snippetsFrame, "TOPRIGHT", -13, -25)
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
  snippetsScrollContainer.frame:SetPoint("TOPLEFT", snippetsFrame, "TOPLEFT", 17, -50)
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
        if apiSearchFrame and apiSearchFrame:IsShown() then
          apiSearchFrame:Hide()
        end
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

  -- Make ApiSearch button
  local apiSearchButton = CreateFrame("Button", "WAAPISearchButton", group.frame, "UIPanelButtonTemplate")
  apiSearchButton:SetPoint("BOTTOMRIGHT", editor.frame, "TOPRIGHT", -20, 15)
  apiSearchButton:SetFrameLevel(group.frame:GetFrameLevel() + 2)
  apiSearchButton:SetHeight(20)
  apiSearchButton:SetWidth(100)
  apiSearchButton:SetText(L["Search API"])
  apiSearchButton:RegisterForClicks("LeftButtonUp")

  -- Make sidebar for apiSearch
  apiSearchFrame = CreateFrame("Frame", "WeakAurasAPISearchFrame", group.frame, "PortraitFrameTemplate")
  ButtonFrameTemplate_HidePortrait(apiSearchFrame)
  apiSearchFrame:SetWidth(350)
  if apiSearchFrame.Bg then
    local color = CreateColorFromHexString("ff1f1e21") -- PANEL_BACKGROUND_COLOR
    local r, g, b = color:GetRGB()
    apiSearchFrame.Bg:SetColorTexture(r, g, b, 0.8)
  end

  local makeAPISearch
  local APISearchTextChangeDelay = 0.3
  local APISearchCTimer

  -- filter line
  local filterInput = CreateFrame("EditBox", "WeakAurasAPISearchFilterInput", apiSearchFrame, "SearchBoxTemplate")
  filterInput:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    if APISearchCTimer then
      APISearchCTimer:Cancel()
    end
    APISearchCTimer = C_Timer.NewTimer(
      APISearchTextChangeDelay,
      function()
        makeAPISearch(filterInput:GetText())
      end
    )
  end)
  filterInput:SetHeight(15)
  filterInput:SetPoint("TOPLEFT", apiSearchFrame, "TOPLEFT", 17, -30)
  filterInput:SetPoint("TOPRIGHT", apiSearchFrame, "TOPRIGHT", -10, -30)
  filterInput:SetFont(STANDARD_TEXT_FONT, 10, "")

  local apiSearchScrollContainer = AceGUI:Create("SimpleGroup")
  apiSearchScrollContainer:SetFullWidth(true)
  apiSearchScrollContainer:SetFullHeight(true)
  apiSearchScrollContainer:SetLayout("Fill")
  apiSearchScrollContainer.frame:SetParent(apiSearchFrame)
  apiSearchScrollContainer.frame:SetPoint("TOPLEFT", apiSearchFrame, "TOPLEFT", 17, -50)
  apiSearchScrollContainer.frame:SetPoint("BOTTOMRIGHT", apiSearchFrame, "BOTTOMRIGHT", -10, 10)

  local apiSearchScroll = AceGUI:Create("ScrollFrame")
  apiSearchScroll:SetLayout("List")
  apiSearchScrollContainer:AddChild(apiSearchScroll)
  apiSearchScroll:FixScroll(true)
  apiSearchScroll.scrollframe:SetScript(
    "OnScrollRangeChanged",
    function(frame)
      frame.obj:DoLayout()
    end
  )

  local snippetOnClickCallback = function(self)
    if self.isSystem then
      filterInput:SetText(self.name)
    else
      self.editor.editBox:Insert(self.name)
      self.editor:SetFocus()
    end
  end

  local function loadBlizzardAPIDocumentation()
    local apiAddonName = "Blizzard_APIDocumentation"
    local _, loaded = C_AddOns.IsAddOnLoaded(apiAddonName)
    if not loaded then
      C_AddOns.LoadAddOn(apiAddonName)
    end
    if #APIDocumentation.systems == 0 then
      APIDocumentation_LoadUI()
    end
  end

  local function addLine(results, apiInfo)
    local name
    if apiInfo.Type == "System" then
      name = apiInfo.Namespace
    elseif apiInfo.Type == "Function" then
      name = apiInfo:GetFullName()
    elseif apiInfo.Type == "Event" then
      name = apiInfo.LiteralName
    end
    table.insert(results, { name = name, apiInfo = apiInfo })
  end

  local function APIListSystems()
    local results = {}
    for i, systemInfo in ipairs(APIDocumentation.systems) do
      if systemInfo.Namespace and #systemInfo.Functions > 0 then
        addLine(results, systemInfo)
      end
    end
    table.sort(results, function(a, b)
      return a.name < b.name
    end)
    return results
  end

  local function APISearch(word)
    local lowerWord = word:lower()
    local results = {}

    -- if search match name of namespace, show all functions & events for the namespace, and also show all other functions & events matching the search
    -- if search is composed with name of a namespace and a word separated by a dot, show matching function for matching namespace

    local nsName, rest = lowerWord:match("^([%w%_]+)(.*)")
    local funcName = rest and rest:match("^%.([%w%_]+)")

    for _, systemInfo in ipairs(APIDocumentation.systems) do
      -- search for namespaceName or namespaceName.functionName
      local systemMatch = nsName and #nsName >= 4
        and systemInfo.Namespace and systemInfo.Namespace:lower():match(nsName)

      for _, apiInfo in ipairs(systemInfo.Functions) do
        if systemMatch then
          if funcName then
            if apiInfo:MatchesSearchString(funcName) then
              addLine(results, apiInfo)
            end
          else
            addLine(results, apiInfo)
          end
        else
          if apiInfo:MatchesSearchString(lowerWord) then
            addLine(results, apiInfo)
          end
        end
      end

      if systemMatch and rest == "" then
        for _, apiInfo in ipairs(systemInfo.Events) do
          addLine(results, apiInfo)
        end
      else
        for _, apiInfo in ipairs(systemInfo.Events) do
          if apiInfo:MatchesSearchString(lowerWord) then
            addLine(results, apiInfo)
          end
        end
      end
    end

    return results
  end

  local lastSearch = nil
  makeAPISearch = function(apiToSearchFor)
    loadBlizzardAPIDocumentation()
    local results
    if not apiToSearchFor or #apiToSearchFor < 4 then
      if lastSearch == "" then return end
      results = APIListSystems()
      lastSearch = ""
    else
      if lastSearch == apiToSearchFor then return end
      results = APISearch(apiToSearchFor)
      lastSearch = apiToSearchFor
    end
    apiSearchScroll:ReleaseChildren()
    for _, element in ipairs(results) do
      local apiInfo = element.apiInfo
      if apiInfo then
        local button = AceGUI:Create("WeakAurasSnippetButton")
        button:SetTitle(element.name)
        button:SetEditable(false)
        button:SetHeight(20)
        button:SetRelativeWidth(1)
        if apiInfo.Type ~= "System" and apiInfo.GetDetailedOutputLines then
          local desc = table.concat(apiInfo:GetDetailedOutputLines(), "\n")
          button:SetDescription(desc)
        else
          button:SetDescription()
        end
        button.name = element.name
        button.editor = editor
        button.isSystem = apiInfo.Type == "System"
        button:SetCallback("OnClick", snippetOnClickCallback)
        apiSearchScroll:AddChild(button)
      end
    end
  end

  apiSearchFrame:Hide()

  -- Toggle the side bar on click
  apiSearchButton:SetScript(
    "OnClick",
    function()
      if apiSearchFrame:IsShown() then
        apiSearchFrame:Hide()
      else
        apiSearchFrame:Show()
        apiSearchFrame:ClearAllPoints()
        apiSearchFrame:SetPoint("TOPLEFT", group.frame, "TOPRIGHT", 20, 0)
        apiSearchFrame:SetPoint("BOTTOMLEFT", group.frame, "BOTTOMRIGHT", 20, 0)
        filterInput:SetFocus()
        if snippetsFrame and snippetsFrame:IsShown() then
          snippetsFrame:Hide()
        end
      end
    end
  )

  editor.editBox.timeMachine = {}
  editor.editBox.timeMachinePos = 1
  local TimeMachineMaximumRollback = 10

  editor.editBox:HookScript(
    "OnKeyDown",
    function(self, key)
      -- CTRL + S saves and closes
      if IsControlKeyDown() and key == "S" then
        group:Close()
      elseif key == "Z" and IsControlKeyDown() then
        self:SetPropagateKeyboardInput(false)
        if self.timeMachine[self.timeMachinePos + 1] then
          self.timeMachinePos = self.timeMachinePos + 1
          self.skipOnTextChanged = true
          originalSetText(self, self.timeMachine[self.timeMachinePos][1])
          self:SetCursorPosition(self.timeMachine[self.timeMachinePos][2])
        end
      elseif key == "Y" and IsControlKeyDown() then
        self:SetPropagateKeyboardInput(false)
        if self.timeMachine[self.timeMachinePos - 1] then
          self.timeMachinePos = self.timeMachinePos - 1
          self.skipOnTextChanged = true
          originalSetText(self, self.timeMachine[self.timeMachinePos][1])
          self:SetCursorPosition(self.timeMachine[self.timeMachinePos][2])
        end
      end
    end
  )

  editor.editBox:HookScript(
    "OnTextChanged",
    function(self, userInput)
      if not userInput then return end
      if self.skipOnTextChanged then
        self.skipOnTextChanged = false
        return
      end
      local cursorPosition = self:GetCursorPosition()
      local text = originalGetText(self)
      if IndentationLib then
        text, cursorPosition = IndentationLib.stripWowColorsWithPos(text, cursorPosition)
      end
      if self.timeMachine[1] and text == self.timeMachine[1][1] then
        return
      end
      -- if cursor is not at position 1, remove elements before cursor
      for i = 2, self.timeMachinePos do
        table.remove(self.timeMachine, 1)
      end
      -- insert current text
      table.insert(self.timeMachine, 1, {text, cursorPosition - 1})
      -- timeMachine is limited to a number of TimeMachineMaximumRollback elements
      for i = #self.timeMachine, TimeMachineMaximumRollback + 1, -1 do
        table.remove(self.timeMachine, i)
      end
      self.timeMachinePos = 1
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
  editorError:SetFont(STANDARD_TEXT_FONT, 12, "")
  editorError:SetJustifyH("LEFT")
  editorError:SetJustifyV("TOP")
  editorError:SetTextColor(1, 0, 0)
  editorError:SetPoint("LEFT", helpButton, "RIGHT", 0, 4)
  editorError:SetPoint("RIGHT", settings_frame, "LEFT")

  local editorLine = CreateFrame("EditBox", nil, group.frame, "InputBoxTemplate")
  -- Set script on enter pressed..
  editorLine:SetPoint("RIGHT", snippetsButton, "LEFT", -10, 0)
  editorLine:SetFont(STANDARD_TEXT_FONT, 10, "")
  editorLine:SetJustifyH("RIGHT")
  editorLine:SetWidth(30)
  editorLine:SetHeight(20)
  editorLine:SetNumeric(true)
  editorLine:SetTextInsets(0, 5, 0, 0)
  editorLine:SetAutoFocus(false)

  local editorLineText = group.frame:CreateFontString(nil, "OVERLAY")
  editorLineText:SetFont(STANDARD_TEXT_FONT, 10)
  editorLineText:SetTextColor(1, 1, 1)
  editorLineText:SetText(L["Line"])
  editorLineText:SetPoint("RIGHT", editorLine, "LEFT", -8, 0)

  helpButton:SetScript("OnClick", function()
    OptionsPrivate.ToggleTip(helpButton, group.url, L["Help"], "")
  end)

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
    if url then
      helpButton:Show()
    else
      helpButton:Hide()
    end
    if (frame.window == "texture") then
      local texturepicker = OptionsPrivate.TexturePicker(frame, true)
      if texturepicker then
        texturepicker:CancelClose()
      end
    elseif (frame.window == "icon") then
      local iconpicker = OptionsPrivate.IconPicker(frame, true)
      if iconpicker then
        iconpicker:CancelClose()
      end
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
    editor.editBox.timeMachine = {}
    editor.editBox.timeMachinePos = 1
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
            func, errorString = OptionsPrivate.Private.LoadFunction("return function() " .. str .. "\n end", true)
          else
            func, errorString = OptionsPrivate.Private.LoadFunction("return " .. str, true)
          end
          if not errorString and validator then
            errorString = validator(func)
          end
          if errorString then
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
    frame:HideTip()
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

function OptionsPrivate.TextEditor(frame, noConstruct)
  textEditor = textEditor or (not noConstruct and ConstructTextEditor(frame))
  return textEditor
end
