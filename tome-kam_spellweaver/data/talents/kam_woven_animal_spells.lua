newTalentType{ type = "spellweaving/wild-spellweaving", no_silence = true, is_spell = true, name = _t("wild spellweaving", "talent type"), description = _t"Kia's Spellwoven animals appear to have gained the ability to Spellweave. Oh dear." }

-- None of these have icons since it should be impossible to ever have them. If you multi-class challenge possessor over or something maybe, but that's a you problem as stands (they'll all break if you do that anyways).

-- Doesn't actually do provide resistances or anything, just a flavour + particles talent.
newTalent{
	name = "Wild Elements",
	short_name = "KAM_KIA_ANIMAL_PARTICLES",
	type = {"spellweaving/wild-spellweaving",1},
	points = 5,
	random_ego = "attack",
	mode = "passive",
	makeParticles = function(self)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return false end
		local colorTable = {}
		ele.getElementColors(self, colorTable, t)
		self.kamWildElementParticle = self:addParticles(Particles.new("kam_spellweaver_wild_element", 1, colorTable))
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
		local resists = self.kamWildElementResistText
		if resists == nil then return [[ERROR: kamWildElementResistText is nil]] end
		return ([[Kia has been working on weaving actual life out of magic, creating Spellwoven animals that are nearly indistinguishable from regular animals.
		... that they are wreathed in destructive elemental energy is probably unintentional, however.
		This animal gains 50%% %s resistance, but its %s resistance is lowered by 100%%. Additionally, it will use the %s element for its spells.]]):
		tformat(resists[1], resists[2], resists[1])
	end,
}

newTalent{
	name = "Elemental Beam",
	short_name = "KAM_KIA_ANIMAL_BEAM",
	type = {"spellweaving/wild-spellweaving",1},
	points = 5,
	random_ego = "attack",
	mana = 12,
	requires_target = true,
	cooldown = 5,
	tactical = { ATTACK = 2 },
	range = 7,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 1
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 1.2
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return true end

		local argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), talent = t}
		self:project(tg, x, y, DamageType.KAM_SPELLWEAVE_MANAGER, argsTable)
		
		local _ _, x, y = self:canProject(tg, x, y)
		
		local colorTable = {tx=x-self.x, ty=y-self.y}
		ele.getElementColors(self, colorTable, t)
		game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", colorTable)	

		return true
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return [[ERROR: kamWildElement is nil]] end
		local damage = t.getDamage(self, ele)
		return ([[This animal appears to be able to cast a basic beam spell with its element (although it lacks the skill of a proper Spellweaver and can hit other animals with it).
		Blast a target with a Spellwoven beam, dealing %d %s damage. %s.
		Each animal will deal its respective element and potentially inflict the associated Spellwoven debuff.]]):
		tformat(self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}

newTalent{
	name = "Elemental Field",
	short_name = "KAM_KIA_ANIMAL_AOE",
	type = {"spellweaving/wild-spellweaving", 1},
	points = 5,
	mode = "passive",
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 0.3
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 0.35
	end,
	getRadius = function(self, ele)
		return 3
	end,
	callbackOnActBase = function(self, t)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return true end
		local tg = {type = "ball", radius = t.getRadius(self, t), range = 0, talent = t, friendlyfire = false, selffire = false}
		local argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = t}
		self:project(tg, self.x, self.y, DamageType.KAM_SPELLWEAVE_MANAGER, argsTable)
		
		local colorTable = {tx=self.x, ty=self.y, radius=2, density = 0.3}
		ele.getElementColors(self, colorTable, t)
--		game.level.map:particleEmitter(x, y, 2, "kam_spellweaver_ball_physical", colorTable)
		
		return true
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return [[ERROR: kamWildElement is nil]] end
		local damage = t.getDamage(self, ele)
		return ([[This Spellwoven animal is wreathed in an elemental field, harming nearby enemies.
		Enemies within range %d take %d %s damage each turn. %s
		Each animal will deal its respective element and potentially inflict the associated Spellwoven debuff.]]):
		tformat(t.getRadius(self, t), self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}

