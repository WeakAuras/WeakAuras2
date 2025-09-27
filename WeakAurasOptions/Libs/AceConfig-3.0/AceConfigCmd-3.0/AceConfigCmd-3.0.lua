--- AceConfigCmd-3.0 handles access to an options table through the "command line" interface via the ChatFrames.
-- @class file
-- @name AceConfigCmd-3.0
-- @release $Id: AceConfigCmd-3.0.lua 1284 2022-09-25 09:15:30Z nevcairiel $

--[[
AceConfigCmd-3.0

Handles commandline optionstable access

REQUIRES: AceConsole-3.0 for command registration (loaded on demand)

]]

-- TODO: plugin args

local cfgreg = LibStub("AceConfigRegistry-3.0")

local MAJOR, MINOR = "AceConfigCmd-3.0", 14
local AceConfigCmd = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfigCmd then return end

AceConfigCmd.commands = AceConfigCmd.commands or {}
local commands = AceConfigCmd.commands

local AceConsole -- LoD
local AceConsoleName = "AceConsole-3.0"

-- Lua APIs
local strsub, strsplit, strlower, strmatch, strtrim = string.sub, string.split, string.lower, string.match, string.trim
local format, tonumber, tostring = string.format, tonumber, tostring
local tsort, tinsert = table.sort, table.insert
local select, pairs, next, type = select, pairs, next, type
local error, assert = error, assert

-- WoW APIs
local _G = _G

local L = setmetatable({}, {	-- TODO: replace with proper locale
	__index = function(self,k) return k end
})

local function print(msg)
	(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME):AddMessage(msg)
end

-- constants used by getparam() calls below

local handlertypes = {["table"]=true}
local handlermsg = "expected a table"

local functypes = {["function"]=true, ["string"]=true}
local funcmsg = "expected function or member name"


-- pickfirstset() - picks the first non-nil value and returns it

local function pickfirstset(...)
	for i=1,select("#",...) do
		if select(i,...)~=nil then
			return select(i,...)
		end
	end
end


-- err() - produce real error() regarding malformed options tables etc

local function err(info,inputpos,msg )
	local cmdstr=" "..strsub(info.input, 1, inputpos-1)
	error(MAJOR..": /" ..info[0] ..cmdstr ..": "..(msg or "malformed options table"), 2)
end


-- usererr() - produce chatframe message regarding bad slash syntax etc

local function usererr(info,inputpos,msg )
	local cmdstr=strsub(info.input, 1, inputpos-1);
	print("/" ..info[0] .. " "..cmdstr ..": "..(msg or "malformed options table"))
end


-- callmethod() - call a given named method (e.g. "get", "set") with given arguments

local function callmethod(info, inputpos, tab, methodtype, ...)
	local method = info[methodtype]
	if not method then
		err(info, inputpos, "'"..methodtype.."': not set")
	end

	info.arg = tab.arg
	info.option = tab
	info.type = tab.type

	if type(method)=="function" then
		return method(info, ...)
	elseif type(method)=="string" then
		if type(info.handler[method])~="function" then
			err(info, inputpos, "'"..methodtype.."': '"..method.."' is not a member function of "..tostring(info.handler))
		end
		return info.handler[method](info.handler, info, ...)
	else
		assert(false)	-- type should have already been checked on read
	end
end

-- callfunction() - call a given named function (e.g. "name", "desc") with given arguments

local function callfunction(info, tab, methodtype, ...)
	local method = tab[methodtype]

	info.arg = tab.arg
	info.option = tab
	info.type = tab.type

	if type(method)=="function" then
		return method(info, ...)
	else
		assert(false) -- type should have already been checked on read
	end
end

-- do_final() - do the final step (set/execute) along with validation and confirmation

local function do_final(info, inputpos, tab, methodtype, ...)
	if info.validate then
		local res = callmethod(info,inputpos,tab,"validate",...)
		if type(res)=="string" then
			usererr(info, inputpos, "'"..strsub(info.input, inputpos).."' - "..res)
			return
		end
	end
	-- console ignores .confirm

	callmethod(info,inputpos,tab,methodtype, ...)
