--[[
  writes to options field of aura data, which is then read to construct the user config panel

  Values in aura data:
  authorOptions -> array of options.
  config -> key/value hash table.
    key, and format of value are defined by author, and the precise value is defined by the user.
    This table gets copied into the aura's script environment via aura_env.config.
  authorMode -> bool, used to determine if author or user mode is displayed in Custom Options tab.

  option -> table with fields:
    type (required) -> string such as "toggle", "slider", "string", "number", "color", etc.
    key (required) -> string which custom scripts can use to read the selected option
    default (required) -> default value of the option
    name (required) -> displayed name in the user config panel
    width (required) -> number between 0.1 and 2 (softMin of 0.5). Determines the width of the option.
    useDesc (optional) -> bool. If false, then the tooltip will not be used.
    desc (optional) -> string to be displayed in the option tooltip
  When options are merged together (i.e. when the user multiselects and then opens the custom options tab), there is one additonal field:
    references -> childID <=> optionID map, used to dereference to the proper option table in setters
  Supported option types, and additional fields that each type supports/requires:
    description -> dummy option which can be used to display some text. Not interactive, and so key/default/name are not set or required.
      text (required) -> text displayed on the panel
      fontSize (optional) -> fontSize. Default is medium.
    space -> dummy option which acts as a spacer. Not interactive, and so key/default/name are not set or required.
      useWidth (required) -> bool. If false, then the space is given full width in AceConfig. Else, option.width is used.
      useHeight (required) -> bool. If false, then the space covers only the line it renders on. Else, it covers the number of lines specified.
      height (optional) -> number. Height of space, in lines.
    separator -> AceConfig header widget.
      useName (required) -> bool. If true, then option.text is used as the name.
      test (optional) -> string. Text to be shown on the header widget.
    input -> text field which the user can input a string.
      length (optional) -> allowed length of the string. If set, then input longer than the allowed length will be trimmed
    number -> text field which the user can type in a number. Input is converted to a number value.
      max (optional) -> maximum allowed value. If set, then input greater than the maximum will be clamped
      min (optional) -> minimum allowed value. If set, then input lesser than the minimum will be clamped
      step (optional) -> stepsize
    select -> dropdown menu with author-specified strings to select.
      values (required) -> array of strings to select. config value will be the index corresponding to the string.
    toggle -> checkbutton which can be in a state of true or false, corresponding to checked and unchecked
    color -> color selector. Color is delivered as an {r, g, b, a} array.
    range -> slider element which allows the user to select a number value.
      max (optional) -> maximum allowed value. If set, then input greater than the maximum will be clamped
      min (optional) -> minimum allowed value. If set, then input lesser than the minimum will be clamped
      softmax (optional) -> Like max, but the manual entry will accept values up to the softmax.
      softmin (optional) -> Like min, but the manual entry will accept values down to the softmin.
      bigStep (optional) -> step size of the slider. Defaults to 0.05
      step (optional) -> like bigStep, but applies to number input as well
]]

local WeakAuras = WeakAuras
local L = WeakAuras.L

local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local conflictBlue = "|cFF4080FF"
local references, conflict = {}, {} -- magic values
-- classifications of options. Currently, we have simple and noninteractive
local optionClasses = {
  toggle = "simple",
  input = "simple",
  number = "simple",
  range = "simple",
  color = "simple",
  select = "simple",
  multiselect = "simple",
  description = "noninteractive",
  space = "noninteractive",
  header = "noninteractive",
}

local function atLeastOneSet(data, references, key)
  for childID, optionID in pairs(references) do
    if data[childID].authorOptions[optionID][key] ~= nil then
      return true
    end
  end
end

local function neq(a, b)
  if type(a) == "table"  and type(b) == "table" then
    for k, v in pairs(a) do
      if neq(v, b[k]) then return true end
    end
    for k, v in pairs(b) do
      if neq(v, a[k]) then return true end
    end
  else
    return a ~= b
  end
end

-- blues the name if there are conflicts between the references for this value
local function name(data, option, key, name, phrase)
  local header = name or phrase
  if not option[references] then
    return header
  elseif option[key] ~= nil or not atLeastOneSet(data, option[references], key) then
    return header
  else
    return conflictBlue .. header
  end
end

local function nameHead(data, option, phrase)
  if not option[references] then
    return phrase
  else
    for i = 1, #data[0].controlledChildren do
      if not option[references][i] then
        return conflictBlue .. phrase
      end
    end
    return phrase
  end
end

local function nameUser(data, config, option)
  if option[references] then
    local firstValue
    for childID in pairs(option[references]) do
      local childConfig = data[childID].config
      if firstValue == nil then
        firstValue = childConfig[option.key]
      elseif neq(firstValue, childConfig[option.key]) then
        return conflictBlue .. option.name
      end
    end
  end
  return option.name
end

local function nameUserDesc(data, option)
  if option.text then
    return option.text
  elseif not option[references] then
    return ""
  else
    local text = {}
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption.text and childOption.text ~= nil then
        tinsert(text, childOption.text)
      end
    end
    return conflictBlue .. tconcat(text, "\n")
  end
end

-- provides a tooltip showing all the conflicting values if there are any
local function desc(data, option, key, phrase)
  if not option[references] then
    return phrase
  elseif option[key] or not atLeastOneSet(data, option[references], key) then
    return phrase
  else
    local desc = {}
    if phrase then
      desc[1] = phrase
    end
    tinsert(desc, L["Values:"])
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption[key] ~= nil then
        tinsert(desc, ("%s #%i: %s"):format(childData.id, optionID, tostring(childOption[key])))
      end
    end
    return tconcat(desc,"\n")
  end
