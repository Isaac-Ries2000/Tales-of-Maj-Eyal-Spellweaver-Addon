local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/ruin", no_silence = true, is_spell = true, name = _t("ruin", "talent type"), description = _t"Weave spells with blight and acid to bring ruin and destruction." }
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
-- Ruin tree. Talents:
-- Ruin: Gives elements and second effects, increases damage and second power.
-- Foul Dissolution: Increases element dam mod, gives some res piercing.
-- Acidic Pestilence: All non-lingering spell damage has a chance to inflict diseases. When you hit a disarmed target with a spell, this is guarenteed. Targets take +% damage for each disease on them when using non-acid/blight damage.
-- Complete Ruin: Gives access to combo element, increases combo second, gives modes: 
--    Shield Bonus: Corrosion Shield (Attackers are corroded, reducing their all damage mod by x% (base 5) stacking additively with each application).
--    Teleport Bonus: Worm Path (Create a worm at both ends of your teleport. The blight pool it creates on death heals you).

newTalent{ -- gloop
	name = "Ruin",
	short_name = "KAM_ELEMENTS_RUIN",
	image = "talents/kam_spellweaver_ruin.png",
--	image = "talents/acidfire.png",
	type = {"spellweaving/ruin", 1},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req1,
	getDamage = function(self, t, level) return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_ACID)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_ACID, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_BLIGHT)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_BLIGHT, true)
		end
	end,
	on_unlearn = function(self, t) -- Shrug.
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_ACID)
			self:unlearnTalent(Talents.T_KAM_ELEMENT_BLIGHT)
		end
	end,
	getDisarmChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 150, 45, 90)
	end,
	getDiseaseChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 150, 50, 100)
	end,
	getDiseasePower = function(self, t)
		return self:combatTalentSpellDamage(t, 5, 30)
	end,
	info = function(self, t)
		return ([[Learn how to cast spells with Acid and Blight. These spells will deal base %d damage with the following extra effects:
		Acid also gains a %d%% chance to disarm enemies for 3 turns as their weapons are corroded.
		Blight gains a %d%% chance to disease enemies, reducing their strength, constitution, or dexterity by %d for 5 turns. These diseases stack, and diseases that are not currently in use will be prioritized.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage increases with Spellpower.]]):tformat(t.getDamage(self, t), t.getDisarmChance(self,t), t.getDiseaseChance(self, t), t.getDiseasePower(self, t))
	end,
}

newTalent{ -- boiling-bubbles
	name = "Foul Dissolution",
	short_name = "KAM_ELEMENTS_RUIN_STRENGTHEN",
	image = "talents/kam_spellweaver_foul_dissolution.png",
--	image = "talents/blood_splash.png",
	type = {"spellweaving/ruin", 2},
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
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.BLIGHT] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.BLIGHT] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.ACID] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.ACID] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Through your practice with blight and acid, you know that everything will break down, eventually, and that nothing can resist it.
		Increase your Blight and Acid damage by %0.1f%% and gain %d%% Blight and Acid resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

