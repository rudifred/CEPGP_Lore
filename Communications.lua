local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP");
--local Comm = LibStub("AceAddon-3.0"):NewAddon("CEPGP", "AceComm-3.0");

--[[function Comm:OnInitialize()
	Comm:RegisterComm("CEPGP", CEPGP_IncAddonMsg);
end]]

function CEPGP_IncAddonMsg(message, channel, sender)
	if sender ~= UnitName("player") then
		table.insert(CEPGP_Info.Logs, {time(), "received", sender, UnitName("player"), message, channel});	--	os.time, time since pc turned on (useful for millisecond precision)
		if #CEPGP_Info.Logs >= 501 then
			table.remove(CEPGP_Info.Logs, 1);
		end
	end
	local args = CEPGP_split(message, ";"); -- The broken down message, delimited by semi-colons
	if sender == UnitName("player") then
		for i = 1, #CEPGP_Info.MessageStack do
			if CEPGP_Info.MessageStack[i][1] == message then
				local message, channel, player = CEPGP_Info.MessageStack[i][1], CEPGP_Info.MessageStack[i][2], CEPGP_Info.MessageStack[i][3];
				table.insert(CEPGP_Info.Logs, {time(), "sent", UnitName("player"), player, message, channel});
				if #CEPGP_Info.Logs >= 501 then
					table.remove(CEPGP_Info.Logs, 1);
				end
				CEPGP_Info.MessageStack[i][5] = true;
			end
		end
	end
	
	if args[1] == "table" then
		return;
	end
	
	if args[1] == "Import" then
		local option = args[2];
		
		if not CEPGP[option] then return; end
		
		table.insert(CEPGP_Info.Import.List, option);
		return;
	end
	
	if args[1] == "ImportStart" then
		CEPGP_settings_import_confirm:Disable();
		if not CEPGP_Info.Import.Running and CEPGP_Info.Import.Source == "" then
			CEPGP_Info.Import.Source = sender;
		end
		CEPGP_Info.Import.Running = true;
		return;
	end
	
	if args[1] == "ImportEnd" then
		CEPGP_ExportConfig(sender);
		return;
	end
	
	if args[1] == "SyncStart" then
		if sender == UnitName("player") then return; end
		if not CEPGP_Info.Guild.Roster[sender] then return; end
		if not CEPGP.Sync[1] then return; end
		
		local rank = CEPGP_Info.Guild.Roster[sender][4];
		
		if not CEPGP.Sync[2][rank] then --Index obtained by GetGuildRosterInfo starts at 0 whereas GuildControlGetRankName starts at 1 for some reason
			return;
		end
		
		if not CEPGP_Info.Import.Running and CEPGP_Info.Import.Source == "" then
			CEPGP_Info.Import.Source = sender;
		end
		CEPGP_Info.Import.Running = true;
		
		CEPGP.Alt.Links = {};
		if CEPGP_options_alt_mangement:IsVisible() then
			CEPGP_UpdateAltScrollBar();
		end
		
		CEPGP.Overrides = {};
		if CEPGP_override:IsVisible() then
			CEPGP_UpdateOverrideScrollBar();
		end
		
		CEPGP.Standby.Roster = {};
		if CEPGP_standby_options:IsVisible() then
			CEPGP_UpdateStandbyScrollBar();
		end
		
		CEPGP_settings_import_confirm:Disable();
		CEPGP_print(sender .. " is updating your CEPGP configuration");
		return;
	end
	
	if args[1] == "ExportConfig" then
		if not CEPGP_Info.Guild.Roster[sender] then return; end
		if not CEPGP_Info.Import.Running then
			if not CEPGP.Sync[1] then return; end
			local rank = CEPGP_Info.Guild.Roster[sender][4];
			if not CEPGP.Sync[2][rank] then return; end
		end
		CEPGP_OverwriteOption(args, sender, channel);
		return;
	end
	
	if args[1] == "CEPGP_setDistID" then
		CEPGP_Info.Loot.DistributionID = args[2];
		local name, link, _, _, _, _, _, _, slot, tex = GetItemInfo(CEPGP_Info.Loot.DistributionID);
		CEPGP_Info.Loot.DistEquipSlot = slot;
		
		local function setDistInfo()
			_G["CEPGP_distribute_item_name"]:SetText(link);
			_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function()
				GameTooltip:SetOwner(_G["CEPGP_distribute_item_tex"], "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(link)
				GameTooltip:Show()
			end);
			_G["CEPGP_distribute_item_texture"]:SetTexture(tex);
			_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(link) end);
			_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
			_G["CEPGP_distribute_GP_value"]:SetText(gp);	
		end
		
		if not name and CEPGP_itemExists(CEPGP_Info.Loot.DistributionID) then
			local item = Item:CreateFromItemID(tonumber(CEPGP_Info.Loot.DistributionID));
			item:ContinueOnItemLoad(function()
				name, link, _, _, _, _, _, _, slot, tex = GetItemInfo(CEPGP_Info.Loot.DistributionID);	
				setDistInfo();
			end);
		else
			setDistInfo();
		end
		CEPGP_UpdateLootScrollBar();
		return;
		
	elseif args[1] == "CEPGP_setLootGUID" and sender ~= UnitName("player") then
		CEPGP_Info.Loot.GUID = args[2];
		return;
	
	elseif args[1] == UnitName("player") and args[2] == "distslot" then
		--Recipient should see this
		local slot = args[3];
		if slot then --string.len(slot) > 0 and slot ~= nil then
			local slotName = string.sub(slot, 9);
			local slotid, slotid2 = CEPGP_SlotNameToID(slotName);
			local currentItem;
			local currentItem2;
			local itemID;
			local itemID2;
			
			if slotid then
				currentItem = GetInventoryItemLink("player", slotid);
			end
			if slotid2 then
				currentItem2 = GetInventoryItemLink("player", slotid2);
			end
			
			if currentItem then
				itemID = CEPGP_getItemID(CEPGP_getItemString(currentItem));
			else
				itemID = "noitem";
			end
			
			if currentItem2 then
				itemID2 = CEPGP_getItemID(CEPGP_getItemString(currentItem2));
			else
				itemID2 = "noitem";
			end
			
			if itemID2 then
				CEPGP_addAddonMsg(sender..";receiving;"..itemID..";"..itemID2, "WHISPER", sender);
			else
				CEPGP_addAddonMsg(sender..";receiving;"..itemID, "WHISPER", sender);
			end
			
		elseif slot == "" then
			CEPGP_addAddonMsg(sender..";receiving;noslot", "WHISPER", sender);
		elseif itemID == "noitem" then
			CEPGP_addAddonMsg(sender..";receiving;noitem", "WHISPER", sender);
		end
		return;
		
		
	elseif args[2] == "receiving" then
		local itemID = args[3];
		local itemID2 = args[4];
		local response, roll;
		if CEPGP_Info.Loot.ItemsTable[sender] then
			response = CEPGP_Info.Loot.ItemsTable[sender][3];
			roll = CEPGP_Info.Loot.ItemsTable[sender][4];
		end
		if not response and not CEPGP.Loot.ShowPass then return; end
		CEPGP_Info.Loot.ItemsTable[sender] = {};
		CEPGP_Info.Loot.ItemsTable[sender] = {
			[1] = itemID,
			[2] = itemID2,
			[3] = response,
			[4] = tonumber(roll)
		};
		CEPGP_UpdateLootScrollBar(true);
		return;
	end
	
	if args[1] == UnitName("player") and args[2] == "versioncheck" then
		local version = args[3];
		CEPGP_Info.Version.List = CEPGP_Info.Version.List or {};
		CEPGP_Info.Version.List[sender] = CEPGP_Info.Version.List[sender] or {};
		CEPGP_Info.Version.List[sender][1] = version;
		if CEPGP_Info.Guild.Roster[sender] then
			CEPGP_Info.Version.List[sender][2] = CEPGP_Info.Guild.Roster[sender][2]; -- Class
			CEPGP_Info.Version.List[sender][3] = CEPGP_Info.Guild.Roster[sender][7]; -- ClassFileName
		else
			for x = 1, GetNumGroupMembers() do
				local name = GetRaidRosterInfo(x);
				if GetRaidRosterInfo(x) == sender then
					_, _, _, _, CEPGP_Info.Version.List[name][2], CEPGP_Info.Version.List[name][3] = GetRaidRosterInfo(x);	--	Class, ClassFileName
					break;
				end
			end
		end
		CEPGP_checkVersion(message);
		if CEPGP_version:IsVisible() then
			CEPGP_UpdateVersionScrollBar();
		end
		return;
		
		
	elseif message == "version-check" then
		if not sender then return; end
		CEPGP_addAddonMsg(sender .. ";versioncheck;" .. CEPGP_Info.Version.Number .. "." .. CEPGP_Info.Version.Build, "WHISPER", sender);
		return;
	end
		
		
	if strfind(message, "RaidAssistLoot") and sender ~= UnitName("player")	then
		for i = 1, GetNumGroupMembers() do
			local name = GetRaidRosterInfo(i);
			if name == sender then
				if not CEPGP_Info.Raid.Roster[i][9] then return; end
			end
		end
		if args[1] == "RaidAssistLootDist" then
			local link, GP = args[2], args[3];
			if args[4] == "true" then
				CEPGP_RaidAssistLootDist(args[2], args[3], true);
			else
				CEPGP_RaidAssistLootDist(args[2], args[3], false);
			end
		else
			CEPGP_RaidAssistLootClosed();
		end
		return;
		
	
	elseif args[1] == "Acknowledge" then
		local response = tonumber(args[3]);
		if CEPGP.Loot.Acknowledge then
			if response == 6 then
				CEPGP_print("You have passed on this item");
			else
				CEPGP_print("You have responded with " .. CEPGP_Info.LootSchema[response]);
			end
		end
		CEPGP_respond:Hide();
		return;
	
	elseif args[1] == "!need" then
		local player = args[2];
		local response = tonumber(args[4]) or CEPGP_getResponse(args[4]) or CEPGP_getResponseIndex(args[4]) or CEPGP_indexToLabel(args[4]);
		local roll = args[5];
		if sender ~= UnitName("player") then
			CEPGP_Info.Loot.ItemsTable[player] = {};
			CEPGP_Info.Loot.ItemsTable[player][3] = response;
			if roll then
				CEPGP_Info.Loot.ItemsTable[player][4] = tonumber(roll);
			end
			CEPGP_UpdateLootScrollBar(sort);
		end
		CEPGP_distribute_responses_received:SetText(CEPGP_ntgetn(CEPGP_Info.Loot.ItemsTable) .. " of " .. CEPGP_Info.Loot.NumOnline .. " Responses Received");
		return;
		
	elseif args[1] == "LootClosed" then
		_G["CEPGP_distribute"]:Hide();		
		_G["CEPGP_button_loot_dist"]:Hide();
		_G["CEPGP_respond"]:Hide();
		return;
		
	elseif args[1] == "CEPGP.Standby.Enabled" and args[2] == UnitName("player") then
		CEPGP_print(args[3]);
		return;
		
	elseif args[1] == "StandbyListAdd" and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and sender ~= UnitName("player") then
		for _, t in pairs(CEPGP.Standby.Roster) do -- Is the player already in the standby roster?
			if t[1] == args[2] then
				return;
			end
		end
		for _, v in ipairs(CEPGP_Info.Raid.Roster) do -- Is the player part of your raid group?
			if args[2] == v[1] then
				return;
			end
		end
		if not CEPGP_Info.Guild.Roster[args[2]] then -- Player might not be part of your guild. This could happen if you're pugging with another guild and they use CEPGP
			return;
		end
		local player, class, rank, rankIndex, EP, GP, classFile = args[2], args[3], args[4], args[5], args[6], args[7], args[8];
		CEPGP.Standby.Roster[#CEPGP.Standby.Roster+1] = {
			[1] = player,
			[2] = class,
			[3] = rank,
			[4] = rankIndex,
			[5] = EP,
			[6] = GP,
			[7] = math.floor((tonumber(EP)*100/tonumber(GP)))/100,
			[8] = classFile
		};
		CEPGP_print(player.." added to standby list.");
		if CEPGP_standby_options:IsVisible() then
			CEPGP_UpdateStandbyScrollBar();
		end
		return;
		
	elseif args[1] == "StandbyListRemove" and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and sender ~= UnitName("player") then
		for i, v in ipairs(CEPGP.Standby.Roster) do
			if v[1] == args[2] then
				table.remove(CEPGP.Standby.Roster, i);
			end
			break;
		end
		return;
	
	elseif (args[1] == "StandbyRemoved" or args[1] == "StandbyAdded") and args[2] == UnitName("player") then
		CEPGP_print(args[3]);	
		return;
		
	elseif args[1] == "!info" and args[2] == UnitName("player") then--strfind(message, "!info"..UnitName("player")) then
		CEPGP_print(args[3]);
		return;
		
	elseif args[1] == "lootschema" then
		for i = 2, #args, 2 do
			CEPGP_Info.LootSchema[tonumber(args[i])] = args[i+1];
		end		
		return;
	
	elseif args[1] == "CallItem" and sender ~= UnitName("player") then
		local id = args[2];
		local gp = args[3];
		local buttons = {args[4], args[5], args[6], args[7]};
		local timeout = args[8];
		local GUID = args[9];
		CEPGP_Info.Loot.Master = sender;
		CEPGP_callItem(id, gp, buttons, timeout);
		if GUID then
			CEPGP_Info.Loot.GUID = GUID;
		end
		return;
		
	elseif strfind(message, "MainSpec") or args[1] == "LootRsp" then
		local response = args[2];
		local GUID = args[3] or "";
		CEPGP_handleComms("CHAT_MSG_WHISPER", nil, sender, response, GUID);
		return;
	
	elseif args[1] == "CEPGP_TRAFFICSyncStart" and sender ~= UnitName("player") then
		CEPGP_Info.Traffic.Sharing = true;
		CEPGP_traffic_share:Disable();
		if not CEPGP_Info.Traffic.Sharing or CEPGP_Info.Traffic.Source == "" then	--	Protects against one player sharing and then another forcefully sharing (via reloading / script)
			CEPGP_Info.Traffic.Source = sender;
		end
		CEPGP_print(sender .. " is sharing their traffic log with you. This process will start in 10 seconds");
		CEPGP_traffic_share_status:SetText("Preparing to receive traffic entries");
		CEPGP_Info.Traffic.ImportEntries = {};
		return;
	
	elseif args[1] == "CEPGP_TRAFFICSyncStop" and sender ~= UnitName("player") and CEPGP_Info.Traffic.Sharing then
		local success, failMsg = pcall(function()
		
			local function cleanup()
				CEPGP_Info.Traffic.Sharing = false;
				CEPGP_Info.Traffic.Source = "";
				CEPGP_traffic_share_status:SetText("Finished processing traffic entries");
				CEPGP_print("Traffic import has completed");
				CEPGP_traffic_share:Enable();
				CEPGP_UpdateTrafficScrollBar();
				CEPGP_Info.Traffic.ImportEntries = {};
			end
			
			CEPGP_print(#CEPGP_Info.Traffic.ImportEntries .. " Traffic Entries Received. Processing..");
			local sigs = {}; 	--	signatures
			for _, v in ipairs(CEPGP.Traffic) do
				if v[9] and v[10] and v[11] then
					if not sigs[v[10]] then
						sigs[v[10]] = {[1] = v[11]};
					else
						table.insert(sigs[v[10]], v[11]);
					end
				end
			end
			local limit = #CEPGP_Info.Traffic.ImportEntries;
			local logs = CEPGP_Info.Traffic.ImportEntries;
			local count = 1;
			local index;
			local ticker;
			ticker = C_Timer.NewTicker(0.1, function()
				local entry = logs[count];
				local newEntry = {};
				local tStamp = tonumber(entry[9]);
				local id = tonumber(entry[10]);
				local GUID = entry[11];
				
				if sigs[entry[10]] then
					for k, v in ipairs(sigs[entry[10]]) do
						if v == GUID then
							count = count + 1;
							CEPGP_traffic_share_status:SetText("Processed " .. count .. " of " .. limit .. " entries");
							if count >= limit then
								ticker._remainingIterations = 1;
								cleanup();
							else
								ticker._remainingIterations = 2;
							end
							return;
						end
					end
				end
				
				for i = #CEPGP.Traffic, 1, -1 do
					if CEPGP.Traffic[i][9] and CEPGP.Traffic[i][10] and CEPGP.Traffic[i][11] then
						if i > 1 then
							if CEPGP.Traffic[i-1][9] then
								if tStamp < tonumber(CEPGP.Traffic[i][9]) and tStamp > tonumber(CEPGP.Traffic[i-1][9]) then
									index = i;
									break;
								elseif tStamp > tonumber(CEPGP.Traffic[i][9]) then
									index = i+1;
									break;
								end
							else
								if tStamp > tonumber(CEPGP.Traffic[i][9]) then
									index = i;
									break;
								end
							end
						else
							if tStamp < tonumber(CEPGP.Traffic[i][9]) then
								index = 1;
								break;
							end
						end
					end
				end
				
				local player = entry[1];
				local issuer = entry[2];
				local action = entry[3];
				local EPB = entry[4];
				local EPA = entry[5];
				local GPB = entry[6];
				local GPA = entry[7];
				local itemID = tonumber(entry[8]);
				
				if CEPGP_itemExists(tonumber(itemID)) then
					local itemLink = CEPGP_getItemLink(itemID);
					if not itemLink then
						local item = Item:CreateFromItemID(tonumber(itemID));
						item:ContinueOnItemLoad(function()
							itemLink = CEPGP_getItemLink(itemID);
							newEntry = {
								[1] = player,
								[2] = issuer,
								[3] = action,
								[4] = EPB,
								[5] = EPA,
								[6] = GPB,
								[7] = GPA,
								[8] = itemLink,
								[9] = tStamp,
								[10] = id,
								[11] = GUID
							};
							if not index and #CEPGP.Traffic == 0 then
								table.insert(CEPGP.Traffic, 1, newEntry);
								if not sigs[newEntry[10]] then
									sigs[newEntry[10]] = {[1] = newEntry[11]};
								else
									table.insert(sigs[10], newEntry[11]);
								end
							elseif index then
								table.insert(CEPGP.Traffic, index, newEntry);
								if not sigs[newEntry[10]] then
									sigs[newEntry[10]] = {[1] = newEntry[11]};
								else
									table.insert(sigs[10], newEntry[11]);
								end
							end
						end);
					elseif itemLink then
						newEntry = {
							[1] = player,
							[2] = issuer,
							[3] = action,
							[4] = EPB,
							[5] = EPA,
							[6] = GPB,
							[7] = GPA,
							[8] = itemLink,
							[9] = tStamp,
							[10] = id,
							[11] = GUID
						};
						if not index and #CEPGP.Traffic == 0 then
							table.insert(CEPGP.Traffic, 1, newEntry);
							if not sigs[newEntry[10]] then
								sigs[newEntry[10]] = {[1] = newEntry[11]};
							else
								table.insert(sigs[10], newEntry[11]);
							end
						elseif index then
							table.insert(CEPGP.Traffic, index, newEntry);
							if not sigs[newEntry[10]] then
								sigs[newEntry[10]] = {[1] = newEntry[11]};
							else
								table.insert(sigs[10], newEntry[11]);
							end
						end
					end
				else
					newEntry = {
						[1] = player,
						[2] = issuer,
						[3] = action,
						[4] = EPB,
						[5] = EPA,
						[6] = GPB,
						[7] = GPA,
						[8] = "",
						[9] = tStamp,
						[10] = id,
						[11] = GUID
					};
					if not index and #CEPGP.Traffic == 0 then
						table.insert(CEPGP.Traffic, 1, newEntry);
						if not sigs[newEntry[10]] then
							sigs[newEntry[10]] = {[1] = newEntry[11]};
						else
							table.insert(sigs[10], newEntry[11]);
						end
					elseif index then
						table.insert(CEPGP.Traffic, index, newEntry);
						if not sigs[newEntry[10]] then
							sigs[newEntry[10]] = {[1] = newEntry[11]};
						else
							table.insert(sigs[10], newEntry[11]);
						end
					end
				end
				
				CEPGP_traffic_share_status:SetText("Processed " .. count .. " of " .. limit .. " entries");
				if count >= limit then
					cleanup();
					ticker._remainingIterations = 1;
					return;
				end
				
				ticker._remainingIterations = 2;
				
				count = count + 1;
			end, 2);
		end);
		
		if not success then
			CEPGP_print("Failed to process imported traffic entries", true);
			CEPGP_print(failMsg);
		end
		return;
	
	elseif args[1] == "CEPGP_TRAFFIC" and sender ~= UnitName("player") then
		local success, failMsg = pcall(function()
			local player = args[2];
			local issuer = args[3];
			local action = args[4];
			local EPB = args[5];
			local EPA = args[6];
			local GPB = args[7];
			local GPA = args[8];
			local itemID = tonumber(args[9]);
			local tStamp = tonumber(args[10]);
			local id = tonumber(args[11]);
			local GUID = args[12];
			
			local index;
			local entry = {};
			
			if tonumber(id) <= tStamp then return; end	--	Protects against malformed entries. Some have been seen where tStamp is on 9 and 10, invalidating the ID
			
			if not CEPGP_Info.Traffic.Sharing or sender ~= CEPGP_Info.Traffic.Source then	--	If only one log is sent (as opposed to share all entries) OR if a player is sending a new entry, such as a boss kill
				for i = #CEPGP.Traffic, 1, -1 do
					if CEPGP.Traffic[i][10] and CEPGP.Traffic[i][11] then
						if CEPGP.Traffic[i][10] == id and CEPGP.Traffic[i][11] == GUID then return; end
						if i > 1 then
							if CEPGP.Traffic[i-1][9] then
								if tStamp < tonumber(CEPGP.Traffic[i][9]) and tStamp > tonumber(CEPGP.Traffic[i-1][9]) then
									index = i;
									break;
								elseif tStamp > tonumber(CEPGP.Traffic[i][9]) then
									index = i+1;
									break;
								end
							else
								if tStamp > tonumber(CEPGP.Traffic[i][9]) then
									index = i;
									break;
								end
							end
						else
							if tStamp < tonumber(CEPGP.Traffic[i][9]) then
								index = 1;
								break;
							end
						end
					end
				end
			end
			
			if not index then index = #CEPGP.Traffic > 0 and #CEPGP.Traffic or 1; end
			
			if itemID == "" then itemID = 0; end
			
			entry = {
				[1] = player,
				[2] = issuer,
				[3] = action,
				[4] = EPB,
				[5] = EPA,
				[6] = GPB,
				[7] = GPA,
				[8] = itemID,
				[9] = tStamp,
				[10] = id,
				[11] = GUID
			};
			
			if not CEPGP_Info.Traffic.Sharing or sender ~= CEPGP_Info.Traffic.Source then
				if CEPGP_itemExists(tonumber(itemID)) then
					local itemLink = CEPGP_getItemLink(itemID);
					if not itemLink then
						local item = Item:CreateFromItemID(tonumber(itemID));
						item:ContinueOnItemLoad(function()
							itemLink = CEPGP_getItemLink(itemID);
							entry = {
								[1] = player,
								[2] = issuer,
								[3] = action,
								[4] = EPB,
								[5] = EPA,
								[6] = GPB,
								[7] = GPA,
								[8] = itemLink,
								[9] = tStamp,
								[10] = id,
								[11] = GUID
							};
							table.insert(CEPGP.Traffic, index, entry);
							CEPGP_UpdateTrafficScrollBar();
						end);
					elseif itemLink then
						entry = {
							[1] = player,
							[2] = issuer,
							[3] = action,
							[4] = EPB,
							[5] = EPA,
							[6] = GPB,
							[7] = GPA,
							[8] = itemLink,
							[9] = tStamp,
							[10] = id,
							[11] = GUID
						};
						table.insert(CEPGP.Traffic, index, entry);
						CEPGP_UpdateTrafficScrollBar();
					end
				else
					entry = {
						[1] = player,
						[2] = issuer,
						[3] = action,
						[4] = EPB,
						[5] = EPA,
						[6] = GPB,
						[7] = GPA,
						[8] = "",
						[9] = tStamp,
						[10] = id,
						[11] = GUID
					};
					table.insert(CEPGP.Traffic, index, entry);
					CEPGP_UpdateTrafficScrollBar();
				end
			end
			
			if CEPGP_Info.Traffic.Sharing and tStamp and id and GUID then
				table.insert(CEPGP_Info.Traffic.ImportEntries, entry);
				CEPGP_traffic_share_status:SetText(#CEPGP_Info.Traffic.ImportEntries .. " entries received");
			end
		end);
		
		if not success then
			CEPGP_print("Failed to import traffic entry from " .. sender, true);
			CEPGP_print(failMsg);
		end
		return;
	end
end

function CEPGP_ExportConfig(player)
	local completed = 0;
	
	local success, failMsg = pcall(function()
		--for index, _option in ipairs(CEPGP_Info.Import.List) do
		local channel = (player and "WHISPER" or "GUILD");
		local _option, option, field;
		_option = CEPGP_Info.Import.List[1];
		if string.find(_option, ".") then
			local args = CEPGP_split(_option, ".");
			option = args[1];
			field = args[2];
		end
		

		if option == "Overrides" then
			if CEPGP_ntgetn(CEPGP.Overrides) > 0 then
			
				local Overrides = {};
				
				for link, gp in pairs(CEPGP.Overrides) do
					table.insert(Overrides, {link, gp});
				end
				
				local limit = CEPGP_ntgetn(Overrides);
				for i = 1, limit do
					CEPGP_addAddonMsg("ExportConfig;Overrides;" .. Overrides[i][1] .. ";" .. Overrides[i][2], channel, player);
				end
				CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
				completed = completed + 1;
				--local i = 1;
				--C_Timer.NewTicker(0.1, function()
					
					--if i >= limit then
						
					--end
					--i = i + 1;
				--end, limit);		
			end
			
		elseif option == "Alt" then
			for key, state in pairs(CEPGP.Alt) do
				if key == "Links" then
					for main, alts in pairs(state) do
						for i = 1, #alts do
							CEPGP_addAddonMsg("ExportConfig;Alt;" .. key .. ";" .. main .. ";" .. alts[i], channel, player);
						end
					end
				else
					CEPGP_addAddonMsg("ExportConfig;Alt;" .. key .. ";" .. (state and "true" or "false"), channel, player);
				end
			end
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		
		elseif option == "Decay" then
			CEPGP_addAddonMsg("ExportConfig;Decay;Separate;" .. (CEPGP.Decay.Separate and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		
		elseif option == "EP" then
			local bossEP = {};
			for boss, EP in pairs(CEPGP.EP.BossEP) do
				table.insert(bossEP, boss);
			end
			
			--local limit = #bossEP;
			--local i = 1;
			--C_Timer.NewTicker(0.1, function()
				--if i >= limit then
				--end
				--i = i + 1;
			--end, limit);
			for i = 1, #bossEP do
				CEPGP_addAddonMsg("ExportConfig;EP;BossEP;" .. bossEP[i] .. ";" .. CEPGP.EP.BossEP[bossEP[i]], channel, player);
				CEPGP_addAddonMsg("ExportConfig;EP;AutoAward;" .. bossEP[i] .. ";" .. (CEPGP.EP.AutoAward[bossEP[i]] and "true" or "false"), channel, player);
			end
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
			
		elseif option == "GP" then
			CEPGP_addAddonMsg("ExportConfig;GP;Base;" .. CEPGP.GP.Base, channel, player);
			CEPGP_addAddonMsg("ExportConfig;GP;DecayFactor;" .. (CEPGP.GP.DecayFactor and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;GP;Min;" .. CEPGP.GP.Min, channel, player);
			CEPGP_addAddonMsg("ExportConfig;GP;Mod;" .. CEPGP.GP.Mod, channel, player);
			CEPGP_addAddonMsg("ExportConfig;GP;Multiplier;" .. CEPGP.GP.Multiplier, channel, player);
			CEPGP_addAddonMsg("ExportConfig;GP;Tooltips;" .. (CEPGP.GP.Tooltips and "true" or "false"), channel, player);
			
			
			for raid, value in pairs(CEPGP.GP.RaidModifiers) do
				CEPGP_addAddonMsg("ExportConfig;GP;RaidModifiers;" .. raid .. ";" .. value, channel, player);
			end
			
			for slot, weight in pairs(CEPGP.GP.SlotWeights) do
				CEPGP_addAddonMsg("ExportConfig;GP;SlotWeights;" .. slot .. ";" .. weight, channel, player);
			end
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		
		elseif option == "Guild" then
			if field == "Exclusions" then
				for i = 1, 10 do
					local state = (CEPGP.Guild.Exclusions[i] and "true" or "false");
					CEPGP_addAddonMsg("ExportConfig;Guild;Exclusions;" .. i .. ";" .. state, channel, player);
				end
			
			elseif field == "Filter" then
				for i = 1, 10 do
					local state = (CEPGP.Guild.Filter[i] and "true" or "false");
					CEPGP_addAddonMsg("ExportConfig;Guild;Filter;" .. i .. ";" .. state, channel, player);
				end
			end
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		
		elseif option == "Loot" then
			CEPGP_addAddonMsg("ExportConfig;Loot;Announcement;" .. CEPGP.Loot.Announcement, channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;AutoPass;" .. (CEPGP.Loot.AutoPass and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;AutoShow;" .. (CEPGP.Loot.AutoShow and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;AutoSort;" .. (CEPGP.Loot.AutoSort and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;DelayResponses;" .. (CEPGP.Loot.DelayResponses and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;ExtraKeywords;Enabled;" .. (CEPGP.Loot.ExtraKeywords.Enabled and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;HideKeyphrases;" .. (CEPGP.Loot.HideKeyphrases and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;HighestRollIncludesPass;" .. (CEPGP.Loot.HighestRollIncludesPass and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;MinThreshold;" .. CEPGP.Loot.MinThreshold, channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;MinReq;" .. (CEPGP.Loot.MinReq[1] and "true" or "false") .. ";" .. CEPGP.Loot.MinReq[2], channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;PassRolls;" .. (CEPGP.Loot.PassRolls and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;PRDifference;" .. (CEPGP.Loot.PRDifference and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;PRWithDelay;" .. (CEPGP.Loot.PRWithDelay and "true" or "false"), channel, player);
			local visRanks = "";
			for i = 1, 10 do
				if i == 1 then
					visRanks = (CEPGP.Loot.RaidVisibility[3][i] and "true" or "false");
				else
					visRanks = visRanks .. ";" .. (CEPGP.Loot.RaidVisibility[3][i] and "true" or "false");
				end
				
			end
			CEPGP_addAddonMsg("ExportConfig;Loot;RaidVisibility;" .. (CEPGP.Loot.RaidVisibility[1] and "true" or "false") .. ";" .. (CEPGP.Loot.RaidVisibility[2] and "true" or "false") .. ";" .. visRanks, channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;RaidWarning;" .. (CEPGP.Loot.RaidWarning and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;ResolveRolls;" .. (CEPGP.Loot.ResolveRolls and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;RollAnnounce;" .. (CEPGP.Loot.RollAnnounce and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;RollWithDelay;" .. (CEPGP.Loot.RollWithDelay and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;ShowPass;" .. (CEPGP.Loot.ShowPass and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;SuppressResponses;" .. (CEPGP.Loot.SuppressResponses and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Loot;GUI;Timer;" .. CEPGP.Loot.GUI.Timer, channel, player);
			
			for index = 1, 4 do
				local data = CEPGP.Loot.GUI.Buttons[index];
				local enabled = data[1] and "true" or "false";
				local buttonText = data[2];
				local discount = data[3];
				local keyphrase = data[4];
				local msg = "ExportConfig;Loot;GUI;Buttons;" .. index .. ";" .. enabled .. ";" .. buttonText .. ";" .. discount .. ";" .. keyphrase;
				if #msg > 249 then
					msg = "ExportConfig;Loot;GUI;Buttons;" .. index;
				end
				CEPGP_addAddonMsg(msg, channel, player);
			end
			
			for label, data in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
				for keyword, discount in pairs(data) do
					CEPGP_addAddonMsg("ExportConfig;Loot;ExtraKeywords;Keywords;" .. label .. ";" .. keyword .. ";" .. discount, channel, player);
				end
			end
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
			
		
		elseif option == "Standby" then
			CEPGP_addAddonMsg("ExportConfig;Standby;AcceptWhispers;" .. (CEPGP.Standby.AcceptWhispers and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;ByRank;" .. (CEPGP.Standby.ByRank and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Enabled;" .. (CEPGP.Standby.Enabled and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Keyword;" .. CEPGP.Standby.Keyword, channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Manual;" .. (CEPGP.Standby.Manual and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Offline;" .. (CEPGP.Standby.Offline and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Percent;" .. CEPGP.Standby.Percent, channel, player);
			CEPGP_addAddonMsg("ExportConfig;Standby;Share;" .. (CEPGP.Standby.Share and "true" or "false"), channel, player);
			
			for index, state in ipairs(CEPGP.Standby.Ranks) do
				CEPGP_addAddonMsg("ExportConfig;Standby;Ranks;" .. index .. ";" .. (state and "true" or "false") .. ";", channel, player);
			end
			
			local roster = {};
			
			for index, data in ipairs(CEPGP.Standby.Roster) do
				table.insert(roster, data[1]);	--	Player name
			end
			
			if #roster > 0 then
				--local i = 1;
				--C_Timer.NewTicker(0.1, function()
					
					--if i >= #roster then
						
					--end
					--i = i + 1;
				--end, #roster);
				
				for i = 1, #roster do
					CEPGP_addAddonMsg("ExportConfig;Standby;Roster;" .. roster[i], channel, player);
				end
				CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
				completed = completed + 1;
			else
				CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
				completed = completed + 1;
			end
		
		elseif option == "Channel" then
			CEPGP_addAddonMsg("ExportConfig;Channel;" .. CEPGP.Channel, channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		
		elseif option == "LootChannel" then
			CEPGP_addAddonMsg("ExportConfig;LootChannel;" .. CEPGP.LootChannel, channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;" .. _option, channel, player);
			completed = completed + 1;
		end
		
		if #CEPGP_Info.Import.List > 1 then
			table.remove(CEPGP_Info.Import.List, 1);
			C_Timer.After(1, function() CEPGP_ExportConfig(player); end);
		else
			CEPGP_Info.Import.List = {};
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;End;", channel, player);
			CEPGP_print("Configuration sent successfully");
			CEPGP_Info.Import.Running = false;
			CEPGP_settings_import_confirm:Enable();
			CEPGP_interface_options_force_sync_button:Enable();
		end
		--count = count + 1;
	end);
	
	if not success then
		CEPGP_print("A problem was encountered while sending your configuration to " .. (player and player or "the Guild"), true);
		CEPGP_print(failMsg);
	end
end

function CEPGP_SyncConfig()
	
	local success, failMsg = pcall(function()
		local function complete()
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;End;", channel, player);
			CEPGP_print("Synchronisation completed successfully");
			CEPGP_Info.Import.Running = false;
			CEPGP_settings_import_confirm:Enable();
			CEPGP_interface_options_force_sync_button:Enable();
		end
		local channel = "GUILD";
		
		--[[	Alts	]]--
			
		for key, state in pairs(CEPGP.Alt) do
			if key == "Links" then
				for main, alts in pairs(state) do
					for i = 1, #alts do
						CEPGP_addAddonMsg("ExportConfig;Alt;" .. key .. ";" .. main .. ";" .. alts[i], channel, player);
					end
				end
			else
				CEPGP_addAddonMsg("ExportConfig;Alt;" .. key .. ";" .. (state and "true" or "false"), channel, player);
			end
		end
		CEPGP_addAddonMsg("ExportConfig;ImportComplete;Alt", channel, player);
		CEPGP_print("Successfully exported Alt configuration");
		
		--[[	Channels & Decay	]]--
		
		C_Timer.After(1, function()
		
			CEPGP_addAddonMsg("ExportConfig;Decay;Separate;" .. (CEPGP.Decay.Separate and "true" or "false"), channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;Decay", channel, player);
			CEPGP_addAddonMsg("ExportConfig;Channel;" .. CEPGP.Channel, channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;Channel", channel, player);
			CEPGP_addAddonMsg("ExportConfig;LootChannel;" .. CEPGP.LootChannel, channel, player);
			CEPGP_addAddonMsg("ExportConfig;ImportComplete;LootChannel", channel, player);
			
			CEPGP_print("Successfully exported Channel & Decay configuration");
			
			--[[	EP	]]--
			
			C_Timer.After(1, function()
				
				local bossEP = {};
				for boss, EP in pairs(CEPGP.EP.BossEP) do
					table.insert(bossEP, boss);
				end
				
				local limit = #bossEP;
				local i = 1;
				C_Timer.NewTicker(0.1, function()
					CEPGP_addAddonMsg("ExportConfig;EP;BossEP;" .. bossEP[i] .. ";" .. CEPGP.EP.BossEP[bossEP[i]], channel, player);
					CEPGP_addAddonMsg("ExportConfig;EP;AutoAward;" .. bossEP[i] .. ";" .. (CEPGP.EP.AutoAward[bossEP[i]] and "true" or "false"), channel, player);
					if i >= limit then
						CEPGP_addAddonMsg("ExportConfig;ImportComplete;EP", channel, player);
						
						CEPGP_print("Successfully exported EP configuration");
						
						--[[	GP	]]--
						
						C_Timer.After(2, function()
						
							CEPGP_addAddonMsg("ExportConfig;GP;Base;" .. CEPGP.GP.Base, channel, player);
							CEPGP_addAddonMsg("ExportConfig;GP;DecayFactor;" .. (CEPGP.GP.DecayFactor and "true" or "false"), channel, player);
							CEPGP_addAddonMsg("ExportConfig;GP;Min;" .. CEPGP.GP.Min, channel, player);
							CEPGP_addAddonMsg("ExportConfig;GP;Mod;" .. CEPGP.GP.Mod, channel, player);
							CEPGP_addAddonMsg("ExportConfig;GP;Multiplier;" .. CEPGP.GP.Multiplier, channel, player);
							CEPGP_addAddonMsg("ExportConfig;GP;Tooltips;" .. (CEPGP.GP.Tooltips and "true" or "false"), channel, player);
							
							
							for raid, value in pairs(CEPGP.GP.RaidModifiers) do
								CEPGP_addAddonMsg("ExportConfig;GP;RaidModifiers;" .. raid .. ";" .. value, channel, player);
							end
							
							for slot, weight in pairs(CEPGP.GP.SlotWeights) do
								CEPGP_addAddonMsg("ExportConfig;GP;SlotWeights;" .. slot .. ";" .. weight, channel, player);
							end
							CEPGP_addAddonMsg("ExportConfig;ImportComplete;GP", channel, player);
							
							CEPGP_print("Successfully exported GP configuration");
							
							--[[	Guild Exclusions & Filter	]]--
							
							C_Timer.After(2, function()
							
								for i = 1, 10 do
									local state = (CEPGP.Guild.Exclusions[i] and "true" or "false");
									CEPGP_addAddonMsg("ExportConfig;Guild;Exclusions;" .. i .. ";" .. state, channel, player);
								end
								CEPGP_addAddonMsg("ExportConfig;ImportComplete;Guild.Exclusions", channel, player);
								
								for i = 1, 10 do
									local state = (CEPGP.Guild.Filter[i] and "true" or "false");
									CEPGP_addAddonMsg("ExportConfig;Guild;Filter;" .. i .. ";" .. state, channel, player);
								end
								CEPGP_addAddonMsg("ExportConfig;ImportComplete;Guild.Filter", channel, player);
								
								CEPGP_print("Successfully exported Guild Exclusions & Filtering");
								
								--[[	Loot	]]--
								
								C_Timer.After(2, function()
								
									CEPGP_addAddonMsg("ExportConfig;Loot;Announcement;" .. CEPGP.Loot.Announcement, channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;AutoPass;" .. (CEPGP.Loot.AutoPass and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;AutoShow;" .. (CEPGP.Loot.AutoShow and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;AutoSort;" .. (CEPGP.Loot.AutoSort and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;DelayResponses;" .. (CEPGP.Loot.DelayResponses and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;ExtraKeywords;Enabled;" .. (CEPGP.Loot.ExtraKeywords.Enabled and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;HideKeyphrases;" .. (CEPGP.Loot.HideKeyphrases and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;HighestRollIncludesPass;" .. (CEPGP.Loot.HighestRollIncludesPass and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;MinThreshold;" .. CEPGP.Loot.MinThreshold, channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;MinReq;" .. (CEPGP.Loot.MinReq[1] and "true" or "false") .. ";" .. CEPGP.Loot.MinReq[2], channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;PassRolls;" .. (CEPGP.Loot.PassRolls and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;PRDifference;" .. (CEPGP.Loot.PRDifference and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;PRWithDelay;" .. (CEPGP.Loot.PRWithDelay and "true" or "false"), channel, player);
									local visRanks = "";
									for i = 1, 10 do
										if i == 1 then
											visRanks = (CEPGP.Loot.RaidVisibility[3][i] and "true" or "false");
										else
											visRanks = visRanks .. ";" .. (CEPGP.Loot.RaidVisibility[3][i] and "true" or "false");
										end
										
									end
									CEPGP_addAddonMsg("ExportConfig;Loot;RaidVisibility;" .. (CEPGP.Loot.RaidVisibility[1] and "true" or "false") .. ";" .. (CEPGP.Loot.RaidVisibility[2] and "true" or "false") .. ";" .. visRanks, channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;RaidWarning;" .. (CEPGP.Loot.RaidWarning and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;ResolveRolls;" .. (CEPGP.Loot.ResolveRolls and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;RollAnnounce;" .. (CEPGP.Loot.RollAnnounce and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;RollWithDelay;" .. (CEPGP.Loot.RollWithDelay and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;ShowPass;" .. (CEPGP.Loot.ShowPass and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;SuppressResponses;" .. (CEPGP.Loot.SuppressResponses and "true" or "false"), channel, player);
									CEPGP_addAddonMsg("ExportConfig;Loot;GUI;Timer;" .. CEPGP.Loot.GUI.Timer, channel, player);
									
									for index = 1, 4 do
										local data = CEPGP.Loot.GUI.Buttons[index];
										local enabled = data[1] and "true" or "false";
										local buttonText = data[2];
										local discount = data[3];
										local keyphrase = data[4];
										local msg = "ExportConfig;Loot;GUI;Buttons;" .. index .. ";" .. enabled .. ";" .. buttonText .. ";" .. discount .. ";" .. keyphrase;
										if #msg > 249 then
											msg = "ExportConfig;Loot;GUI;Buttons;" .. index;
										end
										CEPGP_addAddonMsg(msg, channel, player);
									end
									
									for label, data in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
										for keyword, discount in pairs(data) do
											CEPGP_addAddonMsg("ExportConfig;Loot;ExtraKeywords;Keywords;" .. label .. ";" .. keyword .. ";" .. discount, channel, player);
										end
									end
									CEPGP_addAddonMsg("ExportConfig;ImportComplete;Loot", channel, player);
									
									CEPGP_print("Successfully exported Loot configuration");
									
									--[[	Standby		]]--
									
									C_Timer.After(2, function()
										
										CEPGP_addAddonMsg("ExportConfig;Standby;AcceptWhispers;" .. (CEPGP.Standby.AcceptWhispers and "true" or "false"), channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;ByRank;" .. (CEPGP.Standby.ByRank and "true" or "false"), channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Enabled;" .. (CEPGP.Standby.Enabled and "true" or "false"), channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Keyword;" .. CEPGP.Standby.Keyword, channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Manual;" .. (CEPGP.Standby.Manual and "true" or "false"), channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Offline;" .. (CEPGP.Standby.Offline and "true" or "false"), channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Percent;" .. CEPGP.Standby.Percent, channel, player);
										CEPGP_addAddonMsg("ExportConfig;Standby;Share;" .. (CEPGP.Standby.Share and "true" or "false"), channel, player);
										
										for index, state in pairs(CEPGP.Standby.Ranks) do
											--	Using pairs instead of ipairs because indices may be nil when they initialise.
											--	Although this is not an invalid configuration, it will prevent ipairs from sending all of the information correctly
											if state then
												CEPGP_addAddonMsg("ExportConfig;Standby;Ranks;" .. index .. ";" .. (state and "true" or "false") .. ";", channel, player);
											end
										end
										
										CEPGP_addAddonMsg("ExportConfig;ImportComplete;Standby", channel, player);
										
										CEPGP_print("Successfully exported Standby configuration");
										
										--[[	Overrides	]]--
										
										C_Timer.After(2, function()
											if CEPGP_ntgetn(CEPGP.Overrides) > 0 then
												local Overrides = {};
												
												for link, gp in pairs(CEPGP.Overrides) do
													table.insert(Overrides, {link, gp});
												end
												
												local limit = CEPGP_ntgetn(Overrides);
												local i = 1;
												C_Timer.NewTicker(0.1, function()
													CEPGP_addAddonMsg("ExportConfig;Overrides;" .. Overrides[i][1] .. ";" .. Overrides[i][2], channel, player);
													if i >= limit then
														CEPGP_addAddonMsg("ExportConfig;ImportComplete;Overrides", channel, player);
														
														CEPGP_print("Successfully exported Overrides");
														complete();
													end
													i = i + 1;
												end, limit);
											else
												CEPGP_print("No Overrides to export.. proceeding with synchronisation");
												complete();
											end
											
										end);
										
									end);
								end);
							
							end);
						
						end);
					end
					i = i + 1;
				end, limit);
			end);
		end);			
	end);
	
	if not success then
		CEPGP_addAddonMsg("ExportConfig;!ERROR", "GUILD");
		CEPGP_print("A problem was encountered while sending your configuration to the Guild", true);
		CEPGP_print(failMsg);
		CEPGP_settings_import_confirm:Enable();
		CEPGP_settings_import_verbose_check:Enable();
		CEPGP_interface_options_force_sync_button:Enable();
		CEPGP_Info.Import.Running = false;
		CEPGP_Info.Import.Source = "";
	end
end

function CEPGP_OverwriteOption(args, sender, channel)
	if sender == UnitName("player") then return; end
	if sender ~= CEPGP_Info.Import.Source then return; end
	
	local success, failMsg = pcall(function()
		if channel == "GUILD" then
			if not CEPGP_Info.Guild.Roster[sender] then return; end
			local rank = CEPGP_Info.Guild.Roster[sender][4];
		
			if not CEPGP.Sync[2][rank] then
				return;
			end
		end
		
		local option = args[2];
		local setting = args[3];
		
		if option == "!ERROR" then
			CEPGP_print("Something went wrong while receiving " .. sender .. (string.sub(sender, #sender, #sender) == "s" and "'" or "'s") .. " configuration. The synchronisation has been cancelled.");
			CEPGP_settings_import_confirm:Enable();
			CEPGP_settings_import_verbose_check:Enable();
			CEPGP_interface_options_force_sync_button:Enable();
			CEPGP_Info.Import.Running = false;
			CEPGP_Info.Import.Source = "";
			return;
		end
		
		if option == "ImportComplete" then
			if setting == "End" then
				local i, limit = 1, 0;
				while _G["ImportCheckButton_" .. i] do
					limit = limit + 1;
					i = i + 1;
				end
				for i = 1, limit do
					local frame = _G["ImportCheckButton_" .. i];
					frame:Enable();
				end
				CEPGP_print("Import completed");
				CEPGP_settings_import_confirm:Enable();
				CEPGP_settings_import_verbose_check:Enable();
				CEPGP_interface_options_force_sync_button:Enable();
				CEPGP_Info.Import.Running = false;
				CEPGP_Info.Import.Source = "";
			else
				if CEPGP_Info.Import.Verbose then
					local map = {
						["Alt"] = 				"Alt Management Configuration",
						["Channel"] = 			"EPGP Modification Reporting Channel",
						["Decay"] = 			"Decay Configuration",
						["EP"] = 				"EP Management Configuration",
						["Guild.Exclusions"] =	"Guild Rank Exclusions",
						["Guild.Filter"] =		"Guild Rank Filters",
						["GP"] = 				"GP Management Configuration",
						["Loot"] = 				"Loot Management Configuration",
						["LootChannel"] = 		"Loot Response Reporting Channel",
						["Overrides"] = 		"GP Overrides",
						["Standby"] =			"Standby Configuration"
					}
					CEPGP_print("Successfully imported " .. map[setting]);
				end
			end
			return;
		end
		
		local function sanitise(value)
			if value == "true" then
				return true;
			elseif value == "false" then
				return false;
			elseif tonumber(value) then
				return tonumber(value);
			else
				return value;
			end
		end
		
		if option == "Overrides" then
			local item, GP = args[3], args[4];
			CEPGP.Overrides[item] = GP;	--	Will be updated to new saved var structure when the changeover happens
			if CEPGP_override:IsVisible() then
				CEPGP_UpdateOverrideScrollBar();
			end
		
		elseif option == "Alt" then
			if setting == "Links" then
				CEPGP.Alt.Links[args[4]] = CEPGP.Alt.Links[args[4]] or {};
				table.insert(CEPGP.Alt.Links[args[4]], args[5]);
				if CEPGP_options_alt_mangement:IsVisible() then
					CEPGP_UpdateAltScrollBar();
				end
			else
				CEPGP.Alt[setting] = sanitise(args[4]);
			end
			
		elseif option == "Decay" then
			CEPGP.Decay[setting] = sanitise(args[4]);
		
		elseif option == "EP" then
			local boss = args[4];
			local state = setting == "BossEP" and tonumber(args[5]) or (args[5] == "true" and true or false);
			if setting == "AutoAward" then
				CEPGP.EP.AutoAward[boss] = state;
				_G["CEPGP_options_" .. boss .. "_auto_check"]:SetChecked(state);
			else
				CEPGP.EP.BossEP[boss] = state;
				_G["CEPGP_options_" .. boss .. "_EP_value"]:SetText(state);
			end
			CEPGP.EP[setting][boss] = state;
			
		elseif option == "GP" then
			local index;
			local value;
			if type(CEPGP.GP[setting]) == "table" then
				index = args[4];
				value = args[5];
				CEPGP.GP[setting][index] = value;
				if setting == "SlotWeights" then
					CEPGP.GP.SlotWeights[index] = value;
				end
			else
				value = sanitise(args[4]);
				CEPGP.GP[setting] = value;
			end
		
		elseif option == "Guild" then
			if setting == "Exclusions" then
				local index = tonumber(args[4]);
				local state = (args[5] == "true" and true or false);
				CEPGP.Guild.Exclusions[index] = state;
								
			elseif setting == "Filter" then
				local index = tonumber(args[4]);
				local state = (args[5] == "true" and true or false);
				CEPGP.Guild.Filter[index] = state;
			end
			
			CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			
		elseif option == "Loot" then
			local value;
			if type(CEPGP.Loot[setting]) == "table" then
				if setting == "GUI" then
					if args[4] == "Buttons" then
						local index = sanitise(args[5]);
						local state = sanitise(args[6]);
						local text = sanitise(args[7]);
						local discount = sanitise(args[8]);
						local keyword = sanitise(args[9]);
						
						if text then					
							CEPGP.Loot.GUI.Buttons[index][1] = state;
							CEPGP.Loot.GUI.Buttons[index][2] = text;
							CEPGP.Loot.GUI.Buttons[index][3] = discount;
							CEPGP.Loot.GUI.Buttons[index][4] = keyword;
						else
							CEPGP_print("There was an issue importing data for response button " .. index .. ". You will need to configure this button manually.", true);
							return;
						end
						
					elseif args[4] == "Timer" then
						CEPGP.Loot.GUI.Timer = sanitise(args[5]);
					end
				
				elseif setting == "ExtraKeywords" then
					if args[4] == "Enabled" then
						CEPGP.Loot.ExtraKeywords.Enabled = sanitise(args[5]);
					else
						local label = sanitise(args[5]);
						local keyword = sanitise(args[6]);
						local discount = sanitise(args[7]);
						
						CEPGP.Loot.ExtraKeywords.Keywords[label] = {[keyword] = discount};
					end
					if CEPGP_loot_options:IsVisible() then
						CEPGP_UpdateKeywordScrollBar();
					end
				
				elseif setting == "MinReq" or setting == "RaidVisibility" then
					args[4] = sanitise(args[4]);
					args[5] = sanitise(args[5]);
					value = {args[4], args[5]};
					
					CEPGP.Loot[setting] = value;
					
					if setting == "RaidVisibility" and args[15] then
						CEPGP.Loot.RaidVisibility[3] = {};
						for x = 1, 10 do
							local state = sanitise(args[x+5]);
							CEPGP.Loot.RaidVisibility[3][x] = state;
						end
					end
				end
			else
				value = sanitise(args[4]);
				CEPGP.Loot[setting] = value;
			end
		
		elseif option == "Standby" then
			if setting == "Ranks" then
				local index = sanitise(args[4]);
				local state = sanitise(args[5]);
				
				if type(state) == "boolean" then	--	Required to accommodate for a massive screwup I made in previous versions where the structure didn't match
					CEPGP.Standby.Ranks[index] = state;
				end
			elseif setting == "Roster" then
				local player = sanitise(args[4]);
				CEPGP_addToStandby(player);
			else
				local value = sanitise(args[4]);
				CEPGP.Standby[setting] = value;
			end
		end
		CEPGP_refreshOptions();
	end);
end

function CEPGP_initMessageQueue()
	local length = 0; -- The number of characters sent in the last 1 second
	local period = 0; -- A counter to keep track of sending intervals
	local errorIndex;
	local processQueue;
	processQueue = function()
		if #CEPGP_Info.MessageStack > 0 then
			local lastSend = 0; -- Time since the last successful send
			for index, data in ipairs(CEPGP_Info.MessageStack) do
				errorIndex = index;
				local delete = data[5];
				if delete then
					table.remove(CEPGP_Info.MessageStack, index);
				else
					local tStamp = GetTime();
					local message, channel, player = data[1], data[2], data[3];
					table.insert(CEPGP_Info.Logs, {time(), "attempt", UnitName("player"), player, message, channel});
					if #CEPGP_Info.Logs >= 501 then
						table.remove(CEPGP_Info.Logs, 1);
					end
					if tStamp - period >= 1 then
						period = tStamp;
						length = 0;
					end
					if length + #message >= 750 and tStamp - lastSend < 1 then
						local delay = 1 - (tStamp - lastSend) + 0.25; -- 0.2 second margin added for safety
						C_Timer.After(delay, function() processQueue(); end);
						return;
					else
						local lastAttempt = data[4]; -- Last time a certain message attempted to send. Prevents messages from reattempting too soon
						if tStamp - lastAttempt > 0.5 then
							CEPGP_Info.MessageStack[index][4] = tStamp;
							lastSend = tStamp;
							length = length + #message;
							CEPGP_SendAddonMsg({message, channel, player});
							if channel == "WHISPER" then
								CEPGP_Info.MessageStack[index][5] = true;
								table.insert(CEPGP_Info.Logs, {time(), "whisper", UnitName("player"), player, message, channel});
								if #CEPGP_Info.Logs >= 501 then
									table.remove(CEPGP_Info.Logs, 1);
								end
							end
						end
					end
				end
			end
			C_Timer.After(0.25, function() processQueue() end);
		else
			C_Timer.After(0.25, function() processQueue(); end);
		end
	end
	
	processQueue();
	
end

function CEPGP_addAddonMsg(message, channel, player)
	table.insert(CEPGP_Info.MessageStack, {message, channel, player, 0, false});
	table.insert(CEPGP_Info.Logs, {time(), "queued", UnitName("player"), player, message, channel});
	if #CEPGP_Info.Logs >= 501 then
		table.remove(CEPGP_Info.Logs, 1);
	end
end

function CEPGP_SendAddonMsg(stackItem)
	local status = "unsent";
	local message, channel, player = stackItem[1], stackItem[2], stackItem[3];
	
	--print(message, channel, player);
	local conditions = {
		["CallItem"] = function(id)
			return (id == CEPGP_Info.Loot.DistributionID and CEPGP_Info.Loot.Distributing);
		end,
		["LootClosed"] = function()
			return CEPGP_frame:IsVisible();
		end,
		["RaidAssistLootDist"] = function()
			return CEPGP_Info.Loot.Distributing;
		end,
		["RaidAssistLootClosed"] = function()
			return not CEPGP_Info.Loot.Distributing;
		end,
		["LootRsp"] = function(GUID)
			if #CEPGP_Info.Loot.GUID > 0 then
				return GUID == CEPGP_Info.Loot.GUID;
			elseif CEPGP_Info.Loot.GUID == "" then
				return true;
			else
				return false;
			end
		end,
		["CEPGP_setLootGUID"] = function(GUID)
			return GUID == CEPGP_Info.Loot.GUID;
		end,
		["Acknowledge"] = function(GUID)
			return GUID == CEPGP_Info.Loot.GUID;
		end
	}

	local args = CEPGP_split(message, ";");
	if conditions[args[1]] then
		local func = conditions[args[1]];
		if args[1] == "LootRsp" then args[2] = args[3]; end
		if not func(args[2]) then
			for i = 1, #CEPGP_Info.MessageStack do
				if CEPGP_Info.MessageStack[i][1] == message then
					CEPGP_Info.MessageStack[i][5] = true;
					table.insert(CEPGP_Info.Logs, {time(), "abandoned", UnitName("player"), player, message, channel});
					if #CEPGP_Info.Logs >= 501 then
						table.remove(CEPGP_Info.Logs, 1);
					end
					return;
				end
			end
		end
	end
	
	if channel == "GUILD" and IsInGuild() then
		--Comm:SendCommMessage("CEPGP", message, "GUILD", nil, "ALERT", AddToLog, message);
		C_ChatInfo.SendAddonMessage("CEPGP", message, "GUILD");
		
	elseif channel == "RAID" then
		if not UnitInBattleground("player") then
			--Comm:SendCommMessage("CEPGP", message, "RAID", nil, "ALERT", AddToLog, message);
			C_ChatInfo.SendAddonMessage("CEPGP", message, "RAID");
		else
			--Comm:SendCommMessage("CEPGP", message, "INSTANCE_CHAT", nil, "ALERT", AddToLog, message);
			C_ChatInfo.SendAddonMessage("CEPGP", message, "INSTANCE_CHAT");
		end
		
	elseif channel == "WHISPER" then
		if not player then return; end
		--Comm:SendCommMessage("CEPGP", message, "WHISPER", player, "ALERT", AddToLog, message);
		C_ChatInfo.SendAddonMessage("CEPGP", message, "WHISPER", player);
		
	elseif GetNumGroupMembers() > 0 and not IsInRaid() then --Player is in a party but not a raid
		--Comm:SendCommMessage("CEPGP", message, "PARTY", nil, "ALERT", AddToLog, message);
		C_ChatInfo.SendAddonMessage("CEPGP", message, "PARTY");
	elseif (channel == "RAID" or not channel) and IsInRaid() then --Player is in a raid group
		--Comm:SendCommMessage("CEPGP", message, "RAID", nil, "ALERT", AddToLog, message);
		C_ChatInfo.SendAddonMessage("CEPGP", message, "RAID");
	elseif IsInGuild() then --If channel is not specified then assume guild
		--Comm:SendCommMessage("CEPGP", message, "GUILD", nil, "ALERT", AddToLog, message);
		C_ChatInfo.SendAddonMessage("CEPGP", message, "GUILD");
	else	--None of the above conditions are met, such as not being in a guild and trying to request a version check. Ditch the message!
		for i = 1, #CEPGP_Info.MessageStack do
			if CEPGP_Info.MessageStack[i][1] == message then
				CEPGP_Info.MessageStack[i][5] = true;
				table.insert(CEPGP_Info.Logs, {time(), "abandoned", UnitName("player"), player, message, channel});
				if #CEPGP_Info.Logs >= 501 then
					table.remove(CEPGP_Info.Logs, 1);
				end
				return;
			end
		end
	end
	
	--[[local function AddToLog(msg, sent, total)
		if total - sent == 0 then
			table.insert(CEPGP_Info.Logs, {time(), "sent", UnitName("player"), player, msg, channel});
			if #CEPGP_Info.Logs > 500 then
				table.remove(CEPGP_Info.Logs, 1);
			end
		end
	end]]
end

function CEPGP_ShareTraffic(ID, GUID)
	if not ID or not GUILD then return; end
	
	local success, failMsg = pcall(function()
		local player, issuer, action, EPB, EPA, GPB, GPA, itemID, tStamp;
		for i = #CEPGP.Traffic, 1, -1 do
			if CEPGP.Traffic[i][10] == ID and CEPGP.Traffic[i][11] == GUID then
				player = CEPGP.Traffic[i][1];
				issuer = CEPGP.Traffic[i][2];
				action = CEPGP.Traffic[i][3];
				EPB = CEPGP.Traffic[i][4] or "";
				EPA = CEPGP.Traffic[i][5] or "";
				GPB = CEPGP.Traffic[i][6] or "";
				GPA = CEPGP.Traffic[i][7] or "";
				itemID = CEPGP_getItemID(CEPGP_getItemString(CEPGP.Traffic[i][8])) or "";
				tStamp = CEPGP.Traffic[i][9];
				break;
			end
		end
		
		local str = player .. ";" .. issuer .. ";" .. action .. ";" .. EPB .. ";" .. EPA .. ";" .. GPB .. ";" .. GPA .. ";" .. itemID .. ";" .. tStamp .. ";" .. ID .. ";" .. GUID;
		if #str > 249 then
			CEPGP_print("Could not share traffic entry with ID " .. ID .. " / GUID " .. GUID .. ". Character limit exceeded!", true);
			return;
		end
		
		CEPGP_addAddonMsg("CEPGP_TRAFFIC;" .. player .. ";" .. issuer .. ";" .. action .. ";" .. EPB .. ";" .. EPA .. ";" .. GPB .. ";" .. GPA .. ";" .. itemID .. ";" .. tStamp .. ";" .. ID .. ";" .. GUID, "GUILD");
	end);
	
	if not success then
		CEPGP_print("Error encountered while sharing traffic ID " .. ID .. " / GUID " .. GUID, true);
		CEPGP_print(failMsg);
	end
	
end

	--	group = party|raid|assists
	--	Ranks use their numerical representation!!	i.e. Guild master = 1, rank 2, rank 3 through to rank 10
	--	Combinations can be used - for example: group = "guild" and rank = 2, or group = "raid" and rank = 4
	--	group = "raid" and rank only applies for guild members ONLY
function CEPGP_messageGroup(msg, group, logged, _rank)
	local function MessageParty()
		if not IsInGroup() then
			return;
		end
		local names = {};
		for i = 1, GetNumGroupMembers() do
			local player = select(1, GetRaidRosterInfo(i));
			local online = select(8, GetRaidRosterInfo(i));
			local rank;
			if CEPGP_Info.Guild.Roster[player] then
				rank = CEPGP_Info.Guild.Roster[player][4];
			end
			if (_rank and rank) or not _rank then
				if (_rank and _rank == rank) or not _rank then
					if online and player ~= UnitName("player") then
						table.insert(names, player);
					end
				end
			end
		end
		local limit = #names;
		C_Timer.NewTicker(0.1, function()
			CEPGP_addAddonMsg(msg, "WHISPER", names[1], logged);
			table.remove(names, 1);
		end, limit);
	end
	
	local function MessageRaid()
		if not IsInRaid() then
			return;
		end
		local names = {};
		for i = 1, GetNumGroupMembers() do
			local player = select(1, GetRaidRosterInfo(i));
			local online = select(8, GetRaidRosterInfo(i));
			local rank;
			if CEPGP_Info.Guild.Roster[player] then
				rank = CEPGP_Info.Guild.Roster[player][4];
			end
			if (_rank and rank) or not _rank then
				if (_rank and _rank == rank) or not _rank then
					if online and player ~= UnitName("player") then
						table.insert(names, player);
					end
				end
			end
		end
		local limit = #names;
		C_Timer.NewTicker(0.1, function()
			CEPGP_addAddonMsg(msg, "WHISPER", names[1], logged);
			table.remove(names, 1);
		end, limit);
	end
	
	local function MessageAssists()
		if not IsInRaid() then
			return;
		end
		local names = {};
		for i = 1, GetNumGroupMembers() do
			--	rank : 1 = assist, 2  = leader
			local player, rank = GetRaidRosterInfo(i);
			local leader = (rank == 2);
			local assist = (rank == 1);
			local online = select(8, GetRaidRosterInfo(i));
			local rank;
			if CEPGP_Info.Guild.Roster[player] then
				rank = CEPGP_Info.Guild.Roster[player][4];
			end
			if (_rank and rank) or not _rank then
				if (player ~= UnitName("player") and (leader or assist) and ((_rank and _rank == rank) or not _rank)) and online then
					table.insert(names, player);
				end
			end
		end
		local limit = #names;
		C_Timer.NewTicker(0.1, function()
			CEPGP_addAddonMsg(msg, "WHISPER", names[1], logged);
			table.remove(names, 1);
		end, limit);
		--[[for _, name in ipairs(names) do
			CEPGP_addAddonMsg(msg, "WHISPER", name, logged);
		end]]
	end
		
	if group == "party" then
		MessageParty();
	
	elseif group == "raid" then
		MessageRaid();
		
	elseif group == "assists" then
		MessageAssists();
	end
end