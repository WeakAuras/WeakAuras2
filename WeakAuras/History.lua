--[[
This file contains all of the interfaces to the history collection. Indexed by uid of the active display.

History:
  Table containing historical information about display:
  source: string indicating where this data came from. Possible values:
    "user": aura was created by the user via the WeakAuras interface
    "import": aura was imported via WeakAuras.Import (i.e. pasted string or addon channel transmission)
    "addon": aura was imported via WeakAuras.RegisterDisplay (i.e. an addon requested the addition)
  data: snapshot of data as it was at last import, or nil if source == "user", and the user has not chosen to save their changes to history

--]]

function WeakAuras.SetHistory(uid, data, fromAddon, addon)
  if uid and data then
    db.history[uid] = db.history[uid] or {}
    db.history[uid].data = data
    db.history[uid].source = fromAddon and "addon" or "import"
    db.history[uid].addon = fromAddon and (addon or "unknown") or nil
    db.history[uid].skippedVersions = db.history[uid].skippedVersions or {}
    db.history[uid].lastUpdate = time()
  end
end

function WeakAuras.GetHistory(uid)
  return uid and db.history[uid]
end

function WeakAuras.RemoveHistory(uid)
  if uid then
    db.history[uid] = nil
  end
end

function WeakAuras.SkipVersion(uid, version, skip)
  local history = WeakAuras.GetHistory(uid)
  if skip == nil then
    skip = true
  end
  if history then
    history.skippedVersions[version] = skip
  end
end

function WeakAuras.IsVersionSkipped(uid, version)
  local history = WeakAuras.GetHistory(uid)
  if history then
    return history.skippedVersions[version]
  end
end

function WeakAuras.RestoreFromHistory(uid)
  local history = WeakAuras.GetHistory(uid)
  if history and history.data then
    WeakAuras.Add(CopyTable(history.data))
  end
end

function WeakAuras.ClearOldHistory(daysBack, includeNonDeleted)
  local cutoffTime = time() - ((daysBack or 30) * 86400) -- eighty six, four hundred seconds in a day...
  for uid, history in pairs(db.history) do
    if (includeNonDeleted or not WeakAuras.GetDataByUID(uid))
    and (history.lastUpdate < cutoffTime) then
      db.history[uid] = nil
    end
  end
end
