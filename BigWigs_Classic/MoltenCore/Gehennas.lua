--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Gehennas", 696)
if not mod then return end
mod:RegisterEnableMob(12259)
mod.toggleOptions = {19716, {19717, "FLASH"}, "bosskill"}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Curse", 19716)
	self:Log("SPELL_AURA_APPLIED", "Fire", 19717)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Death("Win", 12259)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Curse(args)
	self:Bar(args.spellId, 30)
	self:Message(args.spellId, "Urgent")
	self:DelayedMessage(args.spellId, 25, "Attention", CL.custom_sec:format(args.spellName, 5))
end

function mod:Fire(args)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Message(args.spellId, "Personal", "Alarm", CL.you:format(args.spellName))
	end
end