end

local function descKey(data, option, key, conflicts)
  local phrase = L["Key for aura_env.config at which the user value can be found."]
  local warning = L["|cFFFF0000Duplicate Keys Found!|nPlease change the keys of the following options!|r"]
  if not option[references] then
    if not conflicts then
      return phrase
    elseif conflicts[key] then
      local desc = {warning}
      for optionID in pairs(conflicts[key]) do
        if data.authorOptions[optionID] ~= option then
          tinsert(desc, L["Option %i"]:format(optionID))
        end
      end
      return tconcat(desc, "\n")
    end
  else
    local haveConflict = false
    local desc = {phrase}
    for childID, optionID in pairs(option[references]) do
      if conflicts[childID] and conflicts[childID][key] then
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        local subDesc = {}
        for optionID in pairs(conflicts[childID][key]) do
          if childData.authorOptions[optionID] ~= childOption then
            tinsert(subDesc,tostring(optionID))
          end
        end
        if not haveConflict then
          haveConflict = true
          desc[1] = warning
        end
        tinsert(desc, childData.id .. ":\n" .. tconcat(subDesc, ", "))
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descType(data, option)
  if not option[references] then
    return L["This setting controls what widget is generated in user mode."]
  else
    local desc = {
      L["This setting controls what widget is generated in user mode."],
      L["Used in Auras:"],
    }
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      tinsert(desc, ("%s - Option %i"):format(childData.id, optionID))
    end
    return tconcat(desc,"\n")
  end
end

local function descSelect(data, option, key)
  if not option[references] then
    return ""
  elseif option.values then
    return ""
  else
    local desc = {L["Values:"]}
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption.values[key] ~= nil then
        tinsert(desc, ("%s %i: - %s"):format(childData.id, optionID, tostring(childOption.values[key])))
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descColor(data, option, key)
  if not option[references] then
    return ""
  elseif option[key] or not atLeastOneSet(data, option[references], key) then
    return ""
  else
    local desc = {
      L["Values are in normalized rgba format."],
      L["Values:"],
    }
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption[key] ~= nil then
        tinsert(desc, ("%s #%i: %.2f %.2f %.2f %.2f"):format(childData.id, optionID, unpack(childOption[key])))
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descUser(data, option)
  if not option[references] then
    return option.useDesc and option.desc or nil
  elseif option.useDesc ~= nil and option.desc ~= nil then
    return option.useDesc and option.desc or nil
  else
    local desc = {}
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption.useDesc and childOption.desc and childOption.desc ~= "" then
        tinsert(desc, ("%s - %s"):format(childData.id, childOption.desc))
      end
    end
    return tconcat(desc, "\n")
  end
end

-- getters for AceConfig
local function get(option, key)
  return function()
    return option[key]
  end
end

local function getKey(option, key, conflicts)
  if option[references] then
    return function()
      local key = option.key
      for childID in pairs(option[references]) do
        if conflicts[childID] and conflicts[childID][key] then
          return "|cFFFF0000" .. key
        end
      end
      return key
    end
  else
    return function()
      if not conflicts or not conflicts[key] then
        return key
      else
        return "|cFFFF0000" .. key
      end
    end
  end
end

local function getUser(data, config, option)
  if option[references] then
    return function()
      local firstValue
      for childID in pairs(option[references]) do
        local childConfig = data[childID].config
        if firstValue == nil then
          firstValue = childConfig[option.key]
        elseif neq(firstValue, childConfig[option.key]) then
          return
        end
      end
      return firstValue
    end
  else
    return function()
      return config[option.key]
    end
  end
end

local function getStr(option, key)
  return function()
    local str = option[key] or ""
    return str:gsub("|", "||")
  end
end

local function getNumAsString(option, key)
  return function()
    if option[key] ~= nil then
      return tostring(option[key])
    end
  end
end

local function getUserNum(data, config, option)
  if option[references] then
    return function()
      local firstValue
      for childID in pairs(option[references]) do
        local childConfig = data[childID].config
        if firstValue == nil then
          firstValue = childConfig[option.key]
        elseif neq(firstValue, childConfig[option.key]) then
          return
        end
      end
      if firstValue ~= nil then
        return tostring(firstValue)
      end
    end
  else
    return function()
      if config[option.key] ~= nil then
        return tostring(config[option.key])
      end
    end
  end
end

local function getValues(data, option)
  local values
  if option[references] then
    values = {}
    local firstChild = true
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      local childValues = childData.authorOptions[optionID].values
      local i = 1
      while i <= #values or i <= #childValues do
        if firstChild then
          values[i] = childValues[i]
        elseif values[i] ~= childValues[i] then
          values[i] = conflict
        end
        i = i + 1
      end
      firstChild = false
    end
  else
    values = option.values
  end
  return values
end

local function getUserValues(data, option)
  local values
  if option[references] then
    values = getValues(data, option)
    for i, v in ipairs(values) do
      if v == conflict then
        values[i] = conflictBlue .. L["Value %i"]:format(i)
      end
    end
  else
    values = option.values
  end
  return values
end

local function getColor(option, key)
  return function()
    if option[key] then
      return unpack(option[key])
    end
  end
end

local function getUserColor(data, config, option)
  if option[references] then
    return function()
      local firstValue
      for childID in pairs(option[references]) do
        local childConfig = data[childID].config
        if firstValue == nil then
          firstValue = childConfig[option.key]
        elseif neq(firstValue, childConfig[option.key]) then
          return
        end
        if firstValue then
          return unpack(firstValue)
        end
      end
    end
  else
    return function()
      if config[option.key] then
        return unpack(config[option.key])
      end
    end
  end
