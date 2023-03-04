local Map = require "engine.Map"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/spells", name = _t("spells", "talent type"), description = _t"Spells created through spellweaving." }

local function universalPowerMod(self, t) -- Multipliers for all Spellweave Multiplier things.
	local powerMod = 1
	if (t.mode ~= "sustained" and t.mode ~= "passive") and self.hasEffect then -- Effects that remove themselves and should thus not apply to sustains which recheck.
		local voidDance = self:hasEffect(self.EFF_KAM_SPELLWEAVER_OTHERWORLDLY_FLOW)
		if voidDance then
			powerMod = powerMod * voidDance.powerMod
			self.kamRemoveVoidDance = true -- Temporary marker to delete in the afterSpellweaveCast function
		end
		local runicEmpowerment = self:hasEffect(self.EFF_KAM_SPELLWEAVER_RUNIC_EMPOWERMENT)
		if runicEmpowerment then
			powerMod = powerMod * runicEmpowerment.powerMod
			self.kamRemoveRunicEmpowerment = true
		end
	end
	local metaEmpowerment = self:isTalentActive(self.T_KAM_METAWEAVING_EMPOWERMENT)
	if (metaEmpowerment and (metaEmpowerment.boostedTalentId == t.kamSpellSlotNumber)) then 
		local metaEmpowermentTalent = self:getTalentFromId(self.T_KAM_METAWEAVING_EMPOWERMENT)
		local multiplier = 1
		local eff = self:hasEffect(self.EFF_KAM_META_EMPOWERMENT_BOOST)
		if (eff) then
			multiplier = 1 + eff.power / 100
		end
		powerMod = powerMod * metaEmpowermentTalent.getSpellweaveMod(self, metaEmpowermentTalent) * multiplier
	end
	if self.attr and self:attr("kam_spellweaver_hundredeyes_glasses_bonus_power") then
		powerMod = powerMod * (self:attr("kam_spellweaver_hundredeyes_glasses_bonus_power") + 1)
	end
	return powerMod
end

local function afterSpellweaveCast(self, t) -- Occasional effects that need to trigger after ALL other Spellweave things.
	if self.kamRemoveVoidDance then
		self:removeEffect(self.EFF_KAM_SPELLWEAVER_OTHERWORLDLY_FLOW) -- You only get this once per move.
		self.kamRemoveVoidDance = nil
	end
	if self.kamRemoveRunicEmpowerment then
		self:removeEffect(self.EFF_KAM_SPELLWEAVER_RUNIC_EMPOWERMENT) -- You can only get this once per rune.
		self.kamRemoveRunicEmpowerment = nil
	end
	if game.state.kam_spellweaver_random_element then
		game.state.kam_spellweaver_random_element = nil
	end
	local metaEmpowerment = self:isTalentActive(self.T_KAM_METAWEAVING_EMPOWERMENT)
	if (metaEmpowerment and (metaEmpowerment.boostedTalentId == t.kamSpellSlotNumber)) and self:hasEffect(self.EFF_KAM_META_EMPOWERMENT_BOOST) then
		self:removeEffect(self.EFF_KAM_META_EMPOWERMENT_BOOST)
	end
end

