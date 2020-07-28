if not WeakAuras.IsCorrectVersion() then return end

local L = WeakAuras.L

function WeakAuras.GetInformationOptions(data)
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
          WeakAuras.HandleRename(data, oldid, newid)
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
  if not isTmpGroup then
    commonURL = data.url
    if data.url then
      desc = "|cFFE0E000"..data.id..": |r".. data.url .. "\n"
    end
  end
  if data.controlledChildren then
    for _, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId)
      if childData.url then
        desc = desc .. "|cFFE0E000"..childData.id..": |r"..childData.url .. "\n"
      end
      if not commonURL then
        commonURL = childData.url or ""
      elseif childData.url ~= commonURL then
        sameURL = false
      end
    end
  end

  args.url = {
    type = "input",
    name = sameURL and L["URL"] or "|cFF4080FF" .. L["URL"],
    width = WeakAuras.doubleWidth,
    get = function()
      if data.controlledChildren then
        return sameURL and commonURL or ""
      else
        return data.url
      end
    end,
    set = function(info, v)
      if data.controlledChildren then
        for _, childId in ipairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId)
          childData.url = v
          WeakAuras.Add(childData)
          WeakAuras.ClearOptions(childData.id)
        end
      end

      if not isTmpGroup then
        data.url = v
        WeakAuras.Add(data)
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

  return options
end
