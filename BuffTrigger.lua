--[[ BuffTrigger.lua
This file contains the "aura" trigger for buffs and debuffs.

It registters the BuffTrigger table for the trigger type "aura".
It has the following API:

Modernize(data)
  Updates all buff triggers in data
]]
-- Lua APIs
local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local tostring, select, pairs, next, type, unpack = tostring, select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable = setmetatable, getmetatable

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local BuffTrigger = {};

local timer = WeakAuras.timer;


function BuffTrigger.Modernize(data)
  -- Give Name Info and Stack Info options to group auras
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and trigger.type == "aura" and trigger.unit and trigger.unit == "group") then
      trigger.name_info = trigger.name_info or "aura";
      trigger.stack_info = trigger.stack_info or "count";
    end
  end

  -- Fix corrupted data to time remaining and stacks (ticket #366, mod allowed users to input non numeric values)
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and (trigger.count) and not tonumber(trigger.count)) then trigger.count = 0 end
    if(trigger and (trigger.remaining) and not tonumber(trigger.remaining)) then trigger.remaining = 0 end
  end
end


WeakAuras.RegisterTriggerSystem({"aura"}, BuffTrigger);