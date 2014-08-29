--[[

****************************************************************************************
Yogg Brain

File date: 2009-06-01T16:46:36Z 
Project version: v1.11

Author: Ackis
****************************************************************************************

]]

local name = "Yogg Brain"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..name)
local sara = BB["Sara"]
local boss = BB["Yogg-Saron"]
local brain = BB["Brain of Yogg-Saron"]
local LBW = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local BWYoggBrain = nil

local GetNumRaidMembers = GetNumRaidMembers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local UnitExists = UnitExists

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return

{
	["Boss Health"] = true,
	["|cff777777Unknown|r"] = true,
	cmd = "YoggBrain",
	font = "Fonts\\FRIZQT__.TTF",
	on = "On",
	on_desc = "Toggle BigWigs_Yogg Brain on or off.",
}


end )

L:RegisterTranslations("deDE", function() return {

	on = "Aktiv",
	on_desc = "Schaltet BigWigs_Yogg Brain an und aus.",
	["|cff777777Unknown|r"] = "|cff777777Unbekannt|r",
	["Boss Health"] = "Lebenspunkte",

} end )

L:RegisterTranslations("frFR", function() return {

	on = "Actif",
	on_desc = "Active ou non BigWigs_Yogg Brain.",
	["|cff777777Unknown|r"] = "|cff777777Inconnu|r",
	["Boss Health"] = "Vie des boss",

} end )

--[[
L:RegisterTranslations("esES", function() return {

	on = "On",
	on_desc = "Toggle BigWigs_Yogg Brain on or off.",
	["|cff777777Unknown|r"] = true,
	["Boss Health"] = true,

} end )
]]--

--[[
L:RegisterTranslations("esMX", function() return {

	on = "On",
	on_desc = "Toggle BigWigs_Yogg Brain on or off.",
	["|cff777777Unknown|r"] = true,
	["Boss Health"] = true,

} end )
]]--

L:RegisterTranslations("koKR", function() return {

	on = "사용",
	on_desc = "BigWigs_Yogg Brain 켜거나 끕니다.",
	["|cff777777Unknown|r"] = "|cff777777알 수 없음|r",
	["Boss Health"] = "보스 생명력",
	font = "Fonts\\2002.TTF",

} end )

--卡雷苟斯
L:RegisterTranslations("zhCN", function() return {

	on = "打开",
	on_desc = "切换BigWigs_YoggBrainh卡雷苟斯生命监视模块.",
	["|cff777777Unknown|r"] = "|cff777777未知|r",
	["Boss Health"] = "Boss生命值",
	font = "Fonts\\ZYKai_T.TTF",

} end )

L:RegisterTranslations("zhTW", function() return {

	on = "啟用",
	on_desc = "Toggle BigWigs_Yogg Brain on or off.",
	["|cff777777Unknown|r"] = "|cff777777未知|r",
	["Boss Health"] = "BOSS生命值",
	font = "Fonts\\bHEI01B.TTF",

} end )

--[[
L:RegisterTranslations("ruRU", function() return {

	on = "On",
	on_desc = "Toggle BigWigs_Yogg Brain on or off.",
	["|cff777777Unknown|r"] = true,
	["Boss Health"] = true,

} end )
]]--

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(name)
mod.synctoken = name
mod.zonename = BZ["Ulduar"]
mod.enabletrigger = {boss, sara, brain}
mod.toggleoptions = {"on"}
mod.revision = 5
mod.external = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("BigWigs_RecvSync")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	if BWYoggBrain then
		BWYoggBrain:Hide()
	end
	local BrainHealth = nil
end

function mod:OnDisable()
	if BWYoggBrain then
		BWYoggBrain:Hide()
	end
end

------------------------------
--      Events              --
------------------------------

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if not self.db.profile.on then return end

	if msg == LBW["engage_trigger"] then
		if not BWYoggBrain then
			self:SetupFrames()
		else
			BWYoggBrain:Show()
			-- Set the health to 100% at the start
			BWYoggBrain.text1:SetText("|cffff0000" .. brain .."): 100%")
		end

		self:ScheduleRepeatingEvent("BWYoggBrainCheck", self.Update, 1, self)
	end
end

