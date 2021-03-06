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
local gsub, pairs, ipairs, tostring, format, wipe, bitband =
	  gsub, pairs, ipairs, tostring, format, wipe, bit.band
local UnitGUID =
	  UnitGUID

local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

local huge = math.huge
local CL_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

-- GLOBALS: TellMeWhen_ChooseName


local DRData = LibStub("DRData-1.0")

local DRSpells = DRData.spells
local DRReset = 18
local PvEDRs = {}
for spellID, category in pairs(DRSpells) do
	if DRData.pveDR[category] then
		PvEDRs[spellID] = 1
	end
end


local Type = TMW.Classes.IconType:New("dr")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DR"]
Type.desc = L["ICONMENU_DR_DESC"]
Type.menuIcon = GetSpellTexture(408)
Type.usePocketWatch = 1
Type.unitType = "unitid"
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)



TMW:RegisterDatabaseDefaults{
	global = {
		-- The default length of diminishing returns.
		-- Supposedly, the actual behavior is that the server "ticks" every 5 seconds to clear DRs.
		-- This happens at a min of 15 seconds and a max of 20 seconds.
		DRDuration = 17
	},
}

Type:RegisterIconDefaults{
	-- The unit(s) to check for DRs
	Unit					= "player", 

	-- Listen to the combat log for spell refreshes.
	-- This is a good thing and a bad thing.
	-- You need it to catch re-applications of an effect before it ended
	-- but it will also catch "fake" refreshes caused by spells that break after a certain amount of damage.
	CheckRefresh			= true,

	-- Show the icon even when no units have been known to have an effect put on them.
	ShowWhenNone			= false,
}

TMW:RegisterUpgrade(71035, {
	icon = function(self, ics)
		-- DR categories that no longer exist (or never really existed):

		ics.Name = ics.Name:
			gsub("DR%-DragonsBreath", "DR-ShortDisorient"):
			gsub("DR%-BindElemental", "DR-Disorient"):
			gsub("DR%-Charge", "DR-RandomStun"):
			gsub("DR%-IceWard", "DR-RandomRoot"):
			gsub("DR%-Scatter", "DR-ShortDisorient"):
			gsub("DR%-Banish", "DR-Disorient"):
			gsub("DR%-Entrapment", "DR-RandomRoot"):
			gsub("DR%-Fear", "DR-Incapacitate"):
			gsub("DR%-MindControl", "DR-Incapacitate"):
			gsub("DR%-Horrify", "DR-Incapacitate"):
			gsub("DR%-RandomRoot", "DR-Root"):
			gsub("DR%-ShortDisorient", "DR-Disorient"):
			gsub("DR%-Fear", "DR-Disorient"):
			gsub("DR%-Cyclone", "DR-Disorient"):
			gsub("DR%-ControlledStun", "DR-Stun"):
			gsub("DR%-RandomStun", "DR-Stun"):
			gsub("DR%-ControlledRoot", "DR-Root")
	end,
})


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "dr",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_DRABSENT"], 	},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_DRPRESENT"], 	},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_DRSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "CheckRefresh",
			title = L["ICONMENU_CHECKREFRESH"],
			tooltip = L["ICONMENU_CHECKREFRESH_DESC"],
		},
		{
			setting = "ShowWhenNone",
			title = L["ICONMENU_SHOWWHENNONE"],
			tooltip = L["ICONMENU_SHOWWHENNONE_DESC"],
		},
	})
end)


TMW:RegisterCallback("TMW_EQUIVS_PROCESSING", function()
	-- Create our own DR equivalencies in TMW using the data from DRData-1.0

	if DRData then
		local myCategories = {
			ctrlstun		= "DR-Stun",
			silence			= "DR-Silence",
			disorient		= "DR-Disorient",
			ctrlroot		= "DR-Root", 
			incapacitate	= "DR-Incapacitate",
			taunt 			= "DR-Taunt",
		}

		local ignored = {
			rndstun = true,
			fear = true,
			mc = true,
			cyclone = true,
			shortdisorient = true,
			horror = true,
			disarm = true,
			shortroot = true,
			knockback = true,
		}
		
		TMW.BE.dr = {}
		local dr = TMW.BE.dr
		for spellID, category in pairs(DRData.spells) do
			local k = myCategories[category]

			if k then
				dr[k] = (dr[k] and (dr[k] .. ";" .. spellID)) or tostring(spellID)
			elseif TMW.debug and not ignored[category] then
				TMW:Error("The DR category %q is undefined!", category)
			end
		end
	end
end)

