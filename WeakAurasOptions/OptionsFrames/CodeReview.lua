if not WeakAuras.IsCorrectVersion() then return end
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
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 30);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  group.frame:Hide();
  group:SetLayout("flow");

  local codeTree = AceGUI:Create("TreeGroup");
  group.codeTree = codeTree;
  group:SetLayout("fill");
  group:AddChild(codeTree);

  local codebox = AceGUI:Create("MultiLineEditBox");
  codebox.frame:SetAllPoints(codeTree.content);
  codebox.frame:SetFrameStrata("FULLSCREEN");
  codebox:SetLabel("");
  group:AddChild(codebox);

  codebox.button:Hide();
  IndentationLib.enable(codebox.editBox, colorScheme, 4);
  local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
  if(fontPath) then
    codebox.editBox:SetFont(fontPath, 12);
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
  cancel:SetPoint("bottomright", frame, "bottomright", -27, 11);
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText(L["Okay"]);

  function group.Open(self, data)
    if frame.window == "codereview" then
      return
    end

    self.data = data;
    self.codeTree:SetTree(data);

    WeakAuras.ShowOptions();
    frame.window = "codereview";
    frame:UpdateFrameVisible()
  end

  function group.Close()
    frame.window = "default";
    frame:UpdateFrameVisible()
  end

  return group
end

function OptionsPrivate.CodeReview(frame)
  codeReview = codeReview or ConstructCodeReview(frame)
  return codeReview
end
