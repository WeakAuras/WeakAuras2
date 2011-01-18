local L = WeakAuras.L;

local function Hooked_AddMessage(self, msg, ...)
	local newMsg = "";
	local remaining = msg;
	local done;
	repeat
		local start, finish, characterName, displayName = remaining:find("%[WeakAuras: ([^%s]+) %- ([^%]]+)%]");
		if(characterName and displayName) then
			characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			newMsg = newMsg..remaining:sub(1, start-1);
			newMsg = newMsg.."|Hweakauras|h|cFF8800FF["..characterName.." |r|cFF8800FF- "..displayName.."]|h|r";
			remaining = remaining:sub(finish + 1);
		else
			newMsg = newMsg..remaining;
			done = true;
		end
	until(done)
	return self:WeakAuras_Original_AddMessage(newMsg, ...);
end

local frame = CreateFrame("frame");
frame:RegisterEvent("VARIABLES_LOADED");
frame:SetScript("OnEvent", function()
	for i=1,NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame"..i];
		cf.WeakAuras_Original_AddMessage = cf.AddMessage;
		cf.AddMessage = Hooked_AddMessage;
	end
end);

function WeakAuras.ShowTooltip(content)
	ShowUIPanel(ItemRefTooltip);
	if not ItemRefTooltip:IsVisible() then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
	end
	ItemRefTooltip:ClearLines();
	for i,v in pairs(content) do
		local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(v);
		if(sides == 1) then
			ItemRefTooltip:AddLine(a1, a2, a3, a4);
		elseif(sides == 2) then
			ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8);
		end
	end
	ItemRefTooltip:Show();
end

local Original = ChatFrame_OnHyperlinkShow;
ChatFrame_OnHyperlinkShow = function(self, link, text, button)
	if(ItemRefTooltip.WeakAuras_Tooltip_Texture) then
		ItemRefTooltip.WeakAuras_Tooltip_Texture:Hide();
	end
	if(ItemRefTooltip.WeakAuras_Tooltip_Button) then
		ItemRefTooltip.WeakAuras_Tooltip_Button:Hide();
	end
	if(link:find("weakauras")) then
		local _, _, characterName, displayName = text:find("|Hweakauras|h|cFF8800FF%[([^%s]+) |r|cFF8800FF%- ([^%]]+)%]|h");
		if(characterName and displayName) then
			characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			WeakAuras.ShowTooltip({
				{2, "WeakAuras", displayName, 0.5, 0, 1, 1, 1, 1},
				{1, "Requesting display information from "..characterName.."...", 1, 0.82, 0}
			});
			WeakAuras.RequestDisplay(characterName, displayName);
		else
			WeakAuras.ShowTooltip({
				{1, "WeakAuras", 0.5, 0, 1},
				{1, "Malformed WeakAuras link", 1, 0, 0}
			});
		end
	else
		Original(self, link, text, button);
	end
end

local Compresser = LibStub:GetLibrary("LibCompress");
local Encoder = Compresser:GetChatEncodeTable();
LibStub("AceSerializer-3.0"):Embed(WeakAuras);
LibStub("AceComm-3.0"):Embed(WeakAuras);

function WeakAuras.TableToString(inTable)
	local serialized = WeakAuras:Serialize(inTable);
	local compressed = Compresser:CompressHuffman(serialized);
	return Encoder:Encode(compressed);
end

function WeakAuras.StringToTable(inString)
	local decoded = Encoder:Decode(inString);
	local decompressed, errorMsg = Compresser:DecompressHuffman(decoded);
	if(not decompressed) then
		print("Error decompressing: "..errorMsg);
		return;
	end
	local success, deserialized = WeakAuras:Deserialize(decompressed);
	if(not success) then
		print("Error deserializing "..deserialized);
		return;
	end
	return deserialized;
end

function WeakAuras.DisplayToString(id)
	local data = WeakAuras.GetData(id);
	if(data) then
		local transmit = {
			messageType = "display",
			owner = GetUnitName("player"),
			id = id,
			display = data
		};
		return WeakAuras.TableToString(transmit);
	else
		return "";
	end
end

function WeakAuras.RequestDisplay(characterName, displayName)
	local transmit = {
		messageType = "displayRequest",
		displayName = displayName
	};
	WeakAuras:SendCommMessage("WeakAuras", WeakAuras.TableToString(transmit), "WHISPER", characterName);
end

function WeakAuras.TransmitError(errorMsg, characterName, displayName)
	local transmit = {
		messageType = "displayError",
		displayName = displayName,
		errorMsg = errorMsg
	};
	WeakAuras:SendCommMessage("WeakAuras", WeakAuras.TableToString(transmit), "WHISPER", characterName);
