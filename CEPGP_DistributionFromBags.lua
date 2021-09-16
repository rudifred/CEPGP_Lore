local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP_Lore")

--[[ Globals ]]--

CEPGP_DFB_Addon = "CEPGP_DistributionFromBags"
CEPGP_DFB_LoadedAddon = false
CEPGP_DFB_LastTime = 0
CEPGP_DFB_LastLink = nil
CEPGP_DFB_Distributing = false
CEPGP_DFB_DistPlayerBtn = nil
CEPGP_DFB_IsAnnounced = false
CEPGP_DFB_distItemLink = nil
CEPGP_DFB_BagId = 0
CEPGP_DFB_SlotId = 0

SLASH_CEPGPDFB1 = "/DFB"
SLASH_CEPGPDFB2 = "/dfb"

--[[ SAVED VARIABLES ]]--
CEPGP_DFB_No_Trade = false
CEPGP_DFB_Enabled = true

--[[ Code ]]--
local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SHOW")
frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
frame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
frame:RegisterEvent("TRADE_REQUEST_CANCEL")
frame:RegisterEvent("ITEM_LOCKED")

frame:SetScript("OnEvent", CEPGP_DFB_OnEvent)
local origCEPGP_ListButton_OnClick = CEPGP_ListButton_OnClick
local origCEPGP_distribute_popup_give = CEPGP_distribute_popup_give

-- [[ CORE ]] --

function CEPGP_DFB_print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB:|r " .. "|c00FF0000Error|r|c00FFF569 - " .. tostring(str) .. "|r");
	end
end

local origCEPGP_distribute_roll_award_OnClick = _G["CEPGP_distribute_roll_award"]:GetScript("OnClick")
function CEPGP_DFB_CheckCepgpUiOverride(confirm)
	if CEPGP_DFB_Enabled and CEPGP_DFB_frame:IsShown() and confirm then
		_G["CEPGP_distribute_roll_award"]:SetText("")
		_G["CEPGP_distribute_roll_award"]:SetScript('OnClick', function() end);
		_G["CEPGP_distribute_roll_award"]:SetScript('OnEnter', function() 
			GameTooltip:SetOwner(_G["CEPGP_distribute_roll_award"], "ANCHOR_TOPRIGHT");
			GameTooltip:SetText("You can't do \"Award to Highest Roller\" on DFB mode.");
		end);
		_G["CEPGP_distribute_roll_award"]:SetScript('OnLeave', function() 
			GameTooltip:Hide();
		end);
	else  
		_G["CEPGP_distribute_roll_award"]:SetText("Award to Highest Roller")
		_G["CEPGP_distribute_roll_award"]:SetScript('OnClick', origCEPGP_distribute_roll_award_OnClick)
		_G["CEPGP_distribute_roll_award"]:SetScript('OnEnter', function() end);
    end
end

function CEPGP_DFB_toggle()
    if CEPGP_DFB_Enabled then
		CEPGP_DFB_Enabled= false;
	else  
		CEPGP_DFB_Enabled = true;
	end
end

function CEPGP_DFB_SlashCmd(arg)
	if not CEPGP_DFB_frame:IsShown() then
		if CEPGP_DFB_Enabled then
			ShowUIPanel(CEPGP_DFB_frame)
			OpenAllBags()
		else
			CEPGP_DFB_print("Please check CEPGP Config->Plugin Manager.", 1);
		end
	else
		HideUIPanel(CEPGP_DFB_frame)
	end
end

SlashCmdList["CEPGPDFB"] = CEPGP_DFB_SlashCmd

