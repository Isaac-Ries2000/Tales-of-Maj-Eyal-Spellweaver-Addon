local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ generic = true, no_silence = true, is_spell = true, type = "spellweaving/runic-mastery", name = _t("runic mastery", "talent type"), description = _t"Anyone can use a rune, but with a little understanding of magic, you can get more out of one than anyone." }

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

-- This tree is literally all rune icons for the runic mastery tree (and it's entirely passives/sustains which helps), so they get to stay as themed ones.

local function countRunes(self) -- Counts runes and taints, including infusions if they are set to allowed.
	local count = 0
	for t_id, _ in pairs(self.talents) do
		local tal = self:getTalentFromId(t_id)
		if tal.is_inscription then
			if KamCalc:isAllowInscriptions(self) or tal.type[1] == "inscriptions/runes" or tal.type[1] == "inscriptions/taints" then
				count = count + 1 
			end
		end
	end
	return count
end
-- Everything in this talent can be set to include Infusions by adjusting KamCalc's function (for the Nature Class Evo). But not steamtech, because tinkers are good enough already.

newTalent{ -- Manasurge runes are dead. Now everything is a manasurge rune (and a max health increase).
	name = "Runic Restoration",
	short_name = "KAM_RUNIC_RESTORATION",
	type = {"spellweaving/runic-mastery", 1},
	require = spells_req_high1,
	image = "talents/rune__manasurge.png", -- I mean that's what it does.
	points = 5,
	mode = "passive",
	getMana = function(self, t) return self:combatTalentScale(t, 10, 40) end,
	getManaRegen = function(self, t) return self:combatTalentScale(t, 0.3, 1.2) end, -- It's multiplied by up to 5... (or 6 for ogres)
	getMaxHealth = function(self, t) return self:combatTalentScale(t, 2, 20) end, -- Not a huge amount but 10-100 on a talent seems real nice.
	callbackOnTalentPost = function(self, t, ab)
		if ab.type[1] == "inscriptions/runes" or ab.type[1] == "inscriptions/taints" or (ab.type[1] == "inscriptions/infusions" and KamCalc:isAllowInscriptions(self)) then
			self:incMana(t.getMana(self, t))
		end
	end,
	callbackOnTalentChange = function(self, t, tid, mode, lvldiff)
		if self:getTalentFromId(tid).is_inscription then 
			self:updateTalentPassives(t) 
		end
	end,
	passives = function(self, t, p)
		local runes = countRunes(self)
		if runes < 1 then return end -- I don't know why you would use this tree with no runes but here's that case.
		self:talentTemporaryValue(p, "mana_regen", t.getManaRegen(self, t) * runes)
		self:talentTemporaryValue(p, "max_life", t.getMaxHealth(self, t) * runes)
	end,

	info = function(self, t)
		local infusionText = ""
		local infusionTextOr = ""
		if (KamCalc:isAllowInscriptions(self)) then
			infusionText = " and Inscriptions"
			infusionTextOr = " or Inscription"
		end
		return ([[Runes%s are useful, but not perfectly efficient. However, in the hands of a skilled Spellweaver, you can put them to better use, fortifying your magic and yourself.
		Whenever you use a Rune%s, instantly regain %d mana. Additionally, passively gain %0.1f mana regeneration and %d max life for every Rune%s inscribed on you.]]):
		tformat(infusionText, infusionTextOr, t.getMana(self, t), t.getManaRegen(self, t), t.getMaxHealth(self, t), infusionTextOr)
	end,
}

newTalent{ 
	name = "Runic Adaption",
	short_name = "KAM_RUNIC_ADAPTION",
	type = {"spellweaving/runic-mastery", 2},
	require = spells_req_high2,
	image = "talents/rune__teleportation.png",
	points = 5,
	mode = "passive",
	getScalingBonus = function(self, t) 
		local bonus = self:combatTalentScale(t, 10, 30)
		if self:hasEffect(self.KAM_RUNIC_ADAPTION_SCALE_BOOST) then
			bonus = bonus * eff.power
		end
		return bonus
	end,
	callbackOnTalentChange = function(self, t, tid, mode, lvldiff)
		if self:getTalentFromId(tid).type[1] == "inscriptions/runes" or self:getTalentFromId(tid).type[1] == "inscriptions/taints" or (KamCalc:isAllowInscriptions(self) and self:getTalentFromId(tid).type[1] == "inscriptions/infusions") then 
			t.updateRunes(self, t)
		end
	end,
	updateRunes = function(self, t)
		if self:knowTalent(self.T_KAM_RUNIC_ADAPTION) then
			for name, insc in pairs(self.inscriptions_data) do
				if name:find("RUNE") or name:find("TAINT") or (KamCalc:isAllowInscriptions(self) and name:find("INFUSION")) then
					if insc.kam_altered_insc then
						insc.use_any_stat = insc.kam_old_use_any_stat
						insc.kam_old_use_any_stat = nil
					end
					if insc.use_stat then 
						insc.kam_old_use_any_stat = insc.use_any_stat
						insc.kam_altered_insc = true
						local mult = 1
						local adaptedAdaption = self:hasEffect(self.EFF_KAM_RUNIC_ADAPTION_SCALE_BOOST)
						if adaptedAdaption then
							mult = adaptedAdaption.power
						end
						insc.use_any_stat = 1 + (t.getScalingBonus(self, t) * mult) / 100
					end
				end
			end
		else
			for name, insc in pairs(self.inscriptions_data) do
				if insc.kam_altered_insc then
					insc.use_any_stat = insc.kam_old_use_any_stat
					insc.kam_old_use_any_stat = nil
				end
			end
		end
	end,
	on_learn = function(self, t)
		t.updateRunes(self, t)
	end,
	on_unlearn = function(self, t)
		t.updateRunes(self, t)
	end,
	passives = function(self, t, p)
	end,
	info = function(self, t)
		local infusionText = ""
		local infusionTextOr = ""
		if (KamCalc:isAllowInscriptions(self)) then
			infusionText = " and Inscriptions"
			infusionTextOr = " or Inscription"
		end
		return ([[Runes%s are tricky to work with, but Spellweaving techniques let you work with them to provide flexibility and increased power.
		Runes%s that scale with any stat instead now scale with your highest stat. Additionally, the scaling of runes%s is increased by %d%%.]]):
		tformat(infusionText, infusionText, infusionText, t.getScalingBonus(self, t))
	end,
}

newTalent{ -- Did someone say do nine million things but only one at a time? Yes, and it was me, unfortunately.
	name = "Runic Modification",
	short_name = "KAM_RUNIC_MODIFICATION",
	type = {"spellweaving/runic-mastery", 3},
	require = spells_req_high3,
	image = "talents/rune__invisibility.png", -- All of these are going to be rune ones for the aesthetic.
	points = 5,
	tactical = { BUFF = 2 },
	cooldown = 10,
	mode = "sustained",
	speed = "spell",
	-- Runes
	getAllRes = function(self, t) return math.ceil(self:combatTalentScale(t, 2, 8)) end,
	getPierce = function(self, t) return math.min(50, self:getTalentLevel(t) * 8) end,
	getInvisibilityPower = function(self, t) return math.ceil(self:combatTalentScale(t, 8, 30)) end,
	getConstitution = function(self, t) return math.ceil(self:combatTalentScale(t, 4, 13)) end, -- It's bad (that's intentional).
	getResPen = function(self, t) return math.ceil(self:combatTalentScale(t, 3, 15)) end,
	getArcaneDamage = function(self, t) return self:attr("max_mana") * self:combatTalentSpellDamage(t, 20, 44) / 100 end, -- Remember that manasurge runes are kinda useless now so.
	getDamageOnMeleeHit = function(self, t) return self:combatTalentSpellDamage(t, 5, 20) end,
	getDamageIncrease = function(self, t) return math.ceil(self:combatTalentScale(t, 3, 8)) end,
	getMovespeed = function(self, t) return math.ceil(self:combatTalentScale(t, 100, 330)) end,
	-- Infusions
	getHealModBonus = function(self, t) return math.ceil(self:combatTalentScale(t, 3, 15)) end,
	getDamageBlocks = function(self, t) -- Evidently this kind of effect is very good, so.
		if self:getTalentLevel(t) > 5 then
			return 2
		else
			return 1
		end
	end,
	getStunPinDazeRemoves = function(self, t) return math.floor(self:getTalentLevel(t) / 1.3 + 0.5) end,
	getDeathHealing = function(self, t) return self:combatTalentSpellDamage(t, 50, 250) end, 
	callbackOnTalentPost = function(self, t, ab)
		local p = self:isTalentActive(t.id)
		if p then
			if ab.type[1] == "inscriptions/runes" or ab.type[1] == "inscriptions/taints" then
				if ab.name == "Rune: Shielding" or ab.name == "Rune: Reflection Shield" then
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_SHIELD, 3, {power = t.getAllRes(self, t)})
				elseif ab.name == "Rune: Teleportation" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_TELEPORT, 2, {})
				elseif ab.name == "Rune: Blink" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_BLINK, 2, {power = t.getInvisibilityPower(self, t)})
				elseif ab.name == "Rune: Biting Gale" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_BITING_GALE, 3, {power = t.getPierce(self, t)})
				elseif ab.name == "Rune: Acid Wave" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_ACID_WAVE, 3, {power = t.getResPen(self, t)})
				elseif ab.name == "Rune: Manasurge" then 
					local tg = {type="ball", range=0, radius=3, friendlyfire = false, selffire = false}
					self:project(tg, self.x, self.y, DamageType.ARCANE, t.getArcaneDamage(self, t))
				elseif ab.name == "Rune: Ethereal" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_ETHEREAL, 1, {power = t.getMovespeed(self, t)})
				elseif ab.name == "Rune: Stormshield" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_STORMSHIELD, 3, {power = t.getDamageOnMeleeHit(self, t)})
				elseif ab.name == "Rune: Shatter Afflictions" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_SHATTER_AFFLICTIONS, 4, {power = t.getConstitution(self, t)})
				else 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_OTHER, 2, {power = t.getDamageIncrease(self, t)})
				end
			elseif KamCalc:isAllowInscriptions(self) and ab.type[1] == "inscriptions/infusions" then
				if ab.name == "Infusion: Regeneration" then
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_REGENERATION, 3, {power = t.getHealModBonus(self, t)})
				elseif ab.name == "Infusion: Healing" then 
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEALING, 3, {power = t.getDamageBlocks(self, t)})
				elseif ab.name == "Infusion: Movement" then 
					local effs = {}
					for eff_id, p in pairs(self.tmp) do
						local e = self.tempeffect_def[eff_id]
						if e and (e.subtype.stun or e.subtype.pin) and (e.status == "detrimental") then
							effs[#effs+1] = eff_id
						end
					end
					effs = rng.tableSample(effs, t.getStunPinDazeRemoves(self, t))
					for _, eff_id in ipairs(effs) do
						if not check_remove or check_remove(self, eff_id) then
							self:dispel(eff_id, self, false, {force=false, silent=false})
						end
					end
				elseif ab.name == "Infusion: Heroism" then 
					if (not self:hasEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEROISM_COOLDOWN)) then
						self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEROISM, 3, {power = t.getDamageBlocks(self, t)})
					end
				elseif ab.name == "Infusion: Wild" then -- Because Wild Infusion deserves better.
					self:removeEffectsFilter(self, {status="detrimental"}, 1)
				else
					self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_OTHER_INFUSION, 4, {power = t.getAllRes(self, t)})
				end
			end
		end
	end, 
	callbackPriorities={callbackOnHit = -100},  -- Heroism-second life should occur VERY early
	callbackOnHit = function(self, t, cb)
		local eff = self:hasEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEROISM)
		if eff and cb.value >= self.life then
			cb.value = 0
			self.life = 1
			self:setEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEROISM_COOLDOWN, 50, {})
			local heal = self:heal(eff.power, self)
			game.logSeen(self, "#YELLOW#%s does not falter!#LAST#", self:getName())
			if heal > 0 then -- You can get an achievement. Fancy. 
				if self.player then
					world:gainAchievement("AVOID_DEATH", self)
				end
			end
			return 0
		end
	end,
	info = function(self, t)
		local infusionText = ""
		local infusionTextOr = ""
		if (KamCalc:isAllowInscriptions(self)) then
			infusionText = " and Inscriptions"
			infusionTextOr = " or Inscription"
		end -- Shatter Afflictions gives constitution because I feel like it's already pretttty good. So it gets something bad and silly.
		local fullInfusionText = ""
		if (KamCalc:isAllowInscriptions(self)) then -- ... so I only really play ghoul and don't actually know how good any of the infusions are.
			fullInfusionText = ([[
			
			Infusions also benefit from this:
			Regeneration: Your healing mod is increased by %d%% for 3 turns.
			Healing: For the next 3 turns, block the next %d instances of damage that deal at least 50 damage that you would take.
			Wild: After the infusion resolves, remove one additional random detrimental effect of any type.
			Movement: Remove %d random stuns, pins, or dazes.
			Heroism: For the next 4 turns, if an attack would reduce your life below 1, prevent that damage, set your life to 1, then heal for %d (scaling with Spellpower). This can only trigger once every 50 turns.
			Other (including artifact infusions): Gain %d all resistance for 4 turns.]]):
			tformat(t.getHealModBonus(self, t), t.getDamageBlocks(self, t), t.getStunPinDazeRemoves(self, t), t.getDeathHealing(self, t), t.getAllRes(self, t))
		end
		return ([[With a little extra mana in, Runes%s can do a lot more. 
		After you use a Rune%s, trigger the effect corresponding to the Rune%s used:
		Shielding (including the Rune of Reflection): Gain %d%% all resistance for 3 turns.
		Blink: Become invisible (power %d) for 2 turns.
		Shatter Afflictions: Gain %d Constitution for 4 turns.
		Teleportation: You gain immunity to damage, but you cannot deal damage for 2 turns.
		Biting Gale: You gain %d%% iceblock penetration for 3 turns.
		Acid Wave: You gain %d%% all resistance penetration for 3 turns.
		Manasurge: Deal %d Arcane damage in radius 3, increasing with Spellpower and maximum mana.
		Ethereal: Gain %d%% movespeed for 1 turn.
		Stormshield: Gain %d Lightning melee retaliation for 3 turns, increasing with Spellpower.
		Other (including artifact runes): Gain %d%% increased damage for 2 turns.%s]]):
		tformat(infusionText, infusionTextOr, infusionTextOr, t.getAllRes(self, t), t.getInvisibilityPower(self, t), t.getConstitution(self, t), t.getPierce(self, t), 
		t.getResPen(self, t), t.getArcaneDamage(self, t), t.getMovespeed(self, t), t.getDamageOnMeleeHit(self, t), t.getDamageIncrease(self, t), fullInfusionText)
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		return {}
	end,
	deactivate = function(self, t, p)
		return true
	end,
}

