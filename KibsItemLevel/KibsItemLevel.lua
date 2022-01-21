LoadAddOn("Blizzard_InspectUI");
LoadAddOn("LibItemUpgradeInfo-1.0");
local FontStrings = {};
local InspectFontStrings = {};
local ActiveFontStrings = {};
local Icons = {};
local InspectIcons = {};
local ActiveIcons = {};
local InspectAilvl;
local EnchantIcons = {};
local InspectEnchantIcons = {};
local ActiveEnchantIcons = {};
local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0");
local ilvlFrame = CreateFrame("frame");
local iconSize = 16;
local iconOffset = 18;
local fontStyle = "SystemFont_Med1";
local UpdateInProgress = false;
local UpdateInProgressInspect = false;
ilvlFrame:RegisterEvent("VARIABLES_LOADED");

-- Globals
KibsItemLevel_variablesLoaded = false;
KibsItemLevel_details = {
	name = "KibsItemLevel",
	frame = "ilvlFrame",
	optionsframe = "KibsItemLevelConfigFrame"
	};
local KibsItemLevelConfig_defaultOn = true;
local KibsItemLevelConfig_defaultUpgrades = false;
local KibsItemLevelConfig_defaultCharacter = true;
local KibsItemLevelConfig_defaultInspection = true;
local KibsItemLevelConfig_defaultColor = true;

	

local emptySockets = { ["Meta "]    = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Meta",
                      ["Red "]     = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Red",
                      ["Blue "]    = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Blue",
					  ["Yellow "]  = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Yellow",
					  ["Prismatic "]  = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Prismatic",
                    } ;
					
local enchatableItems={ [ 1  ] = nil,
						[ 2  ] = nil,
						[ 3  ] = true,
						[ 15 ] = true,
						[ 5  ] = true,
						[ 9  ] = true,
						[ 10 ] = true,
						[ 6  ] = nil,
						[ 7  ] = true,
						[ 8  ] = true,
						[ 11 ] = nil,
						[ 12 ] = nil,
						[ 13 ] = nil,
						[ 14 ] = nil,
						[ 16 ] = true,
						[ 17 ] = true };

function KibsItemLevel_OnLoad()
	createFontStrings();
	createInspectFontStrings();
end

local waitTable = {};
local waitFrame = nil;

function KIL_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

function eventHandler(self,event,...)
	if(KibsItemLevelConfig.on)then
		if (event == "INSPECT_READY" and KibsItemLevelConfig.Inspection) then
			if(InspectFrame.unit)then
				if(UpdateInProgressInspect == false) then
					findItemInfo(InspectFrame.unit);
					KIL_wait(1.5,findItemInfo,InspectFrame.unit);
					KIL_wait(3,findItemInfo,InspectFrame.unit);
					KIL_wait(5,findItemInfo,InspectFrame.unit);
					UpdateInProgressInspect = true;
				end
			end
		elseif(KibsItemLevelConfig.Character) then
			
			if(UpdateInProgress == false) then
			UpdateInProgress = true;
			--findItemInfo("player");
			KIL_wait(0.2,findItemInfo,"player");
			KIL_wait(3,findItemInfo,"player");
			
			end
		end
	end
end
--Register Event Handler


function setupEventHandler(self,event,...)
	if (event == "VARIABLES_LOADED") then
		KibsItemLevelFrame_VARIABLES_LOADED();
		ilvlFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
		ilvlFrame:RegisterEvent("SOCKET_INFO_CLOSE");
		ilvlFrame:RegisterEvent("SOCKET_INFO_SUCCESS");
		ilvlFrame:RegisterEvent("SOCKET_INFO_UPDATE");
		ilvlFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
		ilvlFrame:RegisterEvent("INSPECT_READY");
		ilvlFrame:SetScript("OnEvent",eventHandler);
		--KIL_wait(0.2,findItemInfo,"player");
		findItemInfo("player");
	end
end
ilvlFrame:SetScript("OnEvent",setupEventHandler);

