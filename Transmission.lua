--[[ Transmisson.lua
This file contains all transmission related functionality, e.g. import/export and chat links.
For that it hooks into the chat frame and addon message channels.

This file adds the following API to the WeakAuras object:

DisplayToString(id, forChat)
    Converts the display id to a plain text string

DisplayToTableString(id)
    Converts the display id to a formatted table

ShowDisplayTooltip(data, children, icon, icons, import, compressed, alterdesc)
    Shows a tooltip frame for an aura, which allows for importing if import is true

ImportString(str)
    Imports an aura from a string

]]--

-- Lua APIs
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local fmt, tostring, string_char, strsplit = string.format, tostring, string.char, strsplit
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift
local coroutine = coroutine

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local version = 1421;
local versionString = WeakAuras.versionString;

local regionOptions = WeakAuras.regionOptions;
local regionTypes = WeakAuras.regionTypes;
local event_types = WeakAuras.event_types;
local status_types = WeakAuras.status_types;

-- local functions
local encodeB64, decodeB64, tableAdd, tableSubtract, DisplayStub, removeSpellNames
local CompressDisplay, DecompressDisplay, ShowTooltip, TableToString, StringToTable
local RequestDisplay, TransmitError, TransmitDisplay

-- GLOBALS: WeakAurasOptionsSaved WeakAurasSaved UIParent BNGetNumFriendGameAccounts BNGetFriendGameAccountInfo

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
local encodeB64Table = {};

function encodeB64(str)
  local B64 = encodeB64Table;
  local remainder = 0;
  local remainder_length = 0;
  local encoded_size = 0;
  local l=#str
  local code
  for i=1,l do
    code = string.byte(str, i);
    remainder = remainder + bit_lshift(code, remainder_length);
    remainder_length = remainder_length + 8;
    while(remainder_length) >= 6 do
      encoded_size = encoded_size + 1;
      B64[encoded_size] = bytetoB64[bit_band(remainder, 63)];
      remainder = bit_rshift(remainder, 6);
      remainder_length = remainder_length - 6;
    end
  end
  if remainder_length > 0 then
    encoded_size = encoded_size + 1;
    B64[encoded_size] = bytetoB64[remainder];
  end
  return table.concat(B64, "", 1, encoded_size)
end

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

function tableAdd(augend, addend)
  local function recurse(augend, addend)
    for i,v in pairs(addend) do
      if(type(v) == "table") then
        augend[i] = augend[i] or {};
        recurse(augend[i], addend[i]);
      else
        if(augend[i] == nil) then
          augend[i] = v;
        end
      end
    end
  end
  recurse(augend, addend);
end

function tableSubtract(minuend, subtrahend)
  local function recurse(minuend, subtrahend)
    for i,v in pairs(subtrahend) do
      if(minuend[i] ~= nil) then
        if(type(minuend[i]) == "table" and type(v) == "table") then
          if(recurse(minuend[i], v)) then
            minuend[i] = nil;
          end
        else
          if(minuend[i] == v) then
            minuend[i] = nil;
          end
        end
      end
    end
    local num = 0;
    for i,v in pairs(minuend) do
      num = num + 1;
    end
    return num == 0;
  end
  recurse(minuend, subtrahend);
end

function DisplayStub(regionType)
  local stub = {
    ["untrigger"] = {
    },
    ["animation"] = {
      ["start"] = {
        ["duration_type"] = "seconds",
        ["type"] = "none"
      },
      ["main"] = {
        ["duration_type"] = "seconds",
        ["type"] = "none"
      },
      ["finish"] = {
        ["duration_type"] = "seconds",
        ["type"] = "none"
      }
    },
    ["trigger"] = {
      ["type"] = "aura",
      ["subeventPrefix"] = "SPELL",
      ["subeventSuffix"] = "_CAST_START",
      ["debuffType"] = "HELPFUL",
      ["names"] = {},
      ["spellIds"] = {},
      ["event"] = "Health",
      ["unit"] = "player"
    },
    ["actions"] = {
      ["init"] = {
      },
      ["start"] = {
      },
      ["finish"] = {
      }
    },
    ["conditions"] = {
    },
    ["load"] = {
      ["class"] = {
        ["multi"] = {
        }
      },
      ["spec"] = {
        ["multi"] = {
        }
      },
      ["size"] = {
        ["multi"] = {
        }
      }
    }
  }

  WeakAuras.validate(stub, regionTypes[regionType].default);
  return stub;