newTalent{
	name = "Elemental Claws",
	short_name = "KAM_KIA_ANIMAL_MELEE",
	type = {"spellweaving/wild-spellweaving",1},
	points = 5,
	mode = "passive",
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 0.4
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 0.5
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return false end
		if self.x == target.x and self.y == target.y then return nil end
		local argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = t}
		self:project({type = "hit"}, target.x, target.y, DamageType.KAM_SPELLWEAVE_MANAGER, argsTable)
		
		local colorTable = {tx=target.x-self.x, ty=target.y-self.y, radius=0.4, density = 1}
		ele.getElementColors(self, colorTable, t)
		game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)

		return true
	end,
	info = function(self, t)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return [[ERROR: kamWildElement is nil]] end
		local damage = t.getDamage(self, ele)
		return ([[This animal appears to be enhancing its teeth and claws with Spellweaving.
		When you melee attack, your target takes an additional %d %s damage. %s.
		Each animal will deal its respective element and potentially inflict the associated Spellwoven debuff.]]):
		tformat(self:damDesc(ele.getElement(self, ele), damage), ele.getSpellElementInfo, ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
	end,
}

newTalentType{ type = "spellweaving/construct-controller", no_silence = true, is_spell = true, name = _t("construct controller", "talent type"), description = _t"Was this construct supposed to be able to do all of this...?" }

local basicElements = {
	{
		elementTalent = "T_KAM_ELEMENT_FLAME",
	},
	{
		elementTalent = "T_KAM_ELEMENT_COLD",
	},
	{
		elementTalent = "T_KAM_ELEMENT_LIGHTNING",
	},
	{
		elementTalent = "T_KAM_ELEMENT_PHYSICAL",
	},
	{
		elementTalent = "T_KAM_ELEMENT_LIGHT",
	},
	{
		elementTalent = "T_KAM_ELEMENT_DARKNESS",
	},
	{
		elementTalent = "T_KAM_ELEMENT_ARCANE",
	},
	{
		elementTalent = "T_KAM_ELEMENT_TEMPORAL",
	},
	{
		elementTalent = "T_KAM_ELEMENT_BLIGHT",
	},
	{
		elementTalent = "T_KAM_ELEMENT_ACID",
	}
}

local advancedElements = {
	{
		elementTalent = "T_KAM_ELEMENT_ECLIPSE", -- LIGHT/DARK
		elementOne = "T_KAM_ELEMENT_LIGHT",
		elementTwo = "T_KAM_ELEMENT_DARKNESS",
	},
	{
		elementTalent = "T_KAM_ELEMENT_GRAVECHILL", -- DARK/COLD
		elementOne = "T_KAM_ELEMENT_DARKNESS",
		elementTwo = "T_KAM_ELEMENT_COLD",
	},
	{
		elementTalent = "T_KAM_ELEMENT_WIND_AND_RAIN", -- COLD/LIGHTNING
		elementOne = "T_KAM_ELEMENT_COLD",
		elementTwo = "T_KAM_ELEMENT_LIGHTNING",
	},
	{
		elementTalent = "T_KAM_ELEMENT_MANASTORM", -- LIGHTNING/ARCANE
		elementOne = "T_KAM_ELEMENT_LIGHTNING",
		elementTwo = "T_KAM_ELEMENT_ARCANE",
	},
	{
		elementTalent = "T_KAM_ELEMENT_OTHERWORLDLY", -- ARCANE/TEMPORAL
		elementOne = "T_KAM_ELEMENT_ARCANE",
		elementTwo = "T_KAM_ELEMENT_TEMPORAL",
	},
	{
		elementTalent = "T_KAM_ELEMENT_GRAVITY", -- TEMPORAL/PHYSICAL
		elementOne = "T_KAM_ELEMENT_TEMPORAL",
		elementTwo = "T_KAM_ELEMENT_PHYSICAL",
	},
	{
		elementTalent = "T_KAM_ELEMENT_MOLTEN", -- PHYSICAL/FIRE
		elementOne = "T_KAM_ELEMENT_PHYSICAL",
		elementTwo = "T_KAM_ELEMENT_FLAME",
	},
	{
		elementTalent = "T_KAM_ELEMENT_FEVER", -- FIRE/BLIGHT
		elementOne = "T_KAM_ELEMENT_FLAME",
		elementTwo = "T_KAM_ELEMENT_BLIGHT",
	},
	{
		elementTalent = "T_KAM_ELEMENT_RUIN", -- BLIGHT/ACID
		elementOne = "T_KAM_ELEMENT_BLIGHT",
		elementTwo = "T_KAM_ELEMENT_ACID",
	},
	{
		elementTalent = "T_KAM_ELEMENT_CORRODING_BRILLIANCE", -- ACID/LIGHT
		elementOne = "T_KAM_ELEMENT_ACID",
		elementTwo = "T_KAM_ELEMENT_LIGHT",
	},
}

