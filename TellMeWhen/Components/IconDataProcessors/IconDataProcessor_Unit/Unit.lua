﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print


local Processor = TMW.Classes.IconDataProcessor:New("UNIT", "unit, GUID")
Processor:DeclareUpValue("UnitGUID", UnitGUID)
Processor:DeclareUpValue("playerGUID", UnitGUID('player'))

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: unit, GUID
	t[#t+1] = [[
	
	GUID = GUID or (unit and (unit == "player" and playerGUID or UnitGUID(unit)))
	
	if attributes.unit ~= unit or attributes.GUID ~= GUID then
		local previousUnit = attributes.unit
		attributes.previousUnit = previousUnit
		attributes.unit = unit
		attributes.GUID = GUID

		if EventHandlersSet.OnUnit then
			icon:QueueEvent("OnUnit")
		end
		
		TMW:Fire(UNIT.changedEvent, icon, unit, previousUnit, GUID)
		doFireIconUpdated = true
	end
	--]]
end

Processor:RegisterIconEvent(41, "OnUnit", {
	text = L["SOUND_EVENT_ONUNIT"],
	desc = L["SOUND_EVENT_ONUNIT_DESC"],
})

Processor:RegisterDogTag("TMW", "Unit", {
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		if icon then
			return icon.attributes.unit or ""
		else
			return ""
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("UNIT"),
	ret = "string",
	doc = L["DT_DOC_Unit"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[Unit] => "target"; [Unit:Name] => "Kobold"; [Unit(icon="TMW:icon:1I7MnrXDCz8T")] => "focus"; [Unit(icon="TMW:icon:1I7MnrXDCz8T"):Name] => "Gamon"',
	category = L["ICON"],
})
Processor:RegisterDogTag("TMW", "PreviousUnit", {
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		if icon then
			return icon.__lastUnitChecked or ""
		else
			return ""
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("UNIT"),
	ret = "string",
	doc = L["DT_DOC_PreviousUnit"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[PreviousUnit] => "target"; [PreviousUnit:Name] => "Kobold"; [PreviousUnit(icon="TMW:icon:1I7MnrXDCz8T")] => "focus"; [PreviousUnit(icon="TMW:icon:1I7MnrXDCz8T"):Name] => "Gamon"',
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("unit, GUID", nil, nil)
end)
