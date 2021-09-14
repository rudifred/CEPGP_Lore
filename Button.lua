local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP");

function CEPGP_ListButton_OnClick(obj, button)
	if button == "LeftButton" then
		if strfind(obj, "overrideButton") and strfind(obj, "Delete") then
			
			local name = _G[_G[obj]:GetParent():GetName() .. "item"]:GetText();
			CEPGP.Overrides[name] = nil;
			CEPGP_print(name .. " |c006969FFremoved from the GP override list");
			CEPGP_UpdateOverrideScrollBar();
			return;
		end
		
		if strfind(obj, "keywordButton") and strfind(obj, "Delete") then
			local parent = _G[obj]:GetParent();
			CEPGP.Loot.ExtraKeywords.Keywords[_G[parent:GetName() .. "Label"]:GetText()] = nil;
			CEPGP_UpdateKeywordScrollBar();
			return;
		end
		
		if strfind(obj, "TrafficButton") and strfind(obj, "Remove") then
			local id = string.sub(obj, 14, string.find(obj, "Remove")-1);
			local frame = _G["TrafficButton" .. id];
			local entry = frame:GetAttribute("id");
			if frame:GetAttribute("delete_confirm") == "true" then
				table.remove(CEPGP.Traffic, tonumber(entry));
				CEPGP_print("Traffic entry " .. entry .. " purged.");
				CEPGP_UpdateTrafficScrollBar();
			else
				local function verify(tLog)
					for i = 1, 8 do
						if not tLog[i] then return false; end
					end
					return true;
				end
				if verify(CEPGP.Traffic[entry]) then
					CEPGP_print("You are attempting to purge the following entry:");
					if CEPGP.Traffic[entry][8] and string.find(CEPGP.Traffic[entry][8], "item:") then -- If an item is associated with the log
						CEPGP_print("Issuer: " .. CEPGP.Traffic[entry][2] .. ", Action: " .. CEPGP.Traffic[entry][3] .. ", Item: " .. CEPGP.Traffic[entry][8] .. " |c006969FF, Recipient: " .. CEPGP.Traffic[entry][1] .. "|r");
					else
						CEPGP_print("Issuer: " .. CEPGP.Traffic[entry][2] .. ", Action: " .. CEPGP.Traffic[entry][3] .. ", Recipient: " .. CEPGP.Traffic[entry][1]);
					end
				else
					CEPGP_print("You are attempting to purge a traffic entry.");
				end
				CEPGP_print("This action cannot be undone. To proceed, press the delete button again.");
				frame:SetAttribute("delete_confirm", "true");
			end
			return;
		end
		
		if strfind(obj, "TrafficButton") and strfind(obj, "Share") then
			local entry = tonumber(string.sub(obj, 14, string.find(obj, "Share")-1));
			local ID, GUID = CEPGP.Traffic[entry][10], CEPGP.Traffic[entry][11];
			if ID and GUID then
				CEPGP_ShareTraffic(ID, GUID);
			end
			return;
		end
		
		if obj == "CEPGP_filter_rank_confirm" then
			for i = 1, 10 do
				CEPGP.Guild.Filter[i] = _G["CEPGP_filter_rank_" .. i .. "_check"]:GetChecked();
			end
			CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			CEPGP_rank_filter:Hide();
			return;
		end
		
		--
		--	The following should be only accessible to those with edit access (i.e. officers)
		--
		
		if strfind(obj, "CEPGP_guild_reset") then
			CEPGP_context_popup_desc:SetPoint("TOP", CEPGP_context_popup_title, "BOTTOM", 0, -5);
		else
			CEPGP_context_popup_desc:SetPoint("TOP", CEPGP_context_popup_title, "BOTTOM", 0, -15);
		end
		if strfind(obj, "CEPGP_standby_ep_list_add") then
			_G["CEPGP_context_reason"]:Hide();
			_G["CEPGP_context_popup_reason"]:Hide();
		else
			_G["CEPGP_context_reason"]:Show();
			_G["CEPGP_context_popup_reason"]:Show();
		end
		
		if not CanEditOfficerNote() and not CEPGP_Info.Debug then
			CEPGP_print("You don't have access to modify EPGP", 1);
			return;
		end
		
		if obj == "CEPGP_options_standby_ep_award" then
			ShowUIPanel(CEPGP_context_popup);
			ShowUIPanel(CEPGP_context_amount);
			ShowUIPanel(CEPGP_context_popup_EP_check);
			HideUIPanel(CEPGP_context_popup_GP_check);
			_G["CEPGP_context_popup_EP_check_text"]:Show();
			_G["CEPGP_context_popup_GP_check_text"]:Hide();
			CEPGP_context_popup_EP_check:SetChecked(1);
			CEPGP_context_popup_GP_check:SetChecked(nil);
			CEPGP_context_popup_header:SetText("Standby EPGP Moderation");
			CEPGP_context_popup_title:SetText("Modify EP for Standby List");
			CEPGP_context_popup_desc:SetText("Add/Subtract EP");
			CEPGP_context_amount:SetText("0");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
					if string.find(CEPGP_context_amount:GetText(), '[^0-9%-]') then
						CEPGP_print("Enter a valid number", true);
					else
						PlaySound(799);
						HideUIPanel(CEPGP_context_popup);
						if CEPGP_context_popup_EP_check:GetChecked() then
							CEPGP_addStandbyEP(tonumber(CEPGP_context_amount:GetText()), nil, CEPGP_context_reason:GetText());
						end
					end
				end);
			return;
		
		elseif strfind(obj, "StandbyButton") then
			local name = _G[_G[_G[obj]:GetName()]:GetParent():GetName() .. "Info"]:GetText();
			for i = 1, CEPGP_ntgetn(CEPGP.Standby.Roster) do
				if CEPGP.Standby.Roster[i][1] == name then
					table.remove(CEPGP.Standby.Roster, i);
					if CEPGP_isML() == 0 and CEPGP.Standby.Share then
						CEPGP_addAddonMsg("StandbyListRemove;" .. CEPGP.Standby.Roster[i][1]);
					end
					break;
				end
			end
			if CEPGP_standby_options:IsVisible() then
				CEPGP_UpdateStandbyScrollBar();
			end
			return;
		end
		
		if obj == "CEPGP_exclude_rank_confirm" then
			local changes = false;
			for i = 1, 10 do
				if CEPGP.Guild.Exclusions[i] ~= _G["CEPGP_exclude_rank_" .. i .. "_check"]:GetChecked() then
					CEPGP.Guild.Exclusions[i] = not CEPGP.Guild.Exclusions[i];
					changes = true;
				end
			end
			if changes then
				CEPGP_print("Updated EPGP rank exclusions");
				--CEPGP_Info.Guild.Roster = {};
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			end
			CEPGP_rank_exclude:Hide();
			return;
		end
		
		if obj == "CEPGP_standby_ep_list_add" then
			if not CanEditOfficerNote() and not CEPGP_Info.Debug then
				CEPGP_print("You cannot add players to standby because you cannot modify EPGP", 1);
				return;
			end
			ShowUIPanel(CEPGP_context_popup);
			CEPGP_context_popup_EP_check:Hide();
			CEPGP_context_popup_GP_check:Hide();
			_G["CEPGP_context_popup_EP_check_text"]:Hide();
			_G["CEPGP_context_popup_GP_check_text"]:Hide();
			CEPGP_context_popup_header:SetText("Add to Standby");
			CEPGP_context_popup_title:Hide();
			CEPGP_context_popup_desc:SetText("Add a guild member to the standby list");
			CEPGP_context_amount:SetText("");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
				PlaySound(799);
				HideUIPanel(CEPGP_context_popup);
				local name = CEPGP_context_amount:GetText();
				CEPGP_addToStandby(name);
			end);
			return;
		end

		if obj == "CEPGP_standby_ep_list_addbyrank" then
			if not CanEditOfficerNote() and not CEPGP_Info.Debug then
				CEPGP_print("You cannot add players to standby because you cannot modify EPGP", 1);
				return;
			end
			
			CEPGP_standby_addRank:Show();
			return;
		end
		
		if obj == "CEPGP_standby_addRank_confirm" then
			local function addRankToStandby()
				local group = {};
				local ranks = {};
				local playerList = {};
				
				for i = 1, GetNumGroupMembers() do
					local name = GetRaidRosterInfo(i);
					table.insert(group, name);
				end
				for i = 1, 10 do
					if _G["CEPGP_standby_addRank_" .. i .. "_check"]:GetChecked() then
						ranks[i] = true;
					else
						ranks[i] = false;
					end
				end
				
				for i = 1, GetNumGuildMembers() do
					local name, _, rIndex = GetGuildRosterInfo(i);
					name = Ambiguate(name, "all");
					if ranks[rIndex+1] and not CEPGP_tContains(CEPGP.Standby.Roster, name) and not CEPGP_tContains(group, name) and name ~= UnitName("player") then
						local _, class, rank, _, oNote, _, classFile = CEPGP_getGuildInfo(name);
						local EP,GP = CEPGP_getEPGP(name, i);
						local entry = {
							[1] = name,
							[2] = class,
							[3] = rank,
							[4] = rIndex,
							[5] = EP,
							[6] = GP,
							[7] = math.floor((tonumber(EP)*100/tonumber(GP)))/100,
							[8] = classFile
						}
						table.insert(playerList, entry);
					end
				end
				
				CEPGP_addToStandby(nil, playerList);
			end
			
			--[[if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Guild.Polling then
				CEPGP_print("Scanning guild roster. Will add rank to standby list soon");
				local callback = function() addRankToStandby() end;
				table.insert(CEPGP_Info.RosterStack, callback);
			else]]
				addRankToStandby();
			--end
			CEPGP_standby_addRank:Hide();
			return;
		end
		if obj == "CEPGP_standby_ep_list_purge" then
			CEPGP.Standby.Roster = {};
			if CEPGP_standby_options:IsVisible() then
				CEPGP_UpdateStandbyScrollBar();
			end
			return;
		end
		
		--[[ Distribution Menu ]]--
		if strfind(obj, "LootDistButton") then --A player in the distribution menu is clicked
			local discount, response, reason;
			if _G[obj]:GetAttribute("response") then
				local attr = _G[obj]:GetAttribute("response");
				response = _G[obj]:GetAttribute("responseName");
				response = CEPGP_indexToLabel(response);
				reason = CEPGP.Loot.GUI.Buttons[attr] and CEPGP.Loot.GUI.Buttons[attr][2] or response;
				discount = (CEPGP.Loot.ExtraKeywords.Keywords[attr] and CEPGP_getDiscount(attr)) or (CEPGP.Loot.GUI.Buttons[attr] and CEPGP.Loot.GUI.Buttons[attr][3]) or CEPGP_getDiscount(CEPGP_indexToLabel(attr));
				CEPGP_distribute_popup:SetAttribute("responseName", reason);
				CEPGP_distribute_popup:SetAttribute("response", attr);
			else
				discount = 0;
				CEPGP_distribute_popup:SetAttribute("responseName", nil);
				CEPGP_distribute_popup:SetAttribute("response", nil);
			end
			local gp = math.floor(CEPGP_distribute_GP_value:GetText());
			local discGP = math.floor(gp*((100-discount)/100));
			local player = _G[_G[obj]:GetName() .. "Info"]:GetText();
			local index = CEPGP_getIndex(player);
			if index then
				local rankIndex = select(3, GetGuildRosterInfo(index));
				if CEPGP_Info.Guild.Roster[player] and CEPGP_Info.Guild.Roster[player][9] then
					discGP = 0;
					discount = 100;
					reason = "Exclusion List";
					CEPGP_distribute_popup:SetAttribute("responseName", "Exclusion List");
				end
			end
			ShowUIPanel(CEPGP_distribute_popup);
			if reason then
				if reason == "Exclusion List" then
					CEPGP_distribute_popup_title:SetText(player .. " (Exclusion List)");
					CEPGP_distribute_popup_gp_full:Hide();
					CEPGP_distribute_popup_gp:Show();
					CEPGP_distribute_popup_gp:SetText("Give for " .. discGP .. "\n(" .. reason .. ")");
				else
					CEPGP_distribute_popup_title:SetText(player .. " (" .. reason .. ")");
					CEPGP_distribute_popup_gp_full:Show();
					CEPGP_distribute_popup_gp_full:SetText("Give for " .. gp .. "\n(Standard Price)");
					if discount ~= 0 then
						CEPGP_distribute_popup_gp:SetText("Give for " .. discGP .. "\n(" .. reason .. ")");
						CEPGP_distribute_popup_gp:Show();
					else
						CEPGP_distribute_popup_gp:Hide();
					end
				end
			else
				CEPGP_distribute_popup_title:SetText(player);
				CEPGP_distribute_popup_gp_full:SetText("Give for " .. gp .. "\n(Standard Price)");
				CEPGP_distribute_popup_gp:Hide();
			end
			
			CEPGP_distribute_popup_gp:SetScript('OnClick', function()
				CEPGP_Info.DistTarget = player;
				CEPGP_distribute_popup:SetID(CEPGP_distribute:GetID()); --CEPGP_distribute:GetID gets the ID of the LOOT SLOT. Not the player.
				CEPGP_Info.Loot.AwardRate = (100-discount)/100;
				if reason == "Exclusion List" then
					CEPGP_Info.Loot.AwardGP = false;
				else
					CEPGP_Info.Loot.AwardGP = true;
				end
				CEPGP_Info.Loot.GiveWithEPGP = true;
				PlaySound(799);
				CEPGP_distribute_popup_give();
			end);
			CEPGP_distribute_popup_gp_full:SetScript('OnClick', function()
				reason = "Full Price";
				CEPGP_distribute_popup:SetAttribute("responseName", reason);
				CEPGP_distribute_popup:SetAttribute("response", tonumber(_G[obj]:GetAttribute("response")));
				CEPGP_Info.DistTarget = _G[_G[obj]:GetName() .. "Info"]:GetText();
				CEPGP_distribute_popup:SetID(CEPGP_distribute:GetID());
				CEPGP_Info.Loot.AwardRate = 1;
				CEPGP_Info.Loot.AwardGP = true;
				CEPGP_Info.Loot.GiveWithEPGP = true;
				PlaySound(799);
				CEPGP_distribute_popup_give();
			end);
			CEPGP_distribute_popup_free:SetScript('OnClick', function()
				CEPGP_Info.DistTarget = _G[_G[obj]:GetName() .. "Info"]:GetText();
				CEPGP_distribute_popup:SetID(CEPGP_distribute:GetID());
				CEPGP_Info.Loot.AwardRate = 1;
				CEPGP_Info.Loot.GiveWithEPGP = true;
				CEPGP_Info.Loot.AwardGP = false;
				PlaySound(799);
				CEPGP_distribute_popup_give();
			end);
			return;
		
			--[[ Guild Menu ]]--
		elseif strfind(obj, "GuildButton") then --A player from the guild menu is clicked (awards EP)
			local frame = _G[obj];
			local excluded = frame:GetAttribute("excluded");
			local name = _G[obj.. "Info"]:GetText();
			if excluded then
				CEPGP_print("You cannot modify EPGP for " .. name .. " because their rank has been excluded");
				return;
			end
			ShowUIPanel(CEPGP_context_popup);
			ShowUIPanel(CEPGP_context_amount);
			ShowUIPanel(CEPGP_context_popup_EP_check);
			ShowUIPanel(CEPGP_context_popup_GP_check);
			_G["CEPGP_context_popup_EP_check_text"]:Show();
			_G["CEPGP_context_popup_GP_check_text"]:Show();
			CEPGP_context_popup_EP_check:SetChecked(1);
			CEPGP_context_popup_GP_check:SetChecked(nil);
			CEPGP_context_popup_header:SetText("Guild Moderation");
			CEPGP_context_popup_title:SetText("Modify EP/GP for " .. name);
			CEPGP_context_popup_desc:SetText("Add/Subtract EP");
			CEPGP_context_amount:SetText("0");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
				local amount = CEPGP_context_amount:GetText();
				if string.find(amount, '[^0-9%-]') then
					CEPGP_print("Enter a valid number", true);
				elseif amount == "" then
					return;
				else
					PlaySound(799);
					HideUIPanel(CEPGP_context_popup);
					if CEPGP_context_popup_EP_check:GetChecked() then
						CEPGP_addEP(name, tonumber(CEPGP_context_amount:GetText()), CEPGP_context_reason:GetText());
					else
						CEPGP_addGP(name, tonumber(CEPGP_context_amount:GetText()), nil, nil, CEPGP_context_reason:GetText());
					end
				end
			end);
			return;
			
		elseif strfind(obj, "CEPGP_guild_add_EP") then --Click the Add Guild EP button in the Guild menu
			ShowUIPanel(CEPGP_context_popup);
			ShowUIPanel(CEPGP_context_amount);
			ShowUIPanel(CEPGP_context_popup_EP_check);
			HideUIPanel(CEPGP_context_popup_GP_check);
			_G["CEPGP_context_popup_EP_check_text"]:Show();
			_G["CEPGP_context_popup_GP_check_text"]:Hide();
			CEPGP_context_popup_EP_check:SetChecked(1);
			CEPGP_context_popup_GP_check:SetChecked(nil);
			CEPGP_context_popup_header:SetText("Guild Moderation");
			CEPGP_context_popup_title:SetText("Modify Guild EP");
			CEPGP_context_popup_desc:SetText("Adds/Subtracts EP for all guild members");
			CEPGP_context_amount:SetText("0");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
				local amount = CEPGP_context_amount:GetText();
				if string.find(amount, '[^0-9%-]') then
					CEPGP_print("Enter a valid number", true);
				elseif amount == "" then
					return;
				else
					PlaySound(799);
					HideUIPanel(CEPGP_context_popup);
					CEPGP_addGuildEP(tonumber(CEPGP_context_amount:GetText()), CEPGP_context_reason:GetText());
				end
			end);
			return;
		
		elseif strfind(obj, "CEPGP_guild_decay") then --Click the Decay Guild EPGP button in the Guild menu
			CEPGP_decay_popup:Show();
			CEPGP_decay_popup_reason:SetText("");
			CEPGP_decay_popup_amount:SetText("0");
			local EP, GP; -- Whether or not this is an EP or GP specific decay
			if obj == "CEPGP_guild_decay_EP" then
				CEPGP_decay_popup_header:SetText("Decay Guild EP");
				EP = true;
			elseif obj == "CEPGP_guild_decay_GP" then
				CEPGP_decay_popup_header:SetText("Decay Guild GP");
				GP = true;
			else
				CEPGP_decay_popup_header:SetText("Decay Guild EPGP");
			end
			CEPGP_decay_popup_desc:SetText("Positive numbers decay | Negative numbers inflate");
			CEPGP_decay_popup_confirm:SetScript('OnClick', function()
				local amount = CEPGP_decay_popup_amount:GetText();
				local fixed = CEPGP_decay_popup_fixed_check:GetChecked();
				local reason = CEPGP_decay_popup_reason:GetText();
				if (string.find(amount, '^[0-9]+$') or string.find(amount, '^[0-9]+.[0-9]+$') or
					string.find(amount, '^-[0-9]+$') or string.find(amount, '^-[0-9]+.[0-9]+$')) and
					amount ~= "0" then
					PlaySound(799);
					CEPGP_decay_popup:Hide();
					CEPGP_decay(tonumber(amount), reason, EP, GP, fixed);
				else
					CEPGP_print("Enter a valid number", true);
				end
			end);
			return;
			
		elseif strfind(obj, "CEPGP_guild_reset") then --Click the Reset All EPGP Standings button in the Guild menu
			ShowUIPanel(CEPGP_context_popup);
			HideUIPanel(CEPGP_context_amount);
			HideUIPanel(CEPGP_context_popup_EP_check);
			HideUIPanel(CEPGP_context_popup_GP_check);
			_G["CEPGP_context_popup_EP_check_text"]:Hide();
			_G["CEPGP_context_popup_GP_check_text"]:Hide();
			CEPGP_context_popup_EP_check:SetChecked(nil);
			CEPGP_context_popup_GP_check:SetChecked(nil);
			CEPGP_context_popup_header:SetText("Guild Moderation");
			CEPGP_context_popup_title:SetText("Reset Guild EPGP");
			CEPGP_context_popup_desc:SetText("Resets the Guild EPGP standings\n|c00FF0000Are you sure that is what you want to do?\nthis cannot be reversed!|r");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
				PlaySound(799);
				HideUIPanel(CEPGP_context_popup);
				CEPGP_resetAll(CEPGP_context_reason:GetText());
			end)
			return;
			
			--[[ Raid Menu ]]--
		elseif strfind(obj, "RaidButton") then --A player from the raid menu is clicked (awards EP)
			local frame = _G[obj];
			local excluded = frame:GetAttribute("excluded");
			local name = _G[obj.. "Info"]:GetText();
			if not CEPGP_getGuildInfo(name) then
				CEPGP_print(name .. " is not a guild member - Cannot award EP or GP", true);
				return;
			end
			if excluded then
				CEPGP_print("You cannot modify EPGP for " .. name .. " because their rank has been excluded");
				return;
			end
			ShowUIPanel(CEPGP_context_popup);
			ShowUIPanel(CEPGP_context_amount);
			ShowUIPanel(CEPGP_context_popup_EP_check);
			ShowUIPanel(CEPGP_context_popup_GP_check);
			_G["CEPGP_context_popup_EP_check_text"]:Show();
			_G["CEPGP_context_popup_GP_check_text"]:Show();
			CEPGP_context_popup_EP_check:SetChecked(1);
			CEPGP_context_popup_GP_check:SetChecked(nil);
			CEPGP_context_popup_header:SetText("Raid Moderation");
			CEPGP_context_popup_title:SetText("Modify EP/GP for " .. name);
			CEPGP_context_popup_desc:SetText("Add/Subtract EP");
			CEPGP_context_amount:SetText("0");
			CEPGP_context_popup_confirm:SetScript('OnClick', function()
				local amount = CEPGP_context_amount:GetText();
				if string.find(amount, '[^0-9%-]') then
					CEPGP_print("Enter a valid number", true);
				elseif amount == "" then
					return;
				else
					PlaySound(799);
					HideUIPanel(CEPGP_context_popup);
					if CEPGP_context_popup_EP_check:GetChecked() then
						CEPGP_addEP(name, tonumber(CEPGP_context_amount:GetText()), CEPGP_context_reason:GetText());
					else
						CEPGP_addGP(name, tonumber(CEPGP_context_amount:GetText()), nil, nil, CEPGP_context_reason:GetText());
					end
				end
			end);
			return;
		
		elseif strfind(obj, "CEPGP_raid_add_EP") then --Click the Add Raid EP button in the Raid menu
			CEPGP_award_raid_popup:Show();
			CEPGP_award_raid_popup_amount:SetText("0");
			CEPGP_award_raid_popup_confirm:SetScript('OnClick', function()
				local standby = CEPGP_award_raid_popup_standby_check:GetChecked();
				local amount = tonumber(CEPGP_award_raid_popup_amount:GetText());
				local reason = CEPGP_award_raid_popup_reason:GetText();
				if string.find(amount, '[^0-9%-]') then
					CEPGP_print("Enter a valid number", true);
				elseif amount == "" then
					return;
				else
					PlaySound(799);
					CEPGP_award_raid_popup:Hide();
					CEPGP_AddRaidEP(amount, reason);
					if standby then
						CEPGP_addStandbyEP(amount, nil, reason);
					end
				end
			end);
			return;
		end
	end
