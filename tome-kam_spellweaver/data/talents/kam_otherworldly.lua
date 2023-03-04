local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/otherworldly", no_silence = true, is_spell = true, name = _t("otherworldly", "talent type"), description = _t"Weave spells with the arcane and temporal power of magical itself." }
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
-- Otherworldly tree. Talents:
-- Otherworldly: Gives elements and second effects, increases damage and second power.
-- Magic Time!: Increases element dam mod, gives some res piercing.       -- "magic time!" is great.
-- Void Dance: Whenever you hit a slowed target or a target with less than 50% of its Mana, Vim, or Positive/Negative energies, gain x move speed for 1 turn. Whenever you move, gain 1.3x Spellweaver Power for your next spell during your turn.
-- Blessing of the Void: Gives access to combo element, increases combo second, gives modes: 
--    Shield Bonus: Arcane Break (When the shield is broken, create arcane vortex dealing damage based on shield power. Max one vortex at once).
--    Teleport Bonus: Voidstepping (After teleport, gain 300% movespeed for two turns, also teleport through walls of thickness two or less while this is active).

newTalent{ -- solar-system
	name = "Otherworldly",
	short_name = "KAM_ELEMENTS_OTHERWORLDLY",
	image = "talents/kam_spellweaver_otherworldly.png",
--	image = "talents/pure_aether.png",
	type = {"spellweaving/otherworldly", 1},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req1,
	getDamage = function(self, t, level) return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_ARCANE)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_ARCANE, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_TEMPORAL)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_TEMPORAL, true)
		end
	end,
	on_unlearn = function(self, t) -- Shrug.
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_ARCANE)
			self:unlearnTalent(Talents.T_KAM_ELEMENT_TEMPORAL)
		end
	end,
	getSlowChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 150, 45, 100)
	end,
	getManaburningPercent = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return 1 --self:combatTalentLimit(level, 2, 0.4, 1) -- It already increases with talent level because it's based on percent of damage. This is fine for now.
	end,
	getManaburning = function(self, t, level)
		return t.getDamage(self, level or t) * t.getManaburningPercent(self, t, level)
	end,
	info = function(self, t)
		local manaburnAmount = t.getManaburning(self, t)
		return ([[Learn how to cast spells with Arcane and Temporal. These spells will deal base %d damage with the following extra effects:
		Arcane also drains arcane resources, draining %d mana, %d vim, and %d positive and negative energies, and dealing the greatest of 50%% of the drained mana, 100%% of the drained vim, and 200%% of the drained negative energy as arcane damage.
		Temporal gains a %d%% chance to slow enemies, reducing their global speeds by 35%% and their projectile's speed by 50%% for 4 turns.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage and manaburning increase with Spellpower.]]):tformat(t.getDamage(self, t), manaburnAmount, manaburnAmount / 2, manaburnAmount / 4, t.getSlowChance(self,t))
	end,
}

newTalent{ -- knocked-out-stars
	name = "Magic Time!", -- ... look, I had to.
	short_name = "KAM_ELEMENTS_OTHERWORLDLY_STRENGTHEN",
	image = "talents/kam_spellweaver_magic_time.png",
--	image = "talents/aether_permeation.png",
	type = {"spellweaving/otherworldly", 2},
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
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.ARCANE] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.ARCANE] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.TEMPORAL] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.TEMPORAL] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Through your practice with arcane and temporal magics, you understand that power of magic comes as much from the beyond as from here, and nothing is prepared for that beyond this world.
		Increase your Arcane and Temporal damage by %0.1f%% and gain %d%% Arcane and Temporal resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

