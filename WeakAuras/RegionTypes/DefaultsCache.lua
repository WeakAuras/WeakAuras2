if not WeakAuras.IsLibsOK() then return end
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

local function ApplyDefaults(data, action, mapping)
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
        tablePath = {}
        property = settingsPath
      end

      local settingsBase = GetOrCreateSubTable(data, unpack(tablePath))
      if type(value) == "table" then
        settingsBase[property] = CopyTable(value)
      else
        settingsBase[property] = value
      end
    end
  end
end

local funcs = {
  ClearCache = function(self)
    wipe(self.defaults)
  end,
  GetDefault = function(self, action, mappingName)
    if not self.mappings[mappingName] then
      error("DefaultsCache:GetDefault called with a wrong key: " .. mappingName, 1)
      return nil
    end

    if not action then
      error("DefaultsCache:GetDefault no action", 1)
    end

    if not self.defaults[action] or not self.defaults[action][mappingName] then
      self.defaults[action] = self.defaults[action] or {}

      local mapping = self.mappings[mappingName]
      local defaults = CopyTable(mapping.base)
      ApplyDefaults(defaults, action, mapping.map)

      self.defaults[action][mappingName] = defaults
    end

    return self.defaults[action][mappingName]
  end,
  AddDefault = function(self, mappingName, mapping)
    if not mapping.base or not mapping.map then
      error("DefaultsCache: mapping has incorrect format, key: " .. mappingName, 1)
    end
    self.mappings[mappingName] = mapping
  end
}

local function CreateDefaultsCache(mappings)
  local cache = {}
  cache.mappings = {}
  cache.defaults = {}

  for k, func in pairs(funcs) do
    cache[k] = func
  end

  for mappingName, mapping in pairs(mappings) do
    cache:AddDefault(mappingName, mapping)
  end

  Private.callbacks:RegisterCallback("DefaultsChanged", function() cache:ClearCache() end)
  return cache
end

Private.CreateDefaultsCache = CreateDefaultsCache