end

function CompressDisplay(data)
  local copiedData = {};
  WeakAuras.DeepCopy(data, copiedData);
  copiedData.controlledChildren = nil;
  copiedData.parent = nil;
  tableSubtract(copiedData, DisplayStub(copiedData.regionType));
  return copiedData;
end

function DecompressDisplay(data)
  tableAdd(data, DisplayStub(data.regionType));
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
      newMsg = newMsg.."|Hweakauras|h|cFF8800FF["..characterName.." |r|cFF8800FF- "..displayName.."]|h|r";
      remaining = remaining:sub(finish + 1);
    else
      done = true;
    end
  until(done)
  if newMsg ~= "" then
    local trimmedPlayer = Ambiguate(player, "none")
    if event == "CHAT_MSG_WHISPER" and not UnitInRaid(trimmedPlayer) and not UnitInParty(trimmedPlayer) then -- XXX Need a guild check
      local _, num = BNGetNumFriends()
      for i=1, num do
        local toon = BNGetNumFriendGameAccounts(i)
        for j=1, toon do
          local _, rName, rGame = BNGetFriendGameAccountInfo(i, j)
          if rName == trimmedPlayer and rGame == "WoW" then
            return false, newMsg, player, l, cs, t, flag, channelId, ...; -- Player is a real id friend, allow it
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

function ShowTooltip(content)
  if(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail) then
    ItemRefTooltip.WeakAuras_Tooltip_Thumbnail:Hide();
    ItemRefTooltip.WeakAuras_Tooltip_Thumbnail = nil;
  end
  if(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame) then
    ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame:Hide();
  end
  if(ItemRefTooltip.WeakAuras_Tooltip_Button) then
    ItemRefTooltip.WeakAuras_Tooltip_Button:Hide();
  end
  if(ItemRefTooltip.WeakAuras_Tooltip_Button2) then
    ItemRefTooltip.WeakAuras_Tooltip_Button2:Hide();
  end
  if(ItemRefTooltip.WeakAuras_Desc_Box) then
    ItemRefTooltip.WeakAuras_Desc_Box:Hide();
  end
  ShowUIPanel(ItemRefTooltip);
  if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
  end
  ItemRefTooltip:ClearLines();
  for i,v in pairs(content) do
    local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(v);
    if(sides == 1) then
      ItemRefTooltip:AddLine(a1, a2, a3, a4, a5);
    elseif(sides == 2) then
      ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8);
    end
  end
  ItemRefTooltip:Show();
end

local Compresser = LibStub:GetLibrary("LibCompress");
local Encoder = Compresser:GetAddonEncodeTable()
local Serializer = LibStub:GetLibrary("AceSerializer-3.0");
local Comm = LibStub:GetLibrary("AceComm-3.0");

local tooltipLoading;

hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)
    if(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail) then
      ItemRefTooltip.WeakAuras_Tooltip_Thumbnail:Hide();
      ItemRefTooltip.WeakAuras_Tooltip_Thumbnail = nil;
    end
    if(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame) then
      ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame:Hide();
    end
    if(ItemRefTooltip.WeakAuras_Tooltip_Button) then
      ItemRefTooltip.WeakAuras_Tooltip_Button:Hide();
    end
    if(ItemRefTooltip.WeakAuras_Tooltip_Button2) then
      ItemRefTooltip.WeakAuras_Tooltip_Button2:Hide();
    end
    if(ItemRefTooltip.WeakAuras_Desc_Box) then
      ItemRefTooltip.WeakAuras_Desc_Box:Hide();
    end
    if(link == "weakauras") then
      local _, _, characterName, displayName = text:find("|Hweakauras|h|cFF8800FF%[([^%s]+) |r|cFF8800FF%- ([^%]]+)%]|h");
      if(characterName and displayName) then
        characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
        displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
        if(IsShiftKeyDown()) then
          local editbox = GetCurrentKeyBoardFocus();
          if(editbox) then
            editbox:Insert("[WeakAuras: "..characterName.." - "..displayName.."]");
          end
        else
          ShowTooltip({
              {2, "WeakAuras", displayName, 0.5, 0, 1, 1, 1, 1},
              {1, "Requesting display information from "..characterName.."...", 1, 0.82, 0}
            });
          tooltipLoading = true;
          RequestDisplay(characterName, displayName);
        end
      else
        ShowTooltip({
            {1, "WeakAuras", 0.5, 0, 1},
            {1, "Malformed WeakAuras link", 1, 0, 0}
          });
      end
    end
  end);

