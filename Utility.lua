local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP");

function CEPGP_initialise()
	_, _, _, CEPGP_Info.ElvUI = GetAddOnInfo("ElvUI");
	if not CEPGP_Info.ElvUI then CEPGP_Info.ElvUI = GetAddOnInfo("TukUI"); end
	_G["CEPGP_version_number"]:SetText("Running Version: " .. CEPGP_Info.Version.Number .. " " .. CEPGP_Info.Version.Build);
	
	C_ChatInfo.RegisterAddonMessagePrefix("CEPGP");
	tinsert(UISpecialFrames, "CEPGP_frame");
	tinsert(UISpecialFrames, "CEPGP_context_popup");
	tinsert(UISpecialFrames, "CEPGP_save_guild_logs");
	tinsert(UISpecialFrames, "CEPGP_restore_guild_logs");
	tinsert(UISpecialFrames, "CEPGP_settings_import");
	tinsert(UISpecialFrames, "CEPGP_override");
	tinsert(UISpecialFrames, "CEPGP_traffic");
	tinsert(UISpecialFrames, "CEPGP_changelog");
	tinsert(UISpecialFrames, "CEPGP_license");
	tinsert(UISpecialFrames, "CEPGP_raid_modifiers");
	tinsert(UISpecialFrames, "CEPGP_log");
	
	
	CEPGP_initSavedVars();
	CEPGP_initInterfaceOptions();
	hooksecurefunc("ChatFrame_OnHyperlinkShow", CEPGP_addGPHyperlink);
	hooksecurefunc("GameTooltip_UpdateStyle", CEPGP_addGPTooltip);
	
	if not CEPGP.Notice then
		CEPGP_notice_frame:Show();
	end
	
	if IsInRaid() and CEPGP_isML() == 0 then
		_G["CEPGP_confirmation"]:Show();
	end
	
	local check;
	check = C_Timer.NewTicker(0.25, function()
		if IsInGuild() then
			CEPGP_addAddonMsg("version-check", "GUILD");
			CEPGP_Info.Initialised = true;
			CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			check._remainingIterations = 1;
			if UnitInRaid("player") then
				CEPGP_rosterUpdate("GROUP_ROSTER_UPDATE");
			end
		end
	end, 20);
	
	--[[local frames = {
		CEPGP_frame,
		CEPGP_log,
		CEPGP_version,
		CEPGP_distribute_popup,
		CEPGP_context_popup,
		CEPGP_decay_group,
		CEPGP_award_raid_popup,
		CEPGP_save_guild_logs,
		CEPGP_restore_guild_logs,
		CEPGP_settings_import,
		CEPGP_override,
		CEPGP_traffic,
		CEPGP_debuginfo,
		CEPGP_notice_frame,
		CEPGP_attendance,
		CEPGP_respond,
		CEPGP_export,
		CEPGP_confirmation,
		CEPGP_standby_addRank,
		CEPGP_rank_exclude,
		CEPGP_rank_filter,
		CEPGP_import,
		CEPGP_roll_award_confirm,
		CEPGP_changelog,
		CEPGP_license,
		CEPGP_raid_modifiers,
		CEPGP_interface_options,
		CEPGP_options_alt_mangement,
		CEPGP_EP_options,
		CEPGP_GP_options,
		CEPGP_loot_options,
		CEPGP_options_plugins,
		CEPGP_standby_options
	}]]
	
	C_Timer.After(5, function()
		for k, v in pairs(CEPGP.Overrides) do
			if string.find(k, "item:") then
				local args = CEPGP_split(k, ":");
				if tonumber(args[10]) then
					local id = CEPGP_getItemID(CEPGP_getItemString(k));
					local function swap()
						CEPGP.Overrides[link] = v;
						CEPGP.Overrides[k] = nil;
					end
					local link = CEPGP_getItemLink(id, swap);
				end
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFC100Classic EPGP Version: " .. CEPGP_Info.Version.Number .. " " .. CEPGP_Info.Version.Build .. " Loaded|r");
		if CEPGP.ChangelogVersion ~= CEPGP_Info.Version.Number then
			CEPGP_print("A new version has been installed.");
			CEPGP.ChangelogVersion = CEPGP_Info.Version.Number;
		end
		C_Timer.After(3, function() CEPGP_initMessageQueue(); end);
	end);
end

function CEPGP_localise(frame)
	local subLayers = {frame:GetRegions()};
	local subFrames = {frame:GetChildren()};
	
	for _, child in ipairs(subLayers) do
		if child.SetText and child:GetText() then
			--print(child:GetText());
			child:SetText(L[child:GetText()]);
		end
	end
	
	for _, child in ipairs(subFrames) do
		if child.SetText and child:GetText() then
			--print(child:GetText());
			child:SetText(L[child:GetText()]);
		elseif child:GetChildren() then
			--print(child:GetName() .. " has more kids");
			CEPGP_localise(child);
		end
	end
end

function CEPGP_initSavedVars()
	
	--[[	Unused Vars		]]--
	if CEPGP.Loot then
		CEPGP.Loot.Keyword = nil;
	end
	
	--[[	General Vars	]]--
	
	CEPGP.Minimap = CEPGP.Minimap or {
		["hide"] = false
	};
	
	CEPGP.Channel = CEPGP.Channel or "Guild";
	CEPGP.Exclusions = CEPGP.Exclusions or {false,false,false,false,false,false,false,false,false,false};
	CEPGP.PollRate = CEPGP.PollRate or 0.0001;
	CEPGP.Sync = CEPGP.Sync or {false, {
			[0] = false,
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
			[5] = false,
			[6] = false,
			[7] = false,
			[8] = false,
			[9] = false
		}
	};
	
	if type(CEPGP.Sync[2]) ~= "table" then
		local enabledRank = CEPGP.Sync[2];
		CEPGP.Sync[2] = {};
		for i = 0, 9 do
			if i == enabledRank then
				CEPGP.Sync[2][i] = true;
			else
				CEPGP.Sync[2][i] = false;
			end
		end
	end
	
	CEPGP.Decay = CEPGP.Decay or {Separate = false};
	CEPGP_Info.Logs = {};
	
	--[[	Guild Frame		]]--
	
	CEPGP.Attendance = CEPGP.Attendance or {};
	CEPGP.Backups = CEPGP.Backups or {};
	CEPGP.Traffic = CEPGP.Traffic or {};
	
	--[[	EP States	]]--
	CEPGP.EP = CEPGP.EP or {};
	
	CEPGP.EP.BossEP = CEPGP.EP.BossEP or {};
	
	if not CEPGP.EP.AutoAward then
		CEPGP.EP.AutoAward = {};
		for bossName, state in pairs(CEPGP_EncounterInfo.Bosses) do
			CEPGP.EP.AutoAward[bossName] = state;
		end
	end
	
	for bossName, EP in pairs(CEPGP_EncounterInfo.Bosses) do
		CEPGP.EP.BossEP[bossName] = CEPGP.EP.BossEP[bossName] or EP;
	end
	
	CEPGP.EP.BossEP["Edge of Madness"] = CEPGP.EP.BossEP["Edge of Madness"] or CEPGP.EP.BossEP["Renataki"] or CEPGP_EncounterInfo.Bosses["Edge of Madness"];
	CEPGP.EP.BossEP["Lord Kazzak"] = CEPGP.EP.BossEP["Lord Kazzak"] or CEPGP.EP.BossEP["Doom Lord Kazzak"]  or CEPGP_EncounterInfo.Bosses["Lord Kazzak"];
	CEPGP.EP.BossEP["The Twin Emperors"] = CEPGP.EP.BossEP["The Twin Emperors"] or CEPGP.EP.BossEP["Twin Emperors"] or CEPGP_EncounterInfo.Bosses["The Twin Emperors"];
	CEPGP.EP.BossEP["The Silithid Royalty"] = CEPGP.EP.BossEP["The Silithid Royalty"] or CEPGP.EP.BossEP["Silithid Royalty"] or CEPGP_EncounterInfo.Bosses["The Silithid Royalty"];
	
	CEPGP.EP.BossEP["Renataki"] = nil;
	CEPGP.EP.BossEP["Wushoolay"] = nil;
	CEPGP.EP.BossEP["Gri'lek"] = nil;
	CEPGP.EP.BossEP["Hazza'rah"] = nil;
	CEPGP.EP.BossEP["Doom Lord Kazzak"] = nil;
	CEPGP.EP.BossEP["The Edge of Madness"] = nil;
	
	CEPGP.EP.AutoAward["Renataki"] = nil;
	CEPGP.EP.AutoAward["Wushoolay"] = nil;
	CEPGP.EP.AutoAward["Gri'lek"] = nil;
	CEPGP.EP.AutoAward["Hazza'rah"] = nil;
	CEPGP.EP.AutoAward["Doom Lord Kazzak"] = nil;
	CEPGP.EP.AutoAward["The Edge of Madness"] = nil;
	
	CEPGP.EP.BossEP["Silithid Royalty"] = nil;
	CEPGP.EP.BossEP["Twin Emperors"] = nil;
	
	CEPGP.EP.AutoAward["Silithid Royalty"] = nil;
	CEPGP.EP.AutoAward["Twin Emperors"] = nil;
	
	CEPGP.EP.BossEP["Highlord Mograine"] = nil;
	CEPGP.EP.BossEP["Thane Korth'azz"] = nil;
	CEPGP.EP.BossEP["Lady Blaumeux"] = nil;
	CEPGP.EP.BossEP["Sir Zeliek"] = nil;
	
	CEPGP.EP.AutoAward["Highlord Mograine"] = nil;
	CEPGP.EP.AutoAward["Thane Korth'azz"] = nil;
	CEPGP.EP.AutoAward["Lady Blaumeux"] = nil;
	CEPGP.EP.AutoAward["Sir Zeliek"] = nil;
	
	
	--[[	GP States	]]--
	
	local slotDefaults = {
		["2HWEAPON"] = 2,
		["WEAPONMAINHAND"] = 1.5,
		["WEAPON"] = 1.5,
		["WEAPONOFFHAND"] = 0.5,
		["HOLDABLE"] = 0.5,
		["SHIELD"] = 0.5,
		["WAND"] = 0.5,
		["THROWN"] = 0.5,
		["RANGED"] = 2,
		["RELIC"] = 0.5,
		["HEAD"] = 1,
		["NECK"] = 0.5,
		["SHOULDER"] = 0.75,
		["CLOAK"] = 0.5,
		["CHEST"] = 1,
		["ROBE"] = 1,
		["WRIST"] = 0.5,
		["HAND"] = 0.75,
		["WAIST"] = 0.75,
		["LEGS"] = 1,
		["FEET"] = 0.75,
		["FINGER"] = 0.5,
		["TRINKET"] = 0.75,
		["EXCEPTION"] = 1
	};
	
	CEPGP.GP = CEPGP.GP or {};
	
	CEPGP.GP.Base = CEPGP.GP.Base or 4.83;
	CEPGP.GP.Min = CEPGP.GP.Min or 1;
	CEPGP.GP.Mod = CEPGP.GP.Mod or 1;
	CEPGP.GP.Multiplier = CEPGP.GP.Multiplier or 2;
	CEPGP.GP.SlotWeights = CEPGP.GP.SlotWeights or {};
	
	for slot, weight in pairs(slotDefaults) do
		CEPGP.GP.SlotWeights[slot] = CEPGP.GP.SlotWeights[slot] or slotDefaults[slot];
	end
	
	CEPGP.GP.SlotWeights["RANGEDRIGHT"] = nil;
	
	CEPGP.Overrides = CEPGP.Overrides or {};
	
	CEPGP.GP.RaidModifiers = CEPGP.GP.RaidModifiers or {};
	
	local RaidModifiers = {
		["Molten Core"] = 100,
		["Onyxia's Lair"] = 100,
		["Blackwing Lair"] = 100,
		["Zul'Gurub"] = 100,
		["The Ruins of Ahn'Qiraj"] = 100,
		["The Temple of Ahn'Qiraj"] = 100,
		["Naxxramas"] = 100
	};
	
	for raid, val in pairs(RaidModifiers) do
		CEPGP.GP.RaidModifiers[raid] = CEPGP.GP.RaidModifiers[raid] or val;
	end
	
	--[[	Guild Management	]]--
	
	CEPGP.Guild = CEPGP.Guild or {};
	
	CEPGP.Guild.Exclusions = CEPGP.Guild.Exclusions or CEPGP.Exclusions or {false,false,false,false,false,false,false,false,false,false};
	CEPGP.Guild.Filter = CEPGP.Guild.Filter or {false,false,false,false,false,false,false,false,false,false};
	
	CEPGP.Exclusions = nil;
	
	--[[	Loot Management	]]--
	
	CEPGP.LootChannel = CEPGP.LootChannel or "Raid";
	
	CEPGP.Loot = CEPGP.Loot or {};
	
	CEPGP.Loot.Announcement = CEPGP.Loot.Announcement or "Whisper me for loot";
	CEPGP.Loot.MinThreshold = CEPGP.Loot.MinThreshold or 2;
	
	--	Temporary measure to resolve a structural problem
	CEPGP.Loot.MinThreshold = type(CEPGP.Loot.MinThreshold) == "number" and CEPGP.Loot.MinThreshold or 2;
	
	CEPGP.Loot.MinReq = CEPGP.Loot.MinReq or {false, 0};
	CEPGP.Loot.RaidVisibility = (type(CEPGP.Loot.RaidVisibility) == "boolean" and {[1] = true, [2] = false}) or CEPGP.Loot.RaidVisibility or {[1] = true, [2] = false, [3] = {}};
	CEPGP.Loot.RaidVisibility[3] = CEPGP.Loot.RaidVisibility[3] or {
		[0] = false,
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false,
		[7] = false,
		[8] = false,
		[9] = false
	};
	
	
	CEPGP.Loot.GUI = CEPGP.Loot.GUI or {};
	CEPGP.Loot.GUI.Buttons = CEPGP.Loot.GUI.Buttons or {};
	
	CEPGP.Loot.GUI.Buttons[1] = CEPGP.Loot.GUI.Buttons[1] or {};
	CEPGP.Loot.GUI.Buttons[1][1] = true;
	CEPGP.Loot.GUI.Buttons[1][2] = CEPGP.Loot.GUI.Buttons[1][2] or CEPGP.Loot.GUI.Buttons[1][2] or "Main Spec";
	CEPGP.Loot.GUI.Buttons[1][3] = CEPGP.Loot.GUI.Buttons[1][3] or CEPGP.Loot.GUI.Buttons[1][3] or 0;
	CEPGP.Loot.GUI.Buttons[1][4] = CEPGP.Loot.GUI.Buttons[1][4] or CEPGP.Loot.GUI.Buttons[1][4] or "Need";
	
	CEPGP.Loot.GUI.Buttons[2] = CEPGP.Loot.GUI.Buttons[2] or {};
	CEPGP.Loot.GUI.Buttons[2][2] = CEPGP.Loot.GUI.Buttons[2][2] or CEPGP.Loot.GUI.Buttons[2][2] or "Off Spec";
	CEPGP.Loot.GUI.Buttons[2][3] = CEPGP.Loot.GUI.Buttons[2][3] or CEPGP.Loot.GUI.Buttons[2][3] or 0;
	CEPGP.Loot.GUI.Buttons[2][4] = CEPGP.Loot.GUI.Buttons[2][4] or CEPGP.Loot.GUI.Buttons[2][4] or "Greed";
	
	CEPGP.Loot.GUI.Buttons[3] = CEPGP.Loot.GUI.Buttons[3] or {};
	CEPGP.Loot.GUI.Buttons[3][2] = CEPGP.Loot.GUI.Buttons[3][2] or CEPGP.Loot.GUI.Buttons[3][2] or "Disenchant";
	CEPGP.Loot.GUI.Buttons[3][3] = CEPGP.Loot.GUI.Buttons[3][3] or CEPGP.Loot.GUI.Buttons[3][3] or 0;
	CEPGP.Loot.GUI.Buttons[3][4] = CEPGP.Loot.GUI.Buttons[3][4] or CEPGP.Loot.GUI.Buttons[3][4] or "Disenchant";
	
	CEPGP.Loot.GUI.Buttons[4] = CEPGP.Loot.GUI.Buttons[4] or {};
	CEPGP.Loot.GUI.Buttons[4][2] = CEPGP.Loot.GUI.Buttons[4][2] or CEPGP.Loot.GUI.Buttons[4][2] or "Minor Upgrade";
	CEPGP.Loot.GUI.Buttons[4][3] = CEPGP.Loot.GUI.Buttons[4][3] or CEPGP.Loot.GUI.Buttons[4][3] or 0;
	CEPGP.Loot.GUI.Buttons[4][4] = CEPGP.Loot.GUI.Buttons[4][4] or CEPGP.Loot.GUI.Buttons[4][4] or "Minor";
	
	CEPGP.Loot.GUI.Buttons[5] = CEPGP.Loot.GUI.Buttons[5] or CEPGP.Loot.GUI.Buttons[5];
	CEPGP.Loot.GUI.Buttons[6] = CEPGP.Loot.GUI.Buttons[6] or CEPGP.Loot.GUI.Buttons[6];
	
	CEPGP.Loot.GUI.Timer = CEPGP.Loot.GUI.Timer or 0;
	
	CEPGP.Loot.ExtraKeywords = CEPGP.Loot.ExtraKeywords or {};
	CEPGP.Loot.ExtraKeywords.Keywords = CEPGP.Loot.ExtraKeywords.Keywords or {};
	
	--[[	Alt Management	]]--
	CEPGP.Alt = CEPGP.Alt or {
		SyncEP = true,
		SyncGP = true
	};
	CEPGP.Alt.Links = CEPGP.Alt.Links or {};
	
	--[[	Standby Settings	]]--
	
	CEPGP.Standby = CEPGP.Standby or {};
	
	CEPGP.Standby.Keyword = CEPGP.Standby.Keyword or "!standby";
	CEPGP.Standby.Percent = CEPGP.Standby.Percent or 100;
	CEPGP.Standby.Ranks = CEPGP.Standby.Ranks or {false,false,false,false,false,false,false,false,false,false};
	CEPGP.Standby.Roster = CEPGP.Standby.Roster or {};
	
	for i = 1, 10 do
		--	Really not sure how this structure mismatch hasn't been an issue yet but whatever
		if type(CEPGP.Standby.Ranks[i]) == "table" then
			local state = CEPGP.Standby.Ranks[i][2];
			CEPGP.Standby.Ranks[i] = state;
		end
	end
	
	if not CEPGP.Standby.ByRank and not CEPGP.Standby.Manual then
		CEPGP.Standby.ByRank = true;
	end
	
	--[[	Migration States	]]--
	if not CEPGP.Migrated then
		
		CEPGP.Traffic = TRAFFIC or CEPGP.Traffic;
		CEPGP.Attendance = CEPGP_raid_logs or CEPGP.Attendance;
		CEPGP.Backups = RECORDS or CEPGP.Backups;
		
		CEPGP.Migrated = true;
		
	end