-- TODO: Alternate Version for future boss: Elemental Tyranny - All resistances are increased to 100, adds a Zonewide effect setting resistance piercing cap to 0. Only way to deal damage is to hit it in the weaknesses.
newTalent{
	name = "Elemental Reconfiguration",
	short_name = "KAM_KIA_CONSTRUCT_SHUFFLE",
	type = {"spellweaving/construct-controller",1},
	points = 1,
	mode = "passive",
	on_learn = function(self, t)
		local e = self:hasEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE)
		if not e then
			t.setElements(self, t)
		end
	end,
	callbackOnAct = function(self, t)
		local e = self:hasEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE)
--		if not self.kam_triggered_on_low and (self.life < self.max_life / 10) then
--			self.kam_triggered_on_low = true
--			t.setElements(self, t)
		if not self.kam_triggered_halfway and (self.life < self.max_life / 2) then -- elseif if prismatic is to be reenabled.
			self.kam_triggered_halfway = true
			t.setElements(self, t)
		elseif not e then
			t.setElements(self, t)
		end
	end,
	makeParticles = function(self)
		local ele = self:getTalentFromId(self.kamWildElement)
		if ele == nil then return false end
		local colorTable = {}
		ele.getElementColors(self, colorTable, t)
		self.kamWildElementParticle = self:addParticles(Particles.new("kam_spellweaver_wild_element", 1, colorTable))
	end,
	setElements = function(self, t)
		local e = self:hasEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE)
		if e then
			self:removeEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE, true, true)
			return
		end
--		if (self.life < self.max_life / 10) then
--			self:setEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE, 5, {isPrismatic = true, resistPower = 50})
--			self.kam_controller_construct_element_only = "T_KAM_ELEMENT_PRISMA"
		if (self.life > self.max_life / 2) then -- elseif if prismatic is reenabled
			local elements = {-1, -1, -1, -1}
			elements[1] = rng.range(1, 10)
			for i = 2, 4 do
				local failed = true
				while failed do
					failed = false
					elements[i] = rng.range(1, 10)
					for i2 = 1, i - 1 do
						if elements[i] == elements[i2] then
							failed = true
						end
					end
				end
			end
			local element1 = self:getTalentFromId(basicElements[elements[1]].elementTalent)
			local element2 = self:getTalentFromId(basicElements[elements[2]].elementTalent)
			
			if self.kamControllerElementParticleOne then
				self:removeParticles(self.kamControllerElementParticleOne)
			end
			if self.kamControllerElementParticleTwo then
				self:removeParticles(self.kamControllerElementParticleTwo)
			end
			local colorTable = {density = 0.6}
			element1.getElementColors(self, colorTable, element1)
			self.kamControllerElementParticleOne = self:addParticles(Particles.new("kam_spellweaver_wild_element", 1, colorTable))
			colorTable = {density = 0.6}
			element2.getElementColors(self, colorTable, element2)
			self.kamControllerElementParticleTwo = self:addParticles(Particles.new("kam_spellweaver_wild_element", 1, colorTable))

			self.kam_controller_construct_element1 = basicElements[elements[1]].elementTalent
			self.kam_controller_construct_element2 = basicElements[elements[2]].elementTalent
			self.kam_controller_construct_element_only = nil -- If it heals up (namely through player death or I guess theoretically Fever), this gets odd otherwise.
			self.kam_triggered_halfway = false
			
			local element3 = self:getTalentFromId(basicElements[elements[3]].elementTalent)
			local element4 = self:getTalentFromId(basicElements[elements[4]].elementTalent)
			
			local damtype1 = element1.getElement(self, element1)
			local damtype2 = element2.getElement(self, element2)
			local damtype3 = element3.getElement(self, element3)
			local damtype4 = element4.getElement(self, element4)
			
			damtype1 = (DamageType:get(damtype1)).kamUnderlyingElement or damtype1
			damtype2 = (DamageType:get(damtype2)).kamUnderlyingElement or damtype2
			damtype3 = (DamageType:get(damtype3)).kamUnderlyingElement or damtype3
			damtype4 = (DamageType:get(damtype4)).kamUnderlyingElement or damtype4

			self:setEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE, 5, {resist1 = damtype1, resist2 = damtype2, weakness1 = damtype3, weakness2 = damtype4, resistPower = 50, weaknessPower = 50})
		else
			local elements = {-1, -1}
			elements[1] = rng.range(1, 10)
			local check = true
			while check do
				elements[2] = rng.range(1, 10)
				if math.abs(elements[1] - elements[2]) > 1 and math.abs(elements[1] - elements[2]) ~= 9 then
					check = false
				end
			end
			local element1 = self:getTalentFromId(advancedElements[elements[1]].elementTalent)
			self.kam_controller_construct_element_only = advancedElements[elements[1]].elementTalent
			
			if self.kamControllerElementParticleOne then
				self:removeParticles(self.kamControllerElementParticleOne)
			end
			if self.kamControllerElementParticleTwo then
				self:removeParticles(self.kamControllerElementParticleTwo)
			end
			local colorTable = {}
			element1.getElementColors(self, colorTable, element1)
			self.kamControllerElementParticleOne = self:addParticles(Particles.new("kam_spellweaver_wild_element", 1, colorTable))
			
			local element2 = self:getTalentFromId(advancedElements[elements[2]].elementTalent)
			local resist1, resist2 = element1.getKamDoubleElements()
			local weakness1, weakness2 = element2.getKamDoubleElements()
			self:setEffect(self.EFF_KAM_CONSTRUCT_CONTROLLER_RECONFIGURE, 5, {resist1 = resist1, resist2 = resist2, weakness1 = weakness1, weakness2 = weakness2, resistPower = 50, weaknessPower = 50})
		end
	end,
	info = function(self, t)
		local elementString
		if self.kam_controller_construct_element_only ~= nil then
			local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
			if ele ~= nil then
				elementString = ele.name
			end
		end
		if self.kam_controller_construct_element1 ~= nil then
			local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
			local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
			if ele1 ~= nil then
				elementString = ele1.name.." and "..ele2.name
			end
		end
		if not elementString then
			elementString = "None"
		end
		return ([[The Controller Construct appears to be linked with every Spellweaving element. However, it does not seem intelligent at all, and is just using them completely randomly.
		Every 5 turns, the Controller Construct reconfigures, granting it 2 random resistances and 2 random weakness (all from among the Spellweaving element talents that the construct knows) and changing its damage and status effect types to the types of the resistances.
		If the Controller Construct is at 50%% or less life, those resistances and weaknesses are randomly chosen from the dual elements that the Construct has access to and that dual element damage type and status effect is used instead.
		Current Elements: %s]]):tformat(elementString)