local function setRandom(self, t)
	if t.isKamElementRandom then -- Pick a random element the player knows.
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not (talentTable.isKamDuo or talentTable.isKamPrismatic or talentTable.isKamElementRandom) then
					elements[#elements+1] = talentTable
				end
			end
		end
		game.state.kam_spellweaver_random_element = rng.table(elements)
		game.state.kam_spellweaver_random_element_level = KamCalc:getAverageHighestElementTalentLevel(self, 3) * game.state.kam_spellweaver_random_element.points
	end
end

newTalent{ -- This is duplicated into every needed slot in the load file, but renamed and short_named. It's used as the "blank" spell slot, and also as the base pattern for attack spells.
	name = "Spell Slot X",
	short_name = "KAM_SPELL_SLOT_ATTACK",
	image = "talents/frayed_threads.png",
	type = {"spellweaving/spells", 1},
	isKamSpellSlot = true,
	isKamAttackSpell = false,
	kamSpellSlotNumber = 0,
	reflectable = true,
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 15,
	points = 1,
	cooldown = 5,
	speed = "spell",
	tactical = { 
		ATTACK = function(self, t, target) -- Should only use if crafted already.
			if t.isKamSpellCrafted then 
				return 2
			else
				return nil
			end
		end,
	},

	getElement = function(self, t) return false end, -- Primary element
	getSecond = function(self, t) end, -- Secondary elemental effect
	
	getElementColors = function(self, argsList, t) end,
	
	makeParticles = function(self, t) end,
	
	getDamageFunction = function(self, t, tg, x, y) end, -- Gets the damage function. The big thing.
	
	target = function(self, t) end, -- Gets the shape of the spell.
	
	getPowerModMode = function(self, t)	end, -- Gets the power mod from the mode
	getPowerModShape = function(self, t) end, -- Gets the power mod from the shape
	getPowerModBonus = function(self, t)
		local powerMod = universalPowerMod(self, t)
		if (self:knowTalent(self.T_KAM_SPELLWOVEN_DESTRUCTION)) then -- Handle flat boost from Spellwoven Destruction
			local tal = self:getTalentFromId(self.T_KAM_SPELLWOVEN_DESTRUCTION)
			powerMod = powerMod * (tal.getSpellweaverPowerBoost(self, tal) + 1)
		end
		local changeupEff = self:hasEffect(self.EFF_KAM_SPELLWEAVE_CHANGEUP)
		if (changeupEff) then -- Handle checking if Changeup applies if the buff is active.
			if KamCalc:compareSlots(self, changeupEff, t) then 
				local tal = self:getTalentFromId(self.T_KAM_MODE_CHANGEUP)
				powerMod = powerMod * tal.getSpellweavePowerBoost
			end
		end
		if t.isKamBarrage then  -- Handle dramatic reduction from Barrage.
			powerMod = powerMod * 0.3 
		end
		return powerMod
	end,
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModShape(self, t) * t.getPowerModBonus(self, t))
	end,
	action = function(self, t)
		if not (t.isKamSpellCrafted) then
			game.log("You need to craft a Spell for this Spell Slot before using it!")
			return nil
		end
		local count = 1
		if t.isKamBarrage then 
			count = 3 
		end
		for i = 1, count do -- Special case for barrage.
			local tg
			local x, y
			if t.isKamNoNeedTarget then
				tg = self:getTalentTarget(t)
				x, y = self.x, self.y
			else
				tg = self:getTalentTarget(t)
				old_tg_pass_terrain = tg.pass_terrain
				tg.pass_terrain = t.isKamIgnoreWalls -- Marker for targeting.
				x, y = self:getTarget(tg)
				if (not x or not y) then 
					if i == 1 then
						return nil 
					else 
						return true
					end
				end -- Only allow canceling on the first target selection.
			end
			
			if not (t.isKamNoCheckCanProject) then
				if t.isKamASCExact then
					local _ _, _, _, checkX, checkY = self:canProject(tg, x, y)
					x = checkX
					y = checkY
				else 
					local _ _, checkX, checkY = self:canProject(tg, x, y)
					x = checkX
					y = checkY
				end
			end
			tg.pass_terrain = old_tg_pass_terrain
			if not (t.isKamDoubleShape) then
				setRandom(self, t)
				local particleX, particleY = x, y
				if (self.kamRecheckProjectParticles) then
					if t.isKamASCExact then
						local _ _, _, _, checkX, checkY = self:canProject(tg, x, y)
						particleX = checkX
						particleY = checkY
					else 
						local _ _, checkX, checkY = self:canProject(tg, x, y)
						particleX = checkX
						particleY = checkY
					end
					self.kamRecheckProjectParticles = nil
				end
				t.makeParticles(self, t, tg, particleX, particleY)
				t.getDamageFunction(self, t, tg, x, y)
				game:playSoundNear(self, "talents/arcane")
			else 
				if not (t.swapSpellOrder) then
					setRandom(self, t)
					t.isKamSpellSplitOne = true
					if (t.isKamDuo1) then 
						t.isKamDuo = true
					else 
						t.isKamDuo = false
					end
					if (t.isKamPrismatic1) then 
						t.isKamPrismatic = true
					else
						t.isKamPrismatic = false
					end
					t.isKamElementRandom = t.isKamElementRandom1
					t.getDamageFunction1(self, t, tg, x, y)
					if (self.kamRecheckProjectParticles) then
						if t.isKamASCExact then
							local _ _, _, _, checkX, checkY = self:canProject(tg, x, y)
							x = checkX
							y = checkY
						else 
							local _ _, checkX, checkY = self:canProject(tg, x, y)
							x = checkX
							y = checkY
						end
						self.kamRecheckProjectParticles = nil
					end
				end
				setRandom(self, t)
				t.isKamSpellSplitOne = false
				if (t.isKamDuo2) then 
					t.isKamDuo = true
				else 
					t.isKamDuo = false
				end
				if (t.isKamPrismatic2) then 
					t.isKamPrismatic = true
				else
					t.isKamPrismatic = false
				end
				t.isKamElementRandom = t.isKamElementRandom2
				local tg2 = table.clone(tg)
				tg2.offset = 1
				local particleX, particleY = x, y
				if (self.kamRecheckProjectParticles) then
					if t.isKamASCExact then
						local _ _, _, _, checkX, checkY = self:canProject(tg, x, y)
						particleX = checkX
						particleY = checkY
					else 
						local _ _, checkX, checkY = self:canProject(tg, x, y)
						particleX = checkX
						particleY = checkY
					end
					self.kamRecheckProjectParticles = nil
				end
				t.makeParticles(self, t, tg2, particleX, particleY)
				t.getDamageFunction2(self, t, tg2, x, y)
				game:playSoundNear(self, "talents/arcane")
				if (t.swapSpellOrder) then
					setRandom(self, t)
					t.isKamSpellSplitOne = true
					if (t.isKamDuo1) then 
						t.isKamDuo = true
					else 
						t.isKamDuo = false
					end
					if (t.isKamPrismatic1) then 
						t.isKamPrismatic = true
					else
						t.isKamPrismatic = false
					end
					t.isKamElementRandom = t.isKamElementRandom1
					t.getDamageFunction1(self, t, tg, x, y)
					if (self.kamRecheckProjectParticles) then
						if t.isKamASCExact then
							local _ _, _, _, checkX, checkY = self:canProject(tg, x, y)
							x = checkX
							y = checkY
						else 
							local _ _, checkX, checkY = self:canProject(tg, x, y)
							x = checkX
							y = checkY
						end
						self.kamRecheckProjectParticles = nil
					end
				end
			end
		end
		afterSpellweaveCast(self, t)
		return true
	end,
	info = function(self, t)
		return [[An empty Spell Slot.]]
	end,
}