end

function CEPGP_initInterfaceOptions()
	local panel = {};
	panel.main = _G["CEPGP_interface_options"];
	panel.main.name = "Classic EPGP";
	
	panel.alt = _G["CEPGP_options_alt_mangement"];
	panel.alt.name = "Alt Management";
	panel.alt.parent = panel.main.name;
	
	panel.ep = _G["CEPGP_EP_options"];
	panel.ep.name = "EP Management";
	panel.ep.parent = panel.main.name;
	
	panel.gp = _G["CEPGP_GP_options"];
	panel.gp.name = "GP Management";
	panel.gp.parent = panel.main.name;
	
	panel.loot = _G["CEPGP_loot_options"];
	panel.loot.name = "Loot Distribution";
	panel.loot.parent = panel.main.name;
	
	panel.plugins = _G["CEPGP_options_plugins"];
	panel.plugins.name = "Plugin Manager";
	panel.plugins.parent = panel.main.name;	
	
	panel.standby = _G["CEPGP_standby_options"];
	panel.standby.name = "Standby EP";
	panel.standby.parent = panel.main.name;
	
	InterfaceOptions_AddCategory(panel.main);
	InterfaceOptions_AddCategory(panel.alt);
	InterfaceOptions_AddCategory(panel.ep);
	InterfaceOptions_AddCategory(panel.gp);
	InterfaceOptions_AddCategory(panel.loot);
	InterfaceOptions_AddCategory(panel.plugins);
	InterfaceOptions_AddCategory(panel.standby);
	
	_G["CEPGP_interface_options_version"]:SetText("Classic EPGP Version " .. CEPGP_Info.Version.Number .. " " .. CEPGP_Info.Version.Build);
	
	local varMap = {
		["Alt"] = 				"Alt Management",
		["Channel"] = 			"EPGP Modification Reporting Channel",
		["Decay"] = 			"Decay Configuration",
		["EP"] = 				"EP Management",
		["Guild.Exclusions"] =	"Rank Exclusions",
		["Guild.Filter"] =		"Rank Filters",
		["GP"] = 				"GP Management",
		["Loot"] = 				"Loot Management",
		["LootChannel"] = 		"Loot Response Reporting Channel",
		["Overrides"] = 		"GP Overrides",
		["Standby"] =			"Standby Configuration"
	}
	
	local importFrame = CEPGP_settings_import_sf_container;
	
	local temp = {};
	
	for base, _ in pairs(varMap) do
		table.insert(temp, base);
	end
	
	table.sort(temp);
	
	for i = 1, #temp do
		local frame;
		local base = varMap[temp[i]];
		if not _G["ImportCheckButton_" .. i] then
			frame = CreateFrame('CheckButton', "ImportCheckButton_" .. i, CEPGP_settings_import_sf_container, "ImportOptionCheckTemplate");
			if i == 1 then
				frame:SetPoint("TOPLEFT", CEPGP_settings_import_sf_container, "TOPLEFT", 5, -10);
			else
				frame:SetPoint("TOPLEFT", _G["ImportCheckButton_" .. i-1], "BOTTOMLEFT", 0, -2);
			end
		end
		frame:SetAttribute("varName", temp[i]);		--	Couldn't think of a better generic name to reflect the name of a saved variable
		frame:Show();
		_G[frame:GetName() .. "_text"]:SetText(base);
	end
end

function CEPGP_initDropdown(frame, initFunction, displayMode, level, menuList)
	frame.menuList = menuList;

	--securecall("UIDropDownMenu_InitializeHelper", frame);

	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if ( initFunction ) then
		UIDropDownMenu_SetInitializeFunction(frame, initFunction);
		--initFunction(frame, level, frame.menuList);
	end

	--master frame
	if(level == nil) then
		level = 1;
	end

	local dropDownList = _G["DropDownList"..level];
	dropDownList.dropdown = frame;
	dropDownList.shouldRefresh = true;

	UIDropDownMenu_SetDisplayMode(frame, displayMode);
end

function CEPGP_ContainsIllegalChar(str)
	return string.find(str, '[-!$%^&*()_+|~=`{}\[\]:";<>?,.\/\' ]');
end

function CEPGP_addResponse(player, response, roll)
	if response and not tonumber(response) then
		response = CEPGP_getResponseIndex(response);
	end
	CEPGP_Info.Loot.ItemsTable[player] = CEPGP_Info.Loot.ItemsTable[player] or {};
	
	if CEPGP_Info.Loot.ItemsTable[player][3] then
		if CEPGP.Loot.Resubmit then
			CEPGP_Info.Loot.ItemsTable[player][3] = response;
		end
	else
		CEPGP_Info.Loot.ItemsTable[player][3] = response;
		if CEPGP_indexToLabel(response) or CEPGP_getResponse(response) or CEPGP_getResponseIndex(response) or (CEPGP.Loot.PassRolls and response == 6) or response < 6 then
			CEPGP_Info.Loot.ItemsTable[player][4] = roll;
		end
	end	
	
	local message = "!need;"..player..";"..CEPGP_Info.Loot.DistributionID..";"..response..";"..roll;
	CEPGP_distribute_responses_received:SetText(CEPGP_ntgetn(CEPGP_Info.Loot.ItemsTable) .. " of " .. CEPGP_Info.Loot.NumOnline .. " Responses Received");
	
	CEPGP_addAddonMsg("Acknowledge;" .. CEPGP_Info.Loot.GUID .. ";" .. response, "WHISPER", player);
		--	Shares the loot distribution results with the raid / assists
	if not CEPGP.Loot.DelayResponses then
		CEPGP_sendLootMessage(message);
	end
	if player == UnitName("player") then
		CEPGP_respond:Hide();
	end
	
	if not CEPGP_Info.Loot.Expired and (CEPGP_ntgetn(CEPGP_Info.Loot.ItemsTable) >= CEPGP_Info.Loot.NumOnline and CEPGP.Loot.DelayResponses) then
		CEPGP_announceResponses();
	end
end

function CEPGP_GetNumOnlineGroupMembers()
	local count = 0;
	local limit = GetNumGroupMembers();
	for i = 1, limit do
		local online = select(8, GetRaidRosterInfo(i));
		if online then count = count + 1; end
	end
	return count;
end

