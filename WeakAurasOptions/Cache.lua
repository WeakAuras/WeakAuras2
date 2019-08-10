if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local pairs, error, coroutine = pairs, error, coroutine

-- WoW APIs
local GetSpellInfo, IsSpellKnown = GetSpellInfo, IsSpellKnown

local WeakAuras = WeakAuras

local spellCache = {}
WeakAuras.spellCache = spellCache

local cache
local bestIcon = {}
local dynFrame = WeakAuras.dynFrame

-- Builds a cache of name/icon pairs from existing spell data
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
  if (name == nil) then
    return nil;
  end
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
        elseif(type(spellId) == "number" and IsSpellKnown(spellId)) then
          bestMatch = spellId
        end
      end
    end

    bestIcon[name] = bestMatch and icons[bestMatch];
    return bestIcon[name];
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

-- This function computes the Levenshtein distance between two strings
-- It is used in this program to match spell icon textures with "good" spell names; i.e.,
-- spell names that are very similar to the name of the texture
local function Lev(str1, str2)
  local matrix = {};
  for i=0, str1:len() do
    matrix[i] = {[0] = i};
  end
  for j=0, str2:len() do
    matrix[0][j] = j;
  end
  for j=1, str2:len() do
    for i =1, str1:len() do
      if(str1:sub(i, i) == str2:sub(j, j)) then
        matrix[i][j] = matrix[i-1][j-1];
      else
        matrix[i][j] = math.min(matrix[i-1][j], matrix[i][j-1], matrix[i-1][j-1]) + 1;
      end
    end
  end

  return matrix[str1:len()][str2:len()];
end

function spellCache.BestKeyMatch(nearkey)
  local bestKey = "";
  local bestDistance = math.huge;
  local partialMatches = {};
  if cache[nearkey] then
    return nearkey
  end
  for key, value in pairs(cache) do
    if key:lower() == nearkey:lower() then
      return key
    end
    if(key:lower():find(nearkey:lower(), 1, true)) then
      partialMatches[key] = value;
    end
  end
  for key, value in pairs(partialMatches) do
    local distance = Lev(nearkey, key);
    if(distance < bestDistance) then
      bestKey = key;
      bestDistance = distance;
    end
  end

  return bestKey;
end

function spellCache.CorrectAuraName(input)
  if (not cache) then
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end

  local spellId = WeakAuras.SafeToNumber(input);
  if(spellId) then
    local name, _, icon = GetSpellInfo(spellId);
    if(name) then
      spellCache.AddIcon(name, spellId, icon)
      return name, spellId;
    else
      return "Invalid Spell ID";
    end
  else
    local ret = spellCache.BestKeyMatch(input);
    if(ret == "") then
      return "No Match Found", nil;
    else
      return ret, nil;
    end
  end
end