newTalent{ -- two-shadows
	name = "Void Dance",
	short_name = "KAM_ELEMENTS_OTHERWORLDLY_SUSTAIN",
	image = "talents/kam_spellweaver_void_dance.png",
--	image = "talents/slipstream.png",
	type = {"spellweaving/otherworldly", 3},
	points = 5,
	sustain_mana = 35,
	cooldown = 20,
	tactical = { BUFF = 2 },
	mode = "sustained",
	no_unlearn_last = false,
	require = spells_req3,
	speed = "spell",
	
	getMovespeed = function(self, t) return self:combatTalentScale(t, 100, 200) end, -- Gain somewhere around 100% to 200% movespeed. Test this for power.
	getSpellweaveMod = function(self, t) return self:combatTalentScale(t, 1.04, 1.13) end, -- This is a bonus that you are going to have up very frequently and without needing to pay much attention.
	getMovespeedChance = function(self, t) return self:combatTalentScale(t, 20, 50) end,
	getCooldown = function(self)
		local p = self:isTalentActive(self.T_KAM_ELEMENTS_OTHERWORLDLY_SUSTAIN)
		if not p then return 0 end 
		return p.waitTurns
	end,
	iconOverlay = function(self, t, p)
		local p = self.sustain_talents[t.id]
		if not p or p.waitTurns == 0 then return "" end
		return  "#LIGHT_GREEN#"..p.waitTurns.."#LAST#", "buff_font_smaller"
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy)
		if moved and ox and oy and (ox ~= self.x or oy ~= self.y) then
			self:setEffect(self.EFF_KAM_SPELLWEAVER_OTHERWORLDLY_FLOW, 2, {src=self, powerMod = t.getSpellweaveMod(self, t)})
		end
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)
		if not p then return end
		if p.waitTurns > 0 then
			p.waitTurns = p.waitTurns - 1
		end
	end,
	doGainMovespeed = function(self, t, chanceMultiplier)
		if rng.percent(t.getMovespeedChance(self, t) * chanceMultiplier) then
			self:setEffect(self.EFF_KAM_SPELLWOVEN_SPEED, 2, {src=self, power = t.getMovespeed(self, t)})
		end
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		return { 
			waitTurns = 0
		}
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[You understand the power of motion. Time's eternal march, the flow of arcane power... You know how to work with it all to take advantage of what other's motion lacks.
		When you hit an enemy that is slowed by Spellweave effects or has less than 50%% of its mana, vim, positive energy, or negative energy (and has the associated resource pool) with a Spellwoven spell, gain a %d%% chance (multiplied by the spell's Shape's Spellweave Multiplier) to gain %d%% movespeed for one turn. If you move while this effect is active, you will not be able to gain it again for 5 turns. If a target is slowed and has less than 50%% of one of those values, the chance is increased by half. When you move, except by force, your next Spellwoven activated spell cast during your next turn gains an additional %0.2f Spellweave Multiplier multiplier.
		
		Current Cooldown: %d]]):tformat(t.getMovespeedChance(self, t), t.getMovespeed(self, t), t.getSpellweaveMod(self, t), t.getCooldown(self))
	end, -- Has the associated resource pool is a weird phrasing, but it means you can't hit stuff that doesn't even know what mana is for this. 
}

-- Otherworldly element: Decreases duration of beneficial effects, increases duration of yours.
newTalent{ -- galaxy
	name = "Unreal Showing",
	short_name = "KAM_ELEMENTS_OTHERWORLDLY_MASTERY",
	image = "talents/kam_spellweaver_unreal_showing.png",
--	image = "talents/temporal_bolt.png",
	type = {"spellweaving/otherworldly", 4},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req4,
	
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_OTHERWORLDLY)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_OTHERWORLDLY, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_DRAINARCANE)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_DRAINARCANE, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_VOIDSTEPPING)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_VOIDSTEPPING, true)
			end			
		end		
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_OTHERWORLDLY)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_DRAINARCANE)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_VOIDSTEPPING)
		end
	end,
	getDamage = function(self, t, level) -- Just in case I ever want to change damage here.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY)
		if tal then
			return tal.getDamage(self, tal, level)
		end
		return 0
	end,
	getChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 80, 15, 55)
	end,
	effectNumber = function(self, t) 
		return 1 + math.floor(self:combatTalentScale(t, 0, 2)) 
	end,
	getDuration = function(self, t) 
		return math.floor(self:combatTalentScale(t, 1, 3.5)) 
	end,
	getDurationYou = function(self, t) -- Ceiling of half of the normal duration.
		return math.ceil(self:combatTalentScale(t, 1, 3.5) / 2)
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getLesserResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.ARCANE] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.TEMPORAL] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Every mage knows that what most people see as "reality" in the world of Eyal is not strong. Time can be molded, gravity bent... You, however, know how to harness that unrealness to perform impossible feats.
		Your Arcane and Temporal resistance penetration is increased by %0.1f%%. Gain the Otherworldly element, which deals %d damage (from the Otherworldly talent), divided equally among Arcane and Temporal and multiplied by Spellweave Multiplier. Otherworldly damage also gains a %d%% chance (multiplied by Spellweave Multiplier) to drain time from a target, reducing the duration of up to %d of their beneficial effects by %d turns and increasing the duration of one of your beneficial effects by half as much, rounded up (%d turns).
		Element damage increases with Spellpower.
		Additionally, at raw talent level 3, gain Shield Bonus: Power Draining (When hit, drain the attacker's resources based on the damage received and restore mana based on the amount drained).
		At raw talent level 5, gain Teleport Bonus: Voidstepping (After teleporting, gain significant movespeed for two turns, and the ability to run through one wall of thickness 3 or less while this is active).]]):
		tformat(t.getResistPierce(self, t), t.getDamage(self, t), t.getChance(self, t), t.effectNumber(self, t), t.getDuration(self, t), t.getDurationYou(self, t))
	end, 
}