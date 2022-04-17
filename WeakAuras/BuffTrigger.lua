--[[ BuffTrigger.lua
This used to contains the "aura" trigger for buffs and debuffs. Nowadays all functions do essentially nothing
]]--

if not WeakAuras.IsCorrectVersion() or not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local L = WeakAuras.L

local BuffTrigger = {}

function BuffTrigger.UnloadAll() end

function BuffTrigger.LoadDisplays(toLoad) end

function BuffTrigger.UnloadDisplays(toUnload) end

function BuffTrigger.FinishLoadUnload() end

function BuffTrigger.Delete(id) end

function BuffTrigger.Rename(oldid, newid) end

function BuffTrigger.Add(data)
  if data.triggers then
    local hasLegacyAuraTrigger = false
    for index, t in ipairs(data.triggers) do
      if t.trigger.type == "aura" then
        hasLegacyAuraTrigger = true
        break
      end
    end
    if hasLegacyAuraTrigger then
      Private.AuraWarnings.UpdateWarning(data.uid, "legacy", "warning", L["This aura has legacy aura trigger(s), which are no longer supported."])
    else
      Private.AuraWarnings.UpdateWarning(data.uid, "legacy")
    end
  end
end

function BuffTrigger.CanHaveDuration(data, triggernum)
  return false
end

function BuffTrigger.GetOverlayInfo(data, triggernum) return {} end

function BuffTrigger.CanHaveClones(data, triggernum) return false end

function BuffTrigger.CanHaveTooltip(data, triggernum) end

function BuffTrigger.SetToolTip(trigger, state) end

function BuffTrigger.GetNameAndIcon(data, triggernum) end

function BuffTrigger.GetAdditionalProperties(data, triggernum)
  return ""
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  return {}
end

function BuffTrigger.CreateFallbackState(data, triggernum, state)
  state.show = true;
  state.changed = true;
  state.progressType = "timed";
  state.duration = 0;
  state.expirationTime = math.huge;
end

function BuffTrigger.GetName(triggerType)
  if (triggerType == "aura") then
    return L["Legacy Aura (disabled)"];
  end
end

function BuffTrigger.GetTriggerDescription(data, triggernum, namestable)
  tinsert(namestable, {L["Legacy Aura (disabled):"], L[""]});
end

function BuffTrigger.CreateFakeStates(id, triggernum)
  local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  local data = WeakAuras.GetData(id)
  local state = {}
  BuffTrigger.CreateFallbackState(data, triggernum, state)
  allStates[""] = state
end

WeakAuras.RegisterTriggerSystem({"aura"}, BuffTrigger);