local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
  if(link and link:sub(0, 9) == "weakauras") then
    return;
  end
  return OriginalSetHyperlink(self, link, ...);
end

local OriginalHandleModifiedItemClick = HandleModifiedItemClick
function HandleModifiedItemClick(link, ...)
  if(link and link:find("|Hweakauras|h")) then
    return;
  end
  return OriginalHandleModifiedItemClick(link, ...);
end

function TableToString(inTable, forChat)
  local serialized = Serializer:Serialize(inTable);
  local compressed = Compresser:CompressHuffman(serialized);
  if(forChat) then
    return encodeB64(compressed);
  else
    return Encoder:Encode(compressed);
  end
end

function StringToTable(inString, fromChat)
  local decoded;
  if(fromChat) then
    decoded = decodeB64(inString);
  else
    decoded = Encoder:Decode(inString);
  end
  local decompressed, errorMsg = Compresser:Decompress(decoded);
  if not(decompressed) then
    return "Error decompressing: "..errorMsg;
  end
  local success, deserialized = Serializer:Deserialize(decompressed);
  if not(success) then
    return "Error deserializing "..deserialized;
  end
  return deserialized;
end

function WeakAuras.DisplayToString(id, forChat)
  local data = WeakAuras.GetData(id);
  local transmitData = CompressDisplay(data);
  transmitData.controlledChildren = nil;
  if(data) then
    local children = data.controlledChildren;
    local transmit = {
      m = "d",
      d = transmitData,
      v = version,
      s = versionString
    };
    if(WeakAuras.transmitCache and WeakAuras.transmitCache[id]) then
      transmit.i = WeakAuras.transmitCache[id];
    end
    if(data.trigger.type == "aura" and WeakAurasOptionsSaved and WeakAurasOptionsSaved.iconCache) then
      transmit.a = {};
      for i,v in pairs(data.trigger.names) do
        transmit.a[v] = WeakAurasOptionsSaved.iconCache[v];
      end
    end
    if(children) then
      transmit.c = {};
      for i,v in pairs(children) do
        local childData = WeakAuras.GetData(v);
        if(childData) then
          transmit.c[i] = CompressDisplay(childData);
        end
      end
    end
    return TableToString(transmit, forChat);
  else
    return "";
  end
end

function WeakAuras.DisplayToTableString(id)
  local ret = "{\n";
  local function recurse(table, level)
    for i,v in pairs(table) do
      ret = ret..strrep("    ", level).."[";
      if(type(i) == "string") then
        ret = ret.."\""..i.."\"";
      else
        ret = ret..i;
      end
      ret = ret.."] = ";

      if(type(v) == "number") then
        ret = ret..v..",\n"
      elseif(type(v) == "string") then
        ret = ret.."\""..v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"").."\",\n"
      elseif(type(v) == "boolean") then
        if(v) then
          ret = ret.."true,\n"
        else
          ret = ret.."false,\n"
        end
      elseif(type(v) == "table") then
        ret = ret.."{\n"
        recurse(v, level + 1);
        ret = ret..strrep("    ", level).."},\n"
      else
        ret = ret.."\""..tostring(v).."\",\n"
      end
    end
  end

  local data = WeakAuras.GetData(id)
  if(data) then
    recurse(data, 1);
  end
  ret = ret.."}";
  return ret;
end

