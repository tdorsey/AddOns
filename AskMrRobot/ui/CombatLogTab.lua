local _, AskMrRobot = ...
local L = AskMrRobot.L;

-- initialize the ExportTab class
AskMrRobot.CombatLogTab = AskMrRobot.inheritsFrom(AskMrRobot.Frame)

-- these are valid keys in AmrLogData, all others will be deleted
local _logDataKeys = {
	["_logging"] = true,
	["_autoLog"] = true,
	["_lastZone"] = true,
	["_lastDiff"] = true,
	["_current2"] = true,
	["_history2"] = true,
	["_wipes"] = true,
	["_lastWipe"] = true,
	["_currentExtra"] = true,
	["_historyExtra"] = true
};

local _undoButton = false

-- helper to create text for this tab
local function CreateText(tab, font, relativeTo, xOffset, yOffset, text)
    local t = tab:CreateFontString(nil, "ARTWORK", font)
	t:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", xOffset, yOffset)
	t:SetPoint("RIGHT", tab, "RIGHT", -5, 0)
	t:SetWidth(t:GetWidth())
	t:SetJustifyH("LEFT")
	t:SetText(text)
    
    return t
end

local function newCheckbox(tab, label, tooltipTitle, description, onClick)
	local check = CreateFrame("CheckButton", "AmrCheck" .. label, tab, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		onClick(self, self:GetChecked() and true or false)
	end)
	check.label = _G[check:GetName() .. "Text"]
	check.label:SetText(label)
	check.tooltipText = tooltipTitle
	check.tooltipRequirement = description
	return check
end