newTalent{ 
	name = "Runic Perfection",
	short_name = "KAM_RUNIC_MASTERY",
	type = {"spellweaving/runic-mastery", 4},
	require = spells_req_high4,
	image = "talents/rune__vision.png", -- rune__vision is now unused but.
	points = 5,
	mode = "passive",
	getSpellweaveMod = function(self, t) return self:combatTalentScale(t, 105, 115) / 100 end,
	callbackOnTalentPost = function(self, t, ab)
		if ab.type[1] == "inscriptions/runes" or ab.type[1] == "inscriptions/taints" or (KamCalc:isAllowInscriptions(self) and ab.type[1] == "inscriptions/infusions") then
			self:setEffect(self.EFF_KAM_SPELLWEAVER_RUNIC_EMPOWERMENT, 2, {powerMod = t.getSpellweaveMod(self, t)})
		end
	end,
	info = function(self, t)
		local infusionText = ""
		local infusionTextOr = ""
		local infusionSaturationText = ""
		if (KamCalc:isAllowInscriptions(self)) then
			infusionText = " and Inscriptions"
			infusionTextOr = " or Inscription"
			infusionSaturationText = " or Infusion Saturation"
		end
		return ([[You understand how to use Runes%s better than just about anyone.
		While you have Runic Saturation%s, the cooldown increase only triggers every other Rune%s you activate, also, whenever you activate a Rune%s, gain a %0.2f Spellweave Multiplier bonus to the next Spellwoven spell you cast for the next two turns. This effect stacks, refreshing its duration and increasing the Spellweave Multiplier bonus additively for each Rune%s used.]]):
		tformat(infusionText, infusionSaturationText, infusionTextOr, infusionTextOr, t.getSpellweaveMod(self, t), infusionTextOr)
	end,
}
-- Cut (For further consideration): gain a %d%% chance to reduce the cooldown of one Inscription with a different skill by one turn and 