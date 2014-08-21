local _, AskMrRobot = ...
local L = AskMrRobot.L;

AskMrRobot.eventListener = CreateFrame("FRAME"); -- Need a frame to respond to events
AskMrRobot.eventListener:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded
AskMrRobot.eventListener:RegisterEvent("ITEM_PUSH");
AskMrRobot.eventListener:RegisterEvent("DELETE_ITEM_CONFIRM");
AskMrRobot.eventListener:RegisterEvent("UNIT_INVENTORY_CHANGED");
AskMrRobot.eventListener:RegisterEvent("BANKFRAME_OPENED");
AskMrRobot.eventListener:RegisterEvent("BANKFRAME_CLOSED");
AskMrRobot.eventListener:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
AskMrRobot.eventListener:RegisterEvent("CHARACTER_POINTS_CHANGED");
AskMrRobot.eventListener:RegisterEvent("CONFIRM_TALENT_WIPE");
AskMrRobot.eventListener:RegisterEvent("PLAYER_TALENT_UPDATE");
AskMrRobot.eventListener:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
AskMrRobot.eventListener:RegisterEvent("PLAYER_ENTERING_WORLD");
AskMrRobot.eventListener:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
AskMrRobot.eventListener:RegisterEvent("PLAYER_LEVEL_UP");
--AskMrRobot.eventListener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
AskMrRobot.eventListener:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
AskMrRobot.eventListener:RegisterEvent("SOCKET_INFO_UPDATE")
AskMrRobot.eventListener:RegisterEvent("SOCKET_INFO_CLOSE")
AskMrRobot.eventListener:RegisterEvent("BAG_UPDATE")
AskMrRobot.eventListener:RegisterEvent("ITEM_UNLOCKED")
AskMrRobot.eventListener:RegisterEvent("PLAYER_REGEN_DISABLED")
--AskMrRobot.eventListener:RegisterEvent("ENCOUNTER_START")
AskMrRobot.eventListener:RegisterEvent("CHAT_MSG_ADDON")
AskMrRobot.eventListener:RegisterEvent("UPDATE_INSTANCE_INFO")
AskMrRobot.eventListener:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")

AskMrRobot.AddonName = ...
AskMrRobot.ChatPrefix = "_AMR"

local amrLDB
local icon
local reforgequeue
local reforgeFrame = nil
local LoggingCombat = _G.LoggingCombat

AskMrRobot.itemDiffs = {
	items = {},    -- slotNum -> nil (no change) or current <item id>, optimized <item id>
	enchants = {}, -- slotNum -> nil (no change) or current <enchant id>, optimized <enchant id>
	gems = {},     -- slotNum -> nil (no change) or ?
	reforges = {}   -- slotNum -> nil (no change) or current <reforge id>, optimized <reforge id>
}

AskMrRobot.instanceIds = {
	HeartOfFear = 1009,
	MogushanVaults = 1008,	
	SiegeOfOrgrimmar = 1136,
	TerraceOfEndlessSpring = 996,
	ThroneOfThunder = 1098
}

-- instances that we currently support logging for
AskMrRobot.supportedInstanceIds = {
	[1136] = true
}

-- returns true if currently in a supported instance
function AskMrRobot.IsSupportedInstance()

	local zone, _, difficultyIndex, _, _, _, _, instanceMapID = GetInstanceInfo()
	if AskMrRobot.supportedInstanceIds[tonumber(instanceMapID)] then
		return true
	else
		return false
	end
end

-- upgrade id -> upgrade level
local upgradeTable = {
  [0]   =  0,
  [1]   =  1, -- 1/1 -> 8
  [373] =  1, -- 1/2 -> 4
  [374] =  2, -- 2/2 -> 8
  [375] =  1, -- 1/3 -> 4
  [376] =  2, -- 2/3 -> 4
  [377] =  3, -- 3/3 -> 4
  [378] =  1, -- 1/1 -> 7
  [379] =  1, -- 1/2 -> 4
  [380] =  2, -- 2/2 -> 4
  [445] =  0, -- 0/2 -> 0
  [446] =  1, -- 1/2 -> 4
  [447] =  2, -- 2/2 -> 8
  [451] =  0, -- 0/1 -> 0
  [452] =  1, -- 1/1 -> 8
  [453] =  0, -- 0/2 -> 0
  [454] =  1, -- 1/2 -> 4
  [455] =  2, -- 2/2 -> 8
  [456] =  0, -- 0/1 -> 0
  [457] =  1, -- 1/1 -> 8
  [458] =  0, -- 0/4 -> 0
  [459] =  1, -- 1/4 -> 4
  [460] =  2, -- 2/4 -> 8
  [461] =  3, -- 3/4 -> 12
  [462] =  4, -- 4/4 -> 16
  [465] =  0, -- 0/2 -> 0
  [466] =  1, -- 1/2 -> 4
  [467] =  2, -- 2/2 -> 8
  [468] =  0, -- 0/4 -> 0
  [469] =  1, -- 1/4 -> 4
  [470] =  2, -- 2/4 -> 8
  [471] =  3, -- 3/4 -> 12
  [472] =  4, -- 4/4 -> 16
  [476] =  0, -- ? -> 0
  [479] =  0, -- ? -> 0
  [491] =  0, -- ? -> 0
  [492] =  1, -- ? -> 0
  [493] =  2, -- ? -> 0
  [494] = 0,
  [495] = 1,
  [496] = 2,
  [497] = 3,
  [498] = 4,
  [504] = 3,
  [505] = 4,
  [506] = 5,
  [507] = 6
}