newTalent{ -- The base pattern for shield spells.
	name = "Spell Slot Shield",
	short_name = "KAM_SPELL_SLOT_SHIELD",
	image = "talents/frayed_threads.png",
	type = {"spellweaving/spells", 1},
	isKamSpellSlot = true,
	kamSpellSlotNumber = 0,
	reflectable = false, -- It's a shield.
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 20,
	points = 1,
	cooldown = 15,
	tactical = { DEFEND = 2 },
	speed = function(self, t)
		if self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_SPEED) then 
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_SPEED)
			return tal.getSpeed(self, tal)
		else 
			return 0.5
		end
	end,
	
	getShieldFunction = function(self, t) end,
	doBonus = function(self) end, -- doBonus will have different calling methods used by different versions, types with the same bonusType will share their call.
	getPowerModBonus = function(self, t) end,
	getPowerModMode = function(self, t) end,
	
	getPowerModSpecial = function(self, t)
		local powerMod = universalPowerMod(self, t)
		if (self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_MASTERY)) then -- Handle flat boost from Spellweaver's Protection
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_MASTERY)
			powerMod = powerMod * (tal.getSpellweaverPowerBoost(self, tal) + 1)
		end
		if self.attr and self:attr("kam_spellweaver_teaching_loom_bonus") then
			powerMod = powerMod * (self:attr("kam_spellweaver_teaching_loom_bonus") + 1)
		end
		return powerMod
	end,
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModBonus(self, t) * t.getPowerModSpecial(self, t))
	end,
	action = function(self, t)
		if not (t.isKamSpellCrafted) then
			game.log("Error: Shield Spell thinks it is not crafted.")
			return nil
		end
		
		t.getShieldFunction(self, t)
		afterSpellweaveCast(self, t)
		return true
	end,
	info = function(self, t)
		return [[If you see this, please report this: "The blank shield spell slot is in one of the visible spell slots."]]
	end,
}

