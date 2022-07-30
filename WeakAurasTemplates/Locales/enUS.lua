if not WeakAuras.IsLibsOK() then return end

local L = WeakAuras.L

--@localization(locale="enUS", format="lua_additive_table", namespace="WeakAuras / Templates")@

-- Make missing translations available
setmetatable(WeakAuras.L, {__index = function(self, key)
  self[key] = (key or "")
  return key
end})
