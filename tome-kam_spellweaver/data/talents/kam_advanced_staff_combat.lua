local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/advanced-staff-combat", no_silence = true, is_spell = true, name = _t("advanced staff combat", "talent type"), description = _t"As excellent conduits for magical power, staves make perfect devices for advanced Spellwoven techniques." }

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

-- Advanced Staff Combat alternate title: What If We Let Spellweavers Be Arcane Blades?
-- Components to add:
-- 	Retaliation Shield - Shield Bonus: Increase Frontline Spellweaver retaliation chance while shield is active.
--  Arcane Armor - Shield Mode: Don't gain shield, increase armor (and defense?). Still lasts for an amount of life though (but it's much bigger).
-- 	Defensive Teleportation - Teleport Bonus: Gain substantial armor and defense for a few turns.

-- A lot of this talent from Arcane Combat since it has a similar concept.
newTalent{ -- channel_staff
	name = "Advanced Staff Combat",
	short_name = "KAM_ASC_CORE",
	type = {"spellweaving/advanced-staff-combat", 1},
	mode = "sustained",
	points = 5,
	image = "talents/kam_spellweaver_advanced_staff_combat.png",
	tactical = { BUFF = 4 }, -- Always use.
--	image = "talents/channel_staff.png",
	require = spells_req_high1,
	no_sustain_autoreset = true,
	speed = "spell",
	cooldown = 10,
	getChance = function(self, t) 
		return self:combatLimit(self:getTalentLevel(t) * (1 + self:getMag(9, true)), 100, 20, 0, 70, 50) 
	end, -- From Arcane Combat, but scaling with Magic, since the way Spellweavers use it does not make sense with Cun. Maybe Willpower?
	canUseTalent = function(self, t, triggerTalent)
		local talent = self:getTalentFromId(triggerTalent)
		if not talent or not talent.isKamAttackSpell then return false end
		if not self:knowTalent(talent) then return false end
		if self.talents_cd[triggerTalent.id] then return false end -- Needs to NOT be on cooldown
		if not self:attr("force_talent_ignore_ressources") then
			-- Check all possible resource types and see if the talent has an associated cost
			for _, res_def in ipairs(self.resources_def) do
				local rname = res_def.short_name
				local cost = talent[rname]
				if cost then
					cost = (util.getval(cost, self, talent) or 0) * (util.getval(res_def.cost_factor, self, talent) or 1)
					if cost ~= 0 then
						local rmin, rmax = self[res_def.getMinFunction](self), self[res_def.getMaxFunction](self)
						-- Return false if we can't afford the talent cost
						if res_def.invert_values then
							if rmax and self[res_def.getFunction](self) + cost > rmax then
								return false
							end
						else
							if rmin and self[res_def.getFunction](self) - cost < rmin then
								return false
							end
						end
					end
				end
			end
		end
		return true
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype)
		local p = self:isTalentActive(t.id)
		if p and hitted then
			if self.x == target.x and self.y == target.y then return nil end
			if not ((KamCalc.isAllowWeapons(self)) or weapon.talented == "staff") then return nil end
			local mainhandIsStaff = self:getInven("MAINHAND")[1]
			local offhandIsStaff = self:getInven("OFFHAND")[1]
			
			local chance = t.getChance(self, t)
			
			if (self.kam_modify_asc_chance) then -- Used for 4th talent in tree, radiamarks, and the teleport mode from this tree.
				if self.kam_modify_asc_chance == -1 then
					chance = 100
				else 
					chance = chance * self.kam_modify_asc_chance
				end
			end
			
			if (KamCalc.isAllowWeapons(self)) then
				if self:hasShield() then 
					chance = chance * 0.5
				elseif self:hasDualWeapon() then 
					chance = chance * 0.5
				end
			else 
				if mainhandIsStaff and mainhandIsStaff.subtype == "staff" and offhandIsStaff and offhandIsStaff.subtype == "staff" then -- Curse you, short staves. This will barely ever come up.
					chance = chance * 0.5
				end
			end
					
			if rng.percent(chance) then
				local spells = {}
				-- Load previously selected spell
				
				if p and p.talent then
					local talent = self:getTalentFromId(p.talent)
					if t.canUseTalent(self, t, talent) then
						spells[1] = talent.id
					end
				end
				-- If no appropriate spell is selected, pick a random spell
				if #spells < 1 then
					for _, talent in pairs(self.talents_def) do
						if t.canUseTalent(self, t, talent) then
							spells[#spells+1] = talent.id
						end
					end
				end
				local tid = rng.table(spells)
				if tid then
					local target_x, target_y
					local talent = self:getTalentFromId(tid)
					if (talent.isKamASCBeam) then
						local l = self:lineFOV(target.x, target.y)
						l:set_corner_block()
						local lx, ly, is_corner_blocked = l:step(true)
						target_x, target_y = lx, ly
						-- Check for terrain
						while lx and ly and not is_corner_blocked and core.fov.distance(self.x, self.y, lx, ly) <= 10 do
							local actor = game.level.map(lx, ly, engine.Map.ACTOR)
							if game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, "block_move") then
								target_x, target_y = lx, ly
								break
							end
							target_x, target_y = lx, ly
							lx, ly = l:step(true)
						end
					elseif (talent.isKamASCExact) then
						target_x, target_y = target.x, target.y -- Just aim RIGHT at them
					elseif (talent.isKamASCSelf) then
						target_x, target_y = self.x, self.y
					elseif (talent.isKamASCRand) then
						target_x, target_y = self.x + rng.range(-10, 10), self.y + rng.range(-10, 10)
					end
					local oldStaffAccuracyBonus = self.__global_accuracy_damage_bonus
					if (oldStaffAccuracyBonus) then
						self.__global_accuracy_damage_bonus = ((self.__global_accuracy_damage_bonus - 1) / 2) + 1
					end
					self.__kam_asc_casting = true
					self:forceUseTalent(tid, {ignore_energy=true, force_target={x=target_x, y=target_y}})
					self.__kam_asc_casting = false
					self.talents_cd[tid] = (self:getTalentFromId(tid).cooldown) / 2
					if (oldStaffAccuracyBonus) then
						self.__global_accuracy_damage_bonus = oldStaffAccuracyBonus
					end
				end
			end
		end	
	end,
	activate = function(self, t)
		if self ~= game.player then return {} end
		local talent, use_random = self:talentDialog(require("mod.dialogs.talents.KamAdvancedStaffCombatTalentSelect").new(self))
		if use_random then
			return {}
		elseif talent then
			return {talent = talent}
		else
			return nil
		end
	end,
	deactivate = function(self, t, p)
		p.talent = nil
		return true
	end,
	info = function(self, t)
		local dualWieldText = "dual wielding staves" -- ... staffs?
		if (KamCalc.isAllowWeapons(self)) then
			dualWieldText = "dual wielding or using a shield"
		end
		return ([[Your mastery of Spellwoven magics works perfectly with your understanding of staves and how to fight with them.
		You gain a %d%% chance per melee staff hit to instantly cast one of your Spellwoven Attack spells on the target. The staff accuracy damage bonus to procs triggered this way will be halved.
		This does trigger the spell's cooldown, but the cooldown duration is halved.
		You can choose one talent for this to prioritize, but if that spell is on cooldown (or if no talent is selected), any one of your current Spellwoven Attack spells may be triggered instead.
		If you have no Spellwoven attack spells that are not on cooldown or you do not have enough mana, you will not be able to cast the spell, and nothing will happen. 
		While %s the chance is halved.
		The chance increases with your Magic.]]):
		tformat(t.getChance(self, t), dualWieldText)
	end,
}

