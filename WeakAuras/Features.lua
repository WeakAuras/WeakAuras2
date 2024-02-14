---@type string, Private
local addon, Private = ...

---@alias BuildType "dev" | "pr" | "alpha" | "beta" | "release"

---@class feature
---@field id string
---@field autoEnable? BuildType[]
---@field requiredByAura? fun(self: self, aura: auraData): boolean
---@field enabled? boolean
---@field persist? true
---@field sub? SubscribableObject

---@class Features
---@field private db? table<string, boolean>
---@field private __feats table<string, feature>
---@field private hydrated boolean
local Features = {
  __feats = {},
  hydrated = false,
}
Private.Features = Features

---@param id string
function Features:Exists(id)
  return self.__feats[id] ~= nil
end

---@param id string
function Features:Enabled(id)
    return self.hydrated and self:Exists(id) and self.__feats[id].enabled
end

---@param id string
function Features:Enable(id)
  if not self:Exists(id) then return end
  if not self.hydrated then
    error("Cannot enable a feature before hydration", 2)
  elseif not self.__feats[id].enabled then
    self.__feats[id].enabled = true
    if self.__feats[id].persist then
      self.db[id] = true
    end
    self.__feats[id].sub:Notify("Enable")
  end
end

---@param id string
function Features:Disable(id)
  if not self:Exists(id) then return end
  if not self.hydrated then
    error("Cannot disable a feature before hydration", 2)
  elseif self.__feats[id].enabled then
    self.__feats[id].enabled = false
    if self.__feats[id].persist then
      self.db[id] = false
    end
    self.__feats[id].sub:Notify("Disable")
  end
end

---@return {id: string, enabled: boolean}[]
function Features:ListFeatures()
  if not self.hydrated then return {} end
  local list = {}
  for id, feature in pairs(self.__feats) do
    table.insert(list, {
      id = id,
      enabled = feature.enabled
    })
  end
  table.sort(list, function(a, b)
    return a.id < b.id
  end)
  return list
end

function Features:Hydrate()
  self.db = Private.db.features
  for id, feature in pairs(self.__feats) do
    local enable = false
    if self.db[id] ~= nil then
      enable = self.db[id]
    else
      for _, buildType in ipairs(feature.autoEnable or {}) do
        if WeakAuras.buildType == buildType then
          enable = true
          break
        end
      end
    end
    feature.enabled = enable
  end
  self.hydrated = true
  for _, feature in pairs(self.__feats) do
    -- cannot notify before hydrated flag is set, or we risk consumers getting wrong information
    feature.sub:Notify(feature.enabled and "Enable" or "Disable")
  end
end

---@param feature feature
function Features:Register(feature)
  if self.hydrated then
    error("Cannot register a feature after hydration", 2)
  end
  if not self.__feats[feature.id] then
    self.__feats[feature.id] = feature
    feature.sub = Private.CreateSubscribableObject()
  end
end

---@param id string
---@param enabledFunc function
---@param disabledFunc? function
---hide a code path behind a feature flag,
---optionally provide a disabled path
function Features:Wrap(id, enabledFunc, disabledFunc)
  return function(...)
    if self:Enabled(id) then
      return enabledFunc(...)
    else
      if disabledFunc then
        return disabledFunc(...)
      end
    end
  end
end

---@param data auraData
---@return boolean, table<string, boolean>
function Features:AuraCanFunction(data)
  local enabled = true
  local reasons = {}

  for _, feature in pairs(self.__feats) do
    if feature.requiredByAura and not feature:requiredByAura(data) then
      enabled = false
      reasons[feature.id] = false
    end
  end

  return enabled, reasons
end

---@param id string
---@param enable function
---@param disable function
function Features:Subscribe(id, enable, disable)
  local tbl = {
    Enable = enable,
    Disable = disable
  }
  if self:Exists(id) then
    self.__feats[id].sub:AddSubscriber("Enable", tbl)
    self.__feats[id].sub:AddSubscriber("Disable", tbl)
  end
end


Features:Register({
  id = "debug",
  autoEnable = {"dev"}
})