local professionIds = {
    ["None"] = 0,
    ["Mining"] = 1,
    ["Skinning"] = 2,
    ["Herbalism"] = 3,
    ["Enchanting"] = 4,
    ["Jewelcrafting"] = 5,
    ["Engineering"] = 6,
    ["Blacksmithing"] = 7,
    ["Leatherworking"] = 8,
    ["Inscription"] = 9,
    ["Tailoring"] = 10,
    ["Alchemy"] = 11,
    ["Fishing"] = 12,
    ["Cooking"] = 13,
    ["First Aid"] = 14,
    ["Archaeology"] = 15
}

local raceIds = {
    ["None"] = 0,
    ["BloodElf"] = 1,
    ["Draenei"] = 2,
    ["Dwarf"] = 3,
    ["Gnome"] = 4,
    ["Human"] = 5,
    ["NightElf"] = 6,
    ["Orc"] = 7,
    ["Tauren"] = 8,
    ["Troll"] = 9,
    ["Scourge"] = 10,
    ["Undead"] = 10,
    ["Goblin"] = 11,
    ["Worgen"] = 12,
    ["Pandaren"] = 13
}

local factionIds = {
    ["None"] = 0,
    ["Alliance"] = 1,
    ["Horde"] = 2
}

local function OnExport()
    if (AmrOptions.exportToClient) then
        AskMrRobot.SaveAll()
        ReloadUI()
    else
        AskMrRobot_ReforgeFrame:Show()
        AskMrRobot_ReforgeFrame:ShowTab("export")
    end
end