function AskMrRobot.CombatLogTab:new(parent)

	local tab = AskMrRobot.Frame:new(nil, parent)
	setmetatable(tab, { __index = AskMrRobot.CombatLogTab })
	tab:SetPoint("TOPLEFT")
	tab:SetPoint("BOTTOMRIGHT")
	tab:Hide()

	-- tab header
	local text = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetPoint("TOPLEFT", 0, -5)
	text:SetText("Combat Logging")

	--scrollframe 
	tab.scrollframe = AskMrRobot.ScrollFrame:new(nil, tab)
	tab.scrollframe:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -30)
	tab.scrollframe:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -30, 10)

	local content = tab.scrollframe.content
	content:SetHeight(730)
    
    local btn = CreateFrame("Button", "AmrCombatLogStart", content, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	btn:SetText("Start Logging")
	btn:SetWidth(120)
	btn:SetHeight(30)
    tab.btnStart = btn
    
    btn:SetScript("OnClick", function()
        tab:ToggleLogging()
    end)
    

	text = content:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	text:SetPoint("LEFT", btn, "RIGHT", 10, 0)
	tab.loggingStatus = text;

	local autoChk = newCheckbox(content,
		L.AMR_COMBATLOGTAB_CHECKBOX_AUTOLOG_SOO_LABEL,
		L.AMR_COMBATLOGTAB_CHECKBOX_AUTOLOG_SOO_TOOLTIP_TITLE,
		L.AMR_COMBATLOGTAB_CHECKBOX_AUTOLOG_SOO_DESCRIPTION,
		function(self, value) 
			if value then
				AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] = "enabled"
			else
				AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] = "disabled" 
			end

			AmrLogData._lastZone = nil
			AmrLogData._lastDiff = nil
			tab:UpdateAutoLogging()
		end
	)
	autoChk:SetChecked(AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] == "enabled")
	autoChk:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    autoChk:SetHeight(30)


	local text = CreateText(content, "GameFontNormalLarge", autoChk, 0, -20, L.AMR_COMBATLOGTAB_INFIGHT)

    btn = CreateFrame("Button", "AmrCombatLogWipe", autoChk, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -10)
	btn:SetText("Wipe")
	btn:SetWidth(70)
	btn:SetHeight(30)
    btn:SetScript("OnClick", function()
        tab:LogWipe()
    end)

    tab.btnWipe = btn

    local text2 = CreateText(content, "GameFontWhite", text, 80, -12, L.AMR_COMBATLOGTAB_WIPE_1)
    text2 = CreateText(content, "GameFontWhite", text2, 0, -2, L.AMR_COMBATLOGTAB_WIPE_2)
    text2 = CreateText(content, "GameFontWhite", text2, 0, -2, L.AMR_COMBATLOGTAB_WIPE_3)

    btn = CreateFrame("Button", "AmrCombatLogUnWipe", content, "UIPanelButtonTemplate")
	btn:SetPoint("LEFT", text, "LEFT", 0, 0)
	btn:SetPoint("TOP", text2, "BOTTOM", 0, -10)
	btn:SetText("Undo")
	btn:SetWidth(70)
	btn:SetHeight(30)
	btn:Hide() -- initially hidden
    btn:SetScript("OnClick", function()
        tab:LogUnwipe()
    end)
    tab.btnUnwipe = btn

    text = content:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    text:SetPoint("LEFT", btn, "LEFT", 80, 0)
    tab.lastWipeLabel = text

	text = CreateText(tab, "GameFontNormalLarge", btn, 0, -20, L.AMR_COMBATLOGTAB_HEADLINE_OVER_BUTTON)

	btn = CreateFrame("Button", "AmrCombatLogSaveCharData", content, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -5)
	btn:SetText(L.AMR_COMBATLOGTAB_SAVE_CHARACTER)
	btn:SetWidth(150)
	btn:SetHeight(30)

	-- reload the UI will save character data to disk
	btn:SetScript("OnClick", ReloadUI)

	text = CreateText(content, "GameFontWhite", btn, 0, -15, L.AMR_COMBATLOGTAB_SAVE_CHARACTER_INFO)

    text = CreateText(content, "GameFontNormalLarge", text, 0, -30, L.AMR_COMBATLOGTAB_INSTRUCTIONS)
    text = CreateText(content, "GameFontWhite", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_1)
    text = CreateText(content, "GameFontWhite", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_2)
    text = CreateText(content, "GameFontWhite", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_3)
	text = CreateText(content, "GameFontWhite", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_4)

	text = CreateText(content, "GameFontNormalSmall", text, 0, -30, L.AMR_COMBATLOGTAB_INSTRUCTIONS_5)
	text = CreateText(content, "GameFontNormalSmall", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_6)
	text = CreateText(content, "GameFontNormalSmall", text, 0, -10, L.AMR_COMBATLOGTAB_INSTRUCTIONS_7)
    
	--[[
	btn = CreateFrame("Button", "AmrCombatLogTest", tab, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -15)
	btn:SetText("Test")
	btn:SetWidth(120)
	btn:SetHeight(30)
    
    btn:SetScript("OnClick", function()

		local t = time()
		AskMrRobot.SaveAll()
		AskMrRobot.ExportToAddonChat(t)
		AskMrRobot.ExportLoggingData(t)
    end)
	]]

	-- when we start up, ensure that logging is still enabled if it was enabled when they last used the addon
    if (tab:IsLogging()) then
        SetCVar("advancedCombatLogging", 1)
        LoggingCombat(true)
    end
    
	-- if auto-logging is enabled, do a check when the addon is loaded to make sure that state is set correctly
	if AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] == "enabled" then
		tab:UpdateAutoLogging()
	end

    tab:SetScript("OnShow", function()
        tab:Update()
	end)

    return tab
end

function AskMrRobot.CombatLogTab:IsLogging()
    return AmrLogData._logging == true
end

