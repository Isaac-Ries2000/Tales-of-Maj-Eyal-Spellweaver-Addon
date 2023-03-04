newTalentType{ type = "elemental/elemental-spellweaving", no_silence = true, is_spell = true, name = _t("elemental spellweaving", "talent type"), description = _t"These elementals may be mindless, but they wield magic as strong as even the most powerful Spellweaver." }

-- None of these have icons since it should be impossible to ever have them.

newTalent{
	name = "Raging Elements",
	short_name = "KAM_ELEMENTAL_RUINS_PARTICLES",
	type = {"elemental/elemental-spellweaving",1},
	points = 1,
	cant_steal = true,
	mode = "passive",
	makeParticles = function(self)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return false end
		local colorTable = {}
		ele.getElementColors(self, colorTable, t)
	end,
	on_learn = function(self, t)
		if not self.kamWildElementParticle then
			t.makeParticles(self)
		end
	end,
	callbackOnAct = function(self, t)
		if not self.kamWildElementParticle then
			t.makeParticles(self)
		end
	end,
	callbackOnDeath = function(self, t)
		if self.kamWildElementParticle then
			self:removeParticles(self.kamWildElementParticle)
		end
	end,
	info = function(self, t)
		local eleString
		if not self.kamElementalRuinsDamageType1 then
			eleString = [[Loading. If you see this, please report it.]]
		elseif self.kamElementalRuinsElement3 then
			eleString = ([[%s, %s, and %s]]).tformat((DamageType:get(self.kamElementalRuinsDamageType1).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType2).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType3).name.capitalize()))
		else
			eleString = ([[%s and %s]]).tformat((DamageType:get(self.kamElementalRuinsDamageType1).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType2).name.capitalize()))
		end
		return ([[These constructs are pure elemental magic, and as such, it fuels all they do.
		This elemental construct will use %s spells, and gains a 50%% resistance to each of those %s damage.]]):
		tformat(eleString, eleString)
	end,
}

newTalent{
	name = "Elemental Form",
	short_name = "KAM_ELEMENTAL_RUINS_MELEE",
	type = {"elemental/elemental-spellweaving",1},
	points = 1,
	cant_steal = true,
	mode = "passive",
	info = function(self, t)
		local eleString
		if not self.kamElementalRuinsDamageType1 then
			eleString = [[Loading. If you see this, please report it.]]
		elseif self.kamElementalRuinsElement3 then
			eleString = ([[%s, %s, and %s]]).tformat((DamageType:get(self.kamElementalRuinsDamageType1).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType2).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType3).name.capitalize()))
		else
			eleString = ([[%s and %s]]).tformat((DamageType:get(self.kamElementalRuinsDamageType1).name.capitalize()), (DamageType:get(self.kamElementalRuinsDamageType2).name.capitalize()))
		end
		return ([[These constructs are pure elemental magic, and as such, every strike they make is elementally charged.
		Your melee attacks deal a random mix of %s damage instead of the normal damage type.]]):
		tformat(eleString, eleString)
	end,
}

newTalentType{ type = "elemental/guardian_spellweaving", no_silence = true, is_spell = true, name = _t("guardian spellweaving", "talent type"), description = _t"This elemental protects its allies, defending and empowering them." }

newTalent{
	name = "Elemental Guardian - Aura",
	short_name = "KAM_ELEMENTAL_RUINS_SHIELDING_AURA",
	type = {"elemental/guardian_spellweaving",1},
	points = 5,
	cant_steal = true,
	random_ego = "defensive",
	mode = "sustained",
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 1
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 1.2
	end,
	getRadius = function(self, t)
		return 3
	end,
	callbackOnAct = function(self, t)
		local tg = {type="ball", range = 0, radius = t.getRadius(self, t), friendlyfire=true, talent=t}
		
		self:project(tg, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and self:reactionToward(target) > 0 and not target.kam_spellweavers_is_guardian_elemental then 
				target:setEffect(target.EFF_KAM_SPELLWEAVER_EL_RUINS_GUARDIAN_AURA, 2, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
			end
		end)
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamElementalRuinsDamageTalent1)
		if ele == nil then return [[kamElementalRuinsDamageTalent1 is nil. Please report this (with details).]] end
		local damage = t.getDamage(self, ele)
		return ([[The elemental aura out from this elemental shields its allies around it, protecting them from you and striking back at you when you strike them.
		Allies within radius 3, other than guardian elementals, gain Elemental Shielding, reducing damage dealt to them by %d%% and inflicting %d %s damage to enemies that damage them.]]):
		tformat(self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}

newTalent{
	name = "Elemental Guardian - Shield",
	short_name = "KAM_ELEMENTAL_RUINS_GUARDIAN_SHIELD",
	type = {"elemental/guardian_spellweaving",1},
	points = 5,
	cant_steal = true,
	random_ego = "defensive",
	mode = "sustained",
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 1
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 1.2
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamElementalRuinsDamageTalent1)
		if ele == nil then return [[kamElementalRuinsDamageTalent1 is nil. Please report this (with details).]] end
		local damage = t.getDamage(self, ele)
		return ([[This elemental seems to be able to manifest shields out of its element.
		When you take more than x%% of your life in one hit, instantly a shield that blocks %d damage, reflecting %d%% of any absorbed damage back as %s damage.]]):
		tformat(self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}

newTalent{
	name = "Elemental Guardian - Empowerment",
	short_name = "KAM_ELEMENTAL_RUINS_GUARDIAN_EMPOWER",
	type = {"elemental/guardian_spellweaving",1},
	points = 5,
	cant_steal = true,
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 1
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 1.2
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamElementalRuinsDamageTalent1)
		if ele == nil then return [[kamElementalRuinsDamageTalent1 is nil. Please report this (with details).]] end
		local damage = t.getDamage(self, ele)
		return ([[This elemental is able to empower its own allies with its element.
		Release an elemental wave, granting all of your allies %s empowerment, causing all of their melee damage and all elemental tree damage spells to deal an additional %d %s damage.]]):
		tformat(self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}