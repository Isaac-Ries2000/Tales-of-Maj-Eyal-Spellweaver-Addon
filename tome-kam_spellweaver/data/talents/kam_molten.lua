local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/molten", no_silence = true, is_spell = true, name = _t("molten", "talent type"), description = _t"Weave spells with physical and flaming power of molten earth." }
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
-- Molten tree. Talents:
-- Molten: Gives elements and second effects, increases damage and second power.
-- Burning Earth: Increases element dam mod, gives some res piercing.
-- Melting Stone: Burns and wounds increase in duration by 1 when hitting with non-fire/physical damage.
-- Eyal's Core: Gives access to combo element, increases combo second, gives modes: 
--    Shield Mode: Molten Shield (Skill becomes a sustain that gives regenerating shield with low max life, but bonus power is much lower (or maybe a skill that lasts a while)).
--    Teleport Mode: Molten Path (Teleport in a straight line up to 20 tiles through walls).

newTalent{ -- volcano
	name = "Molten",
	short_name = "KAM_ELEMENTS_MOLTEN",
	image = "talents/kam_spellweaver_molten.png",
--	image = "talents/volcano.png",
	type = {"spellweaving/molten", 1},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req1,
	getDamage = function(self, t, level) return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_PHYSICAL)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_PHYSICAL, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_FLAME)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_FLAME, true)
		end
	end,
	on_unlearn = function(self, t) -- Shrug.
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_PHYSICAL)
			self:unlearnTalent(Talents.T_KAM_ELEMENT_FLAME)
		end
	end,
	getWoundChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 200, 30, 100)
	end,
	getWoundPower = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_SUSTAIN)
		if tal then
			return tal.getWoundBoost(self, tal)
		end
		return 30
	end,
	getBurnPercent = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		local multiplier = 1
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_SUSTAIN)
		if tal then 
			multiplier = (tal.getBurnBoost(self, tal) / 100) + 1
		end
		return 0.8 * multiplier
	end,
	getBurnPower = function(self, t, level)
		return t.getDamage(self, level or t) * (t.getBurnPercent(self, t, level))
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		return ([[Learn how to cast spells with Fire and Physical. These spells will deal base %d damage with the following extra effects:
		Physical gains a %d%% chance to Wound targets, reducing their healing recieved by %d%%, for 4 turns.
		Fire deals only 40%% initial damage, but deals an additional %d%% of base damage (%d damage) as Fire damage over four turns.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage increases with Spellpower.]]):tformat(t.getDamage(self, t), t.getWoundChance(self, t), t.getWoundPower(self, t), 100 * t.getBurnPercent(self, t), self:damDesc(DamageType.FIRE, t.getBurnPower(self,t)))
	end,
}