end

-- setters for AceConfig
local function set(data, option, key)
  if option[references] then
    return function(_, value)
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        childOption[key] = value
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      option[key] = value
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setKey(data, option, key, conflicts)
  if option[references] then
    return function(_, value)
      local isConflict = false
      for childID, conflictingKeys in pairs(conflicts) do
        if conflictingKeys[key] then
          isConflict = true
          break
        end
      end
      if isConflict then
        value = value:gsub("^|cFFFF0000", "", 1)
      end
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        childOption.key = value
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      if conflicts and conflicts[option.key] then
        option.key = value:gsub("^|cFFFF0000", "", 1)
      else
        option.key = value
      end
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setUser(data, config, option)
  if option[references] then
    return function(_, value)
      for childID in pairs(option[references]) do
        local childData = data[childID]
        local childConfig = childData.config
        childConfig[option.key] = value
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      config[option.key] = value
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setStr(data, option, key)
  if option[references] then
    return function(_, value)
      value = value:gsub("||", "|")
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        childOption[key] = value
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      value = value:gsub("||", "|")
      option[key] = value
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setNum(data, option, key, required)
  if option[references] then
    return function(_, value)
      if value ~= "" then
        local num = tonumber(value)
        if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          childOption[key] = num
          WeakAuras.Add(childData)
        end
      elseif not required then
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          childOption[key] = nil
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      if value ~= "" then
        local num = tonumber(value)
        if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
        option[key] = num
      elseif not required then
        option[key] = nil
      end
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setUserNum(data, config, option)
  if option[references] then
    return function(_, value)
      if value ~= "" then
        local num = tonumber(value)
        if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
        for childID in pairs(option[references]) do
          local childData = data[childID]
          local childConfig = childData.config
          childConfig[option.key] = num
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      if value ~= "" then
        local num = tonumber(value)
        if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
        config[option.key] = num
      end
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setColor(data, option, key)
  if option[references] then
    return function(_, r, g, b, a)
      local color = {r, g, b, a}
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        childOption[key] = color
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, r, g, b, a)
      option[key] = {r, g, b, a}
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setUserColor(data, config, option)
  if option[references] then
    return function(_, r, g, b, a)
      local color = {r, g, b, a}
      for childID in pairs(option[references]) do
        local childData = data[childID]
        local childConfig = childData.config
        childConfig[option.key] = color
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, r, g, b, a)
      config[option.key] = {r, g, b, a}
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setSelectDefault(data, option, key)
  if option[references] then
    return function(_, value)
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        childOption.default = min(value, #childOption.values)
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function(_, value)
      option.default = value
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local typeControlAdders = {
  toggle = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      values = WeakAuras.bool_types,
      get = function()
        if option.default == nil then return end
        return option.default and 1 or 0
      end,
      set = function(_, value)
        if option[references] then
          local val = value == 1
          for childID, optionID in pairs(option[references]) do
            local childData = data[childID]
            local childOption = childData.authorOptions[optionID]
            childOption.default = val
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          option.default = value == 1
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end
    }
    order = order + 1
    return order
  end,
  input = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      get = get(option, "default"),
      set = set(data, option, "default"),
    }
    order = order + 1
    args["option" .. i .. "useLength"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = name(data, option, "useLength", L["Max Length"]),
      desc = desc(data, option, "useLength"),
      order = order,
      get = get(option, "useLength"),
      set = set(data, option, "useLength"),
    }
    order = order + 1
    args["option" .. i .. "length"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = name(data, option, "length", L["Length"]),
      desc = desc(data, option, "length"),
      order = order,
      min = 1,
      step = 1,
      softMax = 20,
      get = get(option, "length"),
      set = set(data, option, "length"),
      disabled = function() return not option.useLength end,
    }
    order = order + 1
    return order
  end,
  number = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      get = getNumAsString(option, "default"),
      set = setNum(data, option, "default", true),
    }
    order = order + 1

    args["option" .. i .. "min"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 /3,
      name = name(data, option, "min", L["Min"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min"),
    }
    order = order + 1

    args["option" .. i .. "max"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "max", L["Max"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max"),
    }
    order = order + 1

    args["option" .. i .. "step"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "step", L["Step Size"]),
      desc = desc(data, option, "step"),
      order = order,
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step"),
    }
    order = order + 1

    return order
  end,
  range = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      get = getNumAsString(option, "default"),
      set = setNum(data, option, "default"),
    }
    order = order + 1

    args["option" .. i .. "min"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "min", L["Min"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min"),
    }
    order = order + 1

    args["option" .. i .. "max"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "max", L["Max"]),
      desc = desc(data, option, "max"),
      order = order,
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max"),
    }
    order = order + 1

    args["option" .. i .. "step"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "step", L["Step Size"]),
      desc = desc(data, option, "step"),
      order = order,
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step"),
    }
    order = order + 1

    args["option" .. i .. "softmin"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "softMin", L["Soft Min"]),
      desc = desc(data, option, "softMin"),
      order = order,
      get = getNumAsString(option, "softMin"),
      set = setNum(data, option, "softMin"),
    }
    order = order + 1

    args["option" .. i .. "softmax"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 /3,
      name = name(data, option, "softMax", L["Soft Max"]),
      desc = desc(data, option, "softMax"),
      order = order,
      get = getNumAsString(option, "softMax"),
      set = setNum(data, option, "softMax"),
    }
    order = order + 1

    args["option" .. i .. "bigstep"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(data, option, "bigStep", L["Slider Step Size"]),
      desc = desc(data, option, "bigStep"),
      order = order,
      get = getNumAsString(option, "bigStep"),
      set = setNum(data, option, "bigStep"),
    }
    order = order + 1
    return order
  end,
  description = function(option, args, data, order, i)
    args["option" .. i .. "key"] = nil
    args["option" .. i .. "name"] = nil
    args["option" .. i .. "fontsize"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(data, option, "fontSize", L["Font Size"]),
      desc = desc(data, option, "fontSize"),
      order = order,
      values = WeakAuras.font_sizes,
      get = get(option, "fontSize"),
      set = set(data, option, "fontSize"),
    }
    order = order + 1
    args["option" .. i .. "descinput"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = name(data, option, "text", L["Description Text"]),
      desc = desc(data, option, "text"),
      order = order,
      multiline = true,
      get = getStr(option, "text"),
      set = setStr(data, option, "text")
    }
    order = order + 1
    return order
  end,
  color = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "color",
      width = WeakAuras.normalWidth,
      hasAlpha = true,
      name = name(data, option, "default", L["Default"]),
      desc = descColor(data, option, "default"),
      order = order,
      get = getColor(option, "default"),
      set = setColor(data, option, "default")
    }
    order = order + 1
    return order
  end,
  select = function(option, args, data, order, i)
    local values = getValues(data, option)
    local defaultValues = {}
    for i, v in ipairs(values) do
      if v == conflict then
        defaultValues[i] = conflictBlue .. L["Value %i"]:format(i)
      else
        defaultValues[i] = v
      end
    end
    args["option" .. i .. "default"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      values = defaultValues,
      get = get(option, "default"),
      set = setSelectDefault(data, option),
    }
    order = order + 1
    for j, value in ipairs(values) do
      args["option" .. i .. "space" .. j] = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Value %i"]:format(j),
        order = order,
        disabled = function() return true end,
        get = function() return true end,
        set = function() end,
      }
      order = order + 1
      args["option" .. i .. "value" .. j] = {
        type = "input",
        width = WeakAuras.normalWidth - 0.15,
        name = (value == conflict and conflictBlue or "") .. L["Value %i"]:format(j),
        desc = descSelect(data, option, j, conflict),
        order = order,
        get = function()
          if value ~= conflict then
            return value:gsub("|", "||")
          end
        end,
        set = function(_, value)
          value = value:gsub("||", "|")
          if option[references] then
            for childID, optionID in pairs(option[references]) do
              local childData = data[childID]
              local childOption = childData.authorOptions[optionID]
              local insertPoint = math.min(j, #childOption.values + 1)
              if value == "" then
                tremove(childOption.values, insertPoint)
              else
                childOption.values[insertPoint] = value
              end
              WeakAuras.Add(childData)
            end
            WeakAuras.ReloadTriggerOptions(data[0])
          else
            if value == "" then
              tremove(values, j)
            else
              values[j] = value
            end
            WeakAuras.Add(data)
            WeakAuras.ReloadTriggerOptions(data)
          end
        end
      }
      order = order + 1
      args["option" .. i .. "valdelete" .. j] = {
        type = "execute",
        width = 0.15,
        name = L["Delete"],
        order = order,
        func = function()
          if option[references] then
            for childID, optionID in pairs(option[references]) do
              local childData = data[childID]
              local childOption = childData.authorOptions[optionID]
              tremove(childOption.values, j)
              WeakAuras.Add(childData)
            end
            WeakAuras.ReloadTriggerOptions(data[0])
          else
            tremove(values, j)
            WeakAuras.Add(data)
            WeakAuras.ReloadTriggerOptions(data)
          end
        end,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon"
      }
    end
    args["option" .. i .. "newvaluespace"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order,
      disabled = function() return true end,
      get = function() return true end,
      set = function() end,
    }
    order = order + 1
    args["option" .. i .. "newvalue"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order,
      get = function() return "" end,
      set = function(_, value)
        value = value:gsub("||", "|")
        if option[references] then
          for childID, optionID in pairs(option[references]) do
            local childData = data[childID]
            local childOption = childData.authorOptions[optionID]
            childOption.values[#childOption.values + 1] = value
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          values[#values + 1] = value
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end
    }
    order = order + 1
    return order
  end,
  space = function(option, args, data, order, i)
    -- this option should be just useWidth but no need to do a migration in the data just for that.
    args["option" .. i .. "variableWidth"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = order,
      name = name(data, option, "variableWidth", L["Width"]),
      desc = desc(data, option, "variableWidth", L["If unchecked, then this space will fill the entire line it is on in User Mode."]),
      get = get(option, "variableWidth"),
      set = set(data, option, "variableWidth"),
    }
    order = order + 1
    args["option" .. i .. "widthSpace"] = nil

    local widthOption = args["option" .. i .. "width"]
    widthOption.name = name(data, option, "width", L["Width"])
    widthOption.disabled = function() return not option.variableWidth end
    widthOption.order = order
    order = order + 1

    args["option" .. i .. "useHeight"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = order,
      name = name(data, option, "useHeight", L["Height"]),
      desc = desc(data, option, "useHeight", L["If checked, then this space will span across multiple lines."]),
      get = get(option, "useHeight"),
      set = set(data, option, "useHeight"),
    }
    order = order + 1

    args["option" .. i .. "height"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      order = order,
      name = name(data, option, "height", L["Height"]),
      desc = desc(data, option, "height"),
      get = get(option, "height"),
      set = set(data, option, "height"),
      disabled = function() return not option.useHeight end,
      min = 1,
      softMax = 10,
      step = 1,
    }
    order = order + 1
    return order
  end,
  multiselect = function(option, args, data, order, i)
    args["option" .. i .. "width"] = nil
    local values = getValues(data, option)
    local defaultValues = {}
    for i, v in ipairs(values) do
      if v == conflict then
        defaultValues[i] = conflictBlue .. L["Value %i"]:format(i)
      else
        defaultValues[i] = v
      end
    end
    args["option" .. i .. "default"] = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Default"],
      order = order,
      values = defaultValues,
      get = function(_, k)
        return option.default and option.default[k]
      end,
      set = function(_, k, v)
        if option[references] then
          for childID, optionID in pairs(option[references]) do
            local childData = data[childID]
            local childOption = childData.authorOptions[optionID]
            childOption.default[k] = v
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          option.default[k] = v
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end,
    }
    order = order + 1
    for j, value in ipairs(values) do
      args["option" .. i .. "space" .. j] = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Value %i"]:format(j),
        order = order,
        disabled = function() return true end,
        get = function() return true end,
        set = function() end,
      }
      order = order + 1
      args["option" .. i .. "value" .. j] = {
        type = "input",
        width = WeakAuras.normalWidth - 0.15,
        name = (value == conflict and conflictBlue or "") .. L["Value %i"]:format(j),
        desc = descSelect(data, option, j, conflict),
        order = order,
        get = function()
          if value ~= conflict then
            return value:gsub("|", "||")
          end
        end,
        set = function(_, value)
          value = value:gsub("||", "|")
          if option[references] then
            for childID, optionID in pairs(option[references]) do
              local childData = data[childID]
              local childOption = childData.authorOptions[optionID]
              local insertPoint = math.min(j, #childOption.values + 1)
              if value == "" then
                tremove(childOption.values, insertPoint)
                tremove(childOption.default, insertPoint)
              else
                childOption.values[insertPoint] = value
              end
              WeakAuras.Add(childData)
            end
            WeakAuras.ReloadTriggerOptions(data[0])
          else
            if value == "" then
              tremove(values, j)
              tremove(option.default, j, false)
            else
              values[j] = value
            end
            WeakAuras.Add(data)
            WeakAuras.ReloadTriggerOptions(data)
          end
        end
      }
      order = order + 1
      args["option" .. i .. "valdelete" .. j] = {
        type = "execute",
        width = 0.15,
        name = "",
        order = order,
        func = function()
          if option[references] then
            for childID, optionID in pairs(option[references]) do
              local childData = data[childID]
              local childOption = childData.authorOptions[optionID]
              tremove(childOption.values, j)
              tremove(childOption.default, j)
              WeakAuras.Add(childData)
            end
            WeakAuras.ReloadTriggerOptions(data[0])
          else
            tremove(values, j)
            tremove(option.default, j)
            WeakAuras.Add(data)
            WeakAuras.ReloadTriggerOptions(data)
          end
        end,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24
      }
    end
    args["option" .. i .. "newvaluespace"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order,
      disabled = function() return true end,
      get = function() return true end,
      set = function() end,
    }
    order = order + 1
    args["option" .. i .. "newvalue"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order,
      get = function() return "" end,
      set = function(_, value)
        value = value:gsub("||", "|")
        if option[references] then
          for childID, optionID in pairs(option[references]) do
            local childData = data[childID]
            local childOption = childData.authorOptions[optionID]
            childOption.values[#childOption.values + 1] = value
            childOption.default[#childOption.values + 1] = false
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          values[#values + 1] = value
          option.default[#option.default + 1] = false
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end
    }
    order = order + 1
    return order
  end,
  header = function(option, args, data, order, i)
    args["option" .. i .. "width"] = nil
    args["option" .. i .. "useName"] = {
      type = "toggle",
      name = name(data, option, "useName", L["Separator text"]),
      desc = desc(data, option, "useName", L["If checked, then this separator will include text. Otherwise, it will be just a horizontal line."]),
      order = order,
      width = WeakAuras.normalWidth,
      get = get(option, "useName"),
      set = set(data, option, "useName"),
    }
    order = order + 1
    args["option" .. i .. "text"] = {
      type = "input",
      name = name(data, option, "text", L["Separator Text"]),
      desc = desc(data, option, "text"),
      order = order,
      width = WeakAuras.normalWidth,
      get = getStr(option, "text"),
      set = setStr(data, option, "text"),
      disabled = function() return not option.useName end,
    }
    order = order + 1
    return order
  end
}

local function up(data, option, index)
  if option[references] then
    return function()
      for _, optionID in pairs(option[references]) do
        if optionID <= 1 then return true end
      end
    end, function()
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        if childData then
          WeakAuras.MoveCollapseDataUp(childData.id, "author", optionID)
          childData.authorOptions[optionID], childData.authorOptions[optionID - 1] = childData.authorOptions[optionID - 1], childData.authorOptions[optionID]
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function()
      return index == 1
    end,
    function()
      WeakAuras.MoveCollapseDataUp(data.id, "author", index)
      data.authorOptions[index], data.authorOptions[index - 1] = data.authorOptions[index - 1], data.authorOptions[index]
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function down(data, option, index)
  if option[references] then
    return function()
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        if optionID >= #childData.authorOptions then return true end
      end
    end, function()
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        if childData then
          WeakAuras.MoveCollapseDataDown(childData.id, "author", optionID)
          childData.authorOptions[optionID], childData.authorOptions[optionID + 1] = childData.authorOptions[optionID + 1], childData.authorOptions[optionID]
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function()
      return index == #data.authorOptions
    end,
    function()
      WeakAuras.MoveCollapseDataDown(data.id, "author", index)
      data.authorOptions[index], data.authorOptions[index + 1] = data.authorOptions[index + 1], data.authorOptions[index]
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function delete(data, option, index)
  if option[references] then
    return function()
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        WeakAuras.RemoveCollapsed(childData.id, "author", optionID)
        tremove(childData.authorOptions, optionID)
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function()
      WeakAuras.RemoveCollapsed(data.id, "author", index)
      tremove(data.authorOptions, index)
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function duplicate(data, option, index)
  if option[references] then
    return function()
      for childID, optionID in pairs(option[references]) do
        local childData = data[childID]
        local childOption = childData.authorOptions[optionID]
        WeakAuras.InsertCollapsed(childData.id, "author", optionID + 1)
        tinsert(childData.authorOptions, optionID + 1, CopyTable(childOption))
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function()
      WeakAuras.InsertCollapsed(data.id, "author", index + 1)
      tinsert(data.authorOptions, index + 1, CopyTable(data.authorOptions[index]))
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function addControlsForOption(authorOptions, args, data, order, i, keyConflicts)
  -- add header controls
  local option = authorOptions[i]

  local collapsed = false
  if option[references] then
    for childID, optionID in pairs(option[references]) do
      local childData = data[childID]
      if WeakAuras.IsCollapsed(childData.id, "author", optionID, true) then
        collapsed = true
        break
      end
    end
  else
    collapsed = WeakAuras.IsCollapsed(data.id, "author", i, true)
  end

  args["option" .. i .. "collapse"] = {
    type = "execute",
    name = nameHead(data, option, option.name -- TODO: find a better way than a giant chain of or.
                                  or (option.type == "space" and L["Space"])
                                  or (option.type == "description" and L["Description"])
                                  or (option.type == "header" and L["Separator"])
                                  or L["Option #%i"]:format(i)),
    order = order,
    width = WeakAuras.doubleWidth - 0.6,
    func = function()
      if option[references] then
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          WeakAuras.SetCollapsed(childData.id, "author", optionID, not collapsed)
        end
        WeakAuras.ReloadTriggerOptions(data[0])
      else
        WeakAuras.SetCollapsed(data.id, "author", i, not collapsed)
        WeakAuras.ReloadTriggerOptions(data)
      end
    end,
    image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse" ,
    imageWidth = 18,
    imageHeight = 18,
    control = "WeakAurasExpand"
  }
  order = order + 1

  local upDisable, upFunc = up(data, option, i)
  args["option" .. i .. "up"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Up"],
    order = order,
    disabled = upDisable,
    func = upFunc,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  order = order + 1

  local downDisable, downFunc = down(data, option, i)
  args["option" .. i .. "down"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Down"],
    order = order,
    disabled = downDisable,
    func = downFunc,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  order = order + 1

  args["option" .. i .. "duplicate"] = {
    type = "execute",
    width = 0.15,
    name = L["Duplicate"],
    order = order,
    func = duplicate(data, option, i),
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\duplicate",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  order = order + 1

  args["option" .. i .. "delete"] = {
    type = "execute",
    width = 0.15,
    name = L["Delete"],
    order = order,
    func = delete(data, option, i),
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  order = order + 1

  if collapsed then
    return order
  end

  args["option" .. i .. "type"] = {
    type = "select",
    width = WeakAuras.doubleWidth,
    name = L["Option Type"],
    desc = descType(data, option),
    order = order,
    values = WeakAuras.author_option_types,
    get = get(option, "type"),
    set = function(_, value)
      if value == option.type then return end
      local author_option_fields = WeakAuras.author_option_fields
      local commonFields, newFields = author_option_fields.common, author_option_fields[value]
      local newClass = optionClasses[value]
      if option[references] then
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          for k in pairs(childOption) do
            if not commonFields[k] then
              childOption[k] = nil
            end
          end
          for k, v in pairs(newFields) do
            if type(v) == "table" then
              childOption[k] = CopyTable(v)
            else
              childOption[k] = v
            end
          end
          childOption.type = value
          if newClass == "noninteractive" then
            childOption.name = nil
            childOption.desc = nil
            childOption.key = nil
            childOption.useDesc = nil
            childOption.default = nil
          else
            -- don't use the optionID here if switching from a noninteractive type
            -- mostly because it would have a very non-intuitive effect
            -- the names and keys would likely not match anymore, and so
            -- the merged display would basically explode into a bunch of separate options
            childOption.name = childOption.name or ("Option %i"):format(i)
            childOption.key = childOption.key or ("option" .. i)
          end
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data[0])
      else
        for k in pairs(option) do
          if not commonFields[k] then
            option[k] = nil
          end
        end
        for k, v in pairs(newFields) do
          if type(v) == "table" then
            option[k] = CopyTable(v)
          else
            option[k] = v
          end
        end
        option.type = value
        if newClass == "noninteractive" then
          option.name = nil
          option.desc = nil
          option.key = nil
          option.useDesc = nil
          option.default = nil
        else
          option.name = option.name or ("Option %i"):format(i)
          option.key = option.key or ("option" .. i)
        end
        WeakAuras.Add(data)
        WeakAuras.ReloadTriggerOptions(data)
      end
    end
  }
  order = order + 1

  local optionClass = optionClasses[option.type]

  if optionClass == "simple" then
    args["option" .. i .. "name"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(data, option, "name", L["Display Name"]),
      desc = desc(data, option, "name"),
      order = order,
      get = getStr(option, "name"),
      set = setStr(data, option, "name"),
    }
    order = order + 1

    args["option" .. i .. "key"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(data, option, "key", L["Option key"]),
      desc = descKey(data, option, option.key, keyConflicts),
      order = order,
      get = getKey(option, option.key, keyConflicts),
      set = setKey(data, option, option.key, keyConflicts),
    }
    order = order + 1
    args["option" .. i .. "tooltipSpace"] = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = "",
      order = order,
    }
    order = order + 1
    args["option" .. i .. "usetooltip"] = {
      type = "toggle",
      name = name(data, option, "useDesc", L["Tooltip"]),
      order = order,
      width = WeakAuras.halfWidth,
      get = get(option, "useDesc"),
      set = set(data, option, "useDesc"),
    }
    order = order + 1
    args["option" .. i .. "tooltip"] = {
      type = "input",
      name = name(data, option, "desc", L["Tooltip Text"]),
      desc = desc(data, option, "desc"),
      order = order,
      width = WeakAuras.normalWidth * 1.5,
      get = getStr(option, "desc"),
      set = setStr(data, option, "desc"),
      disabled = function() return not option.useDesc end,
    }
    order = order + 1
  end

  args["option" .. i .. "width"] = {
    type = "range",
    width = WeakAuras.normalWidth,
    name = name(data, option, "width", L["Width"]),
    desc = desc(data, option, "width"),
    order = order,
    min = 0.1,
    max = 2,
    step = 0.05,
    get = get(option, "width"),
    set = set(data, option, "width")
  }
  order = order + 1

  local addControlsForType = typeControlAdders[option.type]
  if addControlsForType then
    order = addControlsForType(option, args, data, order, i)
  end

  return order
end

local function addUserModeOption(options, config, args, data, order, i)
  local option = options[i]
  local optionType = option.type
  local optionClass = optionClasses[optionType]
  local userOption

  if optionClass == "simple" then
    userOption = {
      type = optionType,
      name = nameUser(data, config, option),
      desc = descUser(data, option),
      width = (option.width or 1) * WeakAuras.normalWidth,
      order = order,
      get = getUser(data, config, option),
      set = setUser(data, config, option)
    }
  elseif optionClass == "noninteractive" then
    userOption = {
      type = "description",
      order = order,
      name = "",
      width = (option.width or 1) * WeakAuras.normalWidth,
    }
  end
  args["userOption" .. i] = userOption
  order = order + 1

  -- convert from weakauras option type to ace option type
  if optionClass == "simple" then
    if optionType == "toggle" then
    elseif optionType == "input" then
    elseif optionType == "number" then
      userOption.type = "input"
      userOption.get = getUserNum(data, config, option)
      userOption.set = setUserNum(data, config, option, true)
    elseif optionType == "range" then
      userOption.softMax = option.softMax
      userOption.softMin = option.softMin
      userOption.bigStep = option.bigStep
      userOption.min = option.min
      userOption.max = option.max
      if userOption.max and userOption.min then
        userOption.max = max(userOption.min, userOption.max)
      end
      userOption.step = option.step
    elseif optionType == "color" then
      userOption.hasAlpha = true
      userOption.get = getUserColor(data, config, option)
      userOption.set = setUserColor(data, config, option)
    elseif optionType == "select" then
      userOption.values = getUserValues(data, option)
    elseif optionType == "multiselect" then
      userOption.values = getUserValues(data, option)
      userOption.get = function(_, k)
        return config[option.key][k]
      end
      userOption.set = function(_, k, v)
        if config[references] then
          for childID in pairs(config[references][option.key]) do
            data[childID].config[option.key][k] = v
            WeakAuras.Add(data[childID])
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          config[option.key][k] = v
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end
    end
  elseif optionClass == "noninteractive" then
    if optionType == "header" then
      userOption.type = "header"
      if option[references] then
        local name = {}
        local firstName = nil
        local conflict = false
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          if childOption.useName and #childOption.text > 0 then
            if firstName == nil then
              firstName = childOption.text
              tinsert(name, (childOption.text:gsub("||", "|")))
            elseif childOption.text ~= firstName then
              conflict = true
              tinsert(name, (childOption.text:gsub("||", "|")))
            end
          end
        end
        userOption.name = (conflict and conflictBlue or "") .. tconcat(name, " / ")
      else
        userOption.name = option.useName and (option.text or ""):gsub("||", "|") or ""
      end
    elseif optionType == "description" then
      userOption.name = nameUserDesc(data, option)
      userOption.fontSize = option.fontSize
    elseif optionType == "space" then
      if not option.variableWidth then
        userOption.width = "full"
      end
      if option.useHeight and option.height > 1 then
        userOption.name = string.rep("\n", option.height - 1)
      else
        userOption.name = " "
      end
    end
  end

  return order
end

local function mergeOptions(childIndex, merged, toMerge)
  local nextInsert = 1
  for i = 1, #toMerge do
    -- find the best place to start inserting the next option to merge
    local nextToMerge = toMerge[i]
    local shouldMerge = false
    for j = nextInsert, #merged + 1 do
      if not merged[j] then break end -- no more options to check, so must insert
      if nextToMerge.type == merged[j].type
      and nextToMerge.key == merged[j].key
      and nextToMerge.name == merged[j].name then
        shouldMerge = true
        nextInsert = j
        break
      end
    end
    -- now we know at what point to add nextToMerge
    if shouldMerge then
      local mergedOption = merged[nextInsert]
      -- nil out all fields which aren't the same
      for k, v in pairs(nextToMerge) do
        if neq(mergedOption[k], v) then
          mergedOption[k] = nil
        end
      end
      mergedOption[references][childIndex] = i
    else
      -- can't merge, should insert instead
      local newOption = CopyTable(nextToMerge)
      newOption[references] = {[childIndex] = i}
      tinsert(merged, nextInsert, newOption)
    end
    -- nexver merge 2 options from the same child
    nextInsert = nextInsert + 1
  end
end

local function valuesAreEqual(t1, t2)
  if t1 == t2 then return true end
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= "table" then return false end

  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not valuesAreEqual(v1, v2) then return false end
  end

  for k2, v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not valuesAreEqual(v1, v2) then return false end
  end
  return true
end

local function allChoicesAreDefault(data, options)
  for _, option in ipairs(options) do
    if optionClasses[option.type] ~= "noninteractive" then
      if option[references] then
        for childID, optionID in pairs(option[references]) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          local childConfig = childData.config
          if not valuesAreEqual(childOption.default, childConfig[option.key]) then
            return false
          end
        end
      else
        if not valuesAreEqual(option.default, data.config[option.key]) then
          return false
        end
      end
    end
  end
  return true
end

local function findConflictingKeys(options)
  local conflicted, indices, firstIndices = false, {}, {}
  for index, option in ipairs(options) do
    if optionClasses[option.type] == "noninteractive" then
    elseif not firstIndices[option.key] then
      firstIndices[option.key] = {[index] = true}
    else
      conflicted = true
      indices[option.key] = firstIndices[option.key]
      indices[option.key][index] = true
    end
  end
  return conflicted and indices
end

function WeakAuras.GetAuthorOptions(data, args, startorder)
  if data.controlledChildren then
    local isAuthorMode = true
    for i = 1, #data.controlledChildren do
      local childData = WeakAuras.GetData(data.controlledChildren[i])
      if childData and not childData.authorMode then
        isAuthorMode = false
        break
      end
    end
    local mergedOptions = {}
    local allData = {[0] = data}
    -- merge child options into one
    local keyConflicts = {}
    for i, childID in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childID)
      local childOptions = childData and childData.authorOptions
      allData[i] = childData
      if childOptions then
        mergeOptions(i, mergedOptions, childOptions)
        keyConflicts[i] = findConflictingKeys(childOptions)
      end
    end
    if isAuthorMode then
      local order = startorder + 2
      for i = 1, #mergedOptions do
        order = addControlsForOption(mergedOptions, args, allData, order, i, keyConflicts)
      end
      args["addOption"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Add Option"],
        order = order,
        func = function()
          for _, childData in ipairs(allData) do
            local i = #childData.authorOptions + 1
            childData.authorOptions[i] = {
              type = "toggle",
              key  = "option" .. i,
              name = L["Option %i"]:format(i),
              default = false,
              width = 1,
              useDesc = false,
            }
            WeakAuras.SetCollapsed(childData.id, "author", i, false)
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end
      }

      args["enterUserMode"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Enter User Mode"],
        desc = L["Enter user mode."],
        order = startorder,
        func = function()
          for _, childData in ipairs(allData) do
            childData.authorMode = nil
            WeakAuras.Add(data)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end
      }
      args["enterUserModeSpacer"] = {
        type = "description",
        name = "",
        order = startorder + 1,
      }
    else
      local order = startorder
      for i = 1, #mergedOptions do
        order = addUserModeOption(mergedOptions, nil, args, allData, order, i)
      end
      args["userConfigFooter"] = {
        type = "header",
        name = "",
        order = order,
      }
      order = order + 1
      args["resetAllToDefault"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Reset ALL to Defaults"],
        desc = L["Reset all options in this group to their default values."],
        order = order,
        func = function()
          for i = 1, #data.controlledChildren do
            local childData = WeakAuras.GetData(data.controlledChildren[i])
            wipe(childData.config)
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
        hidden = function()
          return #mergedOptions == 0 or allChoicesAreDefault(allData, mergedOptions)
        end,
      }
      order = order + 1
      args["enterAuthorModeAll"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Enter Author Mode"],
        desc = L["Configure what options appear on this pannel."],
        order = order,
        func = function()
          for i = 1, #data.controlledChildren do
            local childData = WeakAuras.GetData(data.controlledChildren[i])
            childData.authorMode = true
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
      }
    end
  else
    local authorOptions = data.authorOptions
    if not data.authorMode then
      local order = startorder
      local config = data.config
      for i = 1, #authorOptions do
        order = addUserModeOption(authorOptions, config, args, data, order, i)
      end
      args["resetToDefault"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Reset to Defaults"],
        desc = L["Reset all options to their default values."],
        order = order,
        func = function()
          wipe(data.config)
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end,
        hidden = function() return allChoicesAreDefault(data, authorOptions) end
      }
      order = order + 1
      args[data.id .. "footer"] = {
        type = "header",
        name = "",
        order = order,
      }
      order = order + 1
      args["enterAuthorMode"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Enter Author Mode"],
        desc = L["Configure what options appear on this pannel."],
        order = order,
        func = function()
          data.authorMode = true
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end,
      }
    else
      local order = startorder + 2
      local config = data.config
      order = order + 1
      local keyConflicts = findConflictingKeys(authorOptions)
      for i = 1, #authorOptions do
        order = addControlsForOption(authorOptions, args, data, order, i, keyConflicts)
      end
      args["addOption"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Add Option"],
        order = order,
        func = function()
          local i = #authorOptions + 1
          authorOptions[i] = {
            type = "toggle",
            key  = "option" .. i,
            name = L["Option %i"]:format(i),
            default = false,
            width = 1,
          }
          WeakAuras.SetCollapsed(data.id, "author", i, false)
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      }

      args["enterUserMode"] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = L["Enter User Mode"],
        desc = L["Enter user mode."],
        order = startorder,
        func = function()
          data.authorMode = nil
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      }
      args["enterUserModeSpacer"] = {
        type = "description",
        name = "",
        order = startorder + 1,
      }
    end
  end
  return args
end
