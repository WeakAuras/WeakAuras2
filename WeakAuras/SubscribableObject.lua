if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

--- @class SubscribableObject
--- @field events table<string, frame[]> Subscribers ordered by "priority"
--- @field subscribers table<string, frame> Subscribers lookup
--- @field callbacks table<string, fun():nil>
--- @field ClearSubscribers fun(self: SubscribableObject)
--- @field ClearCallbacks fun(self: SubscribableObject)
--- @field AddSubscriber fun(self: SubscribableObject, event: string, subscriber: frame, highPriority: boolean?)
--- @field RemoveSubscriber fun(self: SubscribableObject, event: string, subscriber: frame)
--- @field SetOnSubscriptionStatusChanged fun(self: SubscribableObject, event: string, cb: fun())
--- @field Notify fun(self: SubscribableObject, event: type, ...: any)
--- @field HasSubscribers fun(self: SubscribableObject, event: string): boolean
local SubscribableObject =
{
  events = {},
  subscribers = {},
  callbacks = {},

  --- @type fun(self: SubscribableObject)
  ClearSubscribers = function(self)
    self.events = {}
    self.subscribers = {}
  end,

  --- @type fun(self: SubscribableObject)
  ClearCallbacks = function(self)
    self.callbacks = {}
  end,

  --- @type fun(self: SubscribableObject, event: string, subscriber: frame, highPriority: boolean?)
  AddSubscriber = function(self, event, subscriber, highPriority)
    if not subscriber[event] then
      print("Can't register for ", event, " ", subscriber, subscriber.type)
      return
    end

    self.events[event] = self.events[event] or {}
    self.subscribers[event] = self.subscribers[event] or {}
    if self.subscribers[event][subscriber] then
      -- Already subscribed, just return
      return
    end
    self.subscribers[event][subscriber] = true
    local pos = highPriority and 1 or (#self.events[event] + 1)
    if TableHasAnyEntries(self.events[event]) then
      tinsert(self.events[event], pos, subscriber)
    else
      tinsert(self.events[event], pos, subscriber)
      if self.callbacks[event] then
        self.callbacks[event]()
      end
    end
  end,

  --- @type fun(self: SubscribableObject, event: string, subscriber: frame)
  RemoveSubscriber = function(self, event, subscriber)
    if self.events[event] then
      if not self.subscribers[event][subscriber] then
        -- Not subscribed
        return
      end

      self.subscribers[event][subscriber] = nil
      local index = tIndexOf(self.events[event], subscriber)
      if index then
        tremove(self.events[event], index)
        if not TableHasAnyEntries(self.events[event]) then
          if self.callbacks[event] then
            self.callbacks[event]()
          end
        end
      end
    end
  end,

  --- @type fun(self: SubscribableObject, event: string, cb: fun())
  SetOnSubscriptionStatusChanged = function(self, event, cb)
    self.callbacks[event] = cb
  end,

  --- @type fun(self: SubscribableObject, event: type, ...: any)
  Notify = function(self, event, ...)
    if self.events[event] then
      for _, subscriber in ipairs(self.events[event]) do
        subscriber[event](subscriber, ...)
      end
    end
  end,

  --- @type fun(self: SubscribableObject, event: string): boolean
  HasSubscribers = function(self, event)
    return self.events[event] and TableHasAnyEntries(self.events[event])
  end
}

function Private.CreateSubscribableObject()
  return CopyTable(SubscribableObject)
end
