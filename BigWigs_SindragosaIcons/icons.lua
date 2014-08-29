local mod = BigWigs:NewBoss("Sindragosa Icons", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36853)

local current = 0

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Beacon", 70126)
	self:Log("SPELL_AURA_REMOVED", "Safe", 70126)
	self:Death("Disable", 36853)
end

function mod:Beacon(player)
	current = current + 1
	SetRaidTarget(player, current)

	local d = GetInstanceDifficulty()
	local max = (d == 1 or d == 3) and 2 or 5
	if current == max then current = 0 end
end

function mod:Safe(player)
	SetRaidTarget(player, 0)
end

