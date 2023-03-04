local Map = require "engine.Map"
local Chat = require "engine.Chat"
local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ generic = true, type = "spellweaving/shieldweaving", no_silence = true, is_spell = true, name = _t("shieldweaving", "talent type"), description = _t"The art of weaving magical shields." }
spells_req1 = {
	stat = { mag=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
spells_req2 = {
	stat = { mag=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
spells_req3 = {
	stat = { mag=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
spells_req4 = {
	stat = { mag=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

-- The basic shields tree. 
-- Note: Restructured to give Core the two modes, moving Area from Theory and Drain to Theory from Speed. Added Thorns to Core and Haste to Speed.

newTalent{ -- The shields core. (abstract-024)
	name = "The Art of Shieldweaving",
	short_name = "KAM_SPELLWEAVER_SHIELDS_CORE",
	image = "talents/kam_spellweaver_the_art_of_shieldweaving.png",
--	image = "talents/shielding.png",
	type = {"spellweaving/shieldweaving", 1},
	points = 5,
	require = spells_req1,
	mode = "passive",
	no_unlearn_last = true,
		-- Originally based on Temporal Shield, may need rebalancing because that's designed as a specialty spell...
	getMaxAbsorb = function(self, t)
		local retVal = self:combatTalentSpellDamage(t, 50, 500)
		return retVal
	end,
	getDuration = function(self, t) 
		local extend = 0
		if self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_DURATION) then 
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_DURATION)
			extend = tal.getDurationExtend(self, tal)
		end
		return util.bound(8 + math.floor(extend))
	end,
	info = function(self, t)
		return ([[Magical barriers can be constructed just like any other spell, even if it takes a different approach.
		You gain the Shield Spell Crafting spell. Shields you create have a base %d power multiplied by Spellweave Multiplier and %d duration modified by Spellweave Multiplier. Spellweave Multiplier only has half the normal effect on the duration.
		Shield power scales with spellpower and talent level, and you can only have 1 shield with each shield mode active at once.
		Additionally, gain the basic Shield Components - Mode: Basic Shield and Bonus: None, and if you do not have the first Spell Slot from the Spellweaver tree, gain that Spell Slot.
		At raw talent level 3, also gain the Shield Bonus: Thorns (Deal elemental damage to all attackers).
		At raw talent level 5, also gain the Shield Mode: Shielding Wave (Shield is applied to all nearby friendly targets at slightly reduced power).]]):
		tformat(t.getMaxAbsorb(self, t), t.getDuration(self, t))
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHIELDMODE_BASIC)) then
			self:learnTalent(Talents.T_KAM_SHIELDMODE_BASIC, true)
		end
		if not (self:knowTalent(self.T_KAM_SHIELDBONUS_NONE)) then
			self:learnTalent(Talents.T_KAM_SHIELDBONUS_NONE, true)
		end
		if not (self:knowTalent(self.T_KAM_SPELL_CRAFTING_SHIELD)) then
			self:learnTalent(Talents.T_KAM_SPELL_CRAFTING_SHIELD, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_THORNS_ELEMENTAL)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_THORNS_ELEMENTAL, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_AREA)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_AREA, true)
			end			
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_BASIC)
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_NONE)
			self:unlearnTalent(Talents.T_KAM_SPELL_CRAFTING_SHIELD)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_THORNS_ELEMENTAL)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_AREA)
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
}

newTalent{ -- psychic-waves (1)
	name = "Theory of Barriers",
	short_name = "KAM_SPELLWEAVER_SHIELDS_DURATION",
	image = "talents/kam_spellweaver_theory_of_barriers.png",
--	image = "talents/premonition.png",
	type = {"spellweaving/shieldweaving", 2},
	points = 5,
	require = spells_req2,
	mode = "passive",
	no_unlearn_last = true,
	getDurationExtend = function(self, t) 
		return math.floor(self:getTalentLevel(t)) 
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_CORE)
		local duration = tal.getDuration(self, tal)
		return ([[You have studied the nature of magical shields, and come to understand how to make them last. 
		Your shields gain %d turns of duration (total %d duration).
		At raw talent level 3, also gain the Shield Bonus: Draining (Heal for 20%% of all damage the shield absorbs).
		At raw talent level 5, also gain the Shield Mode: Contingency Shield (Shield becomes a sustain that triggers instantly when you would be hit below a health threshold).]]):
		tformat(t.getDurationExtend(self, t), duration)
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_DRAIN)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_DRAIN, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_CONTINGENCY)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_CONTINGENCY, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_DRAIN)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_CONTINGENCY)
		end
	end,
}

newTalent{
	name = "Practiced Motions",
	short_name = "KAM_SPELLWEAVER_SHIELDS_SPEED",
	image = "talents/kam_spellweaver_practiced_motions.png",
--	image = "talents/anomaly_swap.png",
	type = {"spellweaving/shieldweaving", 3},
	points = 5,
	require = spells_req3,
	mode = "passive",
	no_unlearn_last = true,
	getSpeed = function(self, t) 
		return math.max(0, 0.5 - self:combatTalentLimit(self:getTalentLevel(t), 0.5, 0.08, 0.40))
	end,
	info = function(self, t)
		return ([[Although you cannot intuitively make shields instantly like Archmages and other intuitive mages, you have practiced the motions so many times that it's just as fast.
		Your non-sustained shields now only require %d%% of a turn.
		At raw talent level 3, also gain the Shield Bonus: Haste (When the shield breaks, gain a short but significant increase in movement, attack, mental, and spell speeds).
		At raw talent level 5, also gain the Shield Mode: Perfect Block (Shield duration is reduced to exactly 1 and the time required to use it is increased by half of a turn, but absorption power is multiplied by 7).]]):tformat(t.getSpeed(self, t) * 100)
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_HASTE)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_HASTE, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_ONETURN)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_ONETURN, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_HASTE)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_ONETURN)
		end
	end,
}

newTalent{
	name = "Spellweaver's Protection",
	short_name = "KAM_SPELLWEAVER_SHIELDS_MASTERY",
	image = "talents/kam_spellweaver_spellweavers_protection.png",
--	image = "talents/aegis.png",
	type = {"spellweaving/shieldweaving", 4},
	points = 5,
	require = spells_req4,
	mode = "passive",
	no_unlearn_last = true,
	getSpellweaverPowerBoost = function(self, t) 
		return self:combatTalentLimit(self:getTalentLevel(t), .25, .05, .15)
	end,
	info = function(self, t)
		return ([[Your will does not falter, your guard does not fail.
		Your Shield spells gain an additional %d%% Spellweave Multiplier.
		At raw talent level 3, also gain the Shield Bonus: Reflection (Reflect 50%% of all damage the shield absorbs).
		At raw talent level 5, also gain the Shield Mode: Dispersing Shield (Higher Spellweave Multiplier, but the shield only absorbs up to 100 damage from each hit).]]):tformat(t.getSpellweaverPowerBoost(self, t) * 100)
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_REFLECT)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_REFLECT, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_DISPERSE)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_DISPERSE, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_REFLECT)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_DISPERSE)
		end
	end,
}