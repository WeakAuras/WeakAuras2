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
local Features = {
  ---@type table<string, feature>
  __feats = {}
}
Private.Features = Features

---@param id string
function Features:Exists(id)
  return self.__feats[id] ~= nil
end

---@param id string
function Features:Enabled(id)
    return self:Exists(id) and self.__feats[id].enabled
end

---@param id string
function Features:Enable(id)
  if self:Exists(id) and not self.__feats[id].enabled then
    self.__feats[id].enabled = true
    if self.__feats[id].persist then
      Private.db.features[id] = true
    end
    self.__feats[id].sub:Notify("ENABLED")
  end
end

---@param id string
function Features:Disable(id)
  if self:Exists(id) and self.__feats[id].enabled then
    self.__feats[id].enabled = false
    if self.__feats[id].persist then
      Private.db.features[id] = false
    end
    self.__feats[id].sub:Notify("DISABLED")
  end
end

-- enable persisted features from the db
function Features:Hydrate()
  for id, enabled in (Private.db.features) do
    if not self:Exists(id) then
      Private.db.features[id] = nil
    end
    if enabled then
      self:Enable(id)
    end
  end
end

---@param feature feature
function Features:Register(feature)
  if not self.__feats[feature.id] then
    self.__feats[feature.id] = feature
    feature.sub = Private.CreateSubscribableObject()
    for _, buildType in ipairs(feature.autoEnable or {}) do
      if Private.buildType == buildType then
        self:Enable(feature.id)
      end
    end
  end
end

---@param id string
---@param func function
-- hides a function behind a feature flag
function Features:Wrap(id, func)
  return function(...)
    if self:Enabled(id) then
      return func(...)
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

function Features:Subscribe(id, callback)
  if self:Exists(id) then
    self.__feats[id].sub:AddSubscriber("ENABLED", callback)
    self.__feats[id].sub:AddSubscriber("DISABLED", callback)
  end
end

-- sample debug feature
Features:Register({
  id = "debug",
  autoEnable = {"dev"}
})

