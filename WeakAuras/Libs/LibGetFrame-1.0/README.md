# LibGetFrame

Return unit frame for a given unit

## Usage

```Lua
local LGF = LibStub("LibGetFrame-1.0")
local frame = LGF.GetUnitFrame(unit , options)

local callback = function(event, frame, unit)
  if event == "GETFRAME_REFRESH" then
    -- cache was refreshed
  end
  if event == "FRAME_UNIT_UPDATE" then
    -- 'frame' was updated and is now a match for 'unit'
  end
  if event == "FRAME_UNIT_REMOVED" then
    -- 'frame' was updated and is no longer a match for 'unit'
  end
end

LGF.RegisterCallback("MyAddonName", "GETFRAME_REFRESH", callback)
LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_UPDATE", callback)
LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_REMOVED", callback)

```

## Public functions

```Lua
LGF:GetUnitFrame(unit, options)
```

Options:

- framePriorities : array

- ignorePlayerFrame : boolean (default true)
- ignoreTargetFrame : boolean (default true)
- ignoreTargettargetFrame : boolean (default true)
- ignorePartyFrame : boolean (default false)
- ignorePartyTargetFrame : boolean (default true)
- ignoreRaidFrame : boolean (default false)

- playerFrames : array
- targetFrames : array
- targettargetFrames : array
- partyFrames : array
- partyTargetFrames : array
- raidFrames : array
- ignoreFrames : array
- returnAll : boolean (default false)

If returnAll is false, GetUnitFrame will return a single best match

For arrays check LibGetFrame-1.0.lua code for defaults

```Lua
LGF:ScanForUnitFrames()
```

Ask lib to do a new scan of frames.

This scan can take a few frames to be completed.

You should not expect the cache use by LGF:GetUnitFrame to be updated in the same frame as this ScanForUnitFrames call.

Use lib's callbacks to know when the cache is refresh.

```Lua
LGF:GetUnitNameplate(unit)
```

Return health bar for a nameplate unit, works with a variety of addons


## Callbacks

```Lua
-- Fired after a scan complete and cache refreshed
LGF.RegisterCallback("MyAddonName", "GETFRAME_REFRESH", function(event) end)
```

```Lua
-- Fired when a frame is a new match for a unit (it does not test if it is the BEST match!)
LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_UPDATE", function(event, frame, unit) end)
```

```Lua
-- Fired when a frame is not a new match for a unit anymore
LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_REMOVED", function(event, frame, unit) end)
```

## Examples

### Glow player frame

```Lua
local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")
local frame = LGF.GetUnitFrame("player")

if frame then
  LCG.ButtonGlow_Start(frame)
  -- LCG.ButtonGlow_Stop(frame)
end
```

### Glow every frames for your target

```Lua
local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")

local frames = LGF.GetUnitFrame("target", {
  ignorePlayerFrame = false,
  ignoreTargetFrame = false,
  ignoreTargettargetFrame = false,
  returnAll = true,
})

for _, frame in pairs(frames) do
  LCG.ButtonGlow_Start(frame)
  --LCG.ButtonGlow_Stop(frame)
end
```

### Ignore Vuhdo panel 2 and 3

```Lua
local frame = LGF.GetUnitFrame("player", {
  ignoreFrames = { "Vd2.*", "Vd3.*" }
})
```

### Glow specific units and update glow when frames changes

```Lua
local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")

-- list of units i want glowing
local glow_units = {
  player = true
}
-- track which frame is glowing per unit
local glow_unit_frames = {}

-- glow them using current cache
for unit in pairs(glow_units) do
  local frame = LGF.GetUnitFrame("player")
  if frame then
    LCG.ButtonGlow_Start(frame)
    glow_unit_frames[unit] = frame
  end
end

local callback = function(event, frame, unit)
  if not glow_units[unit] then
    return
  end
  -- new match for GetUnitFrame(unit), check if it's different from previous "best match" returned
  local new_best_match = LGF.GetUnitFrame(unit)
  if new_best_match == nil then
    -- didn't found a best match for this unit
    if glow_unit_frames[unit] then
      -- stop previous glow
      LCG.ButtonGlow_Stop(glow_unit_frames[unit])
      glow_unit_frames[unit] = nil
    end
  elseif new_best_match ~= glow_unit_frames[unit] then
    -- best match found, but different from previous one
    if glow_unit_frames[unit] then
      -- stop previous glow
      LCG.ButtonGlow_Stop(glow_unit_frames[unit])
    end
    LCG.ButtonGlow_Start(new_best_match)
    glow_unit_frames[unit] = new_best_match
  end
end

LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_UPDATE", callback)
LGF.RegisterCallback("MyAddonName", "FRAME_UNIT_REMOVED", callback)
```

[GitHub Project](https://github.com/mrbuds/LibGetFrame)
