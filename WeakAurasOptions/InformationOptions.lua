if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L

function OptionsPrivate.GetInformationOptions(data)
  local isGroup = data.controlledChildren
  local isTmpGroup = type(data.id) == "table"

  local options = {
    type = "group",
    name = L["Information"],
    order = 1,
    args = {

    }
  }

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
  local sameURL = true
  local commonURL
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
    local icon, title, message = OptionsPrivate.Private.AuraWarnings.FormatWarnings(data.uid)
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
      name = L["Ignore Lua Errors on OPTIONS event"],
    },
    groupOffset = {
      name = L["Offset by 1px"],
      onParent = true,
      regionType = "group"
    }
  }

  local same = {
    ignoreOptionsEventErrors = true,
    groupOffset = true
  }

  local common = {

  }

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


  return options
end
