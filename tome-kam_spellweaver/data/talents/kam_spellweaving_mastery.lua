local Map = require "engine.Map"
local Chat = require "engine.Chat"
local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/spellweaving-mastery", no_silence = true, is_spell = true, name = _t("spellweaving mastery", "talent type"), description = _t"The advanced arts of weaving spells." }
spells_req_high1 = {
	stat = { mag=function(level) return 22 + (level-1) * 2 end },
	level = function(level) return 10 + (level-1)  end,
}
spells_req_high2 = {
	stat = { mag=function(level) return 30 + (level-1) * 2 end },
	level = function(level) return 14 + (level-1)  end,
}
spells_req_high3 = {
	stat = { mag=function(level) return 38 + (level-1) * 2 end },
	level = function(level) return 18 + (level-1)  end,
}
spells_req_high4 = {
	stat = { mag=function(level) return 46 + (level-1) * 2 end },
	level = function(level) return 22 + (level-1)  end,
}
-- The advanced spellweaving tree. 
-- Connection, Perfection, Destruction, Mastery.
-- The icons are a bit rainbow-y (a bit too much?), although precision's turned out real nice.

newTalent{ -- boomerang-sun (as for the green/pink area... nature and mind(?) I guess? Honestly the icon had 6 things but I liked it and nature is a Spellweaving element for the class evo so...
	name = "Spellweaver's Connection",
	short_name = "KAM_SPELLWOVEN_MASTERY",
	image = "talents/kam_spellweaver_spellweavers_connection.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaving-mastery", 1},
	points = 3,
	require = spells_req_high1,
	mode = "passive",
	no_unlearn_last = true,
	getManaRegen = function(self, t) return self:combatTalentScale(self:getTalentLevel(t) * 5/3, 0.7, 5, 0.75) end,
	info = function(self, t)
		return ([[You understand the source of magic itself, and it flows into you as easily as you shape it.
		Gain %0.2f mana regeneration. Additionally, gain Shape: Spiral (Create a spiraling shape cenetered on your location).
		At raw talent level 2, gain Shape: Checkerboard (Create two seperate spell effects that activate on alternating tiles in a checkerboard pattern).
		At raw talent level 3, gain Mode: Digging (Pierce and destroy walls).
		]]):tformat(t.getManaRegen(self, t)) -- Digging might be adjusted to not pierce if it's toooo strong.
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "mana_regen", t.getManaRegen(self, t))
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_SPIRAL)) then
			self:learnTalent(Talents.T_KAM_SHAPE_SPIRAL, true)
		end
		if self:getTalentLevelRaw(t) >= 2 then
			if not (self:knowTalent(self.T_KAM_SHAPE_CHECKERBOARD)) then
				self:learnTalent(Talents.T_KAM_SHAPE_CHECKERBOARD, true)
			end			
		end
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_MODE_DIGGING)) then
				self:learnTalent(Talents.T_KAM_MODE_DIGGING, true)
			end			
		end
	end,
	on_unlearn = function(self, t) -- This still shouldn't happen but eh.
		if not (self:knowTalent(t)) then 
			self:unlearnTalent(Talents.T_KAM_SHAPE_SPIRAL)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_CHECKERBOARD)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_MODE_DIGGING)
		end
	end,
}

newTalent{ -- spikes-init
	name = "Spellweaver's Precision",
	short_name = "KAM_SPELLWOVEN_PERFECTION",
	image = "talents/kam_spellweaver_spellweavers_precision.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaving-mastery", 2},
	points = 3,
	require = spells_req_high2,
	mode = "passive",
	no_unlearn_last = true,
	getCritBoost = function(self, t) return self:combatTalentScale(self:getTalentLevel(t) * 5/3, 5, 25, 0.75) end,
	info = function(self, t)
		return ([[Your shaping is perfectly controlled, with unparalleled precision.
		Gain %d%% critical power. Additionally, gain Shape: Touch (High spellpower, melee range.)
		At raw talent level 2, gain Mode: Wall (Create wall tiles the inflict their effects each turn. Chance to create walls is modified by Spellweave Multiplier.). 
		At raw talent level 3, gain Mode: Resistance Breaking (Reduce enemy resistances to the spell's elements.)
		]]):tformat(t.getCritBoost(self, t))
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_critical_power", t.getCritBoost(self, t))
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_TOUCH)) then
			self:learnTalent(Talents.T_KAM_SHAPE_TOUCH, true)
		end			
		if self:getTalentLevelRaw(t) >= 2 then
			if not (self:knowTalent(self.T_KAM_MODE_WALLS)) then
				self:learnTalent(Talents.T_KAM_MODE_WALLS, true)
			end			
		end
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_MODE_EXPOSING)) then
				self:learnTalent(Talents.T_KAM_MODE_EXPOSING, true)
			end			
		end
	end,
	on_unlearn = function(self, t) -- Why do I keep making these anyways.
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHAPE_TOUCH)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_MODE_WALLS)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_MODE_EXPOSING)
		end
	end,
}