end

function WeakAuras.TransmitDisplay(id, characterName)
	local encoded = WeakAuras.DisplayToString(id);
	if(encoded ~= "") then
		WeakAuras:SendCommMessage("WeakAuras", encoded, "WHISPER", characterName);
	else
		WeakAuras.TransmitError("does not exist", characterName, displayName);
	end
end

WeakAuras:RegisterComm("WeakAuras", function(prefix, message, distribution, sender)
	local received = WeakAuras.StringToTable(message);
	if(received and received.messageType) then
		if(received.messageType == "display") then
			local tooltip = {
				{2, "WeakAuras", received.id, 0.5, 0, 1, 1, 1, 1},
				{1, "From: "..received.owner, 0, 1, 0},
			};
			local function traverse(inTable, depth)
				for i,v in pairs(inTable) do
					if(type(v) == "table") then
						tinsert(tooltip, {2, ("  "):rep(depth)..i..":", "table", 1, 1, 1, 1, 1, 1});
						--tinsert(tooltip, {1, ("  "):rep(depth)..i..":", 1, 1, 1});
						--traverse(v, depth + 1);
					else
						local display;
						if(type(v) == "boolean") then
							if(v) then
								display = "true";
							else
								display = "false";
							end
						else
							display = ""..v;
						end
						tinsert(tooltip, {2, ("  "):rep(depth)..i..":", display, 1, 1, 1, 1, 1, 1});
					end
				end
			end
			traverse(received.display, 0);
			tinsert(tooltip, {1, " "});
			tinsert(tooltip, {1, " "});
			WeakAuras.ShowTooltip(tooltip);
			if not(ItemRefTooltip.WeakAuras_Tooltip_Texture) then
				ItemRefTooltip.WeakAuras_Tooltip_Texture = ItemRefTooltip:CreateTexture();
			end
			if not(ItemRefTooltip.WeakAuras_Tooltip_Button) then
				ItemRefTooltip.WeakAuras_Tooltip_Button = CreateFrame("Button", "WeakAurasTooltipImportButton", ItemRefTooltip, "UIPanelButtonTemplate2")
			end
			importbutton = ItemRefTooltip.WeakAuras_Tooltip_Button;
			importbutton:SetPoint("BOTTOMRIGHT", ItemRefTooltip, "BOTTOMRIGHT", -20, 8);
			importbutton:SetText("Import");
			importbutton:SetWidth(100);
			importbutton:SetScript("OnClick", function()
				local id = received.id
				local num = 2;
				while(WeakAurasSaved.displays[id]) do
					id = received.id..num;
					num = num + 1;
				end
				received.display.id = id;
				received.display.parent = nil;
				if(received.display.controlledChildren) then
					received.display.controlledChildren = {};
				end
				WeakAuras.Add(received.display);
				if not(IsAddOnLoaded("WeakAurasOptions")) then
					local loaded, reason = LoadAddOn("WeakAurasOptions");
					if not(loaded) then
						print("WeakAurasOptions could not be loaded:", reason);
					end
				end
				local optionsFrame = WeakAuras.OptionsFrame();
				if not(optionsFrame) then
					WeakAuras.ToggleOptions();
					optionsFrame = WeakAuras.OptionsFrame();
				end
				WeakAuras.NewDisplayButton(received.display);
			end);
			importbutton:Show();
			local texture = ItemRefTooltip.WeakAuras_Tooltip_Texture;
			texture:SetWidth(32);
			texture:SetHeight(32);
			local _, _, icon = GetSpellInfo(95375);
			texture:SetTexture(received.display.displayIcon or icon);
			texture:SetPoint("RIGHT", ItemRefTooltip, "LEFT");
			texture:SetPoint("TOP", ItemRefTooltip, "TOP", 0, -4);
			texture:Show();
		elseif(received.messageType == "displayRequest") then
			--if(WeakAuras.linked[received.displayName]) then
				WeakAuras.TransmitDisplay(received.displayName, sender);
			--else
			--	WeakAuras.TransmitError("not authorized", sender, received.displayName);
			--end
		elseif(received.messageType == "displayError") then
			if(received.errorMsg == "does not exist") then
				WeakAuras.ShowTooltip({
					{2, "WeakAuras", received.displayName, 0.5, 0, 1, 1, 1, 1},
					{1, L["Requested display does not exist"], 1, 0, 0}
				});
			elseif(received.errorMsg == "not authorized") then
				WeakAuras.ShowTooltip({
					{2, "WeakAuras", received.displayName, 0.5, 0, 1, 1, 1, 1},
					{1, L["Requested display not authorized"], 1, 0, 0}
				});
			end
		end
	end
end);