end


-- getparam() - used by handle() to retreive and store "handler", "get", "set", etc

local function getparam(info, inputpos, tab, depth, paramname, types, errormsg)
	local old,oldat = info[paramname], info[paramname.."_at"]
	local val=tab[paramname]
	if val~=nil then
		if val==false then
			val=nil
		elseif not types[type(val)] then
			err(info, inputpos, "'" .. paramname.. "' - "..errormsg)
		end
		info[paramname] = val
		info[paramname.."_at"] = depth
	end
	return old,oldat
end


-- iterateargs(tab) - custom iterator that iterates both t.args and t.plugins.*
local dummytable={}

local function iterateargs(tab)
	if not tab.plugins then
		return pairs(tab.args)
	end

	local argtabkey,argtab=next(tab.plugins)
	local v

	return function(_, k)
		while argtab do
			k,v = next(argtab, k)
			if k then return k,v end
			if argtab==tab.args then
				argtab=nil
			else
				argtabkey,argtab = next(tab.plugins, argtabkey)
				if not argtabkey then
					argtab=tab.args
				end
			end
		end
	end
end

local function checkhidden(info, inputpos, tab)
	if tab.cmdHidden~=nil then
		return tab.cmdHidden
	end
	local hidden = tab.hidden
	if type(hidden) == "function" or type(hidden) == "string" then
		info.hidden = hidden
		hidden = callmethod(info, inputpos, tab, 'hidden')
		info.hidden = nil
	end
	return hidden
end

