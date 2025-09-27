local MAJOR, MINOR = "LibAPIAutoComplete-1.0", 5
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local SharedMedia = LibStub("LibSharedMedia-3.0")

local config = {}

local skipWords = {
  ["local"] = true,
  ["print"] = true,
  ["player"] = true,
  ["display"] = true,
  ["return"] = true,
  ["function"] = true
}

local maxMatches = 100

for k in pairs(skipWords) do
  for i = #k, 5, -1 do
     skipWords[k:sub(1, i)] = true
  end
end

local function LoadBlizzard_APIDocumentation()
  local apiAddonName = "Blizzard_APIDocumentation"
  local _, loaded = C_AddOns.IsAddOnLoaded(apiAddonName)
  if not loaded then
    C_AddOns.LoadAddOn(apiAddonName)
  end
  if #APIDocumentation.systems == 0 then
    -- workaround nil errors when loading PetConstantsDocumentation.lua
    Constants.PetConsts = Constants.PetConsts or {
      MAX_STABLE_SLOTS = 200,
      MAX_SUMMONABLE_PETS = 25,
      MAX_SUMMONABLE_HUNTER_PETS = 5,
      NUM_PET_SLOTS_THAT_NEED_LEARNED_SPELL = 5,
      NUM_PET_SLOTS = 205,
      EXTRA_PET_STABLE_SLOT = 5,
      STABLED_PETS_FIRST_SLOT_INDEX = 6
    }
    MAX_STABLE_SLOTS = MAX_STABLE_SLOTS or 2
    NUM_PET_SLOTS_THAT_NEED_LEARNED_SPELL = NUM_PET_SLOTS_THAT_NEED_LEARNED_SPELL or 1
    EXTRA_PET_STABLE_SLOT = EXTRA_PET_STABLE_SLOT or 0
    -- end of workaround
    APIDocumentation_LoadUI()
  end
end

function lib:Hide()
  self.scrollBox:Hide()
  self.scrollBar:Hide()
end

---Create APIDoc widget and ensure Blizzard_APIDocumentation is loaded
local isInit = false
local function Init()
  if isInit then
    return
  end
  isInit = true

  -- load Blizzard_APIDocumentation
  LoadBlizzard_APIDocumentation()

  local scrollBox = CreateFrame("Frame", nil, UIParent, "WowScrollBoxList")
  scrollBox:SetSize(400, 150)
  scrollBox:Hide()

  local background = scrollBox:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  scrollBox.background = background

  local scrollBar = CreateFrame("EventFrame", nil, UIParent, "WowTrimScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT")
  scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT")
  scrollBar:Hide()

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(dataIndex, elementData)
    return 20
  end)
  view:SetElementInitializer("button", function(frame, elementData)
    Mixin(frame, APIAutoCompleteLineMixin)
    frame:Init(elementData)
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
  local selectionBehaviour = ScrollUtil.AddSelectionBehavior(scrollBox, SelectionBehaviorFlags.Deselectable, SelectionBehaviorFlags.Intrusive)
  selectionBehaviour:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, function(o, elementData, selected)
    local elementFrame = scrollBox:FindFrame(elementData)
    if elementFrame then
      elementFrame:SetSelected(selected)
    end

    if selected and lib.editbox and config[lib.editbox] then
      local maxLinesShown = config[lib.editbox].maxLinesShown
      local index = lib.data:FindIndex(elementData)
      local divisor = lib.data:GetSize() - maxLinesShown
      if divisor == 0 then
        divisor = 1
      end
      local percent = (index - maxLinesShown / 2) / divisor
      if percent < 0 then
        percent = 0
      elseif percent > 1 then
        percent = 1
      end
      scrollBar:SetScrollPercentage(percent)
    end
  end)

  lib.data = CreateDataProvider()
  scrollBox:SetDataProvider(lib.data)

  lib.scrollBar = scrollBar
  lib.scrollBox = scrollBox
  lib.selectionBehaviour = selectionBehaviour

  scrollBox.selectionBehaviour = selectionBehaviour

  scrollBox:SetScript("OnKeyDown", function(self, key)
    if key == "DOWN" then
      lib.scrollBox:SetPropagateKeyboardInput(false)
      if not self.selectionBehaviour:HasSelection() then
        self.selectionBehaviour:SelectFirstElementData()
      else
        self.selectionBehaviour:SelectNextElementData()
      end
    elseif key == "UP" then
      lib.scrollBox:SetPropagateKeyboardInput(false)
      if not self.selectionBehaviour:HasSelection() then
        self.selectionBehaviour:SelectFirstElementData()
      else
        self.selectionBehaviour:SelectPreviousElementData()
      end
    elseif key == "ENTER" and not IsModifierKeyDown() then
      local selectedElementData = self.selectionBehaviour:GetFirstSelectedElementData()
      if selectedElementData then
        lib.scrollBox:SetPropagateKeyboardInput(false)
        local elementFrame = scrollBox:FindFrame(selectedElementData)
        elementFrame:Insert()
      end
    elseif key == "ESCAPE" then
      lib.scrollBox:SetPropagateKeyboardInput(false)
      lib.data:Flush()
      lib:UpdateWidget(lib.editbox)
    else
      lib.scrollBox:SetPropagateKeyboardInput(true)
      lib.data:Flush()
      lib:UpdateWidget(lib.editbox)
    end
  end)