local function DR_OnEvent(icon, event, arg1, cevent, _, _, _, _, _, destGUID, _, destFlags, _, spellID, spellName, _, auraType)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if auraType == "DEBUFF" and (cevent == "SPELL_AURA_REMOVED" or cevent == "SPELL_AURA_APPLIED" or (icon.CheckRefresh and cevent == "SPELL_AURA_REFRESH")) then
			local NameHash = icon.Spells.Hash
			if NameHash[spellID] or NameHash[strlowerCache[spellName]] then

				-- Check that either the spell always has DR, or that the target is a player (or pet).
				if PvEDRs[spellID] or bitband(destFlags, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER then
					-- dr is the table that holds the DR info for this target GUID.
					local dr = icon.DRInfo[destGUID]

					if cevent == "SPELL_AURA_APPLIED" then
						-- If something is applied, and the timer is expired,
						-- reset the timer in preparation for the effect falling off.
						if dr and dr.start + dr.duration <= TMW.time then
							dr.start = 0
							dr.duration = 0
							dr.amt = 100
						end
					else
						if not dr then
							-- If there isn't already a table, make one
							-- Start it off at 50% because the unit just got diminished.
							dr = {
								amt = 50,
								start = TMW.time,
								duration = DRReset,
								tex = SpellTextures[spellID]
							}
							icon.DRInfo[destGUID] = dr
						else
							-- Diminish the unit by one tick.
							-- Ticks go 100 -> 50 -> 25 -> 0
							local amt = dr.amt
							if amt and amt ~= 0 then
								dr.amt = amt > 25 and amt/2 or 0
								dr.duration = DRReset
								dr.start = TMW.time
								dr.tex = SpellTextures[spellID]
							end
						end
					end
					
					-- Schedule an update
					icon.NextUpdateTime = 0
				end
			end
		end
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local function DR_OnUpdate(icon, time)
	-- Upvalue things that will be referenced a lot in our loops.
	local Alpha, UnAlpha, Units = icon.Alpha, icon.UnAlpha, icon.Units

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local dr = icon.DRInfo[GUID]

		if dr then
			if dr.start + dr.duration <= time then
				-- The timer is expired.

				icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
					icon.Alpha,
					dr.tex,
					0, 0,
					nil, nil,
					unit, GUID
				)
				
				if Alpha > 0 then
					return
				end
			else
				-- The timer is not expired.

				local amt = dr.amt
				icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
					icon.UnAlpha,
					dr.tex,
					dr.start, dr.duration,
					amt, amt .. "%",
					unit, GUID
				)
				if UnAlpha > 0 then
					return
				end
			end
		else
			-- The unit doesn't have any DR.
			icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
				icon.Alpha,
				icon.FirstTexture,
				0, 0,
				nil, nil,
				unit, GUID
			)
			if Alpha > 0 then
				return
			end
		end
	end
	
	if icon.ShowWhenNone then
		-- Nothing found. Show default state of the icon.
		icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
			icon.Alpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			Units[1], nil
		)
	else
		icon:SetInfo("alpha", 0)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return data and (L[data] or gsub(data, "DR%-", ""))
end

local CheckCategories
-- CheckCategories is a function that will scan through the spells checked by an icon
-- and tell the user if they are checking spells from more than one DR category in a single icon (which doesn't work).
do	-- CheckCategories
	local length = 0

	-- Holds the spells found from each category. Also increments the counter when a new category is found.
	local categories = setmetatable({}, {
		__index = function(t, k)
			local tbl = {
				order = length,
				str = "",
			}
			length = length + 1
			t[k] = tbl
			return tbl
		end
	})

	local func = function(NameArray)
		local firstCategory
		local append = ""

		for i, IDorName in ipairs(NameArray) do
			for category, str in pairs(TMW.BE.dr) do

				local Names = TMW:GetSpells(str)

				-- Check if the spell being checked by the icon is in the DR category that we are looking at.
				if Names.Hash[IDorName] or Names.StringHash[IDorName] then
					
					-- Record it as the first category found if we haven't found one yet.
					firstCategory = firstCategory or category

					-- Stick the current spell onto the string for the category.
					categories[category].str = categories[category].str .. ";" .. TMW:RestoreCase(IDorName)
				end
			end
		end

		-- If there was more than one category of spells found, we need to warn the user about it.
		local doWarn = length > 1

		-- Create a string of every category and all the spells found for that category.
		for category, data in TMW:OrderedPairs(categories, TMW.OrderSort, true) do
			append = append .. format("\r\n\r\n%s:\r\n%s", L[category], TMW:CleanString(data.str))
		end

		-- Reset for the next use.
		wipe(categories)
		length = 0
		
		return append, doWarn, firstCategory
	end

	CheckCategories = function(icon)
		local append, doWarn, firstCategory = func(icon.Spells.Array)


		if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
			if doWarn then
				TMW.HELP:Show{
					code = "ICON_DR_MISMATCH",
					codeOrder = 5,
					icon = icon,
					relativeTo = TellMeWhen_ChooseName,
					x = 0,
					y = 0,
					text = format(L["WARN_DRMISMATCH"] .. append)
				}
			else
				TMW.HELP:Hide("ICON_DR_MISMATCH")
			end
		end

		return firstCategory
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	
	-- If the spells being checked by the icon have changed since the last icon setup,
	-- wipe the table that holds all the DR info for every unit.
	if not icon.oldDRName then
		icon.DRInfo = icon.DRInfo or {}
		icon.oldDRName = icon.Name
	elseif icon.oldDRName and icon.oldDRName ~= icon.Name then
		wipe(icon.DRInfo)
	end
	
	-- Update this local from the global setting.
	DRReset = TMW.db.global.DRDuration
	
	icon.FirstTexture = SpellTextures[icon.Spells.First]

	-- Do the Right Thing and tell people if their DRs mismatch
	local firstCategoy = CheckCategories(icon)

	icon:SetInfo("texture; spell",
		Type:GetConfigIconTexture(icon),
		firstCategoy
	)



	-- Setup events and update functions
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", DR_OnEvent, icon)
	end
	
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", DR_OnEvent)

	icon:SetUpdateFunction(DR_OnUpdate)
	icon:Update()
end

Type:Register(140)