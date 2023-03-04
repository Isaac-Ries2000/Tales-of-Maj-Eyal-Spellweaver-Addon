local Map = require "engine.Map"
local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/shield-bonuses", is_spell = true, name = _t("shield-bonuses", "talent type"), description = _t"Additional effects you can grant your shields." }

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

-- Unused ideas: Whirling one like from Arcane 4 shield.

newTalent{
	name = "None",
	short_name = "KAM_SHIELDBONUS_NONE",
	image = "talents/arcane_power.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = "",
	no_npc_use = true,
	bonusType = 0,
	doBonus = function() end,
	getPowerModBonus = function(self, t)
		return 1.2
	end,
	info = function(self, t)
		return ([[The damage shield will gain no additional effects. Spellweave Multiplier: 1.2.]])
	end,
	getBonusDescriptor = function(self, t) -- No description needed.
		return ([[]]):tformat()
	end,
}

newTalent{ -- Originally designed as a testing bonus. Still not really in use.
	name = "Thorns",
	short_name = "KAM_SHIELDBONUS_THORNS",
	image = "talents/bone_nova.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Thorns",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, spellweavePower, target)
		local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_THORNS)
		local damage = tal.bonusAssociatedFunction(self)
		DamageType:get(DamageType.THAUM).projector(self, target.x, target.y, DamageType.THAUM, damage*spellweavePower)
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[The damage shield gains the following effect: Enemies who damage the shield will take %d Thaumic damage (which uses the highest resistance penetration, the highest damage increase, cannot be normally resisted without resist all, and cannot be altered into another damage type), multiplied by Spellweave Multiplier. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return self:combatStatLimit("mag", 50, 5, 30)
	end,
	getBonusDescriptor = function(self, t)
		local thornsDamage = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		return ([[
Additionally, enemies who damage the shield take %d Thaumic damage.]]):tformat(thornsDamage)
	end,
}

-- Optimally this should use any element like pulse, but that would be kind of annoying to implement, so for right now it's not going to. Maybe later.
newTalent{ -- Modified version of the above, which is staying because it was the original and also because I'm still thinking of doing a Thaumic set of bonuses and an element.
	name = "Thorns",
	short_name = "KAM_SHIELDBONUS_THORNS_ELEMENTAL",
	image = "talents/bone_nova.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	kamRequiresElement = true,
	mode = "passive",
	getBonusName = " of Thorns",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, spellweavePower, target, _, argsTable)
		if not self.__kam_damage_shield_thorns_running and target and self:reactionToward(target) < 0 then
			if not argsTable then
				game.log("Thorns bonus has failed has failed because there was no argsTable present to handle elements and damage. Please report this if you see this with the exact components of the spell that failed.")
			else
				local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_THORNS_ELEMENTAL)
				local mod = tal.bonusAssociatedFunction(self)
				local DamageType = require "engine.DamageType" -- Due to a closures issue with storing doBonus as a function (which I need to do, since players can, in theory, overwrite shield spells that they have in use), this needs to be required.
				self.__kam_damage_shield_thorns_running = true
				if argsTable.element11 then
					DamageType:get(argsTable.element11).projector(self, target.x, target.y, argsTable.element11, argsTable.dam11 * mod / 2)
					DamageType:get(argsTable.element12).projector(self, target.x, target.y, argsTable.element12, argsTable.dam12 * mod / 2)
					DamageType:get(argsTable.second11).projector(self, target.x, target.y, argsTable.second11, argsTable.statusChance11 * mod / 2)
					DamageType:get(argsTable.second12).projector(self, target.x, target.y, argsTable.second12, argsTable.statusChance12 * mod / 2)
				else
					DamageType:get(argsTable.element).projector(self, target.x, target.y, argsTable.element, argsTable.dam * mod)
					DamageType:get(argsTable.second).projector(self, target.x, target.y, argsTable.second, argsTable.statusChance * mod)
				end
				self.__kam_damage_shield_thorns_running = nil
			end
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Create elemental thorns that strike anyone harming the shield (even if they do so at range), dealing damage based on a chosen element's damage divided by 5 and multiplied by Spellweave Multiplier. Spellweave Multiplier: 1.]]):
		tformat()
	end,
	bonusAssociatedFunction = function(self)
		return 0.2
	end,
	getBonusDescriptor = function(self, t)
		if t.isKamDuo then
			local damage1 = t.getElementDamage1(self, t) * t.getPowerMod(self, t) * t.bonusAssociatedFunction(self) / 2
			local damage2 = t.getElementDamage2(self, t) * t.getPowerMod(self, t) * t.bonusAssociatedFunction(self) / 2
			elementDescriptor = ([[%d %s and %d %s]]):tformat(self:damDesc(t.getElement1(self, t), damage1), DamageType:get(t.getElement1(self, t)).name:capitalize(), self:damDesc(t.getElement2(self, t), damage2), DamageType:get(t.getElement2(self, t)).name:capitalize())
		else 
			local damage = t.getElementDamage(self, t) * t.getPowerMod(self, t) * t.bonusAssociatedFunction(self)
			elementDescriptor = ([[%d %s]]):tformat(self:damDesc(t.getElement(self, t), damage), DamageType:get(t.getElement(self, t)).name:capitalize())
		end
		return ([[
Additionally, enemies who damage the shield take %s damage. %s.]]):tformat(elementDescriptor, t.getSpellStatusInflict(self, t, t.bonusAssociatedFunction(self)))
	end,
}

