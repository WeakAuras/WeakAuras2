if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

--- Creates the options for one aura
---@param data auraData
---@return table
function OptionsPrivate.GetInformationOptions(data)
  --- @type boolean
  local isGroup = data.controlledChildren and true or false
  --- @type boolean
  local isTmpGroup = type(data.id) == "table"

  local options = {
    type = "group",
    name = L["Information"],
    order = 1,
    args = {

    }
  }

  --- @type number
  local order = 1
  local args = options.args

  -- NAME
  -- One Aura or Group: Allows editing of aura/group name
  -- Multi-selection: Don't allow any editing
  if not isTmpGroup then
    args.name = {
      type = "input",
      name = L["Name:"],
      width = WeakAuras.doubleWidth,
      order = order,
      get = function()
        return data.id
      end,
      set = function(info, newid)
        if data.id ~= newid and not WeakAuras.GetData(newid) then
          local oldid = data.id
          WeakAuras.Rename(data, newid);
        end
      end
    }
    order = order + 1
  end

  -- URL
  -- One Aura: Edit URL of the aura
  -- Group/Multi-selection: Edit URLs of both parent and children
  --- @type boolean
  local sameURL = true
  --- @type string|nil
  local commonURL
  --- @type string
  local desc = ""

  local traverseForUrl = isTmpGroup and OptionsPrivate.Private.TraverseAllChildren or OptionsPrivate.Private.TraverseAll
  for child in traverseForUrl(data) do
    if child.url then
      desc = desc .. "|cFFE0E000"..child.id..": |r"..child.url .. "\n"
    end
    if not commonURL then
      commonURL = child.url or ""
    elseif child.url ~= commonURL then
      sameURL = false
    end
  end

  args.url = {
    type = "input",
    name = sameURL and L["URL"] or "|cFF4080FF" .. L["URL"],
    width = WeakAuras.doubleWidth,
    get = function()
      return sameURL and commonURL or ""
    end,
    set = function(info, v)
      for child in traverseForUrl(data) do
        child.url = v
        WeakAuras.Add(child)
        OptionsPrivate.ClearOptions(child.id)
      end

      WeakAuras.ClearAndUpdateOptions(data.id)
    end,
    desc = sameURL and "" or desc,
    order = order
  }
  order = order + 1

  if isGroup then
    args.url_note = {
      type = "description",
      name = isTmpGroup and L["|cFFE0E000Note:|r This sets the URL on all selected auras"]
                         or L["|cFFE0E000Note:|r This sets the URL on this group and all its members."],
      width = WeakAuras.doubleWidth,
      order = order
    }
    order = order + 1
  end
  if OptionsPrivate.HasWagoUrl(data.id) then
    args.ignoreWagoUpdate = {
      type = "toggle",
      name = L["Ignore Wago updates"],
      desc = OptionsPrivate.IsWagoUpdateIgnored(data.id) and L["Do you want to enable updates for this aura"] or L["Do you want to ignore updates for this aura"],
      width = WeakAuras.doubleWidth,
      get = function() return OptionsPrivate.IsWagoUpdateIgnored(data.id) end,
      set = function(info, v)
          local auraData = WeakAuras.GetData(data.id)
          if auraData then
            local ignoreUpdate
            if OptionsPrivate.IsWagoUpdateIgnored(data.id) then
              ignoreUpdate = nil
            else
              ignoreUpdate = true
            end
            for child in OptionsPrivate.Private.TraverseAll(auraData) do
              child.ignoreWagoUpdate = ignoreUpdate
              OptionsPrivate.ClearOptions(child.id)
            end
            WeakAuras.ClearAndUpdateOptions(data.id)
          end
          OptionsPrivate.SortDisplayButtons(nil, true)

      end,
      order = order
    }
    order = order + 1
  end


  -- Description
  -- One Aura/Group: Edit description of the aura or group
  -- Multi-selection: No editing
  if not isTmpGroup then
    args.description = {
      type = "input",
      name = isGroup and L["Group Description"] or L["Description"],
      width = WeakAuras.doubleWidth,
      multiline = true,
      order = order,
      get = function()
        return data.desc
      end,
      set = function(info, v)
        data.desc = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    }
    order = order + 1

    if isGroup then
      args.description_note = {
        type = "description",
        name = string.format(L["|cFFE0E000Note:|r This sets the description only on '%s'"], data.id),
        width = WeakAuras.doubleWidth,
        order = order,
      }
      order = order + 1
    end
  end

  -- Show warnings only for single selection for now
  if not isGroup then
    local _, title, message = OptionsPrivate.Private.AuraWarnings.FormatWarnings(data.uid)
    if title and message then
      args.warningTitle = {
        type = "header",
        name = title,
        width = WeakAuras.doubleWidth,
        order = order,
      }
      order = order + 1

      args.warnings = {
        type = "description",
        name = message,
        width = WeakAuras.doubleWidth,
        order = order,
        fontSize = "medium"
      }
      order = order + 1
    end
  end

    -- compatibility Options
  args.compabilityTitle = {
    type = "header",
    name = L["Compatibility Options"],
    width = WeakAuras.doubleWidth,
    order = order,
  }
  order = order + 1

  local properties = {
    ignoreOptionsEventErrors = {
      name = L["Custom Trigger: Ignore Lua Errors on OPTIONS event"],
    },
    forceEvents = {
      name = L["Custom Trigger: Send fake events instead of STATUS event"]
    },
    groupOffset = {
      name = L["Offset by 1px"],
      onParent = true,
      regionType = "group"
    }
  }

  --- @type table<string, boolean>
  local same = {
    ignoreOptionsEventErrors = true,
    forceEvents = true,
    groupOffset = true
  }

  --- @type table<string, boolean>
  local common = {

  }

  --- @type table<string, string>
  local mergedDesc = {

  }

  for property, propertyData in pairs(properties) do
    if propertyData.onParent then
      if not isTmpGroup and (not propertyData.regionType or propertyData.regionType == data.regionType) then
        if data.information[property] ~= nil then
          common[property] = data.information[property]
        else
          common[property] = false
        end
      end
    else
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
        if not propertyData.regionType or propertyData.regionType == child.regionType then
          local effectiveProperty = child.information[property]
          if effectiveProperty == nil then
            effectiveProperty = false
          end

          mergedDesc[property] = (mergedDesc[property] or "") .. "|cFFE0E000" .. child.id .. ": |r"
          .. (effectiveProperty and "true" or "false") .. "\n"

          if common[property] == nil then
            common[property] = effectiveProperty
          elseif effectiveProperty ~= common[property] then
            same[property] = false
          end
        end
      end
    end

    if common[property] ~= nil then
      args["compatibility_" .. property] = {
        type = "toggle",
        name = same[property] and propertyData.name or "|cFF4080FF" .. propertyData.name,
        width = WeakAuras.doubleWidth,
        get = function()
          if propertyData.onParent then
            return data.information[property]
          else
            return same[property] and common[property] or false
          end
        end,
        set = function(info, v)
          if propertyData.onParent then
            data.information[property] = v
            WeakAuras.Add(data)
            OptionsPrivate.ClearOptions(data.id)
          else
            for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
              if not propertyData.regionType or propertyData.regionType == child.regionType then
                child.information[property] = v
                WeakAuras.Add(child)
                OptionsPrivate.ClearOptions(child.id)
              end
            end
          end
          WeakAuras.ClearAndUpdateOptions(data.id)
        end,
        desc = same[property] and "" or mergedDesc[property],
        order = order
      }
      order = order + 1
    end
  end

  -- Saved Data
  --- @type number
  local savedDataCount = 0
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
    OptionsPrivate.Private.SaveAuraEnvironment(data.id)
    if child.information.saved then
      savedDataCount = savedDataCount + 1
    end
  end
  if savedDataCount > 0 then
    args.savedDataTitle = {
      type = "header",
      name = L["Saved Data"],
      width = WeakAuras.doubleWidth,
      order = order,
    }
    order = order + 1

    for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
      if child.information.saved then
        args["savedData." .. child.uid] = {
          type = "description",
          name = L["%s stores around %s KB of data"]:format(child.id, ceil((#child.information.saved) / 1024)),
          width = savedDataCount > 1 and WeakAuras.doubleWidth or WeakAuras.normalWidth,
          order = order,
        }
        order = order + 1
      end
    end

    args.savedDataClear = {
      type = "execute",
      name = L["Clear Saved Data"],
      width = savedDataCount > 1 and WeakAuras.doubleWidth or WeakAuras.normalWidth,
      order = order,
      func = function()
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
          OptionsPrivate.Private.ClearAuraEnvironmentSavedData(child.id)
          WeakAuras.Add(child)
          OptionsPrivate.ClearOptions(child.id)
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    }
    order = order + 1
  end

  -- Debug Log
  args.debugLogTitle = {
    type = "header",
    name = L["Enable Debug Log"],
    width = WeakAuras.doubleWidth,
    order = order,
  }
  order = order + 1

  args.debugLogDesc = {
    type = "description",
    name = L["This enables the collection of debug logs. Custom code can add debug information to the log through the function DebugPrint."],
    width = WeakAuras.doubleWidth,
    order = order,
  }
  order = order + 1

  --- @type boolean
  local sameDebugLog = true
  --- @type boolean|nil
  local commonDebugLog
  --- @type string
  local debugLogDesc = ""

  if isGroup and not isTmpGroup then
    sameDebugLog = true
    commonDebugLog = data.information.debugLog and true or false
  else
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
      --- @type boolean
      local effectiveDebugLog = child.information.debugLog and true or false
      debugLogDesc = debugLogDesc .. "|cFFE0E000"..child.id..": |r".. (effectiveDebugLog and "true" or "false") .. "\n"
      if commonDebugLog == nil then
        commonDebugLog = effectiveDebugLog
      elseif effectiveDebugLog ~= commonDebugLog then
        sameDebugLog = false
      end
    end
  end

  args.debugLogToggle = {
    type = "toggle",
    name = sameDebugLog and L["Enable Debug Logging"] or "|cFF4080FF" .. L["Enable Debug Logging"],
    desc = not sameDebugLog and debugLogDesc or nil,
    width = WeakAuras.doubleWidth,
    order = order,
    get = function()
      return sameDebugLog and commonDebugLog
    end,
    set = function(info, v)
      if isGroup and not isTmpGroup then
        data.information.debugLog = v
        WeakAuras.Add(data)
      else
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
          child.information.debugLog = v
          WeakAuras.Add(child)
          OptionsPrivate.ClearOptions(child.id)
        end
      end

      WeakAuras.ClearAndUpdateOptions(data.id)
    end
  }
  order = order + 1

  if not sameDebugLog or commonDebugLog then
    args.debugLogShow = {
      type = "execute",
      name = L["Show Debug Logs"],
      width = WeakAuras.normalWidth,
      order = order,
      func = function()
        --- @type string
        local fullMessage = L["WeakAuras %s on WoW %s"]:format(WeakAuras.versionString, WeakAuras.BuildInfo) .. "\n\n"
        --- @type boolean
        local haveLogs = false
        if isGroup and not isTmpGroup then
          local auraLog = OptionsPrivate.Private.DebugLog.GetLogs(data.uid)
          if auraLog then
            haveLogs = true
            fullMessage = fullMessage .. L["Aura: '%s'"]:format(data.id)
            --- @type string|nil
            local version = data.semver or data.version
            if (version) then
              fullMessage = fullMessage .. "\n" .. L["Version: %s"]:format(version)
            end
            fullMessage = fullMessage .. "\n" .. L["Debug Log:"] .. "\n" .. auraLog .. "\n\n"
          end
        else
          for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
            --- @type string
            local auraLog = OptionsPrivate.Private.DebugLog.GetLogs(child.uid)
            if auraLog then
              haveLogs = true
              fullMessage = fullMessage .. L["Aura: '%s'"]:format(child.id)
              --- @type string|nil
              local version = child.semver or child.version
              if (version) then
                fullMessage = fullMessage .. "\n" .. L["Version: %s"]:format(version)
              end
              fullMessage = fullMessage .. "\n" .. L["Debug Log:"] .. "\n" .. auraLog .. "\n\n"
            end
          end
        end

        if haveLogs then
          OptionsPrivate.OpenDebugLog(fullMessage)
        else
          OptionsPrivate.OpenDebugLog(L["No Logs saved."])
        end
      end
    }
    order = order + 1

    args.debugLogClear = {
      type = "execute",
      name = L["Clear Debug Logs"],
      width = WeakAuras.normalWidth,
      order = order,
      func = function()
        if isGroup and not isTmpGroup then
          OptionsPrivate.Private.DebugLog.Clear(data.uid)
        else
          for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
            OptionsPrivate.Private.DebugLog.Clear(child.uid)
          end
        end
      end
    }
    order = order + 1
  end

  return options
end
