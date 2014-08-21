local mod	= DBM:NewMod(709, "DBM-TerraceofEndlessSpring", nil, 320)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 11365 $"):sub(12, -3))
mod:SetCreatureID(60999)--61042 Cheng Kang, 61046 Jinlun Kun, 61038 Yang Guoshi, 61034 Terror Spawn
mod:SetEncounterID(1431)
mod:SetUsedIcons(8, 7, 6, 5, 4)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 119414 129147 120047 119888 118977 131996 132007 120669 120519 120629 120268",
	"SPELL_AURA_REMOVED 129147 120047 118977 120629",
	"SPELL_CAST_START 119593 119692 119693 119862 119888 120672 120455 120519",
	"SPELL_CAST_SUCCESS 120047 119983",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

-- Normal and heroic Phase 1
mod:AddBoolOption("warnThrash", mod:IsTank() or mod:IsHealer(), "announce")
local warnThrashNormal					= mod:NewSpellAnnounce(131996, 3, nil, true, false)
local warnThrashHeroic					= mod:NewCountAnnounce(131996, 3, nil, true, false)
local warnBreathOfFearSoon				= mod:NewPreWarnAnnounce(119414, 10, 3)
local warnBreathOfFear					= mod:NewSpellAnnounce(119414, 4)
mod:AddBoolOption("warnBreathOnPlatform", false, "announce")
local warnOminousCackle					= mod:NewTargetAnnounce(129147, 3)--129147 is debuff, 119693 is cast. We do not reg warn cast cause we reg warn the actual targets instead. We special warn cast to give a little advanced heads up though.
local warnDreadSpray					= mod:NewSpellAnnounce(120047, 2)
-- Heroic Phase 2
local warnPhase2						= mod:NewPhaseAnnounce(2)
local warnDreadThrash					= mod:NewSpellAnnounce(132007, 4, nil, mod:IsTank() or mod:IsHealer())
local warnNakedAndAfraid				= mod:NewTargetAnnounce(120669, 2, nil, mod:IsTank())
local warnWaterspout					= mod:NewTargetCountAnnounce(120519, 3)
local warnHuddleInTerror				= mod:NewTargetCountAnnounce(120629, 3)
local warnImplacableStrike				= mod:NewCountAnnounce(120672, 4)
local warnChampionOfTheLight			= mod:NewTargetAnnounce(120268, 3, nil, false)--seems spammy.
local warnSubmerge						= mod:NewCountAnnounce(120455)
local warnDreadSpawns					= mod:NewCountAnnounce(132018)
--local warnEmerge						= mod:NewSpellAnnounce(120458)--do not match he actually emerges.

-- Normal and heroic Phase 1
local specWarnBreathOfFearSoon			= mod:NewSpecialWarning("specWarnBreathOfFearSoon")
local specWarnThrash					= mod:NewSpecialWarningSpell(131996, mod:IsTank())
local specWarnOminousCackleYou			= mod:NewSpecialWarningYou(129147)--You have debuff, just warns you.
local specWarnDreadSpray				= mod:NewSpecialWarningSpell(120047, nil, nil, nil, 2)--Platform ability, particularly nasty damage, and fear.
local specWarnDeathBlossom				= mod:NewSpecialWarningSpell(119888, nil, nil, nil, 2)--Cast, warns the entire raid.
mod:AddBoolOption("specWarnMovement", false, "announce")--http://mysticalos.com/terraceofendlesssprings.jpg
local MoveWarningForward				= mod:NewSpecialWarning("MoveForward", nil, false)--Warning to switch sites on platform
local MoveWarningRight					= mod:NewSpecialWarning("MoveRight", nil, false)--Warning to move one eighth to the right
local MoveWarningBack					= mod:NewSpecialWarning("MoveBack", nil, false)--Move back to starting position
-- Heroic Phase 2
local specWarnDreadThrash				= mod:NewSpecialWarningSpell(132007, mod:IsTank(), nil, nil, 3)--Extra emphesis special warning.
local specWarnNakedAndAfraidOther		= mod:NewSpecialWarningTaunt(120669)
local specWarnWaterspoutCast			= mod:NewSpecialWarningSpell(120519, nil, nil, nil, 2)
local specWarnWaterspout				= mod:NewSpecialWarningYou(120519)
local specWarnWaterspoutNear			= mod:NewSpecialWarningClose(120519)
local yellWaterspout					= mod:NewYell(120519)
local specWarnImplacableStrike			= mod:NewSpecialWarningSpell(120672)
local specWarnChampionOfTheLight		= mod:NewSpecialWarningYou(120268)
local specWarnSubmerge					= mod:NewSpecialWarningSpell(120455, nil, nil, nil, 2)