newTalent{
	name = "Draining",
	short_name = "KAM_SHIELDBONUS_DRAIN",
	image = "talents/arcane_vortex.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Draining",
	no_npc_use = true,
	bonusType = 4,
	doBonus = function(self, spellweavePower, damage)
		local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_DRAIN)
		local healing = spellweavePower * damage * tal.bonusAssociatedFunction(self) / 100
		self:heal(healing, self)
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[The damage shield absorbs damage, healing you for %d%% of the damage recieved. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return 20
	end,
	getBonusDescriptor = function(self, t)
		local draining = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		return ([[
Additionally, regain %d%% of damage dealt to the shield.]]):tformat(draining)
	end,
}

newTalent{
	name = "Reflection",
	short_name = "KAM_SHIELDBONUS_REFLECT",
	image = "talents/rune__reflection_shield.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Reflection",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, spellweavePower, target, damage)
		if not self.__damage_shield_reflect_running and target and self:reactionToward(target) < 0 then
			local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_REFLECT)
			local reflected = spellweavePower * damage * tal.bonusAssociatedFunction(self) / 100
			self.__damage_shield_reflect_running = true
			target:takeHit(reflected, self)
			self.__damage_shield_reflect_running = nil
			game:delayedLogDamage(self, target, reflected, ("#SLATE#%d reflected#LAST#"):tformat(reflected), false)
			game:delayedLogMessage(self, target, "reflection" ,"#CRIMSON##Source# reflects damage back to #Target#!#LAST#")
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[The damage shield reflects damage, dealing %d%% (multiplied by Spellweave Multiplier) of the damage dealt to it to whoever dealt damage. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return 50
	end,
	getBonusDescriptor = function(self, t)
		local draining = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		return ([[
Additionally, reflect %d%% of damage dealt to the shield back to any enemy that inflicted it.]]):tformat(draining)
	end,
}

newTalent{
	name = "Haste",
	short_name = "KAM_SHIELDBONUS_HASTE",
	image = "talents/anomaly_haste.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Haste",
	no_npc_use = true,
	bonusType = 1,
	doBonus = function(self, spellweavePower, target, damage)
		if not (self.hasEffect and self:hasEffect(self.EFF_KAM_SPELLWOVEN_HASTE_EXHAUSTION)) then
			local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_HASTE)
			local movespeed, combatspeed = tal.bonusAssociatedFunction(self)
			movespeed = movespeed * spellweavePower
			combatspeed = combatspeed * spellweavePower
			
			self:setEffect(self.EFF_KAM_SPELLWOVEN_HASTE, 1, {movespeed = movespeed, combatspeed = combatspeed})
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[When the damage shield ends, absorb its excess energy to gain %d%% movespeed and %d%% attack, mental, and spell speeds (both multiplied by Spellweave Multiplier) for one turn. After the burst of speed ends, you are exhausted and cannot gain this effect again for 5 turns. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return 200, 75
	end,
	getBonusDescriptor = function(self, t)
		local movespeed, combatspeed = t.bonusAssociatedFunction(self)
		movespeed = movespeed * t.getPowerMod(self, t)
		combatspeed = combatspeed * t.getPowerMod(self, t)
		return ([[
When the damage shield ends, absorb its energy to gain %d%% movespeed and %d%% attack, mental, and spell speeds for one turn. After the burst of speed ends, you are exhausted and cannot gain this effect again for 5 turns.]]):tformat(movespeed, combatspeed)
	end,
}