local function showhelp(info, inputpos, tab, depth, noHead)
	if not noHead then
		print("|cff33ff99"..info.appName.."|r: Arguments to |cffffff78/"..info[0].."|r "..strsub(info.input,1,inputpos-1)..":")
	end

	local sortTbl = {}	-- [1..n]=name
	local refTbl = {}   -- [name]=tableref

	for k,v in iterateargs(tab) do
		if not refTbl[k] then	-- a plugin overriding something in .args
			tinsert(sortTbl, k)
			refTbl[k] = v
		end
	end

	tsort(sortTbl, function(one, two)
		local o1 = refTbl[one].order or 100
		local o2 = refTbl[two].order or 100
		if type(o1) == "function" or type(o1) == "string" then
			info.order = o1
			info[#info+1] = one
			o1 = callmethod(info, inputpos, refTbl[one], "order")
			info[#info] = nil
			info.order = nil
		end
		if type(o2) == "function" or type(o1) == "string" then
			info.order = o2
			info[#info+1] = two
			o2 = callmethod(info, inputpos, refTbl[two], "order")
			info[#info] = nil
			info.order = nil
		end
		if o1<0 and o2<0 then return o1<o2 end
		if o2<0 then return true end
		if o1<0 then return false end
		if o1==o2 then return tostring(one)<tostring(two) end   -- compare names
		return o1<o2
	end)

	for i = 1, #sortTbl do
		local k = sortTbl[i]
		local v = refTbl[k]
		if not checkhidden(info, inputpos, v) then
			if v.type ~= "description" and v.type ~= "header" then
				-- recursively show all inline groups
				local name, desc = v.name, v.desc
				if type(name) == "function" then
					name = callfunction(info, v, 'name')
				end
				if type(desc) == "function" then
					desc = callfunction(info, v, 'desc')
				end
				if v.type == "group" and pickfirstset(v.cmdInline, v.inline, false) then
					print("  "..(desc or name)..":")
					local oldhandler,oldhandler_at = getparam(info, inputpos, v, depth, "handler", handlertypes, handlermsg)
					showhelp(info, inputpos, v, depth, true)
					info.handler,info.handler_at = oldhandler,oldhandler_at
				else
					local key = k:gsub(" ", "_")
					print("  |cffffff78"..key.."|r - "..(desc or name or ""))
				end
			end
		end
	end
end


local function keybindingValidateFunc(text)
	if text == nil or text == "NONE" then
		return nil
	end
	text = text:upper()
	local shift, ctrl, alt
	local modifier
	while true do
		if text == "-" then
			break
		end
		modifier, text = strsplit('-', text, 2)
		if text then
			if modifier ~= "SHIFT" and modifier ~= "CTRL" and modifier ~= "ALT" then
				return false
			end
			if modifier == "SHIFT" then
				if shift then
					return false
				end
				shift = true
			end
			if modifier == "CTRL" then
				if ctrl then
					return false
				end
				ctrl = true
			end
			if modifier == "ALT" then
				if alt then
					return false
				end
				alt = true
			end
		else
			text = modifier
			break
		end
	end
	if text == "" then
		return false
	end
	if not text:find("^F%d+$") and text ~= "CAPSLOCK" and text:len() ~= 1 and (text:byte() < 128 or text:len() > 4) and not _G["KEY_" .. text] then
		return false
	end
	local s = text
	if shift then
		s = "SHIFT-" .. s
	end
	if ctrl then
		s = "CTRL-" .. s
	end
	if alt then
		s = "ALT-" .. s
	end
	return s
end

-- handle() - selfrecursing function that processes input->optiontable
-- - depth - starts at 0
-- - retfalse - return false rather than produce error if a match is not found (used by inlined groups)

local function handle(info, inputpos, tab, depth, retfalse)

	if not(type(tab)=="table" and type(tab.type)=="string") then err(info,inputpos) end

	-------------------------------------------------------------------
	-- Grab hold of handler,set,get,func,etc if set (and remember old ones)
	-- Note that we do NOT validate if method names are correct at this stage,
	-- the handler may change before they're actually used!

	local oldhandler,oldhandler_at = getparam(info,inputpos,tab,depth,"handler",handlertypes,handlermsg)
	local oldset,oldset_at = getparam(info,inputpos,tab,depth,"set",functypes,funcmsg)
	local oldget,oldget_at = getparam(info,inputpos,tab,depth,"get",functypes,funcmsg)
	local oldfunc,oldfunc_at = getparam(info,inputpos,tab,depth,"func",functypes,funcmsg)
	local oldvalidate,oldvalidate_at = getparam(info,inputpos,tab,depth,"validate",functypes,funcmsg)
	--local oldconfirm,oldconfirm_at = getparam(info,inputpos,tab,depth,"confirm",functypes,funcmsg)

	-------------------------------------------------------------------
	-- Act according to .type of this table

	if tab.type=="group" then
		------------ group --------------------------------------------

		if type(tab.args)~="table" then err(info, inputpos) end
		if tab.plugins and type(tab.plugins)~="table" then err(info,inputpos) end

		-- grab next arg from input
		local _,nextpos,arg = (info.input):find(" *([^ ]+) *", inputpos)
		if not arg then
			showhelp(info, inputpos, tab, depth)
			return
		end
		nextpos=nextpos+1

		-- loop .args and try to find a key with a matching name
		for k,v in iterateargs(tab) do
			if not(type(k)=="string" and type(v)=="table" and type(v.type)=="string") then err(info,inputpos, "options table child '"..tostring(k).."' is malformed") end

			-- is this child an inline group? if so, traverse into it
			if v.type=="group" and pickfirstset(v.cmdInline, v.inline, false) then
				info[depth+1] = k
				if handle(info, inputpos, v, depth+1, true)==false then
					info[depth+1] = nil
					-- wasn't found in there, but that's ok, we just keep looking down here
				else
					return	-- done, name was found in inline group
				end
			-- matching name and not a inline group
			elseif strlower(arg)==strlower(k:gsub(" ", "_")) then
				info[depth+1] = k
				return handle(info,nextpos,v,depth+1)
			end
		end

		-- no match
		if retfalse then
			-- restore old infotable members and return false to indicate failure
			info.handler,info.handler_at = oldhandler,oldhandler_at
			info.set,info.set_at = oldset,oldset_at
			info.get,info.get_at = oldget,oldget_at
			info.func,info.func_at = oldfunc,oldfunc_at
			info.validate,info.validate_at = oldvalidate,oldvalidate_at
			--info.confirm,info.confirm_at = oldconfirm,oldconfirm_at
			return false
		end

		-- couldn't find the command, display error
		usererr(info, inputpos, "'"..arg.."' - " .. L["unknown argument"])
		return
	end

	local strInput = strsub(info.input,inputpos);

	if tab.type=="execute" then
		------------ execute --------------------------------------------
		do_final(info, inputpos, tab, "func")



	elseif tab.type=="input" then
		------------ input --------------------------------------------

		local res = true
		if tab.pattern then
			if type(tab.pattern)~="string" then err(info, inputpos, "'pattern' - expected a string") end
			if not strmatch(strInput, tab.pattern) then
				usererr(info, inputpos, "'"..strInput.."' - " .. L["invalid input"])
				return
			end
		end

		do_final(info, inputpos, tab, "set", strInput)



	elseif tab.type=="toggle" then
		------------ toggle --------------------------------------------
		local b
		local str = strtrim(strlower(strInput))
		if str=="" then
			b = callmethod(info, inputpos, tab, "get")

			if tab.tristate then
				--cycle in true, nil, false order
				if b then
					b = nil
				elseif b == nil then
					b = false
				else
					b = true
				end
			else
				b = not b
			end

		elseif str==L["on"] then
			b = true
		elseif str==L["off"] then
			b = false
		elseif tab.tristate and str==L["default"] then
			b = nil
		else
			if tab.tristate then
				usererr(info, inputpos, format(L["'%s' - expected 'on', 'off' or 'default', or no argument to toggle."], str))
			else
				usererr(info, inputpos, format(L["'%s' - expected 'on' or 'off', or no argument to toggle."], str))
			end
			return
		end

		do_final(info, inputpos, tab, "set", b)


	elseif tab.type=="range" then
		------------ range --------------------------------------------
		local val = tonumber(strInput)
		if not val then
			usererr(info, inputpos, "'"..strInput.."' - "..L["expected number"])
			return
		end
		if type(info.step)=="number" then
			val = val- (val % info.step)
		end
		if type(info.min)=="number" and val<info.min then
			usererr(info, inputpos, val.." - "..format(L["must be equal to or higher than %s"], tostring(info.min)) )
			return
		end
		if type(info.max)=="number" and val>info.max then
			usererr(info, inputpos, val.." - "..format(L["must be equal to or lower than %s"], tostring(info.max)) )
			return
		end

		do_final(info, inputpos, tab, "set", val)


	elseif tab.type=="select" then
		------------ select ------------------------------------
		local str = strtrim(strlower(strInput))

		local values = tab.values
		if type(values) == "function" or type(values) == "string" then
			info.values = values
			values = callmethod(info, inputpos, tab, "values")
			info.values = nil
		end

		if str == "" then
			local b = callmethod(info, inputpos, tab, "get")
			local fmt = "|cffffff78- [%s]|r %s"
			local fmt_sel = "|cffffff78- [%s]|r %s |cffff0000*|r"
			print(L["Options for |cffffff78"..info[#info].."|r:"])
			for k, v in pairs(values) do
				if b == k then
					print(fmt_sel:format(k, v))
				else
					print(fmt:format(k, v))
				end
			end
			return
		end

		local ok
		for k,v in pairs(values) do
			if strlower(k)==str then
				str = k	-- overwrite with key (in case of case mismatches)
				ok = true
				break
			end
		end
		if not ok then
			usererr(info, inputpos, "'"..str.."' - "..L["unknown selection"])
			return
		end

		do_final(info, inputpos, tab, "set", str)

	elseif tab.type=="multiselect" then
		------------ multiselect -------------------------------------------
		local str = strtrim(strlower(strInput))

		local values = tab.values
		if type(values) == "function" or type(values) == "string" then
			info.values = values
			values = callmethod(info, inputpos, tab, "values")
			info.values = nil
		end

		if str == "" then
			local fmt = "|cffffff78- [%s]|r %s"
			local fmt_sel = "|cffffff78- [%s]|r %s |cffff0000*|r"
			print(L["Options for |cffffff78"..info[#info].."|r (multiple possible):"])
			for k, v in pairs(values) do
				if callmethod(info, inputpos, tab, "get", k) then
					print(fmt_sel:format(k, v))
				else
					print(fmt:format(k, v))
				end
			end
			return
		end

		--build a table of the selections, checking that they exist
		--parse for =on =off =default in the process
		--table will be key = true for options that should toggle, key = [on|off|default] for options to be set
		local sels = {}
		for v in str:gmatch("[^ ]+") do
			--parse option=on etc
			local opt, val = v:match('(.+)=(.+)')
			--get option if toggling
			if not opt then
				opt = v
			end

			--check that the opt is valid
			local ok
			for k in pairs(values) do
				if strlower(k)==opt then
					opt = k	-- overwrite with key (in case of case mismatches)
					ok = true
					break
				end
			end

			if not ok then
				usererr(info, inputpos, "'"..opt.."' - "..L["unknown selection"])
				return
			end

			--check that if val was supplied it is valid
			if val then
				if val == L["on"] or val == L["off"] or (tab.tristate and val == L["default"]) then
					--val is valid insert it
					sels[opt] = val
				else
					if tab.tristate then
						usererr(info, inputpos, format(L["'%s' '%s' - expected 'on', 'off' or 'default', or no argument to toggle."], v, val))
					else
						usererr(info, inputpos, format(L["'%s' '%s' - expected 'on' or 'off', or no argument to toggle."], v, val))
					end
					return
				end
			else
				-- no val supplied, toggle
				sels[opt] = true
			end
		end

		for opt, val in pairs(sels) do
			local newval

			if (val == true) then
				--toggle the option
				local b = callmethod(info, inputpos, tab, "get", opt)

				if tab.tristate then
					--cycle in true, nil, false order
					if b then
						b = nil
					elseif b == nil then
						b = false
					else
						b = true
					end
				else
					b = not b
				end
				newval = b
			else
				--set the option as specified
				if val==L["on"] then
					newval = true
				elseif val==L["off"] then
					newval = false
				elseif val==L["default"] then
					newval = nil
				end
			end

			do_final(info, inputpos, tab, "set", opt, newval)
		end


	elseif tab.type=="color" then
		------------ color --------------------------------------------
		local str = strtrim(strlower(strInput))
		if str == "" then
			--TODO: Show current value
			return
		end

		local r, g, b, a

		local hasAlpha = tab.hasAlpha
		if type(hasAlpha) == "function" or type(hasAlpha) == "string" then
			info.hasAlpha = hasAlpha
			hasAlpha = callmethod(info, inputpos, tab, 'hasAlpha')
			info.hasAlpha = nil
		end

		if hasAlpha then
			if str:len() == 8 and str:find("^%x*$")  then
				--parse a hex string
				r,g,b,a = tonumber(str:sub(1, 2), 16) / 255, tonumber(str:sub(3, 4), 16) / 255, tonumber(str:sub(5, 6), 16) / 255, tonumber(str:sub(7, 8), 16) / 255
			else
				--parse seperate values
				r,g,b,a = str:match("^([%d%.]+) ([%d%.]+) ([%d%.]+) ([%d%.]+)$")
				r,g,b,a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
			end
			if not (r and g and b and a) then
				usererr(info, inputpos, format(L["'%s' - expected 'RRGGBBAA' or 'r g b a'."], str))
				return
			end

			if r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0 and a >= 0.0 and a <= 1.0 then
				--values are valid
			elseif r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 and a >= 0 and a <= 255 then
				--values are valid 0..255, convert to 0..1
				r = r / 255
				g = g / 255
				b = b / 255
				a = a / 255
			else
				--values are invalid
				usererr(info, inputpos, format(L["'%s' - values must all be either in the range 0..1 or 0..255."], str))
			end
		else
			a = 1.0
			if str:len() == 6 and str:find("^%x*$") then
				--parse a hex string
				r,g,b = tonumber(str:sub(1, 2), 16) / 255, tonumber(str:sub(3, 4), 16) / 255, tonumber(str:sub(5, 6), 16) / 255
			else
				--parse seperate values
				r,g,b = str:match("^([%d%.]+) ([%d%.]+) ([%d%.]+)$")
				r,g,b = tonumber(r), tonumber(g), tonumber(b)
			end
			if not (r and g and b) then
				usererr(info, inputpos, format(L["'%s' - expected 'RRGGBB' or 'r g b'."], str))
				return
			end
			if r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0 then
				--values are valid
			elseif r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
				--values are valid 0..255, convert to 0..1
				r = r / 255
				g = g / 255
				b = b / 255
			else
				--values are invalid
				usererr(info, inputpos, format(L["'%s' - values must all be either in the range 0-1 or 0-255."], str))
			end
		end

		do_final(info, inputpos, tab, "set", r,g,b,a)

	elseif tab.type=="keybinding" then
		------------ keybinding --------------------------------------------
		local str = strtrim(strlower(strInput))
		if str == "" then
			--TODO: Show current value
			return
		end
		local value = keybindingValidateFunc(str:upper())
		if value == false then
			usererr(info, inputpos, format(L["'%s' - Invalid Keybinding."], str))
			return
		end

		do_final(info, inputpos, tab, "set", value)

	elseif tab.type=="description" then
		------------ description --------------------
		-- ignore description, GUI config only
	else
		err(info, inputpos, "unknown options table item type '"..tostring(tab.type).."'")
	end
end

--- Handle the chat command.
-- This is usually called from a chat command handler to parse the command input as operations on an aceoptions table.\\
-- AceConfigCmd uses this function internally when a slash command is registered with `:CreateChatCommand`
-- @param slashcmd The slash command WITHOUT leading slash (only used for error output)
-- @param appName The application name as given to `:RegisterOptionsTable()`
-- @param input The commandline input (as given by the WoW handler, i.e. without the command itself)
-- @usage
-- MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceConsole-3.0")
-- -- Use AceConsole-3.0 to register a Chat Command
-- MyAddon:RegisterChatCommand("mychat", "ChatCommand")
--
-- -- Show the GUI if no input is supplied, otherwise handle the chat input.
-- function MyAddon:ChatCommand(input)
--   -- Assuming "MyOptions" is the appName of a valid options table
--   if not input or input:trim() == "" then
--     LibStub("AceConfigDialog-3.0"):Open("MyOptions")
--   else
--     LibStub("AceConfigCmd-3.0").HandleCommand(MyAddon, "mychat", "MyOptions", input)
--   end
-- end
function AceConfigCmd:HandleCommand(slashcmd, appName, input)

	local optgetter = cfgreg:GetOptionsTable(appName)
	if not optgetter then
		error([[Usage: HandleCommand("slashcmd", "appName", "input"): 'appName' - no options table "]]..tostring(appName)..[[" has been registered]], 2)
	end
	local options = assert( optgetter("cmd", MAJOR) )

	local info = {   -- Don't try to recycle this, it gets handed off to callbacks and whatnot
		[0] = slashcmd,
		appName = appName,
		options = options,
		input = input,
		self = self,
		handler = self,
		uiType = "cmd",
		uiName = MAJOR,
	}

	handle(info, 1, options, 0)  -- (info, inputpos, table, depth)
end

--- Utility function to create a slash command handler.
-- Also registers tab completion with AceTab
-- @param slashcmd The slash command WITHOUT leading slash (only used for error output)
-- @param appName The application name as given to `:RegisterOptionsTable()`
function AceConfigCmd:CreateChatCommand(slashcmd, appName)
	if not AceConsole then
		AceConsole = LibStub(AceConsoleName)
	end
	if AceConsole.RegisterChatCommand(self, slashcmd, function(input)
				AceConfigCmd.HandleCommand(self, slashcmd, appName, input)	-- upgradable
		end,
	true) then -- succesfully registered so lets get the command -> app table in
		commands[slashcmd] = appName
	end
end

--- Utility function that returns the options table that belongs to a slashcommand.
-- Designed to be used for the AceTab interface.
-- @param slashcmd The slash command WITHOUT leading slash (only used for error output)
-- @return The options table associated with the slash command (or nil if the slash command was not registered)
function AceConfigCmd:GetChatCommandOptions(slashcmd)
	return commands[slashcmd]
end