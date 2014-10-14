﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local type, wipe, pairs, rawget =
	  type, wipe, pairs, rawget
local UnitGUID, IsInInstance =
	  UnitGUID, IsInInstance
local bit_band = bit.band

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local huge = math.huge

local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures



local Type = TMW.Classes.IconType:New("unitcooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_UNITCOOLDOWN"]
Type.desc = L["ICONMENU_UNITCOOLDOWN_DESC"]
Type.menuIcon = GetSpellTexture(19263)
Type.usePocketWatch = 1
Type.DurationSyntax = 1
Type.unitType = "unitid"
Type.canControlGroup = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



Type:RegisterIconDefaults{
	-- The unit(s) to check for cooldowns
	Unit					= "player", 

	-- True to only show the icon if the unit has used the ability at least once.
	OnlySeen				= false,

	-- Sort the cooldowns found by duration
	Sort					= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "spellwithduration",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_UnitCooldownSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "OnlySeen",
			title = L["ICONMENU_ONLYSEEN"],
			tooltip = L["ICONMENU_ONLYSEEN_DESC"],
		},
	})
end)

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettings", {
	hidden = function(self)
		return TMW.CI.icon:IsGroupController()
	end,
})



-- Holds all unitcooldown icons whose update method is "manual" (not "auto")
-- Since the event handling for this icon type is all done by a single handler that operates on all icons,
-- we need to know which icons we need to queue an update for when something changes.
local ManualIcons = {}
local ManualIconsManager = TMW.Classes.UpdateTableManager:New()
ManualIconsManager:UpdateTable_Set(ManualIcons)


-- Holds the cooldowns of all known units. Structure is:
--[[ Cooldowns = {
	[GUID] = {
		[spellID] = lastCastTime,
		[spellName] = spellID,
		...
	},
	...
}
]]
local Cooldowns = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end})



local resetsOnCast = {
	
	[108285] = { -- Call of the Elements
		[108269] = 1, -- Capacitor Totem
		[8177] = 1, -- Grounding Totem
		[51485] = 1, -- Earthgrab Totem
		[8143] = 1, -- Tremor Totem
		[5394] = 1, -- Healing Stream Totem
	},
	[11129] = { -- Combustion
		[108853] = 1, -- Inferno Blast
	},
	[11958] = { -- coldsnap
		[45438] = 1, -- iceblock
		[31661] = 1, -- dragon's breath
		[12043] = 1, -- presence of mind
		[120] = 1, -- cone of cold
		[122] = 1, -- frost nova
	},
	[14185] = { --prep
		[5277] = 1, -- Evasion
		[2983] = 1, -- Sprint
		[1856] = 1, -- Vanish
	},
	[50334] = { --druid berserk or something
		[33878] = 1,
		[33917] = 1,
	},
}
local resetsOnAura = {
	[81162] = { -- Will of the Necropolis
		[48982] = 1, -- Rune Tap
	},
	[93622] = { -- Mangle! (from lacerate and thrash)
		[33878] = 1, -- Mangle
	},
	[48518] = { -- lunar eclipse
		[48505] = 1, -- Starfall
	},
	[50227] = { -- Sword and Board
		[23922] = 1, -- Shield Slam
	},
	[59578] = { -- The Art of War
		[879] = 1, -- Exorcism
	},
	[52437] = { -- Sudden Death
		[86346] = 1, -- Colossus Smash
	},
	[124430] = { -- Divine Insight (Shadow version)
		[8092] = 1, -- Mind Blast
	},
	[77762] = { -- Lava Surge
		[51505] = 1, -- Lava Burst
	},
	[93400] = { -- Shooting Stars
		[78674] = 1, -- Starsurge
	},
	[32216] = { -- Victorious
		[103840] = 1, -- Impending Victory
	},
}
local spellBlacklist = {
	[50288] = 1, -- Starfall damage effect, causes the cooldown to be off by 10 seconds and prevents proper resets when tracking by name.
}


