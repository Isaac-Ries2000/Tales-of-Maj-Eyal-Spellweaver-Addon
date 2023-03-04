local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/wind-and-rain", is_spell = true, no_silence = true, is_spell = true, name = _t("wind and rain", "talent type"), description = _t"Weave spells with the lightning and cold power of the wind and rain." }
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
-- Wind and Rain tree. Talents:
-- Wind and Rain: Gives elements and second effects, increases damage and second power.
-- Storming Through: Increases element dam mod, gives some res piercing.
-- Hurricane: Lightning and Cold damage criticals have a chance to create Freezing Storm. Targets in freezing storms get 1.2 status chance/power multiplier.
-- The Dreadful Wind and Rain: Gives access to combo element, increases combo second, gives modes: 
--    Shield Bonus: Cleansing Rain (While the shield is active, gain substantial regeneration).
--    Teleport Mode: Lightning Speed (Rather than teleport, gain 700% movespeed for 2 turns. Gain teleport bonus effects once the speed ends).

newTalent{ -- raining
	name = "Wind and Rain",
	short_name = "KAM_ELEMENTS_WIND_AND_RAIN",
	image = "talents/kam_spellweaver_wind_and_rain.png",
--	image = "talents/thunderstorm.png",
	type = {"spellweaving/wind-and-rain", 1},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req1,
	getDamage = function(self, t, level) return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_LIGHTNING)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_LIGHTNING, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_COLD)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_COLD, true)
		end
	end,
	on_unlearn = function(self, t) -- Shrug.
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_LIGHTNING)
			self:unlearnTalent(Talents.T_KAM_ELEMENT_COLD)
		end
	end,
	getDazeChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 200, 35, 100) -- Dazes... aren't fantastic, so.
	end,
	getPinChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 100, 30, 70)
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		return ([[Learn how to cast spells with Lightning and Cold. These spells will deal base %d damage with the following extra effects:
		Lightning gains a %d%% chance to Daze targets for 3 turns and does not remove dazes.
		Cold gains a %d%% chance to freeze enemies to the ground, preventing them from moving, for 4 turns.
		All damage and effect chances are multiplied by Spellweave Multiplier.
		Element damage increases with Spellpower.]]):tformat(t.getDamage(self, t), t.getDazeChance(self, t), t.getPinChance(self,t))
	end,
}

newTalent{ -- waves (do alternating colors)
	name = "Storming Through",
	short_name = "KAM_ELEMENTS_WIND_AND_RAIN_STRENGTHEN",
	image = "talents/kam_spellweaver_storming_through.png",
--	image = "talents/living_lightning.png",
	type = {"spellweaving/wind-and-rain", 2},
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
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.COLD] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.COLD] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.LIGHTNING] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.LIGHTNING] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Through your practice with cold and lightning, you have seen through true force of storms. Icy water and tempest winds can destroy and create, and in the end, nothing can stop them.
		Increase your Cold and Lightning damage by %0.1f%% and gain %d%% Cold and Lightning resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

 -- This talent honestly might be a bit dramatic to put as just the generic 3rd sustain. We'll see how it pans out. It feels like maybe more archmage-y.