newTalent{ -- gooey-molecule
	name = "Acidic Pestilence",
	short_name = "KAM_ELEMENTS_RUIN_SUSTAIN",
	image = "talents/kam_spellweaver_acidic_pestilence.png",
--	image = "talents/caustic_golem.png",
	type = {"spellweaving/ruin", 3},
	points = 5,
	sustain_mana = 35,
	cooldown = 20,
	tactical = { BUFF = 2 },
	mode = "sustained",
	no_unlearn_last = false,
	require = spells_req3,
	speed = "spell",
	
	getDiseaseChance = function(self, t) return self:combatTalentScale(t, 3, 15) end, 
	getDiseaseDamage = function(self, t) return self:combatTalentScale(t, 2, 10) end, -- Remember, this is potentially cubed.
	getDiseasePower = function(self, t)
		if self:knowTalent(self.T_KAM_ELEMENTS_RUIN) then 
			local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
			return tal.getDiseasePower(self, tal)
		else 
			return 0
		end
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		return { 
			diseaseChance = self:addTemporaryValue("kam_apestilence_diseaseChance", t.getDiseaseChance(self, t)),
			diseaseDamage = self:addTemporaryValue("kam_apestilence_diseaseDamage", t.getDiseaseDamage(self, t))
		}
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("kam_apestilence_diseaseChance", p.diseaseChance)
		self:removeTemporaryValue("kam_apestilence_diseaseDamage", p.diseaseDamage)
		return true
	end,
	info = function(self, t)
		return ([[You've learned how to use the energy of pestilence and acid in your other spells, allowing you to spread their power farther.
		When you cast a Spellwoven Spell, you gain a %d%% chance to inflict one of the diseases from the Ruin talent to any enemies in the area. This chance is multiplied by the Spellweave Multiplier modifier of the shape, instead of the standard modifier. The power is currently %d, the same as the power of the Ruin talent, multiplied by the Spellweave Multiplier of the inflicting spell. Additionally, if the target of the Spell is disarmed, the chance is multiplied by 2.5. 
		Targets with Spellwoven diseases take an additional %0.1f%% damage for each disease on them (maxing at three diseases). This damage bonus per disease is increased to %0.1f%% if the damage is not Blight or Acid damage.]]):tformat(t.getDiseaseChance(self, t), t.getDiseasePower(self, t), t.getDiseaseDamage(self, t), t.getDiseaseDamage(self, t) * 1.3)
	end,
}

-- Ruin element: Lowers every offensive stat.
newTalent{ -- goo-explosion
	name = "Absolute Ruin",
	short_name = "KAM_ELEMENTS_RUIN_MASTERY",
	image = "talents/kam_spellweaver_absolute_ruin.png",
--	image = "talents/corpse_explosion.png",
	type = {"spellweaving/ruin", 4},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req4,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_RUIN)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_RUIN, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_CORROSION)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_CORROSION, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_SWAPPY)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_SWAPPY, true)
			end			
		end		
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_RUIN)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_CORROSION)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_SWAPPY)
		end
	end,
	getDamage = function(self, t, level) -- Just in case I ever want to change damage here.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		if tal then
			return tal.getDamage(self, tal, level)
		end
		return 0
	end,
	getRuinChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 60, 10, 40) -- This effect lowers every single offensive stat so it seems powerful enough.
	end,
	getPowerReduction = function(self, t)
		return math.floor(self:combatTalentSpellDamage(t, 5, 30))
	end,
	getAccuracyPenReduction = function(self, t) -- ... probably fine?
		return math.floor(self:combatTalentSpellDamage(t, 2, 20))
	end,
	getDamageBreaking = function(self, t) 
		return self:combatTalentLimit(self:getTalentLevel(t), 30, 5, 20)
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getLesserResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.BLIGHT] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.ACID] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Acid and Blight hold the power to wear anything down. This is inevitable. However, you understand that you can use this power to prevent harm as well as to destroy.
		Your Acid and Blight resistance penetration is increased by %0.1f%%. Gain the Ruin element, which deals %d damage (from the Ruin talent), divided equally among Acid and Blight and multiplied by Spellweave Multiplier. Ruin damage also gains a %d%% chance (multiplied by Spellweave Multiplier) to afflict targets with Ruinous Exhaustion, reducing all of their damage by %d%%, their all damage penetration by %d%%, their Attack, Mental, and Spell powers by %d, and their accuracy by %d for 4 turns.
		Element damage, powers reduction, accuracy, and damage penetration reduction increases with Spellpower.
		Additionally, at raw talent level 3, gain Shield Bonus: Corroding Shield (Attackers damage is reduced stackingly each time you are attacked).
		At raw talent level 5, gain Teleport Mode: Blightgate (Teleport enemies near your destination to your starting point).]]):
		tformat(t.getResistPierce(self, t), t.getDamage(self, t), t.getRuinChance(self, t), t.getDamageBreaking(self, t), t.getAccuracyPenReduction(self, t), t.getPowerReduction(self, t), t.getAccuracyPenReduction(self, t))
	end, 
}