function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _, spellID, spellName)
	if cleuEvent == "SPELL_CAST_SUCCESS"
	or cleuEvent == "SPELL_AURA_APPLIED"
	or cleuEvent == "SPELL_AURA_REFRESH"
	or cleuEvent == "SPELL_DAMAGE"
	or cleuEvent == "SPELL_HEAL"
	or cleuEvent == "SPELL_MISSED"
	then
	
		if spellBlacklist[spellID] then
			return
		end
		
		spellName = spellName and strlowerCache[spellName]
		local cooldownsForGUID = Cooldowns[sourceGUID]
		
		if cleuEvent == "SPELL_AURA_APPLIED" and resetsOnAura[spellID] then
			-- Handle things that reset on aura application.
			for id in pairs(resetsOnAura[spellID]) do
				if cooldownsForGUID[id] then
					-- dont set it to 0 if it doesnt exist so we dont make spells that havent been seen suddenly act like they have been seen
					-- on the other hand, dont set things to nil or it will look like they haven't been seen.
					cooldownsForGUID[id] = 0
					
					-- Force update all icons. Too hard to check each icon to see if they were tracking the spellIDs that were reset,
					-- or if they were tracking the names of the spells that were reset.
					for k = 1, #ManualIcons do
						ManualIcons[k].NextUpdateTime = 0
					end
				end
			end
		end
		

		if cleuEvent == "SPELL_CAST_SUCCESS" then
			if resetsOnCast[spellID] then
				for id in pairs(resetsOnCast[spellID]) do
					if cooldownsForGUID[id] then
						-- dont set it to 0 if it doesnt exist so we dont make spells that havent been seen suddenly act like they have been seen
						-- on the other hand, dont set things to nil or it will look like they haven't been seen.
						cooldownsForGUID[id] = 0
						
						-- Force update all icons. Too hard to check each icon to see if they were tracking the spellIDs that were reset,
						-- or if they were tracking the names of the spells that were reset.
						for k = 1, #ManualIcons do
							ManualIcons[k].NextUpdateTime = 0
						end
					end
				end
			end
			cooldownsForGUID[spellName] = spellID
			cooldownsForGUID[spellID] = TMW.time
		else
			local time = TMW.time
			local storedTimeForSpell = cooldownsForGUID[spellID]
			
			-- If this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS
			-- or a UNIT_SPELLCAST_SUCCEEDED then ignore it.
			-- (This is just a safety window for spell travel time so that
			-- if we found the real cast start, we dont overwrite it)
			-- (And really, how often are people actually going to be tracking cooldowns with cast times?
			-- There arent that many, and the ones that do exist arent that important)
			if not storedTimeForSpell or storedTimeForSpell + 1.8 < time then
				cooldownsForGUID[spellName] = spellID
				
				-- Hack it to make it a little bit more accurate.
				-- A max range dk deathcoil has a travel time of about 1.3 seconds,
				-- so 1 second should be a good average to be safe with travel times.
				cooldownsForGUID[spellID] = time-1			
			end
		end
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.Spells.Hash
			if NameHash and (NameHash[spellID] or NameHash[spellName]) then
				icon.NextUpdateTime = 0
			end
		end
	elseif cleuEvent == "UNIT_DIED" then
		if destFlags then
			if bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER then
				-- Don't reset the cooldowns of a player if they die. Only NPCs.
				Cooldowns[destGUID] = nil
			end
		end
	end
end