function KibsItemLevelFrame_VARIABLES_LOADED()
	if(KibsItemLevel_variablesLoaded)then
		return;
	end
	KibsItemLevel_variablesLoaded = true;
	if (not KibsItemLevelConfig) then
		KibsItemLevelConfig = {};
	end
	if (not KibsItemLevelConfig.on) then
		KibsItemLevelConfig.on = KibsItemLevelConfig_defaultOn;
	end
	if (not KibsItemLevelConfig.upgrades) then
		KibsItemLevelConfig.upgrades = KibsItemLevelConfig_defaultUpgrades;
	end
	if (not KibsItemLevelConfig.Character) then
		KibsItemLevelConfig.Character = KibsItemLevelConfig_defaultCharacter;
	end
	if (not KibsItemLevelConfig.Inspection) then
		KibsItemLevelConfig.Inspection = KibsItemLevelConfig_defaultInspection;
	end
	
	local ConfigPanel = CreateFrame("Frame", "KibsItemLevelConfigPanel", UIParent);
	ConfigPanel.name = "Kibs Item Level";
	
	local b = CreateFrame("CheckButton","Enabled",ConfigPanel,"UICheckButtonTemplate");
	b:SetPoint("TOPLEFT",ConfigPanel,"TOPLEFT",15,-15);
	b:SetChecked(KibsItemLevelConfig.on);
	_G[b:GetName() .. "Text"]:SetText("Enable Kibs Item Level");
	b:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.on = true; cleanUp(); else KibsItemLevelConfig.on = nil; cleanUp(); end end)
	
	local b1 = CreateFrame("CheckButton","Upgrades",ConfigPanel,"UICheckButtonTemplate");
	b1:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,0);
	b1:SetChecked(KibsItemLevelConfig.upgrades);
	_G[b1:GetName() .. "Text"]:SetText("Show upgrades, e.g. (4/4)");
	b1:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.upgrades = true; cleanUp(); else KibsItemLevelConfig.upgrades = nil; cleanUp(); end end)
	
	local b2 = CreateFrame("CheckButton","Char",ConfigPanel,"UICheckButtonTemplate");
	b2:SetPoint("TOPLEFT",b1,"BOTTOMLEFT",0,0);
	b2:SetChecked(KibsItemLevelConfig.Character);
	_G[b2:GetName() .. "Text"]:SetText("Show on Character Sheet");
	b2:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.Character = true; cleanUp(); else KibsItemLevelConfig.Character = nil; cleanUp(); end end)
	
	local b3 = CreateFrame("CheckButton","Insp",ConfigPanel,"UICheckButtonTemplate");
	b3:SetPoint("TOPLEFT",b2,"BOTTOMLEFT",0,0);
	b3:SetChecked(KibsItemLevelConfig.Inspection);
	_G[b3:GetName() .. "Text"]:SetText("Show on Inspection Frame");
	b3:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.Inspection = true; cleanUp(); else KibsItemLevelConfig.Inspection = nil; cleanUp(); end end)
	
	InterfaceOptions_AddCategory(ConfigPanel);
end

function cleanUp()
	for i = 1, 17 do
		if(FontStrings[i])then
			FontStrings[i]:SetText("");
			EnchantIcons[i].texture:SetAlpha(0.0);
			EnchantIcons[i]:SetScript("OnEnter",nil);
			
			InspectFontStrings[i]:SetText("");
			InspectEnchantIcons[i].texture:SetAlpha(0.0);
			InspectEnchantIcons[i]:SetScript("OnEnter",nil);
			
			local slotID = (i - 1) * 3 + 1;
			for j = slotID, slotID + 2 do
				Icons[j].texture:SetAlpha(0.0);
				Icons[j]:SetScript("OnEnter",nil);
				InspectIcons[j].texture:SetAlpha(0.0);
				InspectIcons[j]:SetScript("OnEnter",nil);
			end
		end
	end
	
	eventHandler(self,"PLAYER_EQUIPMENT_CHANGED");
end

