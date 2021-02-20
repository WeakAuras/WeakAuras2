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