newTalent{ -- heavy-rain
	name = "Relentless Hailstorm",
	short_name = "KAM_ELEMENTS_WIND_AND_RAIN_SUSTAIN",
	image = "talents/kam_spellweaver_relentless_hailstorm.png",
--	image = "talents/hurricane.png",
	type = {"spellweaving/wind-and-rain", 3},
	points = 5,
	sustain_mana = 35,
	cooldown = 20,
	mode = "sustained",
	tactical = { ATTACKAREA = {LIGHTNING = 1.5, COLD = 1.5} },
	no_unlearn_last = false,
	require = spells_req3,
	speed = "spell",
	iconOverlay = function(self, t, p)
		local p = self.sustain_talents[t.id]
		if not p or not p.currentDamage then return "" end
		local current = p.currentDamage
		if current < 0 then
			current = 0
		end
		return "#LIGHT_GREEN#"..math.floor(current).."#LAST#", "buff_font_smaller"
	end,
	on_learn = function(self, t)
		local p = self:isTalentActive(t.id)
		if p then
			p.currentDamage = t.getBaseDamage(self, t)
		end
	end,
	on_unlearn = function(self, t)
		local p = self:isTalentActive(t.id)
		if p then
			p.currentDamage = t.getBaseDamage(self, t)
		end
	end,
	getBaseDamage = function(self, t) return self:combatTalentSpellDamage(t, 5, 30) * 0.6 end,
	getRadius = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getDamageBoost = function(self, t) return self:combatTalentScale(t, 2, 6) * 0.6 end,
	getMaxDamage = function(self, t) 
		return self:combatTalentScale(t, 1.5, 5) * t.getBaseDamage(self, t)
	end,
	getOvercharge = function(self, t)
		return self:combatTalentScale(t, 150, 300)
	end,
	getCurrent = function(self, t)
		local p = self:isTalentActive(t.id)
		if p then
			if p.currentDamage < 0 then return 0 end
			return p.currentDamage
		else 
			return 0
		end
	end,
	getCurrentOvercharge = function(self, t)
		local p = self:isTalentActive(t.id)
		if p then
			local damage = p.currentDamage - t.getBaseDamage(self, t)
			damage = damage * t.getOvercharge(self, t)/100
			if damage < 0 then return 0 end
			return damage
		else 
			return 0
		end
	end,
	getPinChance = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		if tal then 
			local chance = 1.2 * tal.getPinChance(self, t) * (t.getCurrent(self, t) - t.getBaseDamage(self, t)) / (t.getMaxDamage(self, t) - t.getBaseDamage(self, t))
			if chance < 0 then return 0 end
			return chance
		else 
			return 0
		end
	end,
	getDazeChance = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		if tal then 
			local chance = 1.2 * tal.getDazeChance(self, t) * (t.getCurrent(self, t) - t.getBaseDamage(self, t)) / (t.getMaxDamage(self, t) - t.getBaseDamage(self, t))
			if chance < 0 then return 0 end
			return chance
		else 
			return 0
		end
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)
		if p then 
			local tg = {type = "ball", radius = t.getRadius(self, t), range = 0, talent = t, friendlyfire = false, selffire = false}
			local dam = p.currentDamage
			local oldundaze
			if self.turn_procs then self.turn_procs.dealing_damage_dont_undaze, oldundaze = true, self.turn_procs.dealing_damage_dont_undaze end
			self:project(tg, self.x, self.y, DamageType.COLD, dam)
			self:project(tg, self.x, self.y, DamageType.LIGHTNING, dam)
			if self.turn_procs then self.turn_procs.dealing_damage_dont_undaze = oldundaze end
		
			if p.currentDamage > t.getBaseDamage(self, t) then
				p.currentDamage = p.currentDamage * 0.95
			end
			if p.currentDamage > t.getMaxDamage(self, t) then
				p.currentDamage = t.getMaxDamage(self, t)
			end
			if p.currentDamage < t.getBaseDamage(self, t) then
				p.currentDamage = t.getBaseDamage(self, t)
			end
		end
	end,
	doOvercharge = function(self, t, p)
		local dam = t.getCurrentOvercharge(self, t)
		if (dam > 0) then
			dam = self:spellCrit(dam)
			local tg = {type = "ball", radius = t.getRadius(self, t), range = 0, talent = t, friendlyfire = false, selffire = false}
			local oldundaze
			if self.turn_procs then self.turn_procs.dealing_damage_dont_undaze, oldundaze = true, self.turn_procs.dealing_damage_dont_undaze end
			self:project(tg, self.x, self.y, DamageType.COLD, dam)
			self:project(tg, self.x, self.y, DamageType.LIGHTNING, dam)
		
			self:project(tg, self.x, self.y, function(px, py, tg, self) 
				local target = game.level.map(px, py, Map.ACTOR)
				if target then 
					local tempStunDrop
					local tempPinDrop
					if target.attr and target:attr("stun_immune") then
						tempStunDrop = target:addTemporaryValue("stun_immune", -target:attr("stun_immune") / 2)
					end
					if target.attr and target:attr("pin_immune") then
						tempPinDrop = target:addTemporaryValue("pin_immune", -target:attr("pin_immune") / 2)
					end
					if target:canBe("pin") then 
						target:setEffect(target.EFF_FROZEN_FEET, 3, {src=self, apply_power=self:combatSpellpower()})
					end
					if target:canBe("stun") then 
						target:setEffect(target.EFF_DAZED, 3, {src=self, apply_power=self:combatSpellpower()})
					end
					if tempStunDrop then
						target:removeTemporaryValue("stun_immune", tempStunDrop)
					end 
					if tempPinDrop then
						target:removeTemporaryValue("pin_immune", tempPinDrop)
					end
				end
			end)
			if self.turn_procs then self.turn_procs.dealing_damage_dont_undaze = oldundaze end
			
			p.currentDamage = t.getBaseDamage(self, t)
		end
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/thunderstorm")
		game.log("#83def2#A powerful hailstorm swirls around you!")
		return {
			currentDamage = t.getBaseDamage(self, t)
		}
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local activeString = ""
		local p = self:isTalentActive(t.id)
		if p then 
			activeString = ([[Currently: %d power, dealing %d Cold and %d Lightning each turn. 
If you overcharge: Deal %d Cold and %d Lightning damage, with a %d%% chance of Dazing and %d%% chance of Freezing in Place and reset the damage to base.

]]):
			tformat(t.getCurrent(self, t), self:damDesc(DamageType.COLD, t.getCurrent(self, t)), self:damDesc(DamageType.LIGHTNING, t.getCurrent(self, t)), self:damDesc(DamageType.COLD, t.getCurrentOvercharge(self, t)), self:damDesc(DamageType.LIGHTNING, t.getCurrentOvercharge(self, t)), t.getDazeChance(self, t), t.getPinChance(self, t))
		end
		return ([[%sYou don't just understand storms, you command them.
		You gain a Hailstorm, dealing %d damage each turn to all enemies in radius %d, split equally between Cold and Lightning damage. When you use a Spellwoven spell that uses the Cold, Lightning, or Wind and Rain elements, the Hailstorm increases in power, increasing its damage by %0.1f%% of the damage of that spell (at most %d per turn). This power decreases by 5%% each turn down to the base values. When you cast a Spellwoven spell not including these elements, you unleash the power of the Hailstorm, resetting its damage and immediately dealing %d%% of its stored damage with a chance to freeze enemies to the ground or daze them for 3 turns. These chances are based on the Wind and Rain talent, but increase with the power of the Hailstorm, and Stun and Pin resist are halved to resist these effects.
		Hailstorm damage will not remove dazes.
		Base and max damage scale with Spellpower.]]):
		tformat(activeString, self:damDesc(DamageType.WIND_AND_RAIN, t.getBaseDamage(self, t) * 2), t.getRadius(self, t), t.getDamageBoost(self, t) * 2, t.getMaxDamage(self, t), t.getOvercharge(self, t))
	end,
}