function findItemInfo(who)
	if not (who) then
		return
	end
	local tilvl = 0;
	local numItems = 0;
	if (who == "player") then
		ActiveFontStrings = FontStrings;
		ActiveIcons = Icons;
		ActiveEnchantIcons = EnchantIcons;
		UpdateInProgress = false;
	else
		ActiveFontStrings = InspectFontStrings;
		ActiveIcons = InspectIcons;
		ActiveEnchantIcons = InspectEnchantIcons;
		UpdateInProgressInspect = false;
	end
	
	GameTooltip:Hide();
	for i = 1, 17 do
		if (ActiveFontStrings[i]) then
			local slotID = (i - 1) * 3 + 1;
			for i = slotID, slotID + 2 do
				ActiveIcons[i].texture:SetAlpha(0.0);
				ActiveIcons[i]:SetScript("OnEnter",nil);
			end
			ActiveEnchantIcons[i].texture:SetAlpha(0.0);
			ActiveEnchantIcons[i]:SetScript("OnEnter",nil);

			local itemlink=GetInventoryItemLink(who,i)
			local enchantInfo;
			if (itemlink) then
				local upgrade, max, delta = ItemUpgradeInfo:GetItemUpgradeInfo(itemlink)
				local ilvl = ItemUpgradeInfo:GetUpgradedItemLevel(itemlink)
				if not(ilvl) then ilvl = 0; end
				
				findSockets(who,i,slotID);
				
				numItems = numItems + 1;
				local line = "";
				GameTooltip:SetOwner(ilvlFrame,"CENTER");
				GameTooltip:SetHyperlink(itemlink);
				for i = 2, GameTooltip:NumLines() do
					line = _G[GameTooltip:GetName().."TextLeft"..i];
					if (line) then
						line = line:GetText();
						if (line) then
							if (line:find(ENCHANTED)) then
								enchantInfo = line;
							elseif(ilvl == 1) then
								if(line:match("Requires level")) then
									local n = line:sub(line:find("%(") + 1,line:find("%)") - 1);
									if n then
										ilvl = n ;
									end
								end
							end
						end
					end
				end
				
				if (upgrade and KibsItemLevelConfig.upgrades) then
					ActiveFontStrings[i]:SetText(ilvl .." ("..upgrade.."/"..max..")")
				else
					ActiveFontStrings[i]:SetText(ilvl)
				end
				
				if(ilvl)then
					tilvl = tilvl + ilvl;
				end
				
				if(enchantInfo) then
					ActiveEnchantIcons[i].texture:SetTexture("INTERFACE/ICONS/INV_Jewelry_Talisman_08");
					ActiveEnchantIcons[i].texture:SetAlpha(1.0);
					ActiveEnchantIcons[i]:SetScript("OnEnter",function(s,m)
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
						GameTooltip:ClearLines();
						GameTooltip:AddLine(enchantInfo);
						GameTooltip:Show(); 
						end);
					ActiveEnchantIcons[i]:SetScript("OnLeave",function(s,m)
						GameTooltip:Hide(); 
						end);
					
				elseif (enchatableItems[i]) then
					ActiveEnchantIcons[i].texture:SetTexture("INTERFACE/ICONS/INV_Jewelry_Talisman_08");
					ActiveEnchantIcons[i].texture:SetAlpha(0.5);
				else
					ActiveEnchantIcons[i].texture:SetTexture(0,0,0,0);
				end
			else
				ActiveFontStrings[i]:SetText("")
				if(i ~= 17) then
					numItems = numItems + 1;
				end
			end 
		end
	end
	if(who ~= "player") then
		InspectAilvl:SetText("ilvl: "..math.floor(tilvl / numItems));
	end
	GameTooltip:Hide();
end

