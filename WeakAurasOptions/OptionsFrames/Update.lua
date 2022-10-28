if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

-- Scam Check
local function notEmptyString(str)
  return str and str ~= "" and string.find(str, "%S")
end

local function addCode(codes, text, code, ...)
  -- The 4th parameter is a "check" if the code is active
  -- The following line let's distinguish between addCode(a, b, c, nil) and addCode(a, b, c)
  -- If the 4th parameter is nil, then we want to return
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
      addCode(codes, L["%s %u. Overlay Function"]:format(id, i), trigger[property])
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
    local customChat = 1
    local customCode = 1
    local customCheck = 1
    for _, condition in ipairs(data.conditions) do
      if (condition.changes) then
        for _, property in ipairs(condition.changes) do
          if type(property.value) == "table" and property.value.custom then
            if property.property == "chat" then
              addCode(codes, L["%s - Condition Custom Chat %s"]:format(data.id, customChat), property.value.custom);
              customChat = customChat + 1
            elseif property.property == "customcode" then
              addCode(codes, L["%s - Condition Custom Code %s"]:format(data.id, customCode), property.value.custom);
              customCode = customCode + 1
            end
          end
        end
      end

      local function recurseAddCustomCheck(checks)
        if not checks then return end
        for _, check in pairs(checks) do
          if check.trigger == -1 and check.variable == "customcheck" then
            addCode(codes, L["%s - Condition Custom Check %s"]:format(data.id, customCheck), check.value);
            customCheck = customCheck + 1
          end
          recurseAddCustomCheck(check.checks)
        end
      end

      if condition.check then
        if condition.check.trigger == -1 and condition.check.variable == "customcheck" then
          addCode(codes, L["%s - Condition Custom Check %s"]:format(data.id, customCheck), condition.check.value);
          customCheck = customCheck + 1
        end
        recurseAddCustomCheck(condition.check.checks)
      end
    end
  end
end
-- End of scam check

-- Diff algorithm
local deleted = {} -- magic value
local fieldToCategory
local internalFieldMarker = {}

local function FieldToCategory(field, isRoot)
  if not fieldToCategory then
    -- Initialize fieldToCategory
    fieldToCategory = {}
    for _, cat in ipairs(OptionsPrivate.Private.update_categories) do
      for _, property in ipairs(cat.fields) do
        fieldToCategory[property] = cat.name
      end
    end
    for _, key in pairs(OptionsPrivate.Private.internal_fields) do
      fieldToCategory[key] = internalFieldMarker
    end
  end

  local category = fieldToCategory[field]
  if category == internalFieldMarker then
    return nil
  end

  if category == nil then
    category = "display"
  end
  -- For child auras, anchor fields are arrangement
  if not isRoot and category == "anchor" then
    category = "arrangement"
  end
  return category
end

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

local ignoredForDiffChecking -- Needs to be created lazily
local function RecurseDiff(ours, theirs)
  local diff, seen, same = {}, {}, true
  for key, ourVal in pairs(ours) do
    if not ignoredForDiffChecking[key] then
      seen[key] = true
      local theirVal = theirs[key]
      if type(ourVal) == "table" and type(theirVal) == "table" then
        local diffVal = RecurseDiff(ourVal, theirVal)
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
local function RecurseSerial(lines, depth, chunk)
  for k, v in pairs(chunk) do
    if v == deleted then
      tinsert(lines, string.rep("  ", depth) .. "|cFFFF0000" .. k .. " -> deleted|r")
    elseif type(v) == "table" then
      tinsert(lines, string.rep("  ", depth) .. k .. " -> {")
      RecurseSerial(lines, depth + 1, v)
      tinsert(lines, string.rep("  ", depth) .. "}")
    else
      tinsert(lines, string.rep("  ", depth) .. k .. " -> " .. tostring(v))
    end
  end
end

local function DebugPrintDiff(diff)
  local lines = {
    "==========================",
    "Diff detected: ",
    "{",
  }
  RecurseSerial(lines, 1, diff)
  tinsert(lines, "}")
  tinsert(lines, "==========================")
  print(table.concat(lines, "\n"))
end

local function Diff(ours, theirs)
  if not ignoredForDiffChecking then
    ignoredForDiffChecking = CreateFromMixins(OptionsPrivate.Private.internal_fields,
    OptionsPrivate.Private.non_transmissable_fields)
  end

  -- generates a diff which WeakAuras.Update can use
  local debug = false
  if not ours or not theirs then return end
  local diff = RecurseDiff(ours, theirs)
  if diff then
    if debug then
      DebugPrintDiff(diff, ours.id, theirs.id)
    end
    return diff
  end
end
-- End of diff

local function EnsureUniqueUid(data)
  if not data.uid then
    data.uid = WeakAuras.GenerateUniqueID()
  elseif OptionsPrivate.Private.GetDataByUID(data.uid) then
    data.uid = WeakAuras.GenerateUniqueID()
  end
end

local function CopyDiff(diff)
  local copy = {}
  for k, v in pairs(diff) do
    if v == deleted then
      copy[k] = deleted
    elseif type(v) == "table" then
      copy[k] = CopyDiff(v)
    else
      copy[k] = v
    end
  end
  return copy
end

