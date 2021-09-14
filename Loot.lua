function CEPGP_LootFrame_Update()
	local items = {};
	local count = 0;
	if CEPGP_Info.ElvUI then
		local numLootItems = GetNumLootItems();
		local texture, item, quantity, quality;
		for index = 1, numLootItems do
			if ( index <= numLootItems ) then	
				texture, item, quantity, _, quality = GetLootSlotInfo(index);
				if (tostring(GetLootSlotLink(index)) ~= "nil" or CEPGP_inOverride(item)) and item ~= nil then
					items[index-count] = {};
					items[index-count][1] = texture;
					items[index-count][2] = item;
					items[index-count][3] = quality;
					items[index-count][4] = GetLootSlotLink(index);
					local link = GetLootSlotLink(index);
					local itemString = string.find(link, "item[%-?%d:]+");
					itemString = strsub(link, itemString, string.len(link)-string.len(item)-6);
					items[index-count][5] = itemString;
					items[index-count][6] = index;
					items[index-count][7] = quantity;
				else
					count = count + 1;
				end
			end
		end
	else
		local numLootItems = LootFrame.numLootItems;
		local texture, item, quantity, quality;
		for index = 1, numLootItems do
			local slot = index;
			if ( slot <= numLootItems ) then	
				if (LootSlotHasItem(slot)) then
					texture, item, quantity, _, quality = GetLootSlotInfo(slot);
					if tostring(GetLootSlotLink(slot)) ~= "nil" or CEPGP_inOverride(item) then
						items[index-count] = {};
						items[index-count][1] = texture;
						items[index-count][2] = item;
						items[index-count][3] = quality;
						items[index-count][4] = GetLootSlotLink(slot);
						local link = GetLootSlotLink(index);
						local itemString = string.find(link, "item[%-?%d:]+");
						itemString = strsub(link, itemString, string.len(link)-string.len(item)-6);
						items[index-count][5] = itemString;
						items[index-count][6] = slot;
						items[index-count][7] = quantity;
					else
						count = count + 1;
					end
				end
			end
		end
	end
	for k, v in pairs(items) do -- k = loot slot number, v is the table result
		if (UnitInRaid("player") or CEPGP_Info.Debug) and (v[3] >= CEPGP.Loot.MinThreshold) or (CEPGP_inOverride(v[2]) or CEPGP_inOverride(v[4])) then
			if CEPGP_isML() == 0 then
				CEPGP_frame:Show();
				CEPGP_Info.Mode = "loot";
				CEPGP_toggleFrame("CEPGP_loot");
			end
			break;
		end
	end
	CEPGP_populateFrame(items);
end

