local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "race/wovenhome-orc", name = _t("wovenhome orc", "talent type"), generic = true, description = _t"The various racial bonuses a character can have." }
-- Cut description (to match with all other ToME descriptions): The Wovenhome orcs may not have a true pride anymore, but only a fool would say they are no longer orcs.
racial_req1 = {
	level = function(level) return 0 + (level-1)  end,
}
racial_req2 = {
	level = function(level) return 8 + (level-1)  end,
}
racial_req3 = {
	level = function(level) return 16 + (level-1)  end,
}
racial_req4 = {
	level = function(level) return 24 + (level-1)  end,
}

-- The first two are very much variants on ToME's orc racials, the third is completely different, the fourth is extremely-loosely based on Skirmisher.

newTalent{ -- Based partially on ORC_FURY, shares some code.
	name = "Peaceful Rage",
	short_name = "KAM_WOVENHOME_ORC_RAGE",
	type = {"race/wovenhome-orc", 1},
	require = racial_req1,
	points = 5,
	image = "talents/kam_spellweaver_peace_rage.png",
	tactical = { ATTACK = function(self, t, aitarget)
			local nb = self.turn_procs[t.id] and self.turn_procs[t.id].count or t.enemyCount(self, t)
			return nb^.5
		end
	},
--	image = "talents/channel_staff.png",
	require = racial_req1,
	no_energy = true,
	target = function(self, t) return {type="hit", range = 10} end,
	direct_hit = true,
	requires_target = true,
	cooldown = function(self, t) return math.ceil(self:combatTalentLimit(t, 8, 45, 25, false, 1.0)) end,
	getPower = function(self, t) return self:combatStatScale("wil", 2, 7) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "wovenhome_orc_damage_reduce", .2)
	end,
	enemyCount = function(self, t) -- Count actors in LOS and seen
		local nb = 0
		for i = 1, #self.fov.actors_dist do
			local act = self.fov.actors_dist[i]
			if act and self:reactionToward(act) < 0 and self:canSee(act) then nb = nb + 1 end
			if nb >= 6 then break end
		end
		self.turn_procs[t.id] = {count = nb}
		return nb
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		
		local nb = self.turn_procs[t.id] and self.turn_procs[t.id].count or t.enemyCount(self, t)
		if nb <= 0 then return false end
		
		if self:reactionToward(target) > 0 then return false end
		
		self:setEffect(self.EFF_KAM_WOVENHOME_ORC_PEACE_FURY_USER, 5, {power=10 + t.getPower(self, t) * math.min(5, nb), target = target })
		
		game.logSeen(self, "%s focuses their rage.", self:getName():capitalize())
		
		self:project({type="ball", range=0, radius=5}, self.x, self.y, function(px, py) -- Fun bonus effect for Summoning classes. May be irritating to use in practice.
			local summon = game.level.map(px, py, Map.ACTOR)
			if not summon then return end
			if summon.summoner == self then
				summon:setEffect(summon.EFF_KAM_WOVENHOME_ORC_PEACE_FURY_USER, 5, {power=10 + t.getPower(self, t) * math.min(5, nb), target = target })
				summon:setTarget(target)
			end	
		end)
		
		return true
	end,
	info = function(self, t)
		return ([[The Spellweavers are known for their dislike of war and violence. Coming from the orcs, who have never really been free of war, it's been a bit of an adjustment.
		You can channel your anger against a single target within range 10, increasing your damage to that target by 10%% + %0.1f%% per enemy you can see (up to 5 enemies, granting a %0.1f%% bonus), but at the same time, remain calm and channel that peace, preventing all damage you would do to any other target, including yourself. These effects cannot be canceled and last 5 turns or until the selected target dies.
		This also affects any summons within range 5, granting them the same effects and causing them to focus on the target.
		The damage bonus increases with your Willpower.
		Additionally, as a passive benefit, reduce all damage you and any of your summons would do to friendly targets by 20%% (stacking additively with other effects in this tree).]]):
		tformat(t.getPower(self, t), t.getPower(self, t) * 5 + 10)
	end,
}

newTalent{ -- Based on Hold the Ground, shares some code.
	name = "New Home Ground",
	short_name = "KAM_WOVENHOME_ORC_GROUND",
	type = {"race/wovenhome-orc", 2},
	require = racial_req2,
	image = "talents/kam_spellweaver_new_home_ground.png",
	points = 5,
	cooldown = function(self, t) return 12 end,
	mode = "passive",
	getSaves = function(self, t) return self:combatTalentScale(t, 4, 16, 0.75) end,
	getDebuff = function(self, t) return math.ceil(self:combatTalentStatDamage(t, "wil", 1, 5)) end,
	passives = function(self, t, p)
		local saves = t.getSaves(self, t)
		self:talentTemporaryValue(p, "combat_physresist", saves)
		self:talentTemporaryValue(p, "combat_spellresist", saves)
		self:talentTemporaryValue(p, "combat_mentalresist", saves)
		self:talentTemporaryValue(p, "wovenhome_orc_damage_reduce", .2)
	end,
	callbackOnTakeDamage = function(self, t, src, x, y, type, dam, state)
		if self:isTalentCoolingDown(t) then return end
		if not ( (self.life - dam) < (self.max_life * 0.5) ) then return end
		
		local nb = self:removeEffectsFilter(self, {status = "detrimental", type = "magical"}, t.getDebuff(self, t))
		if nb > 0 then
			game.logSeen(self, "#YELLOW#%s focuses, cleansing %d magical debuffs and improving their saves!", self:getName():capitalize(), nb)
			self:setEffect(self.EFF_KAM_WOVENHOME_ORC_HOLD_GROUND, 4, {power = t.getSaves(self, t) * 2.5})
			self:startTalentCooldown(t)
		end
	end,
	info = function(self, t)
		return ([[The orcs have always been engaged in war, often because others chose to hurt them. Now, with new allies worth protecting, the Wovenhome orcs have a stronger drive to persevere than ever.
		When your life goes below 50%%, your resolve empowers you to use Spellweaver techniques, cleansing yourself of %d magic debuff(s) based on talent level and Willpower and, if any are cleansed, increasing all of your saves by %d for 4 turns. This can only happen once every %d turns.
		Additionally, all of your saves are increased by %d and all damage you and any of your summons would do to friendly targets by 20%% (stacking additively with other effects in this tree).]]):
		tformat(t.getDebuff(self, t), t.getSaves(self, t) * 2.5, self:getTalentCooldown(t), t.getSaves(self, t))
	end,
}