function CEPGP_DFB_init()
	
	--CEPGP_addPlugin("CEPGP_DistributionFromBags", nil, CEPGP_DFB_Enabled, CEPGP_DFB_toggle);

	if (_G.CEPGP_Lore) then
		_G.CEPGP_distribute_popup_give = CEPGP_distribute_popup_give_Hook
		_G.CEPGP_ListButton_OnClick = CEPGP_ListButton_OnClick_Hook
	end
	
	CEPGP_DFB_confirmation:Hide()
	_G["CEPGP_DFB_frame_text"]:SetText(L["Instruction"] )
	_G["CEPGP_DFB_frame_no_trade_text"]:SetText(L["Give GP without Trade confirm"] )
	_G["CEPGP_DFB_error_desc"]:SetText(L["Wrong Item"])

	CEPGP_DFB_frame:SetScript("OnShow", function()
		CEPGP_DFB_CheckCepgpUiOverride(true)
	end)

	CEPGP_DFB_frame:SetScript("OnHide", function()
		CEPGP_DFB_LastTime = 0
		CEPGP_DFB_LastLink = nil
		CEPGP_DFB_Distributing = false
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_Info.Loot.Distributing = false
		CEPGP_DFB_IsAnnounced = false
		CEPGP_DFB_CheckCepgpUiOverride(false)
	end)

	CEPGP_distribute_popup:HookScript("OnHide", function()
		if CEPGP_DFB_frame:IsShown() and CEPGP_DFB_Enabled then
			CEPGP_distribute_popup_pass:Show()
		end
	end)
	CEPGP_distribute_popup_pass:HookScript("OnClick", function()
		if CEPGP_DFB_frame:IsShown() and CEPGP_DFB_Enabled then
			CEPGP_DFB_DistPlayerBtn = nil
		end
	end)

end

function CEPGP_DFB_OnEvent(self, event, arg1, arg2, arg3, arg4, arg5)

	if event == "ADDON_LOADED" and arg1 == "CEPGP_Lore" and CEPGP_DFB_LoadedAddon == false then
        self:UnregisterEvent("ADDON_LOADED")
        CEPGP_DFB_LoadedAddon = true
		CEPGP_DFB_init()

	elseif event == "TRADE_SHOW" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn then
			PickupContainerItem(CEPGP_DFB_BagId, CEPGP_DFB_SlotId)
			ClickTradeButton(1)
			if CEPGP_DFB_distItemLink ~= GetTradePlayerItemLink(1) then
				CEPGP_DFB_error_open()
			end
		end

	elseif event == "TRADE_ACCEPT_UPDATE" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn then
			CEPGP_distribute_popup_pass:Hide()
			CEPGP_ListButton_OnClick(CEPGP_DFB_DistPlayerBtn, "LeftButton")
		end

	elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
		--if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn then
		--	if CEPGP_DFB_distItemLink ~= GetTradePlayerItemLink(1) then	-- didn't put the item on the trade window
		--		CEPGP_DFB_error_open()
		--	end
		--end

	elseif event == "TRADE_REQUEST_CANCEL" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn and not CEPGP_DFB_error:IsShown() then
			CEPGP_distribute_popup:Hide()
			CEPGP_DFB_confirmation:Show()
		end

	elseif event == "ITEM_LOCKED" then
		if CEPGP_DFB_frame:IsShown() and not CEPGP_DFB_DistPlayerBtn and IsShiftKeyDown() then
			CEPGP_DFB_BagId = arg1
			CEPGP_DFB_SlotId = arg2
			if arg2 ~= nil then  -- not equipment items
				ClearCursor()
				_, _, _, _, _, _, itemLink = GetContainerItemInfo(CEPGP_DFB_BagId, CEPGP_DFB_SlotId)
				if itemLink then
					CEPGP_DFB_LootFrame_Update(itemLink)
				end
			end
		end
	end
end

function CEPGP_DFB_LootFrame_Update(itemLink)

	if GetLootMethod() ~= "master" then
		CEPGP_DFB_print(L["The loot method is not Master Looter"], 1);
		return
	elseif CEPGP_isML() ~= 0 then
		CEPGP_DFB_print(L["You are not the Loot Master"], 1);
		return
	end

	local items = {};
    
    itemName, _, itemRarity, _, _, _, _, _,_, itemIcon, _, _, _, _, _, _, _ = GetItemInfo(itemLink) 
	if itemName == nil then return; end

	items[1] = {};
	items[1][1] = itemIcon;
	items[1][2] = itemName;
	items[1][3] = itemRarity;
	items[1][4] = itemLink;
	local itemString = string.find(itemLink, "item[%-?%d:]+");
	itemString = strsub(itemLink, itemString, string.len(itemLink)-string.len(itemName)-6);
	items[1][5] = itemString;
	items[1][6] = 1;	-- slot
	items[1][7] = 1;	-- quantity	

	CEPGP_DFB_Distributing = true
	CEPGP_DFB_DistPlayerBtn = nil
	CEPGP_DFB_IsAnnounced = false
	CEPGP_DFB_distItemLink = itemLink

	CEPGP_frame:Show();
	CEPGP_Info.Mode = "loot";
	CEPGP_toggleFrame("CEPGP_loot");
	CEPGP_populateFrame(items);
	CEPGP_announce(itemLink, 1, 1, 1)
