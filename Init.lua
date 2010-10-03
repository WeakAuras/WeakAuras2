WeakAuras = {};
WeakAuras.L = {};

local PowerAurasMediaTestFrame = CreateFrame("FRAME");
local PowerAurasMediaTestTexture = PowerAurasMediaTestFrame:CreateTexture();
if(PowerAurasMediaTestTexture:SetTexture("Interface\\Addons\\PowerAuras\\Auras\\Aura1")) then
  WeakAuras.PowerAurasPath = "Interface\\Addons\\PowerAuras\\Auras\\";
  WeakAuras.PowerAurasSoundPath = "Interface\\Addons\\PowerAuras\\Sounds\\"
elseif(PowerAurasMediaTestTexture:SetTexture("Interface\\Addons\\WeakAuras\\Auras\\Aura1")) then
  WeakAuras.PowerAurasPath = "Interface\\Addons\\WeakAuras\\Auras\\";
  WeakAuras.PowerAurasSoundPath = "Interface\\Addons\\WeakAuras\\Sounds\\";
else
  WeakAuras.PowerAurasPath = "";
  WeakAuras.PowerAurasSoundPath = "";
end