-- Normal and heroic Phase 1
local timerThrashCD						= mod:NewCDTimer(9, 131996, nil, mod:IsTank() or mod:IsHealer())--Every 9-12 seconds.
local timerBreathOfFearCD				= mod:NewNextTimer(33.3, 119414)--Based off bosses energy, he casts at 100 energy, and gains about 3 energy per second, so every 33-34 seconds is a breath.
local timerOminousCackleCD				= mod:NewNextTimer(45.5, 119693)
local timerDreadSpray					= mod:NewBuffActiveTimer(8, 120047)
local timerDreadSprayCD					= mod:NewNextTimer(20.5, 120047)
local timerDeathBlossom					= mod:NewBuffActiveTimer(5, 119888)
--local timerTerrorSpawnCD				= mod:NewNextTimer(60, 119108)--every 60 or so seconds, maybe a little more maybe a little less, not sure. this is just based on instinct after seeing where 30 fit.
local timerFearless						= mod:NewBuffFadesTimer(30, 118977)
-- Heroic Phase 2
local timerDreadTrashCD					= mod:NewCDTimer(9, 132007, nil, mod:IsTank() or mod:IsHealer())--Share Trash CD.
local timerNakedAndAfraid				= mod:NewTargetTimer(25, 120669, nil, mod:IsTank() or mod:IsHealer())--25 on 10 man, 50 on 25 (requiring 3 tanks)
local timerNakedAndAfraidCD				= mod:NewCDTimer(30, 120669, nil, mod:IsTank() or mod:IsHealer())-- varies, but mostly 30. can get delayed upwards of 15 seconds though between submerge and specials
local timerSubmergeCD					= mod:NewCDCountTimer(51.5, 120455)
mod:AddBoolOption("timerSpecialAbility", true, "timer")--Better to have one option for his shared special timer than 7
local timerWaterspoutCD					= mod:NewCDTimer(10, 120519, nil, nil, false)
local timerHuddleInTerrorCD				= mod:NewCDTimer(10, 120629, nil, nil, false)
local timerImplacableStrikeCD			= mod:NewCDTimer(9.5, 120672, nil, nil, false)
local timerSpecialAbilityCD				= mod:NewTimer(12, "timerSpecialAbilityCD", 1449, nil, false)--1st Ability 12sec after Submerge
local timerSpoHudCD						= mod:NewTimer(10, "timerSpoHudCD", 64044, nil, false)--Waterspout or Huddle in Terror next
local timerSpoStrCD						= mod:NewTimer(10, "timerSpoStrCD", 1953, nil, false)--Waterspout or Implacable Strike next
local timerHudStrCD						= mod:NewTimer(10, "timerHudStrCD", 64044, nil, false)-- Huddle in Terror or Implacable Strike next

local berserkTimer						= mod:NewBerserkTimer(900)

local countdownBreathOfFear				= mod:NewCountdown(33.3, 119414, nil, nil, 10)

mod:AddBoolOption("RangeFrame")--For Eerie Skull (2 yards) and Unstable Bolt (3 yards)
mod:AddBoolOption("SetIconOnHuddle")

local wallLight = GetSpellInfo(117964)
local fearless = GetSpellInfo(118977)
local waterspout = GetSpellInfo(120519)
local huddleinterror = GetSpellInfo(120629)
local ominousCackleTargets = {}
local platformGUIDs = {}
local waterspoutTargets = {}
local huddleInTerrorTargets = {}
local huddleInTerrorIcons = {}
local platformSent = false
local onPlatform = false--Used to determine when YOU are sent to a platform, so we know to activate MobID on next shoot
local phase2 = false
local dreadSprayCounter = 0
local thrashCount = 0
local submergeCount = 0
local specialCount = 0
local huddleIcon = 8
local MobID = 0
local specialsCast = 000--Huddle(100), Spout(10), Strike(1)

