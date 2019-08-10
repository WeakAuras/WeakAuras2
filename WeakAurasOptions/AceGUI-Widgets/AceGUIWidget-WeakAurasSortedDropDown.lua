if not WeakAuras.IsCorrectVersion() then return end

local Type, Version = "WeakAurasSortedDropdown", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function Constructor()
  local DropDownConstructor = AceGUI.WidgetRegistry["Dropdown"];
  if (not DropDownConstructor) then
    return nil;
  end
  local widget = DropDownConstructor();
  if (not widget) then
    return nil;
  end

  local oldSetList = widget.SetList
  widget.SetList = function(self, list, _, itemType)
    local orderTable = {};
    for k, v in pairs(list) do
      tinsert(orderTable, { key = k, value = v  });
    end

    local order = {};

    table.sort(orderTable, function(a, b)
      return a.value < b.value;
    end);

    for i, item in ipairs(orderTable) do
      order[i] = item.key;
    end

    oldSetList(self, list, order, itemType)
  end

  widget.type = Type;

  return widget;
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
