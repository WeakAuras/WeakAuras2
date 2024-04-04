if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

-- This is a more or less 1:1 copy of SmoothStatusBarMixin except that it
-- doesn't clamp the targetValue in ProcessSmoothStatusBars, because that's incorrect for us
local g_updatingBars = {};

local function IsCloseEnough(bar, newValue, targetValue)
        local min, max = bar:GetMinMaxValues();
        local range = max - min;
        if range > 0.0 then
                return math.abs((newValue - targetValue) / range) < .00001;
        end

        return true;
end

local function ProcessSmoothStatusBars()
        for bar, targetValue in pairs(g_updatingBars) do
                local newValue = FrameDeltaLerp(bar:GetValue(), targetValue, .25);

                if IsCloseEnough(bar, newValue, targetValue) then
                        g_updatingBars[bar] = nil;
                        bar:SetValue(targetValue);
                else
                        bar:SetValue(newValue);
                end
        end
end

C_Timer.NewTicker(0, ProcessSmoothStatusBars);

Private.SmoothStatusBarMixin = {};

function Private.SmoothStatusBarMixin:ResetSmoothedValue(value) --If nil, tries to set to the last target value
        local targetValue = g_updatingBars[self];
        if targetValue then
                g_updatingBars[self] = nil;
                self:SetValue(value or targetValue);
        elseif value then
                self:SetValue(value);
        end
end

function Private.SmoothStatusBarMixin:SetSmoothedValue(value)
        g_updatingBars[self] = value;
end

function Private.SmoothStatusBarMixin:SetMinMaxSmoothedValue(min, max)
        self:SetMinMaxValues(min, max);

        local targetValue = g_updatingBars[self];
        if targetValue then
                local ratio = 1;
                if max ~= 0 and self.lastSmoothedMax and self.lastSmoothedMax ~= 0 then
                        ratio = max / self.lastSmoothedMax;
                end

                g_updatingBars[self] = targetValue * ratio;
        end

        self.lastSmoothedMin = min;
        self.lastSmoothedMax = max;
end