local Spawns = {
	[1] = 1,
	[2] = 2,
	[3] = 2,
	[4] = 3,
	[5] = 3,
	[6] = 4,
	[7] = 4,
	[8] = 5,
	[9] = 5,
	[10]= 6,
	[11]= 6,
	[12]= 7,
	[13]= 7,
	[14]= 8,
	[15]= 8,
	[16]= 9,
	[17]= 9,
	[18]= 10,
	[19]= 10,
	[20]= 11,
}

local function warnOminousCackleTargets()
	warnOminousCackle:Show(table.concat(ominousCackleTargets, "<, >"))
	table.wipe(ominousCackleTargets)
end

local function warnWaterspoutTargets()
	warnWaterspout:Show(specialCount, table.concat(waterspoutTargets, "<, >"))
	table.wipe(waterspoutTargets)
end

local function warnHuddleInTerrorTargets()
	warnHuddleInTerror:Show(specialCount, table.concat(huddleInTerrorTargets, "<, >"))
	table.wipe(huddleInTerrorTargets)
	huddleIcon = 8
end

local function startSpecialTimers()
	if not mod.Options.timerSpecialAbility then return end
	--Huddle(100), Spout(10), Strike(1)
	if specialsCast == 110 then
		timerImplacableStrikeCD:Start()
	end
	if specialsCast == 101 then
		timerWaterspoutCD:Start()
	end
	if specialsCast == 100 then
		timerSpoStrCD:Start()
	end
	if specialsCast == 010 then--Huddle is NEVER cast 3rd.
		timerHuddleInTerrorCD:Start()
	end
	if specialsCast == 001 then
		timerHuddleInTerrorCD:Start()
	end
end

function mod:CheckWall()
	local fearlessTime = timerFearless:GetTime()
	if not onPlatform and not UnitBuff("player", wallLight) and (fearlessTime == 0 or fearlessTime > 21.5) and not UnitIsDeadOrGhost("player") then
		specWarnBreathOfFearSoon:Show()
	end
end

function mod:CheckPlatformLeaved()--Check you are leaved platform by Wall of Light buff. Failsafe for some siturations./
	if UnitBuff("player", wallLight) then
		self:UnscheduleMethod("CheckPlatformLeaved")
		self:LeavePlatform()
	else
		self:ScheduleMethod(3, "CheckPlatformLeaved")
	end
end

function mod:LeavePlatform()
	if not self:IsInCombat() then return end--Because sometimes this still gets scheduled on combat end
	if onPlatform then
		if DBM.BossHealth:IsShown() then
			DBM.BossHealth:RemoveBoss(61038)
			DBM.BossHealth:RemoveBoss(61042)
			DBM.BossHealth:RemoveBoss(61046)
		end
		table.wipe(platformGUIDs)
		platformSent = false
		onPlatform = false
		MobID = nil
		--Breath of fear timer recovery
		if not self.Options.warnBreathOnPlatform then
			local fearlessApplied = UnitBuff("player", fearless)
			local shaPower = UnitPower("boss1") --Get Boss Power
			shaPower = shaPower / 3 --Divide it by 3 (cause he gains 3 power per second and we need to know how many seconds to subtrack from fear CD)
			if (not fearlessApplied and shaPower < 30.3) or (fearlessApplied and shaPower < 5) then--If you have no fearless and breath timer less then 3s, you may not reach to wall. So ignore below 3 sec. Also if you have fearless and breath timer less then 28.3s, not need to warn breath.
				timerBreathOfFearCD:Start(33.3-shaPower)
				countdownBreathOfFear:Start(33.3-shaPower)
				if shaPower < 26.3 then
					self:ScheduleMethod(26.3-shaPower, "CheckWall")
				elseif not fearlessApplied then
					specWarnBreathOfFearSoon:Show()
				end
			end
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(3)
		end
	end
end

