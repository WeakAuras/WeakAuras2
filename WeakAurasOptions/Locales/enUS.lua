if not WeakAuras.IsLibsOK() then return end

if ((GAME_LOCALE or GetLocale()) ~= "enUS") and ((GAME_LOCALE or GetLocale()) ~= "enGB") then
  return
end

local L = WeakAuras.L

--@localization(locale="enUS", format="lua_additive_table", namespace="WeakAuras / Options")@
