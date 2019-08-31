local L = WeakAuras.L

--@localization(locale="enUS", format="lua_additive_table", namespace="WeakAuras", handle-subnamespaces="none")@

-- Make missing translations available
setmetatable(WeakAuras.L, {__index = function(self, key)
  self[key] = (key or "")
  return key
end})

L["Automatic Repair Confirmation Dialog"] = [[
WeakAuras has detected that it has been downgraded.
Your saved auras may no longer work properly.

Would you like to run the |cffff0000EXPERIMENTAL|r repair tool? This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s]]

L["Manual Repair Confirmation Dialog"] = [[
Are you sure you want to run the |cffff0000EXPERIMENTAL|r repair tool?
This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s]]
