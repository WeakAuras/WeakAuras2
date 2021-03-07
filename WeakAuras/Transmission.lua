--[[ Transmisson.lua
This file contains all transmission related functionality, e.g. import/export and chat links.
For that it hooks into the chat frame and addon message channels.

This file adds the following API to the WeakAuras object:

DisplayToString(id, forChat)
Converts the display id to a plain text string

DataToString(id)
Converts the display id to a formatted table

SerializeTable(data)
Converts the table data to a formatted table

ShowDisplayTooltip(data, children, icon, icons, import, compressed)
Shows a tooltip frame for an aura, which allows for importing if import is true

Import(str, [target])
Imports an aura from a table, which may or may not be encoded as a B64 string.
If target is installed data, or is a uid which points to installed data, then the import will be an update to that aura

]]--
if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

-- Lua APIs
local tinsert = table.insert
local tostring, string_char, strsplit = tostring, string.char, strsplit
local pairs, type, unpack = pairs, type, unpack
local error = error
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift
local coroutine = coroutine

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local versionString = WeakAuras.versionString;

local regionOptions = WeakAuras.regionOptions;
local regionTypes = WeakAuras.regionTypes;

-- Local functions
local decodeB64, GenerateUniqueID
local CompressDisplay, ShowTooltip, TableToString, StringToTable
local RequestDisplay, TransmitError, TransmitDisplay

local bytetoB64 = {
  [0]="a","b","c","d","e","f","g","h",
  "i","j","k","l","m","n","o","p",
  "q","r","s","t","u","v","w","x",
  "y","z","A","B","C","D","E","F",
  "G","H","I","J","K","L","M","N",
  "O","P","Q","R","S","T","U","V",
  "W","X","Y","Z","0","1","2","3",
  "4","5","6","7","8","9","(",")"
}

local B64tobyte = {
  a =  0,  b =  1,  c =  2,  d =  3,  e =  4,  f =  5,  g =  6,  h =  7,
  i =  8,  j =  9,  k = 10,  l = 11,  m = 12,  n = 13,  o = 14,  p = 15,
  q = 16,  r = 17,  s = 18,  t = 19,  u = 20,  v = 21,  w = 22,  x = 23,
  y = 24,  z = 25,  A = 26,  B = 27,  C = 28,  D = 29,  E = 30,  F = 31,
  G = 32,  H = 33,  I = 34,  J = 35,  K = 36,  L = 37,  M = 38,  N = 39,
  O = 40,  P = 41,  Q = 42,  R = 43,  S = 44,  T = 45,  U = 46,  V = 47,
  W = 48,  X = 49,  Y = 50,  Z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
  ["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["("]=62,[")"]=63
}

-- This code is based on the Encode7Bit algorithm from LibCompress
-- Credit goes to Galmok (galmok@gmail.com)
local decodeB64Table = {}

function decodeB64(str)
  local bit8 = decodeB64Table;
  local decoded_size = 0;
  local ch;
  local i = 1;
  local bitfield_len = 0;
  local bitfield = 0;
  local l = #str;
  while true do
    if bitfield_len >= 8 then
      decoded_size = decoded_size + 1;
      bit8[decoded_size] = string_char(bit_band(bitfield, 255));
      bitfield = bit_rshift(bitfield, 8);
      bitfield_len = bitfield_len - 8;
    end
    ch = B64tobyte[str:sub(i, i)];
    bitfield = bitfield + bit_lshift(ch or 0, bitfield_len);
    bitfield_len = bitfield_len + 6;
    if i > l then
      break;
    end
    i = i + 1;
  end
  return table.concat(bit8, "", 1, decoded_size)
end

function GenerateUniqueID()
  -- generates a unique random 11 digit number in base64
  local s = {}
  for i=1,11 do
    tinsert(s, bytetoB64[math.random(0, 63)])
  end
  return table.concat(s)
end
WeakAuras.GenerateUniqueID = GenerateUniqueID

local function stripNonTransmissableFields(datum, fieldMap)
  for k, v in pairs(fieldMap) do
    if type(v) == "table" and type(datum[k]) == "table" then
      stripNonTransmissableFields(datum[k], v)
    elseif v == true then
      datum[k] = nil
    end
  end
end

function CompressDisplay(data)
  -- Clean up custom trigger fields that are unused
  -- Those can contain lots of unnecessary data.
  -- Also we warn about any custom code, so removing unnecessary
  -- custom code prevents unnecessary warnings
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger

    if (trigger and trigger.type ~= "custom") then
      trigger.custom = nil;
      trigger.customDuration = nil;
      trigger.customName = nil;
      trigger.customIcon = nil;
      trigger.customTexture = nil;
      trigger.customStacks = nil;
      if (untrigger) then
        untrigger.custom = nil;
      end
    end
  end

  local copiedData = CopyTable(data)
  stripNonTransmissableFields(copiedData, Private.non_transmissable_fields)
  copiedData.tocversion = WeakAuras.BuildInfo
  return copiedData;
end

local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
  if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0) then
    return
  end

  local newMsg = "";
  local remaining = msg;
  local done;
  repeat
    local start, finish, characterName, displayName = remaining:find("%[WeakAuras: ([^%s]+) %- ([^%]]+)%]");
    if(characterName and displayName) then
      characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
      displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
      newMsg = newMsg..remaining:sub(1, start-1);
      newMsg = newMsg.."|Hgarrmission:weakauras|h|cFF8800FF["..characterName.." |r|cFF8800FF- "..displayName.."]|h|r";
      remaining = remaining:sub(finish + 1);
    else
      done = true;
    end
  until(done)
  if newMsg ~= "" then
    local trimmedPlayer = Ambiguate(player, "none")
    if event == "CHAT_MSG_WHISPER" and not UnitInRaid(trimmedPlayer) and not UnitInParty(trimmedPlayer) then -- XXX: Need a guild check
      local _, num = BNGetNumFriends()
      for i=1, num do
        if C_BattleNet then -- introduced in 8.2.5 PTR
          local toon = C_BattleNet.GetFriendNumGameAccounts(i)
          for j=1, toon do
            local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j);
            if gameAccountInfo.characterName == trimmedPlayer and gameAccountInfo.clientProgram == "WoW" then
              return false, newMsg, player, l, cs, t, flag, channelId, ...; -- Player is a real id friend, allow it
            end
          end
        else -- keep old method for 8.2 and Classic
          local toon = BNGetNumFriendGameAccounts(i)
          for j=1, toon do
            local _, rName, rGame = BNGetFriendGameAccountInfo(i, j)
            if rName == trimmedPlayer and rGame == "WoW" then
              return false, newMsg, player, l, cs, t, flag, channelId, ...; -- Player is a real id friend, allow it
            end
          end
        end
      end
      return true -- Filter strangers
    else
      return false, newMsg, player, l, cs, t, flag, channelId, ...;
    end
  end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filterFunc)

local buttonAnchor = CreateFrame("FRAME", "WeakAurasTooltipAnchor", ItemRefTooltip)
buttonAnchor:SetAllPoints()
buttonAnchor:Hide()
buttonAnchor:RegisterEvent("PLAYER_REGEN_ENABLED")
buttonAnchor:RegisterEvent("PLAYER_REGEN_DISABLED")

local thumbnailAnchor = CreateFrame("FRAME",  "WeakAurasTooltipThumbnailFrame", buttonAnchor)
thumbnailAnchor:SetSize(40,40)
thumbnailAnchor:SetPoint("TOPRIGHT", -27, -8)

local importButton = CreateFrame("BUTTON", "WeakAurasTooltipImportButton", buttonAnchor, "UIPanelButtonTemplate")
importButton:SetPoint("BOTTOMRIGHT", -8, 8)