function findSockets(who,slot,slotID)
	
	local itemLink = GetInventoryItemLink(who,slot);
	local _, _, Color, Ltype, itemID = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

	if (itemID) then
		--SOCKETS
		local _,cleanItemLink = GetItemInfo(itemID);
		if (cleanItemLink) then
			GameTooltip:ClearLines();
			GameTooltip:SetOwner(ilvlFrame,"CENTER");
			GameTooltip:SetHyperlink(cleanItemLink);
			local line;
			local texturePath;
			local sockets = slotID;
			for i = 2, GameTooltip:NumLines() do
				line = _G[GameTooltip:GetName().."TextLeft"..i];
				if (line) then
					line = line:GetText();
					if (line) then
						if(line:find("Socket")) then
							texturePath = emptySockets[line:sub(1, line:find("Socket") - 1)];
							if (texturePath) then
								ActiveIcons[sockets].texture:SetTexture(""..texturePath);
								ActiveIcons[sockets].texture:SetAlpha(1.0);
								sockets = sockets + 1;
							end
						end
						--else if(line:find("Touched\"")) then --UNCOMMENT TO SUPPORT SHA-TOUCHED SOCKETS
							--ActiveIcons[sockets].texture:SetTexture("INTERFACE/ITEMSOCKETINGFRAME/UI-EMPTYSOCKET-HYDRAULIC");
							--ActiveIcons[sockets].texture:SetAlpha(1.0);
							--sockets = sockets + 1;
						--end
						
					end
				end
			end
			
			--GEMS
			for i = 1, 3 do
				local _, itemLink = GetItemGem(GetInventoryItemLink(who,slot),i);
				if (itemLink) then
					ActiveIcons[i+slotID-1].texture:SetTexture(GetItemIcon(itemLink));
					ActiveIcons[i+slotID-1].texture:SetAlpha(1.0);
					ActiveIcons[i+slotID-1]:SetScript("OnEnter",function(s,m)
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
						GameTooltip:SetHyperlink(itemLink);
						GameTooltip:Show(); 
						end);
					ActiveIcons[i+slotID-1]:SetScript("OnLeave",function(s,m)
						GameTooltip:Hide(); 
						end);
				end
			end
		end
	end
	
end

--Layout Helpers
local slotID = {1,2,3,15,5,4,18,9,10,6,7,8,11,12,13,14,16,17} ;
local slotAlign1 = {	"TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT",
			"TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT",
			"BOTTOMRIGHT","BOTTOMLEFT" }
local slotAlign2 = {	"TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT",
			"TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT",
			"BOTTOMLEFT","BOTTOMRIGHT" }
local slotOffsetx = { 10, 10, 10, 10, 10, 10, 10, 10, 
			-10, -10, -10, -10, -10, -10, -10, -10, 
			-7, 7 } ;

local slotOffsety = { -5, -5, -5, -5, -5, -5, -5, 2, 
			-5, -5, -5, -5, -5, -5, -5, 2, 
			-7, -7 } ;
			
local iconAlign1 = {	"TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT","TOPLEFT",
			"TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT","TOPRIGHT",
			"BOTTOMRIGHT","BOTTOMLEFT" }
local iconAlign2 = {	"BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT","BOTTOMLEFT",
			"BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT","BOTTOMRIGHT",
			"TOPRIGHT","TOPLEFT" }
local iconOffsetx = { iconOffset, iconOffset, iconOffset, iconOffset, iconOffset, iconOffset, iconOffset, iconOffset, 
			-iconOffset, -iconOffset, -iconOffset, -iconOffset, -iconOffset, -iconOffset, -iconOffset, -iconOffset, 
			-iconOffset, iconOffset } ;

local iconOffsety = { -2, -2, -2, -2, -2, -2, -2, -2, 
			 -2, -2, -2, -2, -2, -2, -2, -2,  
			2, 2 } ;

