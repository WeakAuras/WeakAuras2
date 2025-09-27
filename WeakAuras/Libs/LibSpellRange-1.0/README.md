# LibSpellRange-1.0

## Background

Blizzard's `IsSpellInRange` API has always been very limited - you either must have the name of the spell, 
or its spell book ID. Checking directly by spellID is simply not possible. 
Now, since Mists of Pandaria, Blizzard changed the way that many talents and specialization spells work - 
instead of giving you a new spell when leaned, they replace existing spells. These replacement spells do 
not work with Blizzard's IsSpellInRange function whatsoever; this limitation is what prompted the creation of this lib.

## Usage

**LibSpellRange-1.0** exposes an enhanced version of IsSpellInRange that:

*   Allows ranged checking based on both spell name and spellID.
*   Works correctly with replacement spells that will not work using Blizzard's IsSpellInRange method alone.
*   Attempts to works with pet spells via the action bar API, which as of some indeterminate recent WoW version no longer work with IsSpellInRange.

### `SpellRange.IsSpellInRange(spell, unit)` - Improved `IsSpellInRange`

#### Parameters

- `spell` - Name or spellID of a spell that you wish to check the range of. The spell must be a spell that you have in your spellbook or your pet's spellbook.
- `unit` - UnitID of the spell that you wish to check the range on.

#### Return value

Exact same returns as [the built-in `IsSpellInRange`](http://wowprogramming.com/docs/api/IsSpellInRange.html)

#### Usage

``` lua
-- Check spell range by spell name on unit "target"
local SpellRange = LibStub("SpellRange-1.0")
local inRange = SpellRange.IsSpellInRange("Stormstrike", "target")

-- Check spell range by spellID on unit "mouseover"
local SpellRange = LibStub("SpellRange-1.0")
local inRange = SpellRange.IsSpellInRange(17364, "mouseover")
```

### `SpellRange.SpellHasRange(spell)` - Improved `SpellHasRange`

#### Parameters

- `spell` - Name or spellID of a spell that you wish to check for a range. The spell must be a spell that you have in your spellbook or your pet's spellbook.

#### Return value

Exact same returns as [the built-in `SpellHasRange`](http://wowprogramming.com/docs/api/SpellHasRange.html)

#### Usage

``` lua
-- Check if a spell has a range by spell name
local SpellRange = LibStub("SpellRange-1.0")
local hasRange = SpellRange.SpellHasRange("Stormstrike")

-- Check if a spell has a range by spellID
local SpellRange = LibStub("SpellRange-1.0")
local hasRange = SpellRange.SpellHasRange(17364)
```