newTalent{ -- This may need testing as an omni-drain shield. It's just doing only manaburn gets to feel like a weird thing. Like, cool, here's an antimagic shield, but... I might eventually change this back to being just manaburn, it just seemed sad.
	name = "Power Draining",
	short_name = "KAM_SHIELDBONUS_DRAINARCANE",
	image = "talents/disruption_shield.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Power Draining",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, spellweavePower, target, damage)
		local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_DRAINARCANE)
		local reflected = spellweavePower * damage * tal.bonusAssociatedFunction(self) / 100
		
		local drain = 0
		if target then
			drain = KamCalc:kam_burn_all_resources(target, reflected) or 0
		end
		
		if (drain > 0) then
			self:incMana(drain)
			game:delayedLogMessage(self, target, "reflection" ,("#CRIMSON##Source# absorbs %d mana from #Target#!#LAST#"):tformat(drain))
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		local extraText = [[]]
		if game:isAddonActive("orcs") then
			extraText = extraText..(([[ steam (10%%),]]):tformat())
		end
		if game:isAddonActive("cults") then
			extraText = extraText..(([[ insanity (10%%),]]):tformat())
		end
		return ([[The damage shield drains energy from attackers. Each time you are attacked, drain %d%% (multiplied by Spellweave Multiplier) of the damage absorbed from target's resources: mana (draining 100%% of the absorbing value), vim (draining 50%%), stamina (draining 50%%), positive and negative energies (draining 25%%), psi (draining 25%%),%s and hate (draining 10%%), and regain mana based on the resources drained (specifically, the greatest of: the amounts drained times 1 divided by the percents listed before). Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self), extraText)
	end,
	bonusAssociatedFunction = function(self)
		return 70
	end,
	getBonusDescriptor = function(self, t)
		local draining = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		local extraText = [[]]
		if game:isAddonActive("orcs") then
			extraText = extraText..(([[ steam (10%%),]]):tformat())
		end
		if game:isAddonActive("cults") then
			extraText = extraText..(([[ insanity (10%%),]]):tformat())
		end
		return ([[
Additionally, drain %d%% (multiplied by Spellweave Multiplier) of the damage absorbed from target's resources: mana (draining 100%% of the absorbing value), vim (draining 50%%), stamina (draining 50%%), positive and negative energies (draining 25%%), psi (draining 25%%),%s and hate (draining 10%%), and regain mana based on the resources drained (specifically, the greatest of: the amounts drained times 1 times the inverse of the percents listed before).]]):tformat(draining, extraText)
	end,
}

newTalent{ 
	name = "Restoring Rain",
	short_name = "KAM_SHIELDBONUS_REGEN",
	image = "talents/reality_smearing.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Restoring Rain",
	no_npc_use = true,
	bonusType = 5,
	doBonus = function(self, spellweavePower, valueStorage, atEnd, midBreak) -- Still not working with Molten
		if not atEnd and not midBreak then -- Activation
			local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_REGEN)
			local regen = spellweavePower * tal.bonusAssociatedFunction(self)
			valueStorage.kamRestoringRainRegenerationStorage = regen
			valueStorage.kamRestoringRainRegeneration = self:addTemporaryValue("life_regen", regen)
		elseif not atEnd and midBreak == 0 then -- Molten breaking
			self:removeTemporaryValue("life_regen", valueStorage.kamRestoringRainRegeneration)
			valueStorage.kamRestoringRainRegeneration = self:addTemporaryValue("life_regen", valueStorage.kamRestoringRainRegenerationStorage / 2)
		elseif not atEnd and midBreak == 1 then
			self:removeTemporaryValue("life_regen", valueStorage.kamRestoringRainRegeneration)
			valueStorage.kamRestoringRainRegeneration = self:addTemporaryValue("life_regen", valueStorage.kamRestoringRainRegenerationStorage)
		else
			self:removeTemporaryValue("life_regen", valueStorage.kamRestoringRainRegeneration)
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[The damage shield creates a rejuvenating rain, increasing your regeneration by %d while it is active. Regeneration increases with Spellpower. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return 3 + self:combatStatScale(self:combatSpellpower(), 2, 12)
	end,
	getBonusDescriptor = function(self, t)
		local regen = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		local moltenText = ""
		if t.isKamMoltenShield then 
			moltenText = [[ If the shield breaks, then the regeneration will be halved, but will remain active until the shield is disabled.]]
		end
		return ([[
The damage shield creates a rejuvenating rain, increasing your regeneration by %d while it is active. Regeneration increases with Spellpower.%s]]):tformat(regen, moltenText)
	end,
}

newTalent{ -- May need balancing, it's an odd one too.
	name = "Corrosion",
	short_name = "KAM_SHIELDBONUS_CORROSION",
	image = "talents/corrosive_seeds.png",
	type = {"spellweaving/shield-bonuses", 1},
	points = 1,
	isKamShieldBonus = true,
	mode = "passive",
	getBonusName = " of Corrosion",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, spellweavePower, target)
		local tal = self:getTalentFromId(self.T_KAM_SHIELDBONUS_CORROSION)
		target:setEffect(target.EFF_KAM_SHIELDBONUS_CORROSION, 4, {src = src, power = spellweavePower * tal.bonusAssociatedFunction(self)})
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[The damage shield is corrosive, stackingly reducing attackers damage by %d%% (multiplied by Spellweave Multiplier, maxing at 50%%) for 4 turns each time you are hit (this can only be applied once per turn per enemy). Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	bonusAssociatedFunction = function(self)
		return 3
	end,
	getBonusDescriptor = function(self, t)
		local draining = t.bonusAssociatedFunction(self) * t.getPowerMod(self, t)
		return ([[
Additionally, corrode targets, stackingly reducing their damage by %d%% for 4 turns each time you are hit (this can only apply once per turn per enemy and maxes at 50%% reduction).]]):tformat(draining)
	end,
}