function CEPGP_announceResponses()
	if not CEPGP_Info.Loot.DistributionID then return; end
	local responses = {};
		
	for _, label in ipairs(CEPGP_Info.LootSchema) do
		responses[label] = {};
	end
	
	for name, v in pairs(CEPGP_Info.Loot.ItemsTable) do
		local label = CEPGP_Info.LootSchema[v[3]];
		table.insert(responses[label], name);
	end
	
	for label, _ in pairs(responses) do
		responses[label] = CEPGP_tSort(responses[label], nil, false);
	end
	
	for _, label in ipairs(CEPGP_Info.LootSchema) do
		local msg = label .. ": ";
		for index, name in ipairs(responses[label]) do
			local EP, GP, PR, roll;
			if CEPGP_Info.Loot.ItemsTable[name][3] ~= 5 and CEPGP_Info.Loot.ItemsTable[name][3] ~= 6 then	--	Ensures that misc responses and passes are not announced
				if CEPGP.Loot.DelayResponses and CEPGP.Loot.PRWithDelay then
					EP, GP = CEPGP_getEPGP(name);
					PR = math.floor((tonumber(EP)*100/tonumber(GP)))/100;
				end
				if CEPGP.Loot.DelayResponses and CEPGP.Loot.RollWithDelay then
					roll = CEPGP_Info.Loot.ItemsTable[name][4];
				end
				if #(msg .. name .. (PR and " (PR " .. PR .. ")" or "") .. (roll and " (Roll " .. roll .. ")" or "")) > 249 then
					SendChatMessage(msg, "RAID", CEPGP_Info.Language);
					msg = label .. " (Continued): " .. name .. (PR and " (PR " .. PR .. ")" or "") .. (roll and " (Roll " .. roll .. ")" or "");
				else
					msg = msg .. name .. (PR and " (PR " .. PR .. ")" or "") .. (roll and " (Roll " .. roll .. ")" or "") .. ((index < #responses[label]) and ", " or "");
				end
			end
			local message = "!need;"..name..";"..CEPGP_Info.Loot.DistributionID..";"..CEPGP_Info.Loot.ItemsTable[name][3]..";"..CEPGP_Info.Loot.ItemsTable[name][4];
			if CEPGP.Loot.DelayResponses then
				CEPGP_sendLootMessage(message);
			end
		end
		if label ~= "" and label ~= "Pass" and msg ~= label .. ": " then
			SendChatMessage(msg, "RAID", CEPGP_Info.Language);
		end
	end
end

function CEPGP_sendLootMessage(message)
	local announceRanks = {};
	--	Identify which guild ranks should be included
	for rank, state in pairs(CEPGP.Loot.RaidVisibility[3]) do
		if state then
			table.insert(announceRanks, rank);
		end
	end

	if #announceRanks == 1 then
		CEPGP_messageGroup(message, "raid", false, announceRanks[1]);
	elseif #announceRanks > 1 then	--	If more than one rank is selected it's more efficient to collect all of the players and send messages individually
		local players = {};
		for i = 1, GetNumGroupMembers() do
			local name = GetRaidRosterInfo(i);
			local rank;
			if CEPGP_Info.Guild.Roster[name] then
				rank = CEPGP_Info.Guild.Roster[name][4];
				if CEPGP.Loot.RaidVisibility[3][rank] then
					table.insert(players, name);
				end
			end
		end
		local limit = #players;
		C_Timer.NewTicker(0.1, function()
			CEPGP_addAddonMsg(message, "WHISPER", players[1]);
			table.remove(players, 1);
		end, limit);
	end
	
	if CEPGP.Loot.RaidVisibility[2] then
		CEPGP_addAddonMsg(message, "RAID");
	elseif CEPGP.Loot.RaidVisibility[1] then
		CEPGP_messageGroup(message, "assists");
	end
end

function CEPGP_getDiscount(label)
	for l, v in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
		for _, discount in pairs(v) do
			if l == label then
				return tonumber(discount);
			end
		end
	end
end

function CEPGP_indexToLabel(index)
	return CEPGP_Info.LootSchema[index];
end

function CEPGP_getResponse(keyword)
	if not keyword then return end
	for index, v in ipairs(CEPGP.Loot.GUI.Buttons) do
		if keyword == index then
			return v[2];
		end
	end
	for label, v in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
		for key, _ in pairs(v) do
			if string.lower(keyword) == string.lower(key) then
				return label;
			end
		end
	end
end

function CEPGP_getResponseIndex(keyword)
	if not keyword then return; end
	for index, v in ipairs(CEPGP.Loot.GUI.Buttons) do
		if string.lower(keyword) == string.lower(v[4]) then
			return index;
		end
	end
end

function CEPGP_getLabelIndex(_label)
	for index, v in ipairs(CEPGP.Loot.GUI.Buttons) do
		if _label == v[2] then
			return index;
		end
	end
	for index, label in ipairs(CEPGP_Info.LootSchema) do
		if _label == label then
			return index;
		end
	end
end

function CEPGP_calcGP(link, quantity, id)	
	local name, rarity, ilvl, itemType, subType, slot, classID, subClassID;
	if id then
		name, link, rarity, ilvl, itemType, subType, _, _, slot, _, _, classID, subClassID = GetItemInfo(id);
	elseif link then
		name, _, rarity, ilvl, itemType, subType, _, _, slot, _, _, classID, subClassID = GetItemInfo(link);
	else
		return 0;
	end
	if not name and CEPGP_itemExists(tonumber(id)) then
		local item = Item:CreateFromItemID(tonumber(id));
		item:ContinueOnItemLoad(function()
			name, link, rarity, ilvl, itemType, subType, _, _, slot, _, _, classID, subClassID = GetItemInfo(id);
			if CEPGP.Overrides[name] then return CEPGP.Overrides[name]; end
			if CEPGP.Overrides[CEPGP_getItemLink(id)] then return CEPGP.Overrides[CEPGP_getItemLink(id)]; end
			
			for _, k in pairs(CEPGP_tokens) do
				for slotName, v in pairs(k) do
					if k[slotName][tonumber(id)] then
						slot = "INVTYPE_" .. string.upper(slotName);
						ilvl = k[slotName][tonumber(id)];
						rarity = (rarity == 3 and 4 or rarity);
						break;
					end
				end
			end
			if slot == "" or slot == nil then
				slot = "INVTYPE_EXCEPTION";
			end
			
			if slot == "INVTYPE_ROBE" then slot = "INVTYPE_CHEST"; end
			if classID == 2 and subClassID == 19 then slot = "INVTYPE_WAND" end;
			if classID == 2 and (subClassID == 2 or subClassID == 3 or subClassID == 18) then slot = "INVTYPE_RANGED" end;
			
			if CEPGP_Info.Debug then
				local quality = rarity == 0 and "Poor" or rarity == 1 and "Common" or rarity == 2 and "Uncommon" or rarity == 3 and "Rare" or rarity == 4 and "Epic" or "Legendary";
				CEPGP_print("Name: " .. name);
				CEPGP_print("Rarity: " .. quality);
				CEPGP_print("Item Level: " .. ilvl);
				CEPGP_print("Class ID: " .. classID);
				CEPGP_print("Subclass ID: " .. subClassID);
				CEPGP_print(GetItemSubClassInfo(classID, subClassID), false);
				CEPGP_print("Item Type: " .. itemType);
				CEPGP_print("Subtype: " .. subType);
				CEPGP_print("Slot: " .. slot);
			end
			slot = strsub(slot,strfind(slot,"INVTYPE_")+8,string.len(slot));
			slot = CEPGP.GP.SlotWeights[slot];
			
			local raidscaling = 1;
			
			for raid, data in pairs(CEPGP_ItemDomain) do
				for _, _id in pairs(data) do
					if tonumber(id) == _id then
						raidScaling = CEPGP.GP.RaidModifiers[raid]/100;
						break;
					end
				end
			end
			
			if ilvl and rarity and slot then
				return math.floor((((CEPGP.GP.Base * (CEPGP.GP.Multiplier^((ilvl/26) + (rarity-4))) * slot)*CEPGP.GP.Mod)*quantity)*raidScaling);
			else
				return 0;
			end
		end);
	else
		if not ilvl then ilvl = 0; end
		
		if CEPGP.Overrides[name] then return CEPGP.Overrides[name]; end
		if CEPGP.Overrides[CEPGP_getItemLink(id)] then return CEPGP.Overrides[CEPGP_getItemLink(id)]; end
		--local compare = "item[%-?" .. id .. ":]+";
		--return CEPGP.Overrides[compare];
		
		--for k, v in pairs(CEPGP.Overrides) do
		
			--[[local compName = GetItemInfo(k);
			if compName == name then
				return v;
			end]]
		--end
		for _, k in pairs(CEPGP_tokens) do
			for slotName, v in pairs(k) do
				if k[slotName][tonumber(id)] then
					slot = "INVTYPE_" .. string.upper(slotName);
					ilvl = k[slotName][tonumber(id)];
					rarity = (rarity == 3 and 4 or rarity);
					break;
				end
			end
		end
		if slot == "" or slot == nil then
			slot = "INVTYPE_EXCEPTION";
		end
		
		if slot == "INVTYPE_ROBE" then slot = "INVTYPE_CHEST"; end
		if classID == 2 and subClassID == 19 then slot = "INVTYPE_WAND" end;
		if classID == 2 and (subClassID == 2 or subClassID == 3 or subClassID == 18) then slot = "INVTYPE_RANGED" end;
		
		
		if CEPGP_Info.Debug then
			local quality = rarity == 0 and "Poor" or rarity == 1 and "Common" or rarity == 2 and "Uncommon" or rarity == 3 and "Rare" or rarity == 4 and "Epic" or "Legendary";
			CEPGP_print("Name: " .. name);
			CEPGP_print("Rarity: " .. quality);
			CEPGP_print("Item Level: " .. ilvl);
			CEPGP_print("Class ID: " .. classID);
			CEPGP_print("Subclass ID: " .. subClassID);
			CEPGP_print(GetItemSubClassInfo(classID, subClassID), false);
			CEPGP_print("Item Type: " .. itemType);
			CEPGP_print("Subtype: " .. subType);
			CEPGP_print("Slot: " .. slot);
		end
		slot = strsub(slot,strfind(slot,"INVTYPE_")+8,string.len(slot));
		slot = CEPGP.GP.SlotWeights[slot];
		
		local raidScaling = 1;

		for raid, data in pairs(CEPGP_ItemDomain) do
			for _, _id in pairs(data) do
				if tonumber(id) == _id then
					raidScaling = CEPGP.GP.RaidModifiers[raid]/100;
					break;
				end
			end
		end
		
		if ilvl and rarity and slot then
			return math.floor((((CEPGP.GP.Base * (CEPGP.GP.Multiplier^((ilvl/26) + (rarity-4))) * slot)*CEPGP.GP.Mod)*quantity)*raidScaling);
		else
			return 0;
		end
	end
end

function CEPGP_addGPTooltip(frame)
	if not CEPGP.GP.Tooltips or not frame:GetItem() or frame:GetItem() == nil or frame:GetItem() == "" then return; end
	local _, link = frame:GetItem();
	local id = CEPGP_getItemID(CEPGP_getItemString(link));
	if not CEPGP_itemExists(tonumber(id)) then return; end
	local name = GetItemInfo(id);
	if not name and CEPGP_itemExists(tonumber(id)) then
		local item = Item:CreateFromItemID(tonumber(id));
		item:ContinueOnItemLoad(function()
			local gp = CEPGP_calcGP(_, 1, id);
			frame:AddLine("GP Value: " .. gp, {1,1,1});	
		end);
	else
		local gp = CEPGP_calcGP(_, 1, id);
		frame:AddLine("GP Value: " .. gp, {1,1,1});
	end
	
end

function CEPGP_addGPHyperlink(self, iString)
	if not string.find(iString, "item:") or not CEPGP.GP.Tooltips then return; end
	local id = CEPGP_getItemID(iString);
	local name = GetItemInfo(id);
	for i = 1, ItemRefTooltip:NumLines() do
		if string.find(_G["ItemRefTooltipTextLeft"..i]:GetText(), "GP Value:") then return end;
	end
	if not name and CEPGP_itemExists(tonumber(id)) then
		local item = Item:CreateFromItemID(tonumber(id));
		item:ContinueOnItemLoad(function()
			local gp = CEPGP_calcGP(_, 1, id);
			ItemRefTooltip:AddLine("GP Value: " .. gp, {1,1,1});
			ItemRefTooltip:Show();
		end);
	else
		local gp = CEPGP_calcGP(_, 1, id);
		ItemRefTooltip:AddLine("GP Value: " .. gp, {1,1,1});
		ItemRefTooltip:Show();
	end
end

function CEPGP_populateFrame(items)
	local subframe = nil;
	
	if CEPGP_Info.Mode == "loot" then
		CEPGP_cleanTable();
	elseif CEPGP_Info.Mode ~= "loot" then
		CEPGP_cleanTable();
	end
	local tempItems = {};
	local total;
	if CEPGP_Info.Mode == "guild" and _G["CEPGP_guild"]:IsVisible() then
		CEPGP_UpdateGuildScrollBar();
	elseif CEPGP_Info.Mode == "raid" and _G["CEPGP_raid"]:IsVisible() then
		CEPGP_UpdateRaidScrollBar();
	elseif CEPGP_Info.Mode == "loot" then
		subframe = CEPGP_loot;
		local count = 0;
		if not items then
			total = 0;
		else
			local i = 1;
			for _,value in pairs(items) do 
				tempItems[i] = value;
				i = i + 1;
				count = count + 1;
			end
			i = nil;
		end
		total = count;
	end
	if CEPGP_Info.Mode == "loot" then 
		for i = 1, total do
			local texture, name, quality, gp, colour, iString, link, slot, x, quantity;
			x = i;
			texture = tempItems[i][1];
			name = tempItems[i][2];
			colour = ITEM_QUALITY_COLORS[tempItems[i][3]];
			link = tempItems[i][4];
			iString = tempItems[i][5];
			slot = tempItems[i][6];
			quantity = tempItems[i][7];
			gp = CEPGP_calcGP(link, quantity, CEPGP_getItemID(iString));
			if _G[CEPGP_Info.Mode..'item'..i] ~= nil then
				_G[CEPGP_Info.Mode..'announce'..i]:Show();
				_G[CEPGP_Info.Mode..'announce'..i]:SetWidth(20);
				_G[CEPGP_Info.Mode..'announce'..i]:SetScript('OnClick', function()
					--[[if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Guild.Polling then
						local callback = function() CEPGP_announce(link, x, slot, quantity) end;
						CEPGP_Info.Loot.QueuedAnnouncement = callback;
						CEPGP_print(L["This item will be announced in a moment. Please wait and keep the loot window open"]);
					else]]
						CEPGP_announce(link, x, slot, quantity);
						CEPGP_distribute:SetID(_G[CEPGP_Info.Mode..'announce'..i]:GetID());
					--end
				end);
				_G[CEPGP_Info.Mode..'announce'..i]:SetID(slot);
				
				_G[CEPGP_Info.Mode..'icon'..i]:Show();
				_G[CEPGP_Info.Mode..'icon'..i]:SetScript('OnEnter', function() GameTooltip:SetOwner(_G[CEPGP_Info.Mode..'icon'..i], "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
				_G[CEPGP_Info.Mode..'icon'..i]:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				_G[CEPGP_Info.Mode..'texture'..i]:Show();
				_G[CEPGP_Info.Mode..'texture'..i]:SetTexture(texture);
				
				_G[CEPGP_Info.Mode..'item'..i]:Show();
				_G[CEPGP_Info.Mode..'item'..i].text:SetText(link);
				_G[CEPGP_Info.Mode..'item'..i].text:SetTextColor(colour.r, colour.g, colour.b);
				_G[CEPGP_Info.Mode..'item'..i].text:SetPoint('CENTER',_G[CEPGP_Info.Mode..'item'..i]);
				_G[CEPGP_Info.Mode..'item'..i]:SetWidth(_G[CEPGP_Info.Mode..'item'..i].text:GetStringWidth());
				_G[CEPGP_Info.Mode..'item'..i]:SetScript('OnClick', function() SetItemRef(link, iString) end);
				
				_G[CEPGP_Info.Mode..'itemGP'..i]:SetText(gp);
				_G[CEPGP_Info.Mode..'itemGP'..i]:SetTextColor(colour.r, colour.g, colour.b);
				_G[CEPGP_Info.Mode..'itemGP'..i]:SetWidth(35);
				_G[CEPGP_Info.Mode..'itemGP'..i]:SetScript('OnEnterPressed', function() _G[CEPGP_Info.Mode..'itemGP'..i]:ClearFocus() end);
				_G[CEPGP_Info.Mode..'itemGP'..i]:SetAutoFocus(false);
				_G[CEPGP_Info.Mode..'itemGP'..i]:Show();
			else
				subframe.announce = CreateFrame('Button', CEPGP_Info.Mode..'announce'..i, subframe, 'UIPanelButtonTemplate');
				subframe.announce:SetHeight(20);
				subframe.announce:SetWidth(20);
				subframe.announce:SetScript('OnClick', function()
					--[[if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Guild.Polling then
						local callback = function() CEPGP_announce(link, x, slot, quantity) end;
						CEPGP_Info.Loot.QueuedAnnouncement = callback;
						CEPGP_print(L["This item will be announced in a moment. Please wait and keep the loot window open"]);
					else]]
						CEPGP_announce(link, x, slot, quantity);
						CEPGP_distribute:SetID(_G[CEPGP_Info.Mode..'announce'..i]:GetID());
					--end
				end);
				subframe.announce:SetID(slot);
	
				subframe.icon = CreateFrame('Button', CEPGP_Info.Mode..'icon'..i, subframe);
				subframe.icon:SetHeight(20);
				subframe.icon:SetWidth(20);
				subframe.icon:SetScript('OnEnter', function() GameTooltip:SetOwner(_G[CEPGP_Info.Mode..'icon'..i], "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(link) GameTooltip:Show() end);
				subframe.icon:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				local tex = subframe.icon:CreateTexture(CEPGP_Info.Mode..'texture'..i, "BACKGROUND");
				tex:SetAllPoints();
				tex:SetTexture(texture);
				
				subframe.itemName = CreateFrame('Button', CEPGP_Info.Mode..'item'..i, subframe);
				subframe.itemName:SetHeight(20);
				
				subframe.itemGP = CreateFrame('EditBox', CEPGP_Info.Mode..'itemGP'..i, subframe, 'InputBoxTemplate');
				subframe.itemGP:SetHeight(20);
				subframe.itemGP:SetWidth(35);
				
				if i == 1 then
					subframe.announce:SetPoint('CENTER', _G['CEPGP_'..CEPGP_Info.Mode..'_announce'], 'BOTTOM', 0, -20);
					subframe.icon:SetPoint('LEFT', _G[CEPGP_Info.Mode..'announce'..i], 'RIGHT', 30, 0);
					tex:SetPoint('LEFT', _G[CEPGP_Info.Mode..'announce'..i], 'RIGHT', 30, 0);
					subframe.itemName:SetPoint('LEFT', _G[CEPGP_Info.Mode..'icon'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G['CEPGP_'..CEPGP_Info.Mode..'_GP'], 'BOTTOM', 10, -20);
				else
					subframe.announce:SetPoint('CENTER', _G[CEPGP_Info.Mode..'announce'..(i-1)], 'BOTTOM', 0, -20);
					subframe.icon:SetPoint('LEFT', _G[CEPGP_Info.Mode..'announce'..i], 'RIGHT', 30, 0);
					tex:SetPoint('LEFT', _G[CEPGP_Info.Mode..'announce'..i], 'RIGHT', 30, 0);
					subframe.itemName:SetPoint('LEFT', _G[CEPGP_Info.Mode..'icon'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G[CEPGP_Info.Mode..'itemGP'..(i-1)], 'BOTTOM', 0, -20);
				end
				
				subframe.icon:SetScript('OnClick', function() SetItemRef(link, iString) end);
				
				subframe.itemName.text = subframe.itemName:CreateFontString(CEPGP_Info.Mode..'EPGP_i'..name..'text', 'OVERLAY', 'GameFontNormal');
				subframe.itemName.text:SetPoint('CENTER', _G[CEPGP_Info.Mode..'item'..i]);
				subframe.itemName.text:SetText(link);
				subframe.itemName.text:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemName:SetWidth(subframe.itemName.text:GetStringWidth());
				subframe.itemName:SetScript('OnClick', function() SetItemRef(link, iString) end);
				
				subframe.itemGP:SetText(gp);
				subframe.itemGP:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemGP:SetWidth(35);
				subframe.itemGP:SetScript('OnEnterPressed', function() _G[CEPGP_Info.Mode..'itemGP'..i]:ClearFocus() end);
				subframe.itemGP:SetAutoFocus(false);
				subframe.itemGP:Show();
			end
		end
		texture, name, colour, link, iString, slot, quantity, gp, tempItems = nil;
	end
end

function CEPGP_print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP:|r " .. "|c00FF0000Error|r|c006969FF - " .. tostring(str) .. "|r");
	end
end

function CEPGP_cleanTable()
	local i = 1;
	while _G[CEPGP_Info.Mode..'member_name'..i] ~= nil do
		_G[CEPGP_Info.Mode..'member_group'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'member_name'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'member_rank'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'member_EP'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'member_GP'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'member_PR'..i].text:SetText("");
		i = i + 1;
	end
	
	
	i = 1;
	while _G[CEPGP_Info.Mode..'item'..i] ~= nil do
		_G[CEPGP_Info.Mode..'announce'..i]:Hide();
		_G[CEPGP_Info.Mode..'icon'..i]:Hide();
		_G[CEPGP_Info.Mode..'texture'..i]:Hide();
		_G[CEPGP_Info.Mode..'item'..i].text:SetText("");
		_G[CEPGP_Info.Mode..'itemGP'..i]:Hide();
		i = i + 1;
	end
end

function CEPGP_toggleFrame(frame)
	for i = 1, table.getn(CEPGP_Info.CoreFrames) do
		if CEPGP_Info.CoreFrames[i]:GetName() == frame then
			CEPGP_Info.CoreFrames[i]:Show();
		else
			CEPGP_Info.CoreFrames[i]:Hide();
		end
	end
end

function CEPGP_rosterUpdate(event)
	if CEPGP_Info.IgnoreUpdates or not CEPGP_Info.Initialised then return; end
	if event == "GUILD_ROSTER_UPDATE" then
		if CEPGP_Info.Guild.Polling then
			CEPGP_Info.Guild.Rescan = true;
			return;
		end
		--CEPGP_Info.LastUpdate = GetTime()+(CEPGP.PollRate*GetNumGuildMembers());
		CEPGP_Info.Guild.Polling = true;
		CEPGP_Info.Version.List = CEPGP_Info.Version.List or {};
		local pRate = CEPGP.PollRate;
		local quit = false;
		--local timer = CEPGP_Info.LastUpdate;
		--local numGuild = GetNumGuildMembers();
		
		if CanEditOfficerNote() then
			CEPGP_guild_add_EP:Show();
			CEPGP_guild_decay:Show();
			CEPGP_guild_reset:Show();
			CEPGP_raid_add_EP:Show();
			CEPGP_button_guild_restore:Show();
			CEPGP_button_guild_import:Show();
		else --[[ Hides context sensitive options if player cannot edit officer notes ]]--
			CEPGP_guild_add_EP:Hide();
			CEPGP_guild_decay:Hide();
			CEPGP_guild_reset:Hide();
			CEPGP_raid_add_EP:Hide();
			CEPGP_button_guild_restore:Hide();
			CEPGP_button_guild_import:Hide();
		end
		
		local tempRoster = {};
		for k, _ in pairs(CEPGP_Info.Guild.Roster) do
			tempRoster[k] = "";
		end
		
		CEPGP_rosterUpdate("GROUP_ROSTER_UPDATE");
		
		local function update()
			--	Purges players that have been removed from the guild from CEPGP_Info.Guild.Roster
			for k, _ in pairs(tempRoster) do
				CEPGP_Info.Guild.Roster[k] = nil;
			end
			
			if _G["CEPGP_options_alt_mangement"]:IsVisible() then
				CEPGP_UpdateAltScrollBar();
			end
			
			--CEPGP_Info.Version.List = CEPGP_tSort(CEPGP_Info.Version.List, 1);
			if _G["CEPGP_guild"]:IsVisible() and IsInGuild() then
				CEPGP_UpdateGuildScrollBar();
			elseif _G["CEPGP_raid"]:IsVisible() then
				CEPGP_UpdateRaidScrollBar();
			end
			if GetNumGuildMembers() > 0 then
				if CEPGP_standby_options:IsVisible() then
					CEPGP_UpdateStandbyScrollBar();
				end
			end
			
			if CEPGP_Info.Loot.QueuedAnnouncement then
				CEPGP_Info.Loot.QueuedAnnouncement();
				CEPGP_Info.Loot.QueuedAnnouncement = nil;
			end
			
			for _, func in pairs(CEPGP_Info.RosterStack) do
				func();
			end
			CEPGP_Info.RosterStack = {};
			CEPGP_Info.Guild.Polling = false;
			if CEPGP_Info.Guild.Rescan then
				CEPGP_Info.Guild.Rescan = false;
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			end
		end
		
		local i = 0;
		local limit = GetNumGuildMembers();
		C_Timer.NewTicker(CEPGP.PollRate, function()
			if quit then return; end
			if pRate ~= CEPGP.PollRate then 
				quit = true;
				return;
			end
			if limit ~= GetNumGuildMembers() then
				quit = true;
				CEPGP_Info.Guild.Polling = false;
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
				return;
			end
			i = i + 1;
			local name, rank, rankIndex, _, class, _, _, _, online, _, classFileName = GetGuildRosterInfo(i);
			if name then
				name = Ambiguate(name, "all");
				tempRoster[name] = nil;
				local EP, GP = CEPGP_getEPGP(name, i);
				local PR = math.floor((EP/GP)*100)/100;
				CEPGP_Info.Guild.Roster[name] = {
					[1] = i,
					[2] = class,
					[3] = rank,
					[4] = rankIndex,
					[5] = officerNote,
					[6] = PR,
					[7] = classFileName,
					[8] = online,
					[9] = (CEPGP.Guild.Exclusions[rankIndex+1] and true or nil),
					[10] = (CEPGP.Guild.Filter[rankIndex+1] and true or nil)
				};
				if CEPGP_Info.Import.Running or CEPGP_Info.Traffic.Sharing then
					if CEPGP_Info.Import.Running and CEPGP_Info.Import.Source == name then
						if not online then
							CEPGP_print(name .. " is offline. Importing settings has ended.");
							CEPGP_settings_import_confirm:Enable();
							CEPGP_settings_import_verbose_check:Enable();
							CEPGP_interface_options_force_sync_button:Enable();
							CEPGP_Info.Import.Running = false;
							CEPGP_Info.Import.Source = "";
						end
					elseif CEPGP_Info.Traffic.Sharing and CEPGP_Info.Traffic.Source == name then
						if not online then
							CEPGP_print(name .. " is offline. Traffic sharing has ended.");
							CEPGP_Info.Traffic.Sharing = false;
							CEPGP_Info.Traffic.Source = "";
							CEPGP_traffic_share_status:SetText(name .. " is Offline");
							CEPGP_traffic_share:Enable();
							CEPGP_UpdateTrafficScrollBar();
							CEPGP_Info.Traffic.ImportEntries = {};
						end
					end
				end
				CEPGP_Info.Version.List[name] = CEPGP_Info.Version.List[name] or {};
				if online then
					CEPGP_Info.Version.List[name][1] = CEPGP_Info.Version.List[name][1] or "Addon not enabled";
				else
					CEPGP_Info.Version.List[name][1] = "Offline";
				end
			end

			if i >= limit then	--	Although it should never exceed the number of guild members normally, on login, the number of guild members returns 0 and when running this loop, i becomes 1
				update();
			end
		end, limit);
		
	elseif event == "GROUP_ROSTER_UPDATE" then
		if IsInRaid() or UnitInParty("player") then
			_G["CEPGP_button_raid"]:Show();
			if CEPGP_version:IsVisible() then
				CEPGP_version_raid_check:Show();
			end
		else
			_G["CEPGP_button_raid"]:Hide();
			_G["CEPGP_raid"]:Hide();
			if CEPGP_version:IsVisible() then
				CEPGP_version_raid_check:Hide();
				CEPGP_Info.Version.ListSearch = "GUILD";
				CEPGP_UpdateVersionScrollBar();
			end
			CEPGP_Info.Raid.Roster = {};
		end
		--CEPGP_Info.Raid.Roster = {};
		
		local shadowRoster = {};
		
		local function update()			
			CEPGP_Info.Raid.Roster = shadowRoster;
			if UnitInRaid("player") or UnitInParty("player") then
				ShowUIPanel(CEPGP_button_raid);
				
			else --[[ Hides the raid and loot distribution buttons if the player is not in a raid group ]]--
				CEPGP_Info.Mode = "guild";
				CEPGP_toggleFrame("CEPGP_guild");
			end
			if _G["CEPGP_raid"]:IsVisible() then
				CEPGP_UpdateRaidScrollBar();
			end
		end
		
		local i = 0;
		--for i = 1, GetNumGroupMembers() do
		local limit = GetNumGroupMembers();
		
		C_Timer.NewTicker(CEPGP.PollRate, function()
			i = i + 1;
			local name = GetRaidRosterInfo(i);
			
			if not UnitInRaid("player") then
				CEPGP.Standby.Roster = {};
				if CEPGP_standby_options:IsVisible() then
					CEPGP_UpdateStandbyScrollBar();
				end
			else
				for k, v in ipairs(CEPGP.Standby.Roster) do
					if v[1] == name then
						table.remove(CEPGP.Standby.Roster, k); --Removes player from standby list if they have joined the raid
						if CEPGP_isML() == 0 then
							CEPGP_addAddonMsg("StandbyRemoved;" .. name .. ";You have been removed from the standby list because you have joined the raid.", "WHISPER", name);
						end
						if CEPGP_standby_options:IsVisible() then
							CEPGP_UpdateStandbyScrollBar();
						end
					end
				end
			end
			
			local _, _, _, _, class, classFileName = GetRaidRosterInfo(i);
			local isML = select(11, GetRaidRosterInfo(i));
			local index = CEPGP_getIndex(name);
			local rank;
			
			if index then
				
				rank = select(2, GetGuildRosterInfo(index));
				local rankIndex = select(3, GetGuildRosterInfo(index));
				
				EP, GP = CEPGP_getEPGP(name, index);
				local PR = math.floor((EP/GP)*100)/100;
				
				shadowRoster[i] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = rankIndex,
					[5] = EP,
					[6] = GP,
					[7] = PR,
					[8] = classFileName,
					[9] = isML
				};
			else
				rank = "Not in Guild";
				shadowRoster[i] = {
					[1] = name,
					[2] = class,
					[3] = rank,
					[4] = 11,
					[5] = 0,
					[6] = CEPGP.GP.Min,
					[7] = 0,
					[8] = classFileName,
					[9] = isML
				};
			end
			if i == limit then
				update();
			end
		end, limit);
	end
end

function CEPGP_getUnit(name)
	if name == UnitName("player") then return "player"; end
	for i = 1, GetNumGroupMembers() do
		local raidn = GetRaidRosterInfo(i);
		if name == raidn then
			if i < 5 then
				return "party" .. i-1;
			else
				return "raid" .. i;
			end
		end
	end
end

function CEPGP_addToStandby(player, playerList)
	if not player and not playerList then return; end
	
	if player and player == UnitName("player") then
		CEPGP_print("You cannot add yourself to the standby list.", true);
		return;
	end
	
	--	Adding a few associative arrays for faster checking
	local raidRoster = {};
	local standbyRoster = {};
	local alts = {};
	
	if not UnitInRaid("player") then
		CEPGP_print("You cannot add players to the standby list while not in a raid group.", true);
		return;
	end
	
	if player then
		if not CEPGP_Info.Guild.Roster[player] then
			for i = 1, GetNumGuildMembers() do	--	Checks for case sensitivity
				local name = Ambiguate(GetGuildRosterInfo(i), "all");
				if string.lower(player) == string.lower(name) then
					player = name;
					break;
				end
			end
			if not CEPGP_Info.Guild.Roster[player] then	--	If they're still not found then they musn't be a guild member
				CEPGP_print(player .. " is not a guild member", true);
				return;
			end
		end
	end

	for _, data in ipairs(CEPGP_Info.Raid.Roster) do
		local name = data[1];
		if player and string.lower(player) == string.lower(name) then
			CEPGP_print(player .. " is part of the raid", true);
			return;
		end
		if CEPGP_Info.Guild.Roster[name] then
			local index = CEPGP_getIndex(name, CEPGP_Info.Guild.Roster[name][1]);
			raidRoster[name] = {index};
		end
	end
	
	for _, data in ipairs(CEPGP.Standby.Roster) do
		local name = data[1];
		if player and string.lower(player) == string.lower(name) then
			CEPGP_print(name .. " is already on the standby list", true);
			return;
		end
		standbyRoster[name] = "";
	end
	
	for main, data in pairs(CEPGP.Alt.Links) do
		for _, alt in ipairs(data) do
			alts[alt] = main;
		end
	end
	
	if player then	--	If just one player is being added
		local main = alts[player];
		if raidRoster[main] then	--	If an alt and a main are in the raid
			CEPGP_print("The main of " .. player .. " is in the raid", true);
		end
		if CEPGP.Alt.Links[player] then	--	If the character is a main
			for _, alt in ipairs(CEPGP.Alt.Links[player]) do
				if raidRoster[alt] or standbyRoster[alt] then
					CEPGP_print("An alt of " .. player .. " is already " .. (raidRoster[main] and "in the raid" or "on the standby list"), true);
					return;
				end
			end
		elseif alts[player] then	--	If the character is an alt
			local main = alts[player];
			if raidRoster[main] or standbyRoster[main] then
				CEPGP_print("The main of " .. player .. " is already " .. (raidRoster[main] and "in the raid" or "on the standby list"), true);
				return;
			end
		end
		
		local _, class, rank, rankIndex, _, _, classFile = CEPGP_getGuildInfo(player);
		local index = CEPGP_getIndex(CEPGP_Info.Guild.Roster[player][1]);
		local EP,GP = CEPGP_getEPGP(player, index);
		local entry = {
			[1] = player,
			[2] = class,
			[3] = rank,
			[4] = rankIndex,
			[5] = EP,
			[6] = GP,
			[7] = math.floor((tonumber(EP)*100/tonumber(GP)))/100,
			[8] = classFile
		};
		
		table.insert(CEPGP.Standby.Roster, entry);
		CEPGP.Standby.Roster = CEPGP_tSort(CEPGP.Standby.Roster, 1);
		if CEPGP.Standby.Share then CEPGP_addAddonMsg("StandbyListAdd;"..player..";"..class..";"..rank..";"..rankIndex..";"..EP..";"..GP..";"..classFile, "RAID"); end
		CEPGP_addAddonMsg("StandbyAdded;" .. player .. ";You have been added to the standby list.", "GUILD");
	
	else --	If a list of players is being imported
		for index, data in ipairs(playerList) do
			local player, class, rank, rankIndex, EP, GP, PR, classFile = data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8];
			local valid = true;
			
			if raidRoster[player] or standbyRoster[player] then
				valid = false;
			end
			
			if CEPGP.Alt.Links[player] and valid then	--	If the character is a main, no point in checking if it's not valid
				for _, alt in ipairs(CEPGP.Alt.Links[player]) do
					if raidRoster[alt] or standbyRoster[alt] then
						valid = false;
					end
				end
			end
			
			if alts[player] and valid then	--	If the character is an alt
				local main = alts[player];
				if raidRoster[main] or standbyRoster[main] then
					valid = false;
				end
			end
			
			if valid then
				local entry = {
					[1] = player,
					[2] = class,
					[3] = rank,
					[4] = rankIndex,
					[5] = EP,
					[6] = GP,
					[7] = PR,
					[8] = classFile
				};
				
				table.insert(CEPGP.Standby.Roster, entry);
			else
				table.remove(playerList, index);
			end
		end
	end
	
	if CEPGP_standby_options:IsVisible() then
		if CEPGP_standby_options:IsVisible() then
			CEPGP_UpdateStandbyScrollBar();
		end
	end
end

function CEPGP_standardiseString(str)
	--Returns the string with proper nouns capitalised
	if not str then return; end
	local words = {};
	
	local count = 0;
	for i in (str .. " "):gmatch("([^ ]*) ") do
		if count == 0 then
			if string.lower(i) == "the" then
				count = count + 1;
				words[count] = "The";
			else
				count = count + 1;
				words[count] = string.upper(string.sub(i, 1, 1)) .. string.lower(string.sub(i, 2, string.len(i)));
			end
		else
			if string.lower(i) == "the" or string.lower(i) == "of" then
				count = count + 1;
				words[count] = string.lower(i);
			else
				count = count + 1;
				words[count] = string.upper(string.sub(i, 1, 1)) .. string.lower(string.sub(i, 2, string.len(i)));
			end
		end
	end
	local result = "";
	for i = 1, count do
		if i == 1 then
			result = words[i];
		elseif i <= count then
			result = result .. " " .. words[i];
		end
	end
	
	return result;
end

function CEPGP_refreshOptions()
	if CEPGP_options_alt_mangement:IsVisible() then
		CEPGP_options_alt_mangement:Hide();
		CEPGP_options_alt_mangement:Show();
		
	elseif CEPGP_EP_options:IsVisible() then
		CEPGP_EP_options:Hide();
		CEPGP_EP_options:Show();
		
	elseif CEPGP_GP_options:IsVisible() then
		CEPGP_GP_options:Hide();
		CEPGP_GP_options:Show();
		
	elseif CEPGP_loot_options:IsVisible() then
		CEPGP_loot_options:Hide();
		CEPGP_loot_options:Show();
		
	elseif CEPGP_standby_options:IsVisible() then
		CEPGP_standby_options:Hide();
		CEPGP_standby_options:Show();
		
	end
	
end

function CEPGP_toggleStandbyRanks(show)
	if show then
		CEPGP_options_standby_ep_accept_whispers_check:Disable();
		CEPGP_options_standby_ep_message_val:Disable();
		CEPGP_options_standby_ep_accept_whispers_check_label:SetTextColor(0.5, 0.5, 0.5);
		CEPGP_options_standby_ep_message_val:SetTextColor(0.5, 0.5, 0.5);
		CEPGP_options_standby_ep_message_val_label:SetTextColor(0.5, 0.5, 0.5);
		CEPGP_standby_ep_list_add:Hide();
		CEPGP_standby_ep_list_addbyrank:Hide();
		CEPGP_standby_ep_list_purge:Hide();
		CEPGP_options_standby_ep_byrank_check:SetChecked(true);
		CEPGP_options_standby_ep_manual_check:SetChecked(false);
		CEPGP_standby_scrollframe:Hide();
		
		for i = 1, 10 do
			local rank = GuildControlGetRankName(i);
			if rank == "" then
				_G["CEPGP_options_standby_ep_check_rank_" .. i]:Hide();
			else
				_G["CEPGP_options_standby_ep_check_rank_" .. i]:Show();
				_G["CEPGP_options_standby_ep_check_rank_" .. i .. "_label"]:SetText(rank);
			end
		end
	else
		CEPGP_options_standby_ep_accept_whispers_check:Enable();
		CEPGP_options_standby_ep_message_val:Enable();
		CEPGP_options_standby_ep_accept_whispers_check_label:SetTextColor(1, 1, 1);
		CEPGP_options_standby_ep_message_val:SetTextColor(1, 1, 1);
		CEPGP_options_standby_ep_message_val_label:SetTextColor(1, 1, 1);
		CEPGP_standby_ep_list_add:Show();
		CEPGP_standby_ep_list_addbyrank:Show();
		CEPGP_standby_ep_list_purge:Show();
		CEPGP_options_standby_ep_byrank_check:SetChecked(false);
		CEPGP_options_standby_ep_manual_check:SetChecked(true);
		CEPGP_standby_scrollframe:Show();
		
		for i = 1, 10 do
			_G["CEPGP_options_standby_ep_check_rank_" .. i]:Hide();
		end
	end
end

function CEPGP_getGuildInfo(name)
	if CEPGP_Info.Guild.Roster[name] then
		local index = CEPGP_getIndex(name);
		local _, _, _, _, _, _, _, oNote = GetGuildRosterInfo(index);
		return index, CEPGP_Info.Guild.Roster[name][2], CEPGP_Info.Guild.Roster[name][3], CEPGP_Info.Guild.Roster[name][4], oNote, CEPGP_Info.Guild.Roster[name][6], CEPGP_Info.Guild.Roster[name][7];  -- index, class, Rank, RankIndex, OfficerNote, PR, className in English
	else
		return nil;
	end
end

function CEPGP_getVal(str)
	local val = nil;
	val = strsub(str, strfind(str, " ")+1, string.len(str));
	return val;
end

function CEPGP_getIndex(name, index)
	if not IsInGuild() then return nil; end
	if not name then return; end
	
	if not index then
		if CEPGP_Info.Guild.Roster[name] and CEPGP_Info.Guild.Roster[name][1] <= GetNumGuildMembers() then
			index = CEPGP_Info.Guild.Roster[name][1];
		end
	end
	
	if index and index <= GetNumGuildMembers() then
		local temp = Ambiguate(GetGuildRosterInfo(index), "all");
		if string.lower(temp) == string.lower(name) then
			return index;
		else
			for i = 1, GetNumGuildMembers() do
				local temp = Ambiguate(GetGuildRosterInfo(i), "all");
				if string.lower(temp) == string.lower(name) then
					return i;
				end
			end
		end
	else	-- no index is supplied
		for i = 1, GetNumGuildMembers() do
			local temp = Ambiguate(GetGuildRosterInfo(i), "all");
			if string.lower(temp) == string.lower(name) then
				return i;
			end
		end
	end
end

function CEPGP_indexToName(index)
	for name,value in pairs(CEPGP_Info.Guild.Roster) do
		if value[1] == index then
			return name;
		end
	end
end

function CEPGP_getEPGP(name, index)
	if not index and not name then return; end
	local offNote;
	
	index = CEPGP_getIndex(name, index);
	if not index then return 0, CEPGP.GP.Min; end
	_, _, _, _, _, _, _, offNote = GetGuildRosterInfo(index);
	
	local EP, GP = nil;
	
	if not CEPGP_checkEPGP(offNote) then
		return 0, CEPGP.GP.Min;
	else
		EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
		GP = tonumber(strsub(offNote, strfind(offNote, ",")+1, string.len(offNote)));
		GP = math.max(math.floor(GP), CEPGP.GP.Min);
		return EP, GP;
	end
end

function CEPGP_checkEPGP(note)
	if not note then return false; end
	
	if string.find(note, '[^0-9,-]') or #note == 0 then
		return false;
	end
	if string.find(note, '^[0-9]+,[0-9]+$') then --EPGP is positive
		return true;
	elseif string.find(note, '^%-[0-9]+,[0-9]+$') then --EP is negative
		return true;
	elseif string.find(note, '^[0-9]+,%-[0-9]+$') then --GP is negative
		return true;
	elseif string.find(note, '^%-[0-9]+,%-[0-9]+$') then --EPGP is negative
		return true;
	else
		return false;
	end
end

function CEPGP_getItemString(link)
	if not link then
		return nil;
	end
	local itemString = string.find(link, "item[%-?%d:]+");
	if not itemString then return nil; end
	itemString = strsub(link, itemString, string.len(link)-(string.len(link)-2)-6);
	return itemString;
end

function CEPGP_getItemID(iString)
	if not iString or not string.find(iString, "item:") then
		return nil;
	end
	local itemString = string.sub(iString, string.find(iString, "item:")+5, string.len(iString)-1)
	return string.sub(itemString, 1, string.find(itemString, ":")-1);
end

function CEPGP_getItemLink(id, func)
	if not tonumber(id) or not CEPGP_itemExists(id) then return; end
	id = tonumber(id);
	local name, _, rarity = GetItemInfo(id);
	if not name then
		local item = Item:CreateFromItemID(tonumber(id));
		item:ContinueOnItemLoad(function()
			name, _, rarity = GetItemInfo(id);
			if rarity == 0 then -- Poor
				return "\124cff9d9d9d\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			elseif rarity == 1 then -- Common
				return "\124cffffffff\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			elseif rarity == 2 then -- Uncommon
				return "\124cff1eff00\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			elseif rarity == 3 then -- Rare
				return "\124cff0070dd\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			elseif rarity == 4 then -- Epic
				return "\124cffa335ee\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			elseif rarity == 5 then -- Legendary
				return "\124cffff8000\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
			end
			func();
		end);
	else
		if rarity == 0 then -- Poor
			return "\124cff9d9d9d\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		elseif rarity == 1 then -- Common
			return "\124cffffffff\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		elseif rarity == 2 then -- Uncommon
			return "\124cff1eff00\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		elseif rarity == 3 then -- Rare
			return "\124cff0070dd\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		elseif rarity == 4 then -- Epic
			return "\124cffa335ee\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		elseif rarity == 5 then -- Legendary
			return "\124cffff8000\124Hitem:" .. id .. ":::::::::::::\124h[" .. name .. "]\124h\124r";
		end
		func();
	end
end

function CEPGP_SlotNameToID(name)
	if name == nil then
		return nil
	end
	if name == "HEAD" then
		return 1;
	elseif name == "NECK" then
		return 2;
	elseif name == "SHOULDER" then
		return 3;
	elseif name == "CHEST" or name == "ROBE" then
		return 5;
	elseif name == "WAIST" then
		return 6;
	elseif name == "LEGS" then
		return 7;
	elseif name == "FEET" then
		return 8;
	elseif name == "WRIST" then
		return 9;
	elseif name == "HAND" then
		return 10;
	elseif name == "FINGER" then
		return 11, 12;
	elseif name == "TRINKET" then
		return 13, 14;
	elseif name == "CLOAK" then
		return 15;
	elseif name == "2HWEAPON" or name == "WEAPON" or name == "WEAPONMAINHAND" or name == "WEAPONOFFHAND" or name == "SHIELD" or name == "HOLDABLE" then
		return 16, 17;
	elseif name == "RANGED" or name == "RANGEDRIGHT" or name == "RELIC" then
		return 18;
	end
end

function CEPGP_inOverride(link)
	local id;
	id = CEPGP_getItemID(CEPGP_getItemString(link));
	if id then
		for item, _ in pairs(CEPGP.Overrides) do
			local temp = CEPGP_getItemID(CEPGP_getItemString(item));
			if id == temp then
				return true;
			end
		end
	else
		if CEPGP.Overrides[link] then
			return true;
		end
	end
	return false;
end

function CEPGP_updateOverride(id)
	if not id then return; end
	id = tonumber(id);
	local link = CEPGP_getItemLink(id);
	local name = GetItemInfo(id);
	for item, v in pairs(CEPGP.Overrides) do
		if string.lower(name) == string.lower(item) then
			CEPGP.Overrides[link] = v;
			CEPGP.Overrides[item] = nil;
			return;
		end
	end
end

function CEPGP_tContains(t, val, isKey)
	if not t then return; end
	
	if isKey then
		for index,_ in pairs(t) do 
			if index == val then
				return true;
			end
		end
	else
		for _,value in pairs(t) do
			if type(value) == "table" then	--	If the first tier of the table is a nested table
				for k, v in pairs(value) do
					if val == k then	--	The key can't be nil so no need to check
						return true;
					end
					if v then	--	Need to make sure the nested value isn't nil
						if val == v then
							return true;
						end
					end
				end
			else
				if value == val then	--	The first tier isn't nested, it's just a simple k, v pair
					return true;
				end
			end
		end
	end
	
	return false;
end

function CEPGP_isNumber(num)
	return not (string.find(tostring(num), '[^-0-9.]+') or string.find(tostring(num), '[^-0-9.]+$'));
end

function CEPGP_isML()
	local _, isML = GetLootMethod();
	return isML;
end

function CEPGP_tSort(_t, index, inverse)
	local t = _t;
	if not t then return; end
	if #t == 1 then return t; end
	if index then	--	2 dimensional table
		for x = 1, #t do
			for z = x+1, #t do
				local xIndex = t[x][index];
				local zIndex = t[z][index];
				if inverse then
					if xIndex < zIndex then
						local v = t[x];
						t[x] = t[z];
						t[z] = v;
					end
				else
					if xIndex > zIndex then
						local v = t[x];
						t[x] = t[z];
						t[z] = v;
					end
				end
			end
		end
	else	--	1 dimensional table
		for x = 1, #t do
			for z = x+1, #t do
				if t[x] > t[z] then
					local v = t[x];
					t[x] = t[z];
					t[z] = v;
				end
			end
		end
	end
	
	return t;
end

function CEPGP_sortDistList(list)
	local temp = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {}
	};
	
	for i = 7, #CEPGP_Info.LootSchema+7 do
		temp[i] = {};
	end
	
	local function getKeyIndex(key)
		for index, label in pairs(CEPGP_Info.LootSchema) do
			if label == key then
				return index;
			end
		end
	end
	for i = 1, #list do
		if CEPGP_Info.LootSchema[tonumber(list[i][11])] then
			local entry = {
				[1] = list[i][1],
				[2] = list[i][2],
				[3] = list[i][3],
				[4] = list[i][4],
				[5] = list[i][5],
				[6] = list[i][6],
				[7] = list[i][7],
				[8] = list[i][8],
				[9] = list[i][9],
				[10] = list[i][10],
				[11] = list[i][11],
				[12] = list[i][12]
			};
			--local index = getKeyIndex(list[i][11]);
			local index = tonumber(list[i][11]);
			table.insert(temp[index], entry);
		end
	end
	for i = 1, #temp do
		for x = 1, #temp[i] do
			for z = x+1, #temp[i] do
				if temp[i][x][7] < temp[i][z][7] then
					local v = temp[i][x];
					temp[i][x] = temp[i][z];
					temp[i][z] = v;
				end
			end
		end
	end
	local result = {};
	for i = 1, #temp do	--	Response level
		for x = 1, #temp[i]	do	--	Entry index
			local response = i <= 6 and i or temp[i][x][11];
			local entry = {
				[1] = temp[i][x][1],	--	Character Name
				[2] = temp[i][x][2],	--	Localised class name
				[3] = temp[i][x][3],	--	Guild Rank
				[4] = temp[i][x][4],	--	Guild Rank Index
				[5] = temp[i][x][5],	--	EP
				[6] = temp[i][x][6],	--	GP
				[7] = temp[i][x][7],	--	PR
				[8] = temp[i][x][8],	--	Item ID 1
				[9] = temp[i][x][9],	--	Item ID 2
				[10] = temp[i][x][10],	--	Class name in English
				[11] = response,		--	Response
				[12] = temp[i][x][12]	--	Roll
			};
			table.insert(result, entry);
		end
	end
	
	return result;
end

function CEPGP_ntgetn(tbl)
	if tbl == nil then
		return 0;
	end
	local n = 0;
	for _,_ in pairs(tbl) do
		n = n + 1;
	end
	return n;
end

function CEPGP_setCriteria(sortIndex, method)
	if not method then return; end
	
	if method == "Raid" then
		if CEPGP_Info.Sorting.Raid[1] == sortIndex then
			CEPGP_Info.Sorting.Raid[2] = not CEPGP_Info.Sorting.Raid[2];
		else
			CEPGP_Info.Sorting.Raid[1] = sortIndex;
		end
		if CEPGP_raid:IsVisible() then
			CEPGP_UpdateRaidScrollBar();
		end
		
	elseif method == "Guild" then
		if CEPGP_Info.Sorting.Guild[1] == sortIndex then
			CEPGP_Info.Sorting.Guild[2] = not CEPGP_Info.Sorting.Guild[2];
		else
			CEPGP_Info.Sorting.Guild[1] = sortIndex;
		end
		if CEPGP_guild:IsVisible() then
			CEPGP_UpdateGuildScrollBar();
		end
	elseif method == "Loot" then
		if CEPGP_Info.Sorting.Loot[1] == sortIndex then
			CEPGP_Info.Sorting.Loot[2] = not CEPGP_Info.Sorting.Loot[2];
		else
			CEPGP_Info.Sorting.Loot[1] = sortIndex;
		end
		if CEPGP_distribute:IsVisible() then
			CEPGP_UpdateLootScrollBar(nil, true);
		end
	elseif method == "Standby" then
		if CEPGP_Info.Sorting.Standby[1] == sortIndex then
			CEPGP_Info.Sorting.Standby[2] = not CEPGP_Info.Sorting.Standby[2];
		else
			CEPGP_Info.Sorting.Standby[1] = sortIndex;
		end
		if CEPGP_standby_options:IsVisible() then
			CEPGP_UpdateStandbyScrollBar();
		end
	elseif method == "Attendance" then
		if CEPGP_Info.Sorting.Attendance[1] == sortIndex then
			CEPGP_Info.Sorting.Attendance[2] = not CEPGP_Info.Sorting.Attendance[2];
		else
			CEPGP_Info.Sorting.Attendance[1] = sortIndex;
		end
		CEPGP_UpdateAttendanceScrollBar();
	elseif method == "Version" then
		if CEPGP_Info.Sorting.Version[1] == sortIndex then
			CEPGP_Info.Sorting.Version[2] = not CEPGP_Info.Sorting.Version[2];
		else
			CEPGP_Info.Sorting.Version[1] = sortIndex;
		end
		if CEPGP_version:IsVisible() then
			CEPGP_UpdateVersionScrollBar();
		end
	end
end

function CEPGP_toggleBossConfigFrame(fName)
	for _, frame in pairs(CEPGP_Info.BossEPFrames) do
		if frame:GetName() ~= fName then
			HideUIPanel(frame);
		else
			frame:Show();
		end;
	end
end

function CEPGP_getPlayerClass(name, index)
	if not index and not name then return; end
	if index then index = CEPGP_getIndex(name); end
	local class;
	if name == "Guild" then
		return _, {r=0, g=1, b=0};
	end
	if name == "Raid" then
		return _, {r=1, g=0.10, b=0.10};
	end
	if index then
		_, _, _, _, _, _, _, _, _, _, classFileName = GetGuildRosterInfo(index);
		return class, CEPGP_Info.ClassColours[classFileName];
	else
		index = CEPGP_getIndex(name);
		if not index then
			return nil;
		else
			_, _, _, _, _, _, _, _, _, _, classFileName = GetGuildRosterInfo(index);
			return class, CEPGP_Info.ClassColours[classFileName];
		end
	end
end

function CEPGP_recordAttendance()
	if not UnitInRaid("player") and not CEPGP_Info.Debug then
		CEPGP_print("You are not in a raid group", true);
		return;
	end
	CEPGP.Attendance[#CEPGP.Attendance+1] = {
		[1] = time()
	};
	for i = 1, GetNumGroupMembers(), 1 do
		CEPGP.Attendance[#CEPGP.Attendance][i+1] = {
			[1] = GetRaidRosterInfo(i),
			[2] = false --Are they a standby player? Nope.
		};
	end
	for k, v in ipairs(CEPGP.Standby.Roster) do
		CEPGP.Attendance[#CEPGP.Attendance][#CEPGP.Attendance[#CEPGP.Attendance]+1] = { --CEPGP.Attendance[index][timestamp][1] = player name, [2] = bool
			[1] = v[1],
			[2] = true --Are they a standby player? YUP.
		};
	end
	CEPGP_print("Snapshot recorded");
	CEPGP_UpdateAttendanceScrollBar();
end

function CEPGP_deleteAttendance()
	local index = UIDropDownMenu_GetSelectedValue(CEPGP_attendance_dropdown);
	if not index or index == 0 then
		CEPGP_print("Select a snapshot and try again", true);
		return;
	end
	CEPGP_print("Deleted snapshot: " .. date("%d/%m/%Y %H:%M", CEPGP.Attendance[index][1]));
	local size = CEPGP_ntgetn(CEPGP.Attendance);
	for i = index, size-1 do
		CEPGP.Attendance[index] = CEPGP.Attendance[index+1];
	end
	CEPGP.Attendance[size] = nil;
	CEPGP_Info.Attendance.SelectedSnapshot = nil;
	UIDropDownMenu_SetSelectedValue(CEPGP_attendance_dropdown, 0);
	CEPGP_UpdateAttendanceScrollBar();
end

function CEPGP_formatExport()
	--form is the export format
	local temp = {};
	local text = "";
	local count = 0;
	for name, v in pairs(CEPGP_Info.Guild.Roster) do
	--for i = 1, GetNumGuildMembers() do
		local index = CEPGP_getIndex(name);
		local name = Ambiguate(GetGuildRosterInfo(index), "all");
		local EP,GP = CEPGP_getEPGP(name, index);
		temp[#temp+1] = {
			[1] = name,
			[2] = v[2], -- Class
			[3] = v[3], -- Guild Rank
			[4] = EP .. "," .. GP, -- Officer Note, processed like this incase the officer note is blank
			[5] = math.floor((EP/GP)*100)/100 -- Priority
		};
	end
	temp = CEPGP_tSort(temp, 1);
	
	local form = _G["CEPGP_export"]:GetAttribute("format");
	
	
	if form == "CSV" then
		for i = 1, #temp do
			text = text .. temp[i][1];
			if CEPGP_export_class_check:GetChecked() then
				text = text .. "," .. temp[i][2]; -- Class
			end
			if CEPGP_export_rank_check:GetChecked() then
				text = text .. "," .. temp[i][3];
			end
			text = text .. "," .. temp[i][4];
			if CEPGP_export_PR_check:GetChecked() then
				text = text .. "," .. temp[i][5];
			end
			if CEPGP_export_trailing_check:GetChecked() then
				text = text .. ",\n";
			else
				text = text .. "\n";
			end
		end
		_G["CEPGP_export_dump"]:SetText(text);
		_G["CEPGP_export_dump"]:HighlightText();
		
		
	elseif form == "JSON" then
		text = "{";
		text = text .. "\"roster\": [";
		for i = 1, #temp do
			text = text .. "[\"" .. temp[i][1] .. "\""; -- Player Name
			if CEPGP_export_class_check:GetChecked() then
				text = text .. ",\"" .. temp[i][2] .. "\""; -- Class
			end
			if CEPGP_export_rank_check:GetChecked() then
				text = text .. ",\"" .. temp[i][3] .. "\""; -- Guild Rank
			end
			text = text .. "," .. temp[i][4];
			text = text .. "," .. temp[i][5];
			if i+1 <= #temp then
				text = text .. "],";
			else
				text = text .. "]";
			end
		end
		text = text .. "],";
		text = text .. "\"timestamp\":" .. time() .. "";
		text = text .. "}";
		_G["CEPGP_export_dump"]:SetText(text);
		_G["CEPGP_export_dump"]:HighlightText();
	end
end

function CEPGP_calcAttendance(name)
	local count = 0;
	local cWeek = 0; --count week
	local cFN = 0; --count fornight
	local cMonth = 0; --count month
	local cTwoMonth = 0; --count 2 months
	local cThreeMonth = 0; --count 3 months
	for _, v in pairs(CEPGP.Attendance) do
		for i = 2, CEPGP_ntgetn(v), 1 do
			local diff = time() - v[1];
			diff = diff/60/60/24;
			if v[i] == name then --Accommodates for the old raid attendance structure
				count = count + 1;
				if diff <= 90 then
					cThreeMonth = cThreeMonth + 1;
					if diff <= 60 then
						cTwoMonth = cTwoMonth + 1;
						if diff <= 30 then
							cMonth = cMonth + 1;
							if diff <= 14 then
								cFN = cFN + 1;
								if diff <= 7 then
									cWeek = cWeek + 1;
								end
							end
						end
					end
				end
				break;
			elseif v[i][1] == name then --Accommodates for the new raid attendance structure (i.e. [1] = name, [2] = bool for standby roster
				local diff = time() - v[1];
				diff = diff/60/60/24;
				count = count + 1;
				if diff <= 90 then
					cThreeMonth = cThreeMonth + 1;
					if diff <= 60 then
						cTwoMonth = cTwoMonth + 1;
						if diff <= 30 then
							cMonth = cMonth + 1;
							if diff <= 14 then
								cFN = cFN + 1;
								if diff <= 7 then
									cWeek = cWeek + 1;
								end
							end
						end
					end
				end
				break;
			end
		end
	end
	return count, cWeek, cFN, cMonth, cTwoMonth, cThreeMonth;
end

function CEPGP_calcAttIntervals()
	local week = 0;
	local fn = 0;
	local mon = 0;
	local twoMon = 0;
	local threeMon = 0;
	for _, v in pairs(CEPGP.Attendance) do
		local diff = time() - v[1];
		diff = diff/60/60/24;
		if diff <= 90 then
			threeMon = threeMon + 1;
			if diff <= 60 then
				twoMon = twoMon + 1;
				if diff <= 30 then
					mon = mon + 1;
					if diff <= 14 then
						fn = fn + 1;
						if diff <= 7 then
							week = week + 1;
						end
					end
				end
			end
		end
	end
	return week, fn, mon, twoMon, threeMon;
end

function CEPGP_callItem(id, gp, buttons, timeout)
	if not id then return; end
	CEPGP_Info.Loot.ItemsTable = {};
	CEPGP_UpdateLootScrollBar();
	id = tonumber(id); -- Must be in a numerical format
	local name, link, _, _, _, _, _, _, _, tex, _, classID, subClassID = GetItemInfo(id);
	local iString;
	CEPGP_Info.LastRun.ItemCall = GetTime();
	CEPGP_Info.Loot.NumOnline = CEPGP_GetNumOnlineGroupMembers();
	local timestamp = CEPGP_Info.LastRun.ItemCall;
	
	local call;
	local timer = timeout-1;
	CEPGP_respond_timeout_string:Show();
	CEPGP_distribute_time:Show();
	if CEPGP.Loot.PRDifference then
		CEPGP_respond_gp_change:Show();
	else
		CEPGP_respond_gp_change:Hide();
	end
	CEPGP_respond_timeout_string:SetText("Time Remaining: " .. timer);
	CEPGP_distribute_time:SetText("Time Remaining: " .. timer);
	CEPGP_distribute_responses_received:SetText("0 of " .. CEPGP_Info.Loot.NumOnline .. " Responses Received");
	
	if tonumber(timeout) > 0 then
		local callback;
		callback = C_Timer.NewTicker(1, function()
			if CEPGP_Info.LastRun.ItemCall ~= timestamp then
				callback._remainingIterations = 1;
				return;
			end
			if CEPGP_ntgetn(CEPGP_Info.Loot.ItemsTable) == CEPGP_Info.Loot.NumOnline then
				CEPGP_distribute_time:SetText("All Responses Received");
				CEPGP_Info.Loot.Expired = true;
				callback._remainingIterations = 1;
				return;
			end
			if timer == 0 then
				CEPGP_distribute_time:SetText("Response Time Expired");
				if CEPGP_isML() == 0 and CEPGP.Loot.DelayResponses then
					CEPGP_announceResponses();
				end
				CEPGP_Info.Loot.Expired = true;
				if not CEPGP_respond:IsVisible() then
					return;
				end
				CEPGP_respond:Hide();
				CEPGP_Info.Loot.GUID = CEPGP_Info.Loot.GUID or "";
				CEPGP_addAddonMsg("LootRsp;6;" .. CEPGP_Info.Loot.GUID, "WHISPER", CEPGP_Info.Loot.Master);
				return;
			end
			timer = timer - 1;
			CEPGP_respond_timeout_string:SetText("Time Remaining: " .. timer);
			CEPGP_distribute_time:SetText("Time Remaining: " .. timer);
		end, timeout);
	else
		CEPGP_respond_timeout_string:Hide();
		CEPGP_distribute_time:Hide();
	end
	
	local playerName = UnitName("player")
	local prChangeText = ""
	if CEPGP_Info.Guild.Roster[playerName] then
		local index = CEPGP_getIndex(playerName);
		local EP, GP = CEPGP_getEPGP(playerName, index);
		local actualPR = math.floor((EP/GP)*100)/100
		local potentialPR = math.floor((EP/(GP+gp))*100)/100
		prChangeText = "PR: " .. actualPR .. " -> " .. potentialPR;
	end
	
	if not link and CEPGP_itemExists(id) then
		local item = Item:CreateFromItemID(id);
		item:ContinueOnItemLoad(function()
				_, link, _, _, _, _, _, _, _, tex, _, classID, subClassID = GetItemInfo(id)
				if not CEPGP_canEquip(classID, subClassID) and CEPGP.Loot.AutoPass then
					CEPGP_print("Cannot equip " .. link .. "|c006969FF. Passing on item.|r");
					CEPGP_addAddonMsg("LootRsp;6", "WHISPER", CEPGP_Info.Loot.Master);
					return;
				end
				iString = CEPGP_getItemString(link);
				_G["CEPGP_respond"]:Show();
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
				_G["CEPGP_respond_gp_value"]:SetText(gp);
				_G["CEPGP_respond_gp_change"]:SetText(prChangeText);
				for i = 1, 4 do
					if buttons[i] ~= "" and buttons[i] then
						_G["CEPGP_respond_"..i]:Show();
						_G["CEPGP_respond_"..i]:SetText(buttons[i]);
					else
						_G["CEPGP_respond_"..i]:Hide();
					end
				end
			end);
	else
		if not CEPGP_canEquip(classID, subClassID) and CEPGP.Loot.AutoPass then
			CEPGP_print("Cannot equip " .. link .. "|c006969FF. Passing on item.|r");
			CEPGP_addAddonMsg("LootRsp;6", "WHISPER", CEPGP_Info.Loot.Master);
			return;
		end
		iString = CEPGP_getItemString(link);
		_G["CEPGP_respond"]:Show();
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
		_G["CEPGP_respond_gp_value"]:SetText(gp);
		_G["CEPGP_respond_gp_change"]:SetText(prChangeText);
		for i = 1, 4 do
			if buttons[i] ~= "" and buttons[i] then
				_G["CEPGP_respond_"..i]:Show();
				_G["CEPGP_respond_"..i]:SetText(buttons[i]);
			else
				_G["CEPGP_respond_"..i]:Hide();
			end
		end
	end
end

function CEPGP_checkVersion(message)
	local temp = CEPGP_split(message, ";");
	local args = CEPGP_split(temp[3], ".");
	local version = {
		major = tonumber(args[1]),
		minor = tonumber(args[2]),
		revision = tonumber(args[3])
	};
	if args[4] then
		version.build = args[4];
	elseif temp[4] then
		version.build = temp[4];
	end
	
	--Current build information
	local curBuild = CEPGP_split(CEPGP_Info.Version.Number, ".");
	local current = {
		major = tonumber(curBuild[1]),
		minor = tonumber(curBuild[2]),
		revision = tonumber(curBuild[3]),
		build = CEPGP_Info.Version.Build
	};
	
	outMessage = "Your addon is out of date. Version " .. version.major .. "." .. version.minor .. "." .. version.revision .. " is now available for download."
	if not CEPGP_Info.VersionNotified and (version.build == "release" or version.build == "Release") then
		if version.major > current.major then 
			CEPGP_print(outMessage);
			CEPGP_Info.VersionNotified = true;
		elseif version.major == current.major and version.minor > current.minor then
			CEPGP_print(outMessage);
			CEPGP_Info.VersionNotified = true;
		elseif version.major == current.major and version.minor == current.minor and version.revision > current.revision then
			CEPGP_print(outMessage);
			CEPGP_Info.VersionNotified = true;
		end
	end
end

function CEPGP_split(msg, delim)
	local args = {};
	local count = 1;
	for i in (msg .. delim):gmatch("([^"..delim.."]*)" .. delim) do
		args[count] = i;
		count = count + 1;
	end
	return args;
end

function CEPGP_canEquip(classID, subClassID)
	if classID == 9 then return true; end
	local slot = GetItemSubClassInfo(classID, subClassID);
	local _, class = UnitClass("player");
	local temp = string.sub(class, 2, string.len(class));
	class = string.sub(class, 1, 1) .. string.lower(temp);
	if CEPGP_tContains(CEPGP_classes[class], slot) then return true; end
	return false;
end

function CEPGP_itemExists(id)
	if not id or not tonumber(id) then return false; end
	if C_Item.DoesItemExistByID(tonumber(id)) then
		return true;
	else
		return false;
	end
end

function CEPGP_getReportChannel(channel)
	local channels = {
		[1] = "Party",
		[2] = "Raid",
		[3] = "Guild",
		[4] = "Officer"
	};
	for k, v in ipairs(channels) do
		if string.upper(channel) == v then
			return string.upper(channel);
		end
	end
end

function CEPGP_sendChatMessage(msg, channel)
	if not msg then return; end
	SendChatMessage(msg, channel, CEPGP_Info.Language);
end

function CEPGP_toggleGPEdit(mode)
	if mode then
		CEPGP_options_coef_edit:Enable();
		CEPGP_options_coef_2_edit:Enable();
		CEPGP_options_mod_edit:Enable();
		CEPGP_options_gp_initial:Enable();
		CEPGP_loot_options_min_EP_check:Enable();
		CEPGP_loot_options_min_EP_amount:Enable();
		CEPGP_loot_options_show_passes_check:Enable();
		CEPGP_loot_options_enforce_PR_sorting_check:Enable();
		CEPGP_loot_options_dist_assist_check:Enable();
		CEPGP_loot_options_pass_roll_check:Enable();
		CEPGP_loot_options_announce_roll_check:Enable();
		CEPGP_loot_options_resolve_roll_check:Enable();
		for k, v in pairs(CEPGP.GP.SlotWeights) do
			if k ~= "ROBE" and k ~= "EXCEPTION" then
				_G["CEPGP_options_" .. k .. "_weight"]:Enable();
			end
		end
	else
		CEPGP_options_coef_edit:Disable();
		CEPGP_options_coef_2_edit:Disable();
		CEPGP_options_mod_edit:Disable();
		CEPGP_options_gp_initial:Disable();
		CEPGP_loot_options_min_EP_check:Disable();
		CEPGP_loot_options_min_EP_amount:Disable();
		CEPGP_loot_options_show_passes_check:Disable();
		CEPGP_loot_options_enforce_PR_sorting_check:Disable();
		CEPGP_loot_options_dist_assist_check:Disable();
		CEPGP_loot_options_pass_roll_check:Disable();
		CEPGP_loot_options_announce_roll_check:Disable();
		CEPGP_loot_options_resolve_roll_check:Disable();
		
		for k, v in pairs(CEPGP.GP.SlotWeights) do
			if k ~= "ROBE" and k ~= "EXCEPTION" then
				_G["CEPGP_options_" .. k .. "_weight"]:Disable();
			end
		end
	end
end

function CEPGP_saveStandings(name)
	if CEPGP.Backups[name] == nil or (CEPGP_Info.OverwriteLog and name == CEPGP_Info.RecordExists) then
		CEPGP.Backups[name] = {};
		SortGuildRoster(name);
		for i = 1, GetNumGuildMembers(), 1 do
			local _, _, _, _, _, _, _, oNote = GetGuildRosterInfo(i);
			CEPGP.Backups[name][GetGuildRosterInfo(i)] = oNote;
		end
		if CEPGP_Info.OverwriteLog then
			CEPGP_print("Record overwritten [" .. name .. "]");
			CEPGP_Info.OverwriteLog = false;
		else
			CEPGP_print("Record saved [" .. name .. "]");
		end
		HideUIPanel(CEPGP_save_guild_logs);
	else
		CEPGP_print("Record [" .. name .. "] already exists. Click confirm again to overwrite");
		CEPGP_Info.RecordExists = name;
		CEPGP_Info.OverwriteLog = true;
	end
end

function CEPGP_importStandings()
	local impString = CEPGP_import_dump:GetText();
	local frags = CEPGP_split(impString, ",");
	local output = _G["CEPGP_import_progress_dump"];
	CEPGP_import_dump:Disable();
	output:SetText("Checking import string...");
	for i = 1, #frags, 3 do
		local name, EP, GP;
		name = frags[i];
		if name then
			name = string.gsub(string.gsub(name, "\n", ""), " ", "");
			if #name == 0 or name == "" then
				frags[#frags] = nil;
				break;
			end
			EP = math.floor(frags[i+1]);
			GP = math.floor(frags[i+2]);
			if #name > 0 and EP and GP then
				if string.find(name, '[0-9!@#$%^&*(),.?":{}|<>]') then
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid name: " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				end
				if string.find(EP, '[^0-9]!@#$%^&*(),.?":{}|<>]') then
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid EP for " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				end
				if string.find(GP, '[^0-9]!@#$%^&*(),.?":{}|<>]') then
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid GP for " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				end
			else
				if #name == 0 then
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid name: " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				elseif #EP == 0 then
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid EP for " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				else
					output:SetText(output:GetText() .. "\n|c00FF0000Error: Invalid GP for " .. name .. ". Aborting.|r");
					CEPGP_import_dump:Enable();
					return;
				end
			end
		end
	end	
	output:SetText(output:GetText() .. "\nImport string is valid.\nSaving guild record...");
	local tStamp = date("%I:%M:%S%p, %a, %d %B %Y", time()) .. " (Backup)";
	CEPGP_saveStandings(tStamp);
	C_Timer.After(1, function()
		output:SetText(output:GetText() .. "\nGuild record saved.\nApplying changes...");
		CEPGP_Info.IgnoreUpdates = true;
		CEPGP_addAddonMsg("?IgnoreUpdates;true", "GUILD");
		C_Timer.After(1, function()
			for i = 1, #frags, 3 do
				local index, name, EP, GP;
				name = frags[i];
				if name then
					name = string.gsub(string.gsub(name, "\n", ""), " ", "");
					if #name == 0 or name == "" then
						frags[#frags] = nil;
						break;
					end
					EP = frags[i+1];
					GP = frags[i+2];
					index = CEPGP_getIndex(name);
					if index == nil then
						output:SetText(output:GetText() .. "\nSkipping record: " .. name);
					else
						--local rankIndex = select(3, GetGuildRosterInfo(index));
						if not CEPGP_Info.Guild.Roster[name][9] then
							output:SetText(output:GetText() .. "\nProcessing record: " .. name);
							GuildRosterSetOfficerNote(index, EP .. "," .. GP);
							CEPGP_import_progress_scrollframe:SetVerticalScroll(CEPGP_import_progress_scrollframe:GetVerticalScroll()+12);
						end
					end
				end
			end
			C_Timer.After(3, function()
				output:SetText(output:GetText() .. "\nImport complete.");
				CEPGP_Info.IgnoreUpdates = false;
				CEPGP_addAddonMsg("?IgnoreUpdates;false", "GUILD");
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
				CEPGP_import_dump:Enable();
			end);
		end);
	end);
end

function CEPGP_addPlugin(plugin, iPanel, enabled, func)	-- Addon name, interface panel, enabled status, function to toggle enabled status
	if not plugin then return; end
	for i = 1, GetNumAddOns() do
		local name = GetAddOnInfo(i);
		if name == plugin then
			table.insert(CEPGP_Info.Plugins, plugin);
			break;
		end
	end
	if not CEPGP_tContains(CEPGP_Info.Plugins, plugin) then
		CEPGP_print(plugin .. " couldn't be found. Plugin not loaded.", true);
		return;
	end
	
	local frame;
	if #CEPGP_Info.Plugins == 1 then
		frame = CreateFrame("Frame", "CEPGP_plugin_" .. 1, CEPGP_options_plugins, "PluginButtonTemplate");
		frame:SetPoint("TOPLEFT", CEPGP_options_plugins, "TOPLEFT", 0, -40);
	else
		frame = CreateFrame("Frame", "CEPGP_plugin_" .. #CEPGP_Info.Plugins, CEPGP_options_plugins, "PluginButtonTemplate");
		frame:SetPoint("TOPLEFT", _G["CEPGP_plugin_" .. #CEPGP_Info.Plugins-1], "BOTTOMLEFT");
	end
	local name = frame:GetName();
	if iPanel then
		_G[name .. "Name"]:SetText(iPanel.name);
		_G[name .. "Enabled"]:SetChecked(enabled);
		_G[name .. "Enabled"]:SetScript('OnClick', func);
		_G[name .. "Options"]:SetScript('OnClick', function()
			xpcall(function() InterfaceOptionsFrame_OpenToCategory(iPanel) end, geterrorhandler());
		end);
	else
		_G[name .. "Name"]:SetText(plugin);
		_G[name .. "Enabled"]:SetChecked(enabled);
		_G[name .. "Enabled"]:SetScript('OnClick', func);
		_G[name .. "Options"]:Hide();
	end
end

function CEPGP_addTraffic(target, source, desc, EPB, EPA, GPB, GPA, itemID, tStamp)
	
	if not source == UnitName("player") then return; end
	local id = time() + GetTime();
	
	EPB = EPB or "";
	EPA = EPA or "";
	GPB = GPB or "";
	GPA = GPA or "";
	itemID = itemID or "";
	tStamp = tstamp or time();
	
	
	if CEPGP_itemExists(tonumber(itemID)) then
		local itemLink = CEPGP_getItemLink(itemID);
		if not itemLink then
			local item = Item:CreateFromItemID(tonumber(itemID));
			item:ContinueOnItemLoad(function()
				itemLink = CEPGP_getItemLink(itemID);
	
				CEPGP.Traffic[#CEPGP.Traffic+1] = {
					[1] = target,
					[2] = source,
					[3] = desc,
					[4] = EPB,
					[5] = EPA,
					[6] = GPB,
					[7] = GPA,
					[8] = itemLink,
					[9] = tStamp,
					[10] = id,
					[11] = UnitGUID("player")
				};
				
			end);
		elseif itemLink then
			CEPGP.Traffic[#CEPGP.Traffic+1] = {
				[1] = target,
				[2] = source,
				[3] = desc,
				[4] = EPB,
				[5] = EPA,
				[6] = GPB,
				[7] = GPA,
				[8] = itemLink,
				[9] = tStamp,
				[10] = id,
				[11] = UnitGUID("player")
			};
		end
	else
		CEPGP.Traffic[CEPGP_ntgetn(CEPGP.Traffic)+1] = {
			[1] = target,
			[2] = source,
			[3] = desc,
			[4] = EPB,
			[5] = EPA,
			[6] = GPB,
			[7] = GPA,
			[8] = "",
			[9] = tStamp,
			[10] = id,
			[11] = UnitGUID("player")
		};
	end
	
	if CanEditOfficerNote() then
		CEPGP_addAddonMsg("CEPGP_TRAFFIC;" .. target .. ";" .. source .. ";" .. desc .. ";" .. EPB .. ";" .. EPA .. ";" .. GPB .. ";" .. GPA .. ";" .. itemID .. ";" .. tStamp .. ";" .. id .. ";" .. UnitGUID("player"), "GUILD");
	end
end

function CEPGP_keyExists(t, key)
	return t[key] ~= nil;
end

function CEPGP_addCharacterLink(main, alt)
	if not CEPGP.Alt.Links then
		CEPGP.Alt.Links = {};
	end
	
	for m, t in pairs(CEPGP.Alt.Links) do
		for k, v in pairs(t) do
			if string.lower(m) == string.lower(alt) then
				CEPGP_print(alt .. " is already marked as a main character", true);
				return;
			elseif string.lower(v) == string.lower(main) then
				CEPGP_print(main .. " is marked as an alt of " .. m .. " and cannot be a main character", true);
				return;
			elseif string.lower(v) == string.lower(alt) then
				CEPGP_print(alt .. " is already linked to " .. m, true);
				return;
			end
		end
	end
	
	if not CEPGP.Alt.Links[main] then
		CEPGP.Alt.Links[main] = {};
	end
	
	CEPGP.Alt.Links[main][#CEPGP.Alt.Links[main]+1] = alt;
	
	CEPGP_print(alt .. " is now an alt of " .. main);
end

function CEPGP_removeCharacterLink(main, alt)
	if not CEPGP.Alt.Links then
		CEPGP.Alt.Links = {};
	end
	
	if not CEPGP.Alt.Links[main] then
		CEPGP_print(alt .. " is not an alt of " .. main, true);
	elseif CEPGP.Alt.Links[main] and alt then
		for k, v in ipairs(CEPGP.Alt.Links[main]) do
			if v == alt then
				table.remove(CEPGP.Alt.Links[main], k);
				CEPGP_print(alt .. " is no longer linked to " .. main);
				if #CEPGP.Alt.Links[main] == 0 then
					CEPGP.Alt.Links[main] = nil;
				end
				return;
			end
		end
	elseif CEPGP.Alt.Links[main] then
		CEPGP.Alt.Links[main] = nil;
		CEPGP_print(main .. " and all linked alts have been released");
		return;
	else
		CEPGP_print(alt .. " is not an alt of " .. main, true);
	end
end

function CEPGP_encodeClassString(class, str)
	
	local colours = {
		["DRUID"] = "00FF7D0A",
		["HUNTER"] = "00A9D271",
		["MAGE"] = "0040C7EB",
		["PALADIN"] = "00F58CBA",
		["PRIEST"] = "00FFFFFF",
		["ROGUE"] = "00FFF569",
		["SHAMAN"] = "000070DE",
		["WARLOCK"] = "008787ED",
		["WARRIOR"] = "00C79C6E"
	}
	
	if class then
		return "|c" .. colours[class] .. str .. "|r";
	else
		return "|cFFFFFFFF" .. str .. "|r";
	end
end

function CEPGP_getMain(name)
	for mainName, v in pairs(CEPGP.Alt.Links) do
		for index, altName in pairs(v) do
			if name == altName then return mainName; end
		end
	end
end

--[[function CEPGP_syncAltStandings(main)
	if not main or not CEPGP.Alt.Links[main] then return; end
	if not CEPGP_Info.Guild.Roster[main] then return; end
	local mainIndex;
	for k, alt in pairs(CEPGP.Alt.Links[main]) do
		if CEPGP_Info.Guild.Roster[alt] then
			mainIndex = CEPGP_getIndex(main, CEPGP_Info.Guild.Roster[main] or nil);
			
			if CEPGP_Info.Guild.Roster[main][9] then
				CEPGP_print("Could not synchronise EPGP from " .. main .. " because they are in an excluded rank", true);
				return;
			end
			
			local index = CEPGP_getIndex(alt);
			local mEP,mGP = CEPGP_getEPGP(main, CEPGP_getIndex(main));	-- Standings of main
			local EP,GP = CEPGP_getEPGP(alt, index);	-- Standings of alt
			if CEPGP.Alt.SyncEP and CEPGP.Alt.SyncGP then
				GuildRosterSetOfficerNote(index, mEP .. "," .. mGP);
			elseif CEPGP.Alt.SyncEP then
				GuildRosterSetOfficerNote(index, mEP .. "," .. GP);
			elseif CEPGP.Alt.SyncGP then
				GuildRosterSetOfficerNote(index, EP .. "," .. mGP);
			end
		end
	end
end

function CEPGP_syncToMain(alt, index, main)
	if not alt or not main then return; end
	if not CEPGP_Info.Guild.Roster[main] then return; end
	local mainIndex = CEPGP_getIndex(main);
	
	if CEPGP_Info.Guild.Roster[main][9] then
		CEPGP_print("Could not synchronise EPGP with " .. main .. " because they are in an excluded rank", true);
		return;
	end
	
	local altEP, altGP = CEPGP_getEPGP(alt, index);
	local mainEP, mainGP = CEPGP_getEPGP(main, mainIndex);
	
	if CEPGP.Alt.SyncEP and CEPGP.Alt.SyncGP then
		GuildRosterSetOfficerNote(mainIndex, altEP .. "," .. altGP);
	elseif CEPGP.Alt.SyncEP then
		GuildRosterSetOfficerNote(mainIndex, altEP .. "," .. mainGP);
	elseif CEPGP.Alt.SyncGP then
		GuildRosterSetOfficerNote(mainIndex, mainEP .. "," .. altGP);
	end
	
	C_Timer.After(1, function()
		CEPGP_syncAltStandings(main);
	end);
end

function CEPGP_addAltEPGP(EP, GP, alt, main)
	local success, failMsg = pcall(function()
		if not main or CEPGP.Alt.BlockAwards then return; end
		local index = CEPGP_getIndex(alt);
		local mainEP, mainGP = CEPGP_getEPGP(main, CEPGP_Info.Guild.Roster[main][1]);
		local altEP, altGP = CEPGP_getEPGP(alt, index);
		
		mainEP = math.max(mainEP + EP, 0);
		mainGP = math.max(mainGP + GP, CEPGP.GP.Min + math.max(GP, 0));
		
		altEP = math.max(altEP + EP, 0);
		altGP = math.max(altGP + GP, CEPGP.GP.Min + math.max(GP, 0));
		
		if CEPGP.Alt.SyncEP and CEPGP.Alt.SyncGP then
			GuildRosterSetOfficerNote(index, mainEP .. "," .. mainGP);	--	Both EPGP are being synced
		elseif CEPGP.Alt.SyncEP then
			GuildRosterSetOfficerNote(index, mainEP .. "," .. altGP);	--	Only EP is being synced
		elseif CEPGP.Alt.SyncGP then
			GuildRosterSetOfficerNote(index, altEP .. "," .. mainGP);	--	Only GP is being synced
		else
			GuildRosterSetOfficerNote(index, altEP .. "," .. altGP);	--	Alt standings are not synced with main
		end
		
		C_Timer.After(1, function()
			CEPGP_syncToMain(alt, index, main);
		end);
	end);
	
	if not success then
		CEPGP_print("Could not process changes to EPGP for " .. alt, true);
		CEPGP_print(failMsg, true);
	end
end]]