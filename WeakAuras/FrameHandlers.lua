if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local LOCAL_FrameHandle_Other_Frames = {};
local LOCAL_FrameHandle_Lookup = {};
local LOCAL_FrameHandle_Args = {};
setmetatable(LOCAL_FrameHandle_Other_Frames, { __mode = "k" });
setmetatable(LOCAL_FrameHandle_Args, { __mode = "k" });

-- Setup metatable for prototype object
local LOCAL_FrameHandle_Prototype = newproxy(true);
-- HANDLE is the frame handle method namespace (populated later)

local HANDLE = {}

local GetFrameHandle, GetFrameHandleFrame, IsFrameHandle

do
    local meta = getmetatable(LOCAL_FrameHandle_Prototype);
    meta.__index = function(tbl, key)
        if (HANDLE[key]) then
            return HANDLE[key]
        else
            local privateData = LOCAL_FrameHandle_Args[tbl]

            if ( privateData and privateData[key] ) then
                return privateData[key]
            end

            local frame = GetFrameHandleFrame(tbl)
            if(frame) then
                return frame[key]
            end
        end

        error('Unable to find value "'..key..'"')
    end;
    meta.__newindex = function(tbl, key, value)
        if (HANDLE[key]) then
            error('Attept to override handle function "'..key..'"')
        else
            local frame = GetFrameHandleFrame(tbl)

            if ( type(value) == 'function' ) then
                if(frame) and frame[key] then
                    error('Attept to override handle function "'..key..'"')
                end

                local privateData = LOCAL_FrameHandle_Args[tbl]
                if ( privateData ) then
                    privateData[key] = value
                end
            else
                if(frame) then
                    frame[key] = value
                end
            end
        end
    end;
    meta.__metatable = false;
end

function IsFrameHandle(handle)
    local surrogate = LOCAL_FrameHandle_Other_Frames[handle];
    return (surrogate ~= nil);
end

function GetFrameHandle(frame)
    local handle = LOCAL_FrameHandle_Lookup[frame];
    return handle;
end

function GetFrameHandleFrame(handle)
    local surrogate = LOCAL_FrameHandle_Other_Frames[handle];
    if (surrogate ~= nil) then
        return surrogate[1];
    end
end


local function FrameHandleLookup_index(t, frame)
  -- Create a 'surrogate' frame object
  local surrogate = { [0] = frame[0], [1] = frame };
  setmetatable(surrogate, getmetatable(frame));

  local handle = newproxy(LOCAL_FrameHandle_Prototype);
  LOCAL_FrameHandle_Lookup[frame] = handle;
  LOCAL_FrameHandle_Other_Frames[handle] = surrogate;
  LOCAL_FrameHandle_Args[handle] = {};

  return handle;
end
setmetatable(LOCAL_FrameHandle_Lookup, { __index = FrameHandleLookup_index; });


local function GetHandleFrame(handle)
    local frame = GetFrameHandleFrame(handle);
    if (frame) then
        return frame;
    end
    error("Invalid frame handle");
end

function HANDLE:GetName()   return GetHandleFrame(self):GetName() end
function HANDLE:GetID()     return GetHandleFrame(self):GetID()     end
function HANDLE:IsShown()   return GetHandleFrame(self):IsShown()   end
function HANDLE:IsVisible() return GetHandleFrame(self):IsVisible() end
function HANDLE:GetWidth()  return GetHandleFrame(self):GetWidth()  end
function HANDLE:GetHeight() return GetHandleFrame(self):GetHeight() end
function HANDLE:GetScale()  return GetHandleFrame(self):GetScale()  end
function HANDLE:GetEffectiveScale()
    return GetHandleFrame(self):GetEffectiveScale()
end

function HANDLE:GetRect()
	local frame = GetHandleFrame(self);
	if frame:IsAnchoringRestricted() then
		return nil;
	end

	return frame:GetRect();
end

function HANDLE:GetAlpha()
    return GetHandleFrame(self):GetAlpha();
end

function HANDLE:GetFrameLevel()
    return GetHandleFrame(self):GetFrameLevel();
