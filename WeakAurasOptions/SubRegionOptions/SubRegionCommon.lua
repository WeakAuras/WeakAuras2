if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

-- Magic constant
local deleteCondition = {}

local function AdjustConditions(data, replacements)
  if (data.conditions) then
    for conditionIndex, condition in ipairs(data.conditions) do
      for changeIndex, change in ipairs(condition.changes) do
        if change.property then
          local sub, rest = string.match(change.property, "^(sub.%d+%.)(.+)$")
          if sub and replacements[sub] then
            if replacements[sub] == deleteCondition then
              change.property = nil
            else
              change.property = replacements[sub] .. rest
            end
          end
        end
      end
    end
  end
end

function WeakAuras.DeleteSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tremove(data.subRegions, index)

    local replacements = {
      ["sub." .. index .. "."] = deleteCondition
    }

    for i = index + 1, #data.subRegions + 1 do
      replacements["sub." .. i .. "."] = "sub." .. (i - 1) .. "."
    end

    AdjustConditions(data, replacements);

    WeakAuras.Add(data)
    OptionsPrivate.ClearOptions(data.id)
  end
end

function OptionsPrivate.MoveSubRegionUp(data, index, regionType)
  if not data.subRegions or index <= 1 then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    data.subRegions[index - 1], data.subRegions[index] = data.subRegions[index], data.subRegions[index - 1]

    local replacements = {
      ["sub." .. (index -1) .. "."] = "sub." .. index .. ".",
      ["sub." .. index .. "."] = "sub." .. (index - 1) .. ".",
    }

    AdjustConditions(data, replacements);

    WeakAuras.Add(data)
    OptionsPrivate.ClearOptions(data.id)
  end
end

function OptionsPrivate.MoveSubRegionDown(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType and data.subRegions[index + 1] then
    data.subRegions[index], data.subRegions[index + 1] = data.subRegions[index + 1], data.subRegions[index]

    local replacements = {
      ["sub." .. index .. "."] = "sub." .. (index + 1) .. ".",
      ["sub." .. (index + 1) .. "."] = "sub." .. index .. ".",
    }

    AdjustConditions(data, replacements);

    WeakAuras.Add(data)
    OptionsPrivate.ClearOptions(data.id)
  end
end

function OptionsPrivate.DuplicateSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tinsert(data.subRegions, index, CopyTable(data.subRegions[index]))


    local replacements = {}
    for i = index + 1, #data.subRegions do
      replacements["sub." .. i .. "."] = "sub." .. (i + 1) .. "."
    end
    AdjustConditions(data, replacements);

    WeakAuras.Add(data)
    OptionsPrivate.ClearOptions(data.id)
  end
end

function OptionsPrivate.AddUpDownDeleteDuplicate(options, parentData, index, subRegionType)
  options.__up = function()
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
      OptionsPrivate.MoveSubRegionUp(child, index, subRegionType)
    end
    WeakAuras.ClearAndUpdateOptions(parentData.id)
  end
  options.__down = function()
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
      OptionsPrivate.MoveSubRegionDown(child, index, subRegionType)
    end
    WeakAuras.ClearAndUpdateOptions(parentData.id)
  end
  options.__duplicate = function()
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
      OptionsPrivate.DuplicateSubRegion(child, index, subRegionType)
    end
    WeakAuras.ClearAndUpdateOptions(parentData.id)
  end
  options.__delete = function()
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
      WeakAuras.DeleteSubRegion(child, index, subRegionType)
    end
    WeakAuras.ClearAndUpdateOptions(parentData.id)
  end
end