end

function CEPGP_setOverrideLink(frame, event)
	
	if event == "enter" then
		local _, link = GetItemInfo(frame:GetText());
		GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT");
		GameTooltip:SetHyperlink(link);
		GameTooltip:Show()
	else
		GameTooltip:Hide();
	end
end

function CEPGP_distribute_popup_give()
	for i = 1, 40 do
		if GetMasterLootCandidate(CEPGP_Info.Loot.SlotNum, i) == CEPGP_Info.DistTarget then
			GiveMasterLoot(CEPGP_Info.Loot.SlotNum, i);
			return;
		end
	end
	CEPGP_print(CEPGP_Info.DistTarget .. " is not on the candidate list for loot", true);
	CEPGP_Info.DistTarget = "";
end

function CEPGP_distribute_popup_OnEvent(eCode)
	
	--[[	Error Codes:
		2		Player's inventory is full
		22		Player already has one of the unique item
	]]
	
	if CEPGP_Info.Loot.Distributing then
		if eCode == 2 then
			CEPGP_print(CEPGP_Info.DistTarget .. "'s inventory is full", 1);
			CEPGP_distribute_popup:Hide();
			CEPGP_Info.DistTarget = "";
			CEPGP_Info.Loot.GiveWithEPGP = false;
			
		elseif eCode == 22 then
			CEPGP_print(CEPGP_Info.DistTarget .. " can't carry any more of this unique item", 1);
			CEPGP_distribute_popup:Hide();
			CEPGP_Info.DistTarget = "";
			CEPGP_Info.Loot.GiveWithEPGP = false;
		end
	end