function AskMrRobot.eventListener:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
        local addon = select(1, ...)
        if (addon == "AskMrRobot") then
            print(L.AMR_ON_EVENT_LOADED.format(GetAddOnMetadata(AskMrRobot.AddonName, "Version")))
            
            -- listen for messages from other AMR addons
            RegisterAddonMessagePrefix(AskMrRobot.ChatPrefix)
            
            AmrRealmName = GetRealmName()
            AmrCharacterName = UnitName("player")

            AskMrRobot.CombatLogTab.InitializeVariable()

            if not AmrIconInfo then AmrIconInfo = {} end
            if not AmrBankItems then AmrBankItems = {} end
            if not AmrCurrencies then AmrCurrencies = {} end
            if not AmrSpecializations then AmrSpecializations = {} end
            if not AmrOptions then AmrOptions = {} end
            if not AmrGlyphs then AmrGlyphs = {} end
            if not AmrTalents then AmrTalents = {} end
            if not AmrBankItemsAndCounts then AmrBankItemsAndCounts = {} end
            if not AmrImportString then AmrImportString = "" end
            if not AmrImportDate then AmrImportDate = "" end
            
			if not AmrSettings then AmrSettings = {} end
			if not AmrSettings.Logins then AmrSettings.Logins = {} end

            if not AmrSendSettings then
                AmrSendSettings = {
                    SendGems = true,
                    SendEnchants = true,
                    SendEnchantMaterials = true,
                    SendToType = "a friend",
                    SendTo = ""
                }
            end

            amrLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AskMrRobot", {
                type = "launcher",
                text = "Ask Mr. Robot",
                icon = "Interface\\AddOns\\AskMrRobot\\Media\\icon",
                OnClick = function()
                	if IsControlKeyDown() then
                		AskMrRobot_ReforgeFrame.combatLogTab:LogWipe()
                    elseif IsModifiedClick("CHATLINK") then
                        OnExport()
                    else
                        AskMrRobot_ReforgeFrame:Toggle()
                    end
                end,
                OnTooltipShow = function(tt)
                    tt:AddLine("Ask Mr. Robot", 1, 1, 1);
                    tt:AddLine(" ");
                    tt:AddLine(L.AMR_ON_EVENT_TOOLTIP)
                end	
            });


            AskMrRobot.AmrUpdateMinimap()

            AskMrRobot_ReforgeFrame = AskMrRobot.AmrUI:new()

            -- remember the import settings between sessions
            AskMrRobot_ReforgeFrame.summaryTab.importDate = AmrImportDate or ""
            AskMrRobot_ReforgeFrame.buttons[2]:Click()
            
            -- the previous import string is loaded when the UI is first shown, otherwise the game spams events and it lags
        end
        
	elseif event == "ITEM_PUSH" or event == "DELETE_ITEM_CONFIRM" or event == "UNIT_INVENTORY_CHANGED" or event == "SOCKET_INFO_CLOSE" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "BAG_UPDATE" then
		if AskMrRobot_ReforgeFrame then
			AskMrRobot_ReforgeFrame:OnUpdate()
		end
		--AskMrRobot.SaveBags();
		--AskMrRobot.SaveEquiped();
		--AskMrRonot.GetCurrencies();
		--AskMrRobot.GetGold();
	elseif event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then 
		--print("Scanning Bank: " .. event);
		AskMrRobot.ScanBank();
	elseif event == "BANKFRAME_CLOSED" then
		--print("Stop Scanning Bank");
		--inBank = false;
	elseif event == "CHARACTER_POINTS_CHANGED" or event == "CONFIRM_TALENT_WIPE" or event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		--AskMrRobot.GetAmrSpecializations();
		if AskMrRobot_ReforgeFrame then
			AskMrRobot_ReforgeFrame:OnUpdate()
		end
	elseif event == "PLAYER_LEVEL_UP" then
		--GetLevel();
	elseif event == "ITEM_UNLOCKED" then
		AskMrRobot.On_ITEM_UNLOCKED()
	elseif event == "PLAYER_LOGOUT" then
		-- doing nothing right now, but leaving this in case we need something here	
	elseif event == "PLAYER_ENTERING_WORLD" then

		-- delete entries that are more than 10 days old to prevent the table from growing indefinitely
		if AmrSettings.Logins and #AmrSettings.Logins > 0 then
			local now = time()
			local oldDuration = 60 * 60 * 24 * 10
			local entryTime
			repeat
				-- parse entry and get time
				local parts = {}
				for part in string.gmatch(AmrSettings.Logins[1], "([^;]+)") do
					tinsert(parts, part)
				end
				entryTime = tonumber(parts[3])

				-- entries are in order, remove first entry if it is old
				if difftime(now, entryTime) > oldDuration then
					tremove(AmrSettings.Logins, 1)
				end
			until #AmrSettings.Logins == 0 or difftime(now, entryTime) <= oldDuration
		end

		-- record the time a player logs in, used to figure out which player logged which parts of their log file
		local key = AmrRealmName .. ";" .. AmrCharacterName .. ";"
		local loginData = key .. time()
		if AmrSettings.Logins and #AmrSettings.Logins > 0 then
			local last = AmrSettings.Logins[#AmrSettings.Logins]
			if string.len(last) >= string.len(key) and string.sub(last, 1, string.len(key)) ~= key then
				table.insert(AmrSettings.Logins, loginData)
			end
		else
			table.insert(AmrSettings.Logins, loginData)
		end

    elseif event == "PLAYER_REGEN_DISABLED" then

        -- send data about this character when a player enters combat in a supported zone
		if AskMrRobot.IsSupportedInstance() then
			local t = time()
			AskMrRobot.SaveAll()
			AskMrRobot.ExportToAddonChat(t)
			AskMrRobot.ExportLoggingData(t)
		end

    elseif event == "CHAT_MSG_ADDON" then
        local chatPrefix, message = select(1, ...)
        local isLogging = AskMrRobot_ReforgeFrame.combatLogTab:IsLogging()
        if (isLogging and chatPrefix == AskMrRobot.ChatPrefix) then
            AskMrRobot_ReforgeFrame.combatLogTab:ReadAddonMessage(message)
        end
    elseif event == "UPDATE_INSTANCE_INFO" or event == "PLAYER_DIFFICULTY_CHANGED" then
    	AskMrRobot_ReforgeFrame.combatLogTab:UpdateAutoLogging()
	end
 
end

AskMrRobot.eventListener:SetScript("OnEvent", AskMrRobot.eventListener.OnEvent);

local function parseItemLink(input)
	local itemId, enchantId, gemEnchantId1, gemEnchantId2, gemEnchantId3, gemEnchantId4, suffixId, _, _, reforgeId, upgradeId = string.match(input, "^|.-|Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(-?%d+):(-?%d+):(-?%d+):(%d+):(%d+)|");
	local item = {}
	item.itemId = tonumber(itemId)
	item.suffixId = tonumber(suffixId)
	item.enchantId = tonumber(enchantId)
	item.reforgeId = tonumber(reforgeId)
	item.upgradeId = tonumber(upgradeId)
	item.gemEnchantIds = { tonumber(gemEnchantId1), tonumber(gemEnchantId2), tonumber(gemEnchantId3), tonumber(gemEnchantId4) }
	return item
end

SLASH_AMR1 = "/amr";
function SlashCmdList.AMR(msg)

	if msg == 'toggle' then
		AskMrRobot_ReforgeFrame:Toggle()
	elseif msg == 'show' then
		AskMrRobot_ReforgeFrame:Show()
	elseif msg == 'hide' then
		AskMrRobot_ReforgeFrame:Hide()
	elseif msg == 'export' then
		OnExport()
	elseif msg == 'wipe' then
		AskMrRobot_ReforgeFrame.combatLogTab:LogWipe()
	elseif msg == 'unwipe' then
		AskMrRobot_ReforgeFrame.combatLogTab:LogUnwipe()
	else
		print(L.AMR_SLASH_COMMAND_TEXT_1 .. L.AMR_SLASH_COMMAND_TEXT_2 .. L.AMR_SLASH_COMMAND_TEXT_3 .. L.AMR_SLASH_COMMAND_TEXT_4 .. L.AMR_SLASH_COMMAND_TEXT_5 .. L.AMR_SLASH_COMMAND_TEXT_6 .. L.AMR_SLASH_COMMAND_TEXT_7)
	end
end

function AskMrRobot.SaveAll()
	AskMrRobot.ScanBank()
	AskMrRobot.SaveBags()
	AskMrRobot.SaveEquiped()
	AskMrRobot.GetCurrencies()
	AskMrRobot.GetGold()
	AskMrRobot.GetAmrSpecializations()
	AskMrRobot.GetAmrProfessions()
	AskMrRobot.GetRace()
	AskMrRobot.GetLevel()
	AskMrRobot.GetAmrGlyphs()
	AskMrRobot.GetAmrTalents()
	--ReloadUI()
end

local function InitIcon()
	icon = LibStub("LibDBIcon-1.0");
	icon:Register("AskMrRobot", amrLDB, AmrIconInfo);
end

function AskMrRobot.AmrUpdateMinimap()	
	if AmrOptions.hideMapIcon then
		if icon then
			icon:Hide("AskMrRobot");
		end
	else
		if not icon then 
			InitIcon() 
		end
		--if AskMrRobot_ReforgeFrame.combatLogTab:IsLogging() then
		if AskMrRobot.CombatLogTab.IsLogging(nil) then
			amrLDB.icon = 'Interface\\AddOns\\AskMrRobot\\Media\\icon_green'
		else
			amrLDB.icon = 'Interface\\AddOns\\AskMrRobot\\Media\\icon'
		end
		icon:Show("AskMrRobot");
	end
end

local function getToolTipText(tip)
	return EnumerateTooltipLines_helper(tip:GetRegions())
end

local bagItems = {}
local bagItemsWithCount = {}

function AskMrRobot.ScanBag(bagId) 	
	local numSlots = GetContainerNumSlots(bagId);
	for slotId = 1, numSlots do
		local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagId, slotId);
		if itemLink ~= nil then
            local itemData = parseItemLink(itemLink)
            if itemData.itemId ~= nil then
                tinsert(bagItems, itemLink);
                tinsert(bagItemsWithCount, {link = itemLink, count = itemCount})
            end
		end
	end
