WowApiWrapper = {}
WowApiWrapper.__index = WowApiWrapper

local instance;

function WowApiWrapper:create()
    -- We don't want to make more than one instance of the API wrapper
    -- as there's no need.

    -- Instead, store the one we created locally and if someone asks for a new
    -- one, just give them the one we already have.
    if not instance then
        local wrapper = {}
        setmetatable(wrapper, WowApiWrapper)

        WowApiWrapper:ConnectGlobalFunctions(wrapper)
        instance = wrapper
    end

    return instance
end

function WowApiWrapper:ConnectGlobalFunctions(wrapper)
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsAddOnLoaded")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "InCombatLockdown")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "LoadAddOn")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "setfenv")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitName")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetRealmName")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetRealZoneText")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetCurrentMapAreaID")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitGroupRolesAssigned")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitRace")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitFactionGroup")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsInRaid")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitClass")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitExists")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitGUID")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitAffectingCombat")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetSpecialization")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetActiveSpecGroup")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetInstanceInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsInInstance")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetNumGroupMembers")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitIsUnit")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetRaidRosterInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetSpecialization")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetSpecializationRole")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitInVehicle")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitHasVehicleUI")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetSpellInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "SendChatMessage")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetChannelName")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitInBattleground")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitInRaid")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitInParty")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "PlaySoundFile")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "PlaySoundKitID")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetTime")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetSpellLink")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetItemInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "CreateFrame")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsShiftKeyDown")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetScreenWidth")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetScreenHeight")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetCursorPosition")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "random")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UpdateAddOnCPUUsage")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetFrameCPUUsage")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "debugprofilestop")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "debugstack")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsSpellKnown")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetTalentInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetPvpTalentInfo")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "GetAddOnEnableState")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "IsPlayerMoving")
    WowApiWrapper:ConnectGlobalFunction(wrapper, "UnitIsDead")
end

function WowApiWrapper:ConnectGlobalFunction(wrapper, name)
    wrapper[name] = _G[name]
end