function AskMrRobot.CombatLogTab:StartLogging()

	local now = time()
	local oldDuration = 60 * 60 * 24 * 10

	-- archive the current logging session so that users don't accidentally blow away data before uploading it
	if AmrLogData._current2 ~= nil then
		if not AmrLogData._history2 then AmrLogData._history2 = {} end

		-- add new entries
		for name, timeList in AskMrRobot.spairs(AmrLogData._current2) do
			if not AmrLogData._history2[name] then AmrLogData._history2[name] = {} end
			for timestamp, dataString in AskMrRobot.spairs(timeList) do
				AmrLogData._history2[name][timestamp] = dataString
			end
		end

		-- delete entries that are more than 10 days old
		for name, timeList in AskMrRobot.spairs(AmrLogData._history2) do
			for timestamp, dataString in AskMrRobot.spairs(timeList) do
				if difftime(now, tonumber(timestamp)) > oldDuration then
					timeList[timestamp] = nil
				end
			end
			
			local count = 0
			for timestamp, dataString in pairs(timeList) do
				count = count + 1
			end
			if count == 0 then
				AmrLogData._history2[name] = nil
			end
		end
	end

	-- same idea with extra info (auras, pets, whatever we end up adding to it)
	if AmrLogData._currentExtra ~= nil then
		if not AmrLogData._historyExtra then AmrLogData._historyExtra = {} end

		-- add new entries
		for name, timeList in AskMrRobot.spairs(AmrLogData._currentExtra) do
			if not AmrLogData._historyExtra[name] then AmrLogData._historyExtra[name] = {} end
			for timestamp, dataString in AskMrRobot.spairs(timeList) do
				AmrLogData._historyExtra[name][timestamp] = dataString
			end
		end

		-- delete entries that are more than 10 days old
		for name, timeList in AskMrRobot.spairs(AmrLogData._historyExtra) do
			for timestamp, dataString in AskMrRobot.spairs(timeList) do
				if difftime(now, tonumber(timestamp)) > oldDuration then
					timeList[timestamp] = nil
				end
			end
			
			local count = 0
			for timestamp, dataString in pairs(timeList) do
				count = count + 1
			end
			if count == 0 then
				AmrLogData._historyExtra[name] = nil
			end
		end
	end


	-- delete _wipes entries that are more than 10 days old
	if AmrLogData._wipes then
		local i = 1
		while i <= #AmrLogData._wipes do
			local t = AmrLogData._wipes[i]
			if difftime(now, t) > oldDuration then
		        tremove(AmrLogData._wipes, i)
		    else
		        i = i + 1
		    end
		end
	end

	-- delete the _lastWipe if it is more than 10 days old
	if AmrLogData._lastWipe and difftime(now, AmrLogData._lastWipe) > oldDuration then
		AmrLogData_lastWipe = nil
	end

	-- clean up old-style logging data from previous versions of the addon
	for k, v in AskMrRobot.spairs(AmrLogData) do
		if not _logDataKeys[k] then
			AmrLogData[k] = nil
		end
	end

    -- start a new logging session
    AmrLogData._current2 = {}
	AmrLogData._currentExtra = {}
    AmrLogData._logging = true
    
    -- always enable advanced combat logging via our addon, gathers more detailed data for better analysis
    SetCVar("advancedCombatLogging", 1)
    
    LoggingCombat(true)
    self:Update()

    AskMrRobot.AmrUpdateMinimap()
    
    print(L.AMR_COMBATLOGTAB_IS_LOGGING)
end

function AskMrRobot.CombatLogTab:StopLogging()
    LoggingCombat(false)
    AmrLogData._logging = false
    self:Update()
    
    AskMrRobot.AmrUpdateMinimap()
    
    print(L.AMR_COMBATLOGTAB_STOPPED_LOGGING)
end

function AskMrRobot.CombatLogTab:ToggleLogging()
	if self:IsLogging() then
		self:StopLogging()
	else
		self:StartLogging()
	end
end

-- update the panel and state
function AskMrRobot.CombatLogTab:Update()
    local isLogging = self:IsLogging()
    
    if isLogging then
    	self.btnStart:SetText(L.AMR_COMBATLOGTAB_STOP_LOGGING)
    	self.loggingStatus:SetText(L.AMR_COMBATLOGTAB_CURRENTLY_LOGGING)
    else
    	self.btnStart:SetText(L.AMR_COMBATLOGTAB_START_LOGGING)
    	self.loggingStatus:SetText("")
    end

	if AmrLogData._lastWipe then
		self.lastWipeLabel:SetText(L.AMR_COMBATLOGTAB_LASTWIPE:format(date('%B %d', AmrLogData._lastWipe), date('%I:%M %p', AmrLogData._lastWipe)))
		self.btnUnwipe:Show()
	else
		self.lastWipeLabel:SetText("")
		self.btnUnwipe:Hide()
	end

end

