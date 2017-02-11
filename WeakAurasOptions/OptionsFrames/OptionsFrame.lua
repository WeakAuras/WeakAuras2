-- Lua APIs
local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local fmt, tostring, string_char, strtrim, strsub = string.format, tostring, string.char, strtrim, strsub
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local coroutine, rad, sqrt, atan2, floor, cos, sin = coroutine, rad, sqrt, atan2, floor, cos, sin
local _G = _G

-- WoW APIs
local IsShiftKeyDown, GetSpellInfo, UnitName
    = IsShiftKeyDown, GetSpellInfo, UnitName
local GetScreenWidth, GetScreenHeight, GetTime, CreateFrame, GetAddOnInfo, PlaySound, IsAddOnLoaded, LoadAddOn
    = GetScreenWidth, GetScreenHeight, GetTime, CreateFrame, GetAddOnInfo, PlaySound, IsAddOnLoaded, LoadAddOn

-- GLOBALS: WeakAuras WeakAuras_DropDownMenu
-- GLOBALS: GameTooltip GameTooltip_Hide UIParent FONT_COLOR_CODE_CLOSE RED_FONT_COLOR_CODE GetAddOnEnableState

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local IndentationLib = IndentationLib

local WeakAuras = WeakAuras
local L = WeakAuras.L

local displayButtons = WeakAuras.displayButtons
local displayOptions = WeakAuras.displayOptions
local loaded = WeakAuras.loaded
local regionOptions = WeakAuras.regionOptions
local savedVars = WeakAuras.savedVars
local spellCache = WeakAuras.spellCache
local tempGroup = WeakAuras.tempGroup