end

		--[[ Restore DropDown ]]--

function CEPGP_initRestoreDropdown(frame, level, menuList)
	for k, _ in pairs(CEPGP.Backups) do
		local info = {text = k, func = CEPGP_restoreDropdownOnClick};
		local entry = UIDropDownMenu_AddButton(info);
	end
end

function CEPGP_restoreDropdownOnClick(self, arg1, arg2, checked)
	if (not checked) then
		UIDropDownMenu_SetSelectedName(CEPGP_restoreDropdown, self:GetText());
	end
end

		--[[ Attendance DropDown ]]--
		
function CEPGP_attendanceDropdown(frame, level, menuList)
	local info = {text = "Guild List", value = 0, func = CEPGP_attendanceChange};
	local entry = UIDropDownMenu_AddButton(info);
	for i = 1, CEPGP_ntgetn(CEPGP.Attendance) do
		local info = {text = date("%d/%m/%Y %H:%M", CEPGP.Attendance[i][1]), value = i, func = CEPGP_attendanceChange};
		local entry = UIDropDownMenu_AddButton(info);
	end
end

function CEPGP_attendanceChange(self, arg1, arg2, checked)
	if (not checked) then
		UIDropDownMenu_SetSelectedName(CEPGP_attendance_dropdown, self:GetText());
		UIDropDownMenu_SetSelectedValue(CEPGP_attendance_dropdown, self.value);
	end
