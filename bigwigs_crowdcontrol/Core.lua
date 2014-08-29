
local success, targetID = false, nil
local player = UnitName("player")
local CC = BigWigs:NewModule("Crowd Control")
CC.revision = 1
CC.external = true


function CC:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- yes, this is a mess... but it Works
function CC:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, detail1, detail2, detail3)
	if event == "SPELL_AURA_APPLIED" and srcName == player then
		if spellName == "Polymorph" then
			success, targetID = true, dstGUID
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 50, "Interface\\Icons\\Spell_Nature_Polymorph")

		elseif spellName == "Shackle Undead" then
			success, targetID = true, dstGUID
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 50, "Interface\\Icons\\Spell_Nature_Slow")

		elseif spellName == "Banish" then -- why does Banish have a shorter duration than the others? =/
			success, targetID = true, dstGUID
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 30, "Interface\\Icons\\Spell_Shadow_Cripple")
		end
	end

	if event == "SPELL_AURA_REFRESH" and success then
		if spellName == "Polymorph" then
			self:TriggerEvent("BigWigs_StopBar", self, spellName.." on "..dstName)
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 50, "Interface\\Icons\\Spell_Nature_Polymorph")

		elseif spellName == "Shackle Undead" then
			self:TriggerEvent("BigWigs_StopBar", self, spellName.." on "..dstName)
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 50, "Interface\\Icons\\Spell_Nature_Slow")

		elseif spellName == "Banish" then -- why does Banish have a shorter duration than the others? =/
			self:TriggerEvent("BigWigs_StopBar", self, spellName.." on "..dstName)
			self:TriggerEvent("BigWigs_StartBar", self, spellName.." on "..dstName, 30, "Interface\\Icons\\Spell_Shadow_Cripple")
		end
	end

	if event == "SPELL_AURA_REMOVED" and success then
		if targetID == dstGUID then -- make sure it's the one YOU sheeped/shackled/banished
			success, targetID = false, nil
			self:TriggerEvent("BigWigs_Message", spellName.." on "..dstName.." was removed!", "Personal")
			self:TriggerEvent("BigWigs_StopBar", self, spellName.." on "..dstName)
		end
	end
end

