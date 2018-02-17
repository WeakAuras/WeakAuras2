# WeakAuras 2

## [2.5.6-22-g08d8ce9](https://github.com/WeakAuras/WeakAuras2/tree/08d8ce9fa0b7b89b2f3ea6bb934b51ee0fae5027) (2018-02-17)

[Full Changelog](https://github.com/WeakAuras/WeakAuras2/compare/2.5.6...08d8ce9fa0b7b89b2f3ea6bb934b51ee0fae5027)

Benjamin Staneck (12):

- change back some power types as their format is not consistent
- change the global strings used for power type translations to be the ones of power types instead of the resource itself
- add some newlines to the changelog
- fix pkgmeta
- add the temp commit file to ,gitignore
- Update pkgmeta
- switch to manual changelog generation and add a script to do that
- only push localization if master changes and ignore the script in WowAce packaging
- add a script to automatically push translations to WowAce
- `dev` instead of `development`
- use the same version string for the window title as for the LDB tooltip
- fix LibRangecheck path

Infus (9):

- Templates: Add KJ's burning wish to the correct specs
- Combat Log Trigger: Fix SPELL_ENERGIZE
- Add Allied Races to templates
- Attach legendaries/sets to each spec instead of a global list
- Update Templates based on suggestions from Nighthawk
- Add Range Checker trigger
- Transmission: Add a timeout if no data to check if we received data
- Add resizers to the bottom right corner
- Fix Stagger progress not updating

emptyrivers (1):

- implement UnitIsUnit option

