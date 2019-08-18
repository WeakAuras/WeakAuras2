if not WeakAuras.IsCorrectVersion() then return end

function WeakAuras.DeleteSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tremove(data.subRegions, index)
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

function WeakAuras.MoveSubRegionUp(data, index, regionType)
  if not data.subRegions or index <= 1 then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    data.subRegions[index - 1], data.subRegions[index] = data.subRegions[index], data.subRegions[index - 1]
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

function WeakAuras.MoveSubRegionDown(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType and data.subRegions[index + 1] then
    data.subRegions[index], data.subRegions[index + 1] = data.subRegions[index + 1], data.subRegions[index]
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

function WeakAuras.DuplicateSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tinsert(data.subRegions, index, CopyTable(data.subRegions[index]))
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end