end

local BACKPACK_CONTAINER = 0;
local BANK_CONTAINER = -1;

function AskMrRobot.ScanEquiped()
	local equipedItems = {};
	for slotNum = 1, #AskMrRobot.slotIds do
		local slotId = AskMrRobot.slotIds[slotNum];
		local itemLink = GetInventoryItemLink("player", slotId);
		if (itemLink ~= nil) then
			equipedItems[slotId .. ""] = itemLink;
		end
	end
	return equipedItems
end

function AskMrRobot.SaveEquiped()
	AmrEquipedItems = AskMrRobot.ScanEquiped();
end

function AskMrRobot.ScanBags()
	bagItems = {}
	bagItemsWithCount = {}

	AskMrRobot.ScanBag(BACKPACK_CONTAINER); -- backpack
	
	for bagId = 1, NUM_BAG_SLOTS do
		AskMrRobot.ScanBag(bagId);
	end
	

	return bagItems, bagItemsWithCount
end

function AskMrRobot.SaveBags()
	AmrBagItems, _ = AskMrRobot.ScanBags()
end

function AskMrRobot.GetGold()
	AmrGold = GetMoney();
end

local lastBankBagId = nil;
local lastBankSlotId = nil;
local bankItems = {};
local bankItemsAndCount = {};
AmrBankItemsAndCounts = {};

local function ScanBankBag(bagId)
	local numSlots = GetContainerNumSlots(bagId);
	for slotId = 1, numSlots do
		local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagId, slotId);
		if itemLink ~= nil then
            local itemData = parseItemLink(itemLink)
            if itemData.itemId ~= nil then
                lastBankBagId = bagId;
                lastBankSlotId = slotId;
                tinsert(bankItems, itemLink);						
                tinsert(bankItemsAndCount, {link = itemLink, count = itemCount})
            end
		end
	end
end
		
function AskMrRobot.ScanBank()
		
	bankItems = {};
	bankItemsAndCount = {}
	
	ScanBankBag(BANK_CONTAINER);
	for bagId = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		ScanBankBag(bagId);
	end
	
	-- see if the scan completed before the window closed
	if lastBankBagId ~= nil then
		local itemLink = GetContainerItemLink(lastBankBagId, lastBankSlotId);
		if itemLink ~= nil then --still open
			AmrBankItems = bankItems;
			AmrBankItemsAndCounts = bankItemsAndCount
		end
	end
end

local function GetCurrencyAmount(index)
	local localized_label, amount, icon_file_name = GetCurrencyInfo(index);
	return amount;
end

function AskMrRobot.GetCurrencies()
	local currencies = {};
	local currencyList = {61, 81, 241, 361, 384, 394, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 416, 515, 614, 615, 676, 679};

	for i, currency in pairs(currencyList) do
		local amount = GetCurrencyAmount(currency);
		if amount ~= 0 then
			currencies[currencyList[i]] = amount;
		end
	end
	AmrCurrencies = currencies;
end

local function GetAmrSpecialization(specGroup)
	local spec = GetSpecialization(false, false, specGroup);
	return spec and GetSpecializationInfo(spec);
end

function AskMrRobot.GetAmrSpecializations()

	AmrSpecializations = {};

	AmrActiveSpec = GetActiveSpecGroup();

	for group = 1, 2 do
		AmrSpecializations[group .. ""] = GetAmrSpecialization(group)
	end

-- Death Knight 
-- 250 - Blood
-- 251 - Frost
-- 252 - Unholy
-- Druid 
-- 102 - Balance
-- 103 - Feral Combat
-- 104 - Guardian
-- 105 - Restoration
-- Hunter 
-- 253 - Beast Mastery
-- 254 - Marksmanship
-- 255 - Survival
-- Mage 
-- 62 - Arcane
-- 63 - Fire
-- 64 - Frost
-- Monk 
-- 268 - Brewmaster
-- 269 - Windwalker
-- 270 - Mistweaver
-- Paladin 
-- 65 - Holy
-- 66 - Protection
-- 70 - Retribution
-- Priest 
-- 256 Discipline
-- 257 Holy
-- 258 Shadow
-- Rogue 
-- 259 - Assassination
-- 260 - Combat
-- 261 - Subtlety
-- Shaman 
-- 262 - Elemental
-- 263 - Enhancement
-- 264 - Restoration
-- Warlock 
-- 265 - Affliction
-- 266 - Demonology
-- 267 - Destruction
-- Warrior 
-- 71 - Arms
-- 72 - Fury
-- 73 - Protection
end

function AskMrRobot.GetAmrProfessions()

	local profMap = {
		[794] = "Archaeology",
		[171] = "Alchemy",
		[164] = "Blacksmithing",
		[185] = "Cooking",
		[333] = "Enchanting",
		[202] = "Engineering",
		[129] = "First Aid",
		[356] = "Fishing",
		[182] = "Herbalism",
		[773] = "Inscription",
		[755] = "Jewelcrafting",
		[165] = "Leatherworking",
		[186] = "Mining",
		[393] = "Skinning",
		[197] = "Tailoring"
	}

	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
	AmrProfessions = {};
	if prof1 then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(prof1);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
	if prof2 then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(prof2);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
	if archaeology then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(archaeology);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
	if fishing then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(fishing);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
	if cooking then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(cooking);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
	if firstAid then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(firstAid);
		if profMap[skillLine] ~= nil then
			AmrProfessions[profMap[skillLine]] = skillLevel;
		end
	end
end

function AskMrRobot.GetRace()
	local race, raceEn = UnitRace("player");
	AmrRace = raceEn;
	AmrFaction = UnitFactionGroup("player");
