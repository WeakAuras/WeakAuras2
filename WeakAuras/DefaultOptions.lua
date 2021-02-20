local AddonName, Private = ...

-- TODO copied from BuffTrigger2
local function GetOrCreateSubTable(base, next, ...)
  if not next then
    return base
  end

  base[next] = base[next] or {}
  return GetOrCreateSubTable(base[next], ...)
end

local function GetSubTable(base, next, ...)
  if not base then
    return nil
  end

  if not next then
    return base
  end

  return GetSubTable(base[next], ...)
end

function Private.SetDefault(namespace, key, property, type, value)
  if WeakAurasSaved then
    local base = GetOrCreateSubTable(WeakAurasSaved, namespace, key, property)
    if type ~= nil then
      base.type = type
    end
    if value ~= nil then
      base.value = value
    end
    Private.callbacks:Fire("DefaultsChanged")
  end
end

function Private.GetDefault(namespace, key, property, default)
  if WeakAurasSaved then
    local base = GetSubTable(WeakAurasSaved, namespace, key, property)
    if base then
      return base.type, base.value
    else
      return nil, default
    end
  end
end

function Private.ApplyDefaults(data, action, mapping)
  for defaultPath, settingsPath in pairs(mapping) do
    local namespace, key, property = defaultPath[1], defaultPath[2], defaultPath[3]
    local savedApplyType, value = Private.GetDefault(namespace, key, property, nil)

    local apply = false
    -- TODO template ?
    if action == "import" then
      apply = savedApplyType == 2 or savedApplyType == 3
    elseif action == "new" then
      apply = savedApplyType == 1 or savedApplyType == 3
    elseif action == "validate" then
      -- Nothing to do, validation can be done without user templates
    end

    if apply then
      local tablePath
      local property
      if type(settingsPath) == "table" then
        tablePath = CopyTable(settingsPath)
        tablePath[#tablePath] = nil
        property = settingsPath[#settingsPath]
      else
        tablePath ={}
        property = settingsPath
      end

      local settingsBase = GetOrCreateSubTable(data, unpack(tablePath))
      settingsBase[property] = value
    end
  end
end