-- Uses hook in load, with code taken from Innovation.
newTalent{ -- This talent basically makes you better with runes, charms, and gear, but not by much. May not actually do enough to hit breakpoints in practice. Needs use-testing.
	name = "Survivalist",
	short_name = "KAM_WOVENHOME_ORC_SURVIVALIST",
	type = {"race/wovenhome-orc", 3},
	require = racial_req3,
	image = "talents/kam_spellweaver_survivalist.png",
	points = 5,
	mode = "passive",

	gearBoost = function(self, t) return self:combatTalentScale(t, 4, 12) end, -- Based on Innovation, but smaller.
	charmReduction = function(self, t) return self:combatTalentLimit(t, 50, 5, 15, false, 1.0) end, -- Based on Device Mastery, but smaller.
	runeReduction = function(self, t) return self:combatTalentScale(t, 5, 15) end, -- Original.

	on_learn = function(self, t)
		self:inventoryApplyAll(function(inven, item, o)
			if inven.worn then
				self:onTakeoff(o, inven.id, true)
				self:onWear(o, inven.id, true)
			end
		end)
	end,
	on_unlearn = function(self, t)
		self:inventoryApplyAll(function(inven, item, o)
			if inven.worn then
				self:onTakeoff(o, inven.id, true)
				self:onWear(o, inven.id, true)
			end
		end)
	end,
	
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "use_object_cooldown_reduce", t.charmReduction(self, t))
		self:talentTemporaryValue(p, "wovenhome_orc_damage_reduce", .2)
	end,
	callbackOnTakeoff = function(self, t, obj)
		if (obj.__kam_wovenhome_survivalist_adds) then
			obj:tableTemporaryValuesRemove(obj.__kam_wovenhome_survivalist_adds)
		end
	end,
	info = function(self, t)
		return ([[Between training with the various Orcish Prides, evading Orcish patrols when they escaped into the wilderness, and training with Grath, the Wovenhome orcs have learned to survive anything the world might throw at them with any resources available.
		All stats, saves, armour, and defense bonuses on your equipment are increased by %d%%.
		The cooldowns and power costs of all usable charms (wands, totems, and torques) are reduced by %d%% (stacking additively with Device Mastery).
		The cooldowns of your inscriptions are reduced by %d%%.
		Additionally, all damage you and any of your summons would do to friendly targets by 20%% (stacking additively with other effects in this tree).]]):
		tformat(t.gearBoost(self, t), t.charmReduction(self, t), t.runeReduction(self, t))
	end,
}

newTalent{ -- Very loosely based on Skirmisher, shares no real code.
	name = "New Pride",
	short_name = "KAM_WOVENHOME_ORC_NEW_PRIDE",
	type = {"race/wovenhome-orc", 4},
	require = racial_req4,
	image = "talents/kam_spellweaver_new_pride.png",
	points = 5,
	mode = "passive",
	getDamageReduction = function(self, t) 
		return 100 - self:combatTalentStatDamage(t, "wil", 3, 7)
	end,
	getThreshold = function(self, t) -- The idea is that this effect is very weak, but it stacks very quickly until it immediately falls off.
		return 5
	end,
	getMaxDamage = function(self, t) -- Much weaker than the ghoulish version, since that's ghoul's Special Thing so I gave this talent something else to do.
		return self:combatTalentLimit(self:getTalentLevel(t), 60, 95, 70, false, 1.0)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "flat_damage_cap", {all=t.getMaxDamage(self, t)})
		self:talentTemporaryValue(p, "wovenhome_orc_damage_reduce", .2)
	end,
	callbackOnTakeDamage = function(self, t, src, _, _, _, dam)
		if src ~= self and dam >= self.max_life * (t.getThreshold(self, t) / 100) then -- Don't trigger if source == self because I'm sure there's some stupid shenanigans you could do and that makes it harder.
			self:setEffect(self.EFF_KAM_WOVENHOME_ORC_NEW_PRIDE, 2, {power = t.getDamageReduction(self, t)})
		end
	end,
	info = function(self, t)
		return ([[The Wovenhome orcs had to abandon their Prides, but through the leadership of Grath, and after surviving through so much and finding a new home, they still have something to have pride in. You take pride in the Wovenhome orcs and they take pride in you; you shall not fail here.
		Whenever you take more than %d%% of your life in a single hit, reduce all damage by a flat %0.1f%% for 2 turns. This damage reduction stacks multiplicatively.
		The resistance will scale with talent level and your Willpower.
		Additionally, you cannot take more than %d%% of your life in a single hit, and all damage you would do to your allies is reduced by 20%% (stacking additively with other effects in this tree).]]):
		tformat(t.getThreshold(self, t), 100 - t.getDamageReduction(self, t), t.getMaxDamage(self, t))
	end,
}