end

function AskMrRobot.GetLevel()
	AmrLevel = UnitLevel("player");
end

local SlotNames = {
   "HeadSlot",
   "NeckSlot",
   "ShoulderSlot",
   "ShirtSlot",
   "ChestSlot",
   "WaistSlot",
   "LegsSlot",
   "FeetSlot",
   "WristSlot",
   "HandsSlot",
   "Finger0Slot",
   "Finger1Slot",
   "Trinket0Slot",
   "Trinket1Slot",
   "BackSlot",
   "MainHandSlot",
   "SecondaryHandSlot",
--   "RangedSlot",
   "TabardSlot",
}

local function GetAmrTalentsForSpec(spec)	
    local talentInfo = {}
    local maxTiers = 6
    for talent = 1, GetNumTalents() do
     	local name, texture, tier, column, selected, available = GetTalentInfo(talent, false, spec)
     	if tier > maxTiers then
     		maxTiers = tier
     	end
     	if selected then
     		talentInfo[tier] = column
    	end
    end
    
    local str = ""
    for i = 1, maxTiers do
    	if talentInfo[i] then
    		str = str .. talentInfo[i]
    	else
    		str = str .. '0'
    	end
    end    	

	return str
end

function AskMrRobot.GetAmrTalents()
	AmrTalents = {}
    for spec = 1, GetNumSpecGroups() do
    	AmrTalents[spec] = GetAmrTalentsForSpec(spec);
    end
end

local function GetAmrGlyphsForSpec(spec)
	local glyphs = {}
	for i = 1,  NUM_GLYPH_SLOTS do
		local _, _, _, glyphSpellID, _, glyphID = GetGlyphSocketInfo(i, spec)
		if (glyphID) then
			tinsert(glyphs, glyphSpellID)
		end
	end
	return glyphs;
end

function AskMrRobot.GetAmrGlyphs()
	AmrGlyphs = {}
	for spec = 1, GetNumSpecGroups() do
		AmrGlyphs[spec] = GetAmrGlyphsForSpec(spec)
	end
end

--[[
local function ItemLinkToExportString(itemLink, slot)
    local itemData = parseItemLink(itemLink)
    local ret = {}
    table.insert(ret, slot)
    table.insert(ret, itemData.itemId)
    table.insert(ret, itemData.suffixId)
    table.insert(ret, itemData.upgradeId)
    table.insert(ret, itemData.gemEnchantIds[1])
    table.insert(ret, itemData.gemEnchantIds[2])
    table.insert(ret, itemData.gemEnchantIds[3])
    table.insert(ret, itemData.enchantId)
    table.insert(ret, itemData.reforgeId)
    return table.concat(ret, ":")
end
]]

local function toCompressedNumberList(list)
    -- ensure the values are numbers, sorted from lowest to highest
    local nums = {}
    for i, v in ipairs(list) do
        table.insert(nums, tonumber(v))
    end
    table.sort(nums)
    
    local ret = {}
    local prev = 0
    for i, v in ipairs(nums) do
        local diff = v - prev
        table.insert(ret, diff)
        prev = v
    end
    
    return table.concat(ret, ",")
end

-- create a more compact but less readable string
function AskMrRobot.ExportToCompressedString(includeInventory)
    local fields = {}
    
    -- compressed string uses a fixed order rather than inserting identifiers
    table.insert(fields, GetAddOnMetadata(AskMrRobot.AddonName, "Version"))
    table.insert(fields, AmrRealmName)
    table.insert(fields, AmrCharacterName)

	-- guild name
	local guildName = GetGuildInfo("player")
	if guildName == nil then
		table.insert(fields, "")
	else
		table.insert(fields, guildName)
    end

    -- race, default to pandaren if we can't read it for some reason
    local raceval = raceIds[AmrRace]
    if raceval == nil then raceval = 13 end
    table.insert(fields, raceval)
    
    -- faction, default to alliance if we can't read it for some reason
    raceval = factionIds[AmrFaction]
    if raceval == nil then raceval = 1 end
    table.insert(fields, raceval)
    
    table.insert(fields, AmrLevel)
    
    local profs = {}
    local noprofs = true
    if AmrProfessions then
	    for k, v in pairs(AmrProfessions) do
	        local profval = professionIds[k]
	        if profval ~= nil then
	            noprofs = false
	            table.insert(profs, profval .. ":" .. v)
	        end
	    end
	end
    
    if noprofs then
        table.insert(profs, "0:0")
    end
    
    table.insert(fields, table.concat(profs, ","))
    
    if (AmrActiveSpec ~= nil) then
        table.insert(fields, AmrActiveSpec)
        table.insert(fields, AmrSpecializations[AmrActiveSpec .. ""])
        table.insert(fields, AmrTalents[AmrActiveSpec])
        table.insert(fields, toCompressedNumberList(AmrGlyphs[AmrActiveSpec]))
    else
        table.insert(fields, "_")
        table.insert(fields, "_")
        table.insert(fields, "_")
        table.insert(fields, "_")
    end
    
    -- convert items to parsed objects, sorted by id
    local itemObjects = {}
    if AmrEquipedItems then
	    for k, v in pairs(AmrEquipedItems) do
	        local itemData = parseItemLink(v)
	        itemData.slot = k
	        table.insert(itemObjects, itemData)
	    end
	end
    
    -- if desired, include bank/bag items too
    if includeInventory then
    	if AmrBagItems then
	        for i, v in ipairs(AmrBagItems) do
	            local itemData = parseItemLink(v)
	            if itemData.itemId ~= nil then
	                table.insert(itemObjects, itemData)
	            end
	        end
	    end
	    if AmrBankItems then
	        for i, v in ipairs(AmrBankItems) do
	            local itemData = parseItemLink(v)
	            if itemData.itemId ~= nil then
	                table.insert(itemObjects, itemData)
	            end
	        end
	    end
    end
    
    -- sort by item id so we can compress it more easily
    table.sort(itemObjects, function(a, b) return a.itemId < b.itemId end)
    
    -- append to the export string
    local prevItemId = 0
    local prevGemId = 0
    local prevEnchantId = 0
    for i, itemData in ipairs(itemObjects) do
    
        local itemParts = {}
        
        table.insert(itemParts, itemData.itemId - prevItemId)
        prevItemId = itemData.itemId
        
        if itemData.slot ~= nil then table.insert(itemParts, "s" .. itemData.slot) end
        if itemData.suffixId ~= 0 then table.insert(itemParts, "f" .. itemData.suffixId) end
        if upgradeTable[itemData.upgradeId] ~= 0 then table.insert(itemParts, "u" .. upgradeTable[itemData.upgradeId]) end
        if itemData.gemEnchantIds[1] ~= 0 then 
            table.insert(itemParts, "a" .. (itemData.gemEnchantIds[1] - prevGemId))
            prevGemId = itemData.gemEnchantIds[1]
        end
        if itemData.gemEnchantIds[2] ~= 0 then 
            table.insert(itemParts, "b" .. (itemData.gemEnchantIds[2] - prevGemId))
            prevGemId = itemData.gemEnchantIds[2]
        end
        if itemData.gemEnchantIds[3] ~= 0 then 
            table.insert(itemParts, "c" .. (itemData.gemEnchantIds[3] - prevGemId))
            prevGemId = itemData.gemEnchantIds[3]
        end
        if itemData.enchantId ~= 0 then 
            table.insert(itemParts, "e" .. (itemData.enchantId - prevEnchantId))
            prevEnchantId = itemData.enchantId
        end
        if itemData.reforgeId ~= 0 then table.insert(itemParts, "r" .. (itemData.reforgeId - 113)) end
    
        table.insert(fields, table.concat(itemParts, ""))
    end

    return "$" .. table.concat(fields, ";") .. "$"
