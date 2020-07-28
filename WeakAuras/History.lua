if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras

local histRepo, migrationRepo
local function loadHistory()
  if not histRepo then
    histRepo = WeakAuras.LoadFromArchive("Repository", "history")
  end
  return histRepo
end

local function loadMigrations()
  if not migrationRepo then
    migrationRepo = WeakAuras.LoadFromArchive("Repository", "migration")
  end
  return migrationRepo
end

function WeakAuras.CleanArchive(historyCutoff, migrationCutoff)
  if type(historyCutoff) == "number" then
    local repo = loadHistory()
    local cutoffTime = time() - (historyCutoff * 86400)
    for uid, subStore in pairs(repo.stores) do
      -- Ideally we would just use Clean and not access the stores list directly,
      -- but that'd mean having Clean take a predicate which seems like overkill for the moment
      if not WeakAuras.GetDataByUID(uid) and subStore.timestamp < cutoffTime then
        repo:Drop(uid)
      end
    end
  end

  if type(migrationCutoff) == "number" then
    local repo = loadMigrations()
    repo:Clean(time() - (migrationCutoff * 86400))
  end
end

function WeakAuras.SetHistory(uid, data, source, addon)
  if uid and data then
    local repo = loadHistory()
    data.source = source
    data.addon = source == "addon" and addon or nil
    local hist = repo:Set(uid, data, true)
    return hist
  end
end

function WeakAuras.GetHistory(uid, load)
  return loadHistory():Get(uid, load)
end

function WeakAuras.RemoveHistory(uid)
  return loadHistory():Drop(uid)
end

function WeakAuras.RestoreFromHistory(uid)
  local _, histData = WeakAuras.GetHistory(uid, true)
  if histData then
    WeakAuras.Add(histData)
  end
end

function WeakAuras.SetMigrationSnapshot(uid, oldData)
  if type(oldData) == "table" then
    local repo = loadMigrations()
    repo:Set(uid, oldData)
  end
end

function WeakAuras.GetMigrationSnapshot(uid)
  return loadMigrations():GetData(uid)
end