function Type:UNIT_SPELLCAST_SUCCEEDED(event, unit, spellName, _, _, spellID)
	local sourceGUID = UnitGUID(unit)
	if sourceGUID then
		-- For some reason, this is firing for unit "npc," (yes, there is a comma there).
		-- It also seems to fire for "npc" without a comma, so ignore that too it it doesnt have a GUID.
		-- Obviously this is invalid, but if you find anything else invalid then scream about it too.
		
		-- Addendum 6-17-12: Fired for arena1 and GUID was nil. Seems this is a more common issue than I though,
		-- so remove all errors and just ignore things without GUIDs.
		
		local c = Cooldowns[sourceGUID]
		spellName = strlowerCache[spellName]
		
		c[spellName] = spellID
		c[spellID] = TMW.time
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.Spells.Hash
			if NameHash and (NameHash[spellID] or NameHash[spellName]) then
				icon.NextUpdateTime = 0
			end
		end
	end
end



-- Wipe cooldowns for arena enemies:
local isArena
local resetForArena = {}
function Type:PLAYER_ENTERING_WORLD()
	local _, zoneType = IsInInstance()
	local wasArena = isArena
	isArena = zoneType == "arena"
	if isArena and not wasArena then
		wipe(resetForArena)
		Type:RegisterEvent("GROUP_ROSTER_UPDATE")
		Type:RegisterEvent("ARENA_OPPONENT_UPDATE")
	elseif not isArena then
		Type:UnregisterEvent("GROUP_ROSTER_UPDATE")
		Type:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	end
end
Type:RegisterEvent("PLAYER_ENTERING_WORLD")
Type:RegisterEvent("ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD")

function Type:GROUP_ROSTER_UPDATE()
	for i = 1, 40 do
		local GUID = UnitGUID("raid" .. i)
		if not GUID then
			return
		elseif not resetForArena[GUID] then
			wipe(Cooldowns[GUID])
			resetForArena[GUID] = 1
		end
	end
end

function Type:ARENA_OPPONENT_UPDATE()
	for i = 1, 5 do
		local GUID = UnitGUID("arena" .. i)
		if not GUID then
			return
		elseif not resetForArena[GUID] then
			wipe(Cooldowns[GUID])
			resetForArena[GUID] = 1
		end
	end
end
-- End arena enemy cooldown reset code.



local function UnitCooldown_OnEvent(icon, event, arg1)
	if event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local BLANKTABLE = {}

local function UnitCooldown_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Alpha, NameArray, OnlySeen, Sort, Durations, Units =
	icon.Alpha, icon.Spells.Array, icon.OnlySeen, icon.Sort, icon.Spells.Durations, icon.Units

	-- These variables will hold all the attributes that we pass to SetInfo().
	local unstart, unname, unduration, usename, dobreak, useUnit, unUnit
	
	-- Initial values for the vars that track the duration/stack of the aura that currently occupies unname and related locals.
	-- If we are sorting by smallest duration, we intitialize to math.huge so that the first thing we find is definitely smaller.
	local curSortDur = Sort == -1 and huge or 0

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local cooldowns = GUID and rawget(Cooldowns, GUID)

		if u == 1 and GUID and not cooldowns and not OnlySeen then
			-- If this is the first unit, use a blank cooldowns table for it if it doesn't exist
			-- so that we can still find the first usable spell.
			-- Such a dirty, dirty hack.
			cooldowns = BLANKTABLE
		end

		if cooldowns then
			for i = 1, #NameArray do
				local iName = NameArray[i]

				if not isNumber[iName] then
					-- spell name keys have values that are the spellid of the name,
					-- we need the spellid for the texture (thats why i did it like this)
					iName = cooldowns[iName] or iName
				end

				local start
				if OnlySeen then
					-- If we only want cooldowns that have been seen,
					-- don't default to 0 if it isn't in the table.
					start = cooldowns[iName]
				else
					start = cooldowns[iName] or 0
				end

				if start then
					local duration = Durations[i]
					local remaining = duration - (time - start)
					if remaining < 0 then remaining = 0 end

					if Sort then
						if remaining ~= 0 then
							-- Found an unusable cooldown
							-- Sort is either 1 or -1, so multiply by it to get the correct ordering.
							-- (multiplying by a negative flips inequalities)
							if curSortDur*Sort < remaining*Sort then
								curSortDur = remaining
								unname = iName
								unstart = start
								unduration = duration
								unUnit = unit
							end
						else
							-- We found the first usable cooldown
							if not usename then
								usename = iName
								useUnit = unit
							end
						end
					else
						if remaining ~= 0 and not unname then
							-- We found the first UNusable cooldown
							unname = iName
							unstart = start
							unduration = duration
							unUnit = unit

							-- We DONT care about usable cooldowns, so stop looking
							if Alpha == 0 then 
								dobreak = 1
								break
							end
						elseif remaining == 0 and not usename then
							-- We found the first usable cooldown
							usename = iName
							useUnit = unit

							-- We care about usable cooldowns, so stop looking
							if Alpha ~= 0 then 
								dobreak = 1
								break
							end
						end
					end
				end
			end
			if dobreak then
				break
			end
		end
	end
	
	if usename and Alpha > 0 then
		icon:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			icon.Alpha,
			SpellTextures[usename] or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			0, 0,
			usename,
			useUnit, nil
		)

	elseif unname then
		icon:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			icon.UnAlpha,
			SpellTextures[unname],
			unstart, unduration,
			unname,
			unUnit, nil
		)

	else
		icon:SetInfo("alpha", 0)
	end