end

local function GetPlayerExtraData(data, index)

	local unitId = "raid" .. index

	local guid = UnitGUID(unitId)
	if guid == nil then
		return nil
	end
	
	local fields = {}

	local buffs = {}
    for i=1,40 do
    	local _,_,_,count,_,_,_,_,_,_,spellId = UnitAura(unitId, i, "HELPFUL")
    	table.insert(buffs, spellId)
    end
	if #buffs == 0 then
		table.insert(fields, "_")
	else
		table.insert(fields, toCompressedNumberList(buffs))
	end

	local petGuid = UnitGUID("raidpet" .. index)
	if petGuid then
		table.insert(fields, guid .. "," .. petGuid)
    else
		table.insert(fields, '_')
	end

	local name = GetRaidRosterInfo(index)
    local realm = GetRealmName()
    local splitPos = string.find(name, "-")
    if splitPos ~= nil then
        realm = string.sub(name, splitPos + 1)
        name = string.sub(name, 1, splitPos - 1)
    end

	data[realm .. ":" .. name] = table.concat(fields, ";")
end

function AskMrRobot.ExportLoggingData(timestamp)

	local isLogging = AskMrRobot_ReforgeFrame.combatLogTab:IsLogging()
	if not isLogging then
		return
	end

	-- we only get extra information for people if in a raid
	if not IsInRaid() then 
		return
	end

	local data = {}
	for i = 1,40 do
		GetPlayerExtraData(data, i)
	end
	
	AskMrRobot.CombatLogTab.SaveExtras(data, timestamp)
end

function AskMrRobot.ExportToAddonChat(timestamp)
    local msg = AskMrRobot.ExportToCompressedString(false)
    local msgPrefix = timestamp .. "\n" .. AmrRealmName .. "\n" .. AmrCharacterName .. "\n"
    
    -- break the data into 250 character chunks (to deal with the short limit on addon message size)
    local chunks = {}
    local i = 1
    local length = string.len(msg)
    local chunkLen = 249 - string.len(msgPrefix)
    while (i <= length) do
        local endpos = math.min(i + chunkLen, length)
        table.insert(chunks, msgPrefix .. string.sub(msg, i, endpos))
        i = endpos + 1
    end
    
    for i, v in ipairs(chunks) do
        SendAddonMessage(AskMrRobot.ChatPrefix, v, "RAID")
    end
    
    -- send a completion message
    SendAddonMessage(AskMrRobot.ChatPrefix, msgPrefix .. "done", "RAID")
end

-- Create an export string that can be copied to the website
function AskMrRobot.ExportToString()

    --[[
    local fields = {}
    
    fields["realm"] = AmrRealmName
    fields["name"] = AmrCharacterName
    fields["race"] = AmrRace
    fields["faction"] = AmrFaction
    fields["level"] = AmrLevel
    
    local profs = {}
    for k, v in pairs(AmrProfessions) do
        table.insert(profs, k .. ":" .. v)
    end
    fields["professions"] = table.concat(profs, ",")
    
    if (AmrActiveSpec ~= nil) then
        fields["activespec"] = AmrActiveSpec
        fields["spec"] = AmrSpecializations[AmrActiveSpec .. ""]
        fields["talents"] = AmrTalents[AmrActiveSpec]
        fields["glyphs"] = table.concat(AmrGlyphs[AmrActiveSpec], ",")
    end
    
    local items = {}
    for k, v in pairs(AmrEquipedItems) do
        table.insert(items, ItemLinkToExportString(v, k))
    end
    for i, v in ipairs(AmrBagItems) do
        table.insert(items, ItemLinkToExportString(v, "-1"))
    end
    for i, v in ipairs(AmrBankItems) do
        table.insert(items, ItemLinkToExportString(v, "-1"))
    end
    fields["items"] = table.concat(items, "_")
    
    local fieldList = {}
    for k, v in pairs(fields) do
        table.insert(fieldList, k .. "=" .. v)
    end
    ]]
    
    --return table.concat(fieldList, ";")
    
    return AskMrRobot.ExportToCompressedString(true)
    --return AskMrRobot.ExportToAddonChat(time())
