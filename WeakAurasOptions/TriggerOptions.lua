
local L = WeakAuras.L

local removeFuncs = WeakAuras.commonOptions.removeFuncs
local replaceNameDescFuncs = WeakAuras.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = WeakAuras.commonOptions.replaceImageFuncs
local replaceValuesFuncs = WeakAuras.commonOptions.replaceValuesFuncs
local disabledAll = WeakAuras.commonOptions.CreateDisabledAll("trigger")
local hiddenAll = WeakAuras.commonOptions.CreateHiddenAll("trigger")
local getAll = WeakAuras.commonOptions.CreateGetAll("trigger")
local setAll = WeakAuras.commonOptions.CreateSetAll("trigger", getAll)
local executeAll = WeakAuras.commonOptions.CreateExecuteAll("trigger")

local flattenRegionOptions = WeakAuras.commonOptions.flattenRegionOptions
local fixMetaOrders = WeakAuras.commonOptions.fixMetaOrders

local subevent_actual_prefix_types = WeakAuras.subevent_actual_prefix_types;
local spellCache = WeakAuras.spellCache

local function union(table1, table2)
  local meta = {};
  for i,v in pairs(table1) do
    meta[i] = v;
  end
  for i,v in pairs(table2) do
    meta[i] = v;
  end
  return meta;
end

local function GetGlobalOptions(data)

  local triggerCount = 0
  local globalTriggerOptions = {
    __title = L["Trigger Combination"],
    __order = 1,
    disjunctive = {
      type = "select",
      name = L["Required for Activation"],
      width = WeakAuras.doubleWidth,
      order = 2,
      values = function()
        if #data.triggers > 1 then
          return WeakAuras.trigger_require_types;
        else
          return  WeakAuras.trigger_require_types_one;
        end
      end,
      get = function()
        if #data.triggers > 1 then
          return data.triggers.disjunctive or "all";
        else
          return (data.triggers.disjunctive and data.triggers.disjunctive ~= "all") and data.triggers.disjunctive or "any";
        end
      end,
      set = function(info, v)
        data.triggers.disjunctive = v;
        WeakAuras.Add(data);
      end
    },
    -- custom trigger combiner text editor added below
    activeTriggerMode = {
      type = "select",
      name = L["Dynamic Information"],
      width = WeakAuras.doubleWidth,
      order = 2.3,
      values = function()
        local vals = {};
        vals[WeakAuras.trigger_modes.first_active] = L["Dynamic information from first active trigger"];
        for i = 1, #data.triggers do
          vals[i] = L["Dynamic information from Trigger %i"]:format(i);
        end
        return vals;
      end,
      get = function()
        return data.triggers.activeTriggerMode or WeakAuras.trigger_modes.first_active;
      end,
      set = function(info, v)
        data.triggers.activeTriggerMode = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      hidden = function() return #data.triggers <= 1 end
    }
  }

  local function hideTriggerCombiner()
    return not (data.triggers.disjunctive == "custom")
  end
  WeakAuras.commonOptions.AddCodeOption(globalTriggerOptions, data, L["Custom"], "custom_trigger_combination", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-activation",
                          2.4, hideTriggerCombiner, {"triggers", "customTriggerLogic"}, false);

  return {
    global = globalTriggerOptions
  }
end

local function AddOptions(allOptions, data)
  allOptions = union(allOptions, GetGlobalOptions(data))

  local triggerOptions = {}
  for index, trigger in ipairs(data.triggers) do
    local triggerSystemOptionsFunction = trigger.trigger.type and WeakAuras.triggerTypesOptions[trigger.trigger.type]
    if (triggerSystemOptionsFunction) then
      triggerOptions = union(triggerOptions, triggerSystemOptionsFunction(data, index))
    else
      local options = {};
      WeakAuras.commonOptions.AddCommonTriggerOptions(options, data, index)
      WeakAuras.AddTriggerMetaFunctions(options, data, index)
      triggerOptions = union(triggerOptions, {
          ["trigger." .. index .. ".unknown"] = options
      })
    end
  end

  return union(allOptions, triggerOptions)
end