-- Wind and Rain element: Makes icestorms at enemies.
newTalent{ -- wind-slap
	name = "Eyal's Storm", -- Changed from The Dreadful Wind and Rain because the reference was a bit out there for your average ToME player maybe.
	short_name = "KAM_ELEMENTS_WIND_AND_RAIN_MASTERY",
	image = "talents/kam_spellweaver_the_dreadful_wind_and_rain.png",
--	image = "talents/thunderclap.png",
	type = {"spellweaving/wind-and-rain", 4},
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req4,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_WIND_AND_RAIN)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_WIND_AND_RAIN, true)
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHIELDBONUS_REGEN)) then
				self:learnTalent(Talents.T_KAM_SHIELDBONUS_REGEN, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_SPEED)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_SPEED, true)
			end			
		end		
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_WIND_AND_RAIN)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHIELDBONUS_REGEN)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_SPEED)
		end
	end,
	getDamage = function(self, t, level) -- Just in case I ever want to change damage here.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		if tal then
			return tal.getDamage(self, tal, level)
		end
		return 0
	end,
	getChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 60, 8, 40) -- Not a high chance, since its fairly substantial extra damage and lets you apply debuffs even more easily.
	end,
	getIcestormDamage = function(self, t) -- This is free radiating damage for 3 turns.
		return math.floor(self:combatTalentSpellDamage(t, 15, 80))
	end,
	getRadius = function(self, t) -- Radius of radiating damage.
		return 3 -- math.floor(self:combatTalentScale(t, 3, 5)) -- Nerfed for getting over the top on large group purposes.
	end,
	getDuration = function(self, t) -- For ease of adjustment.
		return 4
	end,
	getChanceMod = function(self, t)
		local icestorms = self:attr("kam_icestorm_count") or 0
		return math.max(0, 1 - icestorms * 0.15)
	end,
	doUpdateCount = function(self, t) -- Update icestorm count
		self:attr("kam_icestorm_count", 0, 0)
		for _, e in pairs(game.level.entities) do
			if e.rank and e.subtype and e.hasEffect and e:hasEffect(e.EFF_KAM_WIND_AND_RAIN_EFFECT) then
				self:attr("kam_icestorm_count", 1)
			end
		end
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getLesserResistancePiercingForElementTalents(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.COLD] = t.getResistPierce(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.LIGHTNING] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		t.doUpdateCount(self, t)
		return ([[Any sailor knows that the seas of Eyal carry hurricanes and storms that can swallow ships and that even the strongest mage couldn't control. You know that the most powerful storms cannot be controlled, merely unleashed.
		Your Cold and Lightning resistance penetration is increased by %0.1f%%. Gain the Wind and Rain element, which deals %d damage (from the Wind and Rain talent), divided equally among Cold and Lightning and multiplied by Spellweave Multiplier. Wind and Rain damage has a %d%% chance (multiplied by Spellweave Multiplier) to surround targets with an Icestorm, halving their Pinning and Stun resistance and dealing %d damage, equally divided between Cold and Lightning to every enemy around them in radius %d for %d turns. Icestorm damage does not break dazes. The chance of inflicting icestorm reduces by 15%% for each icestorm present on the level.
		Element damage and Icestorm damage increase with Spellpower.
		Additionally, at raw talent level 3, gain Shield Bonus: Cleansing Rain (Gain regeneration as long as the shield is active).
		At raw talent level 5, gain Teleport Mode: Lightning Speed (Instead of teleporting, gain a significant amount of movespeed).]]):
		tformat(t.getResistPierce(self, t), t.getDamage(self, t), t.getChance(self, t) * t.getChanceMod(self, t), t.getIcestormDamage(self, t), t.getRadius(self, t), t.getDuration(self, t))
	end, 
}