local function checkElementRandom(self, t)
	if t.isKamElementRandom then -- Pick a random element the player knows.
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not (talentTable.isKamDuo or talentTable.isKamPrismatic) then
					elements[#elements+1] = talentTable
				end
			end
		end
		game.state.kam_spellweaver_random_element = rng.table(elements)
	end
end

newTalent{ -- The special pattern for the molten shield mode. It actually will stack with others so if you want to walk around with 6 molten shields and no combat, you can! (don't though)
	name = "Spell Slot Shield Molten",
	short_name = "KAM_SPELL_SLOT_SHIELD_SUSTAIN",
	image = "talents/frayed_threads.png",
	type = {"spellweaving/spells", 1},
	mode = "sustained",
	tactical = { DEFEND = 2 },
	isKamSpellSlot = true,
	kamSpellSlotNumber = 0,
	reflectable = false, -- It's still a shield.
	isKamMoltenShield = true, -- For things with altered text for Molten.
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 0,
	sustain_mana = 25, 
	points = 1,
	cooldown = 30,
	speed = "spell",
	iconOverlay = function(self, t, p)
		local p = self.sustain_talents[t.id]
		if not p or not p.absorb then return "" end
		return  "#LIGHT_GREEN#"..math.floor(p.absorb).."#LAST#", "buff_font_smaller"
	end,
	
	getShieldFunction = function(self, t) end,
	doBonus = function(self) end,
	getPowerModBonus = function(self, t) end,
	getPowerModMode = function(self, t) end,
	
	getPowerModSpecial = function(self, t) end, -- See load's makeSpellslots.
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModBonus(self, t) * t.getPowerModSpecial(self, t))
	end,
	activate = function(self, t)
		local particle
		if core.shader.active(4) then
			particle = self:addParticles(Particles.new("shader_shield", 1, {img="shield7"}, {type="shield", shieldIntensity=0.2, color={1.0, 0.3, 0.3}}))
		else
			particle = self:addParticles(Particles.new("damage_shield", 1))
		end
		game:playSoundNear(self, "talents/spell_generic")
		local ret = {absorb = t.getShieldFunction(self, t), maxAbsorb = t.getShieldFunction(self, t), particle = particle, broken = false}
		
		afterSpellweaveCast(self, t)
		if (t.bonusType == 5) then 
			t.doBonus(self, t.getPowerMod(self, t), ret, false)
		end
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		if (t.bonusType == 5) then 
			t.doBonus(self, t.getPowerMod(self, t), p, true)
		end
		return true
	end,
	callbackOnAct = function(self, t, state)
		local p = self:isTalentActive(t.id)
		if not p then return end 
		
		p.absorb = p.absorb or 0
		p.maxAbsorb = t.getShieldFunction(self, t) -- Recalculated each turn since you can modify Spellweave power.
		
		if self.in_combat then 
			p.absorb = p.absorb + p.maxAbsorb * 0.04 -- Every turn regain 4% of shield power.
		else 
			p.absorb = p.absorb + p.maxAbsorb * 0.1 -- Out of combat, regain 10%.
		end
		if p.broken and p.absorb >= p.maxAbsorb then -- If p.absorb is fully unbroken, then unmark broken.
			if (t.bonusType == 5) then 
				t.doBonus(self, t.getPowerMod(self, t), p, false, 1)
			end
			p.broken = false
		end
		p.absorb = math.min(p.absorb, p.maxAbsorb)
		if (t.bonusType == 3) then 
			local effectiveSpellweave = t.getPowerMod(self, t)
			if p.broken then 
				effectiveSpellweave = effectiveSpellweave * 0.5
			end
			t.doBonus(self, effectiveSpellweave)
		end
	end,
	callbackOnRest = function(self, t)
		local p = self:isTalentActive(t.id)
		if not p then return end 
		p.absorb = p.absorb or 0
		p.maxAbsorb = p.maxAbsorb or 0
		if p.absorb < p.maxAbsorb then return true end
	end,
	callbackOnHit = function(self, t, cb, src, dt)
		checkElementRandom(self, t)
		local p = self:isTalentActive(t.id)
		if not p then return end 
		if cb.value <= 0 then return end -- If there's no damage, nothing is needed.
		
		p.absorb = p.absorb or 0
		p.maxAbsorb = p.maxAbsorb or 0
		if p.absorb <= 0.5 then return end
		
		local damageToShield = cb.value
		if src and src.attr and src:attr("damage_shield_penetrate") then
			damageToShield = cb.value * (1 - (util.bound(src.damage_shield_penetrate, 0, 100) / 100))
		end
		local damageToShield = math.min(p.absorb, damageToShield)
		p.absorb = p.absorb - damageToShield
		cb.value = cb.value - damageToShield
		game:delayedLogDamage(src, self, 0, ("#SLATE#(%d absorbed)#LAST#"):tformat(damageToShield), false)
		
		if (t.bonusType == 2) then 
			local a = game.level.map(src.x, src.y, Map.ACTOR)
			if a and self:reactionToward(a) < 0 then 
				local effectiveSpellweave = t.getPowerMod(self, t)
				if p.broken then 
					effectiveSpellweave = effectiveSpellweave * 0.5
				end
				t.doBonus(self, effectiveSpellweave, a, damageToShield, KamCalc:buildShieldArgsTableElement(self, t, 1))
			end 
		end
		if (t.bonusType == 4) then 
			local effectiveSpellweave = t.getPowerMod(self, t)
			if p.broken then 
				effectiveSpellweave = effectiveSpellweave * 0.5
			end
			t.doBonus(self, effectiveSpellweave, damageToShield)
		end
		if p.absorb <= 0 then 
			if (t.bonusType == 1) or (t.bonusType == 5) and not p.broken then 
				t.doBonus(self, t.getPowerMod(self, t), p, false, 0)
			end
			p.broken = true
		end
		return true
	end,
	info = function(self, t)
		return [[If you see this, please report this: "The slag shield spell base is in one of the visible spell slots (or wherever else you see this)."]]
	end,
}

newTalent{ 
	name = "Spell Slot Shield Contingency",
	short_name = "KAM_SPELL_SLOT_SHIELD_CONTINGENCY",
	image = "talents/frayed_threads.png",
	type = {"spellweaving/spells", 1},
	mode = "sustained",
	tactical = { DEFEND = 2 },
	isKamSpellSlot = true,
	kamSpellSlotNumber = 0,
	reflectable = false, -- It's still still a shield.
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 0,
	sustain_mana = 25, 
	points = 1,
	cooldown = 20,
	speed = "spell",
	
	getShieldFunction = function(self, t) end,
	doBonus = function(self) end,
	getPowerModBonus = function(self, t) end,
	getPowerModMode = function(self, t) end,
	
	getPowerModSpecial = function(self, t) end, -- See load's makeSpellslots again.
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModBonus(self, t) * t.getPowerModSpecial(self, t))
	end,
	activate = function(self, t)
		local ret = {cooldown = 0}
		
		if core.shader.active(4) then
			ret.particle = self:addParticles(Particles.new("shader_shield", 1, {size_factor=1.2, img="runicshield_teal"}, {type="runicshield", shieldIntensity=0.10, ellipsoidalFactor=1, scrollingSpeed=1, time_factor=12000, bubbleColor={0.5, 1, 0.8, 0.2}, auraColor={0.5, 1, 0.8, 0.5}}))
		end
		
		afterSpellweaveCast(self, t)
		return ret
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)
		if p.cooldown > 0 then p.cooldown = p.cooldown - 1 end
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		return true
	end,