newTalent{ -- staff_mastery
	name = "Staff Empowerment",
	short_name = "KAM_ASC_EMPOWERMENT",
	type = {"spellweaving/advanced-staff-combat", 2},
	require = spells_req_high2,
	image = "talents/kam_spellweaver_staff_empowerment.png",
--	image = "talents/staff_mastery.png", 
	points = 5,
	mode = "passive",
	getStatmult = function(self, t) return 1.07 + 0.3 * (self:getTalentLevel(t))^.5 end,
	info = function(self, t)
		local weaponText = "Staves"
		local lowerWeaponTextSingular = "a staff"
		local lowerWeaponText = "staves"
		if (KamCalc.isAllowWeapons(self)) then
			weaponText = "Your weapons"
			lowerWeaponText = "weapons you wield"
			lowerWeaponTextSingular = "your weapons"
		end
		return ([[%s are like any other magical tool: With a little better understanding, you can get much better results.
		By channeling your own magic through %s more effectively, the Magic damage multiplier on %s is increased by %d%%.]]):
		tformat(weaponText, lowerWeaponTextSingular, lowerWeaponText, (t.getStatmult(self, t) - 1) * 100)
	end,
	on_learn = function(self, t)
		self:attr("on_wear_simple_reload", 1)
		for i, o in ipairs(self:getInven("MAINHAND") or {}) do 
			self:onTakeoff(o, self.INVEN_MAINHAND, true) 
			self:onWear(o, self.INVEN_MAINHAND, true) 
		end
		for i, o in ipairs(self:getInven("OFFHAND") or {}) do 
			self:onTakeoff(o, self.INVEN_OFFHAND, true) 
			self:onWear(o, self.INVEN_OFFHAND, true) 
		end
		for i, o in ipairs(self:getInven("PSIONIC_FOCUS") or {}) do -- To my knowledge I don't think you can learn to do this on a non-psionic character, but it might be possible/added by another addon or something?
			self:onTakeoff(o, self.INVEN_PSIONIC_FOCUS, true) 
			self:onWear(o, self.INVEN_PSIONIC_FOCUS, true) 
		end
		self:attr("on_wear_simple_reload", -1)
	end,
	on_unlearn = function(self, t)
		self:attr("on_wear_simple_reload", 1)
		for i, o in ipairs(self:getInven("MAINHAND") or {}) do 
			self:onTakeoff(o, self.INVEN_MAINHAND, true) 
			self:onWear(o, self.INVEN_MAINHAND, true) 
		end
		for i, o in ipairs(self:getInven("OFFHAND") or {}) do 
			self:onTakeoff(o, self.INVEN_OFFHAND, true) 
			self:onWear(o, self.INVEN_OFFHAND, true) 
		end
		for i, o in ipairs(self:getInven("PSIONIC_FOCUS") or {}) do -- To my knowledge I don't think you can learn to do this on a non-psionic character, but it might be possible/added by another addon or something?
			self:onTakeoff(o, self.INVEN_PSIONIC_FOCUS, true) 
			self:onWear(o, self.INVEN_PSIONIC_FOCUS, true) 
		end
		self:attr("on_wear_simple_reload", -1)
	end,
	callbackOnTakeoff = function(self, t, obj)
		if (obj.__kam_staff_empowerment_data) then
			obj:tableTemporaryValuesRemove(obj.__kam_staff_empowerment_data)
		end
	end,
}