newTalent{ -- burning-meteor
	name = "Meteoric Force",
	short_name = "KAM_ELEMENTS_MOLTEN_STRENGTHEN",
	image = "talents/kam_spellweaver_meteoric_force.png",
--	image = "talents/meteor_rain.png",
	type = {"spellweaving/molten", 2},
	points = 5,
	mode = "passive",
	no_unlearn_last = false,
	require = spells_req2,
	getDamageIncrease = function(self, t) 
		return KamCalc:getDamageIncForElementTalents(self, t)
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.FIRE] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.FIRE] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.PHYSICAL] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.PHYSICAL] = t.getResistPierce(self, t)})
	end,
	info = function(self, t) -- Hopefully Eyal actually has a molten core.
		return ([[Like a meteor can make it through the magical barriers and atmosphere of Eyal, enough fire and stone can break through any defense.
		Increase your Fire and Physical damage by %0.1f%% and gain %d%% Fire and Physical resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

newTalent{ -- burning-embers
	name = "Unending Melting",
	short_name = "KAM_ELEMENTS_MOLTEN_SUSTAIN",
	image = "talents/kam_spellweaver_unending_melting.png",
--	image = "talents/burning_wake.png",
	type = {"spellweaving/molten", 3},
	points = 5,
	sustain_mana = 35,
	cooldown = 20,
	tactical = { BUFF = 2 },
	mode = "sustained",
	no_unlearn_last = false,
	require = spells_req3,
	speed = "spell",
	
	getBurnBoost = function(self, t) 
		return self:combatTalentScale(t, 10, 30) 
	end,
	getWoundBoost = function(self, t) 
		return self:combatTalentScale(t, 35, 70) 
	end,
	getMoltenDrain = function(self, t) -- This is a pretty weak upside but it's fine, since the talent has a lot.
		return math.floor(self:combatTalentSpellDamage(t, 5, 35))
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		return { }
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[You have figured out how to combine your elements to extend the lifespan of your molten effects.
		Whenever you hit a Spellwoven Burning target with a non-Fire element Spellwoven spell, extend that burn by 1 turn. When you hit a Spellwoven Wounded target with a non-Physical element Spellwoven spell, extend that wound by 1 turn. Whenever you hit a target affected by Molten Drain with a non-Molten element Spellwoven spell, drain %d life from the target as draining Molten damage. 
		Additionally, as a passive bonus, Spellwoven burn damage is increased by %d%%, and the healing reduction of wounds is increased to %d%%.]]):
		tformat(self:damDesc(DamageType:get(DamageType.KAM_MOLTEN_DAMAGE_TYPE_DRAINING), t.getMoltenDrain(self, t)), t.getBurnBoost(self, t), t.getWoundBoost(self, t))
	end,
}

-- Molten element: Make damage tiles that steal healing, redirecting part of it to you.
newTalent{ -- caldera
	name = "Eyal's Flames",
	short_name = "KAM_ELEMENTS_MOLTEN_MASTERY",
	image = "talents/kam_spellweaver_eyals_flames.png",
--	image = "talents/elemental_retribution.png",
	type = {"spellweaving/molten", 4},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req4,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_MOLTEN)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_MOLTEN, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_SUSTAINED)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_SUSTAINED, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_WALLS)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_WALLS, true)
			end			
		end		
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_MOLTEN)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_SUSTAINED)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_WALLS)
		end
	end,
	getDamage = function(self, t, level) -- Just in case I ever want to change damage here.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		if tal then
			return tal.getDamage(self, tal, level)
		end
		return 0
	end,
	getMoltenChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 70, 10, 50) -- It's heal stealing damage tiles.
	end,
	getMoltenFloorTurns = function(self, t) -- For ease of editing later.
		return 4
	end,
	getMoltenDamage = function(self, t) -- This does NOT scale with Spellweave Multiplier (this talent is very strange feeling to balance).
		return math.floor(self:combatTalentSpellDamage(t, 8, 50))
	end,
	getHealReduction = function(self, t) -- Hopefully this won't be Problems.
		return self:combatTalentLimit(self:getTalentLevel(t), 70, 10, 50)
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getLesserResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.FIRE] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.PHYSICAL] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[You don't just use Fire or Physical magic, you draw power from the depths of Eyal itself. The magma deep down gives life and death, and so can you.
		Your Fire and Physical resistance penetration is increased by %0.1f%%. Gain the Molten element, which deals %d damage (from the Molten talent), divided equally among Fire and Physical. Molten damage also has a %d%% chance to scorch the ground, creating magma tiles for %d turns. Enemies on those tiles take %d Fire damage and %d Physical damage each turn and are afflicted with Molten Drain for 1 turn, redirecting %d%% of direct heals that target receives to you. Molten tile damage increases with Spellpower.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage and molten tile damage increase with Spellpower.
		Additionally, at raw talent level 3, gain Shield Mode: Slag Shield (The shield becomes a sustained shield that regenerates its power every turn).
		At raw talent level 5, gain Teleport Mode: Molten Path (Teleport in a straight line through enemies and walls until you hit an empty space, ignoring and removing all freezes and stuns).]]):
		tformat(t.getResistPierce(self, t), t.getDamage(self, t), t.getMoltenChance(self, t), t.getMoltenFloorTurns(self, t), self:damDesc(DamageType.FIRE, t.getMoltenDamage(self, t)), self:damDesc(DamageType.PHYSICAL, t.getMoltenDamage(self, t)), t.getHealReduction(self, t))
	end, 
}