end

function HANDLE:GetFrameStrata()
    return GetHandleFrame(self):GetFrameStrata();
end

function HANDLE:IsMouseEnabled()
    return GetHandleFrame(self):IsMouseEnabled();
end

function HANDLE:IsMouseClickEnabled()
    return GetHandleFrame(self):IsMouseClickEnabled();
end

function HANDLE:IsMouseMotionEnabled()
    return GetHandleFrame(self):IsMouseMotionEnabled();
end

function HANDLE:IsKeyboardEnabled()
    return GetHandleFrame(self):IsKeyboardEnabled();
end

function HANDLE:IsGamePadButtonEnabled()
    return GetHandleFrame(self):IsGamePadButtonEnabled();
end

function HANDLE:IsGamePadStickEnabled()
    return GetHandleFrame(self):IsGamePadStickEnabled();
end

function HANDLE:GetObjectType()
    return GetHandleFrame(self):GetObjectType()
end

function HANDLE:IsObjectType(ot)
    return GetHandleFrame(self):IsObjectType(tostring(ot))
end

function HANDLE:IsProtected()
    return GetHandleFrame(self):IsProtected();
end

function HANDLE:GetAttribute(name)
    if (type(name) ~= "string" or name:match("^_")) then
        return;
    end
    local val = GetHandleFrame(self):GetAttribute(name)
    local tv = type(val);
    if (tv == "string" or tv == "number" or tv == "boolean" or val == nil) then
        return val;
    end
    if (tv == "userdata" and IsFrameHandle(val)) then
        return val;
    end
    return nil;
end

local function ShouldAllowAccessToFrame(frame)
	if frame:IsForbidden() then
		return false;
	end

    return true;
end

local function GetValidatedFrameHandle(frame)
	if ShouldAllowAccessToFrame(frame) then
		return GetFrameHandle(frame);
	end

	return nil;
end


local function FrameHandleMapper(frame, nextFrame, ...)
    if (not frame) then
        return;
    end

    frame = GetValidatedFrameHandle(frame);

    if frame then
        if (nextFrame) then
            return frame, FrameHandleMapper(nextFrame, ...);
        else
            return frame;
        end
    end

    if (nextFrame) then
        return FrameHandleMapper(nextFrame, ...);
    end
end

local function FrameHandleInserter(result, ...)
    local idx = #result;
    for i = 1, select('#', ...) do
        local frame = GetValidatedFrameHandle(select(i, ...));
        if frame then
			idx = idx + 1;
			result[idx] = frame;
        end
    end

    return result;
end

function HANDLE:GetChildren()
    return FrameHandleMapper(GetHandleFrame(self):GetChildren());
end

function HANDLE:GetChildList(tbl)
    return FrameHandleInserter(tbl, GetHandleFrame(self):GetChildren());
end

function HANDLE:GetParent()
    return FrameHandleMapper(GetHandleFrame(self):GetParent());
end

function HANDLE:GetNumPoints()
    return GetHandleFrame(self):GetNumPoints();
end

function HANDLE:GetPoint(i)
	local thisFrame = GetHandleFrame(self);
	if thisFrame:IsAnchoringRestricted() then
		return nil;
	end

    local point, frame, relative, dx, dy = thisFrame:GetPoint(i);
    local handle;
    if (frame) then
        handle = FrameHandleMapper(frame);
    end
    if (handle or not frame) then
        return point, handle, relative, dx, dy;
    end
end


---------------------------------------------------------------------------
-- "SETTER" methods and actions

function HANDLE:Show()
    GetHandleFrame(self):Show();
end

function HANDLE:Hide()
    GetHandleFrame(self):Hide();
end

function HANDLE:SetID(id)
    GetHandleFrame(self):SetID(tonumber(id) or 0);
end

function HANDLE:SetWidth(width)
    GetHandleFrame(self):SetWidth(tonumber(width));
end

function HANDLE:SetHeight(height)
    GetHandleFrame(self):SetHeight(tonumber(height));
end