local function BuildUidMap(data, children, type)
  children = children or {}
  -- The eventual result
  local uidMap = {
    map = { -- per uid
      -- originalName: The original id of the aura
      -- id: The current id of the aura, might have changed due to ids being unique
      -- data: The raw data, contains non-authoritative information on e.g. id, controlledChildren, parent, sortHybridTable
      -- controlledChildren: A array of child uids
      -- parent: The parent uid
      -- sortHybrid: optional bool !! the parent's sortHybridTable is split up and recorded per aura:
      --             nil, if the parent is not a dynamic group
      --             false/true based on the sortHybridTable of the dynamic group

      -- matchedUid: for "update", the matched uid. Is from a different domain!
      -- diff, categories: for "update", the diff and the categories of that diff between the aura and its match

      -- index, total, parentIsDynamicGroup: helpers that transport data between phase 1 and 2
    },
    type = type -- Either old or new, only used for error checking
    -- root: uid of the root
    -- totalCount: count of members
    -- idToUid maps from id to uid
  }
  uidMap.root = data.uid
  uidMap.totalCount = #children + 1

  -- Build helper map from id to uid
  local idToUid = {}
  idToUid[data.id] = data.uid
  for i, child in ipairs(children) do
    if idToUid[child.id] then
      error("Duplicate id in import data: "..child.id)
    end
    idToUid[child.id] = child.uid
  end

  uidMap.idToUid = idToUid

  local function handle(data)
    -- Add names and data to map
    uidMap.map[data.uid] = {
      originalName = data.id,
      id = data.id,
      data = data
    }

    -- Add controlled children
    if data.controlledChildren then
      local uidChildren = {}
      for i, id in ipairs(data.controlledChildren) do
        tinsert(uidChildren, idToUid[id])
      end
      uidMap.map[data.uid].controlledChildren = uidChildren
    end

    -- Add parent
    if data.parent then
      uidMap.map[data.uid].parent = idToUid[data.parent]
    end
  end

  local function handleSortHybridTable(data)
    if data.regionType == "dynamicgroup" then
      local sortHybridTableByUid = {}
      if data.sortHybridTable then
        for id, b in pairs(data.sortHybridTable) do
          -- The sortHybridTable might contain stale ids, since e.g. ungroup doesn't correctly
          -- remove entries
          if idToUid[id] then
            sortHybridTableByUid[idToUid[id]] = b
          end
        end
      end

      local children = uidMap.map[data.uid].controlledChildren or {}
      for _, childUid in ipairs(children) do
        local sortHybrid = sortHybridTableByUid[childUid] and true or false
        uidMap.map[childUid].sortHybrid = sortHybrid
      end
    end
  end

  handle(data)
  for i, child in ipairs(children) do
    handle(child)
  end

  handleSortHybridTable(data)
  for _, child in ipairs(children) do
    handleSortHybridTable(child)
  end


  uidMap.InsertData = function(self, data, parentUid, children, sortHybrid, index)
    self.idToUid[data.id] = data.uid
    self.totalCount = self.totalCount + 1

    -- clean up children/sortHybrid
    -- The Update code first inserts children before it inserts us
    -- But not every child might be inserted, since empty groups aren't inserted
    -- so clean that up here
    if children then
      for index, childUid in ipairs_reverse(children) do
        if not self:Contains(childUid) then
          tremove(children, index)
          if sortHybrid then
            sortHybrid[childUid] = nil
          end
        end
      end
    end

    uidMap.map[data.uid] = {
      originalName = data.id,
      id = data.id,
      data = data,
      parent = parentUid,
      matchedUid = data.uid,
      controlledChildren = children,
      sortHybrid = sortHybrid
    }

    if index then
      if uidMap.map[parentUid] and uidMap.map[parentUid].controlledChildren then
        tinsert(uidMap.map[parentUid].controlledChildren, index, data.uid)
      else
        error("Can't insert into parent")
      end
    end
  end

  uidMap.GetRootUID = function(self)
    return self.root
  end

  uidMap.GetType = function(self)
    return self.type
  end

  uidMap.Contains = function(self, uid)
    return self.map[uid] and true or false
  end

  uidMap.GetTotalCount = function(self)
    return self.totalCount
  end

  uidMap.GetRawData = function(self, uid)
    if not self.map[uid] then
      error("GetRawData for unknown uid")
      return
    end
    return self.map[uid].data
  end

  -- Cleans up id, controlledChildren, sortHybridTable, parent
  uidMap.GetPhase1Data = function(self, uid, withAppliedPath, activeCategories)
    if not self.map[uid] then
      error("GetPhase1Data for unknown uid")
      return nil
    end
    local data = CopyTable(self.map[uid].data)
    if withAppliedPath then
      if self.type == "new" then
        error("Can't apply patch on new side")
      end
      local diff = self:GetDiff(uid, activeCategories)
      if diff then
        recurseUpdate(data, diff)
      end
    end

    data.id = self.map[uid].id

    if (data.controlledChildren) then
      data.controlledChildren = {}
    end

    if (data.sortHybridTable) then
      data.sortHybridTable = {}
    end

    data.parent = nil
    return data
  end

  -- Remaps parent, controlledChildren, sortHybridTable
  uidMap.GetPhase2Data = function(self, uid, withAppliedPath, activeCategories)
    if not self.map[uid] then
      error("GetPhase2Data for unknown uid")
      return nil
    end

    local data = CopyTable(self.map[uid].data)
    if withAppliedPath then
      if self.type == "new" then
        error("Can't apply patch on new side")
      end
      local diff = self:GetDiff(uid, activeCategories)

      if diff then
        recurseUpdate(data, diff)
      end
    end
    data.id = self.map[uid].id
    if uid == self.root then
      data.parent = self.rootParent
    elseif self.map[uid].parent then
      data.parent = self:GetIdFor(self.map[uid].parent)
    else
      data.parent = nil
    end

    if self.map[uid].controlledChildren then
      data.controlledChildren = {}
      for i, childUid in ipairs(self.map[uid].controlledChildren) do
        data.controlledChildren[i] = self:GetIdFor(childUid)
      end
    else
      data.controlledChildren = nil
    end

    if data.regionType == "dynamicgroup" then
      data.sortHybridTable = {}
      for i, childUid in ipairs(self.map[uid].controlledChildren) do
        data.sortHybridTable[self:GetIdFor(childUid)] = self:GetSortHybrid(childUid)
      end
    else
      data.sortHybridTable = nil
    end

    return data
  end

  uidMap.GetChildren = function(self, uid)
    return self.map[uid] and self.map[uid].controlledChildren or {}
  end

  uidMap.GetRawChildren = function(self, uid)
    return self.map[uid] and self.map[uid].controlledChildren
  end

  uidMap.GetSortHybrid = function(self, uid)
    return self.map[uid] and self.map[uid].sortHybrid
  end

  uidMap.ChangeId = function(self, uid, id)
    if not self.map[uid] then
      error("ChangeId for unknown uid")
      return
    end

    local oldId = self.map[uid].id
    if (oldId == id) then
      return
    end
    uidMap.idToUid[oldId] = nil
    uidMap.idToUid[id] = uid

    self.map[uid].id = id
  end

  uidMap.ChangeUID = function(self, uid, newUid)
    if self.root == uid then
      self.root = newUid
    end
    if not self.map[uid] or self.map[newUid] then
      error("Invalid ChangeUID")
    end

    if self.map[uid] then
      self.map[newUid] = self.map[uid]
      self.map[uid] = nil

      self.map[newUid].data.uid = newUid
      self.idToUid[self.map[newUid].id] = newUid
      if self.map[newUid].parent then
        local parentMap = self.map[self.map[newUid].parent]
        for i, childUid in ipairs(parentMap.controlledChildren) do
          if childUid == uid then
            parentMap.controlledChildren[i] = newUid
            break;
          end
        end
      end

      if self.map[newUid].controlledChildren then
        for index, childUid in ipairs(self.map[newUid].controlledChildren) do
          self.map[childUid].parent = newUid
        end
      end

    end
  end

  uidMap.GetIdFor = function(self, uid)
    if not uid or not self.map[uid] then
      error(string.format("GetIdFor for unknown uid %s", uid))
      return
    end
    return self.map[uid].id
  end

  uidMap.GetOriginalName = function(self, uid)
    if not uid or not self.map[uid] then
      error(string.format("GetOriginalName for unknown uid %s", uid))
      return
    end
    return self.map[uid].originalName
  end

  uidMap.GetGroupOrder = function(self, uid)
    if not self.map[uid] then
      error("GetGroupOrder for unknown uid")
      return
    end
    return self.map[uid].index, self.map[uid].total
  end

  uidMap.SetGroupOrder = function(self, uid, index, total)
    if not self.map[uid] then
      error("SetGroupOrder for unknown uid")
      return
    end
    self.map[uid].index = index
    self.map[uid].total = total
  end

  uidMap.GetParent = function(self, uid)
    if not self.map[uid] then
      error("GetParent for unknown uid")
      return
    end
    return self.map[uid].parent
  end

  uidMap.UnsetParent = function(self, uid)
    if not self.map[uid] then
      error("GetParent for unknown uid")
      return
    end
    self.map[uid].parent = nil
  end

  uidMap.GetParentIsDynamicGroup = function(self, uid)
    if not self.map[uid] then
      error("GetParentIsDynamicGroup for unknown uid")
      return
    end
    return self.map[uid].parentIsDynamicGroup
  end

  uidMap.SetParentIsDynamicGroup = function(self, uid, parentIsDynamicGroup)
    if not self.map[uid] then
      error("SetParentIsDynamicGroup for unknown uid")
      return
    end
    self.map[uid].parentIsDynamicGroup = parentIsDynamicGroup
  end

  uidMap.SetUIDMatch = function(self, uid, matchedUid)
    if not self.map[uid] then
      error("SetUIDMatch for unknown uid")
      return
    end
    self.map[uid].matchedUid = matchedUid
  end

  uidMap.GetUIDMatch = function(self, uid)
    if not self.map[uid] then
      error("GetUIDMatch for unknown uid")
      return
    end
    return self.map[uid].matchedUid
  end

  uidMap.SetDiff = function(self, uid, diff, categories)
    if not self.map[uid] then
      error("SetDiff for unknown uid")
      return
    end
    self.map[uid].diff = diff
    self.map[uid].categories = categories
  end

  uidMap.GetDiff = function(self, uid, categories)
    if not self.map[uid] then
      error("GetDiff for unknown uid")
      return
    end
    if not self.map[uid].diff then
      return
    end
    local diff = CopyDiff(self.map[uid].diff)
    local isRoot = not self.map[uid].parent
    for key in pairs(diff) do
      local category = FieldToCategory(key, isRoot)
      if category == nil or not categories[category] then
        diff[key] = nil
      end
    end
    return diff
  end

  uidMap.GetGroupRegionType = function(self, uid)
    if not self.map[uid] then
      error("GetGroupRegionType for unknown uid")
      return
    end
    local data = self.map[uid].data
    if data.regionType == "group" or data.regionType == "dynamicgroup" then
      return data.regionType
    end
    return nil
  end

  uidMap.EnsureUniqueIdOfUnmatched = function(self, uid, IncProgress)
    uid = uid or self.root
    if not self.map[uid] then
      error(string.format("EnsureUniqueIdOfUnmatched for unknown uid %s", uid))
      return
    end

    if self.type == "old" then
      error("Call to EnsureUniqueIdOfUnmatched for old")
    end

    if not self:GetUIDMatch(uid) then
      if OptionsPrivate.Private.GetDataByUID(uid) then
        local newUid = WeakAuras.GenerateUniqueID()
        self:ChangeUID(uid, newUid)
        uid = newUid
      end
    end
    IncProgress()
    local children = self:GetChildren(uid)
    for _, childUid in ipairs(children) do
      self:EnsureUniqueIdOfUnmatched(childUid, IncProgress)
    end
  end

  uidMap.InsertUnmatchedPhase1 = function(self, otherUidMap, otherUid, IncProgress)
    local children = otherUidMap:GetChildren(otherUid)
    local lastMatchUid = nil -- our uid
    local waitingForMatch = {} -- Auras that we haven't assigned to a match yet
                               -- Will be added to before on finding a match
                               -- or the parent will be added
    local matchToInsert = {
      -- from our uid to
      --   before: array of other uids that should be inserted before the uid
      --   after: array of other uids that should be inserted after the uid
    }

    for index, childUid in ipairs(children) do
      local needsToBeInserted = self:InsertUnmatchedPhase1(otherUidMap, childUid, IncProgress)
      local matchedUid = otherUidMap:GetUIDMatch(childUid)
      if matchedUid then
        lastMatchUid = matchedUid
        matchToInsert[matchedUid] = matchToInsert[matchedUid] or {}
        matchToInsert[matchedUid].before = waitingForMatch
        waitingForMatch = {}
      else
        -- Auras => matchToInsert/waitingForMatch
        -- Groups:
        --    with Children: => matchToInsert/waitingForMatch
        --    without Children => skip groups that are empty and don't match
        local toInsert = otherUidMap:GetGroupRegionType(childUid) == nil or needsToBeInserted
        if toInsert then
          if lastMatchUid then
            matchToInsert[lastMatchUid] = matchToInsert[lastMatchUid] or {}
            matchToInsert[lastMatchUid].after = matchToInsert[lastMatchUid].after or {}
            tinsert(matchToInsert[lastMatchUid].after, childUid)
          else
            tinsert(waitingForMatch, childUid)
          end
        else
          IncProgress()
          coroutine.yield()
        end
      end
      coroutine.yield()
    end

    for uid, otherList in pairs(matchToInsert) do
      -- First find uid in parent
      local parent = self.map[uid].parent
      if parent then
        local parentChildren = self:GetChildren(parent)
        local index = tIndexOf(parentChildren, uid)

        if otherList.before then
          for _, otherUid in ipairs(otherList.before) do
            local otherData = otherUidMap:GetRawData(otherUid)
            local rawChildren = otherUidMap:GetRawChildren(otherUid)
            local sortHybrid = otherUidMap:GetSortHybrid(otherUid)
            self:InsertData(otherData, parent, rawChildren, sortHybrid, index)
            index = index + 1
            otherUidMap:SetUIDMatch(otherUid, otherUid) -- Uids are the same!
            self:SetUIDMatch(otherUid, otherUid)
            IncProgress()
            coroutine.yield()
          end
        end

        if otherList.after then
          index = index + 1 -- We insert after the match
          for _, otherUid in ipairs(otherList.after) do
            local otherData = otherUidMap:GetRawData(otherUid)
            local rawChildren = otherUidMap:GetRawChildren(otherUid)
            local sortHybrid = otherUidMap:GetSortHybrid(otherUid)
            self:InsertData(otherData, parent, rawChildren, sortHybrid, index)
            index = index + 1
            otherUidMap:SetUIDMatch(otherUid, otherUid) -- Uids are the same!
            self:SetUIDMatch(otherUid, otherUid)
            IncProgress()
            coroutine.yield()
          end
        end
      end
      coroutine.yield()
    end

    for _, otherUid in ipairs(waitingForMatch) do
      local otherData = otherUidMap:GetRawData(otherUid)
      local parent = otherUidMap:GetParent(otherUid)
      local rawChildren = otherUidMap:GetRawChildren(otherUid)
      local sortHybrid = otherUidMap:GetSortHybrid(otherUid)

      if otherUidMap:GetUIDMatch(parent) then
        -- the parent is matched, we need to insert ourselves into it
        local matchedParent = otherUidMap:GetUIDMatch(parent)
        self:InsertData(otherData, matchedParent, rawChildren, sortHybrid, #(self:GetChildren(matchedParent)) + 1)
      else
        -- the parent is unmatched, so we'll end up inserting it
        self:InsertData(otherData, parent, rawChildren, sortHybrid)
      end
      otherUidMap:SetUIDMatch(otherUid, otherUid) -- Uids are the same!
      self:SetUIDMatch(otherUid, otherUid)
      IncProgress()
      coroutine.yield()
    end

    return #waitingForMatch > 0
  end

  uidMap.InsertUnmatchedFrom = function(self, otherUidMap, IncProgress)
    self:InsertUnmatchedPhase1(otherUidMap, otherUidMap:GetRootUID(), IncProgress)
  end

  uidMap.Remove = function(self, uid)
    if not self.map[uid] then
      error("Can't remove what isn't there")
    end

    local id = self:GetIdFor(uid)
    local parent = self:GetParent(uid)
    self.map[uid] = nil
    self.idToUid[id] = nil
    self.totalCount = self.totalCount - 1
    if parent then
      if not self.map[parent] then
        error("Parent not found")
      end
      tDeleteItem(self.map[parent].controlledChildren, uid)
    end
  end

  uidMap.SetRootParent = function(self, parentId)
    self.rootParent = parentId
  end

  uidMap.Dump = function(self, uid)
    if uid == nil then
      uid = self:GetRootUID()
    end
    print(self:GetIdFor(uid))
    local children = self:GetChildren(uid)
    for i, childUid in ipairs(children) do
      uidMap:Dump(childUid)
    end
  end

  return uidMap, uidMap.root
end


local function hasChildren(data)
  return data.controlledChildren and true or false
end

local function MatchChild(uid, newUidMap, oldUidMap)
  if oldUidMap:Contains(uid) then
    newUidMap:SetUIDMatch(uid, uid)
    oldUidMap:SetUIDMatch(uid, uid)
  end

  local newChildren = newUidMap:GetChildren(uid)
  for _, childUid in ipairs(newChildren) do
    MatchChild(childUid, newUidMap, oldUidMap)
  end

end

local function BuildMatches(newUidMap, oldUidMap)
  newUidMap:SetUIDMatch(newUidMap:GetRootUID(), oldUidMap:GetRootUID())
  oldUidMap:SetUIDMatch(oldUidMap:GetRootUID(), newUidMap:GetRootUID())

  local newChildren = newUidMap:GetChildren(newUidMap:GetRootUID())
  for _, childUid in ipairs(newChildren) do
    MatchChild(childUid, newUidMap, oldUidMap)
  end
end

local function CheckForChangedRegionTypesHelper(newUidMap, oldUidMap, uid)
  local matchedUid = newUidMap:GetUIDMatch(uid)
  if matchedUid then
    if newUidMap:GetGroupRegionType(uid) ~= oldUidMap:GetGroupRegionType(matchedUid) then
      return false
    end
  end

  local newChildren = newUidMap:GetChildren(uid)
  for _, childUID in ipairs(newChildren) do
    if not CheckForChangedRegionTypesHelper(newUidMap, oldUidMap, childUID) then
      return false
    end
  end
  return true
end

local function CheckForChangedRegionTypes(newUidMap, oldUidMap)
  return CheckForChangedRegionTypesHelper(newUidMap, oldUidMap, newUidMap:GetRootUID())
end

-- This checks for this kind of matches:
-- Old:
-- Root
--  |> A
--     |-> B
-- New:
-- Root
--  |> B
--     |-> A
-- Where the structures conflict.
-- We do that with the following check per aura 'A' in new:
-- Consider the parents of A_new, root -> A_new
--   For each (recursive) child of A_old, check that none point to any parent of A_new
local function CheckForIncompatibleStructuresCheckOld(oldUid, oldUidMap, parents)
  local oldChildren = oldUidMap:GetChildren(oldUid)
  for _, oldChildUid in ipairs(oldChildren) do
    if parents[oldUidMap:GetUIDMatch(oldChildUid)] then
      return false
    end
    if not CheckForIncompatibleStructuresCheckOld(oldChildUid, oldUidMap, parents) then
      return false
    end
  end

  return true
end

local function CheckForIncompatibleStructuresHelper(uid, parents, newUidMap, oldUidMap)
  local oldUid = newUidMap:GetUIDMatch(uid)
  if not CheckForIncompatibleStructuresCheckOld(oldUid, oldUidMap, parents) then
    return false
  end

  parents[uid] = true
  local newChildren = newUidMap:GetChildren(uid)
  for _, newChildUid in ipairs(newChildren) do
    if not CheckForIncompatibleStructuresHelper(newChildUid, parents, newUidMap, oldUidMap) then
      return false
    end
  end
  parents[uid] = nil
  return true
end

local function CheckForIncompatibleStructures(newUidMap, oldUidMap)
  local parents = {}
  return CheckForIncompatibleStructuresHelper(newUidMap:GetRootUID(), parents, newUidMap, oldUidMap)
end

local function SetCategories(globalCategories, categories)
  for key, b in pairs(categories) do
    if b then
      globalCategories[key] = true
    end
  end
end



local function GetCategories(diff, isRoot)
  local categories = {}
  for key in pairs(diff) do
    local category = FieldToCategory(key, isRoot)
    if category then
      categories[category] = true
    end
  end
  return categories
end

local function BuildDiffsHelper(uid, newUidMap, oldUidMap, matchInfo)
  local matchedUid = newUidMap:GetUIDMatch(uid)
  local isGroup = newUidMap:GetGroupRegionType(uid)
  if matchedUid then
    local newParent = newUidMap:GetParent(uid)
    local oldParent = oldUidMap:GetParent(matchedUid)

    local differentParents = false
    if newParent == nil and oldParent == nil then
      -- Same
    elseif newParent == nil or oldParent == nil then
      -- Can't really happen
      differentParents = true
    else
      if newUidMap:GetUIDMatch(newParent) ~= oldParent then
        differentParents = true
      end
    end

    if differentParents then
      matchInfo.activeCategories.arrangement = true
    end

    if newUidMap:GetSortHybrid(uid) ~= oldUidMap:GetSortHybrid(matchedUid) then
      matchInfo.activeCategories.arrangement = true
    end

    -- We can use the raw data, because the diff algorithm ignores all the members that
    -- aren't directly comparable
    local oldRawData = oldUidMap:GetRawData(matchedUid)
    local newRawData = newUidMap:GetRawData(uid)
    local diff = Diff(oldRawData, newRawData)
    if diff then
      local categories = GetCategories(diff, uid == newUidMap:GetRootUID())
      newUidMap:SetDiff(uid, diff, categories)
      oldUidMap:SetDiff(matchedUid, diff, categories)
      SetCategories(matchInfo.activeCategories, categories)

      matchInfo.diffs[uid] = true
      if isGroup then
        matchInfo.modifiedGroupCount = matchInfo.modifiedGroupCount + 1
      else
        matchInfo.modifiedCount = matchInfo.modifiedCount + 1
      end
    else
      matchInfo.unmodified[uid] = true
      if isGroup then
        matchInfo.unmodifiedGroupCount = matchInfo.unmodifiedGroupCount + 1
      else
        matchInfo.unmodifiedCount = matchInfo.unmodifiedCount + 1
      end
    end
  else
    if isGroup then
      matchInfo.addedGroupCount = matchInfo.addedGroupCount + 1
      matchInfo.activeCategories.arrangement = true
    else
      matchInfo.added[uid] = true
      matchInfo.addedCount = matchInfo.addedCount + 1
      matchInfo.activeCategories.newchildren = true
    end
  end

  local newChildren = newUidMap:GetChildren(uid)
  for _, newChildUid in ipairs(newChildren) do
    BuildDiffsHelper(newChildUid, newUidMap, oldUidMap, matchInfo)
  end

  return matchInfo
end

local function BuildDiffsRemoved(oldUID, newUidMap, oldUidMap, matchInfo)
  local uid = oldUidMap:GetUIDMatch(oldUID)
  local isGroup = oldUidMap:GetGroupRegionType(oldUID)
  if not uid then
    if isGroup then
      matchInfo.deletedGroupCount = matchInfo.deletedGroupCount + 1
      matchInfo.activeCategories.arrangement = true
    else
      matchInfo.deleted[oldUID] = true
      matchInfo.deletedCount = matchInfo.deletedCount + 1
      matchInfo.activeCategories.oldchildren = true
    end
  end

  local oldChildren = oldUidMap:GetChildren(oldUID)
  for _, oldChildUid in ipairs(oldChildren) do
    BuildDiffsRemoved(oldChildUid, newUidMap, oldUidMap, matchInfo)
  end
end

-- This function compares the order of children in a given parent
-- It detects e.g.
-- Group         Group
--  A        =>   B
--- B             A
local function CompareControlledChildrenOrder(oldUID, newUidMap, oldUidMap, matchInfo)
  local newUid = oldUidMap:GetUIDMatch(oldUID)
  if newUid then
    -- We first iterate over the old order, and remember the index for all matches
    local oldOrder = {
      -- maps childUids of newUid to the index the corresponding aura has in oldUid
    }
    local oldChildren = oldUidMap:GetChildren(oldUID)
    for index, oldChildUid in ipairs(oldChildren) do
      local newChildUid = oldUidMap:GetUIDMatch(oldChildUid)
      if newChildUid then
        oldOrder[newChildUid] = index
      end
    end

    -- We now iterate the new order, and expect the indexes to monotonically increase
    local highestIndex = -1
    local newChildren = newUidMap:GetChildren(newUid)
    for index, newChildUid in ipairs(newChildren) do
      local oldIndex = oldOrder[newChildUid]
      if oldIndex then
        if oldIndex < highestIndex then
          matchInfo.activeCategories.arrangement = true
          return -- Don't need to check more
        else
          highestIndex = oldIndex
        end
      end
    end
  end

  local oldChildren = oldUidMap:GetChildren(oldUID)
  for _, oldChildUid in ipairs(oldChildren) do
    CompareControlledChildrenOrder(oldChildUid, newUidMap, oldUidMap, matchInfo)
  end
end

local function hasChanges(matchInfo)
  return matchInfo.modifiedCount > 0
         or matchInfo.modifiedGroupCount > 0
         or matchInfo.addedCount > 0
         or matchInfo.addedGroupCount > 0
         or matchInfo.deletedCount > 0
         or matchInfo.deletedGroupCount > 0
         or matchInfo.activeCategories.arrangement
end

local function BuildDiffs(newUidMap, oldUidMap)
  local matchInfo = {
    modifiedCount = 0,
    modifiedGroupCount = 0,
    unmodifiedCount = 0,
    unmodifiedGroupCount = 0,
    addedCount = 0,
    addedGroupCount = 0,
    deletedCount = 0,
    deletedGroupCount = 0,
    diffs = {}, -- Contains diffs for new uids
    unmodified = {}, -- Contains new uids that had a empty diff
    added = {}, -- Contains new uids that were added
    deleted = {}, -- Contains old uids that were removed
    activeCategories = {} -- maps from name of Private.update_categories to true/nil
  }
  -- Handles addition + modification
  BuildDiffsHelper(newUidMap:GetRootUID(), newUidMap, oldUidMap, matchInfo)
  -- Handles removals
  BuildDiffsRemoved(oldUidMap:GetRootUID(), newUidMap, oldUidMap, matchInfo)
  if not matchInfo.activeCategories.arrangement then
    CompareControlledChildrenOrder(oldUidMap:GetRootUID(), newUidMap, oldUidMap, matchInfo)
  end

  return matchInfo
end

local function MatchInfo(data, children, target)
  -- Check that the import has uids, otherwise we won't even try to match
  if not data.uid then
    return nil, L["Import has no UID, cannot be matched to existing auras."]
  end
  if children then
    for _, child in ipairs(children) do
      if not child.uid then
        return nil, L["Import has no UID, cannot be matched to existing auras."]
      end
    end
  end

  if target then
    if hasChildren(data) ~= hasChildren(target) then
      return nil, L["Invalid target aura"]
    end
  else
    target = OptionsPrivate.Private.GetDataByUID(data.uid)
    if target and hasChildren(data) ~= hasChildren(target) then
      target = nil
    end
  end
  if not target then
    return nil -- No error
  end

  -- Build a uid map for the target auras
  local oldChildren = {}
  for child in OptionsPrivate.Private.TraverseAllChildren(target) do
    tinsert(oldChildren, child)
  end

  local newUidMap = BuildUidMap(data, children, "new")
  local oldUidMap = BuildUidMap(target, oldChildren, "old")
  oldUidMap:SetRootParent(target.parent)
  newUidMap:SetRootParent(target.parent)

  BuildMatches(newUidMap, oldUidMap)
  if not CheckForChangedRegionTypes(newUidMap, oldUidMap) then
    return nil, L["Incompatible changes to group region types detected"]
  end

  if not CheckForIncompatibleStructures(newUidMap, oldUidMap) then
    return nil, L["Incompatible changes to group structure detected"]
  end

  local matchInfo = BuildDiffs(newUidMap, oldUidMap)
  matchInfo.newUidMap = newUidMap
  matchInfo.oldUidMap = oldUidMap

  return matchInfo
end

local function AddAuraList(container, uidMap, list, expandText)
  local expand = AceGUI:Create("WeakAurasExpand")
  local collapsed = true
  local image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand"
                           or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse"
  expand:SetImage(image)
  expand:SetImageSize(10, 10)
  expand:SetFontObject(GameFontHighlight)
  expand:SetFullWidth(true)
  expand:SetLabel(expandText)
  container:AddChild(expand)

  local auraLabelContainer = AceGUI:Create("WeakAurasInlineGroup")
  auraLabelContainer:SetFullWidth(true)
  auraLabelContainer:DoLayout()
  container:AddChild(auraLabelContainer)

  local sortedNames = {}
  for uid in pairs(list) do
    tinsert(sortedNames, uidMap:GetIdFor(uid))
  end
  table.sort(sortedNames)

  expand:SetCallback("OnClick", function()
    collapsed = not collapsed
    local image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand"
                           or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse"
    expand:SetImage(image)

    if collapsed then
      auraLabelContainer:ReleaseChildren()
    else
      local text
      for _, name in ipairs(sortedNames) do
        text = (text or "") .. "   • " .. name .. "\n"
      end
      if text then
        local auraLabel = AceGUI:Create("Label")
        auraLabel:SetText(text)
        auraLabel:SetFullWidth(true)
        auraLabelContainer:AddChild(auraLabel)
      end
    end
    auraLabelContainer:DoLayout()
    container:DoLayout()
  end)
end

local methods = {
  Open = function(self, data, children, target, sender, callbackFunc)
    if(self.optionsWindow.window == "importexport") then
      self.optionsWindow.importexport:Close();
    elseif(self.optionsWindow.window == "texture") then
      self.optionsWindow.texturePicker:CancelClose();
    elseif(self.optionsWindow.window == "icon") then
      self.optionsWindow.iconPicker:CancelClose();
    elseif(self.optionsWindow.window == "model") then
      self.optionsWindow.modelPicker:CancelClose();
    end
    self.optionsWindow.window = "update"
    self.optionsWindow:UpdateFrameVisible()

    self.pendingData = {
      data = data,
      children = children or {},
      target = target,
      sender = sender
    }
    self.userChoices = {

    }
    self.callbackFunc = callbackFunc

    self:ReleaseChildren()
    self:AddBasicInformationWidgets(data, sender)

    local matchInfoResult = AceGUI:Create("Label")
    matchInfoResult:SetFontObject(GameFontHighlight)
    matchInfoResult:SetFullWidth(true)
    self:AddChild(matchInfoResult)

    local matchInfo, errorMessage = MatchInfo(data, children, target)
    self.matchInfo = matchInfo

    -- Cases:
    -- No match => Import
    -- Match, but no difference => Import as Copy
    -- Match with difference  => Import as Copy / Update, preference depends on preferToUpdate
    if matchInfo ~= nil then
      if not hasChanges(matchInfo) then
        -- there is no difference whatsoever
        self.userChoices.mode = "import"
        matchInfoResult:SetText(L["You already have this group/aura. Importing will create a duplicate."])
        self.importButton:SetText(L["Import as Copy"])
      else
        local oldRootId = matchInfo.oldUidMap:GetIdFor(matchInfo.oldUidMap:GetRootUID())
        local preferToUpdate = matchInfo.oldUidMap:GetRawData(matchInfo.oldUidMap:GetRootUID()).preferToUpdate
        if (data.regionType == "group" or data.regionType == "dynamicgroup") then
          local matchInfoText = L["This is a modified version of your group: |cff9900FF%s|r"]:format(oldRootId)
          matchInfoResult:SetText(matchInfoText)
          if matchInfo.addedCount ~= 0 then
            AddAuraList(self, matchInfo.newUidMap, matchInfo.added, L["%d |4aura:auras; added"]:format(matchInfo.addedCount))
          end
          if matchInfo.modifiedCount ~= 0 then
            AddAuraList(self, matchInfo.oldUidMap, matchInfo.diffs, L["%d |4aura:auras; modified"]:format(matchInfo.modifiedCount))
          end
          if matchInfo.deletedCount ~= 0 then
            AddAuraList(self, matchInfo.oldUidMap, matchInfo.deleted, L["%d |4aura:auras; deleted"]:format(matchInfo.deletedCount))
          end
        else
          matchInfoResult:SetText(L["This is a modified version of your aura, |cff9900FF%s.|r"]:format(oldRootId))
        end

        self:AddChild(AceGUI:Create("WeakAurasSpacer"))
        local choicesHeader = AceGUI:Create("Label")
        choicesHeader:SetText(L["What do you want to do?"])
        choicesHeader:SetFontObject(GameFontNormalHuge)
        choicesHeader:SetFullWidth(true)
        self:AddChild(choicesHeader)

        local importCopyRadioButton = AceGUI:Create("CheckBox")
        importCopyRadioButton:SetLabel(L["Create a Copy"])
        importCopyRadioButton:SetType("radio")
        importCopyRadioButton:SetFullWidth(true)
        self.importCopyRadioButton = importCopyRadioButton
        self:AddChild(importCopyRadioButton)

        local updateRadioButton = AceGUI:Create("CheckBox")
        updateRadioButton:SetLabel(L["Update Auras"])
        updateRadioButton:SetType("radio")
        updateRadioButton:SetFullWidth(true)
        self.updateRadioButton = updateRadioButton
        self:AddChild(updateRadioButton)

        local updateUiArea = AceGUI:Create("WeakAurasInlineGroup")
        updateUiArea:SetFullWidth(true)
        updateUiArea:SetFullHeight(true)
        self.updateUiArea = updateUiArea
        self:AddChild(updateUiArea)

        importCopyRadioButton:SetCallback("OnValueChanged", function(_, _, v)
          self:SelectMode(v and "import" or "update")
          self:DoLayout()
        end)

        updateRadioButton:SetCallback("OnValueChanged", function(_, _, v)
          self:SelectMode(v and "update" or "import")
          self:DoLayout()
        end)

        self:SelectMode(preferToUpdate and "update" or "import")
      end
    else
      self.userChoices.mode = "import"
      local matchInfoText = ""
      if (errorMessage) then
        matchInfoText = matchInfoText .. "|cFFFF0000" .. errorMessage .. "|r\n"
      end

      -- No match, so plain import
      if data.controlledChildren then
        matchInfoText = matchInfoText .. L["Importing a group with %s child auras."]:format(#children)
      else
        matchInfoText = matchInfoText .. L["Importing a stand-alone aura."]
      end

      matchInfoResult:SetText(matchInfoText)
      self.importButton:SetText(L["Import"])
    end

    local scamCheckResult = {}
    scamCheck(scamCheckResult, data)
    if children then
      for _, child in ipairs(children) do
        scamCheck(scamCheckResult, child)
      end
    end
    self.scamCheckResult = scamCheckResult

    if (#scamCheckResult > 0) then
      self:AddChild(AceGUI:Create("WeakAurasSpacer"))

      local scamCheckText = AceGUI:Create("Label")
      scamCheckText:SetFontObject(GameFontHighlight)
      scamCheckText:SetFullWidth(true)
      scamCheckText:SetText(L["This aura contains custom Lua code.\nMake sure you can trust the person who sent it!"])
      scamCheckText:SetColor(1, 0, 0)
      self:AddChild(scamCheckText)
    end

    local highestVersion = data.internalVersion or 0
    if children then
      for _, child in ipairs(children) do
        highestVersion = max(highestVersion, child.internalVersion or 0)
      end
    end

    if (highestVersion > WeakAuras.InternalVersion()) then
      local highestVersionWarning = AceGUI:Create("Label")
      highestVersionWarning:SetFontObject(GameFontHighlight)
      highestVersionWarning:SetFullWidth(true)
      highestVersionWarning:SetText(L["This aura was created with a newer version of WeakAuras.\nIt might not work correctly with your version!"])
      highestVersionWarning:SetColor(1, 0, 0)
      self:AddChild(highestVersionWarning)
    end


    local currentBuild = floor(WeakAuras.BuildInfo / 10000)
    local importBuild = data.tocversion and floor(data.tocversion / 10000)

    if importBuild and currentBuild ~= importBuild then
      local flavorWarning = AceGUI:Create("Label")
      flavorWarning:SetFontObject(GameFontHighlight)
      flavorWarning:SetFullWidth(true)
      flavorWarning:SetText(L["This aura was created with a different version (%s) of World of Warcraft.\nIt might not work correctly!"]:format(OptionsPrivate.Private.TocToExpansion[importBuild]))
      flavorWarning:SetColor(1, 0, 0)
      self:AddChild(flavorWarning)
    end

    if (#scamCheckResult > 0) then
      self.viewCodeButton:Show()
    else
      self.viewCodeButton:Hide()
    end

    self:DoLayout()
  end,
  CreateUpdateArea = function(self, area, matchInfo)
    area:AddChild(AceGUI:Create("WeakAurasSpacer"))
    local categoryHeader = AceGUI:Create("Label")
    categoryHeader:SetText(L["Categories to Update"])
    categoryHeader:SetFontObject(GameFontNormalHuge)
    categoryHeader:SetFullWidth(true)
    area:AddChild(categoryHeader)

    self.userChoices.activeCategories = {}
    for index, category in pairs(OptionsPrivate.Private.update_categories) do
      local name = category.name
      if matchInfo.activeCategories[name] then
        local button = AceGUI:Create("CheckBox")
        button:SetLabel(category.label)
        button:SetFullWidth(true)
        button:SetValue(category.default)
        area:AddChild(button)

        self.userChoices.activeCategories[name] = category.default

        button:SetCallback("OnValueChanged", function(_, _, value)
          self.userChoices.activeCategories[name] = value
        end)

      end
    end

    area:DoLayout()
  end,
  SelectMode = function(self, mode)
    if self.userChoices.mode == mode then
      return
    end
    self.userChoices.mode = mode
    if mode == "update" then
      self.importButton:SetText(L["Update"])
      self.updateRadioButton:SetValue(true)
      self.importCopyRadioButton:SetValue(false)
      self:CreateUpdateArea(self.updateUiArea, self.matchInfo)
    elseif mode == "import" then
      self.importButton:SetText(L["Import as Copy"])
      self.updateRadioButton:SetValue(false)
      self.importCopyRadioButton:SetValue(true)
      self.updateUiArea:ReleaseChildren()
    end
  end,
  Import = function(self)
    OptionsPrivate.Private.dynFrame:AddAction("import", coroutine.create(function()
      self:ImportImpl()
    end))
  end,
  ImportImpl = function(self)
    local pendingData = self.pendingData
    local userChoices = self.userChoices
    local matchInfo = self.matchInfo

    self.importButton:SetEnabled(false)
    self.closeButton:SetEnabled(false)
    self.viewCodeButton:SetEnabled(false)
    OptionsPrivate.Private.SetImporting(true)

    -- Adjust UI
    self:ReleaseChildren()
    self:AddBasicInformationWidgets(pendingData.data, pendingData.sender)
    self:AddProgressWidgets()

    local pendingPickData

    if userChoices.mode == "import" then
      self:InitializeProgress(2 * (#pendingData.children + 1))

      EnsureUniqueUid(pendingData.data)
      for i, child in ipairs(pendingData.children) do
        EnsureUniqueUid(child)
      end

      local uidMap = BuildUidMap(pendingData.data, pendingData.children, "new")

      local phase2Order = {}
      self:ImportPhase1(uidMap, uidMap:GetRootUID(), phase2Order)
      self:ImportPhase2(uidMap, phase2Order)

      pendingPickData = {
        id = uidMap:GetIdFor(uidMap:GetRootUID())
      }
      if #pendingData.children > 0 then
        pendingPickData.tabToShow = "group"
      end

      OptionsPrivate.SortDisplayButtons()
    elseif userChoices.mode == "update" then
      local onePhaseProgress = matchInfo.oldUidMap:GetTotalCount() + matchInfo.newUidMap:GetTotalCount()
      local IncProgress = function() self:IncProgress() end

      -- The progress is more for appearances than anything resembling real calculation
      -- The estimate for the total work is wonky, as is how the code compensates for that
      -- But then again, lying progress bar is a industry standard pratice
      self:InitializeProgress(onePhaseProgress * 26)
      -- The uids of unmatched auras, might already be in use already, assign unique uids then
      -- This can happen if e.g. the user imports a group with a aura "A", but moves the aura out of the group
      -- On update, we won't match A_new to A_old, because A_old is outside the matched parent group
      -- Thus on import A_new needs to get its own uid
      -- On next import, the auras uids won't match either, there's not much we can do about that.
      matchInfo.newUidMap:EnsureUniqueIdOfUnmatched(nil, IncProgress)
      self:SetMinimumProgress(1 * onePhaseProgress)
      coroutine.yield()

      local removeOldGroups = matchInfo.activeCategories.arrangement and userChoices.activeCategories.arrangement
      if userChoices.activeCategories.oldchildren or removeOldGroups then
        self:RemoveUnmatchedOld(matchInfo.oldUidMap, matchInfo.oldUidMap:GetRootUID(), matchInfo.newUidMap,
                                userChoices.activeCategories.oldchildren,
                                removeOldGroups)
      end

      self:SetMinimumProgress(2 * onePhaseProgress)

      local removeNewGroups = matchInfo.activeCategories.arrangement and not userChoices.activeCategories.arrangement
      if not userChoices.activeCategories.newchildren or removeNewGroups then
        self:RemoveUnmatchedNew(matchInfo.newUidMap, matchInfo.newUidMap:GetRootUID(), matchInfo.oldUidMap,
                                not userChoices.activeCategories.newchildren,
                                removeNewGroups)
      end
      self:SetMinimumProgress(3 * onePhaseProgress)

      local targetNames = {}

      local structureUidMap -- We iterate either over new or old, depending on the mode
      local GetPhase1Data   -- Getting the right data is a bit tricky, and depends on the mode
      local GetPhase2Data
      if userChoices.activeCategories.arrangement then
        -- new arrangement
        structureUidMap = matchInfo.newUidMap
        if not userChoices.activeCategories.oldchildren then
          -- Keep old children
          matchInfo.newUidMap:InsertUnmatchedFrom(matchInfo.oldUidMap, IncProgress)
        end

        self:SetMinimumProgress(4 * onePhaseProgress)

        -- This ensures that we use unique (for new uids) or the same id (for existing uids) for the initial add
        -- There's another renaming after everything has been added
        self:FixUpNames(matchInfo.newUidMap)
        self:SetMinimumProgress(5 * onePhaseProgress)

        local useOldNames = not userChoices.activeCategories.name
        self:GatherTargetNames(matchInfo.newUidMap, matchInfo.oldUidMap, useOldNames, targetNames)
        self:SetMinimumProgress(6 * onePhaseProgress)

        GetPhase1Data = function(uid)
          local matchedUid = matchInfo.newUidMap:GetUIDMatch(uid)
          if matchedUid then
            local data = matchInfo.oldUidMap:GetPhase1Data(matchedUid, true, userChoices.activeCategories)
            data.uid = uid
            data.id = matchInfo.newUidMap:GetIdFor(uid)
            return data
          else
            return matchInfo.newUidMap:GetPhase1Data(uid)
          end
        end
        GetPhase2Data = function(uid)
          local matchedUid = matchInfo.newUidMap:GetUIDMatch(uid)
          if matchedUid then
            -- We want a combination of the old data updated via the diff and
            -- the new structure.
            local oldData = matchInfo.oldUidMap:GetPhase2Data(matchedUid, true, userChoices.activeCategories)
            local newData = matchInfo.newUidMap:GetPhase2Data(uid)
            oldData.controlledChildren = newData.controlledChildren
            oldData.parent = newData.parent
            oldData.sortHybridTable = newData.sortHybridTable
            oldData.uid = uid
            oldData.id = matchInfo.newUidMap:GetIdFor(uid)
            return oldData
          else
            return matchInfo.newUidMap:GetPhase2Data(uid)
          end
        end
      else
        -- old arrangement
        structureUidMap = matchInfo.oldUidMap
        if userChoices.activeCategories.newchildren then
          -- Add new children
          matchInfo.oldUidMap:InsertUnmatchedFrom(matchInfo.newUidMap, IncProgress)
        end
        self:SetMinimumProgress(4 * onePhaseProgress)

        self:FixUpNames(matchInfo.oldUidMap)
        self:SetMinimumProgress(5 * onePhaseProgress)

        local useNewNames = userChoices.activeCategories.name
        self:GatherTargetNames(matchInfo.oldUidMap, matchInfo.newUidMap, useNewNames, targetNames)
        self:SetMinimumProgress(6 * onePhaseProgress)

        GetPhase1Data  = function(uid)
          return matchInfo.oldUidMap:GetPhase1Data(uid, true, userChoices.activeCategories)
        end
        GetPhase2Data = function(uid)
          return matchInfo.oldUidMap:GetPhase2Data(uid, true, userChoices.activeCategories)
        end
      end

      local phase2Order = {}
      self:UpdatePhase1(structureUidMap, structureUidMap:GetRootUID(), GetPhase1Data, phase2Order)
      self:SetMinimumProgress(16 * onePhaseProgress)

      self:UpdatePhase2(structureUidMap, GetPhase2Data, phase2Order)
      self:SetMinimumProgress(26 * onePhaseProgress)
      while(self:RenameAuras(targetNames)) do
        -- Try renaming again and again...
      end
      self:SetMaxProgress()
      coroutine.yield()

      pendingPickData = {
        id = OptionsPrivate.Private.GetDataByUID(matchInfo.oldUidMap:GetRootUID()).id
      }
      if matchInfo.oldUidMap:GetGroupRegionType(matchInfo.oldUidMap:GetRootUID()) then
        pendingPickData.tabToShow = "group"
      end

      OptionsPrivate.SortDisplayButtons()
    end

    OptionsPrivate.Private.SetImporting(false)
    self.viewCodeButton:SetEnabled(true)
    self.importButton:SetEnabled(true)
    self.closeButton:SetEnabled(true)
    OptionsPrivate.Private.callbacks:Fire("Import")

    self:Close(true, pendingPickData.id)

    if pendingPickData then
      OptionsPrivate.ClearPicks()
      WeakAuras.PickDisplay(pendingPickData.id, pendingPickData.tabToShow)
    end
  end,
  -- This ensures that the id that we are adding is either
  --  same for existing uids
  --  or unique for non-existing uids
  -- Note: There's a final renaming via WeakAuras.Rename at the end of the update process
  FixUpNames = function(self, uidMap, uid)
    uid = uid or uidMap:GetRootUID()
    local existingData = OptionsPrivate.Private.GetDataByUID(uid)
    if existingData then
      if uidMap:GetIdFor(uid) ~= existingData.id then
      end
      uidMap:ChangeId(uid, existingData.id)
    else
      if WeakAuras.GetData(uidMap:GetIdFor(uid)) then
        local newId = OptionsPrivate.Private.FindUnusedId(uidMap:GetIdFor(uid))
        uidMap:ChangeId(uid, newId)
      end
    end
    self:IncProgress()
    coroutine.yield()
    local children = uidMap:GetChildren(uid)
    for _, childUid in ipairs(children) do
      self:FixUpNames(uidMap, childUid)
    end
  end,
  GatherTargetNames = function(self, structureUidMap, otherUidMap, useOtherUidMapNames, targetNames, uid)
    uid = uid or structureUidMap:GetRootUID()

    if useOtherUidMapNames then
      local matchedUid = structureUidMap:GetUIDMatch(uid)
      if matchedUid then
        targetNames[uid] = otherUidMap:GetOriginalName(matchedUid)
      else
        targetNames[uid] = structureUidMap:GetOriginalName(uid)
      end
    else
      targetNames[uid] = structureUidMap:GetOriginalName(uid)
    end

    self:IncProgress()
    coroutine.yield()
    local children = structureUidMap:GetChildren(uid)
    for _, childUid in ipairs(children) do
      self:GatherTargetNames(structureUidMap, otherUidMap, useOtherUidMapNames, targetNames, childUid)
    end
  end,
  RenameAuras = function(self, targetNames)
    local changed = false
    for uid, targetName in pairs(targetNames) do
      local aura = WeakAuras.GetData(targetName)
      if not aura then
        -- No squatter, so just take the name
        local data = OptionsPrivate.Private.GetDataByUID(uid)
        WeakAuras.Rename(data, targetName)
        targetNames[uid] = nil
        changed = true
        self:IncProgress()
        coroutine.yield()
      elseif aura.uid == uid then
        -- Already the correct name
        targetNames[uid] = nil
      else
        -- Somebody else is squatting the name, rename us with a suffix,
        -- so maybe a different aura can take our name

        local data = OptionsPrivate.Private.GetDataByUID(uid)
        if string.sub(data.id, 1, #targetName) == targetName then
          -- Our name is already prefixed with targetName, don't try to improve
        else
          local newId = OptionsPrivate.Private.FindUnusedId(targetName)
          local oldid = data.id
          WeakAuras.Rename(data, newId)
          if targetName[aura.uid] then -- We can hope that the aura the squatter renames itself, so try again
            changed = true
          end
          self:IncProgress()
          coroutine.yield()
        end
      end
    end
    coroutine.yield()
    return changed
  end,
  RemoveUnmatchedOld = function(self, uidMap, uid, otherMap, removeAuras, removeGroups)
    if uidMap:GetType() ~= "old" then
      error("Wrong map for delete")
    end

    local children = uidMap:GetChildren(uid)
    local removedAllChildren = true
    for index, childUid in ipairs_reverse(children) do
      local removed = self:RemoveUnmatchedOld(uidMap, childUid, otherMap, removeAuras, removeGroups)
      if not removed and not uidMap:GetUIDMatch(childUid) then
        removedAllChildren = false
      end
    end

    local matchedUid = uidMap:GetUIDMatch(uid)
    if not matchedUid and removedAllChildren then
      if uidMap:GetRootUID() == uid then
        error("Can't remove root")
      end

      if (uidMap:GetGroupRegionType(uid) and removeGroups)
          or (uidMap:GetGroupRegionType(uid) == nil and removeAuras)
        then

        for index, childUid in ipairs_reverse(children) do
          uidMap:UnsetParent(childUid)
        end

        local data = OptionsPrivate.Private.GetDataByUID(uid)
        if not data then
          error("Can't find data")
        end
        WeakAuras.Delete(data)
        uidMap:Remove(uid)
        self:IncProgress()
        coroutine.yield()
        return true
      end
    end
    self:IncProgress()
    coroutine.yield()
    return false
  end,
  RemoveUnmatchedNew = function(self, uidMap, uid, otherMap, removeAuras, removeGroups)
    if uidMap:GetType() ~= "new" then
      error("Wrong map for delete")
    end

    local children = uidMap:GetChildren(uid)
    local removedAllChildren = true
    for index, childUid in ipairs_reverse(children) do
      local removed = self:RemoveUnmatchedNew(uidMap, childUid, otherMap, removeAuras, removeGroups)
      if not removed and not uidMap:GetUIDMatch(childUid) then
        removedAllChildren = false
      end
    end

    local matchedUid = uidMap:GetUIDMatch(uid)
    if not matchedUid and removedAllChildren then
      if uidMap:GetRootUID() == uid then
        error("Can't remove root")
      end

      if (uidMap:GetGroupRegionType(uid) and removeGroups)
          or (uidMap:GetGroupRegionType(uid) == nil and removeAuras)
        then

        for index, childUid in ipairs_reverse(children) do
          uidMap:UnsetParent(childUid)
        end

        uidMap:Remove(uid)
        self:IncProgress()
        coroutine.yield()
        return true
      end
    end
    self:IncProgress()
    coroutine.yield()
    return false
  end,
  UpdatePhase1 = function(self, structureUidMap, uid, GetPhase1Data, phase2Order)
    local matched = structureUidMap:GetUIDMatch(uid)

    tinsert(phase2Order, uid)
    local data = GetPhase1Data(uid)
    data.preferToUpdate = true
    data.authorMode = nil

    WeakAuras.Add(data)
    WeakAuras.NewDisplayButton(data, true)
    self:IncProgress10()
    coroutine.yield()

    local children = structureUidMap:GetChildren(uid)
    local parentIsDynamicGroup = data.regionType == "dynamicgroup"
    for index, childUid in ipairs(children) do
      self:UpdatePhase1(structureUidMap, childUid, GetPhase1Data, phase2Order)
      structureUidMap:SetGroupOrder(childUid, index, #children)
      structureUidMap:SetParentIsDynamicGroup(childUid, parentIsDynamicGroup)
    end
  end,
  UpdatePhase2 = function(self, structureUidMap, GetPhase2Data, phase2Order)
    for i = #phase2Order, 1, -1 do
      local uid = phase2Order[i]
      local data = GetPhase2Data(uid)
      data.preferToUpdate = true
      data.authorMode = nil
      WeakAuras.Add(data)
      OptionsPrivate.Private.SetHistory(data.uid, data, "import")
      local button = OptionsPrivate.GetDisplayButton(data.id)
      button:SetData(data)
      if (data.parent) then
        local parentIsDynamicGroup = structureUidMap:GetParentIsDynamicGroup(uid)
        local index, total = structureUidMap:GetGroupOrder(uid)
        button:SetGroup(data.parent, parentIsDynamicGroup)
        button:SetGroupOrder(index, total)
      else
        button:SetGroup()
        button:SetGroupOrder(nil, nil)
      end
      button.callbacks.UpdateExpandButton()
      WeakAuras.UpdateGroupOrders(data)
      WeakAuras.UpdateThumbnail(data)
      WeakAuras.ClearAndUpdateOptions(data.id)
      self:IncProgress10()
      coroutine.yield()
    end

    -- Since we add from the leafs to the top, we need to correct the offset last
    for i = #phase2Order, 1, -1 do
      local uid = phase2Order[i]
      local data = OptionsPrivate.Private.GetDataByUID(uid)
      local displayButton = OptionsPrivate.GetDisplayButton(data.id)
      displayButton:UpdateOffset()
    end
  end,
  ImportPhase1 = function(self, uidMap, uid, phase2Order)
    tinsert(phase2Order, uid)
    local data = uidMap:GetPhase1Data(uid)
    local newId = OptionsPrivate.Private.FindUnusedId(data.id)
    uidMap:ChangeId(uid, newId)

    data.preferToUpdate = false
    data.authorMode = nil
    data.id = newId

    WeakAuras.Add(data)
    WeakAuras.NewDisplayButton(data, true)

    self:IncProgress()
    coroutine.yield()

    local children = uidMap:GetChildren(uid)
    local totalChildren = #children
    local parentIsDynamicGroup = data.regionType == "dynamicgroup"
    for index, childUid in ipairs(children) do
      self:ImportPhase1(uidMap, childUid, phase2Order)
      uidMap:SetGroupOrder(childUid, index, totalChildren)
      uidMap:SetParentIsDynamicGroup(childUid, parentIsDynamicGroup)
    end
  end,
  ImportPhase2 = function(self, uidMap, phase2Order)
    for i = #phase2Order, 1, -1 do
      local uid = phase2Order[i]
      local data = uidMap:GetPhase2Data(uid)
      data.preferToUpdate = false
      data.authorMode = nil
      WeakAuras.Add(data)
      OptionsPrivate.Private.SetHistory(data.uid, data, "import")

      local button = OptionsPrivate.GetDisplayButton(data.id)
      button:SetData(data)
      if (data.parent) then
        local parentIsDynamicGroup = uidMap:GetParentIsDynamicGroup(uid)
        local index, total = uidMap:GetGroupOrder(uid)
        button:SetGroup(data.parent, parentIsDynamicGroup)
        button:SetGroupOrder(index, total)
      else
        button:SetGroup()
        button:SetGroupOrder(nil, nil)
      end
      button.callbacks.UpdateExpandButton()
      WeakAuras.UpdateGroupOrders(data)
      WeakAuras.UpdateThumbnail(data)
      WeakAuras.ClearAndUpdateOptions(data.id)
      self:IncProgress()
      coroutine.yield()
    end

    for i = #phase2Order, 1, -1 do
      local uid = phase2Order[i]
      local data = OptionsPrivate.Private.GetDataByUID(uid)
      local displayButton = OptionsPrivate.GetDisplayButton(data.id)
      displayButton:UpdateOffset()
    end

  end,
  InitializeProgress = function(self, total)
    self.progress = 0
    self.total = total
    self.minProgress = nil
    self.progressBar:SetProgress(self.progress, self.total)
  end,
  IncProgress = function(self)
    if self.minProgress and self.progress + 10 < self.minProgress then
      self.progress = self.progress + 1 + floor((self.minProgress - self.progress + 1) / 10)
    else
      self.progress = self.progress + 1
    end
    self.progressBar:SetProgress(self.progress, self.total)
  end,
  IncProgress10 = function(self)
    if self.minProgress and self.progress + 10 < self.minProgress then
      self.progress = self.progress + 10 + floor((self.minProgress - self.progress + 10) / 10)
    else
      self.progress = self.progress + 10
    end
    self.progressBar:SetProgress(self.progress, self.total)
  end,
  SetMinimumProgress = function(self, minProgress)
    self.minProgress = minProgress
  end,
  SetMaxProgress = function(self)
    self.progress = self.total
    self.progressBar:SetProgress(self.progress, self.total)
  end,
  Close = function(self, success, id)
    self.optionsWindow.window = "default";
    self.optionsWindow:UpdateFrameVisible()
    if self.callbackFunc then
      self.callbackFunc(success, id)
    end
  end,
  AddBasicInformationWidgets = function(self, data, sender)
    local title = AceGUI:Create("Label")
    title:SetFontObject(GameFontNormalHuge)
    title:SetFullWidth(true)
    title:SetText(L["Importing %s"]:format(data.id))
    self:AddChild(title)

    local description = AceGUI:Create("Label")
    description:SetFontObject(GameFontHighlight)
    description:SetFullWidth(true)
    description:SetText(data.desc or "")
    self:AddChild(description)

    if data.url and data.url ~= "" then
      local url = AceGUI:Create("Label")
      url:SetFontObject(GameFontHighlight)
      url:SetFullWidth(true)
      url:SetText(L["Url: %s"]:format(data.url))
      self:AddChild(url)
    end

    if data.semver or data.version then
      local version = AceGUI:Create("Label")
      version:SetFontObject(GameFontHighlight)
      version:SetFullWidth(true)
      version:SetText(L["Version: %s"]:format(data.semver or data.version))
      self:AddChild(version)
    end

    if sender then
      local senderLabel = AceGUI:Create("Label")
      senderLabel:SetFontObject(GameFontHighlight)
      senderLabel:SetFullWidth(true)
      senderLabel:SetText(L["Aura received from: %s"]:format(sender))
      self:AddChild(senderLabel)
    end
  end,
  AddProgressWidgets = function(self)
    local title = AceGUI:Create("Label")
    title:SetFontObject(GameFontNormalHuge)
    title:SetFullWidth(true)
    title:SetText(L["Importing...."])
    self:AddChild(title)

    local progress = AceGUI:Create("WeakAurasProgressBar")
    self.progressBar = progress
    self:AddChild(progress)
  end
}

local updateFrame
local function ConstructUpdateFrame(frame)
  local group = AceGUI:Create("ScrollFrame");
  group.frame:SetParent(frame);
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 46);
  group.frame:Hide();
  group:SetLayout("flow");
  group.optionsWindow = frame


  -- Action buttons
  local viewCodeButton = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  viewCodeButton:SetScript("OnClick", function() OptionsPrivate.OpenCodeReview(group.scamCheckResult) end);
  viewCodeButton:SetPoint("BOTTOMLEFT", 20, -24);
  viewCodeButton:SetFrameLevel(viewCodeButton:GetFrameLevel() + 1)
  viewCodeButton:SetHeight(20);
  viewCodeButton:SetWidth(160);
  viewCodeButton:SetText(L["View custom code"])

  local importButton = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  importButton:SetScript("OnClick", function() group:Import() end);
  importButton:SetPoint("BOTTOMRIGHT", -190, -24);
  importButton:SetFrameLevel(importButton:GetFrameLevel() + 1)
  importButton:SetHeight(20);
  importButton:SetWidth(160);
  importButton:SetText(L["Import"])

  local closeButton = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  closeButton:SetScript("OnClick", function() group:Close(false) end);
  closeButton:SetPoint("BOTTOMRIGHT", -20, -24);
  closeButton:SetFrameLevel(closeButton:GetFrameLevel() + 1)
  closeButton:SetHeight(20);
  closeButton:SetWidth(160);
  closeButton:SetText(L["Close"])

  group.viewCodeButton = viewCodeButton
  group.importButton = importButton
  group.closeButton = closeButton

  for name, method in pairs(methods) do
    group[name] = method
  end

  return group
end

function OptionsPrivate.UpdateFrame(frame)
  updateFrame = updateFrame or ConstructUpdateFrame(frame)
  return updateFrame
end