end

local function parseGlyphs(input)
	local glyphs = {}
	for glyph in string.gmatch(input, "([^,]+)") do
		tinsert(glyphs, glyph)
	end
	table.sort(glyphs)
	return glyphs
end

local function parseProfessions(input)
	local professions = {}
	for prof, v in string.gmatch(input, "([^:,]+):([^,]+)") do
		professions[prof] = tonumber(v);
	end
	return professions;
end

local gemColorMapping = {
	y = 'Yellow',
	b = 'Blue',
	r = 'Red',
	h = 'Hydraulic',
	p = 'Prismatic',
	m = 'Meta',
	c = 'Cogwheel'
}

local function parseAmrItem(input)
	local slot, itemId, suffixList, upgradeId, gemColorString, gemEnchantIdString, gemIdString, enchantId, reforgeId = string.match(input, "^(%d+):(%d+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(%d+):(%d+)");
	-- parse the gem enchant ids out of their comma seperated list
	local gems = {}
	for gemEnchantId in string.gmatch(gemEnchantIdString, '(%d+)') do
		tinsert(gems, {enchantId = tonumber(gemEnchantId), id = 0})
	end
	-- make sure we have 4 gem ids
	for i = #gems + 1, 4 do
		tinsert(gems, {enchantId = 0, id = 0})
	end	
	-- parse the gem ids out of their comma seperated list	
	local gemIds = {}
	i = 1
	for gemId in string.gmatch(gemIdString, '(%d+)') do
		gems[i].id = tonumber(gemId)
		i = i + 1
	end
	i = 1
	for gemColor in string.gmatch(gemColorString, '([^,])') do
		gems[i].color = gemColorMapping[gemColor]
		i = i + 1
	end

	-- parse the possible suffixes out of their comma seperated list and put them in a set (number -> bool)
	local suffixes = {}
	for suffixId in string.gmatch(suffixList, '(%-?%d+)') do
		suffixes[tonumber(suffixId)] = true
	end

	local item = {
		itemId = tonumber(itemId),
		suffixes = suffixes,
		upgradeId = tonumber(upgradeId),
		gems = gems,
		enchantId = tonumber(enchantId),
		reforgeId = tonumber(reforgeId)
	}
	return slot, item
end


function AskMrRobot.parseAmr(input)
	local parsedInput = {}
	parsedInput.items = {}
	for k, v in string.gmatch(input, "([^=;]+)=([^;]*)") do
		if (k == 'item') then
			local slot, item = parseAmrItem(v);
			parsedInput.items[AskMrRobot.slotIdToSlotNum[tonumber(slot) + 1]] = item;
		 elseif (k == 'glyphs') then
		 	parsedInput.glyphs = parseGlyphs(v)
	 	 elseif (k == 'professions') then
	 	 	parsedInput.professions = parseProfessions(v)
		 else
		 	parsedInput[k]=v
		end
	end
	return parsedInput
end

function AskMrRobot.validateRealm(realm)
	return realm == GetRealmName();
end

function AskMrRobot.validateCharacterName(characterName)
	return UnitName("player") == characterName
end

function AskMrRobot.validateRace(race)
	local _, raceEn = UnitRace("player")
	return raceEn == race or (raceEn == "Scourge" and race == "Undead")
end

function AskMrRobot.validateFaction(faction)
	return faction == UnitFactionGroup("player")
end

function AskMrRobot.validateSpec(spec)
	if spec == 'nil' then 
		spec = nil
	end
	local currentSpec = GetAmrSpecialization(GetActiveSpecGroup())
	return (not currentSpec and not spec) or tostring(currentSpec) == spec
end

function AskMrRobot.validateTalents(talents)
	if talents == nil then
		talents = ''
	end
	return talents == GetAmrTalentsForSpec(GetActiveSpecGroup())
end

function AskMrRobot.validateGlyphs(glyphs)
	if (glyphs == nil) then
		glyphs = {};
	end
	local currentGlyphs = GetAmrGlyphsForSpec(GetActiveSpecGroup())
	table.sort(glyphs, function(a,b) return tostring(a) < tostring(b) end)
	table.sort(currentGlyphs, function(a,b) return tostring(a) < tostring(b) end)

	if #glyphs ~= #currentGlyphs then
		return false
	end
	for i = 1, #glyphs do
		if tostring(glyphs[i]) ~= tostring(currentGlyphs[i]) then
			return false
		end
	end

	return true
end

local function getPrimaryProfessions()
	local profs = {}
	local prof1, prof2 = GetProfessions()
	local profMap = {
		[794] = "Archaeology",
		[171] = "Alchemy",
		[164] = "Blacksmithing",
		[185] = "Cooking",
		[333] = "Enchanting",
		[202] = "Engineering",
		[129] = "First Aid",
		[356] = "Fishing",
		[182] = "Herbalism",
		[773] = "Inscription",
		[755] = "Jewelcrafting",
		[165] = "Leatherworking",
		[186] = "Mining",
		[393] = "Skinning",
		[197] = "Tailoring"
	}

	if prof1 then
		local _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof1);
		if profMap[skillLine] ~= nil then
			profs[profMap[skillLine]] = skillLevel
		end
	end
	if prof2 then
		local _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof2);
		if profMap[skillLine] ~= nil then
			profs[profMap[skillLine]] = skillLevel
		end
	end	
	return profs;
end