newTalent{ -- abstract-049
	name = "Spellweaver's Destruction",
	short_name = "KAM_SPELLWOVEN_DESTRUCTION",
	image = "talents/kam_spellweaver_spellweavers_destruction.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaving-mastery", 3},
	points = 3,
	require = spells_req_high3,
	mode = "passive",
	no_unlearn_last = true,
	getSpellweaverPowerBoost = function(self, t) 
		return self:combatTalentLimit(self:getTalentLevel(t) * 5/3, .15, .03, .08)
	end,
	info = function(self, t)
		return ([[Your shaping is unstoppably powerful, able to shape the world, or to break it.
		Your Attack spells gain an additional %d%% Spellweave Multiplier. Additionally, gain Shape: Huge (Much lower Spellweave Multiplier, huge area)
		At raw talent level 2, gain Shape: Wavepulse (Alternating waves extending from you with two different spell effects). 
		At raw talent level 3, gain Mode: Powerful Opening (Deal double damage to undamaged enemies).
		]]):tformat(t.getSpellweaverPowerBoost(self, t) * 100)
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_HUGE)) then
			self:learnTalent(Talents.T_KAM_SHAPE_HUGE, true)
		end			
		if self:getTalentLevelRaw(t) >= 2 then
			if not (self:knowTalent(self.T_KAM_SHAPE_WAVEPULSE)) then
				self:learnTalent(Talents.T_KAM_SHAPE_WAVEPULSE, true)
			end			
		end
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_MODE_GOODSTART)) then
				self:learnTalent(Talents.T_KAM_MODE_GOODSTART, true)
			end			
		end
	end,
	on_unlearn = function(self, t) -- Goodstart. I just had to.
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHAPE_HUGE)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_WAVEPULSE)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_MODE_GOODSTART)
		end
	end,
}

newTalent{ -- abstract-061 (1)
	name = "Spellweaver's Perfection",
	short_name = "KAM_SPELLWEAVER_MASTER",
	image = "talents/kam_spellweaver_spellweavers_perfection.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaving-mastery", 4},
	points = 3,
	require = spells_req_high4,
	mode = "passive",
	no_unlearn_last = true,
	info = function(self, t)
		return ([[You are a master of the spellweaving arts, and you understand how to shape your spells in incredible ways.
		Gain Element: Prismatic (Use all basic elements you've unlocked) and Shape: Grand Checkerboard (Lower Spellweave Multiplier, very large checkerboard effect).
		At raw talent level 2, gain Mode: Changeup (Lower Spellweave Multiplier, Spellweave Multiplier for spells sharing no elements with this spell temporarily increased) and Shape: Barrage (Choose 1 Shape, then use it three times at significantly reduced power).
		At raw talent level 3, gain an additional Spell Slot.
		]])
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_PRISMA)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_PRISMA, true)
		end
		if not (self:knowTalent(self.T_KAM_SHAPE_HUGE_CHECKERBOARD)) then
			self:learnTalent(Talents.T_KAM_SHAPE_HUGE_CHECKERBOARD, true)
		end	
		if self:getTalentLevelRaw(t) >= 2 then
			if not (self:knowTalent(self.T_KAM_MODE_CHANGEUP)) then
				self:learnTalent(Talents.T_KAM_MODE_CHANGEUP, true)
			end			
			if not (self:knowTalent(self.T_KAM_SHAPE_BARRAGE)) then
				self:learnTalent(Talents.T_KAM_SHAPE_BARRAGE, true)
			end			
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_ELEMENT_PRISMA)
			self:unlearnTalent(Talents.T_KAM_SHAPE_HUGE_CHECKERBOARD)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_MODE_CHANGEUP)
			self:unlearnTalent(Talents.T_KAM_SHAPE_BARRAGE)
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
}