--	callbackOnRest = function(self, t)
--	--	local p = self:isTalentActive(t.id)
--		if not p then return end 
--		p.absorb = p.absorb or 0
--		p.maxAbsorb = p.maxAbsorb or 0
--		if p.absorb < p.maxAbsorb then return true end
--	end,
	callbackPriorities={callbackOnHit = 1}, -- Trigger after most other things.
	callbackOnHit = function(self, t, cb, src, dt)
--		if src == self then return cb.value end -- If you hurt yourself, it does nothing. -- Edit: Now it does.
		local tal = self:getTalentFromId(self.T_KAM_SHIELDMODE_CONTINGENCY)
		local threshold = tal.health_threshold
		
		local p = self:isTalentActive(t.id)
		local life_after = self.life - cb.value
		local cont_trigger = self.max_life * threshold / 100
		
		if p and p.cooldown <= 0 and cont_trigger > life_after then 
			p.cooldown = t.cooldown
			game.logPlayer(self, "#STEEL_BLUE#Your Contingency shield has triggered!")
			t.getShieldFunction(self, t)
			-- Between these two points is added to make it so that contingency shield will block the attack it triggered on, generally preventing you from actually being lowered that low. Basically, it reduces your odds of a big hit one shotting you and rendering the talent useless.
			local eff = self:hasEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_CONTINGENT)
			if eff then
				local ed = self:getEffectFromId(eff.effect_id)
				if ed then
					ed.callbackOnHit(self, eff, cb, src)
				end
			end
			--
		end
		
		return cb.value
	end,
	info = function(self, t)
		return [[If you see this, please report this: "The contingency shield spell base is in one of the visible spell slots (or wherever else you see this)."]]
	end,
}

