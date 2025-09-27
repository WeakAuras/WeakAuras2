---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

local optionsVersion = "5.20.4"
--[==[@debug@
optionsVersion = "Dev"
--@end-debug@]==]

if optionsVersion ~= WeakAuras.versionString then
  local message = string.format(L["The WeakAuras Options Addon version %s doesn't match the WeakAuras version %s. If you updated the addon while the game was running, try restarting World of Warcraft. Otherwise try reinstalling WeakAuras"],
                    optionsVersion, WeakAuras.versionString)
  ---@diagnostic disable-next-line: duplicate-set-field
  WeakAuras.IsLibsOk = function() return false end
  ---@diagnostic disable-next-line: duplicate-set-field
  WeakAuras.ToggleOptions = function()
       WeakAuras.prettyPrint(message)
  end

end