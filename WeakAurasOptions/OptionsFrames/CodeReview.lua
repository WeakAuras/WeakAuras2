if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local IndentationLib = IndentationLib

local WeakAuras = WeakAuras
local L = WeakAuras.L

local codeReview

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
  -- ellipsis, curly braces, table access
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

local function ConstructCodeReview(frame)
  local group = AceGUI:Create("WeakAurasInlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 46);
  group.frame:Hide();
  group:SetLayout("flow");

  local title = AceGUI:Create("Label")
  title:SetFontObject(GameFontNormalHuge)
  title:SetFullWidth(true)
  title:SetText(L["Custom Code Viewer"])
  group:AddChild(title)

  local codeTree = AceGUI:Create("TreeGroup");
  codeTree:SetTreeWidth(300, false)
  codeTree:SetFullWidth(true)
  codeTree:SetFullHeight(true)
  codeTree:SetLayout("flow")
  codeTree.dragger:Hide()
  codeTree.border:SetBackdrop(nil)
  codeTree.content:SetAllPoints()
  group.codeTree = codeTree;
  group:AddChild(codeTree);

  local codebox = AceGUI:Create("MultiLineEditBox");
  codebox:SetLabel("");
  codebox:DisableButton(true)
  codebox:SetFullWidth(true)
  codebox:SetFullHeight(true)
  codeTree:AddChild(codebox)

  IndentationLib.enable(codebox.editBox, colorScheme, 4);
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
  if(fontPath) then
    codebox.editBox:SetFont(fontPath, 12, "");
  end
  group.codebox = codebox;

  codeTree:SetCallback("OnGroupSelected", function(self, event, value)
    for _, v in pairs(group.data) do
      if (v.value == value) then
        codebox:SetText(v.code);
      end
    end
  end);

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", function() group:Close() end);
  cancel:SetPoint("BOTTOMRIGHT", -20, -24);
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Okay"]);

  function group.Open(self, data)
    if frame.window == "codereview" then
      return
    end

    local _, firstEntry = next(data)
    self.data = data;
    self.codeTree:SetTree(data);
    self.codeTree:SelectByValue(firstEntry.value)

    frame.window = "codereview";
    frame:UpdateFrameVisible()
  end

  function group.Close()
    frame.window = "update";
    frame:UpdateFrameVisible()
  end

  return group
end

function OptionsPrivate.CodeReview(frame)
  codeReview = codeReview or ConstructCodeReview(frame)
  return codeReview
end
