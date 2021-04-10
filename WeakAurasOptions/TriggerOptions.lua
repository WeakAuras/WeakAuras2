if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L

local removeFuncs = OptionsPrivate.commonOptions.removeFuncs
local replaceNameDescFuncs = OptionsPrivate.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = OptionsPrivate.commonOptions.replaceImageFuncs
local replaceValuesFuncs = OptionsPrivate.commonOptions.replaceValuesFuncs
local disabledAll = OptionsPrivate.commonOptions.CreateDisabledAll("trigger")
local hiddenAll = OptionsPrivate.commonOptions.CreateHiddenAll("trigger")
local getAll = OptionsPrivate.commonOptions.CreateGetAll("trigger")
local setAll = OptionsPrivate.commonOptions.CreateSetAll("trigger", getAll)
local executeAll = OptionsPrivate.commonOptions.CreateExecuteAll("trigger")

local flattenRegionOptions = OptionsPrivate.commonOptions.flattenRegionOptions
local fixMetaOrders = OptionsPrivate.commonOptions.fixMetaOrders

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
          return OptionsPrivate.Private.trigger_require_types;
        else
          return  OptionsPrivate.Private.trigger_require_types_one;
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
        vals[OptionsPrivate.Private.trigger_modes.first_active] = L["Dynamic information from first active trigger"];
        for i = 1, #data.triggers do
          vals[i] = L["Dynamic information from Trigger %i"]:format(i);
        end
        return vals;
      end,
      get = function()
        return data.triggers.activeTriggerMode or OptionsPrivate.Private.trigger_modes.first_active;
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
  OptionsPrivate.commonOptions.AddCodeOption(globalTriggerOptions, data, L["Custom"], "custom_trigger_combination", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-activation",
                          2.4, hideTriggerCombiner, {"triggers", "customTriggerLogic"}, false);

  return {
    global = globalTriggerOptions
  }
end

local collapsedId = {}
local maxTriggerNumForExpand = 0

local function AddOptions(allOptions, data)
  allOptions = union(allOptions, GetGlobalOptions(data))

  local triggerOptions = {}
  for index, trigger in ipairs(data.triggers) do
    local triggerSystemOptionsFunction = trigger.trigger.type and OptionsPrivate.Private.triggerTypesOptions[trigger.trigger.type]
    if (triggerSystemOptionsFunction) then
      triggerOptions = union(triggerOptions, triggerSystemOptionsFunction(data, index))
    else
      -- Unknown trigger system, empty options
      local options = {};
      OptionsPrivate.commonOptions.AddCommonTriggerOptions(options, data, index)
      OptionsPrivate.AddTriggerMetaFunctions(options, data, index, true)
      triggerOptions = union(triggerOptions, {
          ["trigger." .. index .. ".unknown"] = options
      })
    end
  end

  triggerOptions["addTriggerOption"] = {
    __title = L["Add Trigger"],
    __order = 5000,
    __withoutheader = true,
    __topLine = true,
    __collapsed = false,
    addTrigger = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Add Trigger"],
      order = 1,
      func = function()
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
        OptionsPrivate.SetCollapsed(collapsedId, "trigger", #data.triggers, false)
        maxTriggerNumForExpand = max(maxTriggerNumForExpand, #data.triggers)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    }
  }

  return union(allOptions, triggerOptions)
end

function OptionsPrivate.GetTriggerOptions(data)
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

function OptionsPrivate.ClearTriggerExpandState()
  for i = 1, maxTriggerNumForExpand do
    OptionsPrivate.SetCollapsed(collapsedId, "trigger", i, nil)
  end
  maxTriggerNumForExpand = 0
end

local triggerDeleteDialogOpen = false

function OptionsPrivate.AddTriggerMetaFunctions(options, data, triggernum)
  options.__title = L["Trigger %s"]:format(triggernum)
  options.__order = triggernum * 10
  options.__collapsed = #data.triggers > 1
  options.__isCollapsed = function()
    return OptionsPrivate.IsCollapsed(collapsedId, "trigger", triggernum, #data.triggers > 1)
  end
  options.__setCollapsed = function(info, button, secondCall)
    if not secondCall then
      local isCollapsed = OptionsPrivate.IsCollapsed(collapsedId, "trigger", triggernum, #data.triggers > 1)
      OptionsPrivate.SetCollapsed(collapsedId, "trigger", triggernum, not isCollapsed)
      maxTriggerNumForExpand = max(maxTriggerNumForExpand, triggernum)
    end
  end
  options.__up =
  {
    disabled = function()
      return triggernum < 2
    end,
    func = function()
      if (moveTriggerDownImpl(data, triggernum - 1)) then
        WeakAuras.Add(data);
        OptionsPrivate.MoveCollapseDataUp(collapsedId, "trigger", {triggernum})
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
        OptionsPrivate.MoveCollapseDataDown(collapsedId, "trigger", {triggernum})
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
    func = function(...)
      if triggerDeleteDialogOpen then
        -- This function is called multiple times if multiple auras are selected
        return
      end

      local canDelete = false
      -- Since we want to handle all selected auras in one dialog, we have to iterate over GetPickedDisplay
      local picked = OptionsPrivate.GetPickedDisplay()
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(picked) do
        if #child.triggers > 1 and #child.triggers >= triggernum then
          canDelete = true
          break;
        end
      end

      if canDelete then
        StaticPopupDialogs["WEAKAURAS_CONFIRM_TRIGGER_DELETE"] = {
          text = L["You are about to delete a trigger. |cFFFF0000This cannot be undone!|r Would you like to continue?"],
          button1 = L["Delete"],
          button2 = L["Cancel"],
          OnAccept = function()
            for child in OptionsPrivate.Private.TraverseLeafsOrAura(picked) do
              if #child.triggers > 1 and #child.triggers >= triggernum then
                tremove(child.triggers, triggernum)
                DeleteConditionsForTrigger(child, triggernum)
                WeakAuras.Add(child)
                OptionsPrivate.RemoveCollapsed(collapsedId, "trigger", {triggernum})
                OptionsPrivate.ClearOptions(child.id)
              end
            end

            WeakAuras.FillOptions()
            triggerDeleteDialogOpen = false
          end,
          OnCancel = function()
            triggerDeleteDialogOpen = false
          end,
          showAlert = true,
          whileDead = true,
          preferredindex = STATICPOPUP_NUMDIALOGS,
        }
        triggerDeleteDialogOpen = true
        StaticPopup_Show("WEAKAURAS_CONFIRM_TRIGGER_DELETE")
      end
    end
  }
  if (GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0) then
    options.__applyTemplate = function()
      WeakAuras.OpenTriggerTemplate(data)
    end
  end
end
