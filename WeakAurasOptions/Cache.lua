-- Lua APIs
local select, pairs, next, type, assert, error, coroutine = select, pairs, next, type, assert, error, coroutine

-- WoW APIs
local GetSpellInfo, IsSpellKnown = GetSpellInfo, IsSpellKnown

-- GLOBALS: WeakAuras

local WeakAuras = WeakAuras

local spellCache = {}
WeakAuras.spellCache = spellCache

local cache
local bestIcon = {}
local dynFrame = WeakAuras.dynFrame

-- Builds a cache of name/icon pairs from existing spell data
-- Why? Because if you call GetSpellInfo with a spell name, it only works if the spell is an actual castable ability,
-- but if you call it with a spell id, you can get buffs, talents, etc. This is useful for displaying faux aura information
-- for displays that are not actually connected to auras (for non-automatic icon displays with predefined icons)
--
-- This is a rather slow operation, so it's only done once, and the result is subsequently saved
function spellCache.Build(callback)
  if cache then
    local co = coroutine.create(function()
      local id = 0
      local misses = 0

      while misses < 400 do
        id = id + 1
        local name, _, icon = GetSpellInfo(id)

        if(icon == 136243) then -- 136243 is the a gear icon, we can ignore those spells
          misses = 0;
        elseif name and name ~= "" then
          cache[name] = cache[name] or {}
          cache[name][id] = icon
          misses = 0
        else
          misses = misses + 1
        end

        coroutine.yield()
      end

      if callback then
        callback()
      end
    end)
    dynFrame:AddAction(callback, co)
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.GetIcon(name)
  if cache then
    if (bestIcon[name]) then
      return bestIcon[name]
    end

    local icons = cache[name]
    local bestMatch = nil
    if (icons) then
      for spellId, icon in pairs(icons) do
        if (not bestMatch) then
          bestMatch = spellId
        elseif(IsSpellKnown(spellId)) then
          bestMatch = spellId
        end
      end
    end

    return bestMatch and icons[bestMatch]
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.AddIcon(name, id, icon)
  if cache then
    if name then
      cache[name] = cache[name] or {}
      if id and icon then
        cache[name][id] = icon
      end
    end
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.Get()
  if cache then
    return cache
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.Load(data)
  cache = cache or data
end