--		If the Controller Construct is at 10%% or less life, it instead gains Prismatic damage and a significant resistance to all elements. -- Cut for unnecessary compication reasons
	end,
}

newTalent{
	name = "Elemental Charge",
	short_name = "KAM_KIA_CONSTRUCT_MELEE",
	type = {"spellweaving/construct-controller",1},
	points = 1,
	mode = "passive",
	getDamage = function(self, ele)
		local multiplier = 1
		if self.kam_construct_increase_elemental_charge_damage then
			multiplier = self.kam_construct_increase_elemental_charge_damage
		end
		return ele.getElementDamage(self, ele) * 0.35 * multiplier
	end,
	getStatusChange = function(self, ele)
		local multiplier = 1
		if self.kam_construct_increase_elemental_charge_damage then
			multiplier = self.kam_construct_increase_elemental_charge_damage
		end
		return ele.getStatusChance(self, ele) * 0.4 * multiplier
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype)
		if self.x == target.x and self.y == target.y then return nil end
		local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
		local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
		local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
		local argsTable
		local damageHandler
		if ele then
			argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = t}
			damageHandler = DamageType.KAM_SPELLWEAVE_MANAGER
		else
			damageHandler = DamageType.KAM_SPELLWEAVE_DUO_MANAGER
			argsTable = {dam11 = t.getDamage(self, ele1), dam12 = t.getDamage(self, ele2), statusChance11 = t.getStatusChange(self, ele1), statusChance12 = t.getStatusChange(self, ele2), element11 = ele1.getElement(self, ele1), element12 = ele2.getElement(self, ele2), second11 = ele1.getSecond(self, ele1), second12 = ele2.getSecond(self, ele2), friendlyfire = false, selffire = false, talent = t}
		end
		if not argsTable or not damageHandler then
			print("[KAM CONTROLLER CONSTRUCT] Construct did not have element when benefiting from Elemental Charge.")
			return false
		end
		self:project({type = "hit"}, target.x, target.y, damageHandler, argsTable)
		if ele then
			local colorTable = {tx=self.x, ty=self.y, radius=0.4, density = 1}
			ele.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
		else
			local colorTable = {tx=self.x, ty=self.y, radius=0.4, density = 0.5}
			ele1.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
			colorTable = {tx=self.x, ty=self.y, radius=0.4, density = 0.5}
			ele2.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
		end
		return true
	end,
	info = function(self, t)
		local elementString
		if self.kam_controller_construct_element_only then
			local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
			local damage = t.getDamage(self, ele)
