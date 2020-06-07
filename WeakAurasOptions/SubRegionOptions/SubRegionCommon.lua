if not WeakAuras.IsCorrectVersion() then return end

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
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)

    local replacements = {
      ["sub." .. index .. "."] = deleteCondition
    }

    for i = index + 1, #data.subRegions + 1 do
      replacements["sub." .. i .. "."] = "sub." .. (i - 1) .. "."
    end

    AdjustConditions(data, replacements);
  end
end

function WeakAuras.MoveSubRegionUp(data, index, regionType)
  if not data.subRegions or index <= 1 then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    data.subRegions[index - 1], data.subRegions[index] = data.subRegions[index], data.subRegions[index - 1]
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)

    local replacements = {
      ["sub." .. (index -1) .. "."] = "sub." .. index .. ".",
      ["sub." .. index .. "."] = "sub." .. (index - 1) .. ".",
    }

    AdjustConditions(data, replacements);
  end
end

function WeakAuras.MoveSubRegionDown(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType and data.subRegions[index + 1] then
    data.subRegions[index], data.subRegions[index + 1] = data.subRegions[index + 1], data.subRegions[index]
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)

    local replacements = {
      ["sub." .. index .. "."] = "sub." .. (index + 1) .. ".",
      ["sub." .. (index + 1) .. "."] = "sub." .. index .. ".",
    }

    AdjustConditions(data, replacements);
  end
end

function WeakAuras.DuplicateSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tinsert(data.subRegions, index, CopyTable(data.subRegions[index]))
    WeakAuras.Add(data)
    WeakAuras.ClearAndUpdateOptions(data.id)

    local replacements = {}
    for i = index + 1, #data.subRegions do
      replacements["sub." .. i .. "."] = "sub." .. (i + 1) .. "."
    end
    AdjustConditions(data, replacements);
  end
end