end

		--[[ Minimum Threshold DropDown ]]--

function CEPGP_minThresholdDropdown(frame, level, menuList)
	local rarity = {
		[0] = "|cFF9D9D9DPoor|r",
		[1] = "|cFFFFFFFFCommon|r",
		[2] = "|cFF1EFF00Uncommon|r",
		[3] = "|cFF0070DDRare|r",
		[4] = "|cFFA335EEEpic|r",
		[5] = "|cFFFF8000Legendary|r"
	};
	for i = 0, 5 do
		local info = {
			text = rarity[i],
			value = i,
			func = CEPGP_minThresholdChange
		};
		local entry = UIDropDownMenu_AddButton(info);
	end
	UIDropDownMenu_SetSelectedName(CEPGP_min_threshold_dropdown, rarity[CEPGP.Loot.MinThreshold]);
	--UIDropDownMenu_SetSelectedValue(CEPGP.Loot.MinThreshold_dropdown, CEPGP.Loot.MinThreshold);
end

function CEPGP_minThresholdChange(self, value)
	UIDropDownMenu_SetSelectedName(CEPGP_min_threshold_dropdown, self:GetText());
	--UIDropDownMenu_SetSelectedValue(CEPGP.Loot.MinThreshold_dropdown, self.value);
	CEPGP.Loot.MinThreshold = self.value;
	CEPGP_print("Minimum auto show threshold is now set to " .. self:GetText());
