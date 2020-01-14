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
    group -> represents a group of options.
      useCollapse (optional) -> if true, then group will have a collapsible header in user mode.
      collapse (optional) -> whether or not the collapsible header begins collapsed when the user begins a session.
      subOptions (required) -> array of options
      groupType (required) -> type of group:
        simple -> group is for organizational purposes only.
                  config value is a sub config
        array -> group represents an array of entries from the user, with similar information between them:
                 config value is arranged as an array of sub configs, one for each entry in the array.
          limitType (required) -> Specifies if user can add or remove entries from the array freely
          size (optional) -> required if the limitType is not "none".
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
if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local L = WeakAuras.L

local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local conflictBlue = "|cFF4080FF"
local conflict = {} -- magic value

local optionClasses = WeakAuras.author_option_classes

local function atLeastOneSet(references, key)
  for id, optionData in pairs(references) do
    local childOption = optionData.options[optionData.index]
    if childOption[key] ~= nil then
      return true
    end
  end
end

local function neq(a, b)
  if type(a) == "table" and type(b) == "table" then
    for k, v in pairs(a) do
      if neq(v, b[k]) then
        return true
      end
    end
    for k, v in pairs(b) do
      if neq(v, a[k]) then
        return true
      end
    end
  else
    return a ~= b
  end
end

-- blues the name if there are conflicts between the references for this value
local function name(option, key, name, phrase)
  local header = name or phrase
  if option[key] ~= nil or not atLeastOneSet(option.references, key) then
    return header
  else
    return conflictBlue .. header
  end
end

-- blue if at least one member of the group does not have an option in the references
local function nameHead(data, option, phrase)
  if not data.controlledChildren then
    return phrase
  else
    for _, id in ipairs(data.controlledChildren) do
      if not option.references[id] then
        return conflictBlue .. phrase
      end
    end
  end
  return phrase
end

local function nameUser(option)
  local firstValue
  for id, optionData in pairs(option.references) do
    local childConfig = optionData.config
    if not childConfig then
      return option.name
    elseif firstValue == nil then
      firstValue = childConfig[option.key]
    elseif neq(firstValue, childConfig[option.key]) then
      return conflictBlue .. option.name
    end
  end
  return option.name
end

local function nameUserDesc(option)
  if option.text then
    return option.text
  else
    local text = {}
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      if childOption.text and childOption.text ~= nil then
        tinsert(text, childOption.text)
      end
    end
    return conflictBlue .. tconcat(text, "\n")
  end
end

local function nameArray(option, array, index, phrase)
  local value
  for id, optionData in pairs(option.references) do
    local childOption = optionData.options[optionData.index]
    if not childOption[array] then
      return conflictBlue .. phrase
    elseif childOption[array][index] == nil then
      return conflictBlue .. phrase
    elseif value == nil then
      value = childOption[array][index]
    elseif value ~= childOption[array][index] then
      return conflictBlue .. phrase
    end
  end
  return phrase
end

