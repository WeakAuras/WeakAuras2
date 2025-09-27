<Ui><Script><![CDATA[--[[

TaintLess [24-07-27]
https://www.townlong-yak.com/addons/taintless

All rights reserved.

Permission is hereby granted to distribute unmodified copies of this file.
]]

local purgeKey do
	local e = {}
	function purgeKey(t, k)
		e.textures, t[k] = t, 0
		TextureLoadingGroupMixin.RemoveTexture(e, k)
	end
end

local patch, cbuild do
	local skips = securecall(function()
		local r, _, an = {moon="haunted"}
		cbuild, r.moon, _, an = select(4,GetBuildInfo()), nil, issecurevariable(r, "moon")
		for m, v, clo, chi in (C_AddOns.GetAddOnMetadata(an, "X-TaintLess-DisableMitigations") or ""):gmatch("([%a_]+)=(%d+):?(%d*):?(%d*)") do
			if (clo == "" or cbuild >= clo+0) and (chi == "" or chi+0 >= cbuild) then
				r[m] = v + 0
			end
		end
		return r
	end)
	function patch(name, version, impl)
		if impl and not ((tonumber(_G[name]) or 0) >= version or skips and skips[name] == version) then
			_G[name] = version
			securecall(impl, version)
		end
	end
end
local CLASSIC = cbuild and cbuild < 11e4

-- https://www.townlong-yak.com/addons/taintless/fixes/RefreshOverread
patch("UIDD_REFRESH_OVERREAD_PATCH_VERSION", 7, CLASSIC and function(V)
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function()
		for i=1, UIDD_REFRESH_OVERREAD_PATCH_VERSION == V and UIDROPDOWNMENU_MAXLEVELS or 0 do
			for j=1+_G["DropDownList" .. i].numButtons, UIDROPDOWNMENU_MAXBUTTONS do
				local b, _ = _G["DropDownList" .. i .. "Button" .. j]
				_ = issecurevariable(b, "checked")      or purgeKey(b, "checked")
				_ = issecurevariable(b, "notCheckable") or purgeKey(b, "notCheckable")
			end
		end
	end)
end)

-- https://www.townlong-yak.com/addons/taintless/fixes/DisplayModeTaint
patch("UIDROPDOWNMENU_OPEN_PATCH_VERSION", 5, CLASSIC and function(V)
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function(frame)
		if UIDROPDOWNMENU_OPEN_PATCH_VERSION == V
		   and UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU ~= frame
		   and not issecurevariable(UIDROPDOWNMENU_OPEN_MENU, "displayMode") then
			purgeKey(_G, "UIDROPDOWNMENU_OPEN_MENU")
		end
	end)
end)

-- https://www.townlong-yak.com/addons/taintless/fixes/CUFProfileActivation
patch("CUF_PROFILE_ACTIVATE_PATCH_VERSION", 1, function(V)
	if not (type(SetActiveRaidProfile) == "function" and type(CompactUnitFrameProfiles) == "table" and
	        type(ScriptErrorsFrameMixin) == "table" and type(ScriptErrorsFrameMixin.DisplayMessageInternal) == "function") then
		return
	end
	local o, dd = {}, CreateFrame("Frame") do
		local s, sk, sv = 1, {"seen", "order", "order", "count"}, {{}, {}, newproxy(true), _G}
		getmetatable(sv[3]).__len = function()
			return "UIDROPDOWNMENU_MENU_LEVEL"
		end
		setmetatable(o, {__index=function(_,k)
			s, sv[2][1] = k == sk[s] and s+1 or 1
			return sv[s-1]
		end})
		function dd.initialize() end
		dd:Hide()
	end
	hooksecurefunc("SetActiveRaidProfile", function()
		if CUF_PROFILE_ACTIVATE_PATCH_VERSION ~= V or
		   (issecurevariable("UIDROPDOWNMENU_MENU_LEVEL") and issecurevariable(DropDownList1, "numButtons")) then
			return
		end
		pcall(UIDropDownMenu_InitializeHelper, dd)
		purgeKey(_G, "UIDROPDOWNMENU_OPEN_MENU")
		purgeKey(_G, "UIDROPDOWNMENU_INIT_MENU")
		pcall(ScriptErrorsFrameMixin.DisplayMessageInternal, o, "", 0, 0, 0, "")
	end)
end)

]]></Script></Ui>