local professionThresholds = {
	Leatherworking = 575,
	Inscription = 600,
	Alchemy = 50,
	Enchanting = 550,
	Jewelcrafting = 550,
	Blacksmithing = 550,
	Tailoring = 550
}

function AskMrRobot.validateProfessions(professions)
	local currentProfessions = getPrimaryProfessions()
	if #currentProfessions ~= #professions then
		return false
	end
	for k, v in pairs(professions) do
		if currentProfessions[k] then
			local threshold = professionThresholds[k]
			if not threshold then
				threshold = 1
			end
			-- compare the desired profession against the threshold
			local desired = v >= threshold
			-- compare the current profession against the threshold
			local has = currentProfessions[k] and currentProfessions[k] >= threshold
			-- if the current value is on the other side of the threshold
			-- then we don't match
			if desired ~= has then 
				return false 
			end
		else 
			return false
		end
	end
	return true
end

function AskMrRobot.populateItemDiffs(amrItem, itemLink, slotNum)
	AskMrRobot.itemDiffs.items[slotNum] = nil
	AskMrRobot.itemDiffs.gems[slotNum] = nil
	AskMrRobot.itemDiffs.enchants[slotNum] = nil
	AskMrRobot.itemDiffs.reforges[slotNum] = nil

	local needsUpgrade = false
	local aSuffix = 0
	if amrItem then
		for k,v in pairs(amrItem.suffixes) do
			aSuffix = k
		end
	end

	if itemLink == nil then
		if amrItem ~= nil then
			AskMrRobot.itemDiffs.items[slotNum] = {
				current = nil,
				optimized = { itemId = amrItem.itemId, upgradeId = amrItem.upgradeId, suffixId = aSuffix },
				needsUpgrade = false
			}
		end
		return
	end
	local item = parseItemLink(itemLink)
	local isItemBad = false

	if amrItem == nil or item.itemId ~= amrItem.itemId then
		isItemBad = true
	else
		if item.suffixId == 0 then
			if #amrItem.suffixes > 0 then
				isItemBad = true
			end
		else
			if not amrItem.suffixes[item.suffixId] then
				isItemBad = true
			end
		end
		if not isItemBad and upgradeTable[item.upgradeId] ~= upgradeTable[amrItem.upgradeId] then
			isItemBad = true
			needsUpgrade = true
		end
	end

	if isItemBad then
		AskMrRobot.itemDiffs.items[slotNum] = {
			current = item.itemId,
			optimized = { itemId = amrItem and amrItem.itemId or 0, upgradeId = amrItem and amrItem.upgradeId or 0, suffixId = aSuffix },			
			needsUpgrade = needsUpgrade
		}
		return
	end

	local badGemCount, gemInfo = AskMrRobot.MatchesGems(itemLink, item.gemEnchantIds, amrItem.gems)
	if badGemCount > 0 then
		AskMrRobot.itemDiffs.gems[slotNum] = gemInfo
	end

	if item.enchantId ~= amrItem.enchantId then
		AskMrRobot.itemDiffs.enchants[slotNum] = {
			current = item.enchantId,
			optimized = amrItem.enchantId
		}
	end

	if item.reforgeId ~= amrItem.reforgeId then
		AskMrRobot.itemDiffs.reforges[slotNum] = {
			current = item.reforgeId,
			optimized = amrItem.reforgeId
		}
	end
end

--[[
function AskMrRobot.StartLogging()
	if not LoggingCombat() then
		LoggingCombat(1)
		print("Started Combat Logging")
	end
end

function AskMrRobot.FinishLogging()
	if LoggingCombat() then
		LoggingCombat(0)
		print("Finished Combat Logging")
	end
end

-- local difficultyLookup = {
-- 	DUNGEON_DIFFICULTY1,
-- 	DUNGEON_DIFFICULTY2,
-- 	RAID_DIFFICULTY_10PLAYER,
-- 	RAID_DIFFICULTY_25PLAYER,
-- 	RAID_DIFFICULTY_10PLAYER_HEROIC,
-- 	RAID_DIFFICULTY_25PLAYER_HEROIC,
-- 	RAID_FINDER,
-- 	CHALLENGE_MODE,
-- 	RAID_DIFFICULTY_40PLAYER,
-- 	nil,
-- 	nil, -- Norm scen
-- 	nil, -- heroic scen
-- 	nil,
-- 	PLAYER_DIFFICULTY4
-- }

--http://wowpedia.org/InstanceMapID
local instanceMaps = {
	HeartOfFear = 1009,
	MogushanVaults = 1008,	
	SiegeOfOrgrimmar = 1136,
	TerraceOfEndlessSpring = 996,
	ThroneOfThunder = 1098
}

function AskMrRobot.UpdateLogging()

	-- get the info about the instance
	--local zone, zonetype, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID = GetInstanceInfo()
	local zone, _, difficultyIndex, _, _, _, _, instanceMapID = GetInstanceInfo()
	--local difficulty = difficultyIndex
	-- Unless Blizzard fixes scenarios to not return nil, let's hardcode this into returning "scenario" -Znuff
	--if zonetype == nil and difficultyIndex == 1 then
		--zonetype = "scenario"
	--end

	-- if nothing has changed, then bail
	--if (not zone) and difficulty == 0 then return end
	if zone == AskMrRobot.lastzone and difficultyIndex == AskMrRobot.lastdiff then
	  -- do nothing if the zone hasn't ACTUALLY changed
	  -- otherwise we may override the user's manual enable/disable
	  return
	end

	AskMrRobot.lastzone = zone
	AskMrRobot.lastdiff = difficultyIndex

	if AmrOptions.autoLog[tonumber(instanceMapID)] then
		if instanceMapID == instanceMaps.SiegeOfOrgrimmar then
			AskMrRobot.StartLogging()
		else
			AskMrRobot.FinishLogging()
		end
	end
end
]]