function WeakAuras.CreateFrame()
  local WeakAuras_DropDownMenu = CreateFrame("frame", "WeakAuras_DropDownMenu", nil, "UIDropDownMenuTemplate");
  local frame;
  local db = savedVars.db;
  local odb = savedVars.odb;
  -------- Mostly Copied from AceGUIContainer-Frame--------
  frame = CreateFrame("FRAME", nil, UIParent);
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  });
  frame:SetBackdropColor(0, 0, 0, 1);
  frame:EnableMouse(true);
  frame:SetMovable(true);
  frame:SetResizable(true);
  frame:SetMinResize(610, 240);
  frame:SetFrameStrata("DIALOG");
  frame.window = "default";

  local xOffset, yOffset;
  if(db.frame) then
    xOffset, yOffset = db.frame.xOffset, db.frame.yOffset;
  end
  if not(xOffset and yOffset) then
    xOffset = (610 - GetScreenWidth()) / 2;
    yOffset = (492 - GetScreenHeight()) / 2;
  end
  frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset, yOffset);
  frame:Hide();

  local width, height;
  if(db.frame) then
    width, height = db.frame.width, db.frame.height;
  end
  if not(width and height) then
    width, height = 630, 492;
  end
  frame:SetWidth(width);
  frame:SetHeight(height);

  local close = CreateFrame("Frame", nil, frame);
  close:SetWidth(17)
  close:SetHeight(40)
  close:SetPoint("TOPRIGHT", -30, 12)

  local closebg = close:CreateTexture(nil, "BACKGROUND")
  closebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  closebg:SetTexCoord(0.31, 0.67, 0, 0.63)
  closebg:SetAllPoints(close);

  local closebutton = CreateFrame("BUTTON", nil, close)
  closebutton:SetWidth(30);
  closebutton:SetHeight(30);
  closebutton:SetPoint("CENTER", close, "CENTER", 1, -1);
  closebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Up.blp");
  closebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Down.blp");
  closebutton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  closebutton:SetScript("OnClick", WeakAuras.HideOptions);

  local closebg_l = close:CreateTexture(nil, "BACKGROUND")
  closebg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  closebg_l:SetTexCoord(0.235, 0.275, 0, 0.63)
  closebg_l:SetPoint("RIGHT", closebg, "LEFT")
  closebg_l:SetWidth(10)
  closebg_l:SetHeight(40)

  local closebg_r = close:CreateTexture(nil, "BACKGROUND")
  closebg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  closebg_r:SetTexCoord(0.72, 0.76, 0, 0.63)
  closebg_r:SetPoint("LEFT", closebg, "RIGHT")
  closebg_r:SetWidth(10)
  closebg_r:SetHeight(40)

  local import = CreateFrame("Frame", nil, frame);
  import:SetWidth(17)
  import:SetHeight(40)
  import:SetPoint("TOPRIGHT", -100, 12)
  --import:Hide()

  local importbg = import:CreateTexture(nil, "BACKGROUND")
  importbg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  importbg:SetTexCoord(0.31, 0.67, 0, 0.63)
  importbg:SetAllPoints(import);

  local importbutton = CreateFrame("CheckButton", nil, import, "OptionsCheckButtonTemplate")
  importbutton:SetWidth(30);
  importbutton:SetHeight(30);
  importbutton:SetPoint("CENTER", import, "CENTER", 1, -1);
  importbutton:SetHitRectInsets(0,0,0,0)
  importbutton:SetChecked(db.import_disabled)

  importbutton:SetScript("PostClick", function(self)
    if self:GetChecked() then
      PlaySound("igMainMenuOptionCheckBoxOn")
      db.import_disabled = true
    else
      PlaySound("igMainMenuOptionCheckBoxOff")
      db.import_disabled = nil
    end
  end)
  importbutton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      GameTooltip:SetText("Disable Import")
      GameTooltip:AddLine("If this option is enabled, you are no longer able to import auras.", 1, 1, 1)
      GameTooltip:Show()
  end)
  importbutton:SetScript("OnLeave", GameTooltip_Hide)

  local importbg_l = import:CreateTexture(nil, "BACKGROUND")
  importbg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  importbg_l:SetTexCoord(0.235, 0.275, 0, 0.63)
  importbg_l:SetPoint("RIGHT", importbg, "LEFT")
  importbg_l:SetWidth(10)
  importbg_l:SetHeight(40)

  local importbg_r = import:CreateTexture(nil, "BACKGROUND")
  importbg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  importbg_r:SetTexCoord(0.72, 0.76, 0, 0.63)
  importbg_r:SetPoint("LEFT", importbg, "RIGHT")
  importbg_r:SetWidth(10)
  importbg_r:SetHeight(40)

  local titlebg = frame:CreateTexture(nil, "OVERLAY")
  titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  titlebg:SetTexCoord(0.31, 0.67, 0, 0.63)
  titlebg:SetPoint("TOP", 0, 12)
  titlebg:SetWidth(120)
  titlebg:SetHeight(40)

  local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
  titlebg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
  titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
  titlebg_l:SetWidth(30)
  titlebg_l:SetHeight(40)

  local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
  titlebg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
  titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
  titlebg_r:SetWidth(30)
  titlebg_r:SetHeight(40)

  local title = CreateFrame("Frame", nil, frame)

  local function commitWindowChanges()
    local xOffset = frame:GetRight() - GetScreenWidth();
    local yOffset = frame:GetTop() - GetScreenHeight();
    if(title:GetRight() > GetScreenWidth()) then
      xOffset = xOffset + (GetScreenWidth() - title:GetRight());
    elseif(title:GetLeft() < 0) then
      xOffset = xOffset + (0 - title:GetLeft());
    end
    if(title:GetTop() > GetScreenHeight()) then
      yOffset = yOffset + (GetScreenHeight() - title:GetTop());
    elseif(title:GetBottom() < 0) then
      yOffset = yOffset + (0 - title:GetBottom());
    end
    db.frame = db.frame or {};
    db.frame.xOffset = xOffset;
    db.frame.yOffset = yOffset;
  if(not frame.minimized) then
    db.frame.width = frame:GetWidth();
    db.frame.height = frame:GetHeight();
  end
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset, yOffset);
  end

  title:EnableMouse(true)
  title:SetScript("OnMouseDown", function() frame:StartMoving() end)
  title:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing();
    commitWindowChanges();
  end);
  title:SetPoint("BOTTOMLEFT", titlebg, "BOTTOMLEFT", -25, 0);
  title:SetPoint("TOPRIGHT", titlebg, "TOPRIGHT", 25, 0);

  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)
  titletext:SetText(L["WeakAurasOptions"]);

  local sizer_sw = CreateFrame("button",nil,frame);
  sizer_sw:SetPoint("bottomleft",frame,"bottomleft",0,0);
  sizer_sw:SetWidth(25);
  sizer_sw:SetHeight(25);
  sizer_sw:EnableMouse();
  sizer_sw:SetScript("OnMouseDown", function() frame:StartSizing("bottomleft") end);
  sizer_sw:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing();
    commitWindowChanges();
  end);
  frame.sizer_sw = sizer_sw;

  local sizer_sw_texture = sizer_sw:CreateTexture(nil, "OVERLAY");
  sizer_sw_texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
  sizer_sw_texture:SetTexCoord(1, 0, 0, 1);
  sizer_sw_texture:SetPoint("bottomleft", sizer_sw, "bottomleft", 6, 6);
  sizer_sw_texture:SetPoint("topright", sizer_sw, "topright");
  sizer_sw:SetNormalTexture(sizer_sw_texture);

  local sizer_sw_texture_pushed = sizer_sw:CreateTexture(nil, "OVERLAY");
  sizer_sw_texture_pushed:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
  sizer_sw_texture_pushed:SetTexCoord(1, 0, 0, 1);
  sizer_sw_texture_pushed:SetPoint("bottomleft", sizer_sw, "bottomleft", 6, 6);
  sizer_sw_texture_pushed:SetPoint("topright", sizer_sw, "topright");
  sizer_sw:SetPushedTexture(sizer_sw_texture_pushed);

  local sizer_sw_texture_highlight = sizer_sw:CreateTexture(nil, "OVERLAY");
  sizer_sw_texture_highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
  sizer_sw_texture_highlight:SetTexCoord(1, 0, 0, 1);
  sizer_sw_texture_highlight:SetPoint("bottomleft", sizer_sw, "bottomleft", 6, 6);
  sizer_sw_texture_highlight:SetPoint("topright", sizer_sw, "topright");
  sizer_sw:SetHighlightTexture(sizer_sw_texture_highlight);

  -- local line1 = sizer_sw:CreateTexture(nil, "BACKGROUND")
  -- line1:SetWidth(14)
  -- line1:SetHeight(14)
  -- line1:SetPoint("bottomleft", 8, 8)
  -- line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
  -- local x = 0.1 * 14/17
  -- line1:SetTexCoord(0.05,0.5 - x, 0.5 + x,0.5, 0.05 - x,0.5, 0.05,0.5 + x)

  -- local line2 = sizer_sw:CreateTexture(nil, "BACKGROUND")
  -- line2:SetWidth(8)
  -- line2:SetHeight(8)
  -- line2:SetPoint("bottomleft", 8, 8)
  -- line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
  -- local x = 0.1 * 8/17
  -- line2:SetTexCoord(0.05,0.5 - x, 0.5 + x,0.5, 0.05 - x,0.5, 0.05,0.5 + x)
  --------------------------------------------------------


  local minimize = CreateFrame("Frame", nil, frame);
  minimize:SetWidth(17)
  minimize:SetHeight(40)
  minimize:SetPoint("TOPRIGHT", -65, 12)

  local minimizebg = minimize:CreateTexture(nil, "BACKGROUND")
  minimizebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  minimizebg:SetTexCoord(0.31, 0.67, 0, 0.63)
  minimizebg:SetAllPoints(minimize);

  local minimizebutton = CreateFrame("BUTTON", nil, minimize)
  minimizebutton:SetWidth(30);
  minimizebutton:SetHeight(30);
  minimizebutton:SetPoint("CENTER", minimize, "CENTER", 1, -1);
  minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp");
  minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp");
  minimizebutton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  minimizebutton:SetScript("OnClick", function()
    if(frame.minimized) then
      frame.minimized = nil;
      if db.frame then
        if db.frame.height < 240 then
          db.frame.height = 500
        end
      end
      frame:SetHeight(db.frame and db.frame.height or 500);
      if(frame.window == "default") then
        frame.buttonsContainer.frame:Show();
        frame.container.frame:Show();
      elseif(frame.window == "texture") then
        frame.texturePick.frame:Show();
      elseif(frame.window == "icon") then
        frame.iconPick.frame:Show();
      elseif(frame.window == "model") then
        frame.modelPick.frame:Show();
      elseif(frame.window == "importexport") then
        frame.importexport.frame:Show();
      elseif(frame.window == "texteditor") then
        frame.texteditor.frame:Show();
      elseif(frame.window == "codereview") then
        frame.codereview.frame:Show();
      elseif(frame.window == "newview") then
        frame.newView.frame:Show();
      end
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp");
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp");
    else
      frame.minimized = true;
      frame:SetHeight(40);
      frame.buttonsContainer.frame:Hide();
      frame.texturePick.frame:Hide();
      frame.iconPick.frame:Hide();
      frame.modelPick.frame:Hide();
      frame.importexport.frame:Hide();
      frame.texteditor.frame:Hide();
      frame.codereview.frame:Hide();
      if (frame.newView) then
        frame.newView.frame:Hide();
      end
      frame.container.frame:Hide();
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Up.blp");
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Down.blp");
    end
  end);

  local minimizebg_l = minimize:CreateTexture(nil, "BACKGROUND")
  minimizebg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  minimizebg_l:SetTexCoord(0.235, 0.275, 0, 0.63)
  minimizebg_l:SetPoint("RIGHT", minimizebg, "LEFT")
  minimizebg_l:SetWidth(10)
  minimizebg_l:SetHeight(40)

  local minimizebg_r = minimize:CreateTexture(nil, "BACKGROUND")
  minimizebg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  minimizebg_r:SetTexCoord(0.72, 0.76, 0, 0.63)
  minimizebg_r:SetPoint("LEFT", minimizebg, "RIGHT")
  minimizebg_r:SetWidth(10)
  minimizebg_r:SetHeight(40)

  local _, _, _, enabled, loadable = GetAddOnInfo("WeakAurasTutorials");
  if(enabled and loadable) then
    local tutorial = CreateFrame("Frame", nil, frame);
    tutorial:SetWidth(17)
    tutorial:SetHeight(40)
    tutorial:SetPoint("TOPRIGHT", -140, 12)

    local tutorialbg = tutorial:CreateTexture(nil, "BACKGROUND")
    tutorialbg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    tutorialbg:SetTexCoord(0.31, 0.67, 0, 0.63)
    tutorialbg:SetAllPoints(tutorial);

    local tutorialbutton = CreateFrame("BUTTON", nil, tutorial)
    tutorialbutton:SetWidth(30);
    tutorialbutton:SetHeight(30);
    tutorialbutton:SetPoint("CENTER", tutorial, "CENTER", 1, -1);
    tutorialbutton:SetNormalTexture("Interface\\GossipFrame\\DailyActiveQuestIcon");
    tutorialbutton:GetNormalTexture():ClearAllPoints();
    tutorialbutton:GetNormalTexture():SetSize(16, 16);
    tutorialbutton:GetNormalTexture():SetPoint("center", -2, 0);
    tutorialbutton:SetPushedTexture("Interface\\GossipFrame\\DailyActiveQuestIcon");
    tutorialbutton:GetPushedTexture():ClearAllPoints();
    tutorialbutton:GetPushedTexture():SetSize(16, 16);
    tutorialbutton:GetPushedTexture():SetPoint("center", -2, -2);
    tutorialbutton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
    tutorialbutton:SetScript("OnClick", function()
      if not(IsAddOnLoaded("WeakAurasTutorials")) then
        local loaded, reason = LoadAddOn("WeakAurasTutorials");
        if not(loaded) then
          print("|cff9900FF".."WeakAurasTutorials"..FONT_COLOR_CODE_CLOSE.." could not be loaded: "..RED_FONT_COLOR_CODE.._G["ADDON_"..reason]);
          return;
        end
      end
      WeakAuras.ToggleTutorials();
    end);

    local tutorialbg_l = tutorial:CreateTexture(nil, "BACKGROUND")
    tutorialbg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    tutorialbg_l:SetTexCoord(0.235, 0.275, 0, 0.63)
    tutorialbg_l:SetPoint("RIGHT", tutorialbg, "LEFT")
    tutorialbg_l:SetWidth(10)
    tutorialbg_l:SetHeight(40)

    local tutorialbg_r = tutorial:CreateTexture(nil, "BACKGROUND")
    tutorialbg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    tutorialbg_r:SetTexCoord(0.72, 0.76, 0, 0.63)
    tutorialbg_r:SetPoint("LEFT", tutorialbg, "RIGHT")
    tutorialbg_r:SetWidth(10)
    tutorialbg_r:SetHeight(40)
  end

  local container = AceGUI:Create("InlineGroup");
  container.frame:SetParent(frame);
  container.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12);
  container.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -423, -10);
  container.frame:Show();
  container.frame:SetClipsChildren(true);
  container.titletext:Hide();
  frame.container = container;

  local texturePick = AceGUI:Create("InlineGroup");
  texturePick.frame:SetParent(frame);
  texturePick.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 42);
  texturePick.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  texturePick.frame:Hide();
  texturePick:SetLayout("flow");
  frame.texturePick = texturePick;
  texturePick.children = {};
  texturePick.categories = {};

  local texturePickDropdown = AceGUI:Create("DropdownGroup");
  texturePickDropdown:SetLayout("fill");
  texturePickDropdown.width = "fill";
  texturePickDropdown:SetHeight(390);
  texturePick:SetLayout("fill");
  texturePick:AddChild(texturePickDropdown);
  texturePickDropdown.list = {};
  texturePickDropdown:SetGroupList(texturePickDropdown.list);

  local texturePickScroll = AceGUI:Create("ScrollFrame");
  texturePickScroll:SetWidth(540);
  texturePickScroll:SetLayout("flow");
  texturePickScroll.frame:SetClipsChildren(true);
  texturePickDropdown:AddChild(texturePickScroll);

  local function texturePickGroupSelected(widget, event, uniquevalue)
    texturePickScroll:ReleaseChildren();
    for texturePath, textureName in pairs(texturePick.textures[uniquevalue]) do
      local textureWidget = AceGUI:Create("WeakAurasTextureButton");
      if (texturePick.SetTextureFunc) then
        texturePick.SetTextureFunc(textureWidget, texturePath, textureName);
      else
        textureWidget:SetTexture(texturePath, textureName);
        local d = texturePick.textureData;
        textureWidget:ChangeTexture(d.r, d.g, d.b, d.a, d.rotate, d.discrete_rotation, d.rotation, d.mirror, d.blendMode);
      end

      textureWidget:SetClick(function()
        texturePick:Pick(texturePath);
      end);
      texturePickScroll:AddChild(textureWidget);
      table.sort(texturePickScroll.children, function(a, b)
        local aPath, bPath = a:GetTexturePath(), b:GetTexturePath();
        local aNum, bNum = tonumber(aPath:match("%d+")), tonumber(bPath:match("%d+"));
        local aNonNumber, bNonNumber = aPath:match("[^%d]+"), bPath:match("[^%d]+")
        if(aNum and bNum and aNonNumber == bNonNumber) then
          return aNum < bNum;
        else
          return aPath < bPath;
        end
      end);
    end
    texturePick:Pick(texturePick.data[texturePick.field]);
  end

  texturePickDropdown:SetCallback("OnGroupSelected", texturePickGroupSelected)

  function texturePick.UpdateList(self)
    wipe(texturePickDropdown.list);
    for categoryName, category in pairs(self.textures) do
      local match = false;
      for texturePath, textureName in pairs(category) do
        if(texturePath == self.data[self.field]) then
          match = true;
          break;
        end
      end
      texturePickDropdown.list[categoryName] = (match and "|cFF80A0FF" or "")..categoryName;
    end
    texturePickDropdown:SetGroupList(texturePickDropdown.list);
  end

  function texturePick.Pick(self, texturePath)
    local pickedwidget;
    for index, widget in ipairs(texturePickScroll.children) do
      widget:ClearPick();
      if(widget:GetTexturePath() == texturePath) then
        pickedwidget = widget;
      end
    end
    if(pickedwidget) then
      pickedwidget:Pick();
    end

    if(self.data.controlledChildren) then
      setAll(self.data, {"region", self.field}, texturePath);
    else
      self.data[self.field] = texturePath;
    end
    if(type(self.data.id) == "string") then
      WeakAuras.Add(self.data);
      WeakAuras.SetIconNames(self.data);
      WeakAuras.SetThumbnail(self.data);
    end
    texturePick:UpdateList();
    local status = texturePickDropdown.status or texturePickDropdown.localstatus
    texturePickDropdown.dropdown:SetText(texturePickDropdown.list[status.selected]);
  end

  function texturePick.Open(self, data, field, textures, SetTextureFunc)
    self.data = data;
    self.field = field;
    self.textures = textures;
    self.SetTextureFunc = SetTextureFunc
    if(data.controlledChildren) then
      self.givenPath = {};
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenPath[childId] = childData[field];
        end
      end
      local colorAll = getAll(data, {"region", "color"}) or {1, 1, 1, 1};
      self.textureData = {
        r = colorAll[1] or 1,
        g = colorAll[2] or 1,
        b = colorAll[3] or 1,
        a = colorAll[4] or 1,
        rotate = getAll(data, {"region", "rotate"}),
        discrete_rotation = getAll(data, {"region", "discrete_rotation"}) or 0,
        rotation = getAll(data, {"region", "rotation"}) or 0,
        mirror = getAll(data, {"region", "mirror"}),
        blendMode = getAll(data, {"region", "blendMode"}) or "ADD"
      };
    else
      self.givenPath = data[field];
      data.color = data.color or {};
      self.textureData = {
        r = data.color[1] or 1,
        g = data.color[2] or 1,
        b = data.color[3] or 1,
        a = data.color[4] or 1,
        rotate = data.rotate,
        discrete_rotation = data.discrete_rotation or 0,
        rotation = data.rotation or 0,
        mirror = data.mirror,
        blendMode = data.blendMode or "ADD"
      };
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "texture";
    local picked = false;
    local _, givenPath
    if(type(self.givenPath) == "string") then
      givenPath = self.givenPath;
    else
      _, givenPath = next(self.givenPath);
    end
    WeakAuras.debug(givenPath, 3);
    for categoryName, category in pairs(self.textures) do
      if not(picked) then
        for texturePath, textureName in pairs(category) do
          if(texturePath == givenPath) then
            texturePickDropdown:SetGroup(categoryName);
            self:Pick(givenPath);
            picked = true;
            break;
          end
        end
      end
    end
    if not(picked) then
      for categoryName, category in pairs(self.textures) do
        texturePickDropdown:SetGroup(categoryName);
        break;
      end
    end
  end

  function texturePick.Close()
    texturePick.frame:Hide();
    frame.buttonsContainer.frame:Show();
    frame.container.frame:Show();
    frame.window = "default";
    AceConfigDialog:Open("WeakAuras", container);
  end

  function texturePick.CancelClose()
    if(texturePick.data.controlledChildren) then
      for index, childId in pairs(texturePick.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[texturePick.field] = texturePick.givenPath[childId];
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      texturePick:Pick(texturePick.givenPath);
    end
    texturePick.Close();
  end

  local texturePickCancel = CreateFrame("Button", nil, texturePick.frame, "UIPanelButtonTemplate")
  texturePickCancel:SetScript("OnClick", texturePick.CancelClose)
  texturePickCancel:SetPoint("BOTTOMRIGHT", -27, -23)
  texturePickCancel:SetHeight(20)
  texturePickCancel:SetWidth(100)
  texturePickCancel:SetText(L["Cancel"])

  local texturePickClose = CreateFrame("Button", nil, texturePick.frame, "UIPanelButtonTemplate")
  texturePickClose:SetScript("OnClick", texturePick.Close)
  texturePickClose:SetPoint("RIGHT", texturePickCancel, "LEFT", -10, 0)
  texturePickClose:SetHeight(20)
  texturePickClose:SetWidth(100)
  texturePickClose:SetText(L["Okay"])

  local iconPick = AceGUI:Create("InlineGroup");
  iconPick.frame:SetParent(frame);
  iconPick.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 30); -- 12
  iconPick.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -50);
  iconPick.frame:Hide();
  iconPick:SetLayout("flow");
  frame.iconPick = iconPick;

  local iconPickScroll = AceGUI:Create("ScrollFrame");
  iconPickScroll:SetLayout("flow");
  iconPickScroll.frame:SetClipsChildren(true);
  iconPick:AddChild(iconPickScroll);

  local function iconPickFill(subname, doSort)
    iconPickScroll:ReleaseChildren();

    local distances = {};
    local names = {};

    subname = tonumber(subname) and GetSpellInfo(tonumber(subname)) or subname;
    subname = subname:lower();

    local usedIcons = {};
    local num = 0;
    if(subname ~= "") then
      for name, icons in pairs(spellCache) do
        local bestDistance = math.huge;
        local bestName;
        if(name:lower():find(subname, 1, true)) then

          for spellId, icon in pairs(icons) do
            if (not usedIcons[icon]) then
              local button = AceGUI:Create("WeakAurasIconButton");
              button:SetName(name);
              button:SetTexture(icon);
              button:SetClick(function()
                iconPick:Pick(icon);
              end);
              iconPickScroll:AddChild(button);

              usedIcons[icon] = true;
              num = num + 1;
              if(num >= 500) then
                break;
              end
            end
          end
        end

        if(num >= 500) then
          break;
        end
      end
    end
  end

  local iconPickInput = CreateFrame("EDITBOX", nil, iconPick.frame, "InputBoxTemplate");
  iconPickInput:SetScript("OnTextChanged", function(...) iconPickFill(iconPickInput:GetText(), false); end);
  iconPickInput:SetScript("OnEnterPressed", function(...) iconPickFill(iconPickInput:GetText(), true); end);
  iconPickInput:SetScript("OnEscapePressed", function(...) iconPickInput:SetText(""); iconPickFill(iconPickInput:GetText(), true); end);
  iconPickInput:SetWidth(170);
  iconPickInput:SetHeight(15);
  iconPickInput:SetPoint("BOTTOMRIGHT", iconPick.frame, "TOPRIGHT", -12, -5);
  WeakAuras.iconPickInput = iconPickInput;

  local iconPickInputLabel = iconPickInput:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  iconPickInputLabel:SetText(L["Search"]);
  iconPickInputLabel:SetJustifyH("RIGHT");
  iconPickInputLabel:SetPoint("BOTTOMLEFT", iconPickInput, "TOPLEFT", 0, 5);

  local iconPickIcon = AceGUI:Create("WeakAurasIconButton");
  iconPickIcon.frame:Disable();
  iconPickIcon.frame:SetParent(iconPick.frame);
  iconPickIcon.frame:SetPoint("BOTTOMLEFT", iconPick.frame, "TOPLEFT", 15, -15);

  local iconPickIconLabel = iconPickInput:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
  iconPickIconLabel:SetNonSpaceWrap("true");
  iconPickIconLabel:SetJustifyH("LEFT");
  iconPickIconLabel:SetPoint("LEFT", iconPickIcon.frame, "RIGHT", 5, 0);
  iconPickIconLabel:SetPoint("RIGHT", iconPickInput, "LEFT", -50, 0);

  function iconPick.Pick(self, texturePath)
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[self.field] = texturePath;
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data[self.field] = texturePath;
      WeakAuras.Add(self.data);
      WeakAuras.SetThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
    local success = iconPickIcon:SetTexture(texturePath) and texturePath;
    if(success) then
      iconPickIconLabel:SetText(texturePath);
    else
      iconPickIconLabel:SetText();
    end
  end

  function iconPick.Open(self, data, field)
    self.data = data;
    self.field = field;
    if(data.controlledChildren) then
      self.givenPath = {};
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenPath[childId] = childData[field];
        end
      end
    else
      self.givenPath = self.data[self.field];
    end
    -- iconPick:Pick(self.givenPath);
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "icon";
    iconPickInput:SetText("");
  end

  function iconPick.Close()
    iconPick.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
    AceConfigDialog:Open("WeakAuras", container);
  end

  function iconPick.CancelClose()
    if(iconPick.data.controlledChildren) then
      for index, childId in pairs(iconPick.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData[iconPick.field] = iconPick.givenPath[childId] or childData[iconPick.field];
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      iconPick:Pick(iconPick.givenPath);
    end
    iconPick.Close();
  end

  local iconPickCancel = CreateFrame("Button", nil, iconPick.frame, "UIPanelButtonTemplate");
  iconPickCancel:SetScript("OnClick", iconPick.CancelClose);
  iconPickCancel:SetPoint("bottomright", frame, "bottomright", -27, 11);
  iconPickCancel:SetHeight(20);
  iconPickCancel:SetWidth(100);
  iconPickCancel:SetText(L["Cancel"]);

  local iconPickClose = CreateFrame("Button", nil, iconPick.frame, "UIPanelButtonTemplate");
  iconPickClose:SetScript("OnClick", iconPick.Close);
  iconPickClose:SetPoint("RIGHT", iconPickCancel, "LEFT", -10, 0);
  iconPickClose:SetHeight(20);
  iconPickClose:SetWidth(100);
  iconPickClose:SetText(L["Okay"]);

  iconPickScroll.frame:SetPoint("BOTTOM", iconPickClose, "TOP", 0, 10);

  local modelPick = AceGUI:Create("InlineGroup");
  modelPick.frame:SetParent(frame);
  modelPick.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 87);
  modelPick.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  modelPick.frame:Hide();
  modelPick:SetLayout("flow");
  frame.modelPick = modelPick;

  -- Old X Y Z controls
  local modelPickZ = AceGUI:Create("Slider");
  modelPickZ:SetSliderValues(-20, 20, 0.05);
  modelPickZ:SetLabel(L["Z Offset"]);
  modelPickZ.frame:SetParent(modelPick.frame);
  modelPickZ:SetCallback("OnValueChanged", function()
    modelPick:Pick(nil, modelPickZ:GetValue());
  end);

  local modelPickX = AceGUI:Create("Slider");
  modelPickX:SetSliderValues(-20, 20, 0.05);
  modelPickX:SetLabel(L["X Offset"]);
  modelPickX.frame:SetParent(modelPick.frame);
  modelPickX:SetCallback("OnValueChanged", function()
    modelPick:Pick(nil, nil, modelPickX:GetValue());
  end);

  local modelPickY = AceGUI:Create("Slider");
  modelPickY:SetSliderValues(-20, 20, 0.05);
  modelPickY:SetLabel(L["Y Offset"]);
  modelPickY.frame:SetParent(modelPick.frame);
  modelPickY:SetCallback("OnValueChanged", function()
    modelPick:Pick(nil, nil, nil, modelPickY:GetValue());
  end);

  -- New TX TY TZ, RX, RY, RZ, US controls
  local modelPickTX = AceGUI:Create("Slider");
  modelPickTX:SetSliderValues(-1000, 1000, 1);
  modelPickTX:SetLabel(L["X Offset"]);
  modelPickTX.frame:SetParent(modelPick.frame);
  modelPickTX:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, modelPickTX:GetValue());
  end);

  local modelPickTY = AceGUI:Create("Slider");
  modelPickTY:SetSliderValues(-1000, 1000, 1);
  modelPickTY:SetLabel(L["Y Offset"]);
  modelPickTY.frame:SetParent(modelPick.frame);
  modelPickTY:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, modelPickTY:GetValue());
  end);

  local modelPickTZ = AceGUI:Create("Slider");
  modelPickTZ:SetSliderValues(-1000, 1000, 1);
  modelPickTZ:SetLabel(L["Z Offset"]);
  modelPickTZ.frame:SetParent(modelPick.frame);
  modelPickTZ:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, nil, modelPickTZ:GetValue());
  end);

  local modelPickRX = AceGUI:Create("Slider");
  modelPickRX:SetSliderValues(0, 360, 1);
  modelPickRX:SetLabel(L["X Rotation"]);
  modelPickRX.frame:SetParent(modelPick.frame);
  modelPickRX:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, nil, nil, modelPickRX:GetValue());
  end);

  local modelPickRY = AceGUI:Create("Slider");
  modelPickRY:SetSliderValues(0, 360, 1);
  modelPickRY:SetLabel(L["Y Rotation"]);
  modelPickRY.frame:SetParent(modelPick.frame);
  modelPickRY:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, nil, nil, nil, modelPickRY:GetValue());
  end);

  local modelPickRZ = AceGUI:Create("Slider");
  modelPickRZ:SetSliderValues(0, 360, 1);
  modelPickRZ:SetLabel(L["Z Rotation"]);
  modelPickRZ.frame:SetParent(modelPick.frame);
  modelPickRZ:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, nil, nil, nil, nil, modelPickRZ:GetValue());
  end);

  local modelPickUS = AceGUI:Create("Slider");
  modelPickUS:SetSliderValues(5, 1000, 1);
  modelPickUS:SetLabel(L["Scale"]);
  modelPickUS.frame:SetParent(modelPick.frame);
  modelPickUS:SetCallback("OnValueChanged", function()
    modelPick:PickSt(nil, nil, nil, nil, nil, nil, nil, modelPickUS:GetValue());
  end);

  local modelTree = AceGUI:Create("TreeGroup");
  modelPick.modelTree = modelTree;
  modelPick.frame:SetScript("OnUpdate", function()
    local frameWidth = frame:GetWidth();
    local sliderWidth = (frameWidth - 50) / 3;
    local narrowSliderWidth = (frameWidth - 50) / 7;

    modelTree:SetTreeWidth(frameWidth - 370);

    modelPickZ.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickZ.frame:SetPoint("bottomright", frame, "bottomleft", 15 + sliderWidth, 43);

    modelPickX.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + sliderWidth, 43);
    modelPickX.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (2 * sliderWidth), 43);

    modelPickY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (2 * sliderWidth), 43);
    modelPickY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (3 * sliderWidth), 43);

    -- New controls
    modelPickTX.frame:SetPoint("bottomleft", frame, "bottomleft", 15, 43);
    modelPickTX.frame:SetPoint("bottomright", frame, "bottomleft", 15 + narrowSliderWidth, 43);

    modelPickTY.frame:SetPoint("bottomleft", frame, "bottomleft", 20 + narrowSliderWidth, 43);
    modelPickTY.frame:SetPoint("bottomright", frame, "bottomleft", 20 + (2 * narrowSliderWidth), 43);

    modelPickTZ.frame:SetPoint("bottomleft", frame, "bottomleft", 25 + (2 * narrowSliderWidth), 43);
    modelPickTZ.frame:SetPoint("bottomright", frame, "bottomleft", 25 + (3 * narrowSliderWidth), 43);

    modelPickRX.frame:SetPoint("bottomleft", frame, "bottomleft", 30 + (3 * narrowSliderWidth), 43);
    modelPickRX.frame:SetPoint("bottomright", frame, "bottomleft", 30 + (4 * narrowSliderWidth), 43);

    modelPickRY.frame:SetPoint("bottomleft", frame, "bottomleft", 35 + (4 * narrowSliderWidth), 43);
    modelPickRY.frame:SetPoint("bottomright", frame, "bottomleft", 35 + (5 * narrowSliderWidth), 43);

    modelPickRZ.frame:SetPoint("bottomleft", frame, "bottomleft", 40 + (5 * narrowSliderWidth), 43);
    modelPickRZ.frame:SetPoint("bottomright", frame, "bottomleft", 40 + (6 * narrowSliderWidth), 43);

    modelPickUS.frame:SetPoint("bottomleft", frame, "bottomleft", 45 + (6 * narrowSliderWidth), 43);
    modelPickUS.frame:SetPoint("bottomright", frame, "bottomleft", 45 + (7 * narrowSliderWidth), 43);

  end);
  modelPick:SetLayout("fill");
  modelTree:SetTree(WeakAuras.ModelPaths);
  modelTree:SetCallback("OnGroupSelected", function(self, event, value)
    local path = string.gsub(value, "\001", "/");
    if(string.lower(string.sub(path, -3, -1)) == ".m2") then
      local model_path = path;
      if (modelPick.givenApi) then
        modelPick:PickSt(model_path);
      else
        modelPick:Pick(model_path);
      end
    end
  end);
  modelPick:AddChild(modelTree);

  local model = CreateFrame("PlayerModel", nil, modelPick.content);
  model:SetAllPoints(modelTree.content);
  model:SetFrameStrata("FULLSCREEN");
  modelPick.model = model;

  function modelPick.PickSt(self, model_path, model_tx, model_ty, model_tz, model_rx, model_ry, model_rz, model_us)
    model_path = model_path or self.data.model_path;
    model_tx = model_tx or self.data.model_st_tx;
    model_ty = model_ty or self.data.model_st_ty;
    model_tz = model_tz or self.data.model_st_tz;

    model_rx = model_rx or self.data.model_st_rx;
    model_ry = model_ry or self.data.model_st_ry;
    model_rz = model_rz or self.data.model_st_rz;

    model_us = model_us or self.data.model_st_us;

    if tonumber(model_path) then
      self.model:SetDisplayInfo(tonumber(model_path))
    else
      self.model:SetModel(model_path);
    end
    self.model:SetTransform(model_tx / 1000, model_ty / 1000, model_tz / 1000,
                            rad(model_rx), rad(model_ry), rad(model_rz),
                            model_us / 1000);
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
          childData.model_st_tx = model_tx;
          childData.model_st_ty = model_ty;
          childData.model_st_tz = model_tz;
          childData.model_st_rx = model_rx;
          childData.model_st_ry = model_ry;
          childData.model_st_rz = model_rz;
          childData.model_st_us = model_us;
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data.model_path = model_path;
      self.data.model_st_tx = model_tx;
      self.data.model_st_ty = model_ty;
      self.data.model_st_tz = model_tz;
      self.data.model_st_rx = model_rx;
      self.data.model_st_ry = model_ry;
      self.data.model_st_rz = model_rz;
      self.data.model_st_us = model_us;
      WeakAuras.Add(self.data);
      WeakAuras.SetThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
  end

  function modelPick.Pick(self, model_path, model_z, model_x, model_y)
    model_path = model_path or self.data.model_path;
    model_z = model_z or self.data.model_z;
    model_x = model_x or self.data.model_x;
    model_y = model_y or self.data.model_y;

    if tonumber(model_path) then
      self.model:SetDisplayInfo(tonumber(model_path))
    else
      self.model:SetModel(model_path);
    end
    self.model:ClearTransform();
    self.model:SetPosition(model_z, model_x, model_y);
    self.model:SetFacing(rad(self.data.rotation));
    if(self.data.controlledChildren) then
      for index, childId in pairs(self.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = model_path;
          childData.model_z = model_z;
          childData.model_x = model_x;
          childData.model_y = model_y;
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      self.data.model_path = model_path;
      self.data.model_z = model_z;
      self.data.model_x = model_x;
      self.data.model_y = model_y;
      WeakAuras.Add(self.data);
      WeakAuras.SetThumbnail(self.data);
      WeakAuras.SetIconNames(self.data);
    end
  end

  function modelPick.Open(self, data)
    self.data = data;
    if tonumber(data.model_path) then
      model:SetDisplayInfo(tonumber(data.model_path))
    else
      model:SetModel(data.model_path);
    end
    if (data.api) then
      self.model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
                              rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
                              data.model_st_us / 1000);

      modelPickTX:SetValue(data.model_st_tx);
      modelPickTX.editbox:SetText(("%.2f"):format(data.model_st_tx));
      modelPickTY:SetValue(data.model_st_ty);
      modelPickTY.editbox:SetText(("%.2f"):format(data.model_st_ty));
      modelPickTZ:SetValue(data.model_st_tz);
      modelPickTZ.editbox:SetText(("%.2f"):format(data.model_st_tz));

      modelPickRX:SetValue(data.model_st_rx);
      modelPickRX.editbox:SetText(("%.2f"):format(data.model_st_rx));
      modelPickRY:SetValue(data.model_st_ry);
      modelPickRY.editbox:SetText(("%.2f"):format(data.model_st_ry));
      modelPickRZ:SetValue(data.model_st_rz);
      modelPickRZ.editbox:SetText(("%.2f"):format(data.model_st_rz));

      modelPickUS:SetValue(data.model_st_us);
      modelPickUS.editbox:SetText(("%.2f"):format(data.model_st_us));

      modelPickZ.frame:Hide();
      modelPickY.frame:Hide();
      modelPickX.frame:Hide();

      modelPickTX.frame:Show();
      modelPickTY.frame:Show();
      modelPickTZ.frame:Show();
      modelPickRX.frame:Show();
      modelPickRY.frame:Show();
      modelPickRZ.frame:Show();
      modelPickUS.frame:Show();

    else
      self.model:ClearTransform();
      self.model:SetPosition(data.model_z, data.model_x, data.model_y);
      self.model:SetFacing(rad(data.rotation));
      modelPickZ:SetValue(data.model_z);
      modelPickZ.editbox:SetText(("%.2f"):format(data.model_z));
      modelPickX:SetValue(data.model_x);
      modelPickX.editbox:SetText(("%.2f"):format(data.model_x));
      modelPickY:SetValue(data.model_y);
      modelPickY.editbox:SetText(("%.2f"):format(data.model_y));

      modelPickZ.frame:Show();
      modelPickY.frame:Show();
      modelPickX.frame:Show();

      modelPickTX.frame:Hide();
      modelPickTY.frame:Hide();
      modelPickTZ.frame:Hide();
      modelPickRX.frame:Hide();
      modelPickRY.frame:Hide();
      modelPickRZ.frame:Hide();
      modelPickUS.frame:Hide();
    end

    if(data.controlledChildren) then
      self.givenModel = {};
      self.givenApi = {};
      self.givenZ = {};
      self.givenX = {};
      self.givenY = {};
      self.givenTX = {};
      self.givenTY = {};
      self.givenTZ = {};
      self.givenRX = {};
      self.givenRY = {};
      self.givenRZ = {};
      self.givenUS = {};
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          self.givenModel[childId] = childData.model_path;
          self.givenApi[childId] = childData.api;
          if (childData.api) then
            self.givenTX[childId] = childData.model_st_tx;
            self.givenTY[childId] = childData.model_st_ty;
            self.givenTZ[childId] = childData.model_st_tz;
            self.givenRX[childId] = childData.model_st_rx;
            self.givenRY[childId] = childData.model_st_ry;
            self.givenRZ[childId] = childData.model_st_rz;
            self.givenUS[childId] = childData.model_st_us;
          else
            self.givenZ[childId] = childData.model_z;
            self.givenX[childId] = childData.model_x;
            self.givenY[childId] = childData.model_y;
          end
        end
      end
    else
      self.givenModel = data.model_path;
      self.givenApi = data.api;

      if (data.api) then
        self.givenTX = data.model_st_tx;
        self.givenTY = data.model_st_ty;
        self.givenTZ = data.model_st_tz;
        self.givenRX = data.model_st_rx;
        self.givenRY = data.model_st_ry;
        self.givenRZ = data.model_st_rz;
        self.givenUS = data.model_st_us;
      else
        self.givenZ = data.model_z;
        self.givenX = data.model_x;
        self.givenY = data.model_y;
      end
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "model";
  end

  function modelPick.Close()
    modelPick.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
    AceConfigDialog:Open("WeakAuras", container);
  end

  function modelPick.CancelClose(self)
    if(modelPick.data.controlledChildren) then
      for index, childId in pairs(modelPick.data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          childData.model_path = modelPick.givenModel[childId];
          childData.api = modelPick.givenApi[childId];
          if (childData.api) then
            childData.model_st_tx = modelPick.givenTX[childId];
            childData.model_st_ty = modelPick.givenTY[childId];
            childData.model_st_tz = modelPick.givenTZ[childId];
            childData.model_st_rx = modelPick.givenRX[childId];
            childData.model_st_ry = modelPick.givenRY[childId];
            childData.model_st_rz = modelPick.givenRZ[childId];
            childData.model_st_us = modelPick.givenUS[childId];
          else
            childData.model_z = modelPick.givenZ[childId];
            childData.model_x = modelPick.givenX[childId];
            childData.model_y = modelPick.givenY[childId];
          end
          WeakAuras.Add(childData);
          WeakAuras.SetThumbnail(childData);
          WeakAuras.SetIconNames(childData);
        end
      end
    else
      if (modelPick.givenApi) then
        modelPick:PickSt(modelPick.givenPath, modelPick.givenTX, modelPick.givenTY, modelPick.givenTZ,
                         modelPick.givenRX, modelPick.givenRY, modelPick.givenRZ, modelPick.givenUS );
      else
        modelPick:Pick(modelPick.givenPath, modelPick.givenZ, modelPick.givenX, modelPick.givenY);
      end
    end
    modelPick.Close();
  end

  local modelPickCancel = CreateFrame("Button", nil, modelPick.frame, "UIPanelButtonTemplate");
  modelPickCancel:SetScript("OnClick", modelPick.CancelClose);
  modelPickCancel:SetPoint("bottomright", frame, "bottomright", -27, 16);
  modelPickCancel:SetHeight(20);
  modelPickCancel:SetWidth(100);
  modelPickCancel:SetText(L["Cancel"]);

  local modelPickClose = CreateFrame("Button", nil, modelPick.frame, "UIPanelButtonTemplate");
  modelPickClose:SetScript("OnClick", modelPick.Close);
  modelPickClose:SetPoint("RIGHT", modelPickCancel, "LEFT", -10, 0);
  modelPickClose:SetHeight(20);
  modelPickClose:SetWidth(100);
  modelPickClose:SetText(L["Okay"]);

  local importexport = AceGUI:Create("InlineGroup");
  importexport.frame:SetParent(frame);
  importexport.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12);
  importexport.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  importexport.frame:Hide();
  importexport:SetLayout("fill");
  frame.importexport = importexport;

  local importexportbox = AceGUI:Create("MultiLineEditBox");
  importexportbox:SetWidth(400);
  importexportbox.button:Hide();
  importexportbox.frame:SetClipsChildren(true);
  importexport:AddChild(importexportbox);

  local importexportClose = CreateFrame("Button", nil, importexport.frame, "UIPanelButtonTemplate");
  importexportClose:SetScript("OnClick", function() importexport:Close() end);
  importexportClose:SetPoint("BOTTOMRIGHT", -27, 13);
  importexportClose:SetHeight(20);
  importexportClose:SetWidth(100);
  importexportClose:SetText(L["Done"])

  function importexport.Open(self, mode, id)
    if(frame.window == "texture") then
      frame.texturePick:CancelClose();
    elseif(frame.window == "icon") then
      frame.iconPick:CancelClose();
    elseif(frame.window == "model") then
      frame.modelPick:CancelClose();
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "importexport";
    if(mode == "export" or mode == "table") then
      if(id) then
        local displayStr;
        if(mode == "export") then
          displayStr = WeakAuras.DisplayToString(id, true);
        elseif(mode == "table") then
          displayStr = WeakAuras.DisplayToTableString(id);
        end
        importexportbox.editBox:SetMaxBytes(nil);
        importexportbox.editBox:SetScript("OnEscapePressed", function() importexport:Close(); end);
        importexportbox.editBox:SetScript("OnChar", function() importexportbox:SetText(displayStr); importexportbox.editBox:HighlightText(); end);
        importexportbox.editBox:SetScript("OnMouseUp", function() importexportbox.editBox:HighlightText(); end);
        importexportbox:SetLabel(id.." - "..#displayStr);
        importexportbox.button:Hide();
        importexportbox:SetText(displayStr);
        importexportbox.editBox:HighlightText();
        importexportbox:SetFocus();
      end
    elseif(mode == "import") then
      local textBuffer, i, lastPaste = {}, 0, 0
      local function clearBuffer(self)
        self:SetScript('OnUpdate', nil)
          local pasted = strtrim(table.concat(textBuffer))
          importexportbox.editBox:ClearFocus();
          pasted = pasted:match( "^%s*(.-)%s*$" );
          if (#pasted > 20) then
            WeakAuras.ImportString(pasted);
            importexportbox:SetLabel(L["Processed %i chars"]:format(i));
            importexportbox.editBox:SetMaxBytes(2500);
            importexportbox.editBox:SetText(strsub(pasted, 1, 2500));
          end
      end

      importexportbox.editBox:SetScript('OnChar', function(self, c)
        if lastPaste ~= GetTime() then
          textBuffer, i, lastPaste = {}, 0, GetTime()
          self:SetScript('OnUpdate', clearBuffer)
        end
        i = i + 1
        textBuffer[i] = c
      end)

      importexportbox.editBox:SetText("");
      importexportbox.editBox:SetMaxBytes(2500);
      importexportbox.editBox:SetScript("OnEscapePressed", function() importexport:Close(); end);
      importexportbox.editBox:SetScript("OnMouseUp", nil);
      importexportbox:SetLabel(L["Paste text below"]);
      importexportbox:SetFocus();
    end
  end

  function importexport.Close(self)
    importexportbox:ClearFocus();
    self.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
  end

  local texteditor = AceGUI:Create("InlineGroup");
  texteditor.frame:SetParent(frame);
  texteditor.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12);
  texteditor.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  texteditor.frame:Hide();
  texteditor:SetLayout("fill");
  frame.texteditor = texteditor;

  local texteditorbox = AceGUI:Create("MultiLineEditBox");
  texteditorbox:SetWidth(400);
  texteditorbox.button:Hide();
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
  if(fontPath) then
    texteditorbox.editBox:SetFont(fontPath, 12);
  end
  texteditor:AddChild(texteditorbox);
  texteditorbox.frame:SetClipsChildren(true);

  local colorTable = {}
  colorTable[IndentationLib.tokens.TOKEN_SPECIAL] = "|c00ff3333"
  colorTable[IndentationLib.tokens.TOKEN_KEYWORD] = "|c004444ff"
  colorTable[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = "|c0000aa00"
  colorTable[IndentationLib.tokens.TOKEN_COMMENT_LONG] = "|c0000aa00"
  colorTable[IndentationLib.tokens.TOKEN_NUMBER] = "|c00ff9900"
  colorTable[IndentationLib.tokens.TOKEN_STRING] = "|c00999999"

  local tableColor = "|c00ff3333"
  colorTable["..."] = tableColor
  colorTable["{"] = tableColor
  colorTable["}"] = tableColor
  colorTable["["] = tableColor
  colorTable["]"] = tableColor

  local arithmeticColor = "|c00ff3333"
  colorTable["+"] = arithmeticColor
  colorTable["-"] = arithmeticColor
  colorTable["/"] = arithmeticColor
  colorTable["*"] = arithmeticColor
  colorTable[".."] = arithmeticColor

  local logicColor1 = "|c00ff3333"
  colorTable["=="] = logicColor1
  colorTable["<"] = logicColor1
  colorTable["<="] = logicColor1
  colorTable[">"] = logicColor1
  colorTable[">="] = logicColor1
  colorTable["~="] = logicColor1

  local logicColor2 = "|c004444ff"
  colorTable["and"] = logicColor2
  colorTable["or"] = logicColor2
  colorTable["not"] = logicColor2

  colorTable[0] = "|r"

  -- The indention lib overrides GetText, but for the line number
  -- display we ned the original, so save it here.
  local originalGetText = texteditorbox.editBox.GetText;
  IndentationLib.enable(texteditorbox.editBox, colorTable, 4);

  local texteditorCancel = CreateFrame("Button", nil, texteditor.frame, "UIPanelButtonTemplate");
  texteditorCancel:SetScript("OnClick", function() texteditor:CancelClose() end);
  texteditorCancel:SetPoint("BOTTOMRIGHT", -27, 13);
  texteditorCancel:SetHeight(20);
  texteditorCancel:SetWidth(100);
  texteditorCancel:SetText(L["Cancel"]);

  local texteditorClose = CreateFrame("Button", nil, texteditor.frame, "UIPanelButtonTemplate");
  texteditorClose:SetScript("OnClick", function() texteditor:Close() end);
  texteditorClose:SetPoint("RIGHT", texteditorCancel, "LEFT", -10, 0)
  texteditorClose:SetHeight(20);
  texteditorClose:SetWidth(100);
  texteditorClose:SetText(L["Done"]);

  local texteditorError = texteditor.frame:CreateFontString(nil, "OVERLAY");
  texteditorError:SetFont("Fonts\\FRIZQT__.TTF", 10)
  texteditorError:SetJustifyH("LEFT");
  texteditorError:SetJustifyV("TOP");
  texteditorError:SetTextColor(1, 0, 0);
  texteditorError:SetPoint("TOPLEFT", texteditorbox.frame, "BOTTOMLEFT", 5, 25);
  texteditorError:SetPoint("BOTTOMRIGHT", texteditorClose, "BOTTOMLEFT");

  local textEditorLine = CreateFrame("Editbox", nil, texteditor.frame);
  -- Set script on enter pressed..
  textEditorLine:SetPoint("BOTTOMRIGHT", texteditorbox.frame, "TOPRIGHT", -10, -15);
  textEditorLine:SetFont("Fonts\\FRIZQT__.TTF", 10)
  textEditorLine:SetJustifyH("RIGHT");
  textEditorLine:SetWidth(80);
  textEditorLine:SetHeight(20);
  textEditorLine:SetNumeric(true);
  textEditorLine:SetTextInsets(10, 10, 0, 0);

  local oldOnCursorChanged = texteditorbox.editBox:GetScript("OnCursorChanged");
  texteditorbox.editBox:SetScript("OnCursorChanged", function(...)
    oldOnCursorChanged(...);
    local cursorPosition = texteditorbox.editBox:GetCursorPosition();
    local next = -1;
    local line = 0;
    while (next and cursorPosition >= next) do
      next = originalGetText(texteditorbox.editBox):find("[\n]", next + 1);
      line = line + 1;
    end
    textEditorLine:SetNumber(line);
  end);

  textEditorLine:SetScript("OnEnterPressed", function()
    local newLine = textEditorLine:GetNumber();
    local newPosition = 0;
    while (newLine > 1 and newPosition) do
      newPosition = originalGetText(texteditorbox.editBox):find("[\n]", newPosition + 1);
      newLine = newLine - 1;
    end

    if (newPosition) then
      texteditorbox.editBox:SetCursorPosition(newPosition);
      texteditorbox.editBox:SetFocus();
    end
  end);


  function texteditor.Open(self, data, path, enclose, addReturn)
    self.data = data;
    self.path = path;
    self.addReturn = addReturn;
    if(frame.window == "texture") then
      frame.texturePick:CancelClose();
    elseif(frame.window == "icon") then
      frame.iconPick:CancelClose();
    end
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "texteditor";
    local title = (type(data.id) == "string" and data.id or L["Temporary Group"]).." -";
    for index, field in pairs(path) do
      if(type(field) == "number") then
        field = "Trigger "..field+1
      end
      title = title.." "..field:sub(1, 1):upper()..field:sub(2);
    end
    texteditorbox:SetLabel(title);
    texteditorbox.editBox:SetScript("OnEscapePressed", function() texteditor:CancelClose(); end);
    self.oldOnTextChanged = texteditorbox.editBox:GetScript("OnTextChanged");
    texteditorbox.editBox:SetScript("OnTextChanged", function(...)
      local str = texteditorbox.editBox:GetText();
      if not(str) or texteditorbox.combinedText == true then
        texteditorError:SetText("");
      else
        local _, errorString
        if(enclose) then
          _, errorString = loadstring("return function() "..str.."\n end");
        else
          _, errorString = loadstring("return "..str);
        end
        texteditorError:SetText(errorString or "");
      end
      self.oldOnTextChanged(...);
    end);
    if(data.controlledChildren) then
      local singleText;
      local sameTexts = true;
      local combinedText = "";
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        local text = valueFromPath(childData, path);
        if(addReturn and text and #text > 8) then
          text = text:sub(8);
        end
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
        texteditorbox:SetText(singleText or "");
        texteditorbox.combinedText = false;
      else
        texteditorbox:SetText(combinedText);
        texteditorbox.combinedText = true;
      end
    else
      if(addReturn) then
        local value = valueFromPath(data, path);
        texteditorbox:SetText(value and #value > 8 and value:sub(8) or "");
      else
        texteditorbox:SetText(valueFromPath(data, path) or "");
      end
    end
    texteditorbox:SetFocus();
  end

  function texteditor.CancelClose(self)
    texteditorbox.editBox:SetScript("OnTextChanged", self.oldOnTextChanged);
    texteditorbox:ClearFocus();
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

  function texteditor.Close(self)
    if(self.data.controlledChildren) then
      local textById = texteditorbox.combinedText and extractTexts(texteditorbox:GetText(), self.data.controlledChildren);
      for index, childId in pairs(self.data.controlledChildren) do
        local text = texteditorbox.combinedText and (textById[childId] or "") or texteditorbox:GetText();
        local childData = WeakAuras.GetData(childId);
        if(self.addReturn) then
          valueToPath(childData, self.path, "return "..text);
        else
          valueToPath(childData, self.path, text);
        end
        WeakAuras.Add(childData);
      end
    else
      if(self.addReturn) then
        valueToPath(self.data, self.path, "return "..texteditorbox:GetText());
      else
        valueToPath(self.data, self.path, texteditorbox:GetText());
      end
      WeakAuras.Add(self.data);
    end

    texteditorbox.editBox:SetScript("OnTextChanged", self.oldOnTextChanged);
    texteditorbox:ClearFocus();
    self.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";

    frame:RefreshPick();
  end

  local codereview = AceGUI:Create("InlineGroup");
  codereview.frame:SetParent(frame);
  codereview.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 30);
  codereview.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  codereview.frame:Hide();
  codereview:SetLayout("flow");
  frame.codereview = codereview;

  local codeTree = AceGUI:Create("TreeGroup");
  codereview.codeTree = codeTree;
  codereview:SetLayout("fill");
  codereview:AddChild(codeTree);

  local codebox = AceGUI:Create("MultiLineEditBox");
  codebox.frame:SetAllPoints(codeTree.content);
  codebox.frame:SetFrameStrata("FULLSCREEN");
  codebox:SetLabel("");
  codereview:AddChild(codebox);

  codebox.button:Hide();
  IndentationLib.enable(codebox.editBox, colorTable, 4);
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
  if(fontPath) then
    codebox.editBox:SetFont(fontPath, 12);
  end
  codereview.codebox = codebox;

  codeTree:SetCallback("OnGroupSelected", function(self, event, value)
     for _, v in pairs(codereview.data) do
       if (v.value == value) then
          codebox:SetText(v.code);
       end
     end
  end);

  local codereviewCancel = CreateFrame("Button", nil, codereview.frame, "UIPanelButtonTemplate");
  codereviewCancel:SetScript("OnClick", function() codereview:Close() end);
  codereviewCancel:SetPoint("bottomright", frame, "bottomright", -27, 11);
  codereviewCancel:SetHeight(20);
  codereviewCancel:SetWidth(100);
  codereviewCancel:SetText(L["Okay"]);

  function codereview.Open(self, data)
    if frame.window == "codereview" then
      return
    end

    self.data = data;

    self.codeTree:SetTree(data);
    self.codebox.frame:Show();

    WeakAuras.ShowOptions();

    frame.importexport.frame:Hide();
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "codereview";
  end

  function codereview.Close()
    codereview.frame:Hide();
    codebox.frame:Hide();
    frame.container.frame:Show();
    frame.buttonsContainer.frame:Show();
    frame.window = "default";
  end

  local buttonsContainer = AceGUI:Create("InlineGroup");
  buttonsContainer:SetWidth(170);
  buttonsContainer.frame:SetParent(frame);
  buttonsContainer.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 12);
  buttonsContainer.frame:SetPoint("TOP", frame, "TOP", 0, -10);
  buttonsContainer.frame:SetPoint("right", container.frame, "left", -17);
  buttonsContainer.frame:Show();
  frame.buttonsContainer = buttonsContainer;

  local loadProgress = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  loadProgress:SetPoint("TOP", buttonsContainer.frame, "TOP", 0, -4)
  loadProgress:SetText(L["Creating options: "].."0/0");
  frame.loadProgress = loadProgress;

  local filterInput = CreateFrame("editbox", "WeakAurasFilterInput", buttonsContainer.frame, "InputBoxTemplate");

  filterInput:SetAutoFocus(false);
  filterInput:SetScript("OnTextChanged", function(...) WeakAuras.SortDisplayButtons(filterInput:GetText()) end);
  filterInput:SetScript("OnEnterPressed", function(...) filterInput:ClearFocus() end);
  filterInput:SetScript("OnEscapePressed", function(...) filterInput:SetText(""); filterInput:ClearFocus() end);
  filterInput:SetWidth(150);
  filterInput:SetPoint("BOTTOMLEFT", buttonsContainer.frame, "TOPLEFT", 2, -18);
  filterInput:SetPoint("TOPLEFT", buttonsContainer.frame, "TOPLEFT", 2, -2);
  filterInput:SetTextInsets(16, 0, 0, 0);

  local searchIcon = filterInput:CreateTexture(nil, "overlay");
  searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon");
  searchIcon:SetVertexColor(0.6, 0.6, 0.6);
  searchIcon:SetWidth(14);
  searchIcon:SetHeight(14);
  searchIcon:SetPoint("left", filterInput, "left", 3, -1);
  filterInput:SetFont("Fonts\\FRIZQT__.TTF", 10);
  frame.filterInput = filterInput;
  filterInput:Hide();

  local filterInputClear = CreateFrame("BUTTON", nil, buttonsContainer.frame);
  frame.filterInputClear = filterInputClear;
  filterInputClear:SetWidth(12);
  filterInputClear:SetHeight(12);
  filterInputClear:SetPoint("left", filterInput, "right", 0, -1);
  filterInputClear:SetNormalTexture("Interface\\Common\\VoiceChat-Muted");
  filterInputClear:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  filterInputClear:SetScript("OnClick", function() filterInput:SetText(""); filterInput:ClearFocus() end);
  filterInputClear:Hide();

  local buttonsScroll = AceGUI:Create("ScrollFrame");
  buttonsScroll:SetLayout("ButtonsScrollLayout");
  buttonsScroll.width = "fill";
  buttonsScroll.height = "fill";
  buttonsContainer:SetLayout("fill");
  buttonsContainer:AddChild(buttonsScroll);
  buttonsScroll.DeleteChild = function(self, delete)
    for index, widget in ipairs(buttonsScroll.children) do
      if(widget == delete) then
        tremove(buttonsScroll.children, index);
      end
    end
    delete:OnRelease();
    buttonsScroll:DoLayout();
  end
  frame.buttonsScroll = buttonsScroll;

  function buttonsScroll:GetScrollPos()
    local status = self.status or self.localstatus;
    return status.offset, status.offset + self.scrollframe:GetHeight();
  end

  -- override SetScroll to make childrens visible as needed
  local oldSetScroll = buttonsScroll.SetScroll;
  buttonsScroll.SetScroll = function(self, value)
    if (self:GetScrollPos() ~= value) then
      oldSetScroll(self, value);
      self:DoLayout();
    end
  end

  function buttonsScroll:SetScrollPos(top, bottom)
    local status = self.status or self.localstatus;
    local viewheight = self.scrollframe:GetHeight();
    local height = self.content:GetHeight();
    local move;

    local viewtop = -1 * status.offset;
    local viewbottom = -1 * (status.offset + viewheight);
    if(top > viewtop) then
      move = top - viewtop;
    elseif(bottom < viewbottom) then
      move = bottom - viewbottom;
    else
      move = 0;
    end

    status.offset = status.offset - move;

    self.content:ClearAllPoints();
    self.content:SetPoint("TOPLEFT", 0, status.offset);
    self.content:SetPoint("TOPRIGHT", 0, status.offset);

    status.scrollvalue = status.offset / ((height - viewheight) / 1000.0);

    self:FixScroll();
  end

  local moversizer = CreateFrame("FRAME", nil, frame);
  frame.moversizer = moversizer;
  moversizer:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
  });
  moversizer:EnableMouse();
  moversizer:SetFrameStrata("HIGH");

  moversizer.bl = CreateFrame("FRAME", nil, moversizer);
  moversizer.bl:EnableMouse();
  moversizer.bl:SetWidth(16);
  moversizer.bl:SetHeight(16);
  moversizer.bl:SetPoint("BOTTOMLEFT", moversizer, "BOTTOMLEFT");
  moversizer.bl.l = moversizer.bl:CreateTexture(nil, "OVERLAY");
  moversizer.bl.l:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.bl.l:SetBlendMode("ADD");
  moversizer.bl.l:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  moversizer.bl.l:SetPoint("BOTTOMLEFT", moversizer.bl, "BOTTOMLEFT", 3, 3);
  moversizer.bl.l:SetPoint("TOPRIGHT", moversizer.bl, "TOP");
  moversizer.bl.b = moversizer.bl:CreateTexture(nil, "OVERLAY");
  moversizer.bl.b:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.bl.b:SetBlendMode("ADD");
  moversizer.bl.b:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  moversizer.bl.b:SetPoint("BOTTOMLEFT", moversizer.bl.l, "BOTTOMRIGHT");
  moversizer.bl.b:SetPoint("TOPRIGHT", moversizer.bl, "RIGHT");
  moversizer.bl.Highlight = function()
    moversizer.bl.l:Show();
    moversizer.bl.b:Show();
  end
  moversizer.bl.Clear = function()
    moversizer.bl.l:Hide();
    moversizer.bl.b:Hide();
  end
  moversizer.bl.Clear();

  moversizer.br = CreateFrame("FRAME", nil, moversizer);
  moversizer.br:EnableMouse();
  moversizer.br:SetWidth(16);
  moversizer.br:SetHeight(16);
  moversizer.br:SetPoint("BOTTOMRIGHT", moversizer, "BOTTOMRIGHT");
  moversizer.br.r = moversizer.br:CreateTexture(nil, "OVERLAY");
  moversizer.br.r:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.br.r:SetBlendMode("ADD");
  moversizer.br.r:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  moversizer.br.r:SetPoint("BOTTOMRIGHT", moversizer.br, "BOTTOMRIGHT", -3, 3);
  moversizer.br.r:SetPoint("TOPLEFT", moversizer.br, "TOP");
  moversizer.br.b = moversizer.br:CreateTexture(nil, "OVERLAY");
  moversizer.br.b:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.br.b:SetBlendMode("ADD");
  moversizer.br.b:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1);
  moversizer.br.b:SetPoint("BOTTOMRIGHT", moversizer.br.r, "BOTTOMLEFT");
  moversizer.br.b:SetPoint("TOPLEFT", moversizer.br, "LEFT");
  moversizer.br.Highlight = function()
    moversizer.br.r:Show();
    moversizer.br.b:Show();
  end
  moversizer.br.Clear = function()
    moversizer.br.r:Hide();
    moversizer.br.b:Hide();
  end
  moversizer.br.Clear();

  moversizer.tl = CreateFrame("FRAME", nil, moversizer);
  moversizer.tl:EnableMouse();
  moversizer.tl:SetWidth(16);
  moversizer.tl:SetHeight(16);
  moversizer.tl:SetPoint("TOPLEFT", moversizer, "TOPLEFT");
  moversizer.tl.l = moversizer.tl:CreateTexture(nil, "OVERLAY");
  moversizer.tl.l:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.tl.l:SetBlendMode("ADD");
  moversizer.tl.l:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1);
  moversizer.tl.l:SetPoint("TOPLEFT", moversizer.tl, "TOPLEFT", 3, -3);
  moversizer.tl.l:SetPoint("BOTTOMRIGHT", moversizer.tl, "BOTTOM");
  moversizer.tl.t = moversizer.tl:CreateTexture(nil, "OVERLAY");
  moversizer.tl.t:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.tl.t:SetBlendMode("ADD");
  moversizer.tl.t:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  moversizer.tl.t:SetPoint("TOPLEFT", moversizer.tl.l, "TOPRIGHT");
  moversizer.tl.t:SetPoint("BOTTOMRIGHT", moversizer.tl, "RIGHT");
  moversizer.tl.Highlight = function()
    moversizer.tl.l:Show();
    moversizer.tl.t:Show();
  end
  moversizer.tl.Clear = function()
    moversizer.tl.l:Hide();
    moversizer.tl.t:Hide();
  end
  moversizer.tl.Clear();

  moversizer.tr = CreateFrame("FRAME", nil, moversizer);
  moversizer.tr:EnableMouse();
  moversizer.tr:SetWidth(16);
  moversizer.tr:SetHeight(16);
  moversizer.tr:SetPoint("TOPRIGHT", moversizer, "TOPRIGHT");
  moversizer.tr.r = moversizer.tr:CreateTexture(nil, "OVERLAY");
  moversizer.tr.r:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.tr.r:SetBlendMode("ADD");
  moversizer.tr.r:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1);
  moversizer.tr.r:SetPoint("TOPRIGHT", moversizer.tr, "TOPRIGHT", -3, -3);
  moversizer.tr.r:SetPoint("BOTTOMLEFT", moversizer.tr, "BOTTOM");
  moversizer.tr.t = moversizer.tr:CreateTexture(nil, "OVERLAY");
  moversizer.tr.t:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.tr.t:SetBlendMode("ADD");
  moversizer.tr.t:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1);
  moversizer.tr.t:SetPoint("TOPRIGHT", moversizer.tr.r, "TOPLEFT");
  moversizer.tr.t:SetPoint("BOTTOMLEFT", moversizer.tr, "LEFT");
  moversizer.tr.Highlight = function()
    moversizer.tr.r:Show();
    moversizer.tr.t:Show();
  end
  moversizer.tr.Clear = function()
    moversizer.tr.r:Hide();
    moversizer.tr.t:Hide();
  end
  moversizer.tr.Clear();

  moversizer.l = CreateFrame("FRAME", nil, moversizer);
  moversizer.l:EnableMouse();
  moversizer.l:SetWidth(8);
  moversizer.l:SetPoint("TOPLEFT", moversizer.tl, "BOTTOMLEFT");
  moversizer.l:SetPoint("BOTTOMLEFT", moversizer.bl, "TOPLEFT");
  moversizer.l.l = moversizer.l:CreateTexture(nil, "OVERLAY");
  moversizer.l.l:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.l.l:SetBlendMode("ADD");
  moversizer.l.l:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1);
  moversizer.l.l:SetPoint("BOTTOMLEFT", moversizer.bl, "BOTTOMLEFT", 3, 3);
  moversizer.l.l:SetPoint("TOPRIGHT", moversizer.tl, "TOP", 0, -3);
  moversizer.l.Highlight = function()
    moversizer.l.l:Show();
  end
  moversizer.l.Clear = function()
    moversizer.l.l:Hide();
  end
  moversizer.l.Clear();

  moversizer.b = CreateFrame("FRAME", nil, moversizer);
  moversizer.b:EnableMouse();
  moversizer.b:SetHeight(8);
  moversizer.b:SetPoint("BOTTOMLEFT", moversizer.bl, "BOTTOMRIGHT");
  moversizer.b:SetPoint("BOTTOMRIGHT", moversizer.br, "BOTTOMLEFT");
  moversizer.b.b = moversizer.b:CreateTexture(nil, "OVERLAY");
  moversizer.b.b:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.b.b:SetBlendMode("ADD");
  moversizer.b.b:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1);
  moversizer.b.b:SetPoint("BOTTOMLEFT", moversizer.bl, "BOTTOMLEFT", 3, 3);
  moversizer.b.b:SetPoint("TOPRIGHT", moversizer.br, "RIGHT", -3, 0);
  moversizer.b.Highlight = function()
    moversizer.b.b:Show();
  end
  moversizer.b.Clear = function()
    moversizer.b.b:Hide();
  end
  moversizer.b.Clear();

  moversizer.r = CreateFrame("FRAME", nil, moversizer);
  moversizer.r:EnableMouse();
  moversizer.r:SetWidth(8);
  moversizer.r:SetPoint("BOTTOMRIGHT", moversizer.br, "TOPRIGHT");
  moversizer.r:SetPoint("TOPRIGHT", moversizer.tr, "BOTTOMRIGHT");
  moversizer.r.r = moversizer.r:CreateTexture(nil, "OVERLAY");
  moversizer.r.r:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.r.r:SetBlendMode("ADD");
  moversizer.r.r:SetPoint("BOTTOMRIGHT", moversizer.br, "BOTTOMRIGHT", -3, 3);
  moversizer.r.r:SetPoint("TOPLEFT", moversizer.tr, "TOP", 0, -3);
  moversizer.r.Highlight = function()
    moversizer.r.r:Show();
  end
  moversizer.r.Clear = function()
    moversizer.r.r:Hide();
  end
  moversizer.r.Clear();

  moversizer.t = CreateFrame("FRAME", nil, moversizer);
  moversizer.t:EnableMouse();
  moversizer.t:SetHeight(8);
  moversizer.t:SetPoint("TOPRIGHT", moversizer.tr, "TOPLEFT");
  moversizer.t:SetPoint("TOPLEFT", moversizer.tl, "TOPRIGHT");
  moversizer.t.t = moversizer.t:CreateTexture(nil, "OVERLAY");
  moversizer.t.t:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  moversizer.t.t:SetBlendMode("ADD");
  moversizer.t.t:SetPoint("TOPRIGHT", moversizer.tr, "TOPRIGHT", -3, -3);
  moversizer.t.t:SetPoint("BOTTOMLEFT", moversizer.tl, "LEFT", 3, 0);
  moversizer.t.Highlight = function()
    moversizer.t.t:Show();
  end
  moversizer.t.Clear = function()
    moversizer.t.t:Hide();
  end
  moversizer.t.Clear();

  local mover = CreateFrame("FRAME", nil, moversizer);
  frame.mover = mover;
  mover:EnableMouse();
  mover.moving = {};
  mover.interims = {};
  mover.selfPointIcon = mover:CreateTexture();
  mover.selfPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
  mover.selfPointIcon:SetWidth(16);
  mover.selfPointIcon:SetHeight(16);
  mover.selfPointIcon:SetTexCoord(0, 0.25, 0, 1);
  mover.anchorPointIcon = mover:CreateTexture();
  mover.anchorPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
  mover.anchorPointIcon:SetWidth(16);
  mover.anchorPointIcon:SetHeight(16);
  mover.anchorPointIcon:SetTexCoord(0, 0.25, 0, 1);

  local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  mover.text = moverText;
  moverText:Hide();

  local sizerText = moversizer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  moversizer.text = sizerText;
  sizerText:Hide();

  moversizer.ScaleCorners = function(self, width, height)
    local limit = math.min(width, height) + 16;
    local size = 16;
    if(limit <= 40) then
      size = limit * (2/5);
    end
    moversizer.bl:SetWidth(size);
    moversizer.bl:SetHeight(size);
    moversizer.br:SetWidth(size);
    moversizer.br:SetHeight(size);
    moversizer.tr:SetWidth(size);
    moversizer.tr:SetHeight(size);
    moversizer.tl:SetWidth(size);
    moversizer.tl:SetHeight(size);
  end

  moversizer.ReAnchor = function(self)
    if(mover.moving.region) then
      self:AnchorPoints(mover.moving.region, mover.moving.data);
    end
  end

  moversizer.AnchorPoints = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
    local xOff, yOff;
    mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1);
    mover:ClearAllPoints();
    moversizer:ClearAllPoints();
    if(data.regionType == "group") then
      mover:SetWidth((region.trx - region.blx) * scale);
      mover:SetHeight((region.try - region.bly) * scale);
      mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale);
    else
      mover:SetWidth(region:GetWidth() * scale);
      mover:SetHeight(region:GetHeight() * scale);
      mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
    end
    moversizer:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", -8, -8);
    moversizer:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 8, 8);
    moversizer:ScaleCorners(region:GetWidth(), region:GetHeight());
  end

  moversizer.SetToRegion = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
    mover.moving.region = region;
    mover.moving.data = data;
    local xOff, yOff;
    mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1);
    mover:ClearAllPoints();
    moversizer:ClearAllPoints();
    if(data.regionType == "group") then
      mover:SetWidth((region.trx - region.blx) * scale);
      mover:SetHeight((region.try - region.bly) * scale);
      mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale);
    else
      mover:SetWidth(region:GetWidth() * scale);
      mover:SetHeight(region:GetHeight() * scale);
      mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
    end
    moversizer:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", -8, -8);
    moversizer:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 8, 8);
    moversizer:ScaleCorners(region:GetWidth(), region:GetHeight());

    mover.startMoving = function()
      WeakAuras.CancelAnimation(region, true, true, true, true, true);
      mover:ClearAllPoints();
      if(data.regionType == "group") then
        local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
        mover:SetPoint(mover.selfPoint, region, mover.anchorPoint, region.blx * scale, region.bly * scale);
      else
        mover:SetPoint(mover.selfPoint, region, mover.selfPoint);
      end
      region:StartMoving();
      mover.isMoving = true;
      mover.text:Show();
    end

    mover.doneMoving = function(self)
      local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
      region:StopMovingOrSizing();
      mover.isMoving = false;
      mover.text:Hide();

      if(data.xOffset and data.yOffset) then
        local selfX, selfY = mover.selfPointIcon:GetCenter();
        local anchorX, anchorY = mover.anchorPointIcon:GetCenter();
        local dX = selfX - anchorX;
        local dY = selfY - anchorY;
        data.xOffset = dX / scale;
        data.yOffset = dY / scale;
      end
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      region:SetPoint(self.selfPoint, self.anchor, self.anchorPoint, data.xOffset, data.yOffset);
      mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1);
      mover:ClearAllPoints();
      if(data.regionType == "group") then
        mover:SetWidth((region.trx - region.blx) * scale);
        mover:SetHeight((region.try - region.bly) * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale);
      else
        mover:SetWidth(region:GetWidth() * scale);
        mover:SetHeight(region:GetHeight() * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
      end
      if(data.parent) then
        local parentData = db.displays[data.parent];
        if(parentData) then
          WeakAuras.Add(parentData);
          WeakAuras.SetThumbnail(parentData);
        end
      end
      AceConfigDialog:Open("WeakAuras", container);
      WeakAuras.Animate("display", data.id, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true);
    end

    if(data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup") then
      mover:SetScript("OnMouseDown", nil);
      mover:SetScript("OnMouseUp", nil);
    else
      mover:SetScript("OnMouseDown", mover.startMoving);
      mover:SetScript("OnMouseUp", mover.doneMoving);
    end

    if(region:IsResizable()) then
      moversizer.startSizing = function(point)
        mover.isMoving = true;
        WeakAuras.CancelAnimation(region, true, true, true, true, true);
        local rSelfPoint, rAnchor, rAnchorPoint, rXOffset, rYOffset = region:GetPoint(1);
        region:StartSizing(point);
        local textpoint, anchorpoint;
        if(point:find("BOTTOM")) then textpoint = "TOP"; anchorpoint = "BOTTOM";
        elseif(point:find("TOP")) then textpoint = "BOTTOM"; anchorpoint = "TOP";
        elseif(point:find("LEFT")) then textpoint = "RIGHT"; anchorpoint = "LEFT";
        elseif(point:find("RIGHT")) then textpoint = "LEFT"; anchorpoint = "RIGHT"; end
        moversizer.text:ClearAllPoints();
        moversizer.text:SetPoint(textpoint, moversizer, anchorpoint);
        moversizer.text:Show();
        mover:SetAllPoints(region);
        moversizer:SetScript("OnUpdate", function()
          moversizer.text:SetText(("(%.2f, %.2f)"):format(region:GetWidth(), region:GetHeight()));
          if(data.width and data.height) then
            data.width = region:GetWidth();
            data.height = region:GetHeight();
          end
          WeakAuras.Add(data);
          region:ClearAllPoints();
          region:SetPoint(rSelfPoint, rAnchor, rAnchorPoint, rXOffset, rYOffset);
          moversizer:ScaleCorners(region:GetWidth(), region:GetHeight());
          AceConfigDialog:Open("WeakAuras", container);
        end);
      end

      moversizer.doneSizing = function()
        local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
        mover.isMoving = false;
        region:StopMovingOrSizing();
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        if(data.parent) then
          local parentData = db.displays[data.parent];
          WeakAuras.Add(parentData);
          WeakAuras.SetThumbnail(parentData);
        end
        moversizer.text:Hide();
        moversizer:SetScript("OnUpdate", nil);
        mover:ClearAllPoints();
        mover:SetWidth(region:GetWidth() * scale);
        mover:SetHeight(region:GetHeight() * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
        WeakAuras.Animate("display", data.id, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true);
      end

      moversizer.bl:SetScript("OnMouseDown", function() moversizer.startSizing("BOTTOMLEFT") end);
      moversizer.bl:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.bl:SetScript("OnEnter", moversizer.bl.Highlight);
      moversizer.bl:SetScript("OnLeave", moversizer.bl.Clear);
      moversizer.b:SetScript("OnMouseDown", function() moversizer.startSizing("BOTTOM") end);
      moversizer.b:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.b:SetScript("OnEnter", moversizer.b.Highlight);
      moversizer.b:SetScript("OnLeave", moversizer.b.Clear);
      moversizer.br:SetScript("OnMouseDown", function() moversizer.startSizing("BOTTOMRIGHT") end);
      moversizer.br:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.br:SetScript("OnEnter", moversizer.br.Highlight);
      moversizer.br:SetScript("OnLeave", moversizer.br.Clear);
      moversizer.r:SetScript("OnMouseDown", function() moversizer.startSizing("RIGHT") end);
      moversizer.r:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.r:SetScript("OnEnter", moversizer.r.Highlight);
      moversizer.r:SetScript("OnLeave", moversizer.r.Clear);
      moversizer.tr:SetScript("OnMouseDown", function() moversizer.startSizing("TOPRIGHT") end);
      moversizer.tr:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.tr:SetScript("OnEnter", moversizer.tr.Highlight);
      moversizer.tr:SetScript("OnLeave", moversizer.tr.Clear);
      moversizer.t:SetScript("OnMouseDown", function() moversizer.startSizing("TOP") end);
      moversizer.t:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.t:SetScript("OnEnter", moversizer.t.Highlight);
      moversizer.t:SetScript("OnLeave", moversizer.t.Clear);
      moversizer.tl:SetScript("OnMouseDown", function() moversizer.startSizing("TOPLEFT") end);
      moversizer.tl:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.tl:SetScript("OnEnter", moversizer.tl.Highlight);
      moversizer.tl:SetScript("OnLeave", moversizer.tl.Clear);
      moversizer.l:SetScript("OnMouseDown", function() moversizer.startSizing("LEFT") end);
      moversizer.l:SetScript("OnMouseUp", moversizer.doneSizing);
      moversizer.l:SetScript("OnEnter", moversizer.l.Highlight);
      moversizer.l:SetScript("OnLeave", moversizer.l.Clear);

      moversizer.bl:Show();
      moversizer.b:Show();
      moversizer.br:Show();
      moversizer.r:Show();
      moversizer.tr:Show();
      moversizer.t:Show();
      moversizer.tl:Show();
      moversizer.l:Show();
    else
      moversizer.bl:Hide();
      moversizer.b:Hide();
      moversizer.br:Hide();
      moversizer.r:Hide();
      moversizer.tr:Hide();
      moversizer.t:Hide();
      moversizer.tl:Hide();
      moversizer.l:Hide();
    end
    moversizer:Show();
  end

  local function EnsureTexture(self, texture)
    if(texture) then
      return texture;
    else
      local ret = self:CreateTexture();
      ret:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
      ret:SetWidth(16);
      ret:SetHeight(16);
      ret:SetTexCoord(0, 0.25, 0, 1);
      ret:SetVertexColor(1, 1, 1, 0.25);
      return ret;
    end
  end

  mover:SetScript("OnUpdate", function(self, elaps)
    if(IsShiftKeyDown()) then
      self.goalAlpha = 0.1;
    else
      self.goalAlpha = 1;
    end

    if(self.currentAlpha ~= self.goalAlpha) then
      self.currentAlpha = self.currentAlpha or self:GetAlpha();
      local newAlpha = (self.currentAlpha < self.goalAlpha) and self.currentAlpha + (elaps * 4) or self.currentAlpha - (elaps * 4);
      local newAlpha = (newAlpha > 1 and 1) or (newAlpha < 0.1 and 0.1) or newAlpha;
      mover:SetAlpha(newAlpha);
      moversizer:SetAlpha(newAlpha);
      self.currentAlpha = newAlpha;
    end

    local region = self.moving.region;
    local data = self.moving.data;
    if not(self.isMoving) then
      self.selfPoint, self.anchor, self.anchorPoint = region:GetPoint(1);
    end
    self.selfPointIcon:ClearAllPoints();
    self.selfPointIcon:SetPoint("CENTER", region, self.selfPoint);
    local selfX, selfY = self.selfPointIcon:GetCenter();
    selfX, selfY = selfX or 0, selfY or 0;
    self.anchorPointIcon:ClearAllPoints();
    self.anchorPointIcon:SetPoint("CENTER", self.anchor, self.anchorPoint);
    local anchorX, anchorY = self.anchorPointIcon:GetCenter();
    anchorX, anchorY = anchorX or 0, anchorY or 0;
    if(data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup") then
      self.selfPointIcon:Hide();
      self.anchorPointIcon:Hide();
    else
      self.selfPointIcon:Show();
      self.anchorPointIcon:Show();
    end

    local dX = selfX - anchorX;
    local dY = selfY - anchorY;
    local distance = sqrt(dX^2 + dY^2);
    local angle = atan2(dY, dX);

    local numInterim = floor(distance/40);

    for index, texture in pairs(self.interims) do
      texture:Hide();
    end
    for i = 1, numInterim  do
      local x = (distance - (i * 40)) * cos(angle);
      local y = (distance - (i * 40)) * sin(angle);
      self.interims[i] = EnsureTexture(self, self.interims[i]);
      self.interims[i]:ClearAllPoints();
      self.interims[i]:SetPoint("CENTER", self.anchorPointIcon, "CENTER", x, y);
      self.interims[i]:Show();
    end

    self.text:SetText(("(%.2f, %.2f)"):format(dX, dY));
    local midx = (distance / 2) * cos(angle);
    local midy = (distance / 2) * sin(angle);
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midx, midy);
    if((midx > 0 and (self.text:GetRight() or 0) > (moversizer:GetLeft() or 0)) or (midx < 0 and (self.text:GetLeft() or 0) < (moversizer:GetRight() or 0))) then
      if(midy > 0 and (self.text:GetTop() or 0) > (moversizer:GetBottom() or 0)) then
        midy = midy - ((self.text:GetTop() or 0) - (moversizer:GetBottom() or 0));
      elseif(midy < 0 and (self.text:GetBottom() or 0) < (moversizer:GetTop() or 0)) then
        midy = midy + ((moversizer:GetTop() or 0) - (self.text:GetBottom() or 0));
      end
    end
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midx, midy);
  end);

  local newButton = AceGUI:Create("WeakAurasNewHeaderButton");
  newButton:SetText(L["New"]);
  newButton:SetClick(function() frame:PickOption("New") end);
  frame.newButton = newButton;

  local numAddons = 0;
  for addon, addonData in pairs(WeakAuras.addons) do
    numAddons = numAddons + 1;
  end
  if(numAddons > 0) then
    local addonsButton = AceGUI:Create("WeakAurasNewHeaderButton");
    addonsButton:SetText(L["Addons"]);
    addonsButton:SetDescription(L["Manage displays defined by Addons"]);
    addonsButton:SetClick(function() frame:PickOption("Addons") end);
    frame.addonsButton = addonsButton;
  end

  local loadedButton = AceGUI:Create("WeakAurasLoadedHeaderButton");
  loadedButton:SetText(L["Loaded"]);
  loadedButton:Disable();
  loadedButton:EnableExpand();
  if(odb.loadedCollapse) then
    loadedButton:Collapse();
  else
    loadedButton:Expand();
  end
  loadedButton:SetOnExpandCollapse(function()
    if(loadedButton:GetExpanded()) then
      odb.loadedCollapse = nil;
    else
      odb.loadedCollapse = true;
    end
    WeakAuras.SortDisplayButtons()
  end);
  loadedButton:SetExpandDescription(L["Expand all loaded displays"]);
  loadedButton:SetCollapseDescription(L["Collapse all loaded displays"]);
  loadedButton:SetViewClick(function()
    if(loadedButton.view.func() == 2) then
      for id, child in pairs(displayButtons) do
        if(loaded[id] ~= nil) then
          child:PriorityHide(2);
        end
      end
    else
      for id, child in pairs(displayButtons) do
        if(loaded[id] ~= nil) then
          child:PriorityShow(2);
        end
      end
    end
  end);
  loadedButton:SetViewTest(function()
    local none, all = true, true;
    for id, child in pairs(displayButtons) do
      if(loaded[id] ~= nil) then
        if(child:GetVisibility() ~= 2) then
          all = false;
        end
        if(child:GetVisibility() ~= 0) then
          none = false;
        end
      end
    end
    if(all) then
      return 2;
    elseif(none) then
      return 0;
    else
      return 1;
    end
  end);
  loadedButton:SetViewDescription(L["Toggle the visibility of all loaded displays"]);
  frame.loadedButton = loadedButton;

  local unloadedButton = AceGUI:Create("WeakAurasLoadedHeaderButton");
  unloadedButton:SetText(L["Not Loaded"]);
  unloadedButton:Disable();
  unloadedButton:EnableExpand();
  if(odb.unloadedCollapse) then
    unloadedButton:Collapse();
  else
    unloadedButton:Expand();
  end
  unloadedButton:SetOnExpandCollapse(function()
    if(unloadedButton:GetExpanded()) then
      odb.unloadedCollapse = nil;
    else
      odb.unloadedCollapse = true;
    end
    WeakAuras.SortDisplayButtons()
  end);
  unloadedButton:SetExpandDescription(L["Expand all non-loaded displays"]);
  unloadedButton:SetCollapseDescription(L["Collapse all non-loaded displays"]);
  unloadedButton:SetViewClick(function()
    if(unloadedButton.view.func() == 2) then
      for id, child in pairs(displayButtons) do
        if(loaded[id] == nil) then
          child:PriorityHide(2);
        end
      end
    else
      for id, child in pairs(displayButtons) do
        if not(loaded[id] == nil) then
          child:PriorityShow(2);
        end
      end
    end
  end);
  unloadedButton:SetViewTest(function()
    local none, all = true, true;
    for id, child in pairs(displayButtons) do
      if(loaded[id] == nil) then
        if(child:GetVisibility() ~= 2) then
          all = false;
        end
        if(child:GetVisibility() ~= 0) then
          none = false;
        end
      end
    end
    if(all) then
      return 2;
    elseif(none) then
      return 0;
    else
      return 1;
    end
  end);
  unloadedButton:SetViewDescription(L["Toggle the visibility of all non-loaded displays"]);
  frame.unloadedButton = unloadedButton;

  frame.FillOptions = function(self, optionTable)
    AceConfig:RegisterOptionsTable("WeakAuras", optionTable);
    AceConfigDialog:Open("WeakAuras", container);
    container:SetTitle("");
  end

  frame.ClearPicks = function(self, except)
    WeakAuras.PauseAllDynamicGroups();

    frame.pickedDisplay = nil;
    frame.pickedOption = nil;
    wipe(tempGroup.controlledChildren);
    for id, button in pairs(displayButtons) do
      button:ClearPick();
    end
    newButton:ClearPick();
    if(frame.addonsButton) then
      frame.addonsButton:ClearPick();
    end
    loadedButton:ClearPick();
    unloadedButton:ClearPick();
    container:ReleaseChildren();
    self.moversizer:Hide();

    WeakAuras.ResumeAllDynamicGroups();
  end

  frame.PickOption = function(self, option)
    self:ClearPicks();
    self.moversizer:Hide();
    self.pickedOption = option;
    if(option == "New") then
      newButton:Pick();

      local containerScroll = AceGUI:Create("ScrollFrame");
      containerScroll:SetLayout("flow");
      container:SetLayout("fill");
      container:AddChild(containerScroll);

      if(GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0) then
        local button = AceGUI:Create("WeakAurasNewButton");
        button:SetTitle(L["From Template"]);
        button:SetDescription(L["Offer a guided way to create auras for your class"])
        button:SetIcon("Interface\\Icons\\INV_Misc_Book_06");
        button:SetClick(function()
          WeakAuras.OpenTriggerTemplate();
        end);
        containerScroll:AddChild(button);
      end

      for regionType, regionData in pairs(regionOptions) do
        local button = AceGUI:Create("WeakAurasNewButton");
        button:SetTitle(regionData.displayName);
        if(type(regionData.icon) == "string") then
          button:SetIcon(regionData.icon);
        elseif(type(regionData.icon) == "function") then
          button:SetIcon(regionData.icon());
        end
        button:SetDescription(regionData.description);
        button:SetClick(function()
          local new_id = "New";
          local num = 2;
          while(db.displays[new_id]) do
            new_id = "New "..num;
            num = num + 1;
          end

          local data = {
            id = new_id,
            regionType = regionType,
            activeTriggerMode = WeakAuras.trigger_modes.first_active,
            disjunctive = "all",
            trigger = {
              type = "aura",
              unit = "player",
              debuffType = "HELPFUL"
            },
            load = {}
          };
          WeakAuras.Add(data);
          WeakAuras.NewDisplayButton(data);
          WeakAuras.PickAndEditDisplay(new_id);
        end);
        containerScroll:AddChild(button);
      end
      local importButton = AceGUI:Create("WeakAurasNewButton");
      importButton:SetTitle(L["Import"]);

      local data = {
        outline = false,
        color = {1, 1, 1, 1},
        justify = "CENTER",
        font = "Friz Quadrata TT",
        fontSize = 8,
        displayText = [[
b4vmErLxtfM
xu5fDEn1CEn
vmUmJyZ4hyY
DtnEnvBEnfz
EnfzErLxtjx
zNL2BUrvEWv
MxtfwDYfMyH
jNxtLgzEnLt
LDNx051u25L
tXmdmY4fDE5]];
      };

      local thumbnail = regionOptions["text"].createThumbnail(UIParent);
      regionOptions["text"].modifyThumbnail(UIParent, thumbnail, data);
      thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3);
      thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3);

      importButton:SetIcon(thumbnail);
      importButton:SetDescription(L["Import a display from an encoded string"]);
      importButton:SetClick(WeakAuras.ImportFromString);
      containerScroll:AddChild(importButton);
    elseif(option == "Addons") then
      frame.addonsButton:Pick();

      local containerScroll = AceGUI:Create("ScrollFrame");
      containerScroll:SetLayout("AbsoluteList");
      container:SetLayout("fill");
      container:AddChild(containerScroll);

      WeakAuras.CreateImportButtons();
      WeakAuras.SortImportButtons(containerScroll);
    else
      error("An options button other than New or Addons was selected... but there are no other options buttons!");
    end
  end

  frame.PickDisplay = function(self, id)
    self:ClearPicks();
    local data = WeakAuras.GetData(id);

    local function finishPicking()
      displayButtons[id]:Pick();
      self.pickedDisplay = id;
      local data = db.displays[id];
      WeakAuras.ReloadTriggerOptions(data);
      self:FillOptions(displayOptions[id]);
      WeakAuras.regions[id].region:Collapse();
      WeakAuras.regions[id].region:Expand();
      self.moversizer:SetToRegion(WeakAuras.regions[id].region, db.displays[id]);
      local _, _, _, _, yOffset = displayButtons[id].frame:GetPoint(1);
      if (not yOffset) then
        yOffset = displayButtons[id].frame.yOffset;
      end
      if (yOffset) then
        self.buttonsScroll:SetScrollPos(yOffset, yOffset - 32);
      end
      if(data.controlledChildren) then
        for index, childId in pairs(data.controlledChildren) do
          displayButtons[childId]:PriorityShow(1);
        end
      end
      WeakAuras.ResumeAllDynamicGroups();
    end

    local list = {};
    local num = 0;
    if(data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        if not(displayOptions[childId]) then
          list[childId] = WeakAuras.GetData(childId);
          num = num + 1;
        end
      end
    end
    WeakAuras.EnsureOptions(id);
    if(num > 1) then
      WeakAuras.PauseAllDynamicGroups();
      WeakAuras.BuildOptions(list, finishPicking);
    else
      WeakAuras.PauseAllDynamicGroups();
      finishPicking();
    end
  end

  frame.CenterOnPicked = function(self)
    if(self.pickedDisplay) then
      local centerId = type(self.pickedDisplay) == "string" and self.pickedDisplay or self.pickedDisplay.controlledChildren[1];

      if(displayButtons[centerId]) then
        local _, _, _, _, yOffset = displayButtons[centerId].frame:GetPoint(1);
        if not yOffset then
          yOffset = displayButtons[centerId].frame.yOffset
        end
        if yOffset then
          self.buttonsScroll:SetScrollPos(yOffset, yOffset - 32);
        end
      end
    end
  end

  frame.PickDisplayMultiple = function(self, id)
    if not(self.pickedDisplay) then
      self:PickDisplay(id);
    else
      local wasGroup = false;
      if(type(self.pickedDisplay) == "string") then
        if(WeakAuras.GetData(self.pickedDisplay).controlledChildren) then
          wasGroup = true;
        elseif not(WeakAuras.IsDisplayPicked(id)) then
          tinsert(tempGroup.controlledChildren, self.pickedDisplay);
        end
      end
      if(wasGroup) then
        self:PickDisplay(id);
      elseif not(WeakAuras.IsDisplayPicked(id)) then
        self.pickedDisplay = tempGroup;
        WeakAuras.EnsureOptions(id);
        displayButtons[id]:Pick();
        tinsert(tempGroup.controlledChildren, id);
        WeakAuras.ReloadTriggerOptions(tempGroup);
        self:FillOptions(displayOptions[tempGroup.id]);
      end
    end
  end

  frame.RefreshPick = function(self)
    if(type(self.pickedDisplay) == "string") then
      WeakAuras.EnsureOptions(self.pickedDisplay);
      self:FillOptions(displayOptions[self.pickedDisplay]);
    else
      WeakAuras.EnsureOptions(tempGroup.id);
      self:FillOptions(displayOptions[tempGroup.id]);
    end
  end

  frame:SetClampedToScreen(true);
  local w,h = frame:GetSize();
  local left,right,top,bottom = w/2,-w/2,0,h-25
  frame:SetClampRectInsets(left,right,top,bottom);

  return frame;
end
