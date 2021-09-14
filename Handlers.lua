local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP");

function CEPGP_handleComms(event, arg1, arg2, response, lootGUID)
	
	--	arg1 - message | arg2 - sender
	if arg1 then
		response = CEPGP_getLabelIndex(CEPGP_getResponse(arg1));
	end
	response = tonumber(response);
	--if not response then response = arg1; end
	if not response and (string.lower(arg1) ~= "!info" and string.lower(arg1) ~= "!infoclass" and string.lower(arg1) ~= "!infoguild" and string.lower(arg1) ~= "!inforaid") then
		response = arg1;
	end
	local reason = CEPGP.Loot.GUI.Buttons[response] and CEPGP.Loot.GUI.Buttons[response][2] or CEPGP_Info.LootSchema[response] or CEPGP_getResponse(CEPGP_getResponseIndex(response));

	if event == "CHAT_MSG_WHISPER" and response then
		local success, failMsg = pcall(function()
			if (lootGUID ~= CEPGP_Info.Loot.GUID and lootGUID ~= "") and not arg1 then return; end
			local roll = 0;
			local name = arg2;
			
			local function checkRoll(name)
				for k, v in pairs(CEPGP_Info.Loot.ItemsTable) do
					if k ~= name then
						if v[4] then
							if v[4] == roll then
								roll = math.ceil(math.random(1,100));
								checkRoll(name);
								return false;
							end
						end
					end
				end
				return true;
			end
			
			if (response == 6 and CEPGP.Loot.PassRolls) or response ~= 6 then
				roll = math.ceil(math.random(1,100));
				if CEPGP.Loot.ResolveRolls then
					checkRoll(name);
				end
			end
			
			if not CEPGP_Info.Loot.Distributing then return; end
			
			if CEPGP_Info.Loot.Expired and arg1 then
				CEPGP_addAddonMsg("msg;The time to respond for this item has expired. Responses are no longer being accepted!", "WHISPER", name, true);
				return;
			end
			
			if CEPGP_Info.Debug then
				if CEPGP_Info.Loot.ItemsTable[name] then
					CEPGP_print(name .. " changed their response");
				else
					CEPGP_print(name .. " registered");
				end
			end
			
			local EP, GP, PR = nil;
			local inGuild = false;
			if CEPGP_Info.Guild.Roster[name] then 
				local index = CEPGP_getIndex(name, CEPGP_Info.Guild.Roster[name][1]);
				EP, GP = CEPGP_getEPGP(name, index);
				PR = math.floor((EP/GP)*100)/100;
				class = CEPGP_Info.Guild.Roster[name][2];
				inGuild = true;
			end
			if CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or (CEPGP.Loot.ShowPass and response == 6) or response < 6 then
				CEPGP_addAddonMsg(name..";distslot;"..CEPGP_Info.Loot.DistEquipSlot, "WHISPER", name);
			end
			if not CEPGP.Loot.DelayResponses then
				if CEPGP_Info.Loot.ItemsTable[name] and CEPGP.Loot.Resubmit then
					if not CEPGP.Loot.SuppressResubmitResponses then
						CEPGP_sendChatMessage(name .. " changed their response to " .. reason .. " (" .. PR .. ")", "RAID");
					end
				elseif not CEPGP_Info.Loot.ItemsTable[name] then
					if inGuild and not CEPGP.Loot.SuppressResponses then
						if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) then
							if CEPGP.Loot.RollAnnounce then
								CEPGP_sendChatMessage(name .. " (" .. class .. ") needs (" .. reason .. "). (" .. PR .. " PR) (Rolled " .. roll .. ")", CEPGP.LootChannel);
							else
								CEPGP_sendChatMessage(name .. " (" .. class .. ") needs (" .. reason .. "). (" .. PR .. " PR)", CEPGP.LootChannel);
							end
						end
					elseif not CEPGP.Loot.SuppressResponses then
						local total = GetNumGroupMembers();
						for i = 1, total do
							if name == GetRaidRosterInfo(i) then
								_, _, _, _, class = GetRaidRosterInfo(i);
							end
						end
						if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) then
							if CEPGP.Loot.RollAnnounce then
								CEPGP_sendChatMessage(name .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member) (Rolled " .. roll .. ")", CEPGP.LootChannel);
							else
								CEPGP_sendChatMessage(name .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member)", CEPGP.LootChannel);
							end
						end
					end
				end
			end
			CEPGP_addResponse(name, response, roll);
			CEPGP_UpdateLootScrollBar(true);
		end);
		
		if not success then
			CEPGP_print("Error encountered while processing responses", true);
			CEPGP_print(failMsg);
		end
		
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "!info" then
		if CEPGP_getGuildInfo(arg2) ~= nil then
			local sender = arg2;
			local index = CEPGP_getIndex(sender);
			EP, GP = CEPGP_getEPGP(sender, index);
			if CEPGP_Info.Version.List[sender][1] == "Addon not enabled" then
				SendChatMessage("EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "WHISPER", CEPGP_Info.Language, arg2);
			else
				CEPGP_addAddonMsg("!info;" .. arg2 .. ";EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "GUILD");
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and (string.lower(arg1) == "!infoguild" or string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass") then
		if CEPGP_Info.Guild.Roster[arg2] then
			local target = arg2;
			local _, _, class, oNote, EP, GP;
			
			if string.lower(arg1) == "!infoguild" then	--	Need to show EP, GP, PR and PR position
				local roster = {};
				for name, v in pairs(CEPGP_Info.Guild.Roster) do
					local EP, GP = CEPGP_getEPGP(k, v[1]);
					local PR = math.floor((EP/GP)*100)/100;
					local entry = {
						[1] = name,
						[2] = v[1],	--index
						[3] = EP,
						[4] = GP,
						[5] = PR
					};
					
					table.insert(roster, entry);
				end
				
				roster = CEPGP_tSort(roster, 5, true);
				
				for index, data in ipairs(roster) do
					if data[1] == target then
						if CEPGP_Info.Version.List[target][1] == "Addon not enabled" then
							SendChatMessage("EP: " .. data[3] .. " / GP: " .. data[4] .. " / PR: " .. data[5] .. " / PR rank in Guild: #" .. index, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_addAddonMsg("!info;" .. target .. ";EP: " .. data[3] .. " / GP: " .. data[4] .. " / PR: " .. data[5] .. " / PR rank in Guild: #" .. index, "WHISPER", target);
						end
						break;
					end
				end
				
			elseif string.lower(arg1) == "!inforaid" then
				if not UnitInRaid("player") then return; end
			
				local roster = CEPGP_Info.Raid.Roster;
				
				roster = CEPGP_tSort(roster, 7, true);
				
				for index, data in ipairs(roster) do
					if data[1] == target then
						if CEPGP_Info.Version.List[target][1] == "Addon not enabled" then
							SendChatMessage("EP: " .. data[5] .. " / GP: " .. data[6] .. " / PR: " .. data[7] .. " / PR rank in Raid: #" .. index, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_addAddonMsg("!info;" .. target .. ";EP: " .. data[5] .. " / GP: " .. data[6] .. " / PR: " .. data[7] .. " / PR rank in Raid: #" .. index, "WHISPER", target);
						end
						break;
					end
				end
				
			elseif string.lower(arg1) == "!infoclass" then
				if not UnitInRaid("player") then return; end
				
				local function GetClassFromRaid()
					for index, v in ipairs(CEPGP_Info.Raid.Roster) do
						if v[1] == target then
							class = v[2];
							break;
						end
					end
				end
				
				local roster = {};
				local class = CEPGP_Info.Guild.Roster[target] and CEPGP_Info.Guild.Roster[target][2] or GetClassFromRaid();
				
				if not class then
					CEPGP_print(target .. " is not in the raid group");
					return;
				end
				
				for index, v in ipairs(CEPGP_Info.Raid.Roster) do
					if v[2] == class then
						table.insert(roster, v);
					end
				end
				
				roster = CEPGP_tSort(roster, 7, true);
				
				for index, data in ipairs(roster) do
					if data[1] == target then
						if CEPGP_Info.Version.List[target][1] == "Addon not enabled" then
							SendChatMessage("EP: " .. data[5] .. " / GP: " .. data[6] .. " / PR: " .. data[7] .. " / PR rank among " .. class .. "s in Raid: #" .. index, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_addAddonMsg("!info;" .. target .. ";EP: " .. data[5] .. " / GP: " .. data[6] .. " / PR: " .. data[7] .. " / PR rank among " .. class .. "s in Raid: #" .. index, "WHISPER", target);
						end
						break;
					end
				end
			end
		end
	end
end

function CEPGP_handleCombat(name)
	if (((GetLootMethod() == "master" and CEPGP_isML() == 0) or (GetLootMethod() == "group" and UnitIsGroupLeader("player"))) and CEPGP_ntgetn(CEPGP_Info.Guild.Roster) > 0) or CEPGP_Info.Debug then
		local localName = L[name];
		local EP = CEPGP.EP.BossEP[name];
		local plurals = name == "The Four Horsemen" or name == "The Silithid Royalty" or name == "The Twin Emperors";
		local message = format(L["%s " .. (plurals and "have" or "has") .. " been defeated! %d EP has been awarded to the raid"], localName, EP);
		local callback = function()
			local function awardEP(localName, EP, message)
				CEPGP_AddRaidEP(EP, message, localName);
			end
			
			local success, failMsg = pcall(awardEP, localName, EP, message);
			
			if not success then
				CEPGP_print("Failed to award raid EP for " .. name, true);
				CEPGP_print(failMsg);
			end
			
			local function awardStandbyEP(localName, EP)
				if CEPGP.Standby.Enabled and tonumber(CEPGP.Standby.Percent) > 0 then
					CEPGP_addStandbyEP(EP*(tonumber(CEPGP.Standby.Percent)/100), localName);
				end
			end
			
			success, failMsg = pcall(awardStandbyEP, localName, EP);
			
			if not success then
				CEPGP_print("Failed to award standby EP for " .. name, true);
				CEPGP_print(failMsg);
			end
		end
		
		--[[if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Guild.Polling then
			table.insert(CEPGP_Info.RosterStack, callback);
		else]]
			callback();
		--end
		if CEPGP_standby_options:IsVisible() then
			CEPGP_UpdateStandbyScrollBar();
		end
	end
end

function CEPGP_handleLoot(event, arg1, arg2)
	if event == "LOOT_CLOSED" then
		CEPGP_Info.Loot.Open = false;
		if CEPGP_isML() == 0 then
			CEPGP_addAddonMsg("LootClosed;", "RAID");
		end
		CEPGP_Info.Loot.DistributionID = nil;
		CEPGP_Info.Loot.Distributing = false;
		CEPGP_toggleGPEdit(true);
		CEPGP_Info.IgnoreUpdates = false;
		_G["CEPGP_distributing_button"]:Hide();
		if CEPGP_Info.Mode == "loot" then
			CEPGP_cleanTable();
			if CEPGP_isML() == 0 then
				local message = "RaidAssistLootClosed";
				CEPGP_sendLootMessage(message);
			end
			HideUIPanel(CEPGP_frame);
		end
		HideUIPanel(CEPGP_distribute_popup);
		--HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_loot);
		HideUIPanel(CEPGP_distribute);
		HideUIPanel(CEPGP_loot_distributing);
		HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_roll_award_confirm);
		if UnitInRaid("player") then
			CEPGP_toggleFrame(CEPGP_raid);
		elseif GetGuildRosterInfo(1) then
			CEPGP_toggleFrame(CEPGP_guild);
		else
			HideUIPanel(CEPGP_frame);
			if CEPGP_isML() == 0 then
				CEPGP_distributing_button:Hide();
			end
		end
		
		if CEPGP_distribute:IsVisible() == 1 then
			HideUIPanel(CEPGP_distribute);
			ShowUIPanel(CEPGP_loot);
			CEPGP_UpdateLootScrollBar();
		end
		
	elseif event == "LOOT_OPENED" and (UnitInRaid("player") or CEPGP_Info.Debug) then
		CEPGP_Info.Loot.Open = true;
		CEPGP_LootFrame_Update();
		ShowUIPanel(CEPGP_button_loot_dist);

	elseif event == "LOOT_SLOT_CLEARED" then
		local slotNum = arg1;
		if not CEPGP_Info.Loot.Distributing and CEPGP_distribute:IsVisible() then
			CEPGP_LootFrame_Update();
		end
		if CEPGP_Info.Loot.Distributing and slotNum == CEPGP_Info.Loot.SlotNum then --Confirms that an item is currently being distributed and that the item taken is the one in question
			CEPGP_LootFrame_Update();
			if CEPGP_isML() == 0 then
				local message = "RaidAssistLootClosed";
				CEPGP_sendLootMessage(message);
				CEPGP_addAddonMsg("LootClosed;", "RAID");
			end
			
			local player = CEPGP_Info.DistTarget;
			local award = CEPGP_Info.Loot.GiveWithEPGP;
			local rate = CEPGP_Info.Loot.AwardRate;
			local id = CEPGP_Info.Loot.DistributionID;
			local link = select(2, GetItemInfo(id));
			local gpValue = tonumber(_G["CEPGP_distribute_GP_value"]:GetText());
			local itemName = _G["CEPGP_distribute_item_name"]:GetText()
			local response = CEPGP_distribute_popup:GetAttribute("responseName");
			local distGP = CEPGP_Info.Loot.AwardGP;
			local tStamp = time();
			
			CEPGP_Info.DistTarget = "";
			CEPGP_Info.Loot.Distributing = false;
			CEPGP_distribute_popup:Hide();
			CEPGP_roll_award_confirm:Hide();
			CEPGP_distribute:Hide();
			_G["CEPGP_distributing_button"]:Hide();
			CEPGP_loot:Show();
			CEPGP_toggleGPEdit(true);
			
			local callback = function()				
				if player ~= "" and award then
					if response == "" then response = nil; end
					
					if distGP then
						if response then
							local message = "Awarded " .. itemName .. " to ".. player .. " for " .. gpValue*rate .. " GP (" .. response .. ")";
							SendChatMessage(message, CEPGP.Channel, CEPGP_Info.Language);
						else
							local message = "Awarded " .. itemName .. " to ".. player .. " for " .. gpValue*rate .. " GP";
							SendChatMessage(message, CEPGP.Channel, CEPGP_Info.Language);
						end
						CEPGP_addGP(player, gpValue*rate, id, link, nil, response);
					else
						if CEPGP_Info.Guild.Roster[player] then
							local index = CEPGP_Info.Guild.Roster[player][1];
							local EP, GP = CEPGP_getEPGP(player, index);
							if response then
								if response == "Highest Roll (Free)" then
									SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free (Highest Roll)", CEPGP.Channel, CEPGP_Info.Language);
									CEPGP_addTraffic(player, UnitName("player"), response, EP, EP, GP, GP, id, tStamp);
								else
									SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free", CEPGP.Channel, CEPGP_Info.Language);
									CEPGP_addTraffic(player, UnitName("player"), "Given for Free", EP, EP, GP, GP, id, tStamp);
								end
							else
								SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free", CEPGP.Channel, CEPGP_Info.Language);
								CEPGP_addTraffic(player, UnitName("player"), "Given for Free", EP, EP, GP, GP, id, tStamp);
							end
						else
							local index = CEPGP_getIndex(player);
							if index then
								SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free (Exclusion List)", CEPGP.Channel, CEPGP_Info.Language);
								CEPGP_addTraffic(player, UnitName("player"), "Given for Free (Exclusion List)", nil, nil, nil, nil, id, tStamp);
							end
						end
					end
					
				else
					SendChatMessage(itemName .. " has been distributed without EPGP", CEPGP.Channel, CEPGP_Info.Language);
					CEPGP_addTraffic(player, UnitName("player"), "Manually Awarded", "", "", "", "", id, tStamp);
				end
			end;
			--[[if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Guild.Polling then
				table.insert(CEPGP_Info.RosterStack, callback);
			else]]
				callback();
			--end
		end
	end	
end