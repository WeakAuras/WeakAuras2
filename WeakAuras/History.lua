--[[
This file contains all of the interfaces to the history collection. Indexed by uid of the active display.

History:
  Table containing historical information about display:
  source: string indicating where this data came from. Possible values:
    "user": aura was created by the user via the WeakAuras interface
    "import": aura was imported via WeakAuras.Import (i.e. pasted string or addon channel transmission)
    "addon": aura was imported via WeakAuras.RegisterDisplay (i.e. an addon requested the addition)
  data: snapshot of data as it was at last import, or nil if source == "user", and the user has not chosen to save their changes to history
  addon: if source == "addon", then this string indicates which addon supplied the last import
  skippedVersions: record of versions that the user has indicated they don't wish to see update notifications for
  allowUpdates: if false, then WeakAuras will ignore any addon-sourced update requests
  lastUpdate: UNIX timestamp of the last time the user completed an import for this display
--]]
if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local history -- history db upvalue

function WeakAuras.LoadHistory(historydb, ageCutoff)
  history = historydb
  if ageCutoff then
    WeakAuras.ClearOldHistory(ageCutoff)
  end
end

function WeakAuras.SetHistory(uid, data, source, addon)
  if uid and data then
    history[uid] = history[uid] or {}
    local hist = history[uid]
    hist.data = data
    hist.source = source
    hist.addon = source == "addon" and (addon or "unknown") or nil
    hist.skippedVersions = hist.skippedVersions or {}
    hist.lastUpdate = time()
    if hist.allowUpdates == nil then
      hist.allowUpdates = true
    end
  end
end

function WeakAuras.GetHistory(uid)
  return uid and history[uid]
end

function WeakAuras.RemoveHistory(uid)
  if uid then
    history[uid] = nil
  end
end

function WeakAuras.AllowUpdates(uid, allowed)
  local hist = WeakAuras.Gethistory(uid)
  if hist then
    hist.allowUpdates = allowed ~= false
  end
end

function WeakAuras.IsUpdateAllowed(uid)
  local hist = WeakAuras.GetHistory(uid)
  return hist and hist.allowUpdates
end

function WeakAuras.SkipVersion(uid, version, skip)
  local hist = WeakAuras.GetHistory(uid)
  if hist then
    hist.skippedVersions[version] = skip ~= false
  end
end

function WeakAuras.IsVersionSkipped(uid, version)
  local hist = WeakAuras.GetHistory(uid)
  if hist then
    return hist.skippedVersions[version]
  end
end

function WeakAuras.RestoreFromHistory(uid)
  local hist = WeakAuras.GetHistory(uid)
  if hist and hist.data then
    WeakAuras.Add(CopyTable(hist.data))
  end
end

function WeakAuras.ClearOldHistory(daysBack, includeNonDeleted)
  local cutoffTime = time() - ((daysBack or 30) * 86400) -- eighty six, four hundred seconds in a day...
  for uid, hist in pairs(history) do
    if (includeNonDeleted or not WeakAuras.GetDataByUID(uid))
    and (hist.lastUpdate < cutoffTime) then
      history[uid] = nil
    end
  end
end