end

local lastPosition

---@private
---@param editbox EditBox
---@param x number
---@param y number
---@param w number
---@param h number
local function OnTextChanged(editbox, x, y, w, h)
  local cursorPosition = editbox:GetCursorPosition()
  if cursorPosition ~= lastPosition then
    lib:Hide()
    lib.scrollBox:ClearAllPoints()
    lib.scrollBox:SetPoint("TOPLEFT", editbox, "TOPLEFT", x, y - h)
    local currentWord = lib:GetWord(editbox)
    if #currentWord > 4 and not skipWords[currentWord] then
      lib:Search(currentWord, config[editbox])
      if lib.data:GetSize() == 1 and lib.data:Find(1).name == currentWord then
        lib.data:Flush()
      end
      lib:UpdateWidget(editbox)
    end
  end
  lastPosition = cursorPosition
end

---@class Color
---@field r integer
---@field g integer
---@field b integer
---@field a integer?

---@class Params
---@field backgroundColor Color?
---@field maxLinesShown integer?
---@field disableFunctions boolean?
---@field disableEvents boolean?
---@field disableSystems boolean?

---Enable APIDoc widget on editbox
---ForAllIndentsAndPurpose replace GetText, APIDoc must be enabled before FAIAP
---@param editbox EditBox
---@param params Params
function lib:enable(editbox, params)
  if config[editbox] then
    return
  end
  config[editbox] = {
    backgroundColor = params and params.backgroundColor or {.3, .3, .3, .9},
    maxLinesShown = params and params.maxLinesShown or 7,
    disableFunctions = params and params.disableFunctions or false,
    disableEvents = params and params.disableEvents or false,
    disableSystems = params and params.disableSystems or false,
  }
  Init()
  -- hack for WeakAuras
  editbox.APIDoc_originalGetText = editbox.GetText
  editbox.APIDoc_originalSetText = editbox.SetText
  -- hack for WowLua
  if editbox == WowLuaFrameEditBox then
    editbox.APIDoc_originalGetText = function()
      return WowLua.indent.coloredGetText(editbox)
    end
  end
  editbox.APIDoc_oldOnCursorChanged = editbox:GetScript("OnCursorChanged")
  editbox:SetScript("OnCursorChanged", function(...)
    if editbox.APIDoc_oldOnCursorChanged then
      editbox.APIDoc_oldOnCursorChanged(...)
    end
    local _, x, y, w, h = ...
    editbox.lastCursorChanged = {
      time = GetTime(),
      x = x,
      y = y,
      w = w,
      h = h
    }
  end)
  editbox.APIDoc_oldOnTextChanged = editbox:GetScript("OnTextChanged")
  editbox:SetScript("OnTextChanged", function(...)
    if editbox.APIDoc_oldOnTextChanged then
      editbox.APIDoc_oldOnTextChanged(...)
    end
    local info = editbox.lastCursorChanged
    if info and info.time == GetTime() then
      OnTextChanged(editbox, info.x, info.y, info.w, info.h)
    end
  end)
  editbox:SetScript("OnHide", function(...)
    lib:Hide()
  end)
  editbox.APIDoc_hiddenString = editbox:CreateFontString()
end

---Disable APIDoc widget on editbox
---@param editbox EditBox
function lib:disable(editbox)
  if not config[editbox] then
    return
  end
  config[editbox] = nil
  editbox:SetScript("OnCursorChanged", editbox.APIDoc_oldOnCursorChanged)
  editbox.APIDoc_oldOnCursorChanged = nil
  editbox:SetScript("OnTextChanged", editbox.APIDoc_oldOnTextChanged)
  editbox.APIDoc_oldOnTextChanged = nil
