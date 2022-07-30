local AddonName, Private = ...
WeakAuras = {}
WeakAuras.L = {}
WeakAuras.frames = {}

WeakAuras.normalWidth = 1.3
WeakAuras.halfWidth = WeakAuras.normalWidth / 2
WeakAuras.doubleWidth = WeakAuras.normalWidth * 2

local versionStringFromToc = GetAddOnMetadata("WeakAuras", "Version")
local versionString = "@project-version@"
local buildTime = "@build-time@"

local flavorFromToc = GetAddOnMetadata("WeakAuras", "X-Flavor")
local flavorFromTocToNumber = {
  Vanilla = 1,
  TBC = 2,
  Wrath = 3,
  Mainline = 10
}
local flavor = flavorFromTocToNumber[flavorFromToc]

--@debug@
if versionStringFromToc == "@project-version@" then
  versionStringFromToc = "Dev"
  buildTime = "Dev"
end
--@end-debug@

WeakAuras.versionString = versionStringFromToc
WeakAuras.buildTime = buildTime
WeakAuras.newFeatureString = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t"
WeakAuras.BuildInfo = select(4, GetBuildInfo())

function WeakAuras.IsClassic()
  return flavor == 1
end

function WeakAuras.IsBCC()
  return flavor == 2
end

function WeakAuras.IsWrathClassic()
  return flavor == 3
end

function WeakAuras.IsRetail()
  return flavor == 10
end

function WeakAuras.IsClassicOrBCC()
  return WeakAuras.IsClassic() or WeakAuras.IsBCC()
end

function WeakAuras.IsClassicOrBCCOrWrath()
  return WeakAuras.IsClassic() or WeakAuras.IsBCC() or WeakAuras.IsWrathClassic()
end

function WeakAuras.IsBCCOrWrath()
  return WeakAuras.IsBCC() or WeakAuras.IsWrathClassic()
end

function WeakAuras.IsBCCOrWrathOrRetail()
  return WeakAuras.IsBCC() or WeakAuras.IsWrathClassic() or WeakAuras.IsRetail()
end

function WeakAuras.IsWrathOrRetail()
  return WeakAuras.IsRetail() or WeakAuras.IsWrathClassic()
end


WeakAuras.prettyPrint = function(...)
  print("|cff9900ffWeakAuras:|r ", ...)
end

-- Force enable WeakAurasCompanion and Archive because some addon managers interfere with it
EnableAddOn("WeakAurasCompanion")
EnableAddOn("WeakAurasArchive")

local libsAreOk = true
do
  local StandAloneLibs = {
    "Archivist",
    "LibStub"
  }
  local LibStubLibs = {
    "CallbackHandler-1.0",
    "AceConfig-3.0",
    "AceConsole-3.0",
    "AceGUI-3.0",
    "AceEvent-3.0",
    "AceGUISharedMediaWidgets-1.0",
    "AceTimer-3.0",
    "AceSerializer-3.0",
    "AceComm-3.0",
    "LibSharedMedia-3.0",
    "LibDataBroker-1.1",
    "LibCompress",
    "SpellRange-1.0",
    "LibCustomGlow-1.0",
    "LibDBIcon-1.0",
    "LibGetFrame-1.0",
    "LibSerialize",
  }
  if WeakAuras.IsClassic() then
    tinsert(LibStubLibs, "LibClassicSpellActionCount-1.0")
    tinsert(LibStubLibs, "LibClassicCasterino")
    tinsert(LibStubLibs, "LibClassicDurations")
  end
  for _, lib in ipairs(StandAloneLibs) do
    if not lib then
        libsAreOk = false
        WeakAuras.prettyPrint("Missing library:", lib)
    end
  end
  if LibStub then
    for _, lib in ipairs(LibStubLibs) do
        if not LibStub:GetLibrary(lib, true) then
          libsAreOk = false
          WeakAuras.prettyPrint("Missing library:", lib)
        end
    end
  else
    libsAreOk = false
  end
end

function WeakAuras.IsLibsOK()
  return libsAreOk
end

if not WeakAuras.IsLibsOK() then
  C_Timer.After(1, function() WeakAuras.prettyPrint("WeakAuras is missing necessary libraries. Please reinstall a proper package.") end)
end

-- These function stubs are defined here to reduce the number of errors that occur if WeakAuras.lua fails to compile
function WeakAuras.RegisterRegionType()
end

function WeakAuras.RegisterRegionOptions()
end

function Private.StartProfileSystem()
end

function Private.StartProfileAura()
end

function Private.StopProfileSystem()
end

function Private.StopProfileAura()
end

function Private.StartProfileUID()
end

function Private.StopProfileUID()
end

-- If WeakAuras shuts down due to being installed on the wrong target, keep the bindings from erroring
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