local function checkTrigger(codes, id, trigger, untrigger)
  if (not trigger) then return end;
    local t = {};
    if (trigger.custom) then
      t.text = L["%s Trigger Function"]:format(id);
      t.value = t.text;
      t.code = trigger.custom;
      tinsert(codes, t);
    end

    if (untrigger and untrigger.custom) then
      t = {}
      t.text = L["%s Untrigger Function"]:format(id);
      t.value = t.text;
      t.code = untrigger.custom;
      tinsert(codes, t);
    end

    if (trigger.customDuration) then
      t = {}
      t.text = L["%s Duration Function"]:format(id);
      t.value = t.text;
      t.code = trigger.customDuration
      tinsert(codes, t);
    end

    if (trigger.customName) then
      t = {}
      t.text = L["%s Name Function"]:format(id);
      t.value = t.text;
      t.code = trigger.customName
      tinsert(codes, t);
    end

    if (trigger.customIcon) then
      t = {}
      t.text = L["%s Icon Function"]:format(id);
      t.value = t.text;
      t.code = trigger.customIcon
      tinsert(codes, t);
    end

    if (trigger.customTexture) then
      t = {}
      t.text = L["%s Texture Function"]:format(id);
      t.value = t.text;
      t.code = trigger.customTexture
      tinsert(codes, t);
    end

    if (trigger.customStacks) then
      t = {}
      t.text = L["%s Stacks Function"]:format(id);
      t.value = t.text;
      t.code = trigger.customStacks
      tinsert(codes, t);
    end
  end

  local function checkCustom(codes, id, base)
    if (not base) then return end
    if (base.custom) then
      local t = {};
      t.text = id;
      t.value = id;
      t.code = base.custom
      tinsert(codes, t);
    end
  end

  local function checkAnimation(codes, id, a)
    if (not a) then return end
    if (a.alphaType == "custom" and a.use_alpha and a.alphaFunc) then
      local t = {};
      t.text = L["%s - Alpha Animation"]:format(id);
      t.value = t.text;
      t.code = a.alphaFunc;
      tinsert(codes, t);
    end

    if (a.translateType == "custom" and a.use_translate and a.translateFunc) then
      local t = {};
      t.text = L["%s - Translate Animation"]:format(id);
      t.value = t.text;
      t.code = a.translateFunc;
      tinsert(codes, t);
    end

    if (a.scaleType == "custom" and a.use_scale and a.scaleFunc) then
      local t = {};
      t.text = L["%s - Scale Animation"]:format(id);
      t.value = t.text;
      t.code = a.scaleFunc;
      tinsert(codes, t);
    end

    if (a.rotateType == "custom" and a.use_rotate and a.rotateFunc) then
      local t = {};
      t.text = L["%s - Rotate Animation"]:format(id);
      t.value = t.text;
      t.code = a.rotateFunc;
      tinsert(codes, t);
    end

    if (a.colorType == "custom" and a.use_color and a.colorFunc) then
      local t = {};
      t.text = L["%s - Color Animation"]:format(id);
      t.value = t.text;
      t.code = a.colorFunc
      tinsert(codes, t);
    end
  end

  local function checkTriggerLogic(codes, id, logic)
    if (not logic) then return end
    local t = {};
    t.text = id;
    t.value = id;
    t.code = logic;
    tinsert(codes, t);
  end

  local function checkText(codes, id, customText)
    if (not customText) then return end
    local t = {};
    t.text = id;
    t.value = id;
    t.code = customText;
    tinsert(codes, t);
  end

  local function scamCheck(codes, data)
    local r
    checkTrigger(codes, L["%s - 1. Trigger"]:format(data.id), data.trigger, data.untrigger);
    if (data.additional_triggers) then
      for i, v in ipairs(data.additional_triggers) do
        checkTrigger(codes, L["%s - %i. Trigger"]:format(data.id, i+1), v.trigger, v.untrigger);
      end
    end

    if (data.actions) then
      r = checkCustom(codes, L["%s - Init Action"]:format(data.id), data.actions.init);
      r = checkCustom(codes, L["%s - Start Action"]:format(data.id), data.actions.start);
      r = checkCustom(codes, L["%s - Finish Action"]:format(data.id), data.actions.finish);
    end

    if (data.animation) then
      r = checkAnimation(codes, L["%s - Start"]:format(data.id), data.animation.start);
      r = checkAnimation(codes, L["%s - Main"]:format(data.id), data.animation.main);
      r = checkAnimation(codes, L["%s - Finish"]:format(data.id), data.animation.finish);
    end

    if(data.customTriggerLogic) then
      r = checkTriggerLogic(codes,  L["%s - Trigger Logic"]:format(data.id), data.customTriggerLogic);
    end

    if(data.customText) then
      r = checkText(codes, L["%s - Custom Text"]:format(data.id), data.customText);
    end
  end

  function WeakAuras.ShowDisplayTooltip(data, children, icon, icons, import, compressed, alterdesc)
    if(type(data) == "table") then
      if(compressed) then
        DecompressDisplay(data);
        data.controlledChildren = nil;
      end

      local regionType = data.regionType;
      local regionData = regionOptions[regionType or ""]
      local displayName = regionData and regionData.displayName or regionType or "";

      local tooltip = {
        -- 1. parameter: 1 => AddLine, 2=> AddDoubleLine,
        -- Rest of parameters identically to AddLine or AddDoubleLine:
        -- AddLine: text [, red, green, blue [, wrapText]]
        -- AddDoubleLine: textLeft, textRight, textLeft.r, textLeft.g, textLeft.b, textRight.r, textRight.g, textRight.b
        {2, data.id, "          ", 0.5333, 0, 1},
        {2, displayName, "          ", 1, 0.82, 0},
        {1, " ", 1, 1, 1}
      };

      local codes = {};
      scamCheck(codes, data);
      if(children) then
        for index, childData in pairs(children) do
          tinsert(tooltip, {2, " ", childData.id, 1, 1, 1, 1, 1, 1});
          scamCheck(codes, childData);
        end
        if(#tooltip > 3) then
          tooltip[4][2] = L["Children:"];
        else
          tinsert(tooltip, {1, L["No Children:"], 1, 1, 1});
        end
      elseif(data.controlledChildren) then
        for index, childId in pairs(data.controlledChildren) do
          tinsert(tooltip, {2, " ", childId, 1, 1, 1, 1, 1, 1});
        end
        if(#tooltip > 3) then
          tooltip[4][2] = L["Children:"];
        else
          tinsert(tooltip, {1, L["No Children:"], 1, 1, 1});
        end
      else
        for triggernum = 0, 9 do
          local trigger;
          if(triggernum == 0) then
            trigger = data.trigger;
          elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
            trigger = data.additional_triggers[triggernum].trigger;
          end
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

                local i = icons or (WeakAurasOptionsSaved and WeakAurasOptionsSaved.iconCache);
                tinsert(tooltip, {2, left, name..(i and i[name] and (" |T"..i[name]..":12:12:0:0:64:64:4:60:4:60|t") or ""), 1, 1, 1, 1, 1, 1});
              end
            elseif(trigger.type == "event" or trigger.type == "status") then
              if(trigger.type == "event") then
                tinsert(tooltip, {2, L["Trigger:"], (event_types[trigger.event] or L["Undefined"]), 1, 1, 1, 1, 1, 1});
              else
                tinsert(tooltip, {2, L["Trigger:"], (status_types[trigger.event] or L["Undefined"]), 1, 1, 1, 1, 1, 1});
              end
              if(trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix) then
                tinsert(tooltip, {2, L["Message type:"], (WeakAuras.subevent_prefix_types[trigger.subeventPrefix] or L["Undefined"]).." "..(WeakAuras.subevent_suffix_types[trigger.subeventSuffix] or L["Undefined"]), 1, 1, 1, 1, 1, 1});
              end
            else
              tinsert(tooltip, {2, L["Trigger:"], L["Custom"], 1, 1, 1, 1, 1, 1});
            end
          end
        end
      end

      if (import and #tooltip > 30) then
        -- Truncate the tooltip to ~25 auras if there are more than ~30
        local size = #tooltip
        tooltip[26] = {2, " ",  "[...]", 1, 1, 1, 1, 1, 1};
        local nrOfChildren = children and #children or data.controlledChildren and #data.controlledChildren or 0
        tooltip[27] = {1, string.format(L["%s total auras"], nrOfChildren), "", 1, 1, 1, 1, 1, 1};
        for i = 28, size do
          tooltip[i] = nil;
        end
      end

      if(data.desc and data.desc ~= "") then
        tinsert(tooltip, {1, " "});
        tinsert(tooltip, {1, "\""..data.desc.."\"", 1, 0.82, 0, 1});
      end

      local importbutton;
      local showcodebutton;
      if(import) then
        tinsert(tooltip, {1, " "});
        if(type(import) == "string" and import ~= "unknown") then
          tinsert(tooltip, {2, L["From"]..": "..import, "                         ", 0, 1, 0});
        end

        if #codes > 0 then
          tinsert(tooltip, {1, "The Aura you are importing contains custom code.", 1, 0, 0});
          tinsert(tooltip, {1, "Make sure you can trust the person who sent it!", 1, 0, 0});
        end

        tinsert(tooltip, {2, " ", "                         ", 0, 1, 0});
        tinsert(tooltip, {2, " ", "                         ", 0, 1, 0});

        if not(ItemRefTooltip.WeakAuras_Tooltip_Button) then
          ItemRefTooltip.WeakAuras_Tooltip_Button = CreateFrame("Button", "WeakAurasTooltipImportButton", ItemRefTooltip, "UIPanelButtonTemplate")
        end
        importbutton = ItemRefTooltip.WeakAuras_Tooltip_Button;
        importbutton:SetPoint("BOTTOMRIGHT", ItemRefTooltip, "BOTTOMRIGHT", -8, 8);
        importbutton:SetWidth(90);
        importbutton:RegisterEvent("PLAYER_REGEN_ENABLED");
        importbutton:RegisterEvent("PLAYER_REGEN_DISABLED");

        if not(ItemRefTooltip.WeakAuras_Tooltip_Button2) then
          ItemRefTooltip.WeakAuras_Tooltip_Button2 = CreateFrame("Button", "WeakAurasTooltipImportButton", ItemRefTooltip, "UIPanelButtonTemplate")
        end
        showcodebutton = ItemRefTooltip.WeakAuras_Tooltip_Button2;
        showcodebutton:SetPoint("BOTTOMLEFT", ItemRefTooltip, "BOTTOMLEFT", 8, 8);
        showcodebutton:SetWidth(90);

        local function onCombat(self, event)
          if (event == "PLAYER_REGEN_ENABLED") then
            importbutton:Enable();
          else
            importbutton:Disable();
          end
        end

        importbutton:SetScript("OnEvent", onCombat);
        if (InCombatLockdown()) then
          importbutton:Disable();
        end
        showcodebutton:SetText(L["Show Code"]);
        if not WeakAurasSaved.import_disabled or WeakAuras.IsImporting() then
          importbutton:SetText("Import");
          importbutton:SetScript("OnClick", function()
              local func = function()
                WeakAuras.SetImporting(true);
                WeakAuras.OpenOptions();

                local optionsFrame = WeakAuras.OptionsFrame();
                if not(optionsFrame) then
                  WeakAuras.ToggleOptions();
                  optionsFrame = WeakAuras.OptionsFrame();
                end

                if not(WeakAuras.IsOptionsOpen()) then
                  WeakAuras.ToggleOptions();
                end

                local function importData(data)
                  local id = data.id
                  local num = 2;
                  while(WeakAurasSaved.displays[id]) do
                    id = data.id.." "..num;
                    num = num + 1;
                  end
                  data.id = id;
                  data.parent = nil;

                  WeakAuras.Add(data);
                  WeakAuras.NewDisplayButton(data);
                end

                importData(data);
                WeakAuras.Add(data);
                WeakAuras.NewDisplayButton(data);
                coroutine.yield();

                if(children) then
                  for index, childData in pairs(children) do
                    importData(childData);
                    tinsert(data.controlledChildren, childData.id);
                    childData.parent = data.id;
                    WeakAuras.Add(data);
                    WeakAuras.Add(childData);
                    coroutine.yield();
                  end
                end

                if (children) then
                  for index, childData in pairs(children) do
                    WeakAuras.NewDisplayButton(childData);
                    local childButton = WeakAuras.GetDisplayButton(childData.id);
                    childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
                    childButton:SetGroupOrder(index, #data.controlledChildren);
                    coroutine.yield();
                  end

                  local button = WeakAuras.GetDisplayButton(data.id);
                  button.callbacks.UpdateExpandButton();
                  WeakAuras.UpdateDisplayButton(data);
                  WeakAuras.ReloadGroupRegionOptions(data);
                  WeakAuras.SortDisplayButtons();
                end

                WeakAuras.Add(data);
                ItemRefTooltip:Hide();
                WeakAuras.PickDisplay(data.id);
                WeakAuras.CloseImportExport();
                WeakAuras.SetImporting(false);
              end

              local co = coroutine.create(func);
              WeakAuras.dynFrame:AddAction("import", co);
            end);
        else
          -- TODO enable button after importing finished
          importbutton:SetText("Import disabled");
          importbutton:SetScript("OnClick", function()
              WeakAuras.CloseImportExport();
            end);
        end

        showcodebutton:SetScript("OnClick", function()
            WeakAuras.OpenOptions();
            WeakAuras.OpenCodeReview(codes);
          end);
      end

      ShowTooltip(tooltip);

      if(import) then
        importbutton:Show();
        if (#codes > 0) then
          showcodebutton:Show();
        else
          showcodebutton:Hide();
        end
      end

      if not(ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame) then
        ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame = CreateFrame("frame", nil, ItemRefTooltip);
      end
      local thumbnail_frame = ItemRefTooltip.WeakAuras_Tooltip_Thumbnail_Frame;
      thumbnail_frame:SetWidth(40);
      thumbnail_frame:SetHeight(40);
      thumbnail_frame:SetPoint("TOPRIGHT", ItemRefTooltip, "TOPRIGHT", -27, -7);

      if(alterdesc) then
        if not(ItemRefTooltip.WeakAuras_Desc_Box) then
          ItemRefTooltip.WeakAuras_Desc_Box = CreateFrame("frame", nil, ItemRefTooltip);
        end
        local descboxframe = ItemRefTooltip.WeakAuras_Desc_Box;
        descboxframe:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = {
              left = 4,
              right = 3,
              top = 4,
              bottom = 3
            }
          });
        descboxframe:SetBackdropColor(0, 0, 0);
        descboxframe:SetBackdropBorderColor(0.4, 0.4, 0.4);
        descboxframe:SetHeight(80);
        descboxframe:SetWidth(260);
        descboxframe:SetPoint("TOP", ItemRefTooltip, "BOTTOM");
        descboxframe:Show();

        local descbox = descboxframe.descbox;
        if not(descbox) then
          descbox = CreateFrame("editbox", nil, descboxframe);
          descboxframe.descbox = descbox;
        end
        descbox:SetPoint("BOTTOMLEFT", descboxframe, "BOTTOMLEFT", 8, 8);
        descbox:SetPoint("TOPRIGHT", descboxframe, "TOPRIGHT", -8, -8);
        descbox:SetFont("Fonts\\FRIZQT__.TTF", 12);
        descbox:EnableMouse(true);
        descbox:SetAutoFocus(false);
        descbox:SetCountInvisibleLetters(false);
        descbox:SetMultiLine(true);
        descbox:SetScript("OnEscapePressed", function()
            descbox:ClearFocus();
            if(data.desc and data.desc ~= "") then
              descbox:SetText(data.desc);
            else
              descbox:SetText("");
            end
          end);
        descbox:SetScript("OnEnterPressed", function()
            if(descbox:GetText() ~= "") then
              data.desc = descbox:GetText();
            else
              data.desc = nil;
            end
            WeakAuras.ShowDisplayTooltip(data, children, nil, nil, import, nil, true);
            descbox:ClearFocus();
            if(WeakAuras.GetDisplayButton) then
              local button = WeakAuras.GetDisplayButton(data.id);
              if(button) then
                button:SetNormalTooltip();
              end
            end
          end);
        if(data.desc and data.desc ~= "") then
          descbox:SetText(data.desc);
        else
          descbox:SetText("");
        end
        descbox:SetFocus();
        descbox:Show();
      end

      local RegularGetData;
      if(children) then
        data.controlledChildren = {};
        for index, childData in pairs(children) do
          if(compressed) then
            DecompressDisplay(childData);
          end
          data.controlledChildren[index] = childData.id;
        end

        -- WeakAuras.GetData needs to be replaced temporarily so that when the subsequent code constructs the thumbnail for
        -- the tooltip, it will look to the incoming transmission data for child data. This allows thumbnails of incoming
        -- groups to be constructed properly.
        RegularGetData = WeakAuras.GetData;
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

      if (not IsAddOnLoaded('WeakAurasOptions')) then
        LoadAddOn('WeakAurasOptions')
      end

      local ok,thumbnail = pcall(regionOptions[regionType].createThumbnail,thumbnail_frame, regionTypes[regionType].create);
      if not ok then
        error("Error creating thumbnail", 2)
      else
        --print("OK")
      end

      WeakAuras.validate(data, regionTypes[regionType].default);
      regionOptions[regionType].modifyThumbnail(thumbnail_frame, thumbnail, data, regionTypes[regionType].modify);
      ItemRefTooltip.WeakAuras_Tooltip_Thumbnail = thumbnail;

      thumbnail:SetAllPoints(thumbnail_frame);
      if(thumbnail.SetIcon) then
        local i;
        if(icon) then
          i = icon;
        elseif(WeakAuras.transmitCache and WeakAuras.transmitCache[data.id]) then
          i = WeakAuras.transmitCache[data.id];
        end
        thumbnail:SetIcon(i);
      end
      thumbnail_frame:Show();

      if(children and RegularGetData) then
        WeakAuras.GetData = RegularGetData;
        data.controlledChildren = nil;
      end
    elseif(type(data) == "string") then
      ShowTooltip({
          {1, "WeakAuras", 0.5333, 0, 1},
          {1, data, 1, 0, 0}
        });
    end
  end

  function WeakAuras.ImportString(str)
    local received = StringToTable(str, true);
    if(received and type(received) == "table" and received.m) then
      if(received.m == "d") then
        tooltipLoading = nil;
        if(version < received.v) then
          local errorMsg = L["Version error received higher"]
          ShowTooltip({
              {1, "WeakAuras", 0.5333, 0, 1},
              {1, errorMsg:format(received.s, versionString), 1, 0, 0}
            });
        else
          local data = received.d;
          WeakAuras.ShowDisplayTooltip(data, received.c, received.i, received.a, "unknown", true)
        end
      end
    elseif(type(received) == "string") then
      ShowTooltip({
          {1, "WeakAuras", 0.5333, 0, 1},
          {1, received, 1, 0, 0, 1}
        });
    end
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
    Comm:SendCommMessage("WeakAuras", transmitString, "WHISPER", characterName);
  end

  function TransmitError(errorMsg, characterName)
    local transmit = {
      m = "dE",
      eM = errorMsg
    };
    Comm:SendCommMessage("WeakAuras", TableToString(transmit), "WHISPER", characterName);
  end

  function TransmitDisplay(id, characterName)
    local encoded = WeakAuras.DisplayToString(id);
    if(encoded ~= "") then
      Comm:SendCommMessage("WeakAuras", encoded, "WHISPER", characterName, "BULK", function(displayName, done, total)
          Comm:SendCommMessage("WeakAurasProg", done.." "..total.." "..displayName, "WHISPER", characterName, "ALERT");
        end, id);
    else
      TransmitError("dne", characterName);
    end
  end

  Comm:RegisterComm("WeakAurasProg", function(prefix, message, distribution, sender)
      if tooltipLoading and ItemRefTooltip:IsVisible() and safeSenders[sender] then
        local done, total, displayName = strsplit(" ", message, 3)
        local done = tonumber(done)
        local total = tonumber(total)
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
      local received = StringToTable(message);
      if(received and type(received) == "table" and received.m) then
        if(received.m == "d") and safeSenders[sender] then
          tooltipLoading = nil;
          if(version ~= received.v) then
            local errorMsg = version > received.v and L["Version error received lower"] or L["Version error received higher"]
            ShowTooltip({
                {1, "WeakAuras", 0.5333, 0, 1},
                {1, errorMsg:format(received.s, versionString), 1, 0, 0}
              });
          else
            local data = received.d;
            WeakAuras.ShowDisplayTooltip(data, received.c, received.i, received.a, sender, true)
          end
        elseif(received.m == "dR") then
          --if(WeakAuras.linked[received.d]) then
          TransmitDisplay(received.d, sender);
          --else
          --    TransmitError("not authorized", sender);
          --end
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