function WeakAuras.GetTriggerOptions(data)
  local allOptions = {}
  if data.controlledChildren then
    for index, childId in pairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId)
      allOptions = AddOptions(allOptions, childData)
    end
  else
    allOptions = AddOptions(allOptions, data)
  end

  fixMetaOrders(allOptions)

  local triggerOptions = {
    type = "group",
    name = L["Trigger"],
    order = 20,
    args = flattenRegionOptions(allOptions, false)
  }

  if data.controlledChildren then
    removeFuncs(triggerOptions, true);
    replaceNameDescFuncs(triggerOptions, data, "trigger");
    replaceImageFuncs(triggerOptions, data, "trigger");
    replaceValuesFuncs(triggerOptions, data, "trigger");

    triggerOptions.get = function(info, ...)
      return getAll(data, info, ...)
    end
    triggerOptions.set = function(info, ...)
      setAll(data, info, ...)
    end
    triggerOptions.hidden = function(info, ...)
      return hiddenAll(data, info, ...)
    end
    triggerOptions.disabled = function(info, ...)
      return disabledAll(data, info, ...)
    end

    triggerOptions.func = function(info, ...)
      return executeAll(data, info, ...)
    end
  end

  return triggerOptions
end

local function DeleteConditionsForTriggerHandleSubChecks(checks, triggernum)
  for _, check in ipairs(checks) do
    if (check.trigger == triggernum) then
      check.trigger = nil;
    end

    if (check.trigger and check.trigger > triggernum) then
      check.trigger = check.trigger - 1;
    end

    if (checks.checks) then
      DeleteConditionsForTriggerHandleSubChecks(checks.checks, triggernum);
    end
  end
end

local function DeleteConditionsForTrigger(data, triggernum)
  for _, condition in ipairs(data.conditions) do
    if (condition.check and condition.check.trigger == triggernum) then
      condition.check.trigger = nil;
    end

    if (condition.check and condition.check.trigger and condition.check.trigger > triggernum) then
      condition.check.trigger = condition.check.trigger - 1;
    end

    if (condition.check and condition.check.checks) then
      DeleteConditionsForTriggerHandleSubChecks(condition.check.checks, triggernum)
    end
  end
end

local function moveTriggerDownConditionCheck(check, i)
  if (check.trigger == i) then
    check.trigger = i + 1;
  elseif (check.trigger == i  + 1) then
    check.trigger = i;
  end
  if (check.checks) then
    for _, subCheck in ipairs(check.checks) do
      moveTriggerDownConditionCheck(subCheck, i);
    end
  end
end

local function moveTriggerDownImpl(data, i)
  if (i < 1 or i >= #data.triggers) then
    return false;
  end
  data.triggers[i], data.triggers[i + 1] = data.triggers[i + 1], data.triggers[i]
  for _, condition in ipairs(data.conditions) do
    moveTriggerDownConditionCheck(condition.check, i);
  end

  return true;
end

function WeakAuras.AddTriggerMetaFunctions(options, data, triggernum)
  options.__title = L["Trigger %s"]:format(triggernum)
  options.__order = triggernum * 10
  options.__add = function()
    tinsert(data.triggers,
      {
        trigger =
        {
          type = "aura2"
        },
        untrigger = {
        }
      })
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)
  end
  options.__up =
  {
    disabled = function()
      return triggernum < 2
    end,
    func = function()
      if (moveTriggerDownImpl(data, triggernum - 1)) then
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id);
      end
    end
  }
  options.__down =
  {
    disabled = function()
      return triggernum == #data.triggers
    end,
    func = function()
      if (moveTriggerDownImpl(data, triggernum)) then
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id);
      end
    end
  }
  options.__duplicate = function()
    local trigger = CopyTable(data.triggers[triggernum])
    tinsert(data.triggers, trigger)
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)
  end
  options.__delete = {
    disabled = function()
      return #data.triggers == 1
    end,
    func = function()
      if #data.triggers > 1 then
        tremove(data.triggers, triggernum)
        DeleteConditionsForTrigger(data, triggernum);
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end
  }
  if (GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0) then
    options.__applyTemplate = function()
      WeakAuras.OpenTriggerTemplate(data)
    end
  end
end