newTalent{ -- The base pattern for teleport spells.
	name = "Spell Slot Teleport",
	short_name = "KAM_SPELL_SLOT_MOVEMENT",
	image = "talents/frayed_threads.png",
	type = {"spellweaving/spells", 1},
	tactical = {ESCAPE = 2, CLOSEIN = 1}, -- This might be somewhat goofy if your teleport spell is Teleport mode to closein, but close enough.
	isKamSpellSlot = true,
	kamSpellSlotNumber = 0,
	reflectable = false,
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 15,
	points = 1,
	cooldown = 15,
	getTeleportFunction = function(self, t) end,
	doBonus = function(self) end,
	getPowerModBonus = function(self, t) end,
	getPowerModMode = function(self, t) end,
	speed = "spell",
	
	getPowerModSpecial = function(self, t)
		local powerMod = universalPowerMod(self, t)
		if (self:knowTalent(self.T_KAM_SPELLWEAVER_TELEPORT_MASTERY)) then -- Handle flat boost from Spellweaver's Direction
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_TELEPORT_MASTERY)
			powerMod = powerMod * (tal.getSpellweaverPowerBoost(self, tal) + 1)
		end
		if self.attr and self:attr("kam_spellweaver_teaching_loom_bonus") then
			powerMod = powerMod * (self:attr("kam_spellweaver_teaching_loom_bonus") + 1)
		end
		return powerMod
	end,
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModBonus(self, t) * t.getPowerModSpecial(self, t))
	end,
	action = function(self, t)
		if not (t.isKamSpellCrafted) then
			game.log("Error: Teleport spell thinks it is not crafted.")
			return nil
		end
		
		local retVal = t.getTeleportFunction(self, t)
		afterSpellweaveCast(self, t)
		return retVal
	end,
	info = function(self, t)
		return [[If you see this, please report this: "The blank teleport spell slot is in one of the visible spell slots."]]
	end,
}

newTalent{ -- The special slot for that holds only teleport spells.
	name = "Spell Slot Teleport",
	short_name = "KAM_SPELL_SLOT_TELEPORT_UNIQUE",
	image = "talents/kam_spellweaver_spellslot_teleport_14.png",
	type = {"spellweaving/spells", 1},
	tactical = {ESCAPE = 2, CLOSEIN = 1},
	isKamSpellSlot = false,
	isKamTeleportSpellSlot = true,
	kamSpellSlotNumber = 14,
	reflectable = false,
	isKamSpellCrafted = false,
	is_spell = true,
	mana = 15,
	points = 1,
	cooldown = 15,
	getTeleportFunction = function(self, t) end,
	doBonus = function(self) end,
	getPowerModBonus = function(self, t) end,
	getPowerModMode = function(self, t) end,
	speed = "spell",
	
	getPowerModSpecial = function(self, t)
		local powerMod = universalPowerMod(self, t)
		if (self:knowTalent(self.T_KAM_SPELLWEAVER_TELEPORT_MASTERY)) then -- Handle flat boost from Spellweaver's Direction
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_TELEPORT_MASTERY)
			powerMod = powerMod * (tal.getSpellweaverPowerBoost(self, tal) + 1)
		end
		if self.attr and self:attr("kam_spellweaver_teaching_loom_bonus") then
			powerMod = powerMod * (self:attr("kam_spellweaver_teaching_loom_bonus") + 1)
		end
		return powerMod
	end,
	getPowerMod = function(self, t) -- Get net power mod.
		return (t.getPowerModMode(self, t) * t.getPowerModBonus(self, t) * t.getPowerModSpecial(self, t))
	end,
	action = function(self, t)
		if not (t.isKamSpellCrafted) then
			game.log("Error: Teleport spell thinks it is not crafted.")
			return nil
		end
		
		local retVal = t.getTeleportFunction(self, t)
		afterSpellweaveCast(self, t)
		return retVal
	end,
	info = function(self, t)
		return [[If you see this, please report this: "The blank teleport-only spell slot is in one of the visible spell slots."]]
	end,
}