function mod:PLAYER_REGEN_ENABLED()
	if not self.db.profile.on then return end

	local go = self:Scan()
	local running = self:IsEventScheduled("YoggSaron_CheckWipe")
	if not go then
		self:TriggerEvent("BigWigs_RebootModule", self)
	elseif not running then
		self:ScheduleRepeatingEvent("YoggSaron_CheckWipe", self.PLAYER_REGEN_ENABLED, 2, self)
	end
end

function mod:BigWigs_RecvSync(sync, rest1, rest2, name)
	if (sync == "BWBossDeath") and (rest1 == "Yogg Saron") then
		BigWigs:ToggleModuleActive(self, false)
		if BWYoggBrain then
			BWYoggBrain:Hide()
		end
	elseif (sync == "YoggHealth") then
		BrainHealth = tonumber(rest1)
		self:UpdateHealthText()
	end
end

function mod:UpdateHealthText()
	if not BWYoggBrain then return end

	BWYoggBrain.text1:SetText("|cffff0000" .. brain .. (BrainHealth and BrainHealth .. "%" or "?"))

end

function mod:Update()

	for i = 1, GetNumRaidMembers() do

		local unitidtarget = "raid" .. i .. "target"
		if UnitExists(unitidtarget) then
			if UnitName(unitidtarget) == brain then
				if UnitIsEnemy("player", unitidtarget) then
					self:Sync("YoggHealth", ("%.1f"):format(UnitHealth(unitidtarget)/UnitHealthMax(unitidtarget)*100))
				end
			end
		end

	end
end 

function mod:SetupFrames()
	BWYoggBrain = CreateFrame("Frame", "BWYoggBrainDisplay", UIParent)

	BWYoggBrain:SetWidth(200)
	BWYoggBrain:SetHeight(75)

	BWYoggBrain:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		edgeFile = "Interface\\AddOns\\BigWigs\\Textures\\otravi-semi-full-border", edgeSize = 32,
		insets = {left = 1, right = 1, top = 20, bottom = 1},
	})

	BWYoggBrain:SetBackdropColor(24/255, 24/255, 24/255)
	BWYoggBrain:ClearAllPoints()
	BWYoggBrain:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	BWYoggBrain:EnableMouse(true)
	BWYoggBrain:RegisterForDrag("LeftButton")
	BWYoggBrain:SetClampedToScreen(true)
	BWYoggBrain:SetMovable(true)
	BWYoggBrain:SetScript("OnDragStart", function() this:StartMoving() end)
	BWYoggBrain:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		self:SavePosition()
	end)

	local cheader = BWYoggBrain:CreateFontString(nil, "OVERLAY")
	cheader:ClearAllPoints()
	cheader:SetWidth(190)
	cheader:SetHeight(15)
	cheader:SetPoint("TOP", BWYoggBrain, "TOP", 0, -14)
	cheader:SetFont(L["font"], 12)
	cheader:SetJustifyH("CENTER")
	cheader:SetText(L["Boss Health"])
	cheader:SetShadowOffset(.8, -.8)
	cheader:SetShadowColor(0, 0, 0, 1)
	BWYoggBrain.cheader = cheader

	local text = BWYoggBrain:CreateFontString(nil, "OVERLAY")
	text:ClearAllPoints()
	text:SetWidth( 190 )
	text:SetHeight( 80 )
	text:SetPoint( "TOP", BWYoggBrain, "TOP", 0, -35 )
	text:SetJustifyH("RIGHT")
	text:SetJustifyV("TOP")
	text:SetFont(L["font"], 12)
	BWYoggBrain.text1 = text

	local x = self.db.profile.posx
	local y = self.db.profile.posy
	if x and y then
		local s = BWYoggBrain:GetEffectiveScale()
		BWYoggBrain:ClearAllPoints()
		BWYoggBrain:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
	end
	
	self:UpdateHealthText()

end

function mod:SavePosition()
	if not BWYoggBrain then self:SetupFrames() end

	local s = BWYoggBrain:GetEffectiveScale()
	self.db.profile.posx = BWYoggBrain:GetLeft() * s
	self.db.profile.posy = BWYoggBrain:GetTop() * s
end
