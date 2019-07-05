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
  lastUpdate: UNIX timestamp of the last time the user completed an import for this display
--]]

local WeakAuras = WeakAuras
local history -- history db upvalue

function WeakAuras.LoadHistory(historydb)
  history = historydb
  if history.clearOldHistory == nil then
    history.clearOldHistory = 30
  end
  if history.clearOldHistory then
    WeakAuras.ClearOldHistory(history.clearOldHistory)
  end
end

function WeakAuras.SetHistory(uid, data, fromAddon, addon)
  if uid and data then
    history[uid] = history[uid] or {}
    history[uid].data = data
    history[uid].source = fromAddon and "addon" or "import"
    history[uid].addon = fromAddon and (addon or "unknown") or nil
    history[uid].skippedVersions = history[uid].skippedVersions or {}
    history[uid].lastUpdate = time()
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

function WeakAuras.SkipVersion(uid, version, skip)
  local hist = WeakAuras.GetHistory(uid)
  if skip == nil then
    skip = true
  end
  if hist then
    hist.skippedVersions[version] = skip
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