function mod:OnCombatStart(delay)
	if self:IsDifficulty("normal10", "heroic10", "lfr25") then
		timerOminousCackleCD:Start(40-delay)
	else
		timerOminousCackleCD:Start(25.5-delay)
	end
	warnBreathOfFearSoon:Schedule(23.3-delay)
	timerBreathOfFearCD:Start(-delay)
	self:ScheduleMethod(26.3-delay, "CheckWall")
	countdownBreathOfFear:Start(33.3-delay)
	platformSent = false
	onPlatform = false
	phase2 = false
	dreadSprayCounter = 0
	thrashCount = 0
	submergeCount = 0
	huddleIcon = 8
	MobID = nil
	specialsCast = 000
	table.wipe(ominousCackleTargets)
	table.wipe(platformGUIDs)
	table.wipe(waterspoutTargets)
	table.wipe(huddleInTerrorTargets)
	table.wipe(huddleInTerrorIcons)
	berserkTimer:Start(-delay)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(3)
	end
end

local function ClearHuddleTargets()
	table.wipe(huddleInTerrorIcons)
end

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(DBM:GetUnitFullName(v1)) < DBM:GetRaidSubgroup(DBM:GetUnitFullName(v2))
	end
	function mod:SetHuddleIcons()
		table.sort(huddleInTerrorIcons, sort_by_group)
		local huddleIcon = 8
		for i, v in ipairs(huddleInTerrorIcons) do
			-- DBM:SetIcon() is used because of follow reasons
			--1. It checks to make sure you're on latest dbm version, if you are not, it disables icon setting so you don't screw up icons (ie example, a newer version of mod does icons differently)
			--2. It checks global dbm option "DontSetIcons"
			self:SetIcon(v, huddleIcon)
			huddleIcon = huddleIcon - 1
		end
		self:Schedule(1.5, ClearHuddleTargets)--Table wipe delay so if icons go out too early do to low fps or bad latency, when they get new target on table, resort and reapplying should auto correct teh icon within .2-.4 seconds at most.
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 119414 and self:AntiSpam(5, 1) and not phase2 then--using this with antispam is still better then registering SPELL_CAST_SUCCESS for a single event when we don't have to. Less cpu cause mod won't have to check every SPELL_CAST_SUCCESS event.
		warnBreathOfFear:Show()
		if not platformSent or self.Options.warnBreathOnPlatform then--not in middle, not your problem
			timerBreathOfFearCD:Start()
			countdownBreathOfFear:Start(33.3)
			self:ScheduleMethod(26.3, "CheckWall")--check before 7s, 5s is too late.
		end
		warnBreathOfFearSoon:Schedule(23.3)
	elseif spellId == 129147 then
		ominousCackleTargets[#ominousCackleTargets + 1] = args.destName
		if args:IsPlayer() then
			platformSent = true
			timerThrashCD:Cancel()
			specWarnOminousCackleYou:Show()
			if not self.Options.warnBreathOnPlatform then
				countdownBreathOfFear:Cancel()
				timerBreathOfFearCD:Cancel()
				self:UnscheduleMethod("CheckPlatformLeaved")
				self:UnscheduleMethod("CheckWall")
			end
			if self.Options.RangeFrame then
				DBM.RangeCheck:Hide()
			end
		end
		self:Unschedule(warnOminousCackleTargets)
		self:Schedule(2, warnOminousCackleTargets)--this actually staggers a bit, so wait the full 2 seconds to get em all in one table
	elseif spellId == 120047 and MobID and MobID == args:GetSrcCreatureID() then--might change
		warnDreadSpray:Show()
		specWarnDreadSpray:Show()
		timerDreadSpray:Start(args.sourceGUID)
		timerDreadSprayCD:Start(args.sourceGUID)
	elseif spellId == 119888 and MobID and MobID == args:GetSrcCreatureID() then
		timerDeathBlossom:Show()
	elseif spellId == 118977 and args:IsPlayer() then--Fearless, you're leaving platform 
		timerFearless:Start()
		self:UnscheduleMethod("CheckPlatformLeaved")
		self:LeavePlatform()
	elseif spellId == 131996 and not platformSent then
		specWarnThrash:Show()
		if phase2 then
			thrashCount = thrashCount + 1
			if self.Options.warnThrash then
				warnThrashHeroic:Show(thrashCount)
			end
			if thrashCount == 3 then
				timerDreadTrashCD:Start()
			else
				timerThrashCD:Start()
			end
		else
			if self.Options.warnThrash then
				warnThrashNormal:Show()
			end
			timerThrashCD:Start()
		end
	elseif spellId == 132007 then
		thrashCount = 0
		warnDreadThrash:Show()
		specWarnDreadThrash:Show()
		timerThrashCD:Start()
	elseif spellId == 120669 then
		warnNakedAndAfraid:Show(args.destName)
		specWarnNakedAndAfraidOther:Show(args.destName)
		timerNakedAndAfraidCD:Start()
		if self:IsDifficulty("heroic25") then
			timerNakedAndAfraid:Start(50, args.destName)
		else
			timerNakedAndAfraid:Start(args.destName)
		end
	elseif spellId == 120519 then--Waterspout
		waterspoutTargets[#waterspoutTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnWaterspout:Show()
			yellWaterspout:Yell()
		else
			local uId = DBM:GetRaidUnitId(args.destName)
			if uId then
				local inRange = CheckInteractDistance(uId, 2)
				if inRange then
					specWarnWaterspoutNear:Show(args.destName)
				end
			end
		end
		if self:AntiSpam(5, 3) then
			if specialCount == 3 then specialCount = 0 end
			specialCount = specialCount + 1
			specialsCast = specialsCast + 10--Huddle (100), Spout(10), Strike(1)
		end
		self:Unschedule(warnWaterspoutTargets)
		self:Schedule(0.3, warnWaterspoutTargets)
		startSpecialTimers()
	elseif spellId == 120629 then-- Huddle In Terror
		huddleInTerrorTargets[#huddleInTerrorTargets + 1] = args.destName
		if self.Options.SetIconOnHuddle then
			table.insert(huddleInTerrorIcons, DBM:GetRaidUnitId(DBM:GetFullPlayerNameByGUID(args.destGUID)))
			self:UnscheduleMethod("SetHuddleIcons")
			if self:LatencyCheck() then--lag can fail the icons so we check it before allowing.
				if #huddleInTerrorIcons >= 5 and self:IsDifficulty("heroic25") or #huddleInTerrorIcons >= 3 and self:IsDifficulty("heroic10") then
					self:SetHuddleIcons()
				else
					self:ScheduleMethod(0.5, "SetHuddleIcons")
				end
			end
		end
		if self:AntiSpam(5, 3) then
			if specialCount == 3 then specialCount = 0 end
			specialCount = specialCount + 1
			specialsCast = specialsCast + 100--Huddle (100), Spout(10), Strike(1)
		end
		self:Unschedule(warnHuddleInTerrorTargets)
		self:Schedule(0.5, warnHuddleInTerrorTargets)
		startSpecialTimers()
	elseif spellId == 120268 then -- Champion Of The Light
		warnChampionOfTheLight:Show(args.destName)
		if args:IsPlayer() then
			specWarnChampionOfTheLight:Show()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 129147 and args:IsPlayer() then -- Move onPlatform check when Ominous Cackle debuff removes (actually reachs platform). Because on 25 man, you can see other platform warning and timer while flying to platform. (not actually reachs platform). This causes health frame error and etc error. 
		onPlatform = true
	elseif spellId == 120047 then
		timerDreadSpray:Cancel(args.sourceGUID)
		dreadSprayCounter = 0
	elseif spellId == 118977 and args:IsPlayer() then
		timerFearless:Cancel()
	elseif spellId == 120629 and self.Options.SetIconOnHuddle then
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if args:IsSpellID(119593, 119692, 119693) then--This seems to have multiple spellids, depending on which platform he's going to send you to. TODO, figure out which is which platform and add additional warnings
		if self:IsDifficulty("normal10", "heroic10", "lfr25") then
			timerOminousCackleCD:Start(90.5)--Far less often on LFR
		else
			timerOminousCackleCD:Start()
		end
	elseif spellId == 119862 and onPlatform and not platformGUIDs[args.sourceGUID] then--Best way to track engaging one of the side adds, they cast this instantly.
		platformGUIDs[args.sourceGUID] = true
		MobID = self:GetCIDFromGUID(args.sourceGUID)
		timerDreadSprayCD:Start(10.5, args.sourceGUID)--We can accurately start perfectly accurate spray cd bar off their first shoot cast.
		if DBM.BossHealth:IsShown() then
			DBM.BossHealth:AddBoss(MobID, args.sourceName)
		end
	elseif spellId == 119888 and MobID and MobID == args:GetSrcCreatureID() then
		specWarnDeathBlossom:Show()
		self:ScheduleMethod(40, "CheckPlatformLeaved")--you may leave platform soon after Death Blossom casted. failsafe for UNIT_DIED not fire, and fearless fails.
	elseif spellId == 120672 then -- Implacable Strike
		if specialCount == 3 then specialCount = 0 end
		specialCount = specialCount + 1
		specialsCast = specialsCast + 1--Huddle (100), Spout(10), Strike(1)
		warnImplacableStrike:Show(specialCount)
		specWarnImplacableStrike:Show()
		startSpecialTimers()
	elseif spellId == 120455 then
		submergeCount = submergeCount + 1
		warnSubmerge:Show(submergeCount)
		warnDreadSpawns:Schedule(5, Spawns[submergeCount])
		specWarnSubmerge:Show()
		timerSubmergeCD:Start(nil, submergeCount+1)
		specialsCast = 000
		if self.Options.timerSpecialAbility then
			timerSpecialAbilityCD:Start()
		end
	elseif spellId == 120519 then--Waterspout
		specWarnWaterspoutCast:Show()
	--elseif spellId == 120458 then
		--warnEmerge:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)--Handling Dread Sprays
	local spellId = args.spellId
	if spellId == 120047 and onPlatform then
		dreadSprayCounter = 0
	elseif spellId == 119983 and onPlatform then
		if not self.Options.specWarnMovement then return end
		dreadSprayCounter = dreadSprayCounter+1
		if MobID == 61046 then
			if dreadSprayCounter == 6 then
				MoveWarningForward:Show()
			end
		end	
		if MobID == 61042 then
			if dreadSprayCounter == 6 then
				MoveWarningForward:Show()
			end
		end	
		if MobID == 61038 then
			if dreadSprayCounter == 3 then
				MoveWarningRight:Show()
			end
		end
		if dreadSprayCounter == 16 then
			MoveWarningBack:Show()
		end
	end
end

function mod:UNIT_DIED(args)
	-- sometimes UNIT_DIED not fires for Platform mobs. bliz bug.
	if platformGUIDs[args.destGUID] then
		timerDreadSpray:Cancel(args.destGUID)
		timerDreadSprayCD:Cancel(args.destGUID)
		-- Failsafe for Fearless is not applyed to you.
		self:UnscheduleMethod("CheckPlatformLeaved")
		self:ScheduleMethod(7, "CheckPlatformLeaved")
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, _, spellId)
	if spellId == 114936 and self:AntiSpam(10, 2) then--Heroic Phase 2
		phase2 = true
		platformSent = false
		onPlatform = false
		submergeCount = 0
		thrashCount = 0
		specialCount = 0
		timerThrashCD:Cancel()
		timerBreathOfFearCD:Cancel()
		countdownBreathOfFear:Cancel()
		timerOminousCackleCD:Cancel()
		timerDreadSpray:Cancel()
		timerDreadSprayCD:Cancel()
		berserkTimer:Cancel() -- berserk timer seems restarts on heroic phase 2.
		warnBreathOfFearSoon:Cancel()
		self:UnscheduleMethod("CheckWall")
		self:UnscheduleMethod("CheckPlatformLeaved")
		warnPhase2:Show()
		--timerSubmergeCD:Start(nil, 1) -- not known
		berserkTimer:Start() -- currently, seems phase 2 berserk also 15 min.
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
		if DBM.BossHealth:IsShown() then
			DBM.BossHealth:RemoveBoss(61038)
			DBM.BossHealth:RemoveBoss(61042)
			DBM.BossHealth:RemoveBoss(61046)
		end
	end
end