function CEPGP_announce(link, x, slotNum, quantity)

	if (GetLootMethod() == "master" and CEPGP_isML() == 0) or CEPGP_Info.Debug then
		local iString = CEPGP_getItemString(link);
		local name, _, _, _, _, _, _, _, slot, tex = GetItemInfo(iString);
		local id = CEPGP_getItemID(iString);
		CEPGP_Info.Loot.GUID = id .. "-" .. GetTime();	--	Note: This is a custom GUID and is not the standard format provided by the client
		CEPGP_Info.Loot.Expired = false;
		for i = 1, 4 do
			CEPGP_Info.LootSchema[i] = CEPGP.Loot.GUI.Buttons[i][2];
		end
		CEPGP_Info.LootSchema[5] = "";
		CEPGP_Info.LootSchema[6] = "Pass";
		CEPGP_Info.Loot.NumOnline = CEPGP_GetNumOnlineGroupMembers();
		
		local temp = {};
		for label, v in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
			for _, disc in pairs(v) do
				local entry = {[1] = label, [2] = disc};
				table.insert(temp, entry);
			end
		end
		
		temp = CEPGP_tSort(temp, 2, true);
		
		for index, t in ipairs(temp) do
			CEPGP_Info.LootSchema[index+6] = t[1];
		end
		
		local schema = "lootschema";
		local temp = {};	--	Only used if schema needs to be separated due to length
		for index, response in ipairs(CEPGP_Info.LootSchema) do
			if #(schema .. index .. ";" .. response) > 249 then
				table.insert(temp, schema);
				schema = "lootschema;" .. index .. ";" .. response;
		   else
				schema = schema .. ";" .. index .. ";" .. response;
			end
		end
		table.insert(temp, schema);
		
		--if CEPGP.Loot.RaidVisibility[1] or CEPGP.Loot.RaidVisibility[2] then
		for _, schema in ipairs(temp) do
			CEPGP_addAddonMsg(schema, "RAID");
		end
		--end
		
		CEPGP_Info.Loot.Distributing = true;
		CEPGP_toggleGPEdit(false);
		CEPGP_Info.Loot.ItemsTable = {};
		CEPGP_Info.Loot.DistributionID = id;
		CEPGP_Info.Loot.Master = UnitName("player");
		CEPGP_addAddonMsg("CEPGP_setDistID;" .. id, "RAID");
		CEPGP_addAddonMsg("CEPGP_setLootGUID;" .. CEPGP_Info.Loot.GUID, "RAID");
		CEPGP_Info.Loot.DistEquipSlot = slot;
		gp = _G[CEPGP_Info.Mode..'itemGP'..x]:GetText();
		CEPGP_Info.Loot.SlotNum = slotNum;
		CEPGP_UpdateLootScrollBar();		
		_G["CEPGP_respond_texture"]:SetTexture(tex);
		_G["CEPGP_respond_texture_frame"]:SetScript('OnEnter', function()
			GameTooltip:SetOwner(_G["CEPGP_respond_texture_frame"], "ANCHOR_TOPLEFT")
			GameTooltip:SetHyperlink(iString);
			GameTooltip:Show();
		end);
		_G["CEPGP_respond_texture_frame"]:SetScript('OnLeave', function()
			GameTooltip:Hide();
		end);
		_G["CEPGP_respond_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString, name); end);
		_G["CEPGP_respond_item_name"]:SetText(link);
		local rank = 0;
		for i = 1, GetNumGroupMembers() do
			if UnitName("player") == GetRaidRosterInfo(i) then
				_, rank = GetRaidRosterInfo(i);
			end
		end
		
		local message = "RaidAssistLootDist;"..link..";"..gp..";true";
		CEPGP_sendLootMessage(message);
		
		--	Messages are much faster when sent via the WHISPER channel, so a delay is needed so the distribution ID can be set in time
		--C_Timer.After(1, function()
			--[[if CEPGP.Loot.RaidVisibility[2] then
				CEPGP_addAddonMsg("RaidAssistLootDist;"..link..";"..gp..";true", "RAID");
			elseif CEPGP.Loot.RaidVisibility[1] then
				CEPGP_messageGroup("RaidAssistLootDist;"..link..";"..gp..";true", "assists");
			end]]
		--end);
		
		SendChatMessage("--------------------------", "RAID", CEPGP_Info.Language);
		if rank > 0 then
			if quantity > 1 then
				if CEPGP.Loot.RaidWarning then
					SendChatMessage("NOW DISTRIBUTING: x" .. quantity .. " " .. link, "RAID_WARNING", CEPGP_Info.Language);
				else
					SendChatMessage("NOW DISTRIBUTING: x" .. quantity .. " " .. link, "RAID", CEPGP_Info.Language);
				end
			else
				if CEPGP.Loot.RaidWarning then
					SendChatMessage("NOW DISTRIBUTING: " .. link, "RAID_WARNING", CEPGP_Info.Language);
				else
					SendChatMessage("NOW DISTRIBUTING: " .. link, "RAID", CEPGP_Info.Language);
				end
			end
		else
			if quantity > 1 then
				SendChatMessage("NOW DISTRIBUTING: x" .. quantity .. " " .. link, "RAID", CEPGP_Info.Language);
			else
				SendChatMessage("NOW DISTRIBUTING: " .. link, "RAID", CEPGP_Info.Language);
			end
		end
		if quantity > 1 then
			SendChatMessage("GP Value: " .. gp .. " (~" .. math.floor(gp/quantity) .. "GP per unit)", "RAID", CEPGP_Info.Language);
		else
			SendChatMessage("GP Value: " .. gp, "RAID", CEPGP_Info.Language);
		end
		if CEPGP.Loot.GUI.Timer > 0 then
			SendChatMessage("Time to respond: " .. CEPGP.Loot.GUI.Timer .. (CEPGP.Loot.GUI.Timer > 1 and " seconds" or " second"), "RAID", CEPGP_Info.Language);
		end

		SendChatMessage(CEPGP.Loot.Announcement, "RAID", CEPGP_Info.Language);
		if not CEPGP.Loot.HideKeyphrases then
			SendChatMessage(CEPGP.Loot.GUI.Buttons[1][4] .. " : " .. CEPGP.Loot.GUI.Buttons[1][2], "RAID", CEPGP_Info.Language);
			if CEPGP.Loot.GUI.Buttons[2][1] then
				SendChatMessage(CEPGP.Loot.GUI.Buttons[2][4] .. " : " .. CEPGP.Loot.GUI.Buttons[2][2], "RAID", CEPGP_Info.Language);
			end
			if CEPGP.Loot.GUI.Buttons[3][1] then
				SendChatMessage(CEPGP.Loot.GUI.Buttons[3][4] .. " : " .. CEPGP.Loot.GUI.Buttons[3][2], "RAID", CEPGP_Info.Language);
			end
			if CEPGP.Loot.GUI.Buttons[4][1] then
				SendChatMessage(CEPGP.Loot.GUI.Buttons[4][4] .. " : " .. CEPGP.Loot.GUI.Buttons[4][2], "RAID", CEPGP_Info.Language);
			end
		end
		
		local keywords = {};
	
		for label, v in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
			local entry = {};
			for key, disc in pairs(v) do
				entry = {[1] = label, [2] = key, [3] = disc};
			end
			table.insert(keywords, entry);
		end
		
		keywords = CEPGP_tSort(keywords, 3, true);
		
		for k, v in ipairs(keywords) do
			SendChatMessage(v[2] .. " : " .. v[1], "RAID", CEPGP_Info.Language);
		end
	
		SendChatMessage("--------------------------", "RAID", CEPGP_Info.Language);
		
		
		local call = "CallItem;"..id..";"..gp;
		local buttons = {};
		if CEPGP.Loot.GUI.Buttons[1][1] then
			call = call .. ";" .. CEPGP.Loot.GUI.Buttons[1][2];
			buttons[1] = CEPGP.Loot.GUI.Buttons[1][2];
		else
			call = call .. ";";
		end
		if CEPGP.Loot.GUI.Buttons[2][1] then
			call = call .. ";" .. CEPGP.Loot.GUI.Buttons[2][2];
			buttons[2] = CEPGP.Loot.GUI.Buttons[2][2];
		else
			call = call .. ";";
		end
		if CEPGP.Loot.GUI.Buttons[3][1] then
			call = call .. ";" .. CEPGP.Loot.GUI.Buttons[3][2];
			buttons[3] = CEPGP.Loot.GUI.Buttons[3][2];
		else
			call = call .. ";";
		end
		if CEPGP.Loot.GUI.Buttons[4][1] then
			call = call .. ";" .. CEPGP.Loot.GUI.Buttons[4][2];
			buttons[4] = CEPGP.Loot.GUI.Buttons[4][2];
		else
			call = call .. ";";
		end
		call = call .. ";" .. tostring(CEPGP.Loot.GUI.Timer) .. ";" .. CEPGP_Info.Loot.GUID;
		CEPGP_callItem(id, gp, buttons, CEPGP.Loot.GUI.Timer);
		--CEPGP_addAddonMsg(call, "RAID");
		CEPGP_addAddonMsg(call, "RAID");
		
			
		CEPGP_distribute:Show();
		CEPGP_loot:Hide();
		_G["CEPGP_distribute_item_name"]:SetText(link);
		_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString, name) end);
		_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() GameTooltip:SetOwner(_G["CEPGP_distribute_item_tex"], "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
		_G["CEPGP_distribute_item_texture"]:SetTexture(tex);
		_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
		_G["CEPGP_distribute_GP_value"]:SetText(gp);
	elseif GetLootMethod() == "master" then
		CEPGP_print("You are not the Loot Master.", 1);
		return;
	elseif GetLootMethod() ~= "master" then
		CEPGP_print("The loot method is not Master Looter", 1);
	end
end

function CEPGP_announceFromBag()
	
end