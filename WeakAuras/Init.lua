WeakAuras = {}
WeakAuras.L = {}

WeakAuras.normalWidth = 1.25
WeakAuras.halfWidth = WeakAuras.normalWidth / 2
WeakAuras.doubleWidth = WeakAuras.normalWidth * 2

local versionStringFromToc = GetAddOnMetadata("WeakAuras", "Version")
local versionString = "@project-version@"
local buildTime = "@build-time@"

local isDevVersion = false
--@debug@
if versionStringFromToc == "@project-version@" then
  versionStringFromToc = "Dev"
  buildTime = "Dev"
  isDevVersion = true
end
--@end-debug@

local intendedWoWProject = WOW_PROJECT_MAINLINE
--[===[@non-retail@
intendedWoWProject = WOW_PROJECT_CLASSIC
--@end-non-retail@]===]

WeakAuras.versionString = versionStringFromToc
WeakAuras.buildTime = buildTime
WeakAuras.printPrefix = "|cff9900ffWeakAuras:|r "
WeakAuras.newFeatureString = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t"
WeakAuras.BuildInfo = select(4, GetBuildInfo())

function WeakAuras.IsClassic()
  return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function WeakAuras.IsCorrectVersion()
  return isDevVersion or intendedWoWProject == WOW_PROJECT_ID
end

WeakAuras.prettyPrint = function(msg)
  print(WeakAuras.printPrefix .. msg)
end

WeakAuras.versionMismatchPrint = function()
  WeakAuras.prettyPrint("You need to restart your game client to complete the WeakAuras update!")
end

WeakAuras.wrongTargetMessage = "This version of WeakAuras was packaged for World of Warcraft " ..
                              (intendedWoWProject == WOW_PROJECT_MAINLINE and "Retail" or "Classic") ..
                              ". Please install the " .. (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and "Retail" or "Classic") ..
                              " version instead.\nIf you are using the Twitch Client, then " ..
                              " please contact the twitch support for further assistance."

if not WeakAuras.IsCorrectVersion() then
  C_Timer.After(1, function() WeakAuras.prettyPrint(WeakAuras.wrongTargetMessage) end)
end

if versionString ~= versionStringFromToc and versionStringFromToc ~= "Dev" then
  C_Timer.After(1, WeakAuras.versionMismatchPrint)
end

WeakAuras.PowerAurasPath = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\"
WeakAuras.PowerAurasSoundPath = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\"

-- force enable WeakAurasCompanion because some addon managers interfere with it
EnableAddOn("WeakAurasCompanion")

--These function stubs are defined here to reduce the number of errors that occur if WeakAuras.lua fails to compile
function WeakAuras.RegisterRegionType()
end

function WeakAuras.RegisterRegionOptions()
end

function WeakAuras.StartProfileSystem()
end

function WeakAuras.StartProfileAura()
end

function WeakAuras.StopProfileSystem()
end

function WeakAuras.StopProfileAura()
end

-- if weakauras shuts down due to being installed on the wrong target, keep the bindings from erroring
function WeakAuras.StartProfile()
end

function WeakAuras.StopProfile()
end

function WeakAuras.PrintProfile()
end

function WeakAuras.CountWagoUpdates()
  -- XXX this is to work around the Companion app trying to use our stuff!
  return 0
end