--Create Font Strings
function createFontStrings()
	local kids = { PaperDollItemsFrame:GetChildren() };
	for i = 1, 18 do
		if not (i == 6 or i == 7) then --exclude 6 and 7, shirt and tabard
			local ID = slotID[i];
			FontStrings[ID] = kids[i]:CreateFontString("KILFrame_"..slotID[i], "OVERLAY", fontStyle)
			--FontStrings[ID]:SetParent(PaperDollItemsFrame)
			FontStrings[ID]:SetText(ID)
			FontStrings[ID]:SetPoint(slotAlign1[i], kids[i], slotAlign2[i] , slotOffsetx[i], slotOffsety[i])
			
			
			EnchantIcons[ID] = CreateFrame("Frame","EnchantIcon"..i,kids[i]);
			EnchantIcons[ID]:SetPoint(iconAlign1[i],FontStrings[ID],iconAlign2[i], 0, iconOffsety[i]);
			EnchantIcons[ID]:SetSize(iconSize,iconSize);
			local texture = EnchantIcons[ID]:CreateTexture("EnchantIconTex"..i,"OVERLAY");
			texture:SetAllPoints();
			EnchantIcons[ID].texture = texture;
			--EnchantIcons[ID].texture:SetTexture(1,1,0,1);
			
			local offset = iconOffsetx[i];
			local iconSlotID = (ID-1) * 3 + 1;
			for j = iconSlotID, iconSlotID + 2 do
				Icons[j] = CreateFrame("Frame","GemIcon"..j,kids[i]);
				Icons[j]:SetPoint(iconAlign1[i],FontStrings[ID],iconAlign2[i], offset, iconOffsety[i]);
				Icons[j]:SetSize(iconSize,iconSize);
				local texture = Icons[j]:CreateTexture("GemIconTex"..j,"OVERLAY");
				texture:SetAllPoints();
				Icons[j].texture = texture;
				--Icons[j].texture:SetTexture(1,1,0,1);
				offset = offset + iconOffsetx[i];
			end
			
			
		end
	end	
end

function createInspectFontStrings()
	local kids = { InspectPaperDollItemsFrame:GetChildren() };
	for i = 1, 18 do
		if not (i == 6 or i == 7) then --exclude 6 and 7, shirt and tabard
			local ID = slotID[i];
			InspectFontStrings[ID] = kids[i]:CreateFontString("KILFrame_Inspect_"..slotID[i], "OVERLAY", fontStyle)
			--FontStrings[ID]:SetParent(PaperDollItemsFrame)
			InspectFontStrings[ID]:SetText(ID)
			InspectFontStrings[ID]:SetPoint(slotAlign1[i], kids[i], slotAlign2[i] , slotOffsetx[i], slotOffsety[i])
			
			InspectEnchantIcons[ID] = CreateFrame("Frame","InspectEnchantIcon"..i,kids[i]);
			InspectEnchantIcons[ID]:SetPoint(iconAlign1[i],InspectFontStrings[ID],iconAlign2[i], 0, iconOffsety[i]);
			InspectEnchantIcons[ID]:SetSize(iconSize,iconSize);
			local texture = InspectEnchantIcons[ID]:CreateTexture("InspectEnchantIconTex"..i,"OVERLAY");
			texture:SetAllPoints();
			InspectEnchantIcons[ID].texture = texture;
			--InspectEnchantIcons[ID].texture:SetTexture(1,1,0,1);

			local iconSlotID = (ID-1) * 3 + 1;
			local offset = iconOffsetx[i];
			for j = iconSlotID, iconSlotID + 2 do
				InspectIcons[j] = CreateFrame("Frame","InspectGemIcon"..j,kids[i]);
				InspectIcons[j]:SetPoint(iconAlign1[i],InspectFontStrings[ID],iconAlign2[i], offset, iconOffsety[i]);
				InspectIcons[j]:SetSize(iconSize,iconSize);
				local texture = InspectIcons[j]:CreateTexture("InspectGemIconTex"..j,"OVERLAY");
				texture:SetAllPoints();
				InspectIcons[j].texture = texture;
				--InspectIcons[j].texture:SetTexture(1,1,0,1);
				offset = offset + iconOffsetx[i];
			end
		end
	end
	
	InspectAilvl = InspectPaperDollItemsFrame:CreateFontString("KILFrame_Inspect_Ailvl", "OVERLAY", fontStyle);
	InspectAilvl:SetText("ilvl: 0");
	InspectAilvl:SetPoint("BOTTOMRIGHT",InspectPaperDollItemsFrame,"BOTTOMRIGHT",-15,15);
	
end