end

function CEPGP_DFB_ConfirmWinner(player)
	CEPGP_DFB_confirmation:SetAttribute("player", player)
	if player == UnitName("player") then
		_G["CEPGP_DFB_confirmation_desc"]:SetText(CEPGP_DFB_distItemLink .. "\n\nTo yourself")
		_G["CEPGP_DFB_confirmation_yes"]:SetText("OK")
	else
		_G["CEPGP_DFB_confirmation_desc"]:SetText(CEPGP_DFB_distItemLink .. "\n\n" .. player ..  L[" is the winner"])
		_G["CEPGP_DFB_confirmation_yes"]:SetText("Trade")
	end
	CEPGP_DFB_confirmation:Show()
end

function CEPGP_DFB_error_open()
	ClearCursor()
	CancelTrade()
	local player = CEPGP_DFB_confirmation:GetAttribute("player")
	_G["CEPGP_DFB_error_desc"]:SetText(player..L["Wrong Item"])	
	CEPGP_DFB_error:Show()
	if CEPGP_Lore.Loot.RaidWarning then
		SendChatMessage(player..L["Wrong Item"]  , "RAID_WARNING", CEPGP_LANGUAGE);
	else
		SendChatMessage(player..L["Wrong Item"] , "RAID", CEPGP_LANGUAGE);
	end
end

function CEPGP_DFB_error_close()
	CEPGP_DFB_DistPlayerBtn = nil
	CEPGP_DFB_error:Hide();
end

function CEPGP_DFB_AnnounceWinner(isWinner)
	if isWinner then
		local player = CEPGP_DFB_confirmation:GetAttribute("player")

		if CEPGP_DFB_No_Trade then	-- Without Trade Comfirm
			CEPGP_DFB_confirmation:Hide();
			CEPGP_ListButton_OnClick(CEPGP_DFB_DistPlayerBtn, "LeftButton")
			return
		end

		if player == UnitName("player") then
			CEPGP_DFB_confirmation:Hide();
			CEPGP_ListButton_OnClick(CEPGP_DFB_DistPlayerBtn, "LeftButton")
		else
			if not CEPGP_DFB_IsAnnounced then
				if CEPGP_Lore.Loot.RaidWarning then
					SendChatMessage(player .. L[" is the winner. Come to trade with me"] , "RAID_WARNING", CEPGP_LANGUAGE);
				else
					SendChatMessage(player .. L[" is the winner. Come to trade with me"] , "RAID", CEPGP_LANGUAGE);
				end
				CEPGP_DFB_IsAnnounced = true
			end
			if CheckInteractDistance(player, 2) then
				CEPGP_DFB_confirmation:Hide();
				InitiateTrade(player)
			else
				CEPGP_DFB_print(player.." is too far away", true)
			end
		end
	else
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_DFB_confirmation:Hide();
	end
end

-- [[ CEPGP Hook ]] --
function CEPGP_ListButton_OnClick_Hook(obj, button)
	if CEPGP_DFB_Distributing and button == "LeftButton" then
		--[[ Distribution Menu ]]--
		if CEPGP_DFB_frame:IsShown() and strfind(obj, "LootDistButton") then --A player in the distribution menu is clicked
			if CEPGP_DFB_DistPlayerBtn then
				if CEPGP_DFB_confirmation:IsShown() then
					CEPGP_DFB_DistPlayerBtn = nil
					CEPGP_DFB_confirmation:Hide()
					return
				end
			else
				CEPGP_DFB_IsAnnounced = false
				local player = _G[_G[obj]:GetName() .. "Info"]:GetText()
				CEPGP_DFB_DistPlayerBtn = obj
				CEPGP_DFB_ConfirmWinner(player)
				return
			end
		end
	end
	origCEPGP_ListButton_OnClick(obj, button)
end

function CEPGP_distribute_popup_give_Hook()
	if CEPGP_DFB_frame:IsShown() then
		CEPGP_handleLoot("LOOT_SLOT_CLEARED", 1)
		CEPGP_DFB_Distributing = false
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_DFB_IsAnnounced = false
	else
		origCEPGP_distribute_popup_give()
	end
end