function HANDLE:SetSize(width, height)
    if ((width == nil) and (height == nil)) then
        width, height = 0, 0;
    else
        width, height = tonumber(width), tonumber(height);
    end


    GetHandleFrame(self):SetSize(width, height)
end

function HANDLE:SetScale(scale)
    GetHandleFrame(self):SetScale(tonumber(scale));
end

function HANDLE:SetAlpha(alpha)
    GetHandleFrame(self):SetAlpha(tonumber(alpha));
end

local _set_points = {
    TOP=true; BOTTOM=true; LEFT=true; RIGHT=true; CENTER=true;
    TOPLEFT=true; BOTTOMLEFT=true; TOPRIGHT=true; BOTTOMRIGHT=true;
};

function HANDLE:ClearAllPoints()
    GetHandleFrame(self):ClearAllPoints();
end

function HANDLE:SetPoint(point, relframe, relpoint, xofs, yofs)
    if (type(relpoint) == "number") then
        relpoint, xofs, yofs = nil, relpoint, xofs;
    end
    if (relpoint == nil) then
        relpoint = point;
    end
    if ((xofs == nil) and (yofs == nil)) then
        xofs, yofs = 0, 0;
    else
        xofs, yofs = tonumber(xofs), tonumber(yofs);
    end
    if (not _set_points[point]) then
        error("Invalid point '" .. tostring(point) .. "'");
        return;
    end
    if (not _set_points[relpoint]) then
        error("Invalid relative point '" .. tostring(relpoint) .. "'");
        return;
    end
    if (not (xofs and yofs)) then
        error("Invalid offset");
        return
    end

    local frame = GetHandleFrame(self);

    local realrelframe = nil;
    if (type(relframe) == "userdata") then
        -- **MUST** be protected
        realrelframe = GetFrameHandleFrame(relframe);
        if (not realrelframe) then
            error("Invalid relative frame handle");
            return;
        end
    else
        -- from wa envy
        --realrelframe = relframe
        error("Invalid relative frame id '" .. tostring(relframe) .. "'");
        return;
    end

    frame:SetPoint(point, realrelframe, relpoint, xofs, yofs);
end

function HANDLE:SetAllPoints(relframe)
    local frame = GetHandleFrame(self);

    local realrelframe = nil;
    if (type(relframe) == "userdata") then
        realrelframe = GetFrameHandleFrame(relframe);
        if (not realrelframe) then
            error("Invalid relative frame handle");
            return;
        end
    else
        -- from wa envy
        --realrelframe = relframe
        error("Invalid relative frame id '" .. tostring(relframe) .. "'");
        return;
    end

    frame:SetAllPoints(realrelframe);
end


function HANDLE:Raise()
    GetHandleFrame(self):Raise();
end

function HANDLE:Lower()
    GetHandleFrame(self):Lower();
end

function HANDLE:SetFrameLevel(level)
    GetHandleFrame(self):SetFrameLevel(tonumber(level));
end

function HANDLE:SetFrameStrata(strata)
    GetHandleFrame(self):SetFrameStrata(tostring(strata));
end

function HANDLE:SetParent(handle)
    local parent = nil;
    if (handle ~= nil) then
        if (type(handle) == "userdata") then
            parent = GetFrameHandleFrame(handle);
            if (not parent) then
                error("Invalid frame handle for SetParent");
                return;
            end
        else
            parent = handle
        end
    end

    GetHandleFrame(self):SetParent(parent);
end

function HANDLE:EnableMouse(isEnabled)
    GetHandleFrame(self):EnableMouse((isEnabled and true) or false);
end

function HANDLE:EnableKeyboard(isEnabled)
    GetHandleFrame(self):EnableKeyboard((isEnabled and true) or false);
end

function HANDLE:EnableGamePadButton(isEnabled)
    GetHandleFrame(self):EnableGamePadButton((isEnabled and true) or false);
end

function HANDLE:EnableGamePadStick(isEnabled)
    GetHandleFrame(self):EnableGamePadStick((isEnabled and true) or false);
end

