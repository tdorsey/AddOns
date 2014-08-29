local mod = BigWigs:NewBoss("Anub'arak Heal Assist", "Trial of the Crusader")
if not mod then return end
mod:RegisterEnableMob(34564)

local max = nil
local current = 0

function mod:OnBossEnable()
	local d = GetInstanceDifficulty()
	max = (d == 1 or d == 3) and 2 or 5

	self:Log("SPELL_AURA_APPLIED", "Penetrated", 66013, 67700, 68509, 68510)
	self:Log("SPELL_AURA_REMOVED", "Safe", 66013, 67700, 68509, 68510)
	self:Death("Disable", 34564)
end

function mod:Penetrated(player)
	current = current + 1
	SetRaidTarget(player, current)
	if current == max then current = 0 end
end

function mod:Safe(player)
	SetRaidTarget(player, 0)
end