-- provides a tooltip showing all the conflicting values if there are any
local function desc(option, key, phrase)
  if option[key] or not atLeastOneSet(option.references, key) then
    return phrase
  else
    local desc = {}
    if phrase then
      desc[1] = phrase
    end
    tinsert(desc, L["Values:"])
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      if childOption[key] ~= nil then
        tinsert(
          desc,
          ("%s #%i: %s"):format(childData.id, optionData.path[#optionData.path], tostring(childOption[key]))
        )
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descType(option)
  local desc = {
    L["This setting controls what widget is generated in user mode."],
    L["Used in Auras:"]
  }
  for id, optionData in pairs(option.references) do
    tinsert(desc, ("%s - Option %i"):format(id, optionData.path[#optionData.path]))
  end
  return tconcat(desc, "\n")
end

local function descSelect(option, key)
  if option.values then
    return ""
  else
    local desc = {L["Values:"]}
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      if childOption.values[key] ~= nil then
        tinsert(
          desc,
          ("%s %i: - %s"):format(id, optionData.path[#optionData.path], tostring(childOption.values[key]))
        )
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descColor(option, key)
  if option[key] or not atLeastOneSet(option.references, key) then
    return L["Values are in normalized rgba format."]
  else
    local desc = {
      L["Values are in normalized rgba format."],
      L["Values:"]
    }
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      if childOption[key] ~= nil then
        tinsert(
          desc,
          ("%s #%i: %.2f %.2f %.2f %.2f"):format(
            id,
            childOption.path[#childOption.path],
            unpack(childOption[key])
          )
        )
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descUser(option)
  if option.useDesc ~= nil and option.desc ~= nil then
    return option.useDesc and option.desc or nil
  else
    local desc = {}
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      if childOption.useDesc and childOption.desc and childOption.desc ~= "" then
        tinsert(desc, ("%s - %s"):format(id, childOption.desc))
      end
    end
    return tconcat(desc, "\n")
  end
end

local function descArray(option, array, index, phrase)
  local desc, values, isConflict = {phrase}, {}, false
  local initialValue = nil
  for id, optionData in pairs(option.references) do
    local childOption = optionData.options[optionData.index]
    values[id] = tostring(childOption[array][index])
    if initialValue == nil then
      initialValue = values[id]
    elseif values[id] ~= initialValue then
      isConflict = true
    end
  end
  if isConflict then
    for id, value in pairs(values) do
      tinsert(desc, ("%s - %s"):format(id,  value))
    end
  end
  return tconcat(desc, "\n")
end

-- getters for AceConfig
local function get(option, key)
  return function()
    return option[key]
  end
end

local function getUser(option)
  return function()
    local value
    for id, optionData in pairs(option.references) do
      if not optionData.config then
        return
      elseif value == nil then
        value = optionData.config[option.key]
      elseif neq(value, optionData.config[option.key]) then
        return
      end
    end
    return value
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

local function getUserNumAsString(option)
  return function()
    local value
    for id, optionData in pairs(option.references) do
      if value == nil then
        value = optionData.config[option.key]
      elseif neq(value, optionData.config[option.key]) then
        return ""
      end
    end
    if value ~= nil then
      return tostring(value)
    end
  end
end

local function getValues(option)
  local values = {}
  local firstChild = true
  for id, optionData in pairs(option.references) do
    local childOption = optionData.options[optionData.index]
    local childValues = childOption.values
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
  return values
end

local function getUserValues(option)
  local values = getValues(option)
  for i, v in ipairs(values) do
    if v == conflict then
      values[i] = conflictBlue .. L["Value %i"]:format(i)
    end
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

local function getUserColor(option)
  return function()
    local firstValue
    for id, optionData in pairs(option.references) do
      local childConfig = optionData.config
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
end

local function getArrayStr(option, array, index)
  return function()
    if option[array][index] then
      return option[array][index]:gsub("|","||")
    else
      return ""
    end
  end
end

-- setters for AceConfig
local function set(data, option, key)
  return function(_, value)
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      childOption[key] = value
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setUser(data, option)
  return function(_, value)
    for id, optionData in pairs(option.references) do
      local childData = optionData.data
      local childConfig = optionData.config
      childConfig[option.key] = value
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setStr(data, option, key)
  return function(_, value)
    value = value:gsub("||", "|")
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      childOption[key] = value
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setNum(data, option, key, required)
  return function(_, value)
    if value ~= "" then
      local num = tonumber(value)
      if not num or math.abs(num) == math.huge or tostring(num) == "nan" then
        return
      end
      for id, optionData in pairs(option.references) do
        local childOption = optionData.options[optionData.index]
        local childData = optionData.data
        childOption[key] = num
        WeakAuras.Add(childData)
      end
    elseif not required then
      for id, optionData in pairs(option.references) do
        local childOption = optionData.options[optionData.index]
        local childData = optionData.data
        childOption[key] = nil
        WeakAuras.Add(childData)
      end
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setUserNum(data, option)
  return function(_, value)
    if value ~= "" then
      local num = tonumber(value)
      if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
      for id, optionData in pairs(option.references) do
        local childData = optionData.data
        local childConfig = optionData.config
        childConfig[option.key] = num
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function setColor(data, option, key)
  return function(_, r, g, b, a)
    local color = {r, g, b, a}
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      childOption[key] = color
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setUserColor(data, option)
  return function(_, r, g, b, a)
    local color = {r, g, b, a}
    for id, optionData in pairs(option.references) do
      local childData = optionData.data
      local childConfig = optionData.config
      childConfig[option.key] = color
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setSelectDefault(data, option, key)
  return function(_, value)
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      childOption.default = min(value, #childOption.values)
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function setArrayStr(data, option, array, index)
  return function(_, value)
    value = value:gsub("||","|")
    for id, optionData in pairs(option.references) do
      local childOption = optionData.options[optionData.index]
      local childData = optionData.data
      childOption[array][index] = value
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local typeControlAdders, addAuthorModeOption
typeControlAdders = {
  toggle = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "default"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(option, "default", L["Default"]),
      desc = desc(option, "default"),
      order = order(),
      values = WeakAuras.bool_types,
      get = function()
        if option.default == nil then
          return
        end
        return option.default and 1 or 0
      end,
      set = function(_, value)
        local val = value == 1
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.default = val
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
  end,
  input = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "default"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(option, "default", L["Default"]),
      desc = desc(option, "default"),
      order = order(),
      get = get(option, "default"),
      set = set(data, option, "default")
    }
    args[prefix .. "useLength"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = name(option, "useLength", L["Max Length"]),
      desc = desc(option, "useLength"),
      order = order(),
      get = get(option, "useLength"),
      set = set(data, option, "useLength")
    }
    args[prefix .. "length"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = name(option, "length", L["Length"]),
      desc = desc(option, "length"),
      order = order(),
      min = 1,
      step = 1,
      softMax = 20,
      get = get(option, "length"),
      set = set(data, option, "length"),
      disabled = function()
        return not option.useLength
      end
    }
    args[prefix .. "multiline"] = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = name(option, "multiline", L["Large Input"]),
      desc = desc(option, "multiline", L["If checked, then the user will see a multi line edit box. This is useful for inputting large amounts of text."]),
      order = order(),
      get = get(option, "multiline"),
      set = set(data, option, "multiline"),
    }
  end,
  number = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "default"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(option, "default", L["Default"]),
      desc = desc(option, "default"),
      order = order(),
      get = getNumAsString(option, "default"),
      set = setNum(data, option, "default", true)
    }
    args[prefix .. "min"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "min", L["Min"]),
      desc = desc(option, "min"),
      order = order(),
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min")
    }
    args[prefix .. "max"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "max", L["Max"]),
      desc = desc(option, "min"),
      order = order(),
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max")
    }
    args[prefix .. "step"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "step", L["Step Size"]),
      desc = desc(option, "step"),
      order = order(),
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step")
    }
  end,
  range = function(options, args, data, order, prefix, i)
    local option = options[i]
    local min, max, softMin, softMax, step, bigStep
    softMax = option.softMax
    softMin = option.softMin
    bigStep = option.bigStep
    min = option.min
    max = option.max
    if max and min then
      max = math.max(min, max)
    end
    step = option.step
    args[prefix .. "default"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = name(option, "default", L["Default"]),
      desc = desc(option, "default"),
      order = order(),
      get = get(option, "default"),
      set = set(data, option, "default"),
      min = min,
      max = max,
      step = step,
      softMin = softMin,
      softMax = softMax,
      bigStep = bigStep,
    }

    args[prefix .. "min"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "min", L["Min"]),
      desc = desc(option, "min"),
      order = order(),
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min")
    }

    args[prefix .. "max"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "max", L["Max"]),
      desc = desc(option, "max"),
      order = order(),
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max")
    }

    args[prefix .. "step"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "step", L["Step Size"]),
      desc = desc(option, "step"),
      order = order(),
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step")
    }

    args[prefix .. "softmin"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "softMin", L["Soft Min"]),
      desc = desc(option, "softMin"),
      order = order(),
      get = getNumAsString(option, "softMin"),
      set = setNum(data, option, "softMin")
    }

    args[prefix .. "softmax"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "softMax", L["Soft Max"]),
      desc = desc(option, "softMax"),
      order = order(),
      get = getNumAsString(option, "softMax"),
      set = setNum(data, option, "softMax")
    }

    args[prefix .. "bigstep"] = {
      type = "input",
      width = WeakAuras.normalWidth * 2 / 3,
      name = name(option, "bigStep", L["Slider Step Size"]),
      desc = desc(option, "bigStep"),
      order = order(),
      get = getNumAsString(option, "bigStep"),
      set = setNum(data, option, "bigStep")
    }
  end,
  description = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "key"] = nil
    args[prefix .. "name"] = nil
    args[prefix .. "fontsize"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(option, "fontSize", L["Font Size"]),
      desc = desc(option, "fontSize"),
      order = order(),
      values = WeakAuras.font_sizes,
      get = get(option, "fontSize"),
      set = set(data, option, "fontSize")
    }
    args[prefix .. "descinput"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = name(option, "text", L["Description Text"]),
      desc = desc(option, "text"),
      order = order(),
      multiline = true,
      get = getStr(option, "text"),
      set = setStr(data, option, "text")
    }
  end,
  color = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "default"] = {
      type = "color",
      width = WeakAuras.normalWidth,
      hasAlpha = true,
      name = name(option, "default", L["Default"]),
      desc = descColor(option, "default"),
      order = order(),
      get = getColor(option, "default"),
      set = setColor(data, option, "default")
    }
  end,
  select = function(options, args, data, order, prefix, i)
    local option = options[i]
    local values = getValues(option)
    local defaultValues = {}
    for i, v in ipairs(values) do
      if v == conflict then
        defaultValues[i] = conflictBlue .. L["Value %i"]:format(i)
      else
        defaultValues[i] = v
      end
    end
    args[prefix .. "default"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = name(option, "default", L["Default"]),
      desc = desc(option, "default"),
      order = order(),
      values = defaultValues,
      get = get(option, "default"),
      set = setSelectDefault(data, option)
    }
    for j, value in ipairs(values) do
      args[prefix .. "space" .. j] = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Value %i"]:format(j),
        order = order(),
        disabled = function()
          return true
        end,
        get = function()
          return true
        end,
        set = function()
        end
      }
      args[prefix .. "value" .. j] = {
        type = "input",
        width = WeakAuras.normalWidth - 0.15,
        name = (value == conflict and conflictBlue or "") .. L["Value %i"]:format(j),
        desc = descSelect(option, j, conflict),
        order = order(),
        get = function()
          if value ~= conflict then
            return value:gsub("|", "||")
          end
        end,
        set = function(_, value)
          value = value:gsub("||", "|")
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            local insertPoint = math.min(j, #childOption.values + 1)
            if value == "" then
              tremove(childOption.values, insertPoint)
            else
              childOption.values[insertPoint] = value
            end
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end
      }
      args[prefix .. "valdelete" .. j] = {
        type = "execute",
        width = 0.15,
        name = L["Delete"],
        order = order(),
        func = function()
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            tremove(childOption.values, j)
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon"
      }
    end
    args[prefix .. "newvaluespace"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order(),
      disabled = function()
        return true
      end,
      get = function()
        return true
      end,
      set = function()
      end
    }
    args[prefix .. "newvalue"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order(),
      get = function()
        return ""
      end,
      set = function(_, value)
        value = value:gsub("||", "|")
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.values[#childOption.values + 1] = value
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
  end,
  space = function(options, args, data, order, prefix, i)
    local option = options[i]
    -- this option should be just useWidth but no need to do a migration in the data just for that.
    args[prefix .. "variableWidth"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = order(),
      name = name(option, "variableWidth", L["Width"]),
      desc = desc(
        option,
        "variableWidth",
        L["If unchecked, then this space will fill the entire line it is on in User Mode."]
      ),
      get = get(option, "variableWidth"),
      set = set(data, option, "variableWidth")
    }
    args[prefix .. "widthSpace"] = nil

    local widthOption = args[prefix .. "width"]
    widthOption.name = name(option, "width", L["Width"])
    widthOption.disabled = function()
      return not option.variableWidth
    end
    widthOption.order = order()

    args[prefix .. "useHeight"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = order(),
      name = name(option, "useHeight", L["Height"]),
      desc = desc(option, "useHeight", L["If checked, then this space will span across multiple lines."]),
      get = get(option, "useHeight"),
      set = set(data, option, "useHeight")
    }

    args[prefix .. "height"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      order = order(),
      name = name(option, "height", L["Height"]),
      desc = desc(option, "height"),
      get = get(option, "height"),
      set = set(data, option, "height"),
      disabled = function()
        return not option.useHeight
      end,
      min = 1,
      softMax = 10,
      step = 1
    }
  end,
  multiselect = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "width"] = nil
    local values = getValues(option)
    local defaultValues = {}
    for i, v in ipairs(values) do
      if v == conflict then
        defaultValues[i] = conflictBlue .. L["Value %i"]:format(i)
      else
        defaultValues[i] = v
      end
    end
    args[prefix .. "default"] = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Default"],
      order = order(),
      values = defaultValues,
      get = function(_, k)
        return option.default and option.default[k]
      end,
      set = function(_, k, v)
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.default[k] = v
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
    for j, value in ipairs(values) do
      args[prefix .. "space" .. j] = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Value %i"]:format(j),
        order = order(),
        disabled = function()
          return true
        end,
        get = function()
          return true
        end,
        set = function()
        end
      }
      args[prefix .. "value" .. j] = {
        type = "input",
        width = WeakAuras.normalWidth - 0.15,
        name = (value == conflict and conflictBlue or "") .. L["Value %i"]:format(j),
        desc = descSelect(option, j, conflict),
        order = order(),
        get = function()
          if value ~= conflict then
            return value:gsub("|", "||")
          end
        end,
        set = function(_, value)
          value = value:gsub("||", "|")
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            local insertPoint = math.min(j, #childOption.values + 1)
            if value == "" then
              tremove(childOption.values, insertPoint)
              tremove(childOption.default, insertPoint)
            else
              childOption.values[insertPoint] = value
            end
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end
      }
      args[prefix .. "valdelete" .. j] = {
        type = "execute",
        width = 0.15,
        name = "",
        order = order(),
        func = function()
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            tremove(childOption.values, j)
            tremove(childOption.default, j)
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24
      }
    end
    args[prefix .. "newvaluespace"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order(),
      disabled = function()
        return true
      end,
      get = function()
        return true
      end,
      set = function()
      end
    }
    args[prefix .. "newvalue"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["New Value"],
      order = order(),
      get = function()
        return ""
      end,
      set = function(_, value)
        value = value:gsub("||", "|")
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.values[#childOption.values + 1] = value
          childOption.default[#childOption.default + 1] = false
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
  end,
  header = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "width"] = nil
    args[prefix .. "useName"] = {
      type = "toggle",
      name = name(option, "useName", L["Separator text"]),
      desc = desc(
        option,
        "useName",
        L["If checked, then this separator will include text. Otherwise, it will be just a horizontal line."]
      ),
      order = order(),
      width = WeakAuras.normalWidth,
      get = get(option, "useName"),
      set = set(data, option, "useName")
    }
    args[prefix .. "text"] = {
      type = "input",
      name = name(option, "text", L["Separator Text"]),
      desc = desc(option, "text"),
      order = order(),
      width = WeakAuras.normalWidth,
      get = getStr(option, "text"),
      set = setStr(data, option, "text"),
      disabled = function()
        return not option.useName
      end
    }
  end,
  group = function(options, args, data, order, prefix, i)
    local option = options[i]
    args[prefix .. "width"] = nil
    args[prefix .. "groupType"] = {
      type = "select",
      name = name(option, "groupType", L["Group Type"]),
      order = order(),
      width = WeakAuras.doubleWidth,
      values = WeakAuras.group_option_types,
      get = get(option, "groupType"),
      set = function(_, value)
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.groupType = value
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
    args[prefix .. "useCollapse"] = {
      type = "toggle",
      name = name(option, "useCollapse", L["Collapsible Group"]),
      desc = desc(option, "useCollapse", L["If checked, then this option group can be temporarily collapsed by the user."]),
      order = order(),
      width = WeakAuras.normalWidth,
      get = get(option, "useCollapse"),
      set = set(data, option, "useCollapse"),
    }
    args[prefix .. "collapseDefault"] = {
      type = "toggle",
      name = name(option, "collapse", L["Start Collapsed"]),
      desc = desc(option, "collapse", L["If checked, then this option group will start collapsed."]),
      order = order(),
      width = WeakAuras.normalWidth,
      get = get(option, "collapse"),
      set = function(_, value)
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          childOption.collapse = value
          WeakAuras.SetCollapsed(id, "config", optionData.path, value)
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end,
      disabled = function() return not option.useCollapse end
    }
    if option.groupType ~="simple" then
      args[prefix .. "limitType"] = {
        type = "select",
        name = name(option, "limitType", L["Number of Entries"]),
        desc = desc(option, "limitType", L["Determines how many entries can be in the table."]),
        order = order(),
        width = WeakAuras.normalWidth,
        values = WeakAuras.group_limit_types,
        get = get(option, "limitType"),
        set = function(_, value)
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            if childOption.limitType == "fixed" and childOption.nameSource == -1 and value ~= "fixed" then
              childOption.entryNames = nil
              childOption.nameSource = 0
            end
            childOption.limitType = value
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
      }
      args[prefix .. "size"] = {
        type = "range",
        name = name(option, "limitType", option.limitType == "max" and L["Entry limit"] or L["Number of Entries"]),
        desc = desc(option, "limitType"),
        order = order(),
        width = WeakAuras.normalWidth,
        min = 1, -- no point in a table with no entries
        softMax = 20, -- 20 people in a mythic raid group
        step = 1,
        get = get(option, "size"),
        set = function(_, value)
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            if childOption.nameSource == -1 then
              if value < childOption.size then
                for i = value + 1, childOption.size do
                  childOption.entryNames[i] = nil
                end
              else
                for i = childOption.size + 1, value do
                  childOption.entryNames[i] = L["Entry %i"]:format(i)
                end
              end
            end
            childOption.size = value
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
        disabled = function() return option.limitType == "none" end,
      }
      args[prefix .. "hideReorder"] = {
        type = "toggle",
        name = name(option, "hideReorder", L["Disallow Entry Reordering"]),
        desc = desc(option, "hideReorder"),
        order = order(),
        width = WeakAuras.normalWidth,
        get = function()
          return option.hideReorder or option.nameSource == -1
        end,
        set = set(data, option, "hideReorder"),
        disabled = function()
          return option.nameSource == -1
        end,
      }
      local nameSources = CopyTable(WeakAuras.array_entry_name_types)
      local validNameSourceTypes = WeakAuras.name_source_option_types
      if option.limitType ~= "fixed" then
        nameSources[-1] = nil
      end
      for subIndex, subOption in ipairs(option.subOptions) do
        if validNameSourceTypes[subOption.type] then
          local allShareThisOption = true
          for id in pairs(option.references) do
            if not subOption.references[id] then
              allShareThisOption = false
              break
            end
          end
          if allShareThisOption then
            nameSources[subIndex] = subOption.key
          end
        end
      end
      args[prefix .. "nameSource"] = {
        type = "select",
        name = name(option, "nameSource", L["Entry Name Source"]),
        desc = desc(option, "nameSource"),
        order = order(),
        values = nameSources,
        width = WeakAuras.doubleWidth,
        get = function()
          return option.nameSource or 0
        end,
        set = function(_, value)
          for id, optionData in pairs(option.references) do
            local childOption = optionData.options[optionData.index]
            local childData = optionData.data
            if (value == -1) ~= (childOption.nameSource == -1) then
              if value == -1 then
                local entryNames = {}
                for i = 1, childOption.size do
                  entryNames[i] = L["Entry %i"]:format(i)
                end
                childOption.entryNames = entryNames
              else
                childOption.entryNames = nil
              end
            end
            if value > 0 then
              childOption.nameSource = option.subOptions[value].references[id].index
            else
              childOption.nameSource = value
            end
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
      }
      if option.nameSource == -1 then
        for i = 1, option.size do
          args[prefix .. "entry" .. i .. "name"] = {
            type = "input",
            name = nameArray(option, "entryNames", i, L["Entry %i"]:format(i)),
            desc = descArray(option, "entryNames", i),
            order = order(),
            width = WeakAuras.doubleWidth,
            get = getArrayStr(option, "entryNames", i),
            set = setArrayStr(data, option, "entryNames", i),
          }
        end
      end
    end
    args[prefix .. "groupStart"] = {
      type = "header",
      name = L["Start of %s"]:format(option.name),
      order = order()
    }
    local subPrefix = prefix .. "option"
    for subIndex, subOption in ipairs(option.subOptions) do
      local addControlsForType = typeControlAdders[subOption.type]
      if addControlsForType then
        addAuthorModeOption(option.subOptions, args, data, order, subPrefix .. subIndex, subIndex)
      end
    end
    args[prefix .. "addSubOption"] = {
      type = "execute",
      name = L["Add Sub Option"],
      order = order(),
      width = WeakAuras.normalWidth,
      func = function()
        for id, optionData in pairs(option.references) do
          local childOption = optionData.options[optionData.index]
          local childData = optionData.data
          local path = optionData.path
          local j = #childOption.subOptions + 1
          path[#path + 1] = j
          childOption.subOptions[j] = {
            type = "toggle",
            key = "subOption" .. j,
            name = L["Sub Option %i"]:format(j),
            default = false,
            width = 1,
            useDesc = false,
          }
          WeakAuras.SetCollapsed(id, "author", path, false)
          WeakAuras.Add(childData)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
    args[prefix .. "groupEnd"] = {
      type = "header",
      name = L["End of %s"]:format(option.name),
      order = order()
    }
  end
}

local function up(data, options, index)
  local option = options[index]
  return function()
    for id, optionData in pairs(option.references) do
      if optionData.path[#optionData.path] <= 1 then
        return true
      end
    end
  end, function()
    for id, optionData in pairs(option.references) do
      -- move the option up in the subOptions
      local path = optionData.path
      local optionID = optionData.index
      local childData = optionData.data
      local childOptions = optionData.options
      WeakAuras.MoveCollapseDataUp(id, "author", path)
      childOptions[optionID], childOptions[optionID - 1] = childOptions[optionID - 1], childOptions[optionID]
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function down(data, options, index)
  local option = options[index]
  return function()
    for id, optionData in pairs(option.references) do
      if optionData.path[#optionData.path] >= #optionData.options then
        return true
      end
    end
  end, function()
    for id, optionData in pairs(option.references) do
      -- move the option up in the subOptions
      local path = optionData.path
      local optionID = optionData.index
      local childData = optionData.data
      local childOptions = optionData.options
      WeakAuras.MoveCollapseDataUp(id, "author", path)
      childOptions[optionID], childOptions[optionID + 1] = childOptions[optionID + 1], childOptions[optionID]
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function duplicate(data, options, index)
  local option = options[index]
  return function()
    for id, optionData in pairs(option.references) do
      local optionID = optionData.index
      local childOptions = optionData.options
      local childData = optionData.data
      local path = optionData.path
      path[#path] = path[#path] + 1 -- this data is being regenerated very soon
      WeakAuras.InsertCollapsed(id, "author", optionData.path, false)
      local newOption = CopyTable(childOptions[optionID])
      if newOption.key then
        local existingKeys = {}
        for _, option in ipairs(childOptions) do
          if option.key then
            existingKeys[option.key] = true
          end
        end
        while existingKeys[newOption.key] do
          newOption.key = newOption.key .. "copy"
        end
      end
      if newOption.name then
        newOption.name = newOption.name .. " - " .. L["Copy"]
      end
      tinsert(childOptions, optionID + 1, newOption)
      WeakAuras.Add(childData)
    end
    WeakAuras.ReloadTriggerOptions(data)
  end
end

local function ensureNonDuplicateKey(option)
  -- note: this has some unintuitive behavior
  -- e.g. if aura A has option keys "foo", "bar"
  -- and aura B has option keys "foo", "baz",
  -- then you still cannot change the merged option with key "foo" to "bar"
  -- unless you unselect aura A, even though aura B would be fine with that.
  return function(_, newKey)
    for id, optionData in pairs(option.references) do
      for index, otherOption in ipairs(optionData.options) do
        if index ~= optionData.index and otherOption.key == newKey then
          return L["%s - Option #%i has the key %s. Please choose a different option key."]:format(id, index, newKey)
        end
      end
    end
    return true
  end
end

function addAuthorModeOption(options, args, data, order, prefix, i)
  -- add header controls
  local option = options[i]

  local collapsed = false
  for id, optionData in pairs(option.references) do
    if WeakAuras.IsCollapsed(id, "author", optionData.path, true) then
      collapsed = true
      break
    end
  end

  local _, optionData = next(option.references)
  local isInGroup = optionData.parent ~= nil
  local buttonWidth = 0.6
  if isInGroup then
    buttonWidth = buttonWidth + 0.3
  end

  local optionBelow = options[i + 1]
  local isAboveGroup = optionBelow and optionClasses[optionBelow.type] == "group"
  if isAboveGroup then
    buttonWidth = buttonWidth + 0.15
  end

  local optionAbove = options[i - 1]
  local isBelowGroup = optionAbove and optionClasses[optionAbove.type] == "group"
  if isBelowGroup then
    buttonWidth = buttonWidth + 0.15
  end
  local optionClass = optionClasses[option.type]
  local optionName = optionClass == "noninteractive" and WeakAuras.author_option_types[option.type]
                     or option.name

  args[prefix .. "collapse"] = {
    type = "execute",
    name = nameHead(data, option, optionName),
    order = order(),
    width = WeakAuras.doubleWidth - buttonWidth,
    func = function()
      for id, optionData in pairs(option.references) do
        WeakAuras.SetCollapsed(id, "author", optionData.path, not collapsed)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or
      "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse",
    imageWidth = 18,
    imageHeight = 18,
    control = "WeakAurasExpand"
  }

  args[prefix .. "upAndIn"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Into Above Group"],
    order = order(),
    hidden = function() return not isBelowGroup end,
    func = function()
      for id, optionData in pairs(option.references) do
        local groupData = optionAbove.references[id]
        if groupData then
          local childGroup = groupData.options[groupData.index]
          local childCollapsed = WeakAuras.IsCollapsed(id, "author", optionData.path, true)
          WeakAuras.RemoveCollapsed(id, "author", optionData.path)
          local newPath = groupData.path
          tinsert(newPath, #childGroup.subOptions + 1)
          WeakAuras.InsertCollapsed(id, "author", newPath, childCollapsed)
          local childOption = tremove(optionData.options, optionData.index)
          local childData = optionData.data
          tinsert(childGroup.subOptions, childOption)
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\upright",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  args[prefix .. "downAndIn"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Into Below Group"],
    order = order(),
    hidden = function() return not isAboveGroup end,
    func = function()
      for id, optionData in pairs(option.references) do
        local groupData = optionBelow.references[id]
        if groupData then
          local childGroup = groupData.options[groupData.index]
          local childCollapsed = WeakAuras.IsCollapsed(id, "author", optionData.path, true)
          WeakAuras.RemoveCollapsed(id, "author", optionData.path)
          local newPath = groupData.path
          tinsert(newPath, 1)
          WeakAuras.InsertCollapsed(id, "author", newPath, childCollapsed)
          local childOption = tremove(optionData.options, optionData.index)
          local childData = optionData.data
          tinsert(childGroup.subOptions, 1, childOption)
          WeakAuras.Add(childData)
        end
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\downright",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }

  args[prefix .. "upAndOut"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Above Group"],
    order = order(),
    hidden = function() return not isInGroup end,
    func = function()
      for id, optionData in pairs(option.references) do
        local path = optionData.path
        local parentOptions = optionData.parent.options
        local childOption = tremove(optionData.options, optionData.index)
        local childCollapsed = WeakAuras.IsCollapsed(id, "author", optionData.path, true)
        WeakAuras.RemoveCollapsed(id, "author", optionData.path)
        tinsert(parentOptions, path[#path - 1], childOption)
        path[#path] = nil
        WeakAuras.InsertCollapsed(id, "author", path)
        WeakAuras.Add(optionData.data)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\upleft",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  args[prefix .. "downAndOut"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Below Group"],
    order = order(),
    hidden = function() return not isInGroup end,
    func = function()
      for id, optionData in pairs(option.references) do
        local path = optionData.path
        local parentOptions = optionData.parent.options
        local childOption = tremove(optionData.options, optionData.index)
        local childCollapsed = WeakAuras.IsCollapsed(id, "author", optionData.path, true)
        WeakAuras.RemoveCollapsed(id, "author", optionData.path)
        tinsert(parentOptions, path[#path - 1] + 1, childOption)
        path[#path] = nil
        path[#path] = path[#path] + 1
        WeakAuras.InsertCollapsed(id, "author", path)
        WeakAuras.Add(optionData.data)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\downleft",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }
  local upDisable, upFunc = up(data, options, i)
  args[prefix .. "up"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Up"],
    order = order(),
    disabled = upDisable,
    func = upFunc,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }

  local downDisable, downFunc = down(data, options, i)
  args[prefix .. "down"] = {
    type = "execute",
    width = 0.15,
    name = L["Move Down"],
    order = order(),
    disabled = downDisable,
    func = downFunc,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }

  args[prefix .. "duplicate"] = {
    type = "execute",
    width = 0.15,
    name = L["Duplicate"],
    order = order(),
    func = duplicate(data, options, i),
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\duplicate",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }

  args[prefix .. "delete"] = {
    type = "execute",
    width = 0.15,
    name = L["Delete"],
    order = order(),
    func = function()
      for id, optionData in pairs(option.references) do
        local childOptions = optionData.options
        local optionIndex = optionData.index
        local childData = optionData.data
        local parentOption = optionData.parent
        WeakAuras.RemoveCollapsed(id, "author", optionData.path)
        tremove(childOptions, optionIndex)
        if parentOption and parentOption.groupType == "array" then
          local dereferencedParent = parentOption.references[id]
          if dereferencedParent.nameSource == optionData.index then
            dereferencedParent.nameSource = 0
          end
        end
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  }

  if collapsed then return end

  args[prefix .. "type"] = {
    type = "select",
    width = WeakAuras.doubleWidth,
    name = L["Option Type"],
    desc = descType(option),
    order = order(),
    values = WeakAuras.author_option_types,
    get = get(option, "type"),
    set = function(_, value)
      if value == option.type then
        return
      end
      local author_option_fields = WeakAuras.author_option_fields
      local commonFields, newFields = author_option_fields.common, author_option_fields[value]
      local newClass = optionClasses[value]
      for id, optionData in pairs(option.references) do
        local childOption = optionData.options[optionData.index]
        local childData = optionData.data
        local parentOption = optionData.parent
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
          -- don't use the option index here if switching from a noninteractive type
          -- mostly because it would have a very non-intuitive effect
          -- the names and keys would likely not match anymore, and so
          -- the merged display would basically explode into a bunch of separate options
          childOption.name = childOption.name or ("Option %i"):format(i)
          if not childOption.key then
            local newKey = "option" .. i
            local existingKeys = {}
            for index, option in pairs(optionData.options) do
              if index ~= optionData.index and option.key then
                existingKeys[option.key] = true
              end
            end
            while existingKeys[newKey] do
              newKey = newKey .. "copy"
            end
            childOption.key = newKey
          end
        end
        if parentOption and parentOption.groupType == "array" and not WeakAuras.array_entry_name_types[value] then
          local dereferencedParent = parentOption.references[id]
          if dereferencedParent.nameSource == optionData.index then
            dereferencedParent.nameSource = 0
          end
        end
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data)
    end
  }

  if optionClass ~= "noninteractive" then
    args[prefix .. "name"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(option, "name", L["Display Name"]),
      desc = desc(option, "name"),
      order = order(),
      get = getStr(option, "name"),
      set = setStr(data, option, "name")
    }

    args[prefix .. "key"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name(option, "key", optionClass == "group" and L["Group key"] or L["Option key"]),
      order = order(),
      validate = ensureNonDuplicateKey(option),
      get = get(option, "key"),
      set = set(data, option, "key")
    }
  end

  if optionClass == "simple" then
    args[prefix .. "tooltipSpace"] = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = "",
      order = order
    }
    args[prefix .. "usetooltip"] = {
      type = "toggle",
      name = name(option, "useDesc", L["Tooltip"]),
      order = order(),
      width = WeakAuras.halfWidth,
      get = get(option, "useDesc"),
      set = set(data, option, "useDesc")
    }
    args[prefix .. "tooltip"] = {
      type = "input",
      name = name(option, "desc", L["Tooltip Text"]),
      desc = desc(option, "desc"),
      order = order(),
      width = WeakAuras.normalWidth * 1.5,
      get = getStr(option, "desc"),
      set = setStr(data, option, "desc"),
      disabled = function()
        return not option.useDesc
      end
    }
  end

  args[prefix .. "width"] = {
    type = "range",
    width = WeakAuras.normalWidth,
    name = name(option, "width", L["Width"]),
    desc = desc(option, "width"),
    order = order(),
    min = 0.1,
    max = 2,
    step = 0.05,
    get = get(option, "width"),
    set = set(data, option, "width")
  }

  local addControlsForType = typeControlAdders[option.type]
  if addControlsForType then
    addControlsForType(options, args, data, order, prefix, i)
    local option = options[i]
  end
end

local groupPages = {}

local function getPage(id, path, max)
  max = max or math.huge
  groupPages[id] = groupPages[id] or {}
  local base = groupPages[id]
  for _, index in ipairs(path) do
    if not base[index] then
      base[index] = {}
    end
    base = base[index]
  end
  if not base.page or (max and base.page > max) then
    base.page = 1
  end
  return base.page
end

local function setPage(id, path, page)
  groupPages[id] = groupPages[id] or {}
  local base = groupPages[id]
  for _, index in ipairs(path) do
    if not base[index] then
      base[index] = {}
    end
    base = base[index]
  end
  base.page = page
end

local function addUserModeOption(options, args, data, order, prefix, i)
  local option = options[i]
  local optionType = option.type
  local optionClass = optionClasses[optionType]
  local userOption

  if optionClass == "simple" then
    userOption = {
      type = optionType,
      name = nameUser(option),
      desc = descUser(option),
      width = (option.width or 1) * WeakAuras.normalWidth,
      order = order(),
      get = getUser(option),
      set = setUser(data, option)
    }
  elseif optionClass == "noninteractive" then
    userOption = {
      type = "description",
      order = order(),
      name = "",
      width = (option.width or 1) * WeakAuras.normalWidth
    }
  elseif optionClass == "group" then
    local collapsed = false
    if option.useCollapse then
      local defaultCollapsed = true
      if option.collapse ~= nil then
        defaultCollapsed = option.collapse
      end
      for id, optionData in pairs(option.references) do
        if WeakAuras.IsCollapsed(id, "config", optionData.path, defaultCollapsed) then
          collapsed = true
          break
        end
      end
      args[prefix .. "collapse"] = {
        type = "execute",
        name = option.name,
        order = order(),
        width = WeakAuras.doubleWidth,
        func = function()
          for id, optionData in pairs(option.references) do
            WeakAuras.SetCollapsed(id, "config", optionData.path, not collapsed)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end,
        image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or
          "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse",
        imageWidth = 18,
        imageHeight = 18,
        control = "WeakAurasExpand"
      }
    end
    if not collapsed then
      local skipSubOptions = false
      if option.groupType == "array" then
        local values, firstChild = {}, true
        local nameSource = option.nameSource or 0
        if nameSource > 0 then
          nameSource = option.subOptions[option.nameSource].key
        end
        if nameSource == -1 then
          for id, optionData in pairs(option.references) do
            local i = 1
            local childOption = optionData.options[optionData.index]
            local entryNames = childOption.entryNames
            while i <= #values or i <= childOption.size do
              if firstChild then
                values[i] = entryNames[i]
              elseif values[i] ~= entryNames[i] then
                values[i] = conflictBlue .. L["Entry %i"]:format(i)
              end
              i = i + 1
            end
            firstChild = false
          end
        elseif nameSource == 0 then
          for id, optionData in pairs(option.references) do
            local i = 1
            local childOption = optionData.options[optionData.index]
            local childValues = optionData.config[childOption.key]
            while i <= #values or i <= #childValues do
              if firstChild then
                values[i] = L["Entry %i"]:format(i)
              elseif values[i] == nil or childValues[i] == nil then
                values[i] = conflictBlue .. L["Entry %i"]:format(i)
              end
              i = i + 1
            end
            firstChild = false
          end
        else
          for id, optionData in pairs(option.references) do
            local i = 1
            local childOption = optionData.options[optionData.index]
            local childValues = optionData.config[option.key]
            while i <= #values or i <= #childValues do
              if firstChild then
                values[i] = childValues[i][nameSource] or conflictBlue .. L["Entry %i"]:format(i)
              elseif childValues[i] ~= values[i] then
                values[i] = conflictBlue .. L["Entry %i"]:format(i)
              end
              i = i + 1
            end
            firstChild = false
          end
        end
        skipSubOptions = #values == 0
        local buttonWidth = 0.60
        if option.limitType == "fixed" then
          buttonWidth = buttonWidth - 0.30
        end
        if option.hideReorder or option.nameSource == -1 then
          buttonWidth = buttonWidth - 0.30
        end
        args[prefix .. "entryChoice"] = {
          type = "select",
          name = nameUser(option),
          order = order(),
          width = WeakAuras.doubleWidth - buttonWidth,
          values = values,
          get = function()
            if skipSubOptions then
              return 1 -- show the "create" prompt, which is at index 1
            end
            local value
            for id, optionData in pairs(option.references) do
              local childOption = optionData.options[optionData.index]
              local childConfigList = optionData.config[childOption.key]
              if value == nil then
                value = getPage(id, optionData.path, #childConfigList)
              elseif value ~= getPage(id, optionData.path, #childConfigList) then
                return ""
              end
            end
            return value
          end,
          set = function(_, value)
            for id, optionData in pairs(option.references) do
              setPage(id, optionData.path, value) -- XXX: mergeOptions will reset this to the maximum value if it's too big
            end
            WeakAuras.ReloadTriggerOptions(data)
          end,
        }
        if option.limitType ~= "fixed" then
          args[prefix .. "createEntry"] = {
            type = "execute",
            name = L["Add Entry"],
            order = order(),
            func = function()
              for id, optionData in pairs(option.references) do
                local childOption = optionData.options[optionData.index]
                local childConfigList = optionData.config[childOption.key]
                local childData = optionData.data
                if childOption.limitType == "none" or #childConfigList < childOption.size then
                  tinsert(childConfigList, {})
                  setPage(id, optionData.path, #childConfigList)
                  -- we do need to Add here, so that the new entry can get its default values
                  WeakAuras.Add(childData)
                end
              end
              WeakAuras.ReloadTriggerOptions(data)
            end,
            disabled = function()
              if option.limitType == "none" then
                return false
              else
                for id, optionData in pairs(option.references) do
                  local childOption = optionData.options[optionData.index]
                  local childConfigList = optionData.config[childOption.key]
                  if #childConfigList >= childOption.size then
                    return true
                  end
                end
              end
            end,
            width = 0.15,
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\add",
            imageWidth = 18,
            imageHeight = 18,
            control = "WeakAurasIcon"
          }
          args[prefix .. "deleteEntry"] = {
            type = "execute",
            name = L["Delete Entry"],
            order = order(),
            func = function()
              for id, optionData in pairs(option.references) do
                local childOption = optionData.options[optionData.index]
                local childConfigList = optionData.config[childOption.key]
                local childData = optionData.data
                local page = getPage(id, optionData.path)
                if #childConfigList ~= 0 then
                  tremove(childConfigList, page)
                  setPage(id, optionData.path, min(#childConfigList, page))
                  WeakAuras.Add(childData)
                end
              end
              WeakAuras.ReloadTriggerOptions(data)
            end,
            disabled = function()
              return skipSubOptions
            end,
            width = 0.15,
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
            imageWidth = 18,
            imageHeight = 18,
            control = "WeakAurasIcon"
          }
        end
        if option.nameSource ~= -1 and not option.hideReorder then
          args[prefix .. "moveEntryUp"] = {
            type = "execute",
            name = L["Move Entry Up"],
            order = order(),
            func = function()
              for id, optionData in pairs(option.references) do
                local childOption = optionData.options[optionData.index]
                local childConfigList = optionData.config[childOption.key]
                local childData = optionData.data
                local childPage = getPage(id, optionData.path, #childConfigList)
                if childConfigList[childPage] then
                  childConfigList[childPage], childConfigList[childPage - 1] = childConfigList[childPage - 1], childConfigList[childPage]
                  setPage(id, optionData.path, childPage - 1)
                  WeakAuras.Add(childData)
                end
              end
              WeakAuras.ReloadTriggerOptions(data)
            end,
            disabled = function()
              for id, optionData in pairs(option.references) do
                if getPage(id, optionData.path) <= 1 then
                  return true
                end
              end
            end,
            width = 0.15,
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
            imageWidth = 18,
            imageHeight = 18,
            control = "WeakAurasIcon"
          }
          args[prefix .. "moveEntryDown"] = {
            type = "execute",
            name = L["Move Entry Up"],
            order = order(),
            func = function()
              for id, optionData in pairs(option.references) do
                local childOption = optionData.options[optionData.index]
                local childConfigList = optionData.config[childOption.key]
                local childData = optionData.data
                local childPage = getPage(id, optionData.path, #childConfigList)
                if childConfigList[childPage] then
                  childConfigList[childPage], childConfigList[childPage + 1] = childConfigList[childPage + 1], childConfigList[childPage]
                  setPage(id, optionData.path, childPage + 1)
                  WeakAuras.Add(childData)
                end
              end
              WeakAuras.ReloadTriggerOptions(data)
            end,
            disabled = function()
              for id, optionData in pairs(option.references) do
                local childPage = getPage(id, optionData.path)
                local childOption = optionData.options[optionData.index]
                local childConfigList = optionData.config[childOption.key]
                if childPage >= #childConfigList then
                  return true
                end
              end
            end,
            width = 0.15,
            image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
            imageWidth = 18,
            imageHeight = 18,
            control = "WeakAurasIcon"
          }
        end
      end

      if not skipSubOptions then
        local subPrefix = prefix .. "subOption"
        for j = 1, #option.subOptions do
          addUserModeOption(option.subOptions, args, data, order, subPrefix .. j, j)
        end
      end
    end
  end
  args[prefix] = userOption

  -- convert from weakauras option type to ace option type
  if optionClass == "simple" then
    -- toggle and input don't need any extra love
    if optionType == "input" then
      userOption.multiline = option.multiline
    elseif optionType == "number" then
      userOption.type = "input"
      userOption.get = getUserNumAsString(option)
      userOption.set = setUserNum(data, option, true)
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
      userOption.get = getUserColor(option)
      userOption.set = setUserColor(data, option)
    elseif optionType == "select" then
      userOption.values = getUserValues(option)
    elseif optionType == "multiselect" then
      userOption.values = getUserValues(option)
      userOption.get = function(_, k)
        local value
        for id, optionData in pairs(option.references) do
          if value == nil then
            value = optionData.config[option.key][k]
          elseif value ~= optionData.config[option.key] then
            return
          end
        end
        return value
      end
      userOption.set = function(_, k, v)
        for id, optionData in pairs(option.references) do
          optionData.config[option.key][k] = v
          WeakAuras.Add(optionData.data)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    end
  elseif optionClass == "noninteractive" then
    if optionType == "header" then
      userOption.type = "header"
      local name = {}
      local firstName = nil
      local conflict = false
      for id, optionData in pairs(option.references) do
        local childOption = optionData.options[optionData.index]
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
    elseif optionType == "description" then
      userOption.name = nameUserDesc(option)
      userOption.fontSize = option.fontSize
    elseif optionType == "space" then
      if not option.variableWidth then
        userOption.width = "full"
      end
      if option.useHeight and (option.height or 1) > 1 then
        userOption.name = string.rep("\n", option.height - 1)
      else
        userOption.name = " "
      end
    end
  end
end

local function initReferences(mergedOption, data, options, index, config, path, parent)
  mergedOption.references = {
    [data.id] = {
      data = data,
      options = options,
      index = index,
      config = config,
      path = path,
      parent = parent,
    }
  }
  if mergedOption.subOptions then
    local subConfig
    if config then
      if mergedOption.groupType == "simple" then
        subConfig = config[mergedOption.key]
      else
        local configList = config[mergedOption.key]
        local page = getPage(data.id, path, #configList)
        subConfig = configList[page]
      end
    end
    local subOptions = options[index].subOptions
    local subPath
    local subParent = mergedOption
    for i, submergedOption in ipairs(mergedOption.subOptions) do -- ha, submerged
      subPath = CopyTable(path)
      subPath[#subPath + 1] = i
      initReferences(submergedOption, data, subOptions, i, subConfig, subPath, subParent)
    end
  end
end

-- all of these fields must be identical for an option to be merged
-- sometimes this just means that they are both nil, e.g. descriptions have no key
local significantFieldsForMerge = {
  type = true,
  name = true,
  key = true,
  groupType = true,
  limitType = true,
  size = true,
}

-- these fields are special cases, generally reserved for when the UI displays something based on the merged options
-- e.g. array name source displays options in merged order, so the dereferenced source is not useful at that level.
local specialCasesForMerge = {
  nameSource = true
}

local function mergeOptions(mergedOptions, data, options, config, prepath, parent)
  local nextInsert = 1
  for i = 1, #options do
    local path = CopyTable(prepath)
    local option = options[i]
    path[#path + 1] = i
    -- find the best place to start inserting the next option to merge
    local nextToMerge = options[i]
    local shouldMerge = false
    for j = nextInsert, #mergedOptions + 1 do
      local mergedOption = mergedOptions[j]
      if not mergedOption then
        break
      end -- no more options to check, so must insert
      local validMerge = true
      for field in pairs(significantFieldsForMerge) do
        if nextToMerge[field] ~= mergedOption[field] then
          validMerge = false
          break
        end
      end
      if validMerge then
        shouldMerge = true
        nextInsert = j
        break
      end
    end
    -- now we know at what point to add nextToMerge
    if shouldMerge then
      local mergedOption = mergedOptions[nextInsert]
      -- nil out all fields which aren't the same
      mergedOption.references[data.id] = {
        data = data,
        options = options,
        index = i,
        config = config,
        path = path,
        parent = parent,
      }
      for k, v in pairs(nextToMerge) do
        if k == "subOptions" then
          local subConfig
          if config then
            if mergedOption.groupType == "simple" then
              subConfig = config[mergedOption.key]
            else
              local configList = config[mergedOption.key]
              local page = getPage(data.id, path, #configList)
              subConfig = configList[page]
            end
          end
          local subParent = mergedOption
          mergeOptions(mergedOption.subOptions, data, v, subConfig, path, subParent)
          if mergedOption.groupType == "array" and mergedOption.nameSource ~= nil then
            -- special case merge of nameSource
            -- nameSource can be an optionID of the array's subOptions.
            -- Since the optionIDs are normally hidden away in references and options with different optionIDs can be merged together,
            -- we can't simply use nilmerge like we do with most other fields.
            -- Obviously, if the nameSource has already been set to nil then we do not need to do any more checks,
            -- as newly merged options can never resolve conflicts. Otherwise, we need to examine the semantic value of the nameSource.
            if nextToMerge.nameSource < 1 or mergedOption.nameSource < 1 then -- either the names are fixed, or they are auto-generated as "Entry #"
              -- in this case, nilmerge is the appropriate strategy
              if mergedOption.nameSource ~= nextToMerge.nameSource then
                mergedOption.nameSource = nil
              end
            else -- entry names are sourced from config of a particular subOption
              -- check if nextToMerge.nameSource was merged in the same spot as mergedOption.nameSource
              local subMergedOption = mergedOption.subOptions[mergedOption.nameSource]
              local optionData = subMergedOption.references[data.id]
              if not optionData or optionData.optionIndex ~= nextToMerge.nameSource then
                -- either an option was not merged at the name source's index, or the wrong option was.
                -- in both cases, the name source is conflicted. Fallback to "Entry #" as entry names
                mergedOption.nameSource = nil
              end
            end
          end
        elseif not specialCasesForMerge[k] and neq(mergedOption[k], v) then
          mergedOption[k] = nil
        end
      end
    else
      -- can't merge, should insert instead
      local newOption = CopyTable(nextToMerge)
      initReferences(newOption, data, options, i, config, path, parent)
      tinsert(mergedOptions, nextInsert, newOption)
    end
    -- never merge 2 options from the same child
    nextInsert = nextInsert + 1
  end
end

local function valuesAreEqual(t1, t2)
  if t1 == t2 then
    return true
  end
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then
    return false
  end
  if ty1 ~= "table" then
    return false
  end

  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not valuesAreEqual(v1, v2) then
      return false
    end
  end

  for k2, v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not valuesAreEqual(v1, v2) then
      return false
    end
  end
  return true
end

local function allChoicesAreDefault(option, config, id, path)
  local optionClass = optionClasses[option.type]
  if optionClass == "simple" then
    return valuesAreEqual(option.default, config[option.key])
  elseif optionClass == "group" then
    if option.groupType == "simple" then
      local subConfig = config[option.key]
      path[#path + 1] = 0
      for i, subOption in ipairs(option.subOptions) do
        path[#path] = i
        if not allChoicesAreDefault(subOption, subConfig, id, path) then
          return false
        end
      end
      path[#path] = nil
    elseif option.groupType == "array" then
      path[#path + 1] = 0
      for _, subConfig in ipairs(config[option.key]) do
        for i, subOption in ipairs(option.subOptions) do
          path[#path] = i
          if not allChoicesAreDefault(subOption, subConfig, id, path) then
            return false
          end
        end
      end
      path[#path] = nil
    end
    if option.useCollapse then
      local isCollapsed = WeakAuras.IsCollapsed(id, "config", path, option.collapse)
      if isCollapsed ~= option.collapse then
        return false
      end
    end
  end
  return true
end

local function createorder(startorder)
  local order = startorder or 1
  return function()
    order = order + 1
    return order
  end
end

function WeakAuras.GetAuthorOptions(data, args, startorder)
  -- initialize the process
  local isAuthorMode = true
  local options = {}
  local order = createorder(startorder)
  if data.controlledChildren then
    -- merge options together
    for i = 1, #data.controlledChildren do
      local childData = WeakAuras.GetData(data.controlledChildren[i])
      mergeOptions(options, childData, childData.authorOptions, childData.config, {})
      isAuthorMode = isAuthorMode and childData.authorMode
    end
  else
    -- pretend that this is a group with one child
    isAuthorMode = data.authorMode
    mergeOptions(options, data, data.authorOptions, data.config, {})
  end
  if isAuthorMode then
    args["enterUserMode"] = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Enter User Mode"],
      desc = L["Enter user mode."],
      order = order(),
      func = function()
        if data.controlledChildren then
          for _, id in ipairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(id)
            childData.authorMode = nil
            -- no need to add, author mode is picked up by ReloadTriggerOptions
          end
        else
          data.authorMode = nil
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
    args["enterUserModeSpacer"] = {
      type = "description",
      name = "",
      order = order()
    }
    for i = 1, #options do
      addAuthorModeOption(options, args, data, order, "option" .. i, i)
    end
    args["addOption"] = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Add Option"],
      order = order(),
      func = function()
        if data.controlledChildren then
          for _, id in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(id)
            local i = #childData.authorOptions + 1
            childData.authorOptions[i] = {
              type = "toggle",
              key = "option" .. i,
              name = L["Option %i"]:format(i),
              default = false,
              width = 1,
              useDesc = false,
            }
            WeakAuras.SetCollapsed(childData.id, "author", i, false)
            WeakAuras.Add(childData)
          end
        else
          local i = #data.authorOptions + 1
          data.authorOptions[i] = {
            type = "toggle",
            key = "option" .. i,
            name = L["Option %i"]:format(i),
            default = false,
            width = 1,
            useDesc = false,
          }
          WeakAuras.SetCollapsed(data.id, "author", i, false)
          WeakAuras.Add(data)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
  else
    for i = 1, #options do
      addUserModeOption(options, args, data, order, "userOption" .. i, i)
    end
    args["userConfigFooter"] = {
      type = "header",
      name = "",
      order = order()
    }
    args["resetToDefault"] = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Reset to Defaults"],
      desc = L["Reset all options to their default values."],
      order = order(),
      func = function()
        if data.controlledChildren then
          for _, id in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(id)
            WeakAuras.ResetCollapsed(id, "config")
            childData.config = {} -- config validation in Add() will set all the needed keys to their defaults
            WeakAuras.Add(childData)
          end
        else
          data.config = {}
          WeakAuras.ResetCollapsed(data.id, "config")
          WeakAuras.Add(data)
        end
        WeakAuras.ReloadTriggerOptions(data)
      end,
      disabled = function()
        local path = {}
        if data.controlledChildren then
          for _, id in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(id)
            local childConfig = childData.config
            for i, childOption in ipairs(childData.authorOptions) do
              path[1] = i
              local result = allChoicesAreDefault(childOption, childConfig, id, path)
              if result == false then
                return false
              end
            end
          end
        else
          local config = data.config
          for i, option in ipairs(data.authorOptions) do
            path[1] = i
            local result = allChoicesAreDefault(option, config, data.id, path)
            if result == false then
              return false
            end
          end
        end
        return true
      end
    }
    args["enterAuthorMode"] = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Enter Author Mode"],
      desc = L["Configure what options appear on this panel."],
      order = order(),
      func = function()
        if data.controlledChildren then
          for _, id in ipairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(id)
            childData.authorMode = true
            -- no need to add, author mode is picked up by ReloadTriggerOptions
          end
        else
          data.authorMode = true
        end
        WeakAuras.ReloadTriggerOptions(data)
      end
    }
  end
  return args
end