local showCodeButton = CreateFrame("BUTTON", "WeakAurasTooltipImportButton", buttonAnchor, "UIPanelButtonTemplate")
showCodeButton:SetPoint("BOTTOMLEFT", 8, 8)
showCodeButton:SetText(L["Show Code"])
showCodeButton:SetWidth(90)

local urlEditBox = CreateFrame("EDITBOX", "WeakAurasTooltipUrlEditBox", buttonAnchor)
urlEditBox:SetWidth(250)
urlEditBox:SetHeight(34)
urlEditBox:SetFont(STANDARD_TEXT_FONT, 12)
urlEditBox:SetPoint("TOPLEFT", 8, -57)
urlEditBox:SetScript("OnMouseUp", function() urlEditBox:HighlightText() end)
urlEditBox:SetScript("OnChar", function() urlEditBox:SetText(urlEditBox.text) urlEditBox:HighlightText() end)
urlEditBox:SetAutoFocus(false)

local checkButtons, radioButtons, keyToButton, pendingData = {}, {}, {}, {}

for _, key in pairs(Private.internal_fields) do
  keyToButton[key] = false
end

for index,category in pairs(Private.update_categories) do
  local button = CreateFrame("checkButton", "WeakAurasTooltipCheckButton"..index, buttonAnchor, "ChatConfigCheckButtonTemplate")
  for k, v in pairs(category) do
    button[k] = v
  end
  button.text = _G[button:GetName().."Text"]
  local point, relativeFrame, relativePoint, xOff, yOff = button.text:GetPoint(1)
  xOff = xOff + 4
  yOff = yOff - 2
  button.text:SetPoint(point, relativeFrame, relativePoint, xOff, yOff)
  button.text:SetText(button.label)
  button.text:SetTextColor(1, 0.82, 0)
  button.func = function()
    if button:GetChecked() then
      pendingData.buttonsChecked = min(pendingData.buttonsChecked + 1, #checkButtons)
    else
      pendingData.buttonsChecked = max(pendingData.buttonsChecked - 1, 0)
    end
    radioButtons[#radioButtons]:Click()
  end
  checkButtons[index] = button
  checkButtons[button.name] = button
  for _, key in pairs(category.fields) do
    keyToButton[key] = button
  end
end

radioButtons = {
  CreateFrame("CHECKBUTTON", "WeakAurasTooltipRadioButtonCopy", buttonAnchor, "UIRadioButtonTemplate"),
  -- CreateFrame("CHECKBUTTON", "WeakAurasTooltipRadioButtonReplace", buttonAnchor, "UIRadioButtonTemplate"),
  CreateFrame("CHECKBUTTON", "WeakAurasTooltipRadioButtonUpdate", buttonAnchor, "UIRadioButtonTemplate"),
}

local radioButtonLabels = {
  L["Create a Copy"],
  L["Update Auras"]
}

for index, button in ipairs(radioButtons) do
  button.text = _G[button:GetName().."Text"]
  button.text:SetFontObject("GameFontNormal")
  button.text:SetText(radioButtonLabels[index])
  button:SetScript("OnClick", function(self)
    for _, button in ipairs(radioButtons) do
      button:SetChecked(button == self)
    end
    pendingData.mode = index
    Private.RefreshTooltipButtons()
  end)
end

-- Ideally, we would not add an __index method to this
-- But that would greatly bloat the update_category for display
-- A better solution would be to refactor the data
-- Such that all of the display tab settings are in their own subtable
setmetatable(keyToButton,{__index = function(_, key) return key and checkButtons.display end,})

local deleted = {} -- magic value
local function recurseUpdate(data, chunk)
  for k,v in pairs(chunk) do
    if v == deleted then
      data[k] = nil
    elseif type(v) == 'table' and type(data[k]) == 'table' then
      recurseUpdate(data[k], v)
    else
      data[k] = v
    end
  end
end

local function Update(data, diff)
  -- modifies the installed data such that it matches the pending import, sans user-specified options
  -- diff is expected to be output generated by diff
  if not diff then
    WeakAuras.Add(data)
    return
  end
  if not data then
    return
  end
  recurseUpdate(data, diff)
  WeakAuras.Add(data)
  return data
end

local function install(data, oldData, patch, mode, isParent)
  -- munch the provided data and add, update, or delete as appropriate
  -- return the data which the SV knows about afterwards (if there is any)
  local installedUID, imported
  if mode == 1 then
    -- always import as a new thing, set preferToUpdate = false
    if data then
      imported = CopyTable(data)
      data.id = WeakAuras.FindUnusedId(data.id)
      WeakAuras.Add(data)
      installedUID = data.uid
      data.preferToUpdate = false
      if oldData then
        oldData.preferToUpdate = false
      end
    else
      -- nothing to add
      return
    end
  elseif not oldData then
    -- this is a new thing
    if not checkButtons.newchildren:GetChecked() then
      -- user has chosen to not add new children, so do nothing
      return
    end
    imported = CopyTable(data)
    data.id = WeakAuras.FindUnusedId(data.id)
    data.preferToUpdate = true
    WeakAuras.Add(data)
    installedUID = data.uid
  elseif not data then
    -- this is an old thing
    if checkButtons.oldchildren:GetChecked() then
      WeakAuras.Delete(oldData)
      return
    else
      -- user has chosen to not delete obsolete auras, so do nothing
      return Private.GetDataByUID(oldData.uid)
    end
  else
    -- something to update
    if patch then -- if there's no result from Diff, then there's nothing to do
      for key in pairs(patch) do
        local checkButton = keyToButton[key]
        if not isParent and checkButton == checkButtons.anchor then
          checkButton = checkButtons.arrangement
        end
        if checkButton and not checkButton:GetChecked() then
          patch[key] = nil
        end
      end
      if patch.id then
        patch.id = WeakAuras.FindUnusedId(patch.id)
      end
    end
    WeakAuras.Delete(oldData)
    if data.uid and data.uid ~= oldData.uid then
      oldData.uid = data.uid
    end
    Update(oldData, patch)
    oldData.preferToUpdate = true
    installedUID = oldData.uid
    imported = data
  end
  -- if at this point, then some change has been made in the db. Update History to reflect the change
  Private.SetHistory(installedUID, imported, "import")
  return Private.GetDataByUID(installedUID)
end

local function importPendingData()
  -- get necessary info
  local imports, old, diffs = pendingData.newData, pendingData.oldData or {}, pendingData.diffs or {}
  local addedChildren, deletedChildren = pendingData.added or 0, pendingData.deleted or 0
  local mode = pendingData.mode or 1
  local indexMap = pendingData.indexMap

  -- cleanup the mess
  ItemRefTooltip:Hide()-- this also wipes pendingData via the hook on L521
  buttonAnchor:Hide()
  if thumbnailAnchor.currentThumbnail then
    regionOptions[thumbnailAnchor.currentThumbnailType].releaseThumbnail(thumbnailAnchor.currentThumbnail)
    thumbnailAnchor.currentThumbnail = nil
  end
  if imports and Private.LoadOptions() then
    if not WeakAuras.IsOptionsOpen() then
      WeakAuras.OpenOptions()
    end
  else
    return
  end
  WeakAuras.CloseImportExport()
  WeakAuras.SetImporting(true)

  -- import parent/single aura
  local data, oldData, patch = imports[0], old[0], diffs[0]
  data.parent = nil
  -- handle sortHybridTable
  local hybridTables
  if (data and data.sortHybridTable) or (mode ~= 1 and oldData and oldData.sortHybridTable) then
    hybridTables = {
      new = data and data.sortHybridTable or {},
      old = mode ~= 1 and oldData and oldData.sortHybridTable or {},
      merged = {},
    }
  end
  if data then
    data.authorMode = nil
  end
  if oldData then
    oldData.authorMode = nil
  end
  local installedData = {[0] = install(data, oldData, patch, mode, true)}
  WeakAuras.NewDisplayButton(installedData[0])
  coroutine.yield()

  -- handle children, if there are any
  if #imports > 0 then
    local parentData = installedData[0]
    local preserveOldArrangement = mode ~= 1 and not checkButtons.arrangement:GetChecked()

    local map
    if not indexMap then
      map = {}
    else
      map = preserveOldArrangement and indexMap.oldToNew or indexMap.newToOld
    end
    for i = 1, preserveOldArrangement and #old or #imports do
      local j = map[i]
      if preserveOldArrangement then
        oldData = old[i]
        if j then
          data, patch = imports[j], diffs[j]
        else
          data, patch = nil, nil
        end
      else
        data, patch = imports[i], diffs[i]
        if j then
          oldData = old[j]
        else
          oldData = nil
        end
      end
      local oldID, newID = oldData and oldData.id, data and data.id
      if oldData and mode ~= 1 then
        oldData.parent = parentData.id
      end
      if data then
        data.parent = parentData.id
        data.authorMode = nil
      end
      if oldData then
        oldData.authorMode = nil
      end
      local childData = install(data, oldData, patch, mode)
      if childData then
        tinsert(installedData, childData)
        if hybridTables then
          if preserveOldArrangement then
            hybridTables.merged[childData.id] = oldID and hybridTables.old[oldID]
          else
            hybridTables.merged[childData.id] = newID and hybridTables.new[newID]
          end
        end
      end
      coroutine.yield()
    end

    -- now, the other side of the data may have some children which need to be handled
    if mode ~= 1 then
      if preserveOldArrangement then
        if checkButtons.newchildren:GetChecked() and addedChildren > 0 then
          -- we have children which need to be added
          local nextInsert, highestInsert, toInsert, newToOld = 1, 0, {}, indexMap.newToOld
          for newIndex, data in ipairs(imports) do
            local oldIndex = newToOld[newIndex]
            if oldIndex then
              nextInsert = oldIndex + 1
            else
              if nextInsert > highestInsert then
                highestInsert = nextInsert
              end
              toInsert[nextInsert] = toInsert[nextInsert] or {}
              tinsert(toInsert[nextInsert], data)
            end
            coroutine.yield()
          end
          for index = highestInsert, 1, -1 do -- go backwards so that tinsert doesn't screw things up
            if toInsert[index] then
              for i = #toInsert[index], 1, -1 do
                local data = toInsert[index][i]
                local id = data.id
                data.id = WeakAuras.FindUnusedId(id)
                data.parent = parentData.id;
                WeakAuras.Add(data)
                tinsert(installedData, index, data)
                if hybridTables and hybridTables.new[id] then
                  hybridTables.merged[data.id] = true
                end
                coroutine.yield()
              end
            end
          end
        end
      elseif deletedChildren > 0 then
        if not checkButtons.oldchildren:GetChecked() then
          -- we have existing children which need migrating
          -- same algorithm as before, but mirror image
          local nextInsert, highestInsert, toInsert, oldToNew = 1, 0, {}, indexMap.oldToNew
          for oldIndex, data in ipairs(old) do
            local newIndex = oldToNew[oldIndex]
            if newIndex then
              nextInsert = newIndex + 1
            else
              if nextInsert > highestInsert then
                highestInsert = nextInsert
              end
              toInsert[nextInsert] = toInsert[nextInsert] or {}
              tinsert(toInsert[nextInsert], data)
            end
          end
          coroutine.yield()
          for index = highestInsert, 1, -1 do -- go backwards so that tinsert doesn't screw things up
            if toInsert[index] then
              for i = #toInsert[index], 1, -1 do
                local data = toInsert[index][i]
                if hybridTables and hybridTables.old[data.id] then
                  hybridTables.merged[data.id] = true
                end
                tinsert(installedData, index, data)
              end
            end
          end
          coroutine.yield()
        else-- we have children which need deleting
          local oldToNew = indexMap.oldToNew
          for oldIndex, oldData in ipairs(old) do
            if not oldToNew[oldIndex] and WeakAuras.GetData(oldData.id) then
              WeakAuras.Delete(oldData)
              coroutine.yield()
            end
          end
        end
      end
    end

    parentData.controlledChildren = {}
    parentData.sortHybridTable = hybridTables and hybridTables.merged
    for index, installedChild in ipairs(installedData) do
      installedChild.parent = parentData.id
      tinsert(parentData.controlledChildren, installedChild.id)
      WeakAuras.NewDisplayButton(installedChild)
      local childButton = WeakAuras.GetDisplayButton(installedChild.id)
      childButton:SetGroup(parentData.id, parentData.regionType == "dynamicgroup")
      childButton:SetGroupOrder(index, #parentData.controlledChildren)
      coroutine.yield()
    end

    WeakAuras.Add(parentData);
    local button = WeakAuras.GetDisplayButton(parentData.id)
    button.callbacks.UpdateExpandButton()
    WeakAuras.UpdateGroupOrders(parentData)
    WeakAuras.UpdateDisplayButton(parentData)
    WeakAuras.ClearAndUpdateOptions(parentData.id)
    Private.callbacks:Fire("Import")
  end
  WeakAuras.SetImporting(false)
  return WeakAuras.PickDisplay(installedData[0].id)
end

ItemRefTooltip:HookScript("OnHide", function(self)
  buttonAnchor:Hide()
  wipe(pendingData)
  if (ItemRefTooltip.WeakAuras_Desc_Box) then
    ItemRefTooltip.WeakAuras_Desc_Box:Hide();
  end
end)

importButton:SetScript("OnClick", function()
  Private.dynFrame:AddAction("import", coroutine.create(importPendingData))
end)

showCodeButton:SetScript("OnClick", function()
  WeakAuras.OpenOptions()
  WeakAuras.OpenCodeReview(pendingData.codes)
end)


local Compresser = LibStub:GetLibrary("LibCompress")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibSerialize = LibStub("LibSerialize")
local Comm = LibStub:GetLibrary("AceComm-3.0")
local configForDeflate = {level = 9} -- the biggest bottleneck by far is in transmission and printing; so use maximal compression
local configForLS = {
  errorOnUnserializableType =  false
}

local tooltipLoading;
local receivedData;

hooksecurefunc("SetItemRef", function(link, text)
  buttonAnchor:Hide()
  if(link == "garrmission:weakauras") then
    local _, _, characterName, displayName = text:find("|Hgarrmission:weakauras|h|cFF8800FF%[([^%s]+) |r|cFF8800FF%- ([^%]]+)%]|h");
    if(characterName and displayName) then
      characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
      displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
      if(IsShiftKeyDown()) then
        local editbox = GetCurrentKeyBoardFocus();
        if(editbox) then
          editbox:Insert("[WeakAuras: "..characterName.." - "..displayName.."]");
        end
      else
        characterName = characterName:gsub("%.", "")
        ShowTooltip({
          {2, "WeakAuras", displayName, 0.5, 0, 1, 1, 1, 1},
          {1, L["Requesting display information from %s ..."]:format(characterName), 1, 0.82, 0},
          {1, L["Note, that cross realm transmission is possible if you are on the same group"], 1, 0.82, 0}
        });
        tooltipLoading = true;
        receivedData = false;
        RequestDisplay(characterName, displayName);
        WeakAuras.timer:ScheduleTimer(function()
          if (tooltipLoading and not receivedData and ItemRefTooltip:IsVisible()) then
            ShowTooltip({
              {2, "WeakAuras", displayName, 0.5, 0, 1, 1, 1, 1},
              {1, L["Error not receiving display information from %s"]:format(characterName), 1, 0, 0},
              {1, L["Note, that cross realm transmission is possible if you are on the same group"], 1, 0.82, 0}
            })
          end
        end, 5);
      end
    else
      ShowTooltip({
        {1, "WeakAuras", 0.5, 0, 1},
        {1, L["Malformed WeakAuras link"], 1, 0, 0}
      });
    end
  end
end);

local compressedTablesCache = {}

function TableToString(inTable, forChat)
  local serialized = LibSerialize:SerializeEx(configForLS, inTable)
  local compressed
  -- get from / add to cache
  if compressedTablesCache[serialized] then
    compressed = compressedTablesCache[serialized].compressed
    compressedTablesCache[serialized].lastAccess = time()
  else
    compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
    compressedTablesCache[serialized] = {
      compressed = compressed,
      lastAccess = time(),
    }
  end
  -- remove cache items after 5 minutes
  for k, v in pairs(compressedTablesCache) do
    if v.lastAccess < (time() - 300) then
      compressedTablesCache[k] = nil
    end
  end
  local encoded = "!WA:2!"
  if(forChat) then
    encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
  else
    encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
  end
  return encoded
end

function StringToTable(inString, fromChat)
  -- encoding format:
  -- version 0: simple b64 string, compressed with LC and serialized with AS
  -- version 1: b64 string prepended with "!", compressed with LD and serialized with AS
  -- version 2+: b64 string prepended with !WA:N! (where N is encode version)
  --   compressed with LD and serialized with LS
  local _, _, encodeVersion, encoded = inString:find("^(!WA:%d+!)(.+)$")
  if encodeVersion then
    encodeVersion = tonumber(encodeVersion:match("%d+"))
  else
    encoded, encodeVersion = inString:gsub("^%!", "")
  end

  local decoded
  if(fromChat) then
    if encodeVersion > 0 then
      decoded = LibDeflate:DecodeForPrint(encoded)
    else
      decoded = decodeB64(encoded)
    end
  else
    decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
  end

  if not decoded then
    return "Error decoding."
  end

  local decompressed, errorMsg = nil, "unknown compression method"
  if encodeVersion > 0 then
    decompressed = LibDeflate:DecompressDeflate(decoded)
  else
    decompressed, errorMsg = Compresser:Decompress(decoded)
  end
  if not(decompressed) then
    return "Error decompressing: " .. errorMsg
  end

  local success, deserialized
  if encodeVersion < 2 then
    success, deserialized = Serializer:Deserialize(decompressed)
  else
    success, deserialized = LibSerialize:Deserialize(decompressed)
  end
  if not(success) then
    return "Error deserializing "..deserialized
  end
  return deserialized
end
Private.StringToTable = StringToTable

function Private.DisplayToString(id, forChat)
  local data = WeakAuras.GetData(id);
  if(data) then
    data.uid = data.uid or GenerateUniqueID()
    local transmitData = CompressDisplay(data);
    local transmit = {
      m = "d",
      d = transmitData,
      v = 1421, -- Version of Transmisson, won't change anymore.
      s = versionString
    };
    local firstTrigger = data.triggers[1].trigger
    if(firstTrigger.type == "aura" and WeakAurasOptionsSaved and WeakAurasOptionsSaved.spellCache) then
      transmit.a = {};
      for i,v in pairs(firstTrigger.names) do
        transmit.a[v] = WeakAuras.spellCache.GetIcon(v);
      end
    end
    if(data.controlledChildren) then
      transmit.c = {};
      local uids = {}
      local index = 1
      for child in Private.TraverseAllChildren(data) do
        if child.uid then
          if uids[child.uid] then
            child.uid = GenerateUniqueID()
          else
            uids[child.uid] = true
          end
        else
          child.uid = GenerateUniqueID()
        end
        transmit.c[index] = CompressDisplay(child);
        index = index + 1
        if child.controlledChildren then
          transmit.v = 2000
        end
      end
    end
    return TableToString(transmit, forChat);
  else
    return "";
  end
end

local function recurseStringify(data, level, lines)
  for k, v in pairs(data) do
    local lineFormat = strrep("    ", level) .. "[%s] = %s"
    local form1, form2, value
    local kType, vType = type(k), type(v)
    if kType == "string" then
      form1 = "%q"
    elseif kType == "number" then
      form1 = "%d"
    else
      form1 = "%s"
    end
    if vType == "string" then
      form2 = "%q"
      v = v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"")
    elseif vType == "boolean" then
      v = tostring(v)
      form2 = "%s"
    else
      form2 = "%s"
    end
    lineFormat = lineFormat:format(form1, form2)
    if vType == "table" then
      tinsert(lines, lineFormat:format(k, "{"))
      recurseStringify(v, level + 1, lines)
      tinsert(lines, strrep("    ", level) .. "},")
    else
      tinsert(lines, lineFormat:format(k, v) .. ",")
    end
  end
end

function Private.DataToString(id)
  local data = WeakAuras.GetData(id)
  if data then
    return Private.SerializeTable(data):gsub("|", "||")
  end
end

function Private.SerializeTable(data)
  local lines = {"{"}
  recurseStringify(data, 1, lines)
  tinsert(lines, "}")
  return table.concat(lines, "\n")
end

function Private.RefreshTooltipButtons()
  importButton:Disable()
  importButton.tooltipText = nil
  showCodeButton:Enable()
  if not pendingData.codes or #pendingData.codes == 0 then
    showCodeButton:Hide()
  else
    showCodeButton:Show()
  end
  urlEditBox:Enable()
  if pendingData.url then
    urlEditBox:Show()
    urlEditBox.text = pendingData.url
    urlEditBox:SetText(pendingData.url)
    urlEditBox:HighlightText(0, 0)
  else
    urlEditBox:Hide()
  end
  if InCombatLockdown() then
    importButton:SetText(L["In Combat"])
    importButton.tooltipText = L["Importing is disabled while in combat"]
    showCodeButton:Disable()
  elseif WeakAuras.IsImporting() then
    importButton:SetText(L["Import in progress"])
  elseif pendingData.newData then
    if pendingData.activeCategories then
      if pendingData.mode == 1 then
        for button in pairs(pendingData.activeCategories) do
          button.text:SetTextColor(.5, .5, .5)
        end
      else
        for button in pairs(pendingData.activeCategories) do
          button.text:SetTextColor(1, 0.82, 0)
        end
      end
    end
    if pendingData.mode == #radioButtons and pendingData.buttonsChecked == 0 then
      importButton:SetText(L["Choose a category"])
    else
      importButton:Enable()
      if pendingData.diffs then
        if pendingData.mode ~= 1 then
          importButton:SetText(L["Import as Update"])
        else
          importButton:SetText(L["Import as Copy"])
        end
      else
        if pendingData.mode == 1 then
          importButton:SetText(L["Import as Copy"])
        elseif #pendingData.newData > 0 then
          importButton:SetText(L["Import Group"])
        else
          importButton:SetText(L["Import"])
        end
      end
    end
  end
  local importWidth = importButton.Text:GetStringWidth()
  importButton:SetWidth(importWidth + 30)
end
buttonAnchor:SetScript("OnEvent", Private.RefreshTooltipButtons)

local function SetCheckButtonStates(radioButtonAnchor, activeCategories)
  if activeCategories then
    for i, button in ipairs(radioButtons) do
      button:Show()
      button:Enable()
      button:SetChecked(i == pendingData.mode)
      button:SetPoint("TOPLEFT", radioButtonAnchor, "TOPLEFT", 0, -20 * (i - .7))
    end
    local checkButtonAnchor = radioButtons[#radioButtons]
    local buttonsChecked, buttonsShown = 0, 0
    for i, button in ipairs(checkButtons) do
      if activeCategories[button] then
        button:Show()
        button:Enable()
        button:SetPoint("TOPLEFT", checkButtonAnchor, "TOPLEFT", 17, -27*(0.6 + buttonsShown))
        button:SetChecked(button.default)
        buttonsShown = buttonsShown + 1
        buttonsChecked = buttonsChecked + (button:GetChecked() and 1 or 0)
      else
        button:Hide()
        button:Disable()
      end
    end
    pendingData.buttonsChecked = buttonsChecked
  else
    for _, button in ipairs(radioButtons) do
      button:Hide()
      button:Disable()
    end
    for _, button in ipairs(checkButtons) do
      button:Disable()
      button:Hide()
    end
  end
end

function ShowTooltip(lines, linesFromTop, activeCategories)
  ItemRefTooltip:Show();
  if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
  end
  ItemRefTooltip:ClearLines();
  for i, line in ipairs(lines) do
    local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(line);
    if(sides == 1) then
      ItemRefTooltip:AddLine(a1, a2, a3, a4, a5);
    elseif(sides == 2) then
      ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8);
    end
  end
  ItemRefTooltip:Show()
  if pendingData.newData then
    local checkButtonAnchor = _G["ItemRefTooltipTextLeft" .. (linesFromTop or 1)]
    SetCheckButtonStates(checkButtonAnchor, activeCategories)
    Private.RefreshTooltipButtons()
    buttonAnchor:Show()
  else
    buttonAnchor:Hide()
  end
end

local function notEmptyString(str)
  return str and str ~= "" and string.find(str, "%S")
end

local function addCode(codes, text, code, ...)
  -- The 4th paramter is a "check" if the code is active
  -- The following line let's distinguish between addCode(a, b, c, nil) and addCode(a, b, c)
  if (select("#", ...) > 0) then
    if not select(1, ...) then
      return
    end
  end

  if code and notEmptyString(code) then
    local t = {};
    t.text = text;
    t.value = text
    t.code = code
    tinsert(codes, t);
  end
end

-- TODO: Should savedvariables data ever be refactored, then shunting the custom scripts
-- into their own special subtable will allow us to simplify the scam check significantly.
local function checkTrigger(codes, id, trigger, untrigger)
  if not trigger or trigger.type ~= "custom" then return end;

  addCode(codes, L["%s Trigger Function"]:format(id), trigger.custom)

  if trigger.custom_type == "stateupdate" then
    addCode(codes, L["%s Custom Variables"]:format(id), trigger.customVariables, trigger.custom_type == "stateupdate")
  else
    addCode(codes, L["%s Untrigger Function"]:format(id), untrigger and untrigger.custom)
    addCode(codes, L["%s Duration Function"]:format(id), trigger.customDuration)
    addCode(codes, L["%s Name Function"]:format(id), trigger.customName)
    addCode(codes, L["%s Icon Function"]:format(id), trigger.customIcon)
    addCode(codes, L["%s Texture Function"]:format(id),trigger.customTexture)
    addCode(codes, L["%s Stacks Function"]:format(id), trigger.customStacks)
    for i = 1, 7 do
      local property = "customOverlay" .. i;
      addCode(codes, L["%s Overlay Function"]:format(id), trigger[property])
    end
  end
end

local function checkAnimation(codes, id, a)
  if not a or a.type ~= "custom" then return end
  addCode(codes, L["%s - Alpha Animation"]:format(id), a.alphaFunc, a.alphaType == "custom" and a.use_alpha)
  addCode(codes, L["%s - Translate Animation"]:format(id), a.translateFunc, a.translateType == "custom" and a.use_translate)
  addCode(codes, L["%s - Scale Animation"]:format(id), a.scaleFunc, a.scaleType == "custom" and a.use_scale)
  addCode(codes, L["%s - Rotate Animation"]:format(id), a.rotateFunc, a.rotateType == "custom" and a.use_rotate)
  addCode(codes, L["%s - Color Animation"]:format(id), a.colorFunc, a.colorType == "custom" and a.use_color)
end

local function scamCheck(codes, data)
  for i, v in ipairs(data.triggers) do
    checkTrigger(codes, L["%s - %i. Trigger"]:format(data.id, i), v.trigger, v.untrigger);
  end

  addCode(codes,  L["%s - Trigger Logic"]:format(data.id), data.triggers.customTriggerLogic, data.triggers.disjunctive == "custom");
  addCode(codes, L["%s - Custom Text"]:format(data.id), data.customText)
  addCode(codes, L["%s - Custom Anchor"]:format(data.id), data.customAnchor, data.anchorFrameType == "CUSTOM")

  if (data.actions) then
    if data.actions.init then
      addCode(codes, L["%s - Init Action"]:format(data.id), data.actions.init.custom, data.actions.init.do_custom)
    end
    if data.actions.start then
      addCode(codes, L["%s - Start Action"]:format(data.id), data.actions.start.custom, data.actions.start.do_custom)
      addCode(codes, L["%s - Start Custom Text"]:format(data.id), data.actions.start.message_custom, data.actions.start.do_message)
    end
    if data.actions.finish then
      addCode(codes, L["%s - Finish Action"]:format(data.id), data.actions.finish.custom, data.actions.finish.do_custom)
      addCode(codes, L["%s - Finish Custom Text"]:format(data.id), data.actions.finish.message_custom, data.actions.finish.do_message)
    end
  end

  if (data.animation) then
    checkAnimation(codes, L["%s - Start"]:format(data.id), data.animation.start);
    checkAnimation(codes, L["%s - Main"]:format(data.id), data.animation.main);
    checkAnimation(codes, L["%s - Finish"]:format(data.id), data.animation.finish);
  end

  addCode(codes, L["%s - Custom Grow"]:format(data.id), data.customGrow, data.regionType == "dynamicgroup" and data.grow == "CUSTOM")
  addCode(codes, L["%s - Custom Sort"]:format(data.id), data.customSort, data.regionType == "dynamicgroup" and data.sort == "custom")
  addCode(codes, L["%s - Custom Anchor"]:format(data.id), data.customAnchorPerUnit,
          data.regionType == "dynamicgroup" and data.grow ~= "CUSTOM" and data.useAnchorPerUnit and data.anchorPerUnit == "CUSTOM")

  if (data.conditions) then
    for _, condition in ipairs(data.conditions) do
      if (condition and condition.changes) then
        for _, property in ipairs(condition.changes) do
          if ((property.property == "chat" or property.property == "customcode") and type(property.value) == "table" and property.value.custom) then
            addCode(codes, L["%s - Condition Custom Chat"]:format(data.id), property.value.custom);
          end
        end
      end
    end
  end
end

local ignoredForDiffChecking = CreateFromMixins(Private.internal_fields, Private.non_transmissable_fields)
local function recurseDiff(ours, theirs)
  local diff, seen, same = {}, {}, true
  for key, ourVal in pairs(ours) do
    if not ignoredForDiffChecking[key] then
      seen[key] = true
      local theirVal = theirs[key]
      if type(ourVal) == "table" and type(theirVal) == "table" then
        local diffVal = recurseDiff(ourVal, theirVal)
        if diffVal then
          diff[key] = diffVal
          same = false
        end
      elseif ourVal ~= theirVal and -- of course, floating points can be nonequal by less than we could possibly care
      not(type(ourVal) == "number" and type(theirVal) == "number" and math.abs(ourVal - theirVal) < 1e-6) then
        if (theirVal == nil) then
          diff[key] = deleted
        else
          diff[key] = theirVal;
        end
        same = false
      end
    end
  end
  for key, theirVal in pairs(theirs) do
    if not seen[key] and not ignoredForDiffChecking[key] then
      diff[key] = theirVal
      same = false
    end
  end
  if not same then return diff end
end

-- for debug purposes
local function recurseSerial(lines, depth, chunk)
  for k, v in pairs(chunk) do
    if v == deleted then
      tinsert(lines, string.rep("  ", depth) .. "|cFFFF0000" .. k .. " -> deleted|r")
    elseif type(v) == "table" then
      tinsert(lines, string.rep("  ", depth) .. k .. " -> {")
      recurseSerial(lines, depth + 1, v)
      tinsert(lines, string.rep("  ", depth) .. "}")
    else
      tinsert(lines, string.rep("  ", depth) .. k .. " -> " .. tostring(v))
    end
  end
end

local function diff(ours, theirs)
  -- generates a diff which WeakAuras.Update can use
  local debug = false
  if not ours or not theirs then return end
  local diff = recurseDiff(ours, theirs)
  if diff then
    if debug then
      local lines = {
        "==========================",
        "Diff detected: ",
        "ours: " .. (ours.id or "unknown") .. "," .. tostring(ours.uid),
        "theirs: " .. (theirs.id or "unknown") .. "," .. tostring(theirs.uid),
        "{",
      }
      recurseSerial(lines, 1, diff)
      tinsert(lines, "}")
      tinsert(lines, "==========================")
      print(table.concat(lines, "\n"))
    end
    return diff
  end
end

local function findMatch(data, children)
  local function isParentMatch(old, new)
    if old.parent then return end
    if old.uid and new.uid then
      if old.uid ~= new.uid then
        return
      else
        if (children == nil) ~= (old.controlledChildren == nil) then
          return
        end
        return true
      end
    else
      if children then
        if not old.controlledChildren then return end
        return old.id == new.id
      else
        if old.controlledChildren then return end
        return old.id == new.id
      end
    end
  end
  local oldParent = WeakAuras.GetData(data.id)
  if oldParent and not isParentMatch(oldParent, data) then
    oldParent = nil
  end
  if not oldParent or not isParentMatch(oldParent, data) then
    oldParent = nil
    if data.uid then
      for id, existingData in pairs(WeakAurasSaved.displays) do
        if isParentMatch(existingData, data) then
          oldParent = existingData
          break
        end
      end
    else
      return nil
    end
  end
  return oldParent
end

local function MatchInfo(data, children, oldParent)
  if oldParent then
    -- Either both have children, or both don't have
    if type(children) ~= type(oldParent.controlledChildren) then
      return nil
    end
  else
    -- match the parent/single aura (if no children)
    oldParent = findMatch(data, children)
  end

  if not oldParent then
    return nil
  end


  -- setup
  local info = {
    mode = 1,
    unmodified = 0,
    modified = 0,
    added = 0,
    deleted = 0,
    oldData = {},
    newData = {},
    indexMap = {
      oldToNew = {},
      newToOld = {},
    },
    diffs = {},
    activeCategories = {},
  }

  info.oldData[0] = oldParent
  if info.oldData[0].preferToUpdate then
    info.mode = 2
  end
  info.newData[0] = data
  info.diffs[0] = diff(oldParent, data)
  if info.diffs[0] then
    info.modified = info.modified + 1
  end
  local hybridTables
  if oldParent.sortHybridTable or data.sortHybridTable then
    hybridTables = {
      old = {},
      new = {},
    }
    if oldParent.sortHybridTable then
      for id, isHybrid in pairs(oldParent.sortHybridTable) do
        hybridTables.old[id] = isHybrid
      end
    end
    if data.sortHybridTable then
      for id, isHybrid in pairs(data.sortHybridTable) do
        hybridTables.new[id] = isHybrid
      end
    end
  end

  if children then
    -- setup
    info.deleted = #oldParent.controlledChildren
    info.added = #children
    local UIDtoID, IDtoIndex = {}, {}
    for index, oldChildID in ipairs(oldParent.controlledChildren) do
      local oldChild = WeakAuras.GetData(oldChildID)
      info.oldData[index] = oldChild
      IDtoIndex[oldChildID] = index
      if oldChild.uid and not UIDtoID[oldChild.uid] then
        UIDtoID[oldChild.uid] = oldChildID
      end
    end

    -- confirm uid matches, find tentative matches
    local tentativeMatches = {}
    for newIndex, newChild in ipairs(children) do
      info.newData[newIndex] = newChild
      local oldIndex = IDtoIndex[newChild.id]
      local matchedID = newChild.uid and UIDtoID[newChild.uid]
      if matchedID then
        oldIndex = IDtoIndex[matchedID]
        info.indexMap.oldToNew[oldIndex] = newIndex
        info.indexMap.newToOld[newIndex] = oldIndex
        info.deleted = info.deleted - 1
        info.added = info.added - 1
        if hybridTables then
          if (hybridTables.new[newChild.id] and not hybridTables.old[matchedID])
          or (not hybridTables.new[newChild.id] and hybridTables.old[matchedID]) then
            info.activeCategories[checkButtons.arrangement] = true
            hybridTables = nil
          else
            hybridTables.new[newChild.id] = nil
            hybridTables.old[matchedID] = nil
          end
        end
        UIDtoID[newChild.uid] = nil
        tentativeMatches[oldIndex] = nil
      elseif oldIndex then
        tentativeMatches[oldIndex] = newIndex
      end
    end

    -- confirm remaining tentative matches
    for oldIndex, newIndex in pairs(tentativeMatches) do
      local newChild, oldChild = info.newData[newIndex], info.oldData[oldIndex]
      if not newChild.uid or not oldChild.uid or newChild.uid == oldChild.uid then
        if hybridTables then
          if (hybridTables.new[newChild.id] and not hybridTables.old[oldChild.id])
          or (not hybridTables.new[newChild.id] and hybridTables.old[oldChild.id]) then
            info.activeCategories[checkButtons.arrangement] = true
            hybridTables = nil
          else
            hybridTables.new[newChild.id] = nil
            hybridTables.old[oldChild.id] = nil
          end
        end
        info.indexMap.oldToNew[oldIndex] = newIndex
        info.indexMap.newToOld[newIndex] = oldIndex
        info.deleted = info.deleted - 1
        info.added = info.added - 1
      end
    end

    if hybridTables then
      if next(hybridTables.new) ~= nil or next(hybridTables.old) ~= nil then
        info.activeCategories[checkButtons.arrangement] = true
      end
    end
    -- detect order mismatch and find diffs
    local lastMatch = 0
    for newIndex, newChild in ipairs(info.newData) do
      local oldIndex = info.indexMap.newToOld[newIndex]
      if oldIndex then
        local oldChild = info.oldData[oldIndex]
        if lastMatch and lastMatch > oldIndex then
          lastMatch = nil
          info.activeCategories[checkButtons.arrangement] = true
        else
          lastMatch = oldIndex
        end
        local childDiff = diff(oldChild, newChild, true)
        if childDiff then
          info.modified = info.modified + 1
          info.diffs[newIndex] = childDiff
        end
      end
    end
  end

  if info.added ~= 0 then
    info.activeCategories[checkButtons.newchildren] = true
  end

  if info.deleted ~= 0 then
    info.activeCategories[checkButtons.oldchildren] = true
  end

  if info.modified ~= 0 then
    for i, diff in pairs(info.diffs) do
      for key in pairs(diff) do
        local button = keyToButton[key]
        if button then
          if i > 0 and button == checkButtons.anchor then
            button = checkButtons.arrangement
          end
          info.activeCategories[button] = true
        end
      end
    end
  end

  local modified = next(info.activeCategories) ~= nil
  return modified and info or false
end

local function ShowDisplayTooltip(data, children, matchInfo, icon, icons, import, compressed)
  -- since we have new data, wipe the old pending data
  wipe(pendingData)

  local regionType = data.regionType;
  local regionData = regionOptions[regionType or ""]
  local displayName = regionData and regionData.displayName or regionType or "";

  local tooltip = {
    {2, data.id, "          ", 0.5333, 0, 1},
    {2, displayName, "          ", 1, 0.82, 0},
    {1, " ", 1, 1, 1}
  };

  pendingData.codes = {};
  local highestVersion = data.internalVersion or 1;
  local hasDescription = data.desc and data.desc ~= "";
  local hasUrl = data.url and data.url ~= "";
  pendingData.url = hasUrl and data.url
  local hasVersion = (data.semver and data.semver ~= "") or (data.version and data.version ~= "");
  local tocversion = data.tocversion;

  if hasDescription or hasUrl or hasVersion then
    tinsert(tooltip, {1, " "});
  end

  if hasUrl then
    tinsert(tooltip, {1, " "});
  end

  if hasDescription then
    tinsert(tooltip, {1, "\""..data.desc.."\"", 1, 0.82, 0, 1});
  end

  if hasVersion then
    tinsert(tooltip, {1, L["Version: "] .. (data.semver or data.version), 1, 0.82, 0, 1});
  end

  -- WeakAuras.GetData needs to be replaced temporarily so that when the subsequent code constructs the thumbnail for
  -- the tooltip, it will look to the incoming transmission data for child data. This allows thumbnails of incoming
  -- groups to be constructed properly.
  local RegularGetData = WeakAuras.GetData
  if children then
    WeakAuras.GetData = function(id)
      if(children) then
        for index, childData in pairs(children) do
          if(childData.id == id) then
            return childData;
          end
        end
      end
    end
  end

  local linesFromTop
  if import then
    -- import description
    pendingData.newData = {[0] = data}
    if children then
      for index,child in ipairs(children) do
        pendingData.newData[index] = child
      end
    end
    --TODO: only scamCheck codes that have actually changed
    for i = 0, #pendingData.newData do
      scamCheck(pendingData.codes, pendingData.newData[i])
    end
    if matchInfo ~= nil then
      -- we know of at least one match
      tinsert(tooltip, {1, " "})
      if type(matchInfo) ~= "table" then
        -- there is no difference whatsoever
        tinsert(tooltip, {1, L["You already have this group/aura. Importing will create a duplicate."], 1, 0.82, 0,})
      else
        -- load pendingData
        for k,v in pairs(matchInfo) do
          pendingData[k] = v
        end
        -- tally up changes
        if children and #children > 0 then
          tinsert(tooltip, {1, L["This is a modified version of your group, |cff9900FF%s.|r"]:format(pendingData.oldData[0].id), 1, 0.82, 0,})
          tinsert(tooltip, {1, " "})
          if matchInfo.added ~= 0 then
            tinsert(tooltip, {1, L["   • %d auras added"]:format(matchInfo.added), 1, 0.82, 0})
          end
          if matchInfo.modified ~= 0 then
            tinsert(tooltip, {1, L["   • %d auras modified"]:format(matchInfo.modified), 1, 0.82, 0})
          end
          if matchInfo.deleted ~= 0 then
            tinsert(tooltip, {1, L["   • %d auras deleted"]:format(matchInfo.deleted), 1, 0.82, 0})
          end
          tinsert(tooltip, {1, " "})
          tinsert(tooltip, {1, L["What do you want to do?"], 1, 0.82, 0})
          tinsert(tooltip, {1, " "})
        else
          local oldID = type(matchInfo.oldData[0]) == "table" and matchInfo.oldData[0].id or "unknown"
          tinsert(tooltip, {1, L["This is a modified version of your aura, |cff9900FF%s.|r"]:format(pendingData.oldData[0].id), 1, 0.82, 0})
          tinsert(tooltip, {1, L["What do you want to do?"], 1, 0.82, 0})
          tinsert(tooltip, {1, " "})
        end
        linesFromTop = #tooltip
        for _ in ipairs(radioButtons) do
          tinsert(tooltip, {1, " "})
        end
        for _, button in ipairs(checkButtons) do
          if pendingData.activeCategories[button] then
            tinsert(tooltip, {1, " "})
            tinsert(tooltip, {1, " "})
          end
        end
      end
    else
      if not children and (not data.controlledChildren or #data.controlledChildren == 0) then
        tinsert(tooltip, {1, L["No Children"], 1, 1, 1})
        for triggernum = 1, min(#data.triggers, 10) do
          local trigger = data.triggers[triggernum].trigger
          if(trigger) then
            if(trigger.type == "aura") then
              for index, name in pairs(trigger.names) do
                local left = " ";
                if(index == 1) then
                  if(#trigger.names > 0) then
                    if(#trigger.names > 1) then
                      left = L["Auras:"];
                    else
                      left = L["Aura:"];
                    end
                  end
                end
                if (icons) then
                  tinsert(tooltip, {2, left, name..(icons[name] and (" |T"..icons[name]..":12:12:0:0:64:64:4:60:4:60|t") or ""), 1, 1, 1, 1, 1, 1});
                else
                  local icon = WeakAuras.spellCache and WeakAuras.spellCache.GetIcon(name) or "Interface\\Icons\\INV_Misc_QuestionMark";
                  tinsert(tooltip, {2, left, name.." |T"..icon..":12:12:0:0:64:64:4:60:4:60|t", 1, 1, 1, 1, 1, 1});
                end
              end
            elseif(trigger.type == "aura2") then
              tinsert(tooltip, {2, L["Trigger:"], L["Aura"], 1, 1, 1, 1, 1, 1});
            elseif(Private.category_event_prototype[trigger.type]) then
              tinsert(tooltip, {2, L["Trigger:"], (Private.event_prototypes[trigger.event].name or L["Undefined"]), 1, 1, 1, 1, 1, 1});
              if(trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix) then
                tinsert(tooltip, {2, L["Message type:"], (Private.subevent_prefix_types[trigger.subeventPrefix] or L["Undefined"]).." "..(Private.subevent_suffix_types[trigger.subeventSuffix] or L["Undefined"]), 1, 1, 1, 1, 1, 1});
              end
            else
              tinsert(tooltip, {2, L["Trigger:"], L["Custom"], 1, 1, 1, 1, 1, 1});
            end
          end
        end
      else
        tinsert(tooltip, {1, L["Children:"], 1, 1, 1})
        local excessChildren = -30
        for _, child in pairs(children or data.controlledChildren) do
          excessChildren = excessChildren + 1
          if children then
            highestVersion = max(highestVersion, child.internalVersion or 1)
          end
          if excessChildren <= 0 then
            tinsert(tooltip, {2, " ", child.id, 1, 1, 1, 1, 1, 1})
          end
          tocversion = tocversion or child.tocversion
        end
        if excessChildren > 0 then
          tinsert(tooltip, {2, " ", "[...]", 1, 1, 1, 1, 1, 1})
          tinsert(tooltip, {1, L["%s total auras"]:format(excessChildren + 30), "", 1, 1, 1, 1})
        end
      end
    end

    tinsert(tooltip, {1, " "})
    if(type(import) == "string" and import ~= "unknown") then
      tinsert(tooltip, {2, L["From"]..": "..import, "                         ", 0, 1, 0})
    end

    if #pendingData.codes > 0 then
      tinsert(tooltip, {1, L["This aura contains custom Lua code."], 1, 0, 0})
      tinsert(tooltip, {1, L["Make sure you can trust the person who sent it!"], 1, 0, 0})
    end

    if (highestVersion > WeakAuras.InternalVersion()) then
      tinsert(tooltip, {1, L["This aura was created with a newer version of WeakAuras."], 1, 0, 0})
      tinsert(tooltip, {1, L["It might not work correctly with your version!"], 1, 0, 0})
    end

    if WeakAuras.IsClassic() and (not tocversion or tocversion > 20000) then
      tinsert(tooltip, {1, L["This aura was created with the retail version of World of Warcraft."], 1, 0, 0})
      tinsert(tooltip, {1, L["It might not work correctly on Classic!"], 1, 0, 0})
    elseif tocversion and not WeakAuras.IsClassic() and tocversion < 20000 then
      tinsert(tooltip, {1, L["This aura was created with the Classic version of World of Warcraft."], 1, 0, 0})
      tinsert(tooltip, {1, L["It might not work correctly on Retail!"], 1, 0, 0})
    end

    tinsert(tooltip, {2, " ", "                         ", 0, 1, 0})
    tinsert(tooltip, {2, " ", "                         ", 0, 1, 0})

  end

  if not IsAddOnLoaded('WeakAurasOptions') then
    LoadAddOn('WeakAurasOptions')
  end
  if thumbnailAnchor.currentThumbnail then
    regionOptions[thumbnailAnchor.currentThumbnailType].releaseThumbnail(thumbnailAnchor.currentThumbnail)
    thumbnailAnchor.currentThumbnail = nil
  end
  if regionOptions[regionType] then
    local ok, thumbnail = pcall(regionOptions[regionType].acquireThumbnail, thumbnailAnchor, data);
    if not ok then
      error(string.format("Error creating thumbnail for %s %s", regionType, thumbnail), 2)
    end
    thumbnailAnchor.currentThumbnail = thumbnail
    thumbnailAnchor.currentThumbnailType = regionType
    thumbnail:SetAllPoints(thumbnailAnchor);
    thumbnail:SetParent(thumbnailAnchor)
    if (thumbnail.SetIcon) then
      local i;
      if(icon) then
        i = icon;
      end
      if (i) then
        thumbnail:SetIcon(i);
      else
        thumbnail:SetIcon();
      end
    end
  end
  WeakAuras.GetData = RegularGetData or WeakAuras.GetData
  ShowTooltip(tooltip, linesFromTop, matchInfo and matchInfo.activeCategories)
end

function WeakAuras.Import(inData, target)
  local data, children, icon, icons, version
  if type(inData) == 'string' then
    -- encoded data
    local received = StringToTable(inData, true)
    if type(received) == 'string' then
      -- this is probably an error message from LibDeflate. Display it.
      ShowTooltip{
        {1, "WeakAuras", 0.5333, 0, 1},
        {1, received, 1, 0, 0, 1}
      }
      return nil, received
    elseif received.m == "d" then
      data = received.d
      children = received.c
      icon = received.i
      icons = received.a
      version = received.v
    end
  elseif type(inData.d) == 'table' then
    data = inData.d
    children = inData.c
    icon = inData.i
    icons = inData.a
    version = inData.v
  end
  if type(data) ~= "table" then
    return nil, "Invalid import data."
  end
  if version > 1999 then
    ShowTooltip{
      {1, "WeakAuras", 0.5333, 0, 1},
      {1, L["This import requires a newer WeakAuras version."], 1, 0, 0, 1}
    }
    return nil, "Invalid import data. This import requires a newer WeakAuras version."
  end

  local status, msg = true, ""
  if type(target) ~= 'nil' then
    local targetData
    local uid = type(target) == 'table' and target.uid or target
    if type(uid) == 'string' then
      for _, installedData in pairs(WeakAurasSaved.displays) do
        if installedData.uid == uid then
          targetData = installedData
          break
        end
      end
    end
    if not targetData then
      status = false
      msg = "Invalid update target. Importing as an unknown payload."
      target = nil
    else
      target = targetData
    end
  end
  WeakAuras.PreAdd(data)
  if children then
    for _, child in ipairs(children) do
      WeakAuras.PreAdd(child)
    end
  end
  tooltipLoading = nil;
  local matchInfo = MatchInfo(data, children, target)
  if matchInfo == nil and target then
    return false, "Import data did not match to target"
  end
  ShowDisplayTooltip(data, children, matchInfo, icon, icons, "unknown")
  return status, msg
end

-- backwards compatibility
WeakAuras.ImportString = WeakAuras.Import

local function crossRealmSendCommMessage(prefix, text, target, queueName, callbackFn, callbackArg)
  local chattype = "WHISPER"
  if target and not UnitIsSameServer(target) then
    if UnitInRaid(target) then
      chattype = "RAID"
      text = ("§§%s:%s"):format(target, text)
    elseif UnitInParty(target) then
      chattype = "PARTY"
      text = ("§§%s:%s"):format(target, text)
    end
  end
  Comm:SendCommMessage(prefix, text, chattype, target, queueName, callbackFn, callbackArg)
end

local safeSenders = {}
function RequestDisplay(characterName, displayName)
  safeSenders[characterName] = true
  safeSenders[Ambiguate(characterName, "none")] = true
  local transmit = {
    m = "dR",
    d = displayName
  };
  local transmitString = TableToString(transmit);
  crossRealmSendCommMessage("WeakAuras", transmitString, characterName);
end

function TransmitError(errorMsg, characterName)
  local transmit = {
    m = "dE",
    eM = errorMsg
  };
  crossRealmSendCommMessage("WeakAuras", TableToString(transmit), characterName);
end

function TransmitDisplay(id, characterName)
  local encoded = Private.DisplayToString(id);
  if(encoded ~= "") then
    crossRealmSendCommMessage("WeakAuras", encoded, characterName, "BULK", function(displayName, done, total)
      crossRealmSendCommMessage("WeakAurasProg", done.." "..total.." "..displayName, characterName, "ALERT");
    end, id);
  else
    TransmitError("dne", characterName);
  end
end

Comm:RegisterComm("WeakAurasProg", function(prefix, message, distribution, sender)
  if distribution == "PARTY" or distribution == "RAID" then
    local dest, msg = string.match(message, "^§§(.+):(.+)$")
    if dest then
      local dName, dServer = string.match(dest, "^(.*)-(.*)$")
      local myName, myServer = UnitFullName("player")
      if myName == dName and myServer == dServer then
        message = msg
      else
        return
      end
    end
  end
  if tooltipLoading and ItemRefTooltip:IsVisible() and safeSenders[sender] then
    receivedData = true;
    local done, total, displayName = strsplit(" ", message, 3)
    done = tonumber(done)
    total = tonumber(total)
    if(done and total and total >= done) then
      local red = min(255, (1 - done / total) * 511)
      local green = min(255, (done / total) * 511)
      ShowTooltip({
        {2, "WeakAuras", displayName, 0.5, 0, 1, 1, 1, 1},
        {1, L["Receiving display information"]:format(sender), 1, 0.82, 0},
        {2, " ", ("|cFF%2x%2x00"):format(red, green)..done.."|cFF00FF00/"..total}
      })
    end
  end
end)

Comm:RegisterComm("WeakAuras", function(prefix, message, distribution, sender)
  if distribution == "PARTY" or distribution == "RAID" then
    local dest, msg = string.match(message, "^§§([^:]+):(.+)$")
    if dest then
      local dName, dServer = string.match(dest, "^(.*)-(.*)$")
      local myName, myServer = UnitFullName("player")
      if myName == dName and myServer == dServer then
        message = msg
      else
        return
      end
    end
  end
  local received = StringToTable(message);
  if(received and type(received) == "table" and received.m) then
    if(received.m == "d") and safeSenders[sender] then
      tooltipLoading = nil;
      local data, children, icon, icons = received.d, received.c, received.i, received.a
      WeakAuras.PreAdd(data)
      if children then
        for _, child in ipairs(children) do
          WeakAuras.PreAdd(child)
        end
      end
      local matchInfo = MatchInfo(data, children)
      ShowDisplayTooltip(data, children, matchInfo, icon, icons, sender, true)
    elseif(received.m == "dR") then
      if(Private.linked and Private.linked[received.d]) then
        TransmitDisplay(received.d, sender);
      end
    elseif(received.m == "dE") then
      tooltipLoading = nil;
      if(received.eM == "dne") then
        ShowTooltip({
          {1, "WeakAuras", 0.5333, 0, 1},
          {1, L["Requested display does not exist"], 1, 0, 0}
        });
      elseif(received.eM == "na") then
        ShowTooltip({
          {1, "WeakAuras", 0.5333, 0, 1},
          {1, L["Requested display not authorized"], 1, 0, 0}
        });
      end
    end
  elseif(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail and ItemRefTooltip.WeakAuras_Tooltip_Thumbnail:IsVisible()) then
    ShowTooltip({
      {1, "WeakAuras", 0.5333, 0, 1},
      {1, L["Transmission error"], 1, 0, 0}
    });
  end
end);
