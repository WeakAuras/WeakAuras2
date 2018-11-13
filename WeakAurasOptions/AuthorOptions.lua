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
    desc (optional) -> string to be displayed in the option tooltip
  When options are merged together (i.e. when the user multiselects and then opens the custom options tab), there is one additonal field:
    references -> childID <=> optionID map, used to dereference to the proper option table in setters

  Supported option types, and additional fields that each type supports/requires:
    description -> dummy option which can be used to display some text. Not interactive, and so key/default are not set or required.
      name (required) -> text displayed on the panel
      fontSize (optional) -> fontSize. Default is medium.
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

-- temporary (not saved across sessions) cache of which authormode options are collapsed
local collapsedOptions = {}

local function ensureCollapsedData(data)
  if collapsedOptions[data.id] then return end
  local collapsedData = {}
  for i = 1, #data.authorOptions do
    collapsedData[#collapsedData + 1] = false
  end
  collapsedOptions[data.id] = collapsedData
end

function WeakAuras.RenameCollapsedData(oldid, newid)
  collapsedOptions[newid] = collapsedOptions[oldid]
  collapsedOptions[oldid] = nil
end

local function atLeastOneSet(data, references, key)
  for childID, optionID in pairs(references) do
    if data[childID].authorOptions[optionID][key] ~= nil then
      return true
    end
  end
end

-- blues the name if there are conflicts between the references for this value
local function name(data, option, key, name, phrase)
  local header = name or phrase
  if not option.references then
    return header
  elseif option[key] ~= nil or not atLeastOneSet(data, option.references, key) then
    return header
  else
    return "|cFF4080FF" .. header
  end
end

local function nameHead(data, option, phrase)
  if not option.references then
    return phrase
  else
    for i = 1, #data[0].controlledChildren do
      if not option.references[i] then
        return "|cFF4080FF" .. phrase
      end
    end
    return phrase
  end
end

-- provides a tooltip showing all the conflicting values if there are any
local function desc(data, option, key, phrase)
  if not option.references then
    return phrase
  elseif option[key] or not atLeastOneSet(data, option.references, key) then
    return phrase
  else
    local desc = {}
    if phrase then
      desc[1] = phrase
    end
    tinsert(desc, L["Values:"])
    for childID, optionID in pairs(option.references) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption[key] ~= nil then
        tinsert(desc, ("%s #%i: %s"):format(childData.id, optionID, tostring(childOption[key])))
      end
    end
    return tconcat(desc,"\n")
  end
end

local function descType(data, option)
  if not option.references then
    return L["This setting controls what widget is generated in user mode."]
  else
    local desc = {
      L["This setting controls what widget is generated in user mode."],
      L["Used in Auras:"],
    }
    for childID, optionID in pairs(option.references) do
      local childData = data[childID]
      tinsert(desc, ("%s - Option %i"):format(childData.id, optionID))
    end
    return tconcat(desc,"\n")
  end
end

local function descSelect(data, option, key)
  if not option.references then
    return ""
  elseif option.values then
    return ""
  else
    local desc = {L["Values:"]}
    for childID, optionID in pairs(option.references) do
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
  if not option.references then
    return ""
  elseif option[key] or not atLeastOneSet(data, option.references, key) then
    return ""
  else
    local desc = {
      L["Values are in normalized rgba format."],
      L["Values:"],
    }
    for childID, optionID in pairs(option.references) do
      local childData = data[childID]
      local childOption = childData.authorOptions[optionID]
      if childOption[key] ~= nil then
        tinsert(desc, ("%s #%i: %.2f %.2f %.2f %.2f"):format(childData.id, optionID, unpack(childOption[key])))
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

local function getNumAsString(option, key)
  return function()
    if option[key] ~= nil then
      return tostring(option[key])
    end
  end
end

local function getColor(option, key)
  return function()
    if option[key] then
      return unpack(option[key])
    end
  end
end

-- setters for AceConfig
local function set(data, option, key)
  if option.references then
    return function(_, value)
      for childID, optionID in pairs(option.references) do
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

local function setNum(data, option, key, required)
  if option.references then
    return function(_, value)
      if value ~= "" then
        local num = tonumber(value)
        if not num or math.abs(num) == math.huge or tostring(num) == "nan" then return end
        for childID, optionID in pairs(option.references) do
          local childData = data[childID]
          local childOption = childData.authorOptions[optionID]
          childOption[key] = num
          WeakAuras.Add(childData)
        end
      elseif not required then
        for childID, optionID in pairs(option.references) do
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

local function setColor(data, option, key)
  if option.references then
    return function(_, r, g, b, a)
      local color = {r, g, b, a}
      for childID, optionID in pairs(option.references) do
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

local function setSelectDefault(data, option, key)
  if option.references then
    return function(_, value)
      for childID, optionID in pairs(option.references) do
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
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      values = WeakAuras.bool_types,
      get = function()
        if option.default == nil then return end
        return option.default and 1 or 0
      end,
      set = function(_, value)
        if option.references then
          local val = value == 1
          for childID, optionID in pairs(option.references) do
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
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      width = "full",
      get = get(option, "default"),
      set = set(data, option, "default"),
    }
    order = order + 1
    args["option" .. i .. "useLength"] = {
      type = "toggle",
      name = name(data, option, "useLength", L["Max Length"]),
      desc = desc(data, option, "useLength"),
      order = order,
      get = get(option, "useLength"),
      set = set(data, option, "useLength"),
    }
    order = order + 1
    args["option" .. i .. "length"] = {
      type = "range",
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
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      get = getNumAsString(option, "default"),
      set = setNum(data, option, "default", true),
    }
    order = order + 1

    args["option" .. i .. "defaultspace"] = {
      type = "description",
      order = order,
      name = "",
    }
    order = order + 1

    args["option" .. i .. "min"] = {
      type = "input",
      name = name(data, option, "min", L["Min"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "max"] = {
      type = "input",
      name = name(data, option, "max", L["Max"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "step"] = {
      type = "input",
      name = name(data, option, "step", L["Step Size"]),
      desc = desc(data, option, "step"),
      order = order,
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step"),
      width = 2/3,
    }
    order = order + 1

    return order
  end,
  range = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "input",
      name = name(data, option, "default", L["Default"]),
      desc = desc(data, option, "default"),
      order = order,
      get = getNumAsString(option, "default"),
      set = setNum(data, option, "default"),
    }
    order = order + 1

    args["option" .. i .. "defaultspace"] = {
      type = "description",
      order = order,
      name = "",
    }
    order = order + 1

    args["option" .. i .. "min"] = {
      type = "input",
      name = name(data, option, "min", L["Min"]),
      desc = desc(data, option, "min"),
      order = order,
      get = getNumAsString(option, "min"),
      set = setNum(data, option, "min"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "max"] = {
      type = "input",
      name = name(data, option, "max", L["Max"]),
      desc = desc(data, option, "max"),
      order = order,
      get = getNumAsString(option, "max"),
      set = setNum(data, option, "max"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "step"] = {
      type = "input",
      name = name(data, option, "step", L["Step Size"]),
      desc = desc(data, option, "step"),
      order = order,
      get = getNumAsString(option, "step"),
      set = setNum(data, option, "step"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "softmin"] = {
      type = "input",
      name = name(data, option, "softMin", L["Soft Min"]),
      desc = desc(data, option, "softMin"),
      order = order,
      get = getNumAsString(option, "softMin"),
      set = setNum(data, option, "softMin"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "softmax"] = {
      type = "input",
      name = name(data, option, "softMax", L["Soft Max"]),
      desc = desc(data, option, "softMax"),
      order = order,
      get = getNumAsString(option, "softMax"),
      set = setNum(data, option, "softMax"),
      width = 2/3,
    }
    order = order + 1

    args["option" .. i .. "bigstep"] = {
      type = "input",
      name = name(data, option, "bigStep", L["Slider Step Size"]),
      desc = desc(data, option, "bigStep"),
      order = order,
      get = getNumAsString(option, "bigStep"),
      set = setNum(data, option, "bigStep"),
      width = 2/3,
    }
    order = order + 1
    return order
  end,
  description = function(option, args, data, order, i)
    args["option" .. i .. "key"] = nil
    args["option" .. i .. "name"] = nil
    args["option" .. i .. "fontsize"] = {
      type = "select",
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
      name = name(data, option, "text", L["Description Text"]),
      desc = desc(data, option, "text"),
      order = order,
      width = "double",
      multiline = true,
      get = get(option, "text"),
      set = set(data, option, "text")
    }
    order = order + 1
    return order
  end,
  color = function(option, args, data, order, i)
    args["option" .. i .. "default"] = {
      type = "color",
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
    local values
    local conflict = {} -- magic value
    if option.references then
      values = {}
      for childID, optionID in pairs(option.references) do
        local childData = data[childID]
        local childValues = childData.authorOptions[optionID].values
        local i = 1
        while i <= #values or i <= #childValues do
          local value = values[i]
          if value == conflict then
            -- conflicts can't ever be resolved at this point
          elseif value == nil then
            -- set the new value
            values[i] = childValues[i]
          elseif value ~= childValues[i] then
            -- either this child has a conflicting value at this index
            -- or it's already ended and is nil, so we need to mark a conflict
            values[i] = conflict
          end
          i = i + 1
        end
      end
    else
      values = option.values
    end
    args["optino" .. i .. "defaultspace"] = {
      type = "toggle",
      name = name(data, option, "default", L["Default"]),
      order = order,
      disabled = function() return true end,
      get = function() return true end,
      set = function() end,
    }
    order = order + 1
    local defaultValues = {}
    for i, v in ipairs(values) do
      if v == conflict then
        defaultValues[i] = "|cFF4080FF" .. L["Value %i"]:format(i)
      else
        defaultValues[i] = v
      end
    end
    args["option" .. i .. "default"] = {
      type = "select",
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
        name = L["Value %i"]:format(j),
        order = order,
        disabled = function() return true end,
        get = function() return true end,
        set = function() end,
      }
      order = order + 1
      args["option" .. i .. "value" .. j] = {
        type = "input",
        name = (value == conflict and "|cFF4080FF" or "") .. L["Value %i"]:format(j),
        desc = descSelect(data, option, j, conflict),
        order = order,
        width = 0.85,
        get = function()
          if value ~= conflict then
            return value
          end
        end,
        set = function(_, value)
          if option.references then
            for childID, optionID in pairs(option.references) do
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
        name = "",
        order = order,
        func = function()
          if option.references then
            for childID, optionID in pairs(option.references) do
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
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24
      }
    end
    args["option" .. i .. "newvaluespace"] = {
      type = "toggle",
      name = L["New Value"],
      order = order,
      disabled = function() return true end,
      get = function() return true end,
      set = function() end,
    }
    order = order + 1
    args["option" .. i .. "newvalue"] = {
      type = "input",
      name = L["New Value"],
      order = order,
      get = function() return "" end,
      set = function(_, value)
        if option.references then
          for childID, optionID in pairs(option.references) do
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
  end
}

local function up(data, option, index)
  if option.references then
    return function()
      for _, optionID in pairs(option.references) do
        if index == 1 then return true end
      end
    end, function()
      for childID, optionID in pairs(option.references) do
        local childData = data[childID]
        local collapsedData = collapsedOptions[childData.id]
        if childData then
          collapsedData[optionID], collapsedData[optionID - 1] = collapsedData[optionID - 1], collapsedData[optionID]
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
      collapsedOptions[data.id][index], collapsedOptions[data.id][index - 1] = collapsedOptions[data.id][index - 1], collapsedOptions[data.id][index]
      data.authorOptions[index], data.authorOptions[index - 1] = data.authorOptions[index - 1], data.authorOptions[index]
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function down(data, option, index)
  if option.references then
    return function()
      for childID, optionID in pairs(option.references) do
        local childData = data[childID]
        if index == #childData.authorOptions then return true end
      end
    end, function()
      for childID, optionID in pairs(option.references) do
        local childData = data[childID]
        local collapsedData = collapsedOptions[childData.id]
        if childData then
          collapsedData[optionID], collapsedData[optionID + 1] = collapsedData[optionID + 1], collapsedData[optionID]
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
      collapsedOptions[data.id][index], collapsedOptions[data.id][index + 1] = collapsedOptions[data.id][index + 1], collapsedOptions[data.id][index]
      data.authorOptions[index], data.authorOptions[index + 1] = data.authorOptions[index + 1], data.authorOptions[index]
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function delete(data, option, index)
  if option.references then
    return function()
      for childID, optionID in pairs(option.references) do
        local childData = data[childID]
        tremove(collapsedOptions[childData.id], optionID)
        tremove(childData.authorOptions, optionID)
        WeakAuras.Add(childData)
      end
      WeakAuras.ReloadTriggerOptions(data[0])
    end
  else
    return function()
      tremove(collapsedOptions[data.id], index)
      tremove(data.authorOptions, index)
      WeakAuras.Add(data)
      WeakAuras.ReloadTriggerOptions(data)
    end
  end
end

local function addControlsForOption(authorOptions, args, data, order, i)
  -- add header controls
  local option = authorOptions[i]

  local collapsed = true
  if option.references then
    for childID, optionID in pairs(option.references) do
      local childData = data[childID]
      if not collapsedOptions[childData.id][optionID] then
        collapsed = false
        break
      end
    end
  else
    collapsed = collapsedOptions[data.id][i]
  end

  args["option" .. i .. "collapse"] = {
    type = "execute",
    name = "",
    order = order,
    width = 0.15,
    func = function()
      if option.references then
        for childID, optionID in pairs(option.references) do
          local childData = data[childID]
          collapsedOptions[childData.id][optionID] = not collapsed
        end
        WeakAuras.ReloadTriggerOptions(data[0])
      else
        collapsedOptions[data.id][i] = not collapsed
        WeakAuras.ReloadTriggerOptions(data)
      end
    end,
    image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse" ,
    imageWidth = 18,
    imageHeight = 18
  }
  order = order + 1

  args["option" .. i .. "header"] = {
    type = "description",
    name = nameHead(data, option, option.name, L["Option #%i"]:format(i)),
    order = order,
    width = 1.40,
    fontSize = "large",
  }
  order = order + 1

  local upDisable, upFunc = up(data, option, i)
  args["option" .. i .. "up"] = {
    type = "execute",
    name = "",
    order = order,
    disabled = upDisable,
    func = upFunc,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
    imageWidth = 24,
    imageHeight = 24
  }
  order = order + 1

  local downDisable, downFunc = down(data, option, i)
  args["option" .. i .. "down"] = {
    type = "execute",
    name = "",
    order = order,
    disabled = downDisable,
    func = downFunc,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
    imageWidth = 24,
    imageHeight = 24
  }
  order = order + 1

  args["option" .. i .. "delete"] = {
    type = "execute",
    name = "",
    order = order,
    func = delete(data, option, i),
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
    imageWidth = 24,
    imageHeight = 24
  }
  order = order + 1

  if collapsed then
    return order
  end

  args["option" .. i .. "name"] = {
    type = "input",
    name = name(data, option, "name", L["Display Name"]),
    desc = desc(data, option, "name"),
    order = order,
    get = get(option, "name"),
    set = set(data, option, "name"),
  }
  order = order + 1

  args["option" .. i .. "key"] = {
    type = "input",
    name = name(data, option, "key", L["Option key"]),
    desc = desc(data, option, "key", L["Key for aura_env.config at which the user value can be found."]),
    order = order,
    get = get(option, "key"),
    set = set(data, option, "key"),
  }
  order = order + 1

  args["option" .. i .. "type"] = {
    type = "select",
    name = L["Option Type"],
    desc = descType(data, option),
    order = order,
    values = WeakAuras.author_option_types,
    get = get(option, "type"),
    set = function(_, value)
      if value == option.type then return end
      local author_option_fields = WeakAuras.author_option_fields
      local commonFields, newFields = author_option_fields.common, author_option_fields[value]
      if option.references then
        for childID, optionID in pairs(option.references) do
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
        WeakAuras.Add(data)
        WeakAuras.ReloadTriggerOptions(data)
      end
    end
  }
  order = order + 1

  args["option" .. i .. "width"] = {
    type = "range",
    name = name(data, option, "width", L["Width"]),
    desc = desc(data, option, "width"),
    order = order,
    min = 0.1,
    max = 2,
    softMin = 0.5,
    step = 0.05,
    bigStep = 0.1,
    get = get(option, "width"),
    set = set(data, option, "width")
  }
  order = order + 1

  local addControlsForType = typeControlAdders[option.type]
  if addControlsForType then
    order = addControlsForType(option, args, data, order, i)
  end
  if option.type ~= "description" then
    args["option" .. i .. "tooltipSpace"] = {
      type = "description",
      name = "",
      order = order,
      width = "double",
    }
    order = order + 1
    args["option" .. i .. "usetooltip"] = {
      type = "toggle",
      name = name(data, option, "useDesc", L["Tooltip"]),
      order = order,
      width = 0.5,
      get = get(option, "useDesc"),
      set = function(_, value)
        if option.references then
          for childID, optionID in pairs(option.references) do
            local childData = data[childID]
            local childOption = childData.authorOptions[optionID]
            childOption.useDesc = value
            if not value then
              childOption.desc = nil
            end
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data[0])
        else
          if not value then
            option.desc = nil
          end
          option.useDesc = value
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      end,
    }
    order = order + 1
    args["option" .. i .. "tooltip"] = {
      type = "input",
      name = name(data, option, "desc", L["Tooltip Text"]),
      desc = desc(data, option, "desc"),
      order = order,
      width = 1.5,
      get = get(option, "desc"),
      set = set(data, option, "desc"),
      disabled = function() return not option.useDesc end,
    }
    order = order + 1
  end
  return order
end

local function addUserModeOption(options, args, data, order, i)
  local option = options[i]
  local config = data.config
  local optionType = option.type
  local userOption = {
    type = option.type,
    name = option.name,
    desc = option.desc,
    width = option.width,
    order = order,
    get = get(config, option.key),
    set = set(data, config, option.key)
  }
  order = order + 1
  args[data.id .. "userOption" .. i] = userOption

  -- convert from weakauras option type to ace option type
  if optionType == "toggle" then
  elseif optionType == "input" then
  elseif optionType == "number" then
    userOption.type = "input"
    userOption.get = getNumAsString(config, option.key)
    userOption.set = setNum(data, config, option.key, true)
  elseif  optionType == "range" then
    userOption.max = option.max
    userOption.min = option.min
    userOption.step = option.step
    userOption.softMax = option.softMax
    userOption.softMin = option.softMin
    userOption.bigStep = option.bigStep
  elseif optionType == "description" then
    userOption.name = option.text or ""
    userOption.fontSize = option.fontSize
  elseif optionType == "color" then
    userOption.get = getColor(config, option.key)
    userOption.set = setColor(data, config, option.key)
  elseif optionType == "select" then
    userOption.values = option.values
  end
  return order
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

local function mergeOptions(childIndex, merged, toMerge)
  local nextInsert = 1
  for i = 1, #toMerge do
    -- find the best place to start inserting the next option to merge
    local nextToMerge = toMerge[i]
    local shouldMerge = false
    for j = nextInsert, #merged + 1 do
      if not merged[j] then break end -- no more options to check, so must insert
      if nextToMerge.type == merged[j].type and nextToMerge.key == merged[j].key then
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
      mergedOption.references[childIndex] = i
    else
      -- can't merge, should insert instead
      local newOption = CopyTable(nextToMerge)
      newOption.references = {[childIndex] = i}
      tinsert(merged, nextInsert, newOption)
    end
    -- nexver merge 2 options from the same child
    nextInsert = nextInsert + 1
  end
end

local function allChoicesAreDefault(data)
  for _, option in ipairs(data.authorOptions) do
    if option.key ~= nil and option.default ~= nil and option.default ~= data.config[option.key] then
      return false
    end
  end
  return true
end

function WeakAuras.GetAuthorOptions(data, args, startorder)
  if data.controlledChildren then
    local isAuthorMode = true
    for i = 1, #data.controlledChildren do
      local childData = WeakAuras.GetData(data.controlledChildren[i])
      ensureCollapsedData(childData)
      if childData and not childData.authorMode then
        isAuthorMode = false
        break
      end
    end
    if isAuthorMode then
      local order = startorder + 2
      local mergedOptions = {}
      local allData = {[0] = data}
      -- merge child options into one
      for i, childID in ipairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childID)
        local childOptions = childData and childData.authorOptions
        allData[i] = childData
        if childOptions then
          mergeOptions(i, mergedOptions, childOptions)
        end
      end
      for i = 1, #mergedOptions do
        order = addControlsForOption(mergedOptions, args, allData, order, i)
      end
      args["addOption"] = {
        type = "execute",
        name = L["Add Option"],
        order = order,
        func = function()
          for _, childData in ipairs(allData) do
            local i = #childData.authorOptions + 1
            childData.authorOptions[i] = {
              type = "toggle",
              key  = "option" .. i,
              name = L["Option #"] .. i,
              default = false,
              width = 1,
              useDesc = false,
            }
            tinsert(collapsedOptions[childData.id], false)
            WeakAuras.Add(childData)
          end
          WeakAuras.ReloadTriggerOptions(data)
        end
      }

      args["enterUserMode"] = {
        type = "execute",
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
      local values = {}
      for i = 1, #data.controlledChildren do
        local childData = WeakAuras.GetData(data.controlledChildren[i])
        if childData and #childData.authorOptions > 0 then
          tinsert(values, childData.id)
          local childIndex = #values
          args[childData.id .. "header"] = {
            type = "header",
            name = childData.id,
            order = order,
          }
          order = order + 1
          for j = 1, #childData.authorOptions do
            order = addUserModeOption(childData.authorOptions, args, childData, order, j)
          end
          args[childData.id .. "space1"] ={
            type = "description",
            name = "",
            order = order,
          }
          order = order + 1
          args[childData.id .. "resetToDefault"] = {
            type = "execute",
            name = L["Reset to Defaults"],
            desc = L["Reset all options to their default values."],
            order = order,
            func = function()
              wipe(childData.config)
              WeakAuras.Add(childData)
              WeakAuras.ReloadTriggerOptions(data)
            end,
            hidden = function() return allChoicesAreDefault(childData) end
          }
          order = order + 1
        end
      end
      args["userConfigFooter"] = {
        type = "header",
        name = "",
        order = order,
      }
      order = order + 1
      args["resetAllToDefault"] = {
        type = "execute",
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
          if #values <= 1 then return true end
          for _, childID in ipairs(values) do
            local childData = WeakAuras.GetData(childID)
            if not allChoicesAreDefault(childData) then
              return false
            end
          end
          return true
        end,
      }
      order = order + 1
      args["enterAuthorModeAll"] = {
        type = "execute",
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
    ensureCollapsedData(data)
    if not data.authorMode then
      local order = startorder
      args[data.id .. "header"] = {
        type = "header",
        name = data.id .. L[" Configuration"],
        order = order,
      }
      order = order + 1
      for i = 1, #authorOptions do
        order = addUserModeOption(authorOptions, args, data, order, i)
      end
      args["resetToDefault"] = {
        type = "execute",
        name = L["Reset to Defaults"],
        desc = L["Reset all options to their default values."],
        order = order,
        func = function()
          wipe(data.config)
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end,
        hidden = function() return allChoicesAreDefault(data) end
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

      order = order + 1

      for i = 1, #authorOptions do
        order = addControlsForOption(authorOptions, args, data, order, i)
      end
      args["addOption"] = {
        type = "execute",
        name = L["Add Option"],
        order = order,
        func = function()
          local i = #authorOptions + 1
          authorOptions[i] = {
            type = "toggle",
            key  = "option" .. i,
            name = L["Option #"] .. i,
            default = false,
            width = 1,
          }
          tinsert(collapsedOptions[data.id], false)
          WeakAuras.Add(data)
          WeakAuras.ReloadTriggerOptions(data)
        end
      }

      args["enterUserMode"] = {
        type = "execute",
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