end

local function UnitCooldown_OnUpdate_Controller(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Alpha, UnAlpha, NameArray, OnlySeen, Durations, Units =
	icon.Alpha, icon.UnAlpha, icon.Spells.Array, icon.OnlySeen, icon.Spells.Durations, icon.Units
		
	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local cooldowns = GUID and rawget(Cooldowns, GUID)

		if u == 1 and GUID and not cooldowns and not OnlySeen then
			-- If this is the first unit, use a blank cooldowns table for it if it doesn't exist
			-- so that we can still find the first usable spell.
			-- Such a dirty, dirty hack.
			cooldowns = BLANKTABLE
		end

		if cooldowns then
			for i = 1, #NameArray do
				local iName = NameArray[i]
				if not isNumber[iName] then
					-- spell name keys have values that are the spellid of the name,
					-- we need the spellid for the texture (thats why i did it like this)
					iName = cooldowns[iName] or iName
				end

				local start
				if OnlySeen then
					-- If we only want cooldowns that have been seen,
					-- don't default to 0 if it isn't in the table.
					start = cooldowns[iName]
				else
					start = cooldowns[iName] or 0
				end

				if start then
					local duration = Durations[i]
					local remaining = duration - (time - start)
					if remaining < 0 then remaining = 0 end

					if remaining ~= 0 then
						if UnAlpha > 0 and not icon:YieldInfo(true, iName, start, duration, unit, GUID, UnAlpha) then
							-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
							return
						end

					else
						if Alpha > 0 and not icon:YieldInfo(true, iName, 0, 0, unit, GUID, Alpha) then
							-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
							return
						end
					end
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end
function Type:HandleYieldedInfo(icon, iconToSet, name, start, duration, unit, GUID, alpha)
	if name then
		iconToSet:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			alpha,
			SpellTextures[name] or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			start, duration,
			name,
			unit, GUID
		)
	else
		iconToSet:SetInfo("alpha", 0)
	end

end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)

	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	

	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))



	-- Setup event handling to catch unit spellcasts and such.
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")



	-- Setup icon events and update functions.
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		ManualIconsManager:UpdateTable_Register(icon)
		
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", UnitCooldown_OnEvent, icon)
	end

	if icon:IsGroupController() then
		icon:SetUpdateFunction(UnitCooldown_OnUpdate_Controller)
	else
		icon:SetUpdateFunction(UnitCooldown_OnUpdate)
	end

	icon:Update()
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event, icon)
	Type:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end)

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
	ManualIconsManager:UpdateTable_Unregister(icon)
end)

Type:Register(40)