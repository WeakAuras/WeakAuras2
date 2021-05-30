if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local ENV = getfenv(0);
local issecurevariable = ENV.issecurevariable;
local type = ENV.type;
local newproxy = ENV.newproxy;
local next = ENV.next;
local pairs = ENV.pairs;
local ipairs = ENV.ipairs;
local setmetatable = ENV.setmetatable;
local getmetatable = ENV.getmetatable;



local IsFrameHandle = Private.IsFrameHandle;

local RestrictedTable_create

local LOCAL_Restricted_Tables = {};
setmetatable(LOCAL_Restricted_Tables, { __mode="k" });

local LOCAL_Real_Tables = {}
setmetatable(LOCAL_Real_Tables, { __mode="k"})

local LOCAL_Real_Variables = {}
setmetatable(LOCAL_Real_Variables, { __mode="k"})

local LOCAL_Readonly_Restricted_Tables = {};
setmetatable(LOCAL_Readonly_Restricted_Tables, { __mode="k" });

local function CheckReadonlyValue(ret, real, key)

    local tret = type(ret);

    if ( tret == "userdata" ) then
        if (LOCAL_Restricted_Tables[ret]) then
            return LOCAL_Readonly_Restricted_Tables[ret];
        elseif (IsFrameHandle(ret)) then
            return ret
        end
    elseif ( tret == "table" ) then
        if ( LOCAL_Real_Tables[ret] ) then
            return LOCAL_Real_Tables[ret]
        else
            local isSecure = issecurevariable(real, key)
            if ( isSecure ) then
                return RestrictedTable_create(ret)
            end
        end
    elseif ( tret == "function" ) then
        if ( LOCAL_Real_Variables[ret] ) then
            return ret
        else
            local isSecure = issecurevariable(real, key)
            if ( isSecure ) then
                LOCAL_Real_Variables[ret] = true;
                return ret;
            end
        end
    elseif ( tret == "string" or tret == "number" or tret == "boolean"  ) then
        return ret;
    end

    return nil;
end

local LOCAL_Readonly_Restricted_Table_Meta = {
    __index = function(t, k)
        local real = LOCAL_Restricted_Tables[t];
        return CheckReadonlyValue(real[k], real, k)
    end,

    __newindex = function(t, k, v)
        error("Table is read-only");
    end,

    __len = function(t)
        local real = LOCAL_Restricted_Tables[t];
        return #real;
    end,

    __metatable = true,
}

local LOCAL_Readonly_Restricted_Prototype = newproxy(true);
do
    local meta = getmetatable(LOCAL_Readonly_Restricted_Prototype);
    for k, v in pairs(LOCAL_Readonly_Restricted_Table_Meta) do
        meta[k] = v;
    end
end

local function RestrictedTable_Readonly_index(t, k)
    local real = LOCAL_Restricted_Tables[k];
    if (not real) then return; end

    local ret = newproxy(LOCAL_Readonly_Restricted_Prototype);

    LOCAL_Restricted_Tables[ret] = real;
    LOCAL_Real_Tables[real] = ret;

    t[k] = ret;
    return ret;
end

getmetatable(LOCAL_Readonly_Restricted_Tables).__index
    = RestrictedTable_Readonly_index;

function RestrictedTable_create(from)
    local ret = newproxy(LOCAL_Readonly_Restricted_Prototype);

    LOCAL_Restricted_Tables[ret] = from;
    LOCAL_Real_Tables[from] = ret;

    return ret;
end

local function RestrictedTable_next(T, k)
    local PT = LOCAL_Restricted_Tables[T];
    if (PT) then
        local idx, val = next(PT, k);
        if (val ~= nil) then
            return idx, CheckReadonlyValue(val, PT, idx);
        else
            return idx, val;
        end
    end
    return next(T, k);
end

local function RestrictedTable_pairs(T)
    local PT = LOCAL_Restricted_Tables[T];
    if (PT) then
        -- v
        return RestrictedTable_next, T, nil;
    end
    return pairs(T);
end

local function RestrictedTable_ipairsaux(T, i)
    i = i + 1;
    local v = T[i];
    if (v) then
        return i, v;
    end
end

local function RestrictedTable_ipairs(T)
    local PT = LOCAL_Restricted_Tables[T];
    if (PT) then
        return RestrictedTable_ipairsaux, T, 0;
    end
    return ipairs(T);
end

local function RestrictedTable_type(obj)
    local t = type(obj);
    if (t == "userdata") then
        if (LOCAL_Restricted_Tables[obj]) then
            t = "table";
        end
    end
    return t;
end

function Private.GetManagedEnvironment()
    return RestrictedTable_create(ENV)
end

Private.RestrictedTable_API = {
    next = RestrictedTable_next,
    pairs = RestrictedTable_pairs,
    ipairs = RestrictedTable_ipairs,
    type = RestrictedTable_type,
}