-- called to update logging state when auto-logging is enabled
function AskMrRobot.CombatLogTab:UpdateAutoLogging()

	-- get the info about the instance
	--local zone, zonetype, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID = GetInstanceInfo()
	local zone, _, difficultyIndex, _, _, _, _, instanceMapID = GetInstanceInfo()
	--local difficulty = difficultyIndex
	-- Unless Blizzard fixes scenarios to not return nil, let's hardcode this into returning "scenario" -Znuff
	--if zonetype == nil and difficultyIndex == 1 then
		--zonetype = "scenario"
	--end

	if zone == AmrLogData._lastZone and difficultyIndex == AmrLogData._lastDiff then
	  -- do nothing if the zone hasn't actually changed, otherwise we may override the user's manual enable/disable
		return
	end

	AmrLogData._lastZone = zone
	AmrLogData._lastDiff = difficultyIndex

	if AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] == "enabled" then
		if tonumber(instanceMapID) == AskMrRobot.instanceIds.SiegeOfOrgrimmar then
			-- if in SoO, make sure logging is on
			if not self:IsLogging() then
				self:StartLogging()
			end
		else
			-- not in SoO, turn logging off
			if self:IsLogging() then
				self:StopLogging()
			end
		end
	end

end

local function RaidChatType()
	if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") then
		return "RAID_WARNING"
	else
		return "RAID"
	end
end

-- used to store wipes to AmrLogData so that we trim data after the wipe
function AskMrRobot.CombatLogTab:LogWipe()	
	local t = time()
	tinsert(AmrLogData._wipes, t)
	AmrLogData._lastWipe = t

	if GetNumGroupMembers() > 0 then
		SendChatMessage(L.AMR_COMBATLOGTAB_WIPE_CHAT, RaidChatType())
	end
	print(string.format(L.AMR_COMBATLOGTAB_WIPE_MSG, date('%I:%M %p', t)))

	self:Update()
	--AskMrRobot.wait(301, AskMrRobot.CombatLogTab.Update, self)
end

-- used to undo the wipe command
function AskMrRobot.CombatLogTab:LogUnwipe()
	local t = AmrLogData._lastWipe
	if not t then
		print(L.AMR_COMBATLOGTAB_NOWIPES)
	else
		tremove(AmrLogData._wipes)
		AmrLogData._lastWipe = nil
		print(string.format(L.AMR_COMBATLOGTAB_UNWIPE_MSG, date('%I:%M %p', t)))
	end
	self:Update()
end

-- initialize the AmrLogData variable
function AskMrRobot.CombatLogTab.InitializeVariable()
    if not AmrLogData then AmrLogData = {} end
	if not AmrLogData._autoLog then AmrLogData._autoLog = {} end
	if not AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] then 
		AmrLogData._autoLog[AskMrRobot.instanceIds.SiegeOfOrgrimmar] = "disabled" 
	end
	AmrLogData._wipes = AmrLogData._wipes or {}
end

function AskMrRobot.CombatLogTab.SaveExtras(data, timestamp)

	for name,val in pairs(data) do
		-- record aura stuff, we never check for duplicates, need to know it at each point in time
		if AmrLogData._currentExtra[name] == nil then
			AmrLogData._currentExtra[name] = {}
		end
		AmrLogData._currentExtra[name][timestamp] = val
	end
end

-- read a message sent to the addon channel with a player's info at the time an encounter started
function AskMrRobot.CombatLogTab:ReadAddonMessage(message)

    -- message will be of format: timestamp\nrealm\nname\n[stuff]
    local parts = {}
	for part in string.gmatch(message, "([^\n]+)") do
		tinsert(parts, part)
	end
    
    local timestamp = parts[1]
    local name = parts[2] .. ":" .. parts[3]
    local data = parts[4]
    
    if (data == "done") then
        -- we have finished receiving this message; now process it to reduce the amount of duplicate data
        local setup = AmrLogData._current2[name][timestamp]

        if (AmrLogData._previousSetup == nil) then
            AmrLogData._previousSetup = {}
        end
        
        local previousSetup = AmrLogData._previousSetup[name]
        
        if (previousSetup == setup) then
            -- if the last-seen setup for this player is the same as the current one, we don't need this entry
            AmrLogData._current2[name][timestamp] = nil
        else
            -- record the last-seen setup
            AmrLogData._previousSetup[name] = setup
        end

    else
        -- concatenate messages with the same timestamp+name
        if (AmrLogData._current2[name] == nil) then
            AmrLogData._current2[name] = {}
        end
        
        if (AmrLogData._current2[name][timestamp] == nil) then
            AmrLogData._current2[name][timestamp] = data
        else
            AmrLogData._current2[name][timestamp] = AmrLogData._current2[name][timestamp] .. data
        end
    end
end
