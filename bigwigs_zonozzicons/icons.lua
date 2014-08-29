local mod = BigWigs:NewBoss("Warlord Zon'ozz Icons", 824)
if not mod then return end
mod:RegisterEnableMob(55308)

local current = 0

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Shadows", 103434)
	self:Log("SPELL_AURA_REMOVED", "Safe", 103434)
	self:Death("Disable", 55308)
end

function mod:Shadows(args)
	current = current + 1
	SetRaidTarget(args.destName, current)

	local max = 3
	if current == max then current = 0 end
end

function mod:Safe(args)
	SetRaidTarget(args.destName, 0)
end