newTalent{ -- wizard-staff
	name = "Staff Resonance",
	short_name = "KAM_ASC_RESONANCE",
	type = {"spellweaving/advanced-staff-combat", 3},
	require = spells_req_high3,
	image = "talents/kam_spellweaver_staff_resonance.png",
--	image = "talents/staff_mastery.png", 
	points = 5,
	mode = "passive",
	getStatBoost = function(self, t)
		return math.floor(self:combatTalentSpellDamage(t, 4, 20)) -- Have some stats.
	end,
	getArmorDef = function(self, t)
		return math.floor(self:combatTalentSpellDamage(t, 3, 18))
	end,
	info = function(self, t) -- Originally required wearing a staff to get the benefit but you'll almost always be doing that anyways so why bother?
		local weaponText = "Staves"
		if (KamCalc.isAllowWeapons(self)) then
			weaponText = "Your weapons"
		end
		return ([[%s can do a lot more than just channel your magic to unleash power. By weaving your magic together with them, you can empower yourself, as well as your magic.
		Your Magic, Strength, Constitution, and Dexterity are increased by %d, and your armor and defense are increased by %d.
		These increases all increase with your Spellpower.]]):
		tformat(weaponText, t.getStatBoost(self, t), t.getArmorDef(self, t))
	end,
	passives = function(self, t, p)
		local statBoost = t.getStatBoost(self, t)
		self:talentTemporaryValue(p, "inc_stats", {
			[self.STAT_MAG] = statBoost,
			[self.STAT_STR] = statBoost,
			[self.STAT_CON] = statBoost,
			[self.STAT_DEX] = statBoost,
		})
		local armorDefBoost = t.getArmorDef(self, t)
		self:talentTemporaryValue(p, "combat_def", armorDefBoost)
		self:talentTemporaryValue(p, "combat_armor", armorDefBoost)
	end,
}

newTalent{ -- surrounded-shield
	name = "Frontline Spellweaver",
	short_name = "KAM_ASC_MASTERY",
	type = {"spellweaving/advanced-staff-combat", 4},
	require = spells_req_high4,
	image = "talents/kam_spellweaver_frontline_spellweaver.png",
--	image = "talents/staff_mastery.png", 
	points = 5,
	mode = "passive",
	no_unlearn_last = true,
	getAttackChance = function(self, t) -- This DOESN'T cancel damage so.
		local mult = 1
		local boostEff = self:hasEffect(self.EFF_KAM_FRONTLINE_COUNTERATTACK_BOOST)
		if boostEff then
			mult = mult * (1 + boostEff.power / 100)
		end
		return self:combatTalentLimit(self:getTalentLevel(t), 50, 10, 35, false, 1.0) * mult
	end,
	getDamageReduce = function(self, t)
		return self:combatTalentLimit(self:getTalentLevel(t), 40, 5, 29, false, 1.0) -- Damage reduction at 5 is an unreliable ~10%. Theoretical max is 20%.
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_SLASH_DASH)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_SLASH_DASH, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_SLASH_DASH)
		end
	end,
	info = function(self, t)
		local weaponText = "staff"
		if (KamCalc.isAllowWeapons(self)) then
			weaponText = "weapon"
		end
		return ([[Most Spellweavers are known to prefer the comfort of a library or study, or at least prefer being in the back during combat. For you, however, there's nowhere better to be than the front of the fight.
		While wielding a %s, when you are attacked in melee, you have a %d%% chance to counterattack, reducing damage by %d%% and making a free attack. The chance of Advanced Staff Combat spellcasting triggering on this attack is reduced to one third of the normal chance. You can only counterattack each target once per turn this way.
		At talent level 3, also gain Teleport Mode: Strikethrough (Teleport through a line of enemies and make a weak attack on each, always triggering an Advanced Staff Combat spellcasting trigger on the last target in the line).]]):
		tformat(weaponText, t.getAttackChance(self, t), t.getDamageReduce(self, t))
	end,
}