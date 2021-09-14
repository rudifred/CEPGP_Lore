function CEPGP_UpdateLootScrollBar(PRsort, sort)
	local tempTable = {};
	local count = 1;
	CEPGP_Info.LastRun.DistSB = GetTime();
	local call = CEPGP_Info.LastRun.DistSB;
	local quit = false;
	for name, _ in pairs(CEPGP_Info.Loot.ItemsTable) do
		local roll = math.ceil(math.random(0, 100));
		local EP, GP;
		if CEPGP_Info.Guild.Roster[name] then
			local index = CEPGP_getIndex(name);
			EP, GP = CEPGP_getEPGP(name, index);
			GP = math.max(math.floor(GP), CEPGP.GP.Min);
			tempTable[count] = {
				[1] = name,
				[2] = CEPGP_Info.Guild.Roster[name][2], --Class
				[3] = CEPGP_Info.Guild.Roster[name][3], --Rank
				[4] = CEPGP_Info.Guild.Roster[name][4], --RankIndex
				[5] = (CEPGP_Info.Guild.Roster[name][9] and -1 or EP),
				[6] = (CEPGP_Info.Guild.Roster[name][9] and -1 or GP),
				[7] = (CEPGP_Info.Guild.Roster[name][9] and -1 or math.floor((EP/GP)*100)/100),
				[8] = CEPGP_Info.Loot.ItemsTable[name][1] or "noitem",
				[9] = CEPGP_Info.Loot.ItemsTable[name][2] or "noitem",
				[10] = CEPGP_Info.Guild.Roster[name][7], --className in English
				[11] = CEPGP_Info.Loot.ItemsTable[name][3], -- Loot response
				[12] = CEPGP_Info.Loot.ItemsTable[name][4],
				[13] = CEPGP_Info.Guild.Roster[name][9]
			};
		else	--	Player is in raid, but not in guild
			EP = 0;
			GP = CEPGP.GP.Min;
			for i = 1, GetNumGroupMembers() do
				if GetRaidRosterInfo(i) == name then
					local class = select(5, GetRaidRosterInfo(i))
					local rank = "Not in Guild";
					local rankIndex = 11;
					local classFile = select(6, GetRaidRosterInfo(i));
					tempTable[count] = {
						[1] = name,
						[2] = class,
						[3] = rank,
						[4] = rankIndex,
						[5] = EP,
						[6] = GP,
						[7] = math.floor((tonumber(EP)*100/tonumber(GP)))/100,
						[8] = CEPGP_Info.Loot.ItemsTable[name][1] or "noitem",
						[9] = CEPGP_Info.Loot.ItemsTable[name][2] or "noitem",
						[10] = classFile,
						[11] = CEPGP_Info.Loot.ItemsTable[name][3], -- Loot response
						[12] = CEPGP_Info.Loot.ItemsTable[name][4]
					};
				end
			end
		end
		count = count + 1;
		
	end
	if PRsort and CEPGP.Loot.AutoSort then
		tempTable = CEPGP_sortDistList(tempTable);
	elseif sort then
		tempTable = CEPGP_tSort(tempTable, CEPGP_Info.Sorting.Loot[1], CEPGP_Info.Sorting.Loot[2]);
	end
	local kids = {_G["CEPGP_dist_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	local i = 1;
	for _, data in ipairs(tempTable) do
		if CEPGP_Info.LastRun.DistSB ~= call then return; end
		if CEPGP.Loot.ShowPass and data[11] == 6 or data[11] ~= 6 then
			local index = i;
			local response = data[11];
			local reason = CEPGP_Info.LootSchema[data[11]];
			local EPcolour, EP, GP, PR;
			EP = (data[5] == -1 and "Excluded" or data[5]);
			GP = (data[6] == -1 and "Excluded" or data[6]);
			PR = (data[7] == -1 and "Excluded" or data[7]);
			if response == "Pass" then
				return;
			end
			if not _G["LootDistButton" .. index] then
				local frame = CreateFrame('Button', "LootDistButton" .. index, _G["CEPGP_dist_scrollframe_container"], "LootDistButtonTemplate");
				if i > 1 then
					_G["LootDistButton" .. index]:SetPoint("TOPLEFT", _G["LootDistButton" .. index-1], "BOTTOMLEFT", 0, -2);
				else
					_G["LootDistButton" .. index]:SetPoint("TOPLEFT", _G["CEPGP_dist_scrollframe_container"], "TOPLEFT", 0, -10);
				end
			end
			if CEPGP.Loot.MinReq[1] and CEPGP.Loot.MinReq[2] > tonumber(data[5]) then
				EPcolour = {
					r = 1,
					g = 0,
					b = 0
				};
			else
				EPcolour = CEPGP_Info.ClassColours[string.upper(data[10])];
			end
			
			local colour = CEPGP_Info.ClassColours[string.upper(data[10])];
			if not colour then
				colour = {
					r = 1,
					g = 1,
					b = 1
				};
			end
			
			_G["LootDistButton" .. index]:Show();
			_G["LootDistButton" .. index]:SetAttribute("response", response);
			_G["LootDistButton" .. index]:SetAttribute("responseName", response);
			_G["LootDistButton" .. index .. "Info"]:SetText(data[1]);
			_G["LootDistButton" .. index .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["LootDistButton" .. index .. "Class"]:SetText(data[2]);
			_G["LootDistButton" .. index .. "Class"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["LootDistButton" .. index .. "Rank"]:SetText(data[3]);
			_G["LootDistButton" .. index .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["LootDistButton" .. index .. "Response"]:SetText(reason);
			_G["LootDistButton" .. index .. "Response"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["LootDistButton" .. index .. "EP"]:SetText(EP);
			_G["LootDistButton" .. index .. "GP"]:SetText(GP);
			_G["LootDistButton" .. index .. "PR"]:SetText(PR);
			_G["LootDistButton" .. index .. "Roll"]:SetText(data[12]);
			_G["LootDistButton" .. index .. "Roll"]:SetTextColor(colour.r, colour.g, colour.b);
			
			if data[13] then
				_G["LootDistButton" .. index .. "EP"]:SetTextColor(1, 0, 0);
				_G["LootDistButton" .. index .. "GP"]:SetTextColor(1, 0, 0);
				_G["LootDistButton" .. index .. "PR"]:SetTextColor(1, 0, 0);
			else
				_G["LootDistButton" .. index .. "EP"]:SetTextColor(EPcolour.r, EPcolour.g, EPcolour.b);
				_G["LootDistButton" .. index .. "GP"]:SetTextColor(colour.r, colour.g, colour.b);
				_G["LootDistButton" .. index .. "PR"]:SetTextColor(colour.r, colour.g, colour.b);
			end
					
			if data[8] ~= "noitem" or data[9] ~= "noitem" then
				if data[8] ~= "noitem" then
					local id = tonumber(data[8]);
					_, link, _, _, _, _, _, _, _, tex = GetItemInfo(id);
					local iString;
					if not link and CEPGP_itemExists(id) then	--	If the item exists, but item info is not available
						local item = Item:CreateFromItemID(id);
						item:ContinueOnItemLoad(function()
							_, link, _, _, _, _, _, _, _, tex = GetItemInfo(id)
							iString = CEPGP_getItemString(link);
							_G["LootDistButton" .. index .. "Tex"]:SetScript('OnLeave', function()
								GameTooltip:Hide()
							end);
							
							_G["LootDistButton" .. index .. "Tex"]:SetScript('OnEnter', function()	
								GameTooltip:SetOwner(_G["LootDistButton" .. index .. "Tex"], "ANCHOR_TOPLEFT");
								GameTooltip:SetHyperlink(iString);
								GameTooltip:Show();
							end);
							_G["LootDistButton" .. index .. "Icon"]:SetTexture(tex);					
						end);
					elseif link and CEPGP_itemExists(id) then
						iString = CEPGP_getItemString(link);
						_G["LootDistButton" .. index .. "Tex"]:SetScript('OnLeave', function()
							GameTooltip:Hide()
						end);
						_G["LootDistButton" .. index .. "Tex"]:SetScript('OnEnter', function()	
							GameTooltip:SetOwner(_G["LootDistButton" .. index .. "Tex"], "ANCHOR_TOPLEFT");
							GameTooltip:SetHyperlink(iString);
							GameTooltip:Show();
						end);
						_G["LootDistButton" .. index .. "Icon"]:SetTexture(tex);
					end
				else
					_G["LootDistButton" .. index .. "Tex"]:SetScript('OnEnter', function() end);
					_G["LootDistButton" .. index .. "Icon"]:SetTexture(nil);
				end
				
				if data[9] ~= "noitem" then
					local id = tonumber(data[9]);
					_, link, _, _, _, _, _, _, _, tex2 = GetItemInfo(id);
					local iString2;
					if not link and CEPGP_itemExists(id) then
						local item = Item:CreateFromItemID(id);
						item:ContinueOnItemLoad(function()
							_, link, _, _, _, _, _, _, _, tex2 = GetItemInfo(id)
							iString2 = CEPGP_getItemString(link);
							_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnLeave', function()
								GameTooltip:Hide()
							end);
							_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnEnter', function()	
								GameTooltip:SetOwner(_G["LootDistButton" .. index .. "Tex2"], "ANCHOR_TOPLEFT")
								GameTooltip:SetHyperlink(iString2)
								GameTooltip:Show()
							end);				
							_G["LootDistButton" .. index .. "Icon2"]:SetTexture(tex2);
						end);
					else
						iString2 = CEPGP_getItemString(link);
						_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnLeave', function()
							GameTooltip:Hide()
						end);
						_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnEnter', function()	
							GameTooltip:SetOwner(_G["LootDistButton" .. index .. "Tex2"], "ANCHOR_TOPLEFT")
							GameTooltip:SetHyperlink(iString2)
							GameTooltip:Show()
						end);				
						_G["LootDistButton" .. index .. "Icon2"]:SetTexture(tex2);
					end
				else
					_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnEnter', function() end);
					_G["LootDistButton" .. index .. "Icon2"]:SetTexture(nil);
				end
			else --Recipient has no items in the corresponding slots
				_G["LootDistButton" .. index .. "Tex"]:SetScript('OnLeave', function()
							GameTooltip:Hide()
				end);
				_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnLeave', function()
					GameTooltip:Hide()
				end);
				_G["LootDistButton" .. index .. "Icon"]:SetTexture(nil);
				_G["LootDistButton" .. index .. "Icon2"]:SetTexture(nil);
				_G["LootDistButton" .. index .. "Tex2"]:SetScript('OnEnter', function() end);
				_G["LootDistButton" .. index .. "Icon2"]:SetTexture(nil);
				_G["LootDistButton" .. index .. "Tex"]:SetScript('OnEnter', function() end);
				_G["LootDistButton" .. index .. "Icon"]:SetTexture(nil);
			end
			i = i + 1;
		end
	end
end

function CEPGP_UpdateGuildScrollBar()
	CEPGP_Info.LastRun.GuildSB = GetTime();
	if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) ~= GetNumGuildMembers() then return; end	--	This is mostly to prevent an error occurring if people check the scrollframe too soon after the UI loads
	local call = CEPGP_Info.LastRun.GuildSB;
	local quit = false;
	local tempTable = {};
	local count = 1;
	for name, v in pairs(CEPGP_Info.Guild.Roster) do
		if not v[10] then	--	If this player is not being hidden due to rank filtering
			local index = CEPGP_getIndex(name);
			local EP, GP = CEPGP_getEPGP(name, index)
			tempTable[count] = {
				[1] = name,
				[2] = v[2], --Class
				[3] = v[3], --Rank
				[4] = v[4], --RankIndex
				[5] = (CEPGP_Info.Guild.Roster[name][9] and -1 or EP),
				[6] = (CEPGP_Info.Guild.Roster[name][9] and -1 or GP),
				[7] = (CEPGP_Info.Guild.Roster[name][9] and -1 or math.floor((EP/GP)*100)/100),
				[8] = v[7], -- className in English,
				[9] = v[9] -- Exclusion status,
			};
			count = count + 1;
		end
	end
	if #tempTable == 0 then return; end
	tempTable = CEPGP_tSort(tempTable, CEPGP_Info.Sorting.Guild[1], CEPGP_Info.Sorting.Guild[2]);
	local kids = {_G["CEPGP_guild_scrollframe_container"]:GetChildren()};
	for index, child in ipairs(kids) do
		if index > CEPGP_ntgetn(CEPGP_Info.Guild.Roster) or index > #tempTable then
			child:Hide();
			--child = nil;
		end
		--child:Hide();
	end
	local i = 1;
	C_Timer.NewTicker(0.0001, function()
		if CEPGP_Info.LastRun.GuildSB ~= call then
			quit = true;
			return;
		end
		local EPcolour, EP, GP, PR;
		EP = (tempTable[i][5] == -1 and "Excluded" or tempTable[i][5]);
		GP = (tempTable[i][6] == -1 and "Excluded" or tempTable[i][6]);
		PR = (tempTable[i][7] == -1 and "Excluded" or tempTable[i][7]);
		if #tempTable > 0 then
			local frame;
			if not _G["GuildButton" .. i] then
				frame = CreateFrame('Button', "GuildButton" .. i, _G["CEPGP_guild_scrollframe_container"], "GuildButtonTemplate");
				if i > 1 then
					_G["GuildButton" .. i]:SetPoint("TOPLEFT", _G["GuildButton" .. i-1], "BOTTOMLEFT", 0, -2);
				else
					_G["GuildButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_guild_scrollframe_container"], "TOPLEFT", 0, -10);
				end
			else
				frame = _G["GuildButton" .. i];
			end
			local colour = CEPGP_Info.ClassColours[string.upper(tempTable[i][8])];
			if not colour then
				colour = {
				r = 1,
				g = 1,
				b = 1
			};
			end
			frame:SetAttribute("excluded", (tempTable[i][9] and true or false));
			_G["GuildButton" .. i]:Show();
			_G["GuildButton" .. i .. "Info"]:SetText(tempTable[i][1]);
			_G["GuildButton" .. i .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["GuildButton" .. i .. "Class"]:SetText(tempTable[i][2]);
			_G["GuildButton" .. i .. "Class"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["GuildButton" .. i .. "Rank"]:SetText(tempTable[i][3]);
			_G["GuildButton" .. i .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["GuildButton" .. i .. "EP"]:SetText(EP);
			_G["GuildButton" .. i .. "GP"]:SetText(GP);
			_G["GuildButton" .. i .. "PR"]:SetText(PR);
			if tempTable[i][9] then
				_G["GuildButton" .. i .. "EP"]:SetTextColor(1, 0, 0);
				_G["GuildButton" .. i .. "GP"]:SetTextColor(1, 0, 0);
				_G["GuildButton" .. i .. "PR"]:SetTextColor(1, 0, 0);
			else
				_G["GuildButton" .. i .. "EP"]:SetTextColor(colour.r, colour.g, colour.b);
				_G["GuildButton" .. i .. "GP"]:SetTextColor(colour.r, colour.g, colour.b);
				_G["GuildButton" .. i .. "PR"]:SetTextColor(colour.r, colour.g, colour.b);
			end
		end
		i = i + 1;
	end, #tempTable);
end

function CEPGP_UpdateRaidScrollBar()
	CEPGP_Info.LastRun.RaidSB = GetTime();
	local call = CEPGP_Info.LastRun.RaidSB;
	local tempTable = {};
	for i = 1, CEPGP_ntgetn(CEPGP_Info.Raid.Roster) do
		local name = CEPGP_Info.Raid.Roster[i][1];
		local excluded = CEPGP_Info.Guild.Roster[name] and CEPGP_Info.Guild.Roster[name][9];
		local EP, GP = CEPGP_getEPGP(name, index);
		if CEPGP_Info.Guild.Roster[name] then
			tempTable[i] = {
				[1] = CEPGP_Info.Raid.Roster[i][1], --Name
				[2] = CEPGP_Info.Raid.Roster[i][2], --Class
				[3] = CEPGP_Info.Raid.Roster[i][3], --Rank
				[4] = CEPGP_Info.Raid.Roster[i][4], --RankIndex
				[5] = (CEPGP_Info.Guild.Roster[name][9] and -1 or EP),
				[6] = (CEPGP_Info.Guild.Roster[name][9] and -1 or GP),
				[7] = (CEPGP_Info.Guild.Roster[name][9] and -1 or math.floor((EP/GP)*100)/100),
				[8] = CEPGP_Info.Raid.Roster[i][8],  --Class in English
				[9] = excluded
			};
		else
			EP, GP = 0, CEPGP.GP.Min;
			tempTable[i] = {
				[1] = CEPGP_Info.Raid.Roster[i][1], --Name
				[2] = CEPGP_Info.Raid.Roster[i][2], --Class
				[3] = CEPGP_Info.Raid.Roster[i][3], --Rank
				[4] = CEPGP_Info.Raid.Roster[i][4], --RankIndex
				[5] = EP,
				[6] = GP,
				[7] = math.floor((EP/GP)*100)/100,
				[8] = CEPGP_Info.Raid.Roster[i][8],  --Class in English
				[9] = false
			};
		end
		
	end
	tempTable = CEPGP_tSort(tempTable, CEPGP_Info.Sorting.Raid[1], CEPGP_Info.Sorting.Raid[2]);
	local kids = {_G["CEPGP_raid_scrollframe_container"]:GetChildren()};
	for index, child in ipairs(kids) do
		if index > CEPGP_ntgetn(CEPGP_Info.Raid.Roster) then
			child:Hide();
			--child = nil;
		end
	end
	for i = 1, CEPGP_ntgetn(tempTable) do
		if CEPGP_Info.LastRun.RaidSB ~= call or #tempTable ~= #CEPGP_Info.Raid.Roster then
			return;
		end
		local EPcolour, EP, GP, PR;
		EP = (tempTable[i][5] == -1 and "Excluded" or tempTable[i][5]);
		GP = (tempTable[i][6] == -1 and "Excluded" or tempTable[i][6]);
		PR = (tempTable[i][7] == -1 and "Excluded" or tempTable[i][7]);
		local frame;
		if not _G["RaidButton" .. i] then
			frame = CreateFrame('Button', "RaidButton" .. i, _G["CEPGP_raid_scrollframe_container"], "RaidButtonTemplate");
			if i > 1 then
				_G["RaidButton" .. i]:SetPoint("TOPLEFT", _G["RaidButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["RaidButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_raid_scrollframe_container"], "TOPLEFT", 0, -10);
			end
		else
			frame = _G["RaidButton" .. i];
		end
		local colour = CEPGP_Info.ClassColours[string.upper(tempTable[i][8])];
		if not colour then
			colour = {
			r = 1,
			g = 1,
			b = 1
		};
		end
		
		frame:SetAttribute("excluded", (tempTable[i][9] and true or false));
		_G["RaidButton" .. i]:Show();
		_G["RaidButton" .. i .. "Info"]:SetText(tempTable[i][1]);
		_G["RaidButton" .. i .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["RaidButton" .. i .. "Class"]:SetText(tempTable[i][2]);
		_G["RaidButton" .. i .. "Class"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["RaidButton" .. i .. "Rank"]:SetText(tempTable[i][3]);
		_G["RaidButton" .. i .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["RaidButton" .. i .. "EP"]:SetText(EP);		
		_G["RaidButton" .. i .. "GP"]:SetText(GP);
		_G["RaidButton" .. i .. "PR"]:SetText(PR);
		
		if tempTable[i][9] then
			_G["RaidButton" .. i .. "EP"]:SetTextColor(1, 0, 0);
			_G["RaidButton" .. i .. "GP"]:SetTextColor(1, 0, 0);
			_G["RaidButton" .. i .. "PR"]:SetTextColor(1, 0, 0);
		else
			_G["RaidButton" .. i .. "EP"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["RaidButton" .. i .. "GP"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["RaidButton" .. i .. "PR"]:SetTextColor(colour.r, colour.g, colour.b);
		end		
	end
end

function CEPGP_UpdateVersionScrollBar()
	CEPGP_Info.LastRun.VersionSB = GetTime();
	local call = CEPGP_Info.LastRun.VersionSB;
	local search = CEPGP_Info.Version.ListSearch;
	local name, classFile, class, colour, version;
	local showOffline = CEPGP_version:GetAttribute("offline");
	local tempTable = {};
	local kids = {_G["CEPGP_version_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	
	local function IsRaidMember(player)
		if call ~= CEPGP_Info.LastRun.VersionSB then return; end
		if not UnitInParty("player") and not IsInRaid() then return; end
		for i = 1, #CEPGP_Info.Raid.Roster do
			if CEPGP_Info.Raid.Roster[i][1] == player then
				return true;
			end
		end
		
		return false;
	end
	
	local function IsGuildMember(player)
		if not IsInGuild() then return; end
				
		if CEPGP_Info.Guild.Roster[player] then
			return true;
		end
	end
		
	for name, data in pairs(CEPGP_Info.Version.List) do
		if data[1] ~= "Offline" or (showOffline and data[1] == "Offline") then
			if search == "RAID" and IsRaidMember(name) or search == "GUILD" and IsGuildMember(name) then	--Nested these statements for efficiency sake
				local entry = {
					[1] = name,
					[2] = data[1],
					[3] = data[2],
					[4] = data[3]
				};
				table.insert(tempTable, entry);
			end
		end
	end
	
	tempTable = CEPGP_tSort(tempTable, CEPGP_Info.Sorting.Version[1], CEPGP_Info.Sorting.Version[2]);
	
	
	for i = 1, #tempTable do
		if call ~= CEPGP_Info.LastRun.VersionSB then return; end
		if not _G["versionButton" .. i] then
			local frame = CreateFrame('Button', "versionButton" .. i, _G["CEPGP_version_scrollframe_container"], "versionButtonTemplate"); -- Creates version frames if needed
			if i > 1 then
				_G["versionButton" .. i]:SetPoint("TOPLEFT", _G["versionButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["versionButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_version_scrollframe_container"], "TOPLEFT", 5, -6);
			end
		end
		_G["versionButton" .. i]:Show();
		if search == "GUILD" then
			local name = tempTable[i][1];
			local classFile = tempTable[i][4];
			local colour = CEPGP_Info.ClassColours[classFile];
			if not colour then
				colour = {
				r = 1,
				g = 1,
				b = 1
			};
			end
			_G["versionButton" .. i .. "name"]:SetText(tempTable[i][1]);
			_G["versionButton" .. i .. "name"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["versionButton" .. i .. "version"]:SetText(tempTable[i][2]);
			_G["versionButton" .. i .. "version"]:SetTextColor(colour.r, colour.g, colour.b);
		else
			for x = 1, GetNumGroupMembers() do
				if tempTable[i][1] == GetRaidRosterInfo(x) then
					name = tempTable[i][1];
					version = tempTable[i][2];
					class = tempTable[i][3];
					classFile = tempTable[i][4];
					local colour = CEPGP_Info.ClassColours[classFile];
					if not colour then
						colour = {
						r = 1,
						g = 1,
						b = 1
					};
					end
					_G["versionButton" .. i .. "name"]:SetText(name);
					_G["versionButton" .. i .. "name"]:SetTextColor(colour.r, colour.g, colour.b);
					_G["versionButton" .. i .. "version"]:SetText(version);
					_G["versionButton" .. i .. "version"]:SetTextColor(colour.r, colour.g, colour.b);
				end
			end
		end
	end
end

function CEPGP_UpdateOverrideScrollBar()
	local tempTable = {};
	local items = {};
	local compTable = {};
	local kids = {_G["CEPGP_override_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	for k, v in pairs(CEPGP.Overrides) do
		local name = GetItemInfo(k);
		if name then
			table.insert(items, name);
			compTable[name] = k;
		else
			table.insert(items, k);
			compTable[k] = k;
		end
	end
	table.sort(items);
	for i, v in ipairs(items) do
		tempTable[#tempTable+1] = {
			[1] = compTable[v],
			[2] = CEPGP.Overrides[compTable[v]]
		}
	end
	for i = 1, #tempTable do
		if not _G["overrideButton" ..  i] then
			local frame = CreateFrame('Button', "overrideButton" .. i, _G["CEPGP_override_scrollframe_container"], "lootOverrideButtonTemplate"); -- Creates override frames if needed
			if i > 1 then
				_G["overrideButton" .. i]:SetPoint("TOPLEFT", _G["overrideButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["overrideButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_override_scrollframe_container"], "TOPLEFT", 5, -6);
			end
		end
		_G["overrideButton" .. i]:Show();
		_G["overrideButton" .. i .. "item"]:SetText(tempTable[i][1]);
		_G["overrideButton" .. i .. "GP"]:SetText(tempTable[i][2]);
		_G["overrideButton" .. i .. "GP"]:SetTextColor(1, 1, 1);
	end
end

function CEPGP_UpdateTrafficScrollBar()
	CEPGP_Info.LastRun.TrafficSB = GetTime();
	local lastRun = CEPGP_Info.LastRun.TrafficSB;
	local kids = {_G["CEPGP_traffic_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		if lastRun ~= CEPGP_Info.LastRun.TrafficSB then return; end
		child:Hide();
	end
	local search = CEPGP_traffic_search:GetText();
	local results = {};
	local matches = 1;
	
	for i = 1, #CEPGP.Traffic do
		local name, issuer, action, EPB, EPA, GPB, GPA, item, tStamp, ID, GUID = CEPGP.Traffic[i][1] or "", CEPGP.Traffic[i][2] or "", CEPGP.Traffic[i][3] or "", CEPGP.Traffic[i][4] or "", CEPGP.Traffic[i][5] or "", CEPGP.Traffic[i][6] or "", CEPGP.Traffic[i][7] or "", CEPGP.Traffic[i][8] or "", CEPGP.Traffic[i][9], CEPGP.Traffic[i][10], CEPGP.Traffic[i][11];
		if not tStamp then
			tStamp = "";
		end
		if search ~= "" and (string.find(string.lower(name), string.lower(search)) or
			string.find(string.lower(issuer), string.lower(search)) or
			string.find(string.lower(action), string.lower(search)) or
			string.find(string.lower(EPB), string.lower(search)) or
			string.find(string.lower(EPA), string.lower(search)) or
			string.find(string.lower(GPB), string.lower(search)) or
			string.find(string.lower(GPA), string.lower(search)) or
			string.find(string.lower(item), string.lower(search)) or
			string.find(string.lower(tStamp), string.lower(search))) then
			results[matches] = {
				[1] = name,
				[2] = issuer,
				[3] = action,
				[4] = EPB,
				[5] = EPA,
				[6] = GPB,
				[7] = GPA,
				[8] = item,
				[9] = tStamp,
				[10] = ID,
				[11] = GUID,
				[12] = i	--	entry ID
			};
			matches = matches + 1;
		elseif search == "" then
			results[matches] = {
				[1] = name,
				[2] = issuer,
				[3] = action,
				[4] = EPB,
				[5] = EPA,
				[6] = GPB,
				[7] = GPA,
				[8] = item,
				[9] = tStamp,
				[10] = ID,
				[11] = GUID,
				[12] = i	--	entry ID3
			};
			matches = matches + 1;
		end
	end
	local temp = {};
	for i = matches, 0, -1 do
		table.insert(temp, results[i]);
	end
	results = {};
	for i = CEPGP_Info.TrafficScope, math.min(CEPGP_Info.TrafficScope+499, #CEPGP.Traffic) do
		table.insert(results, temp[i]);
	end
	temp = {};
	for i = #results, 0, -1 do
		table.insert(temp, results[i]);
	end
	results = temp;
	CEPGP_traffic_display:SetText("Showing Entries: " .. CEPGP_Info.TrafficScope .. " - " .. math.min(CEPGP_Info.TrafficScope+499, #CEPGP.Traffic));
	CEPGP_traffic_display:SetPoint("BOTTOMRIGHT", -25, 20);
	local i = #results;
	
	if #results > 0 then
		C_Timer.NewTicker(0.0001, function()
			if search ~= CEPGP_traffic_search:GetText() or lastRun ~= CEPGP_Info.LastRun.TrafficSB then return; end -- Terminates the previous search if the query changes
			local frame;
			if _G["TrafficButton" .. i] then
				frame = _G["TrafficButton" .. i];
			else
				frame = CreateFrame('Button', "TrafficButton" .. i, _G["CEPGP_traffic_scrollframe_container"], "trafficButtonTemplate");
			end
			if i ~= #results then
				_G["TrafficButton" .. i]:SetPoint("TOPLEFT", _G["TrafficButton" .. i+1], "BOTTOMLEFT", 0, -2);
			else
				_G["TrafficButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_traffic_scrollframe_container"], "TOPLEFT", 7.5, -10);
			end
			frame:SetAttribute("id", results[i][12]);
			local _, class = CEPGP_getPlayerClass(results[i][1]);
			local _, issuerClass = CEPGP_getPlayerClass(results[i][2]);
			local colour, issuerColour = class, issuerClass;
			if not class then
				colour = {
					r = 1,
					g = 1,
					b = 1
				};
			end
			if not issuerClass then
				issuerColour = {
					r = 1,
					g = 1,
					b = 1
				};
			end
			_G["TrafficButton" .. i]:Show();
			_G["TrafficButton" .. i .. "Name"]:SetText(results[i][1]);
			_G["TrafficButton" .. i .. "Name"]:SetTextColor(colour.r, colour.g, colour.b);
			_G["TrafficButton" .. i .. "Issuer"]:SetText(results[i][2]);
			_G["TrafficButton" .. i .. "Issuer"]:SetTextColor(issuerColour.r, issuerColour.g, issuerColour.b);
			_G["TrafficButton" .. i .. "Action"]:SetText(results[i][3]);
			_G["TrafficButton" .. i .. "EPBefore"]:SetText(results[i][4]);
			_G["TrafficButton" .. i .. "EPAfter"]:SetText(results[i][5]);
			_G["TrafficButton" .. i .. "GPBefore"]:SetText(results[i][6]);
			_G["TrafficButton" .. i .. "GPAfter"]:SetText(results[i][7]);
			if results[i][9] ~= "" then
				local temp = i;
				_G["TrafficButton" .. temp]:SetScript('OnEnter', function()
					GameTooltip:SetOwner(_G["TrafficButton" .. temp], "ANCHOR_TOPLEFT");
					GameTooltip:SetText(date("Time: %I:%M%p\nDate: %a, %d %B %Y", results[temp][9]));
				end);
				_G["TrafficButton" .. i]:SetScript('OnLeave', function()
					GameTooltip:Hide();
				end);
			else
				local temp = i;
				_G["TrafficButton" .. temp]:SetScript('OnEnter', function()
					GameTooltip:SetOwner(_G["TrafficButton" .. temp], "ANCHOR_TOPLEFT");
					GameTooltip:SetText("No time data recorded for this entry");
				end);
				_G["TrafficButton" .. i]:SetScript('OnLeave', function()
					GameTooltip:Hide();
				end);
			end
			if (results[i][8] and strfind(results[i][8], "item")) or tonumber(results[i][8]) then --Accommodates for earlier versions when malformed information may be stored in the item index of the traffic log
				_G["TrafficButton" .. i .. "ItemName"]:SetText(results[i][8]);
				local _, link = GetItemInfo(results[i][8]);
				if link then
					_G["TrafficButton" .. i .. "Item"]:SetScript('OnClick', function() SetItemRef(link) end);
				else
					local id;
					if string.find(tostring(results[i][8]), "item:") then
						id = string.sub(tostring(results[i][8]), string.find(results[i][8], ":")+1);
						id = tonumber(string.sub(id, 0, string.find(id, ":")-1));
					end
					if CEPGP_itemExists(id) then
						local queryID = id;
						local index = i;
						local newItem = Item:CreateFromItemID(id);
						newItem:ContinueOnItemLoad(function()
							
							_, link = GetItemInfo(queryID);
							_G["TrafficButton" .. index .. "Item"]:SetScript('OnClick', function() SetItemRef(link) end);
							
						end);
					else
						_G["TrafficButton" .. i .. "ItemName"]:SetText("");
						_G["TrafficButton" .. i .. "Item"]:SetScript('OnClick', function() end);
					end
				end
			else
				_G["TrafficButton" .. i .. "ItemName"]:SetText("");
				_G["TrafficButton" .. i .. "Item"]:SetScript('OnClick', function() end);
			end
			if not results[i][10] or not results[i][11] or (tonumber(results[i][9]) == tonumber(results[i][10])) then
				_G["TrafficButton" .. i .. "Share"]:Hide();
			elseif results[i][10] and results[i][11] then
				_G["TrafficButton" .. i .. "Share"]:Show();				
			end
			i = i - 1;
		end, #results);
	end
end

function CEPGP_UpdateStandbyScrollBar()
	local tempTable = {};
	local kids = {_G["CEPGP_standby_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	CEPGP_tSort(CEPGP.Standby.Roster, CEPGP_Info.Sorting.Standby[1], CEPGP_Info.Sorting.Standby[2]);
	for i = 1, CEPGP_ntgetn(CEPGP.Standby.Roster) do
		local frame;
		
		if _G["StandbyButton" .. i] then
			frame = _G["StandbyButton" .. i];
		else
			frame = CreateFrame('Button', "StandbyButton" .. i, _G["CEPGP_standby_scrollframe_container"], "StandbyButtonTemplate");
			if i > 1 then
				_G["StandbyButton" .. i]:SetPoint("TOPLEFT", _G["StandbyButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["StandbyButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_standby_scrollframe_container"], "TOPLEFT", 0, -10);
			end
			
			local frameName 	= _G[frame:GetName() .. "Info"];
			local frameClass 	= _G[frame:GetName() .. "Class"];
			local frameRank 	= _G[frame:GetName() .. "Rank"];
			local frameEP 		= _G[frame:GetName() .. "EP"];
			local frameGP 		= _G[frame:GetName() .. "GP"];
			local framePR 		= _G[frame:GetName() .. "PR"];
			
			local width = CEPGP_standby_scrollframe_container:GetWidth();
			
			frame:SetWidth(width);
			frameName:SetPoint("LEFT", frame, "LEFT");
			frameClass:SetPoint("LEFT", frameName, "LEFT", width/6, 0);
			frameRank:SetPoint("LEFT", frameClass, "LEFT", width/5, 0);
			frameEP:SetPoint("LEFT", frameRank, "LEFT", width/5, 0);
			frameGP:SetPoint("LEFT", frameEP, "LEFT", width/7, 0);
			framePR:SetPoint("LEFT", frameGP, "LEFT", width/7, 0);
			
		end
		local _, _, rank, rankIndex, oNote, _, classFile = CEPGP_getGuildInfo(CEPGP.Standby.Roster[i][1]);
		local online = true;
		local name = CEPGP.Standby.Roster[i][1];
		local index = CEPGP_getIndex(name);
		local EP, GP = CEPGP_getEPGP(name, index);
		if not EP then EP = 0; end
		if not GP then GP = CEPGP.GP.Min; end
		if name and index then
			_, _, _, _, _, _, _, _, online = GetGuildRosterInfo(index);
		else
			online = false;
		end
		tempTable[i] = {
			[1] = CEPGP.Standby.Roster[i][1], --name
			[2] = CEPGP.Standby.Roster[i][2], --class
			[3] = CEPGP.Standby.Roster[i][3], --rank
			[4] = CEPGP.Standby.Roster[i][4], --rankIndex
			[5] = EP, --EP
			[6] = GP, --GP
			[7] = math.floor((tonumber(EP)*100/tonumber(GP)))/100,
			[8] = CEPGP.Standby.Roster[i][8], --ClassFile
			[9] = online --Online
		};
		local colour;
		if tempTable[i][9] then
			colour = CEPGP_Info.ClassColours[tempTable[i][8]];
			_G["StandbyButton" .. i]:SetScript('OnEnter', function() end);
		else
			colour = {
				r = 0.62,
				g = 0.62,
				b = 0.62
			};
			_G["StandbyButton" .. i]:SetScript('OnEnter', function()
				GameTooltip:SetOwner(_G["StandbyButton" .. i], "ANCHOR_TOPLEFT");
				GameTooltip:SetText("Player Offline");
			end);
			_G["StandbyButton" .. i]:SetScript('OnLeave', function()
				GameTooltip:Hide()
			end);
		end
		if not colour then
			colour = {
			r = 1,
			g = 1,
			b = 1
		};
		end
		_G["StandbyButton" .. i]:Show();
		_G["StandbyButton" .. i .. "Info"]:SetText(tempTable[i][1]);
		_G["StandbyButton" .. i .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyButton" .. i .. "Class"]:SetText(tempTable[i][2]);
		_G["StandbyButton" .. i .. "Class"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyButton" .. i .. "Rank"]:SetText(tempTable[i][3]);
		_G["StandbyButton" .. i .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyButton" .. i .. "EP"]:SetText(tempTable[i][5]);
		_G["StandbyButton" .. i .. "EP"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyButton" .. i .. "GP"]:SetText(tempTable[i][6]);
		_G["StandbyButton" .. i .. "GP"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyButton" .. i .. "PR"]:SetText(tempTable[i][7]);
		_G["StandbyButton" .. i .. "PR"]:SetTextColor(colour.r, colour.g, colour.b);
	end
end

function CEPGP_UpdateAttendanceScrollBar()
	local kids = {_G["CEPGP_attendance_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	kids = {_G["CEPGP_attendance_scrollframe_standby_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	local tempTable, standbyTable = {}, {};
	local name, class, classFile, rank, rankIndex, index, total, week, fn, month, twoMon, threeMon;
	local size;
	local sbCount = 1;
	local count = 1;
	if CEPGP_Info.Attendance.SelectedSnapshot then 
		size = #CEPGP.Attendance[CEPGP_Info.Attendance.SelectedSnapshot]-1;
	end
	if CEPGP_Info.Attendance.SelectedSnapshot then
		for i = 1, size do
			local standby = false;
			if CEPGP_Info.Attendance.SelectedSnapshot then
				if type(CEPGP.Attendance[CEPGP_Info.Attendance.SelectedSnapshot][i+1]) == "table" then
					name = CEPGP.Attendance[CEPGP_Info.Attendance.SelectedSnapshot][i+1][1];
					standby = CEPGP.Attendance[CEPGP_Info.Attendance.SelectedSnapshot][i+1][2];
				else
					name = CEPGP.Attendance[CEPGP_Info.Attendance.SelectedSnapshot][i+1];
				end
			else
				name = CEPGP_indexToName(i);
			end
			total, week, fn, month, twoMon, threeMon = CEPGP_calcAttendance(name);
			index, class, rank, rankIndex, _, _, classFile = CEPGP_getGuildInfo(name);
			if not index then
				rank = "Non-Guild Member";
				rankIndex = 11;
			end
			if standby then
				standbyTable[sbCount] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = total,
					[5] = tostring(week),
					[6] = tostring(fn),
					[7] = tostring(month),
					[8] = tostring(twoMon),
					[9] = tostring(threeMon),
					[10] = classFile,
					[11] = standby,
					[12] = rankIndex
				}
				sbCount = sbCount + 1;
			else
				tempTable[count] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = total,
					[5] = tostring(week),
					[6] = tostring(fn),
					[7] = tostring(month),
					[8] = tostring(twoMon),
					[9] = tostring(threeMon),
					[10] = classFile,
					[11] = false,
					[12] = rankIndex
				}
				count = count + 1;
			end
		end
	else
		for name, v in pairs(CEPGP_Info.Guild.Roster) do
			total, week, fn, month, twoMon, threeMon = CEPGP_calcAttendance(name);
			index, class, rank, rankIndex, _, _, classFile = CEPGP_getGuildInfo(name);
			if not index then
				rank = "Non-Guild Member";
			end
			if standby then
				standbyTable[sbCount] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = total,
					[5] = tostring(week),
					[6] = tostring(fn),
					[7] = tostring(month),
					[8] = tostring(twoMon),
					[9] = tostring(threeMon),
					[10] = classFile,
					[11] = standby,
					[12] = rankIndex
				}
				sbCount = sbCount + 1;
			else
				tempTable[count] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = total,
					[5] = tostring(week),
					[6] = tostring(fn),
					[7] = tostring(month),
					[8] = tostring(twoMon),
					[9] = tostring(threeMon),
					[10] = classFile,
					[11] = false,
					[12] = rankIndex
				}
				count = count + 1;
			end
		end
	end
	
	tempTable = CEPGP_tSort(tempTable, CEPGP_Info.Sorting.Attendance[1], CEPGP_Info.Sorting.Attendance[2]);
	standbyTable = CEPGP_tSort(standbyTable, CEPGP_Info.Sorting.Standby[1], CEPGP_Info.Sorting.Standby[2]);

	local adjust = false;
	if #standbyTable > 0 then
		adjust = true;
	end
	if adjust then
		_G["CEPGP_attendance_scrollframe"]:SetSize(600, 175);
		_G["CEPGP_attendance_scrollframe_container"]:SetSize(600, 175);
		_G["CEPGP_attendance_scrollframe"]:SetPoint("TOPLEFT", "CEPGP_attendance_header_name", "BOTTOMLEFT", 10, 0);
		_G["CEPGP_attendance_scrollframe_standby"]:Show();
		_G["CEPGP_attendance_scrollframe_standby_container"]:Show();
		_G["CEPGP_attendance_standby_text"]:Show();
	else
		_G["CEPGP_attendance_scrollframe"]:SetSize(600, 315);
		_G["CEPGP_attendance_scrollframe_container"]:SetSize(600, 315);
		_G["CEPGP_attendance_scrollframe"]:SetPoint("RIGHT", "CEPGP_attendance", "RIGHT", -35, -20);
		_G["CEPGP_attendance_scrollframe_standby"]:Hide();
		_G["CEPGP_attendance_scrollframe_standby_container"]:Hide();
		_G["CEPGP_attendance_standby_text"]:Hide();
	end
	local totals = {CEPGP_calcAttIntervals()};
	if #CEPGP.Attendance then
		_G["CEPGP_attendance_header_total"]:SetText("Total Snapshots Recorded: " .. #CEPGP.Attendance);
	else
		_G["CEPGP_attendance_header_total"]:SetText("Total Snapshots Recorded: 0");
	end
	
	size = #tempTable;
	for i = 1, size do
		local avg, colour;
		if #CEPGP.Attendance == 0 then
			avg = 1;
		else
			avg = tempTable[i][4]/#CEPGP.Attendance;
			avg = math.floor(avg*100)/100;
		end
		if tempTable[i][10] then
			colour = CEPGP_Info.ClassColours[tempTable[i][10]];
		end
		if not colour then
			colour = {
				r = 0.5,
				g = 0,
				b = 0
			};
		end
		if tempTable[i][5] == "nil" then tempTable[i][5] = "0"; end;
		if tempTable[i][6] == "nil" then tempTable[i][6] = "0"; end;
		if tempTable[i][7] == "nil" then tempTable[i][7] = "0"; end;
		if tempTable[i][8] == "nil" then tempTable[i][8] = "0"; end;
		if tempTable[i][9] == "nil" then tempTable[i][9] = "0"; end;
		if not _G["AttendanceButton" .. i] then
			local frame = CreateFrame('Button', "AttendanceButton" .. i, _G["CEPGP_attendance_scrollframe_container"], "AttendanceButtonTemplate");
			if i > 1 then
				_G["AttendanceButton" .. i]:SetPoint("TOPLEFT", _G["AttendanceButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["AttendanceButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_attendance_scrollframe_container"], "TOPLEFT", 0, -10);
			end
		end
		_G["AttendanceButton" .. i]:Show();
		_G["AttendanceButton" .. i .. "Info"]:SetText(tempTable[i][1]);
		_G["AttendanceButton" .. i .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["AttendanceButton" .. i .. "Rank"]:SetText(tempTable[i][3]);
		_G["AttendanceButton" .. i .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);		
		if totals[1] == 0 then
			_G["AttendanceButton" .. i .. "Total"]:SetText(tempTable[i][4] .. " (" .. avg*100 .. "%)");
			_G["AttendanceButton" .. i .. "Total"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Total"]:SetText(tempTable[i][4] .. " (" .. avg*100 .. "%)");
			_G["AttendanceButton" .. i .. "Total"]:SetTextColor(1-avg,avg/1,0);
		end
		_G["AttendanceButton" .. i .. "Int7"]:SetText(tempTable[i][5] .. "/" .. totals[1]);
		if totals[1] == 0 then
			_G["AttendanceButton" .. i .. "Int7"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Int7"]:SetTextColor(1-(tempTable[i][5]/totals[1]), (tempTable[i][5]/totals[1])/1, 0);
		end
		_G["AttendanceButton" .. i .. "Int14"]:SetText(tempTable[i][6] .. "/" .. totals[2]);
		if totals[2] == 0 then
			_G["AttendanceButton" .. i .. "Int14"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Int14"]:SetTextColor(1-(tempTable[i][6]/totals[2]), (tempTable[i][6]/totals[2])/1, 0);
		end
		_G["AttendanceButton" .. i .. "Int30"]:SetText(tempTable[i][7] .. "/" .. totals[3]);
		if totals[3] == 0 then
			_G["AttendanceButton" .. i .. "Int30"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Int30"]:SetTextColor(1-(tempTable[i][7]/totals[3]), (tempTable[i][7]/totals[3])/1, 0);
		end		
		_G["AttendanceButton" .. i .. "Int60"]:SetText(tempTable[i][8] .. "/" .. totals[4]);
		if totals[4] == 0 then
			_G["AttendanceButton" .. i .. "Int60"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Int60"]:SetTextColor(1-(tempTable[i][8]/totals[4]), (tempTable[i][8]/totals[4])/1, 0);
		end
		_G["AttendanceButton" .. i .. "Int90"]:SetText(tempTable[i][9] .. "/" .. totals[5]);
		if totals[5] == 0 then
			_G["AttendanceButton" .. i .. "Int90"]:SetTextColor(0, 1, 0);
		else
			_G["AttendanceButton" .. i .. "Int90"]:SetTextColor(1-(tempTable[i][9]/totals[5]), (tempTable[i][9]/totals[5])/1, 0);
		end
	end
	
			--[[ STANDBY ]]--
	size = #standbyTable;
	for i = 1, size do
		local colour;
		local avg = standbyTable[i][4]/#CEPGP.Attendance;
		avg = math.floor(avg*100)/100;
		if standbyTable[i][10] then
			colour = CEPGP_Info.ClassColours[standbyTable[i][10]];
		end
		if not colour then
			colour = {
				r = 0.5,
				g = 0,
				b = 0
			};
		end
		if standbyTable[i][5] == "nil" then standbyTable[i][5] = "0"; end;
		if standbyTable[i][6] == "nil" then standbyTable[i][6] = "0"; end;
		if standbyTable[i][7] == "nil" then standbyTable[i][7] = "0"; end;
		if standbyTable[i][8] == "nil" then standbyTable[i][8] = "0"; end;
		if standbyTable[i][9] == "nil" then standbyTable[i][9] = "0"; end;
		if not _G["StandbyAttendanceButton" .. i] then
			local frame = CreateFrame('Button', "StandbyAttendanceButton" .. i, _G["CEPGP_attendance_scrollframe_standby_container"], "AttendanceButtonTemplate");
			if i > 1 then
				_G["StandbyAttendanceButton" .. i]:SetPoint("TOPLEFT", _G["StandbyAttendanceButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["StandbyAttendanceButton" .. i]:SetPoint("TOPLEFT", _G["CEPGP_attendance_scrollframe_standby_container"], "TOPLEFT", 0, -10);
			end
		end
		_G["StandbyAttendanceButton" .. i]:Show();
		_G["StandbyAttendanceButton" .. i .. "Info"]:SetText(standbyTable[i][1]);
		_G["StandbyAttendanceButton" .. i .. "Info"]:SetTextColor(colour.r, colour.g, colour.b);
		_G["StandbyAttendanceButton" .. i .. "Rank"]:SetText(standbyTable[i][3]);
		_G["StandbyAttendanceButton" .. i .. "Rank"]:SetTextColor(colour.r, colour.g, colour.b);		
		_G["StandbyAttendanceButton" .. i .. "Total"]:SetText(standbyTable[i][4] .. " (" .. avg*100 .. "%)");
		_G["StandbyAttendanceButton" .. i .. "Total"]:SetTextColor(1-avg,avg/1,0);
		_G["StandbyAttendanceButton" .. i .. "Int7"]:SetText(standbyTable[i][5] .. "/" .. totals[1]);
		if totals[1] == 0 then
			_G["StandbyAttendanceButton" .. i .. "Int7"]:SetTextColor(1-(standbyTable[i][5]/totals[1]), 1, 0);
		else
			_G["StandbyAttendanceButton" .. i .. "Int7"]:SetTextColor(1-(standbyTable[i][5]/totals[1]), (standbyTable[i][5]/totals[1])/1, 0);
		end
		_G["StandbyAttendanceButton" .. i .. "Int14"]:SetText(standbyTable[i][6] .. "/" .. totals[2]);
		if totals[2] == 0 then
			_G["StandbyAttendanceButton" .. i .. "Int14"]:SetTextColor(1-(standbyTable[i][6]/totals[2]), 1, 0);
		else
			_G["StandbyAttendanceButton" .. i .. "Int14"]:SetTextColor(1-(standbyTable[i][6]/totals[2]), (standbyTable[i][6]/totals[2])/1, 0);
		end
		_G["StandbyAttendanceButton" .. i .. "Int30"]:SetText(standbyTable[i][7] .. "/" .. totals[3]);
		if totals[3] == 0 then
			_G["StandbyAttendanceButton" .. i .. "Int30"]:SetTextColor(1-(standbyTable[i][7]/totals[3]), 1, 0);
		else
			_G["StandbyAttendanceButton" .. i .. "Int30"]:SetTextColor(1-(standbyTable[i][7]/totals[3]), (standbyTable[i][7]/totals[3])/1, 0);
		end		
		_G["StandbyAttendanceButton" .. i .. "Int60"]:SetText(standbyTable[i][8] .. "/" .. totals[4]);
		if totals[4] == 0 then
			_G["StandbyAttendanceButton" .. i .. "Int60"]:SetTextColor(1-(standbyTable[i][8]/totals[4]), 1, 0);
		else
			_G["StandbyAttendanceButton" .. i .. "Int60"]:SetTextColor(1-(standbyTable[i][8]/totals[4]), (standbyTable[i][8]/totals[4])/1, 0);
		end
		_G["StandbyAttendanceButton" .. i .. "Int90"]:SetText(standbyTable[i][9] .. "/" .. totals[5]);
		if totals[5] == 0 then
			_G["StandbyAttendanceButton" .. i .. "Int90"]:SetTextColor(1-(standbyTable[i][9]/totals[5]), 1, 0);
		else
			_G["StandbyAttendanceButton" .. i .. "Int90"]:SetTextColor(1-(standbyTable[i][9]/totals[5]), (standbyTable[i][9]/totals[5])/1, 0);
		end
	end
end

function CEPGP_UpdateAltScrollBar()
	local tempTable = {};
	for name, _ in pairs(CEPGP.Alt.Links) do
		table.insert(tempTable, name);
	end
	table.sort(tempTable);
	
	for _, main in ipairs(tempTable) do
		local temp = {};
		
		for index, alt in ipairs(CEPGP.Alt.Links[main]) do
			table.insert(temp, alt);
		end
		
		table.sort(temp);
		tempTable[main] = temp;
	end
	
	local kids = {_G["CEPGP_options_alt_mangement_ScrollFrame_Container"]:GetChildren()};
	for index, child in ipairs(kids) do
		child:Hide();
	end
	for i, main in ipairs(tempTable) do
		local main = tempTable[i];
		local class = select(7, CEPGP_getGuildInfo(main));
		local frame;
		if #tempTable > 0 then
			if not _G["AltFrame" .. i] then
				frame = CreateFrame('Button', "AltFrame" .. i, _G["CEPGP_options_alt_mangement_ScrollFrame_Container"], "AltFrameTemplate");
			else
				frame = _G["AltFrame" .. i];
			end
			
			local colour = CEPGP_Info.ClassColours[class];
			if not colour then
				colour = {
				r = 1,
				g = 1,
				b = 1
			};
			end
			
			local altText;
			
			for index, name in ipairs(tempTable[main]) do
				local altClass = select(7, CEPGP_getGuildInfo(name));
				if index == 1 then
					altText = CEPGP_encodeClassString(altClass, name);
				else
					_G[frame:GetName() .. "AltName"]:SetText(altText .. ", " .. CEPGP_encodeClassString(altClass, name));
					if _G[frame:GetName() .. "AltName"]:GetStringWidth() > 400 then
						altText = altText .. ",\n" .. CEPGP_encodeClassString(altClass, name);
					else
						altText = altText .. ", " .. CEPGP_encodeClassString(altClass, name);
					end
				end
			end
			
			frame:Show();
			_G[frame:GetName() .. "MainName"]:SetText(main);
			_G[frame:GetName() .. "MainName"]:SetTextColor(colour.r, colour.g, colour.b);
			_G[frame:GetName() .. "AltName"]:SetText(altText);
			frame:SetHeight(_G[frame:GetName() .. "AltName"]:GetStringHeight());
			
			if i > 1 then
				frame:SetPoint("TOPLEFT", _G["AltFrame" .. i-1], "BOTTOMLEFT", 0, -20);
			else
				frame:SetPoint("TOPLEFT", _G["CEPGP_options_alt_mangement_ScrollFrame_Container"], "TOPLEFT", 0, -10);
			end
		end
	end
end

function CEPGP_UpdateKeywordScrollBar()
	local kids = {_G["CEPGP_loot_options_keywords_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
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
		
	for i, v in ipairs(keywords) do
		local label, key, disc = v[1], v[2], v[3];
		if not _G["keywordButton" .. i] then
			local frame = CreateFrame('Button', 'keywordButton' .. i, _G["CEPGP_loot_options_keywords_scrollframe_container"], "KeywordButtonTemplate");
			if i > 1 then
				_G["keywordButton" .. i]:SetPoint("TOPLEFT", _G["keywordButton" .. i-1], "BOTTOMLEFT", 0, -2);
			else
				_G["keywordButton" .. i]:SetPoint("TOP", _G["CEPGP_loot_options_keywords_scrollframe_container"], "TOP", 0, -10);
			end
		end
		_G["keywordButton" .. i]:Show();
		_G["keywordButton" .. i .. "Label"]:SetText(label);
		_G["keywordButton" .. i .. "Keyword"]:SetText(key);
		_G["keywordButton" .. i .. "Discount"]:SetText(disc);
		_G["keywordButton" .. i .. "Label"]:SetTextColor(1, 1, 1);
		_G["keywordButton" .. i .. "Keyword"]:SetTextColor(1, 1, 1);
		_G["keywordButton" .. i .. "Discount"]:SetTextColor(1, 1, 1);
	end
end

function CEPGP_UpdateLogScrollBar()
	
	local call = CEPGP_Info.LastRun.LogSB;
	local quit = false;

	local logs = {};
	for _, data in ipairs(CEPGP_Info.Logs) do
		table.insert(logs, data);
	end
	
	local frame = CEPGP_log_container;
	local str = "";
	CEPGP_log_container:SetText("Compiling message log. Please wait...");
	for i = #logs, math.max(1, #logs-500), -1 do
		if call ~= CEPGP_Info.LastRun.LogSB then
			timer._remainingIterations = 1;
			return;
		end
		
		local absTime =			logs[i][1] or "|cFFFF0000nil|r";
		local msgType =			logs[i][2] or "|cFFFF0000nil|r";
		local source =			logs[i][3] or "|cFFFF0000nil|r";
		local destination =		logs[i][4] or "Channel-Wide";
		local content =			logs[i][5] or "|cFFFF0000nil|r";
		local channel = 		logs[i][6] or "|cFFFF0000nil|r";

		local state = (msgType == "queued" and "|cFFFFFFFFQueued|r") or
						(msgType == "attempt" and "|cFFF5B342Attempting|r") or
						(msgType == "abandoned" and "|cFFFF0000Abandoned|r") or
						(msgType == "received" and "|cFF03A9FCReceived|r") or
						(msgType == "sent" and "|cFF00FF00Sent|r") or
						(msgType == "whisper" and "|cFF7A00ABUntraceable|r") or
						(msgType == "error" and "cFFFF0000Error|r");
		str = str .. date("%H:%M:%S", absTime) .. ": Source: " .. source .. ", Scope: " .. destination .. ", Channel: " .. channel .. ", State: " .. state .. "\nContent: " .. content .. "\n\n";
	end
	CEPGP_log_container:SetText(str);
	CEPGP_log_num:SetText("Showing last " .. #logs .. " messages");
end

function CEPGP_UpdateTradeableScrollBar(itemPool)
	local kids = {_G["CEPGP_bag_items_scrollframe_container"]:GetChildren()};
	for _, child in ipairs(kids) do
		child:Hide();
	end
	for i = 1, #itemPool do
		local frame;
		if not _G["CEPGPTradeableItem" .. i] then
			frame = CreateFrame('Button', "CEPGPTradeableItem" .. i, _G["CEPGP_bag_items_scrollframe_container"], "CEPGPBagItemTemplate");
			if i == 1 then
				_G["CEPGPTradeableItem" .. i]:SetPoint("TOPLEFT", _G["CEPGP_bag_items_scrollframe_container"], "TOPLEFT", 0, -10);
			else
				_G["CEPGPTradeableItem" .. i]:SetPoint("TOPLEFT", _G["CEPGPTradeableItem" .. i-1], "BOTTOMLEFT", 0, -2);
			end
		end
		_G["CEPGPTradeableItem" .. i]:SetAttribute('itemID', itemPool[i][1]);
		_G["CEPGPTradeableItem" .. i]:SetAttribute('itemGUID', itemPool[i][2]);
		
		local name, link, rarity, tex = itemPool[i][3], itemPool[i][4], itemPool[i][5], itemPool[i][6];
		
		_G["CEPGPTradeableItem" .. i .. "_name_text"]:SetText(link);
		_G["CEPGPTradeableItem" .. i .. "_icon_tex"]:SetTexture(tex);
	end
end