end

function lib:addLine(apiInfo)
  local name
  if apiInfo.Type == "System" then
    name = apiInfo.Namespace
  elseif apiInfo.Type == "Function" then
    name = apiInfo:GetFullName()
  elseif apiInfo.Type == "Event" then
    name = apiInfo.LiteralName
  end
  self.data:Insert({ name = name, apiInfo = apiInfo })
end

---Search a word in documentation, set results in lib.data
---@param word string
---@param config Params
function lib:Search(word, config)
  self.data:Flush()
  if word and #word > 3 then
    local lowerWord = word:lower();
    local nsName, rest = lowerWord:match("^([%w%_]+)(.*)")
    local funcName = rest and rest:match("^%.([%w%_]+)")
    for _, systemInfo in ipairs(APIDocumentation.systems) do
      local systemMatch = (not config.disableSystems)
        and (nsName and #nsName >= 4)
        and (systemInfo.Namespace and systemInfo.Namespace:lower():match(nsName))

      if not config.disableFunctions then
        for _, apiInfo in ipairs(systemInfo.Functions) do
          if systemMatch then
            if funcName then
              if apiInfo:MatchesSearchString(funcName) then
                self:addLine(apiInfo)
              end
            else
              self:addLine(apiInfo)
            end
          else
            if apiInfo:MatchesSearchString(lowerWord) then
              self:addLine(apiInfo)
            end
          end
        end
      end

      if not config.disableEvents then
        if systemMatch and rest == "" then
          for _, apiInfo in ipairs(systemInfo.Events) do
            self:addLine(apiInfo)
          end
        else
          for _, apiInfo in ipairs(systemInfo.Events) do
            if apiInfo:MatchesSearchString(lowerWord) then
              self:addLine(apiInfo)
            end
          end
        end
      end

      if self.data:GetSize() > maxMatches then
        break
      end
    end
  end
end

---set in lib.data the list of systems
function lib:ListSystems()
  self.data:Flush()
  for i, systemInfo in ipairs(APIDocumentation.systems) do
    if systemInfo.Namespace and #systemInfo.Functions > 0 then
      self:addLine(systemInfo)
    end
  end
end

---Hide, or Show and fill APIDoc widget, using lib.data data
---@param editbox EditBox
function lib:UpdateWidget(editbox)
  if self.data:IsEmpty() then
    self:Hide()
    self.editbox = nil
  else
    -- fix size
    local maxLinesShown = config[editbox].maxLinesShown
    local lines = self.data:GetSize()
    local height = math.min(lines, maxLinesShown) * 20
    local width = 0
    local hiddenString = editbox.APIDoc_hiddenString
    local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium")
    hiddenString:SetFont(fontPath, 12, "")
    for _, elementData in self.data:Enumerate() do
      hiddenString:SetText(elementData.name)
      width = math.max(width, hiddenString:GetStringWidth())
    end
    self.scrollBox:SetSize(width, height)

    -- fix look
    local backgroundColor = config[editbox].backgroundColor
    self.scrollBox.background:SetColorTexture(unpack(backgroundColor))

    -- show
    self.scrollBox:SetParent(UIParent)
    self.scrollBar:SetParent(UIParent)
    self.scrollBox:SetFrameStrata("TOOLTIP")
    self.scrollBar:SetFrameStrata("TOOLTIP")
    self.scrollBox:Show()
    self.scrollBar:SetShown(lines > maxLinesShown)
    self.editbox = editbox
  end
end

local function OnClickCallback(self)
  local name
  if IndentationLib then
    name = IndentationLib.stripWowColors(self.name)
  elseif WowLua and WowLua.indent then
    name = WowLua.indent.stripWowColors(self.name)
  end
  lib:SetWord(lib.editbox, name)
  lib:Hide()
  lib.editbox:SetFocus()
end

---@param editbox EditBox
---@return string currentWord
---@return integer startPosition
---@return integer endPosition
function lib:GetWord(editbox)
  -- get cursor position
  local cursorPosition = editbox:GetCursorPosition()
  local text = editbox:APIDoc_originalGetText()
  if IndentationLib then
    text, cursorPosition = IndentationLib.stripWowColorsWithPos(text, cursorPosition)
  end

  -- get start position of current word
  local startPosition = cursorPosition
  while startPosition - 1 > 0 and text:sub(startPosition - 1, startPosition - 1):find("[%w%.%_]") do
    startPosition = startPosition - 1
  end

  -- get end position of current word
  local endPosition = startPosition
  while endPosition < #text and text:sub(endPosition + 1, endPosition + 1):find("[%w%.%_]") do
    endPosition = endPosition + 1
  end

  local nextChar = text:sub(cursorPosition, cursorPosition)
  if nextChar ~= "" and nextChar ~= " " and nextChar ~= "\n" then
    return "", nil, nil
  end

  local currentWord = text:sub(startPosition, endPosition)
  return currentWord, startPosition, endPosition
end

---@param editbox EditBox
---@param word string
function lib:SetWord(editbox, word)
  -- get cursor position
  local cursorPosition = editbox:GetCursorPosition()
  local text = editbox:APIDoc_originalGetText()
  if IndentationLib then
    text, cursorPosition = IndentationLib.stripWowColorsWithPos(text, cursorPosition)
  end

  -- get start position of current word
  local startPosition = cursorPosition
  while startPosition > 0 and text:sub(startPosition - 1, startPosition - 1):find("[%w%.%_]") do
    startPosition = startPosition - 1
  end

  -- get end position of current word
  local endPosition = startPosition
  while endPosition < #text and text:sub(endPosition + 1, endPosition + 1):find("[%w%.%_]") do
    endPosition = endPosition + 1
  end

  -- check if replacement word looks like a function and has args
  local funcName, argsString = word:match("([%w%.%_]+)%(([%w%.%_,\"%s]*)%)")
  local funcArgs = {}
  if funcName and argsString then
    for arg in argsString:gmatch("([%w%.%_\"]+),?") do
      table.insert(funcArgs, arg)
    end
  end

  -- check if current word has parentheses and args
  local oldFuncArgs = {}
  if funcName then
    local currentWordArgs = text:sub(endPosition + 1, #text):match("^%(([%w%.%_,\"%s]*)%)")
    if currentWordArgs then
      for arg in currentWordArgs:gmatch("([%w%.%_\"]+),?") do
        table.insert(oldFuncArgs, arg)
      end
      -- move endPosition
      endPosition = endPosition + #currentWordArgs + 2
    end
  end

  -- replace replacement word's args with args from current word
  if funcName then
    local concatArgs = {}
    for i = 1, math.max(#funcArgs, #oldFuncArgs) do
      concatArgs[i] = oldFuncArgs[i] or funcArgs[i]
    end
    word = funcName .. "(" .. table.concat(concatArgs, ", ") .. ")"
  end

  -- replace word
  text = text:sub(1, startPosition - 1) .. word .. text:sub(endPosition + 1, #text)
  editbox:APIDoc_originalSetText(text)
  -- SetText triggers the OnTextChanged handler without the "userInput" flag. We need that flag set to true, so run the handler again
  local script = editbox:GetScript("OnTextChanged")
  if script then
    script(editbox, true)
  end

  -- move cursor at end of word or start of parenthese
  local parenthesePosition = word:find("%(")
  editbox:SetCursorPosition(startPosition - 1 + (parenthesePosition or #word))
end

local function showTooltip(self)
  if self.apiInfo then
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 20, 20)
    GameTooltip:ClearLines()
    for _, line in ipairs(self.apiInfo:GetDetailedOutputLines()) do
      GameTooltip:AddLine(line)
    end
    GameTooltip:Show()
  end
end

local function hideTooltip(self)
  GameTooltip:Hide()
  GameTooltip:ClearLines()
end

APIAutoCompleteLineMixin = {}
function APIAutoCompleteLineMixin:Init(elementData)
  self.name = elementData.name
  self.apiInfo = elementData.apiInfo
  self:SetText(elementData.name)
  self:SetScript("OnClick", OnClickCallback)
  self:SetScript("OnEnter", showTooltip)
  self:SetScript("OnLeave", hideTooltip)
  local fontString = self:GetFontString()
  fontString:ClearAllPoints()
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium")
  fontString:SetFont(fontPath, 12, "")
  fontString:SetPoint("LEFT")
  fontString:SetTextColor(0.973, 0.902, 0.581)
  if not self:GetHighlightTexture() then
    local texture = self:CreateTexture()
    texture:SetColorTexture(0.4,0.4,0.4,0.5)
    texture:SetAllPoints()
    self:SetHighlightTexture(texture)
  end
  self:SetSelected(false)
end

function APIAutoCompleteLineMixin:SetSelected(selected)
  self:SetHighlightLocked(selected)
end

function APIAutoCompleteLineMixin:Insert()
  OnClickCallback(self)
end