end

		--[[ Default Channel DropDown ]]--
		
function CEPGP_defChannelDropdown(frame, level, menuList)
	local channels = {
		[1] = "Party",
		[2] = "Raid",
		[3] = "Guild",
		[4] = "Officer"
	};
	for index, value in ipairs(channels) do
		local info = {
			text = value,
			value = index,
			func = CEPGP_defChannelChange
		};
		local entry = UIDropDownMenu_AddButton(info);
	end
	for i = 1, #channels do
		if string.lower(CEPGP.Channel) == string.lower(channels[i]) then
			UIDropDownMenu_SetSelectedName(CEPGP_interface_options_def_channel_dropdown, channels[i]);
		end
	end
end

function CEPGP_defChannelChange(self, value)
	UIDropDownMenu_SetSelectedName(CEPGP_interface_options_def_channel_dropdown, self:GetText());
	--UIDropDownMenu_SetSelectedValue(CEPGP_interface_options_def_channel_dropdown, self.value);
	CEPGP.Channel = self:GetText();
	CEPGP_print("Reporting channel set to \"" .. CEPGP.Channel .. "\".");
end

		--[[ Loot Response Channel DropDown ]]--
		
function CEPGP_lootChannelDropdown(frame, level, menuList)
	local channels = {
		[1] = "Party",
		[2] = "Raid",
		[3] = "Guild",
		[4] = "Officer"
	};
	for index, value in ipairs(channels) do
		local info = {
			text = value,
			value = index,
			func = CEPGP_lootChannelChange
		};
		local entry = UIDropDownMenu_AddButton(info);
	end
	for i = 1, #channels do
		if string.lower(CEPGP.LootChannel) == string.lower(channels[i]) then
			UIDropDownMenu_SetSelectedName(CEPGP_loot_channel_dropdown, channels[i]);
			--UIDropDownMenu_SetSelectedValue(CEPGP_loot_channel_dropdown, i);
		end
	end
end

function CEPGP_lootChannelChange(self, value)
	UIDropDownMenu_SetSelectedName(CEPGP_loot_channel_dropdown, self:GetText());
	--UIDropDownMenu_SetSelectedValue(CEPGP_loot_channel_dropdown, self.value);
	CEPGP.LootChannel = self:GetText();
	CEPGP_print("Loot response channel set to \"" .. CEPGP.LootChannel .. "\".");
end