--			if self.kam_controller_construct_element_only == "T_KAM_ELEMENT_PRISMA" then
--				elementString = ""..self:damDesc(ele.getElement(self, ele), damage).." damage, divided between all 10 Spellwoven elements. This damage has a chance to inflict any Spellwoven debuff."
--			else
			local ele1, ele2 = ele.getKamDoubleElements()
			elementString = ([[%d %s damage (equally split between %s and %s damage). %s.]]):
				tformat(self:damDesc(ele.getElement(self, ele), damage), ele.name, DamageType:get(ele1).name:capitalize(), DamageType:get(ele2).name:capitalize(), ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
--			end
		elseif self.kam_controller_construct_element1 then
			local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
			local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
			local damage1 = t.getDamage(self, ele1) / 2
			local damage2 = t.getDamage(self, ele2) / 2
			elementString = ([[%d %s and %d %s damage. %s.]]):
				tformat(self:damDesc(ele1.getElement(self, ele1), damage1), DamageType:get(ele1.getElement(self, ele1)).name:capitalize(), self:damDesc(ele2.getElement(self, ele2), damage2), DamageType:get(ele2.getElement(self, ele2)).name:capitalize(), ele1.getSpellStatusInflict(self, ele1, t.getStatusChange(self, ele1) / 2, false, true).." "..ele2.getSpellStatusInflict(self, ele2, t.getStatusChange(self, ele2) / 2, true, false))
		end
		if not elementString then
			elementString = "No element is currently active."
		end
		return ([[The construct's strikes appear to be full of elemental force.
		When you melee attack, your target takes an additional damage and has a chance to gain negative status effects based on your current configured element.
		Currently: %s.]]):tformat(elementString)
	end,
}