function HANDLE:SetAttribute(name, value)
    if (type(name) ~= "string" or name:match("^_")) then
        error("Invalid attribute name");
        return;
    end
    local tv = type(value);
    if (tv ~= "string" and tv ~= "nil" and tv ~= "number"
        and tv ~= "boolean") then
        if (not (tv == "userdata" and IsFrameHandle(value))) then
            error("Invalid attribute value");
            return;
        end
    end
    GetHandleFrame(self):SetAttribute(name, value);
end

---------------------------------------------------------------------------
-- Type specific methods

function HANDLE:Click()
    local frame = GetHandleFrame(self);
    if (not frame:IsObjectType("Button")) then
        error("Frame is not a Button");
        return;
    end

    return false
end

function HANDLE:Disable()
    local frame = GetHandleFrame(self);
    if (not frame:IsObjectType("Button")) then
        error("Frame is not a Button");
        return;
    end
    frame:Disable();
end

function HANDLE:Enable()
    local frame = GetHandleFrame(self);
    if (not frame:IsObjectType("Button")) then
        error("Frame is not a Button");
        return;
    end
    frame:Enable();
end

function HANDLE:RegisterForClicks(...)
    local frame = GetHandleFrame(self);
    if (not frame:IsObjectType("Button")) then
        error("Frame is not a Button");
        return;
    end
    frame:RegisterForClicks(...);
end

---------------------------------------------------------------------------
-- Events methods

function HANDLE:RegisterEvent(...)
    local frame = GetHandleFrame(self);

    frame:RegisterEvent(...)
end

function HANDLE:UnregisterEvent(...)
    local frame = GetHandleFrame(self);

    frame:UnregisterEvent(...)
end

function HANDLE:UnregisterAllEvent()
    local frame = GetHandleFrame(self);

    frame:UnregisterAllEvent()
end

function HANDLE:RegisterUnitEvent(...)
    local frame = GetHandleFrame(self);

    frame:RegisterUnitEvent(...)
end

---------------------------------------------------------------------------
-- Script methods

local __GetScriptMapper = {}

function HANDLE:GetScript(event, handler)
    local frame = GetHandleFrame(self);

    return __GetScriptMapper[frame]
end


function HANDLE:SetScript(event, handler)
    local frame = GetHandleFrame(self);

    if ( type(handler) == 'function' ) then

        __GetScriptMapper[frame] = handler

        frame:SetScript(event, function(_, ...)
            handler(self,  ...)
        end)
    else
        __GetScriptMapper[frame] = nil

        frame:SetScript(event, nil)
    end
end

---------------------------------------------------------------------------
-- FontString

function HANDLE:CreateFontString(...)
    local frame = GetHandleFrame(self);

    return frame:CreateFontString(...)
end

---------------------------------------------------------------------------
-- Texture

function HANDLE:CreateTexture(...)
    local frame = GetHandleFrame(self);

    return frame:CreateTexture(...)
end

---------------------------------------------------------------------------
-- Backdrop

local backdropMethods = {
    'SetBackdrop', 'GetBackdrop',
    'GetBackdropColor', 'SetBackdropColor',
    'GetBackdropBorderColor', 'SetBackdropBorderColor'
}

for k,v in pairs(backdropMethods) do
    HANDLE[v] = function (self, ...)
        local frame = GetHandleFrame(self);

        if ( not frame[v] ) then
            error('Invalid frame method "'..v..'"')
        end

        return frame[v](frame, ...)
    end
end

Private.GetFrameHandle = GetFrameHandle
Private.GetFrameHandleFrame = GetFrameHandleFrame
Private.AddToFrameHandle = function(name)
    if ( HANDLE[name] ) then
        error('Private.AddToFrameHandle "'..name..'" already exists')
    end

    HANDLE[name] = function (self, ...)
        local frame = GetHandleFrame(self);

        if ( not frame[name] ) then
            error('Invalid frame method "'..name..'"')
        end

        return frame[name](frame, ...)
    end
end


Private.AddToFrameHandle('Collapse') -- group function