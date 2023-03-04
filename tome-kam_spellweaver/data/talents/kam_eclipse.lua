local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/eclipse", no_silence = true, is_spell = true, name = _t("eclipse", "talent type"), description = _t"Weave spells with light and dark from the eclipse." }
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
-- Eclipse tree. Talents:
-- Eclipse: Gives elements and second effects, increases damage and second power.
-- Luminous Shadows: Increases element dam mod, gives some res piercing.
-- Darklight Confusion: Sustain. Increases damage to Illuminated/Blinded targets (bonus increased by 1.5 for non-light/dark elements).
-- Endless Eclipse: Gives access to combo element, increases combo second, gives modes: 
--    Shield Mode: Phantasmal Shield (Gives 50% chance to completely negate damage, reducing shield life by amount negated, but shield power increases substantially).
--    Teleport Bonus: Illusions (Creates mirror image on teleport (max 1), 2 life multiplied by Spellweave Multiplier, min 1, rounding with standard rules).

newTalent{ -- eclipse-flare
	name = "Eclipse",
	short_name = "KAM_ELEMENTS_ECLIPSE",
	image = "talents/kam_spellweaver_eclipse.png",
--	image = "talents/twilight_glyph.png",
	type = {"spellweaving/eclipse", 1},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req1,
	getDamage = function(self, t, level) return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_DARKNESS)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_DARKNESS, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_LIGHT)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_LIGHT, true)
		end
	end,
	on_unlearn = function(self, t) -- It occurs to me that you can't do this but whatever I guess.
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_DARKNESS)
			self:unlearnTalent(Talents.T_KAM_ELEMENT_LIGHT)
		end
	end,
	getBlindChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 200, 50, 100) -- Consider switching to 200, 50, 85 (guarenteed on single target, otherwise only likely).. 
	end,
	getIlluminateChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 400, 150, 250)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENT_LIGHT)
		local illChance = tal.getStatusChance(self, tal)
		return ([[Learn how to cast spells with Light and Darkness. These spells will deal base %d damage with the following extra effects:
		Darkness gains a %d%% chance to blind for 5 turns.
		Light gains an additional 10%% damage and has a %d%% chance to light targets with Luminescence (reducing their stealth power by 20) for 5 turns.
		All damage and effect chances are multiplied by Spellweave Multiplier.]]):tformat(t.getDamage(self, t), t.getBlindChance(self, t), illChance)
	end,
}

newTalent{ -- Sunbeams (reverse light and dark)
	name = "Luminous Shadows",
	short_name = "KAM_ELEMENTS_ECLIPSE_STRENGTHEN",
	image = "talents/kam_spellweaver_luminous_shadows.png",
--	image = "talents/corona.png",
	type = {"spellweaving/eclipse", 2},
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
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.LIGHT] = t.getDamageIncrease(self, t), [DamageType.DARKNESS] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.LIGHT] = t.getResistPierce(self, t), [DamageType.DARKNESS] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Through your practice with light and darkness, you have grown to understand that they are everywhere and in everything, empowering you and letting you break through resistances.
		Increase your Light and Dark damage by %0.1f%% and gain %d%% Light and Dark resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

newTalent{ -- star-sattelites
	name = "Darklight Confusion",
	short_name = "KAM_ELEMENTS_ECLIPSE_SUSTAIN",
	image = "talents/kam_spellweaver_darklight_confusion.png",
--	image = "talents/set_up.png",
	type = {"spellweaving/eclipse", 3},
	points = 5,
	sustain_mana = 35,
	cooldown = 20,
	tactical = { BUFF = 2 },
	mode = "sustained",
	no_unlearn_last = false,
	require = spells_req3,
	speed = "spell",
	
	getDamPowerIlluminate = function(self, t) return self:combatTalentScale(t, 5, 20) end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		return {
			illuminateDam = self:addTemporaryValue("kam_darklight_illuminate_damage", t.getDamPowerIlluminate(self, t))
		}
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("kam_darklight_illuminate_damage", p.illuminateDam)
		return true
	end,
	info = function(self, t)
		return ([[In the complex swirl of light and darkness, you always have an advantage. 
		Targets that are Blinded, have Luminescence, or have an Eclipsing Corona take an additional %d%% damage. These damage bonuses will not stack. 
		When the damage is with an element other than Light or Dark, the damage bonus is increased to %d%%.]]):tformat(t.getDamPowerIlluminate(self, t), t.getDamPowerIlluminate(self, t) * 1.1 + 10)
	end,
}

-- Eclipse element: Lowers every defensive stat, lower application chance. 
newTalent{ -- sun (cut out the center)
	name = "Endless Eclipse",
	short_name = "KAM_ELEMENTS_ECLIPSE_MASTERY",
	image = "talents/kam_spellweaver_endless_eclipse.png",
--	image = "talents/celestial_surge.png",
	type = {"spellweaving/eclipse", 4},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req4,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_ECLIPSE)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_ECLIPSE, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_MIRRORIMAGE)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_MIRRORIMAGE, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_SHIELDMODE_CHANCEY)) then
				self:learnTalent(Talents.T_KAM_SHIELDMODE_CHANCEY, true)
			end			
		end		
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_ECLIPSE)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_MIRRORIMAGE)		
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_SHIELDMODE_CHANCEY)		
		end
	end,
	getDamage = function(self, t, level) -- Just in case I ever want to change damage here.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE)
		if tal then
			return tal.getDamage(self, tal, level)
		end
		return 0
	end,
	getCoronaChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 60, 10, 40) -- This effect lowers every single defensive stat so it seems powerful enough.
	end,
	getDefensesPenalty = function(self, t) -- Defense and Stealth are this, Invisibility and Armor are half of this.
		return math.floor(self:combatTalentSpellDamage(t, 10, 45))
	end,
	getArmorPenalty = function(self, t) -- In case I ever want to alter the ratio.
		return t.getDefensesPenalty(self, t) / 2
	end,
	getResistanceBreaking = function(self, t) 
		return self:combatTalentLimit(self:getTalentLevel(t), 30, 5, 20)
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getLesserResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.LIGHT] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.DARKNESS] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[You don't just control the Light or Dark, you control the power of night and day itself.
		Your Light and Darkness resistance penetration is increased by %0.1f%%. Gain the Eclipse element, which deals %d damage (from the Eclipse talent), divided equally among Light and Darkness. Eclipse damage also has a %d%% chance to create an Eclipsing Corona around an enemy, reducing all of their resistances by %d%% and reducing their defense and stealth power by %d and their armor and invisibility power by %d for 4 turns.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage and armor, defense, stealth and invisibility power reduction increase with Spellpower.
		Additionally, at raw talent level 3, gain Teleport Bonus: Illusions (create a Spellwoven Simulcrum when you teleport that taunts enemies into attacking it instead of you).
		At raw talent level 5, gain Shield Mode: Phantasmal (increased shield power, but only applies half of the time).]]):
		tformat(t.getResistPierce(self, t), t.getDamage(self, t), t.getCoronaChance(self, t), t.getResistanceBreaking(self, t), t.getDefensesPenalty(self, t), t.getArmorPenalty(self, t))
	end,
}