newTalent{
	name = "Elemental Overflow",
	short_name = "KAM_KIA_CONSTRUCT_LINGERING",
	type = {"spellweaving/construct-controller",1},
	points = 1,
	random_ego = "attack",
	cooldown = 10,
	tactical = { ATTACK = 3 },
	range = 0,
	radius = 10,
--	tactical = {DEFEND = 1, -- Extremely likely to use at close range, very low at far.
--		ATTACKAREA = function(self, t, target) 
--			return math.max(1, 5 - core.fov.distance(self.x, self.y, target.x, target.y) / 1.5)
--		end,
--		ATTACK = function(self, t, target) 
--			return math.max(0.5, 5 - core.fov.distance(self.x, self.y, target.x, target.y))
--		end,
--	},
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius = 10, talent=t, friendlyfire = false, selffire = false}
	end,
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 0.25
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 0.3
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
		local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
		local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
		local argsTable
		local damageHandler
		if ele then
			argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = t}
			damageHandler = DamageType.KAM_SPELLWEAVE_MANAGER
		else
			damageHandler = DamageType.KAM_SPELLWEAVE_DUO_MANAGER
			argsTable = {dam11 = t.getDamage(self, ele1), dam12 = t.getDamage(self, ele2), statusChance11 = t.getStatusChange(self, ele1), statusChance12 = t.getStatusChange(self, ele2), element11 = ele1.getElement(self, ele1), element12 = ele2.getElement(self, ele2), second11 = ele1.getSecond(self, ele1), second12 = ele2.getSecond(self, ele2), friendlyfire = false, selffire = false, talent = t}
		end
		if not argsTable or not damageHandler then
			print("[KAM CONTROLLER CONSTRUCT] Construct did not have element when using Elemental Overflow.")
			return false
		end
		
		game.log("The Controller Construct unleashes elemental energies!")
		
		local colorTable, colorTable1, colorTable2
		if ele then
			colorTable = {tx=self.x, ty=self.y, radius=10, density = 0.5}
			ele.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(self.x, self.y, 10, "kam_spellweaver_ball_physical", colorTable)
		else
			colorTable1 = {tx=self.x, ty=self.y, radius=10, density = 0.25}
			ele1.getElementColors(self, colorTable1, t)
			game.level.map:particleEmitter(self.x, self.y, 10, "kam_spellweaver_ball_physical", colorTable1)
			colorTable2 = {tx=self.x, ty=self.y, radius=10, density = 0.25}
			ele2.getElementColors(self, colorTable2, t)
			game.level.map:particleEmitter(self.x, self.y, 10, "kam_spellweaver_ball_physical", colorTable2)
		end

		local lingeringTilesFunction = function(px, py, tg, self)
			local closeness = 10 - core.fov.distance(self.x, self.y, px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if (rng.range(1,100) <= 100 * (closeness / 10) ^ 2) or (closeness < 7 and (target and self:reactionToward(target) < 0)) then
				local color_br 
				local color_bg
				local color_bb
				if colorTable then
					if not colorTable.colorATopAlt or (rng.percent(50)) then
						color_br = (rng.range(colorTable.colorRLow, colorTable.colorRTop))
						color_bg = (rng.range(colorTable.colorGLow, colorTable.colorGTop))
						color_bb = (rng.range(colorTable.colorBLow, colorTable.colorBTop))
					else
						color_br = (rng.range(colorTable.colorRLowAlt, colorTable.colorRTopAlt))
						color_bg = (rng.range(colorTable.colorGLowAlt, colorTable.colorGTopAlt))
						color_bb = (rng.range(colorTable.colorBLowAlt, colorTable.colorBTopAlt))
					end
				else
					local chanceSet = rng.range(1,100)
					if chanceSet <= 34 then
						if not colorTable1.colorATopAlt or (rng.percent(50)) then
							color_br = (rng.range(colorTable1.colorRLow, colorTable1.colorRTop))
							color_bg = (rng.range(colorTable1.colorGLow, colorTable1.colorGTop))
							color_bb = (rng.range(colorTable1.colorBLow, colorTable1.colorBTop))
						else
							color_br = (rng.range(colorTable1.colorRLowAlt, colorTable1.colorRTopAlt))
							color_bg = (rng.range(colorTable1.colorGLowAlt, colorTable1.colorGTopAlt))
							color_bb = (rng.range(colorTable1.colorBLowAlt, colorTable1.colorBTopAlt))
						end
					elseif chanceSet <= 67 then
						if not colorTable2.colorATopAlt or (rng.percent(50)) then
							color_br = (rng.range(colorTable2.colorRLow, colorTable2.colorRTop))
							color_bg = (rng.range(colorTable2.colorGLow, colorTable2.colorGTop))
							color_bb = (rng.range(colorTable2.colorBLow, colorTable2.colorBTop))
						else
							color_br = (rng.range(colorTable2.colorRLowAlt, colorTable2.colorRTopAlt))
							color_bg = (rng.range(colorTable2.colorGLowAlt, colorTable2.colorGTopAlt))
							color_bb = (rng.range(colorTable2.colorBLowAlt, colorTable2.colorBTopAlt))
						end
					else
						if not colorTable1.colorATopAlt or (rng.range(1,2) == 1) then
							color_br = (rng.range(colorTable1.colorRLow, colorTable1.colorRTop))
							color_bg = (rng.range(colorTable1.colorGLow, colorTable1.colorGTop))
							color_bb = (rng.range(colorTable1.colorBLow, colorTable1.colorBTop))
						else
							color_br = (rng.range(colorTable1.colorRLowAlt, colorTable1.colorRTopAlt))
							color_bg = (rng.range(colorTable1.colorGLowAlt, colorTable1.colorGTopAlt))
							color_bb = (rng.range(colorTable1.colorBLowAlt, colorTable1.colorBTopAlt))
						end
						if not colorTable2.colorATopAlt or (rng.range(1,2) == 1) then
							color_br = color_br + (rng.range(colorTable2.colorRLow, colorTable2.colorRTop))
							color_bg = color_bg + (rng.range(colorTable2.colorGLow, colorTable2.colorGTop))
							color_bb = color_bb + (rng.range(colorTable2.colorBLow, colorTable2.colorBTop))
						else
							color_br = color_br + (rng.range(colorTable2.colorRLowAlt, colorTable2.colorRTopAlt))
							color_bg = color_bg + (rng.range(colorTable2.colorGLowAlt, colorTable2.colorGTopAlt))
							color_bb = color_bb + (rng.range(colorTable2.colorBLowAlt, colorTable2.colorBTopAlt))
						end
						color_br = color_br / 2
						color_bg = color_bg / 2
						color_bb = color_bb / 2
					end
				end
				game.level.map:addEffect(self,
					px, py, 10,
					damageHandler, argsTable,
					0,
					5, nil,
					engine.MapEffect.new{zdepth = 3, color_br=color_br, color_bg=color_bg, color_bb=color_bb, effect_shader="shader_images/water_effect1.png"},
					function(e, update_shape_only)
						if not update_shape_only then e.radius = e.radius end
						return true
					end, 
					false
				)
			end
		end
		tg.selffire = true
		tg.friendlyfire = true
		self:project(tg, self.x, self.y, lingeringTilesFunction)
		
		return true
	end,
	info = function(self, t)
		local elementString
		if self.kam_controller_construct_element_only then
			local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
			local damage = t.getDamage(self, ele)
--			if self.kam_controller_construct_element_only == "T_KAM_ELEMENT_PRISMA" then
--				elementString = ""..self:damDesc(ele.getElement(self, ele), damage).." damage, divided between all 10 Spellwoven elements. This damage has a chance to inflict any Spellwoven debuff."
--			else
			local ele1, ele2 = ele.getKamDoubleElements()
			elementString = ([[Deal %d %s damage each turn (equally split between %s and %s damage. %s.]]):
			tformat(self:damDesc(ele.getElement(self, ele), damage), ele.name, DamageType:get(ele1).name:capitalize(), DamageType:get(ele2).name:capitalize(), ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true))
--			end
		elseif self.kam_controller_construct_element1 then
			local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
			local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
			local damage1 = t.getDamage(self, ele1) / 2
			local damage2 = t.getDamage(self, ele2) / 2
			elementString = ([["Deal %d %s and %d %s damage each turn. %s.]]):
			tformat(self:damDesc(ele1.getElement(self, ele1), damage1), DamageType:get(ele1.getElement(self, ele1)).name:capitalize(), self:damDesc(ele2.getElement(self, ele2), damage2), DamageType:get(ele2.getElement(self, ele2)).name:capitalize(), ele1.getSpellStatusInflict(self, ele1, t.getStatusChange(self, ele1) / 2, false, true), ele2.getSpellStatusInflict(self, ele2, t.getStatusChange(self, ele2) / 2, true, false))
		end
		if not elementString then
			elementString = "Tiles cannot be created since no element is active."
		end
		return ([[The construct's elemental energy appears to be flowing out of it with painful results.
		You release stored elemental energy, randomly creating damage tiles in a radius of up to 10 that deal damage over time based on your current element and last for 10 turns. The chance of creating tiles the farther away from you they are, although tiles will always be created on any enemy within range 7.
		Currently, these tiles will have the following effect: %s]]):tformat(elementString)
	end,
}

newTalent{
	name = "Elemental Spark",
	short_name = "KAM_KIA_CONSTRUCT_HARM",
	type = {"spellweaving/construct-controller",1},
	points = 1,
	random_ego = "attack",
	cooldown = 3,
	tactical = { ATTACK = 1 },
	range = 10,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t, friendlyfire = false, selffire = false}
	end,
	getDamage = function(self, ele)
		return ele.getElementDamage(self, ele) * 0.5
	end,
	getStatusChange = function(self, ele)
		return ele.getStatusChance(self, ele) * 0.7
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
		local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
		local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
		local argsTable
		local damageHandler
		if ele then
			argsTable = {dam = t.getDamage(self, ele), statusChance = t.getStatusChange(self, ele), element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = t}
			damageHandler = DamageType.KAM_SPELLWEAVE_MANAGER
		else
			damageHandler = DamageType.KAM_SPELLWEAVE_DUO_MANAGER
			argsTable = {dam11 = t.getDamage(self, ele1), dam12 = t.getDamage(self, ele2), statusChance11 = t.getStatusChange(self, ele1), statusChance12 = t.getStatusChange(self, ele2), element11 = ele1.getElement(self, ele1), element12 = ele2.getElement(self, ele2), second11 = ele1.getSecond(self, ele1), second12 = ele2.getSecond(self, ele2), friendlyfire = false, selffire = false, talent = t}
		end
		if not argsTable or not damageHandler then
			print("[KAM CONTROLLER CONSTRUCT] Construct did not have element when attacking with Elemental Spark.")
			return false
		end
		self:project({type = "hit"}, x, y, damageHandler, argsTable)
		if ele then
			local colorTable = {tx=x-self.x, ty=y-self.y, radius=0.4, density = 1}
			ele.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
		else
			local colorTable = {tx=x-self.x, ty=y-self.y, radius=0.4, density = 0.5}
			ele1.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
			colorTable = {tx=x-self.x, ty=y-self.y, radius=0.4, density = 0.5}
			ele2.getElementColors(self, colorTable, t)
			game.level.map:particleEmitter(x, y, 0.4, "kam_spellweaver_ball_physical", colorTable)
		end
		return true
	end,
	info = function(self, t)
		local elementString
		local effectString
		if self.kam_controller_construct_element_only then
			local ele = self:getTalentFromId(self.kam_controller_construct_element_only)
			local damage = t.getDamage(self, ele)
--			if self.kam_controller_construct_element_only == "T_KAM_ELEMENT_PRISMA" then
--				elementString = ""..self:damDesc(ele.getElement(self, ele), damage).." damage, divided between all 10 Spellwoven elements. This damage has a chance to inflict any Spellwoven debuff."
--			else
			local ele1, ele2 = ele.getKamDoubleElements()
			elementString = ([[%d %s damage (equally split between %s and %s damage)]]):
				tformat(self:damDesc(ele.getElement(self, ele), damage), ele.name, DamageType:get(ele1).name:capitalize(), DamageType:get(ele2).name:capitalize())
			effectString = ele.getSpellStatusInflict(self, ele, t.getStatusChange(self, ele), false, true)
--			end
		elseif self.kam_controller_construct_element1 then
			local ele1 = self:getTalentFromId(self.kam_controller_construct_element1)
			local ele2 = self:getTalentFromId(self.kam_controller_construct_element2)
			local damage1 = t.getDamage(self, ele1) / 2
			local damage2 = t.getDamage(self, ele2) / 2
			elementString = ([[%d %s and %d %s damage]]):
				tformat(self:damDesc(ele1.getElement(self, ele1), damage1), DamageType:get(ele1.getElement(self, ele1)).name:capitalize(), self:damDesc(ele2.getElement(self, ele2), damage2), DamageType:get(ele2.getElement(self, ele2)).name:capitalize())
			effectString = ele1.getSpellStatusInflict(self, ele1, t.getStatusChange(self, ele1) / 2, false, true).." "..ele2.getSpellStatusInflict(self, ele2, t.getStatusChange(self, ele2) / 2, true, false)
		end
		if not elementString then
			elementString = "No element is currently active."
		end
		return ([[The construct's elemental energy jumps out in sparks and bits quickly, albeit with less power than a skilled Spellweaver could unleash.
		Deal %s to a target within range 10. This can target through other enemies, although they will not take damage. %s.]]):tformat(elementString, effectString)
	end,
}

newTalent{ -- Predominantly copied from the Rush talent
	name = "Elemental Dash",
	short_name = "KAM_KIA_CONSTRUCT_RUSH",
	type = {"spellweaving/construct-controller", 1},
	message = _t"@Source@ charges with an elemental burst!",
	points = 5,
	random_ego = "attack",
	cooldown = function(self, t) 
		return 17
	end,
	tactical = { ATTACK = 1.5, CLOSEIN = 3 },
	requires_target = true,
	is_melee = true,
	target = function(self, t) 
		return {type="bolt", range=self:getTalentRange(t), stop__block=true} 
	end,
	range = function(self, t) 
		return 10
	end,
	on_pre_use_ai = function(self, t)
		local target = self.ai_target.actor
		if target and core.fov.distance(self.x, self.y, target.x, target.y) > 1 then return true end
		return false
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTargetLimited(tg)
		if not target then game.logPlayer(self, "Elemental Dash must have a target to function.") return nil end
		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local linestep = self:lineFOV(x, y, block_actor)

		local tx, ty, lx, ly, is_corner_blocked
		repeat  -- make sure each tile is passable
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or core.fov.distance(self.x, self.y, tx, ty) < 1 then
			game.logPlayer(self, "You are too close to build up momentum!")
			return
		end
		if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return nil end

		local ox, oy = self.x, self.y
		self:move(tx, ty, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 8, 5)
		end

		if target and core.fov.distance(self.x, self.y, target.x, target.y) <= 1 then
			self.kam_construct_increase_elemental_charge_damage = 1.5
			self:attackTarget(target, nil, 1, true)
			self.kam_construct_increase_elemental_charge_damage = nil
		end

		return true
	end,
	info = function(self, t)
		return ([[The golem appears to be able to propel itself torwards sources of magic using pure elemental force.
		Rush at a target within range 10 and perform a basic attack for 100%% damage. Elemental Charge damage and status infliction chance from this effect is increased by 50%%.]]):tformat()
	end,
}