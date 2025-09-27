--$Id: LibEasyMenu.lua 64 2020-11-18 13:13:15Z arithmandar $
-- //////////////////////////////////////////////////////////////
-- Notes: 
--      Functions have been moved to under LibUIDropDownMenu.lua
--      New function calls are as below:
--
--      - lib:EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay )
--      - lib:EasyMenu_Initialize( frame, level, menuList )
--
-- //////////////////////////////////////////////////////////////
-- Simplified Menu Display System
--	This is a basic system for displaying a menu from a structure table.
--
--	See UIDropDownMenu.lua for the menuList details.
--
--	Args:
--		menuList - menu table
--		menuFrame - the UI frame to populate
--		anchor - where to anchor the frame (e.g. CURSOR)
--		x - x offset
--		y - y offset
--		displayMode - border type
--		autoHideDelay - how long until the menu disappears
--
--
--[[
function EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay )
	if ( displayMode == "MENU" ) then
		menuFrame.displayMode = displayMode;
	end
	UIDropDownMenu_Initialize(menuFrame, EasyMenu_Initialize, displayMode, nil, menuList);
	ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList, nil, autoHideDelay);
end

function EasyMenu_Initialize( frame, level, menuList )
	for index = 1, #menuList do
		local value = menuList[index]
		if (value.text) then
			value.index = index;
			UIDropDownMenu_AddButton( value, level );
		end
	end
end
]]