﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local GetInventoryItemTexture, GetInventorySlotInfo, GetSpellTexture
	= GetInventoryItemTexture, GetInventorySlotInfo, GetSpellTexture
local pairs
	= pairs  
	
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

local INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND =
	  INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND


if not TMW.COMMON.SwingTimerMonitor then
	return
end

local SwingTimers = TMW.COMMON.SwingTimerMonitor.SwingTimers


local Type = TMW.Classes.IconType:New("swingtimer")
Type.name = L["ICONMENU_SWINGTIMER"]
Type.desc = L["ICONMENU_SWINGTIMER_DESC"]
Type.menuIcon = "Interface\\Icons\\INV_Gauntlets_04"
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



Type:RegisterIconDefaults{
	-- Weapon slot to monitor the swing of. Can also be "SecondaryHandSlot".
	SwingTimerSlot			= "MainHandSlot",
}


if pclass == "HUNTER" then
	Type:RegisterConfigPanel_XMLTemplate(130, "TellMeWhen_AutoshootSwingTimerTip")
end

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_SWINGTIMER_SWINGING"],			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_SWINGTIMER_NOTSWINGING"],		},
})


Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_WeaponSlot", function(self)
	self.Header:SetText(TMW.L["ICONMENU_WPNENCHANTTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "SwingTimerSlot",
			value = "MainHandSlot",
			title = INVTYPE_WEAPONMAINHAND,
		},
		{
			setting = "SwingTimerSlot",
			value = "SecondaryHandSlot",
			title = INVTYPE_WEAPONOFFHAND,
		},
	})
end)



local function SwingTimer_OnEvent(icon, event, unit, _, _, _, spellID)
	if event == "UNIT_INVENTORY_CHANGED" then
		-- Update the icon's texture when the player changes weapons.
		local wpnTexture = GetInventoryItemTexture("player", icon.Slot)
		icon:SetInfo("texture", wpnTexture or SpellTextures[15590])

	elseif event == "TMW_COMMON_SWINGTIMER_CHANGED" then
		-- Queue an icon update when the swing timer updates.
		icon.NextUpdateTime = 0
	end
end

local function SwingTimer_OnUpdate(icon, time)

	-- Get the SwingTimer object for the slow from TMW's common swing timer module
	local SwingTimer = SwingTimers[icon.Slot]
	
	if time - SwingTimer.startTime > SwingTimer.duration then
		-- Weapon swing is not on cooldown.
		icon:SetInfo(
			"alpha; start, duration",
			icon.UnAlpha,
			0, 0
		)
	else
		-- Weapon swing is on cooldown
		icon:SetInfo(
			"alpha; start, duration",
			icon.Alpha,
			SwingTimer.startTime, SwingTimer.duration
		)
	end
end



function Type:Setup(icon)
	-- Convert the slot name to a slotID.
	icon.Slot = GetInventorySlotInfo(icon.SwingTimerSlot)


	local wpnTexture = GetInventoryItemTexture("player", icon.Slot)
	icon:SetInfo("texture", wpnTexture or SpellTextures[15590])
	
	
	-- Register events and setup update functions.
	TMW:RegisterCallback("TMW_COMMON_SWINGTIMER_CHANGED", SwingTimer_OnEvent, icon)
	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	
	icon:SetScript("OnEvent", SwingTimer_OnEvent)
	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(SwingTimer_OnUpdate)
	
	
	icon:Update()
end


Type:Register(155)
