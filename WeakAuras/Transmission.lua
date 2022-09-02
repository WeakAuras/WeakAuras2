--[[ Transmisson.lua
This file contains all transmission related functionality, e.g. import/export and chat links.
For that it hooks into the chat frame and addon message channels.

Noteable functions in this file are:

DisplayToString(id, forChat)
Converts the display id to a plain text string

DataToString(id)
Converts the display id to a formatted table

SerializeTable(data)
Converts the table data to a formatted table

Import(str, [target])
Imports an aura from a table, which may or may not be encoded as a B64 string.
If target is installed data, or is a uid which points to installed data, then the import will be an update to that aura

]]--
if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

-- Lua APIs
local tinsert = table.insert
local tostring, string_char, strsplit = tostring, string.char, strsplit
local pairs, type, unpack = pairs, type, unpack
local error = error
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local versionString = WeakAuras.versionString;

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

function CompressDisplay(data, version)
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
  local non_transmissable_fields = version >= 2000 and Private.non_transmissable_fields_v2000 or Private.non_transmissable_fields
  stripNonTransmissableFields(copiedData, non_transmissable_fields)
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
    local start, finish, characterName, displayName = remaining:find("%[WeakAuras: ([^%s]+) %- (.*)%]");
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
  if(link == "garrmission:weakauras") then
    local _, _, characterName, displayName = text:find("|Hgarrmission:weakauras|h|cFF8800FF%[([^%s]+) |r|cFF8800FF%- (.*)%]|h");
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
    -- Check which transmission version we want to use
    local version = 1421
    for child in Private.TraverseSubGroups(data) do -- luacheck: ignore
      version = 2000
      break;
    end
    local transmitData = CompressDisplay(data, version);
    local transmit = {
      m = "d",
      d = transmitData,
      v = version,
      s = versionString
    };
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
        transmit.c[index] = CompressDisplay(child, version);
        index = index + 1
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

function ShowTooltip(lines)
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
end

local delayedImport = CreateFrame("Frame")

local function ImportNow(data, children, target, sender, callbackFunc)
  if InCombatLockdown() then
    WeakAuras.prettyPrint(L["Importing will start after combat ends."])

    delayedImport:RegisterEvent("PLAYER_REGEN_ENABLED")
    delayedImport:SetScript("OnEvent", function()
      delayedImport:UnregisterEvent("PLAYER_REGEN_ENABLED")
      ImportNow(data, children, target, sender, callbackFunc)
    end)
    return
  end

  if Private.LoadOptions() then
    if not WeakAuras.IsOptionsOpen() then
      WeakAuras.OpenOptions()
    end
    Private.OpenUpdate(data, children, target, sender, callbackFunc)
  end
end

function WeakAuras.Import(inData, target, callbackFunc)
  local data, children, version
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
      version = received.v
    end
  elseif type(inData.d) == 'table' then
    data = inData.d
    children = inData.c
    version = inData.v
  end
  if type(data) ~= "table" then
    return nil, "Invalid import data."
  end

  if version < 2000 then
    if children then
      data.controlledChildren = {}
      for i, child in ipairs(children) do
        tinsert(data.controlledChildren, child.id)
        child.parent = data.id
      end
    end
  end

  local status, msg = true, ""
  if type(target) ~= 'nil' then
    local uid = type(target) == 'table' and target.uid or target
    local targetData = Private.GetDataByUID(uid)
    if not targetData then
      return false, "Invalid update target."
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
  return ImportNow(data, children, target, nil, callbackFunc)
end

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

  local linkValidityDuration = 60 * 5
  local safeSender = safeSenders[sender]
  local validLink = false
  if Private.linked then
    local expiredLinkTime = GetTime() - linkValidityDuration
    for id, time in pairs(Private.linked) do
      if time > expiredLinkTime then
        validLink = true
      end
    end
  end
  if not safeSender and not validLink then
    return
  end

  local received = StringToTable(message);
  if(received and type(received) == "table" and received.m) then
    if(received.m == "d") then
      tooltipLoading = nil;
      local data, children, version = received.d, received.c, received.v
      WeakAuras.PreAdd(data)
      if children then
        for _, child in ipairs(children) do
          WeakAuras.PreAdd(child)
        end
      end
      if version < 2000 then
        if children then
          data.controlledChildren = {}
          for i, child in ipairs(children) do
            tinsert(data.controlledChildren, child.id)
            child.parent = data.id
          end
        end
      end

      ItemRefTooltip:Hide()
      ImportNow(data, children, nil, sender)
    elseif(received.m == "dR") then
      if(Private.linked and Private.linked[received.d] and Private.linked[received.d] > GetTime() - linkValidityDuration) then
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
