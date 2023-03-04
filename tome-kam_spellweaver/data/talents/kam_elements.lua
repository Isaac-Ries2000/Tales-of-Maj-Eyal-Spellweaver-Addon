local Map = require "engine.Map"
local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/elements", no_silence = true, is_spell = true, name = _t("elements", "talent type"), description = _t"Weave spells with the elements." }
-- You know, in retrospect, "second" effects should probably just be part of the damage types. In my defense, the way damage types are used in ToME is not necessarily intuitive.
-- Although with how I've ended up handling everything, there are advantages to this weird layout too.
local getDamageMultiplier = function(self)
	local mult = 1
	return mult
end

local countElements = function(self) -- For prismatic.
	local count = 0
	if self:knowTalent(self.T_KAM_ELEMENTS_ECLIPSE) then 
		count = count + 2
	end
	if self:knowTalent(self.T_KAM_ELEMENTS_MOLTEN) then 
		count = count + 2
	end
	if self:knowTalent(self.T_KAM_ELEMENTS_WIND_AND_RAIN) then 
		count = count + 2
	end
	if self:knowTalent(self.T_KAM_ELEMENTS_RUIN) then 
		count = count + 2
	end
	if self:knowTalent(self.T_KAM_ELEMENTS_OTHERWORLDLY) then 
		count = count + 2
	end
	return count
end

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

newTalent{
	name = "Darkness",
	short_name = "KAM_ELEMENT_DARKNESS",
	image = "talents/darkness.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Shadowed ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.DARKNESS
	end,
	getSecond = function(self, t)
		return DamageType.KAM_BLIND_DARK
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE)
		return tal.getBlindChance(self, tal, level) -- You can reliably blind small groups, or more with good Mode usage. Lots of late game stuff is less affected/blind immune.
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 0, colorRTop = 20, colorGLow = 0, colorGTop = 20, colorBLow = 0, colorBTop = 20, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Darkness.
		Effect: Inflict %d Darkness damage, with a %d%% chance to blind targets for 5 turns. Damage and blindness chance are both multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Dark",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Blind targets for 5 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Blind targets for 5 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Blind targets for 5 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { dark = true },
}

newTalent{
	name = "Light",
	short_name = "KAM_ELEMENT_LIGHT",
	image = "talents/illuminate.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Luminous ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.LIGHT
	end,
	getSecond = function(self, t)
		return DamageType.KAM_ILLUMINATING_LIGHT
	end,
	getElementDamage = function(self, t, level, useFlatDamage)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE)
		local lightMod = 1.1
		if useFlatDamage then
			lightMod = 1
		end
		return lightMod * tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE)	
		return tal.getIlluminateChance(self, tal, level) -- Look, if you want to Illuminate everything, go ahead.
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 220, colorRTop = 255, colorGLow = 200, colorGTop = 230, colorBLow = 0, colorBTop = 5, colorALow = 220, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Light.
		Effect: Inflict %d Light damage, with a %d%% chance to light targets with Luminescence (reducing their stealth power by 20) for 5 turns. Damage and illumination chance are both multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)),t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Light",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to light targets with Luminescence (reducing their stealth power by 20) for 5 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to light targets with Luminescence (reducing their stealth power by 20) for 5 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to light targets with Luminescence (reducing their stealth power by 20) for 5 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { light = true },
}

newTalent{
	name = "Physical",
	short_name = "KAM_ELEMENT_PHYSICAL",
	image = "talents/boulder_rock.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Earthen ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.PHYSICAL
	end,
	getSecond = function(self, t)
		return DamageType.KAM_WOUNDING_PHYSICAL
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		return tal.getWoundChance(self, tal, level) -- This one you can apply reliably, but only if you focus on application.
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 155, colorRTop = 176, colorGLow = 67, colorGTop = 99, colorBLow = 16, colorBTop = 39, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		local healingReduce = tal.getWoundPower(self, tal)
		return ([[Set the element of your spell to Physical.
		Effect: Inflict %d Physical damage, with a %d%% chance to wound the target, lowering their healing by %d%% for 4 turns. Damage and wounding chance are both multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t), healingReduce)
	end,
	getSpellElementInfo = "Physical",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		local healingReduce = tal.getWoundPower(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to Wound targets, reducing their healing by %d%% for 4 turns]]):tformat(chance, healingReduce)
		elseif isSecond then 
			return ([[and a %d%% chance to Wound targets, reducing their healing by %d%% for 4 turns]]):tformat(chance, healingReduce)
		else
			return ([[Additionally, gain a %d%% chance to Wound targets, reducing their healing by %d%% for 4 turns]]):tformat(chance, healingReduce)
		end
	end,
--	getStatusEffectTypes = { physical = true },
}

newTalent{
	name = "Flame",
	short_name = "KAM_ELEMENT_FLAME",
	image = "talents/flame.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Fiery ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.FIRE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_BURNING_FIRE
	end,
	getElementDamage = function(self, t, level, useFlatDamage)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		local flameMod = 0.4
		if useFlatDamage then
			flameMod = 1
		end
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self) * flameMod
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN)
		return tal.getBurnPower(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 200, colorRTop = 255, colorGLow = 30, colorGTop = 170, colorBLow = 0, colorBTop = 10, colorALow = 220, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Fire.
		Effect: Inflict %d Fire damage and Burn the targets for an additional %d damage over four turns, both multiplied by Spellweave Multiplier. This burning stacks.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), self:damDesc(t.getElement(self, t), t.getStatusChance(self, t)))
	end,
	getSpellElementInfo = "Fire",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		chance = self:damDesc(DamageType.FIRE, chance)
		if alternate then
			return ([[This damage will also Burn targets for an additional %d Fire damage over four turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and Burn targets for an additional %d Fire damage over four turns]]):tformat(chance)
		else
			return ([[Additionally, Burn targets for an additional %d Fire damage over four turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { fire = true },
}

newTalent{
	name = "Lightning",
	short_name = "KAM_ELEMENT_LIGHTNING",
	image = "talents/lightning.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Thunderous ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_LIGHTNING_NO_UNDAZE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_DAZING_LIGHTNING
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		return tal.getDazeChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 130, colorRTop = 255, colorGLow = 235, colorGTop = 255, colorBLow = 245, colorBTop = 255, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Lightning.
		Effect: Inflict %d Lightning damage, with a %d%% chance to daze targets for 3 turns. Damage and daze chance are both multiplied by Spellweave Multiplier.
		Spellwoven Lightning damage does not remove dazes.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Lightning",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Daze targets for 3 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Daze targets for 3 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Daze targets for 3 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { lightning = true },
}

newTalent{
	name = "Cold",
	short_name = "KAM_ELEMENT_COLD",
	image = "talents/frozen_ground.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Frigid ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.COLD
	end,
	getSecond = function(self, t)
		return DamageType.KAM_PINNING_COLD
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN)
		return tal.getPinChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 50, colorRTop = 175, colorGLow = 65, colorGTop = 205, colorBLow = 184, colorBTop = 255, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Cold.
		Effect: Inflict %d Cold damage, with a %d%% chance to freeze targets to the ground, immobilizing them for 4 turns. Damage and freeze chance are both multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Cold",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to freeze targets to the ground, immobilizing them for 4 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to freeze targets to the ground, immobilizing them for 4 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to freeze targets to the ground, immobilizing them for 4 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { cold = true },
}

newTalent{
	name = "Arcane",
	short_name = "KAM_ELEMENT_ARCANE",
	image = "talents/arcane_vortex.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Ethereal ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.ARCANE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_MANABURN
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level) -- Not actually a chance, but treated by system as one.
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY)
		return tal.getManaburning(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 120, colorRTop = 200, colorGLow = 0, colorGTop = 100, colorBLow = 130, colorBTop = 255, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local manaburning = t.getStatusChance(self, t)
		return ([[Set the element of your spell to Arcane.
		Effect: Inflict %d Arcane damage and drain %d mana, %d vim, and %d positive and negative energies, then deal 50%% of the drained mana, 100%% of the drained vim, and 200%% of the drained negative energy as additional arcane damage. Damage and manadrain chance are multiplied by Spellweave Multiplier.
		]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), manaburning, manaburning / 2, manaburning / 4)
	end, 
	getSpellElementInfo = "Arcane",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage drains %d mana, %d vim, and %d positive and negative energies, then deals 50%% of the mana drained, 100%% of the vim, 200%% of the positive energy, and 200%% of the negative energy, whichever is higher, to the target again as additional Arcane damage]]):tformat(chance, chance / 2, chance / 4)
		elseif isSecond then 
			return ([[and drain %d mana, %d vim, and %d positive and negative energies, then deal 50%% of the mana drained, 100%% of the vim, 200%% of the positive energy, and 200%% of the negative energy, whichever is higher, to the target again as additional Arcane damage]]):tformat(chance, chance / 2, chance / 4)
		else
			return ([[Additionally, drain %d mana, %d vim, and %d positive and negative energies, then deal 50%% of the mana drained, 100%% of the vim, 200%% of the positive energy, and 200%% of the negative energy, whichever is higher, to the target again as additional Arcane damage]]):tformat(chance, chance / 2, chance / 4)
		end
	end,
--	getStatusEffectTypes = { arcane = true },
}

newTalent{
	name = "Temporal",
	short_name = "KAM_ELEMENT_TEMPORAL",
	image = "talents/haste.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Temporal ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.TEMPORAL
	end,
	getSecond = function(self, t)
		return DamageType.KAM_SLOWING_TIME
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY)
		return tal.getSlowChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 145, colorRTop = 205, colorGLow = 170, colorGTop = 245, colorBLow = 70, colorBTop = 160, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Temporal.
		Effect: Inflict %d Temporal damage, with a %d%% chance to slow them for 4 turns, reducing their global speed by 35%% and their projectile's speeds by 50%%. Both damage and slowing chance are multiplied by Spellweave Multiplier.
		]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Temporal",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Slow targets, reducing their global speeds by 35%% and their projectile's speeds by 50%% for 4 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Slow targets, reducing their global speeds by 35%% and their projectile's speeds by 50%% for 4 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Slow targets, reducing their global speeds by 35%% and their projectile's speeds by 50%% for 4 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { temporal = true },
}

newTalent{
	name = "Blight",
	short_name = "KAM_ELEMENT_BLIGHT",
	image = "talents/pestilent_blight.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Blighted ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.BLIGHT
	end,
	getSecond = function(self, t)
		return DamageType.KAM_DISEASING_BLIGHT
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		return tal.getDiseaseChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 90, colorRTop = 130, colorGLow = 90, colorGTop = 145, colorBLow = 45, colorBTop = 60, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	getDiseasePower = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		return tal.getDiseasePower(self, tal)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Blight.
		Effect: Inflict %d Blight damage, with a %d%% chance to disease targets, reducing their strength, constitution, or dexterity by %d for 5 turns. These diseases stack, and diseases that are not currently active will be prioritized. Both damage and disease chance are multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t), t.getDiseasePower(self, t))
	end,
	getSpellElementInfo = "Blight",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Disease targets for 5 turns, reducing their strength, constitution, or dexterity (These diseases stack and diseases not currently active will be prioritized. Additionally, diseases with a larger effect will be prioritized)]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Disease targets for 5 turns, reducing their strength, constitution, or dexterity (These diseases stack and diseases not currectly active will be prioritized. Additionally, diseases with a larger effect will be prioritized)]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Disease targets for 5 turns, reducing their strength, constitution, or dexterity (These diseases stack and diseases not currectly active will be prioritized. Additionally, diseases with a larger effect will be prioritized)]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { blight = true },
}

newTalent{
	name = "Acid",
	short_name = "KAM_ELEMENT_ACID",
	image = "talents/acid_splash.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Dissolving ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.ACID
	end,
	getSecond = function(self, t)
		return DamageType.KAM_DISARMING_ACID
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
		return tal.getDisarmChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 50, colorRTop = 90, colorGLow = 150, colorGTop = 255, colorBLow = 50, colorBTop = 90, colorALow = 225, colorATop = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Acid.
		Effect: Inflict %d Acid damage, with a %d%% chance to disarm targets for 3 turns. Both damage and disarm chance are multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Acid",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Disarm targets for 3 turns]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Disarm targets for 3 turns]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Disarm targets for 3 turns]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { acid = true },
}

-- Advanced elements that have two sub-elements.
newTalent{
	name = "Eclipse",
	short_name = "KAM_ELEMENT_ECLIPSE",
	image = "talents/kam_spellweaver_endless_eclipse.png",
--	image = "talents/celestial_surge.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.LIGHT, DamageType.DARKNESS
	end,
	getSpellNameElement = "Eclipsing ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_ECLIPSE_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_ECLIPSE_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY)
		return tal.getCoronaChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 225, colorRTop = 255, colorGLow = 225, colorGTop = 255, colorBLow = 225, colorBTop = 255, colorALow = 225, colorATop = 255, colorRLowAlt = 0, colorRTopAlt = 25, colorGLowAlt = 0, colorGTopAlt = 25, colorBLowAlt = 0, colorBTopAlt = 25, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY)
		local resistanceDamage = tal.getResistanceBreaking(self, tal)
		local defenseDamage = tal.getDefensesPenalty(self, tal)
		local armorDamage = tal.getArmorPenalty(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Eclipse, combining both Light and Darkness.
		Effect: Inflict %d Light and %d Dark damage, with a %d%% chance to afflict targets with an Eclipsing Corona for 4 turns, lowering their resistances by %d%%, their defense and stealth power by %d and their armor and invisibility power by %d. Armor, defense, and stealth and invisibility power reduction scales with Magic. Chance is multiplied by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t), resistanceDamage, defenseDamage, armorDamage)
	end,
	getSpellElementInfo = "Eclipse",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY)
		local resistanceDamage = tal.getResistanceBreaking(self, tal)
		local defenseDamage = tal.getDefensesPenalty(self, tal)
		local armorDamage = tal.getArmorPenalty(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to afflict targets with an Eclipsing Corona for 4 turns, lowering their resistances by %d%%, their defense and stealth power by %d and their armor and invisibility power by %d]]):
			tformat(chance, resistanceDamage, defenseDamage, armorDamage)
		elseif isSecond then 
			return ([[and a %d%% chance to afflict targets with an Eclipsing Corona for 4 turns, lowering their resistances by %d%%, their defense and stealth power by %d and their armor and invisibility power by %d]]):
			tformat(chance, resistanceDamage, defenseDamage, armorDamage)
		else
			return ([[Additionally, gain a %d%% chance to afflict targets with an Eclipsing Corona for 4 turns, lowering their resistances by %d%%, their defense and stealth power by %d and their armor and invisibility power by %d]]):
			tformat(chance, resistanceDamage, defenseDamage, armorDamage)
		end
	end,
--	getStatusEffectTypes = { light = true, dark = true },
}

newTalent{
	name = "Molten",
	short_name = "KAM_ELEMENT_MOLTEN",
	image = "talents/kam_spellweaver_eyals_flames.png",
--	image = "talents/elemental_retribution.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.FIRE, DamageType.PHYSICAL
	end,
	getSpellNameElement = "Molten ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_MOLTEN_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_MOLTEN_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_MASTERY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_MASTERY)
		return tal.getMoltenChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 225, colorRTop = 255, colorGLow = 0, colorGTop = 30, colorBLow = 0, colorBTop = 30, colorALow = 225, colorATop = 255, colorRLowAlt = 100, colorRTopAlt = 150, colorGLowAlt = 70, colorGTopAlt = 100, colorBLowAlt = 10, colorBTopAlt = 20, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_MASTERY)
		local moltenFloorTurns = tal.getMoltenFloorTurns(self, tal)
		local floorDamage = tal.getMoltenDamage(self, tal)
		local healReduction = tal.getHealReduction(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Molten, combining both Fire and Physical.
		Effect: Inflict %d Fire and %d Physical damage, with a %d%% chance to scorch the earth for %d turns, creating Molten tiles that deal %d Fire and %d Physical damage and inflict enemies with Molten Drain for 1 turn, redirecting %d%% of any direct heals they recieve to you. Chance is multipled by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t), moltenFloorTurns, self:damDesc(DamageType.FIRE, floorDamage), self:damDesc(DamageType.PHYSICAL, floorDamage), healReduction)
	end,
	getSpellElementInfo = "Molten",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_MASTERY)
		local moltenFloorTurns = tal.getMoltenFloorTurns(self, tal)
		local floorDamage = tal.getMoltenDamage(self, tal)
		local healReduction = tal.getHealReduction(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to scorch the earth for %d turns, creating Molten tiles that deal %d Fire and %d Physical damage and inflict enemies with Molten Drain for 1 turn, redirecting %d%% of any direct heals they recieve to you]]):
			tformat(chance, moltenFloorTurns, self:damDesc(DamageType.FIRE, floorDamage), self:damDesc(DamageType.PHYSICAL, floorDamage), healReduction)
		elseif isSecond then 
			return ([[and a %d%% chance to scorch the earth for %d turns, creating Molten tiles that deal %d Fire and %d Physical damage and inflict enemies with Molten Drain for 1 turn, redirecting %d%% of any direct heals they recieve to you]]):
			tformat(chance, moltenFloorTurns, self:damDesc(DamageType.FIRE, floorDamage), self:damDesc(DamageType.PHYSICAL, floorDamage), healReduction)
		else
			return ([[Additionally, gain a %d%% chance to scorch the earth for %d turns, creating Molten tiles that deal %d Fire and %d Physical damage and inflict enemies with Molten Drain for 1 turn, redirecting %d%% of any direct heals they recieve to you]]):
			tformat(chance, moltenFloorTurns, self:damDesc(DamageType.FIRE, floorDamage), self:damDesc(DamageType.PHYSICAL, floorDamage), healReduction)
		end
	end,
--	getStatusEffectTypes = { fire = true, physical = true },
}

newTalent{
	name = "Otherworldly",
	short_name = "KAM_ELEMENT_OTHERWORLDLY",
	image = "talents/kam_spellweaver_unreal_showing.png",
--	image = "talents/temporal_bolt.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.ARCANE, DamageType.TEMPORAL
	end,
	getSpellNameElement = "Otherworldly ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_OTHERWORLDLY_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_OTHERWORLDLY_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY)
		return tal.getChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 150, colorRTop = 190, colorGLow = 150, colorGTop = 190, colorBLow = 150, colorBTop = 190, colorALow = 225, colorATop = 255, colorRLowAlt = 125, colorRTopAlt = 195, colorGLowAlt = 0, colorGTopAlt = 25, colorBLowAlt = 200, colorBTopAlt = 255, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY)
		local effNumber = tal.effectNumber(self, tal)
		local durationChange = tal.getDuration(self, tal)
		local durationChangeYou = tal.getDurationYou(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Otherworldly, combining both Arcane and Temporal.
		Effect: Inflict %d Arcane and %d Temporal damage, with a %d%% chance to drain time from targets, reducing the duration of up to %d of their beneficial effects by %d and increasing the duration of the same number of yours by %d (half as much, always rounded up). This chance is multiplied by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t), effNumber, durationChange, durationChangeYou)
	end,
	getSpellElementInfo = "Otherworldly",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY)
		local effNumber = tal.effectNumber(self, tal)
		local durationChange = tal.getDuration(self, tal)
		local durationChangeYou = tal.getDurationYou(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to drain time from targets, reducing the duration of up to %d of their beneficial effects by %d and increasing the duration of the same number of yours by %d (half as much, always rounded up)]]):
			tformat(chance, effNumber, durationChange, durationChangeYou)
		elseif isSecond then 
			return ([[and a %d%% chance to drain time from targets, reducing the duration of up to %d of their beneficial effects by %d and increasing the duration of the same number of yours by %d (half as much, always rounded up)]]):
			tformat(chance, effNumber, durationChange, durationChangeYou)
		else
			return ([[Additionally, gain a %d%% chance to drain time from targets, reducing the duration of up to %d of their beneficial effects by %d and increasing the duration of the same number of yours by %d (half as much, always rounded up)]]):
			tformat(chance, effNumber, durationChange, durationChangeYou)
		end
	end,
--	getStatusEffectTypes = { arcane = true, temporal = true },
}

newTalent{
	name = "Wind and Rain",
	short_name = "KAM_ELEMENT_WIND_AND_RAIN",
	image = "talents/kam_spellweaver_the_dreadful_wind_and_rain.png",
--	image = "talents/thunderclap.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.COLD, DamageType.LIGHTNING
	end,
	getSpellNameElement = "Hailstorming ", -- Sigh. The Wind and Raind just doesn't fit in here. NO way I can make it.
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_WIND_AND_RAIN_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY)
		return tal.getChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 40, colorRTop = 75, colorGLow = 70, colorGTop = 95, colorBLow = 180, colorBTop = 210, colorALow = 225, colorATop = 255, colorRLowAlt = 0, colorRTopAlt = 35, colorGLowAlt = 200, colorGTopAlt = 255, colorBLowAlt = 200, colorBTopAlt = 255, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY)
		tal.doUpdateCount(self, tal)
		local icestormDamage = tal.getIcestormDamage(self, tal)
		local radius = tal.getRadius(self, tal)
		local duration = tal.getDuration(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Hailstorm, combining both Cold and Lightning.
		Effect: Inflict %d Cold and %d Lightning damage, with a %d%% to surround targets with an Icestorm, halving their Pinning and Stun resistance and dealing %d Hailstorm damage to every enemy around them in radius %d for %d turns. Icestorm damage does not break dazes, and the chance of inflicting an Icestorm is multiplied by Spellweave Multiplier. The chance of inflicting icestorm reduces by 15%% for each icestorm present on the level (additively).
		Hailstorm damage does not break dazes.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t) * tal.getChanceMod(self, tal), self:damDesc(DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE,icestormDamage), radius, duration)
	end,
	getSpellElementInfo = "Hailstorm",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY)
		tal.doUpdateCount(self, tal)
		chance = chance * tal.getChanceMod(self, tal)
		local icestormDamage = tal.getIcestormDamage(self, tal)
		local radius = tal.getRadius(self, tal)
		local duration = tal.getDuration(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to surround targets with an Icestorm (reduced by 15%% for each icestorm present on the level), halving their Pinning and Stun resistance and dealing %d damage, equally divided between Cold and Lightning, to every enemy around them in radius %d for %d turns, which will not break dazes.]]):
			tformat(chance, self:damDesc(DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE,icestormDamage), radius, duration)
		elseif isSecond then 
			return ([[and a %d%% chance to surround targets with an Icestorm, halving their Pinning and Stun resistance and dealing %d damage, equally divided between Cold and Lightning, to every enemy around them in radius %d for %d turns, which will not break dazes. The chance of inflicting icestorm reduces by 15%% for each icestorm present on the level]]):
			tformat(chance, self:damDesc(DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE,icestormDamage), radius, duration)
		else
			return ([[Additionally, gain a %d%% chance to surround targets with an Icestorm (reduced by 15%% for each icestorm present on the level), halving their Pinning and Stun resistance and dealing %d damage, equally divided between Cold and Lightning, to every enemy around them in radius %d for %d turns, which will not break dazes]]):
			tformat(chance, self:damDesc(DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE,icestormDamage), radius, duration)
		end
	end,
--	getStatusEffectTypes = { cold = true, lightning = true },
}

newTalent{
	name = "Ruin",
	short_name = "KAM_ELEMENT_RUIN",
	image = "talents/kam_spellweaver_absolute_ruin.png",
--	image = "talents/corpse_explosion.png",
	type = {"spellweaving/elements", 1},
	points = 5,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.ACID, DamageType.BLIGHT
	end,
	getSpellNameElement = "Ruinous ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_RUIN_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_RUIN_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN_MASTERY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN_MASTERY)
		return tal.getRuinChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 110, colorRTop = 150, colorGLow = 100, colorGTop = 150, colorBLow = 30, colorBTop = 60, colorALow = 225, colorATop = 255, colorRLowAlt = 20, colorRTopAlt = 80, colorGLowAlt = 225, colorGTopAlt = 255, colorBLowAlt = 20, colorBTopAlt = 80, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN_MASTERY)
		local damageReduction = tal.getDamageBreaking(self, tal)
		local powerReduction = tal.getPowerReduction(self, tal)
		local accuracyPenReduction = tal.getAccuracyPenReduction(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Ruin, combining both Acid and Blight.
		Effect: Inflict %d Acid and %d Blight damage, with a %d%% chance to afflict targets with Ruinous Exhaustion for 4 turns, lowering their damage by %d%%, their all damage penetration by %d%%, their Physical Power, Mindpower, and Spellpower by %d, and their accuracy by %d. Powers, crit chance, and accuracy reduction scales with Magic. Chance is multiplied by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t), damageReduction, accuracyPenReduction, powerReduction, accuracyPenReduction)
	end,
	getSpellElementInfo = "Ruin",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN_MASTERY)
		local damageReduction = tal.getDamageBreaking(self, tal)
		local powerReduction = tal.getPowerReduction(self, tal)
		local accuracyPenReduction = tal.getAccuracyPenReduction(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance to afflict targets with Ruinous Exhaustion for 4 turns, lowering their damage by %d%%, their all damage penetration by %d%%, their Physical Power, Mindpower, and Spellpower by %d, and their crit chance and accuracy by %d]]):
			tformat(chance, damageReduction, accuracyPenReduction, powerReduction, accuracyPenReduction)
		elseif isSecond then 
			return ([[and a %d%% chance to afflict targets with Ruinous Exhaustion for 4 turns, lowering their damage by %d%%, their all damage penetration by %d%%, their Physical Power, Mindpower, and Spellpower by %d, and their crit chance and accuracy by %d]]):
			tformat(chance, damageReduction, accuracyPenReduction, powerReduction, accuracyPenReduction)
		else
			return ([[Additionally, gain a %d%% chance to afflict targets with Ruinous Exhaustion for 4 turns, lowering their damage by %d%%, their all damage penetration by %d%%, their Physical Power, Mindpower, and Spellpower by %d, and their crit chance and accuracy by %d]]):
			tformat(chance, damageReduction, accuracyPenReduction, powerReduction, accuracyPenReduction)
		end
	end,
--	getStatusEffectTypes = { acid = true, blight = true },
}

newTalent{
	name = "Gravechill",
	short_name = "KAM_ELEMENT_GRAVECHILL",
	image = "talents/kam_spellweaver_gravechill.png",
--	image = "talents/grave_mistake.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	is_necromancy = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.COLD, DamageType.DARKNESS
	end,
	getSpellNameElement = "Gravechilling ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_GRAVECHILL_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_GRAVECHILL_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVECHILL)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 0, colorRTop = 25, colorGLow = 0, colorGTop = 25, colorBLow = 0, colorBTop = 25, colorALow = 225, colorATop = 255, colorRLowAlt = 50, colorRTopAlt = 80, colorGLowAlt = 50, colorGTopAlt = 80, colorBLowAlt = 150, colorBTopAlt = 200, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVECHILL)
		local armor = tal.getArmor(self, tal)
		local skeletonDuration = tal.getSkeletonDuration(self, tal)
		local skeletonChance = tal.getSkeletonChance(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Frostdusk, combining both Cold and Darkness.
		Effect: Inflict %d Cold and %d Dark damage, gain a stacking %d Armor per target hit, and inflict targets with the chill of the grave, giving them a %d%% chance to rise as skeletons upon death for %d turns. Skeleton stats scale with Gravechill talent level. Armor and chance is multiplied by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), armor, skeletonChance, skeletonDuration)
	end,
	getSpellElementInfo = "Frostdusk",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVECHILL)
		local armor = tal.getArmor(self, tal) * chance
		local skeletonDuration = tal.getSkeletonDuration(self, tal)
		local skeletonChance = tal.getSkeletonChance(self, tal) * chance
		if alternate then
			return ([[This damage causes you to gain a stacking %d Armor for 5 turns per target hit, and inflict targets with the chill of the grave, giving them a %d%% chance to rise as skeletons upon death for %d turns (with skeleton stats increasing with Gravechill talent level)]]):
			tformat(armor, skeletonChance, skeletonDuration)
		elseif isSecond then 
			return ([[and increase your Armor stackingly by %d for 5 turns per target hit and inflict targets with the chill of the grave, giving them a %d%% chance to rise as skeletons upon death for %d turns (with skeleton stats increasing with Gravechill talent level)]]):
			tformat(armor, skeletonChance, skeletonDuration)
		else
			return ([[Additionally, gain a stacking %d Armor for 5 turns per target hit, and inflict targets with the chill of the grave, giving them a %d%% chance to rise as skeletons upon death for %d turns (with skeleton stats increasing with Gravechill talent level)]]):
			tformat(armor, skeletonChance, skeletonDuration)
		end
	end,
--	getStatusEffectTypes = { cold = true, dark = true },
}

newTalent{
	name = "Gravitic (Pushing)",
	short_name = "KAM_ELEMENT_GRAVITY",
	image = "talents/kam_spellweaver_gravity_push.png",
--	image = "talents/gravity_locus.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.PHYSICAL, DamageType.TEMPORAL
	end,
	getSpellNameElement = "Gravitic ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_GRAVITY_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_GRAVITY_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 50, colorRTop = 90, colorGLow = 150, colorGTop = 255, colorBLow = 50, colorBTop = 90, colorALow = 225, colorATop = 255, colorRLowAlt = 155, colorRTopAlt = 175, colorGLowAlt = 65, colorGTopAlt = 100, colorBLowAlt = 15, colorBTopAlt = 40, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		local exhaustionPower = tal.getGraviticExhaustion(self, tal)
		local exhaustionDuration = tal.getGraviticExhaustionDuration(self, tal)
		local pushDistance = tal.getPushDist(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Gravitic, combining both Physical and Temporal.
		Effect: Inflict %d Physical and %d Temporal damage, and knocking targets back %d tiles from you (if the spell originates on you like a beam or spiral) or the center of the spell and inflicting them with Gravitic Exhausion for %d turns, reducing their knockback resistance by %d%%. Targets slammed into things take an additional 20%% of base damage as Physical and Temporal damage. Knockback distance and resistance reduction are modified by Spellweave Multiplier (but knockback distance is minimum 1).]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), pushDistance, exhaustionDuration, exhaustionPower)
	end,
	getSpellElementInfo = "Gravitic",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		local exhaustionPower = tal.getGraviticExhaustion(self, tal) * chance
		local exhaustionDuration = tal.getGraviticExhaustionDuration(self, tal)
		local pushDistance = math.max(1, tal.getPushDist(self, tal) * chance)
		if alternate then
			return ([[This damage knocks targets back %d tiles from you (if the spell originates on you like a beam or spiral) or the center of the spell, reduces their knockback resistance by %d%% for %d turns, and deals an addition 20%% of base damage as Physical and Temporal damage to targets who slam into solid objects]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		elseif isSecond then 
			return ([[and knocks targets back %d tiles from you (if the spell originates on you like a beam or spiral) or the center of the spell, reduces their knockback resistance by %d%% for %d turns, and deals an addition 20%% of base damage as Physical and Temporal damage to targets who slam into solid objects]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		else
			return ([[Additionally, this knocks targets back %d tiles from you (if the spell originates on you like a beam or spiral) or the center of the spell, reduces their knockback resistance by %d%% for %d turns, and deals an addition 20%% of base damage as Physical and Temporal damage to targets who slam into solid objects]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		end
	end,
--	getStatusEffectTypes = { temporal = true, physical = true },
}

newTalent{
	name = "Gravitic (Pulling)",
	short_name = "KAM_ELEMENT_GRAVITY_PULL",
	image = "talents/kam_spellweaver_gravity_pull.png",
--	image = "talents/gravity_locus.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	isKamNotRandomElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.PHYSICAL, DamageType.TEMPORAL
	end,
	getSpellNameElement = "Gravitic-Pulling ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_GRAVITY_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_GRAVITY_PULL_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		return tal.getDamagePulling(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 50, colorRTop = 90, colorGLow = 150, colorGTop = 255, colorBLow = 50, colorBTop = 90, colorALow = 225, colorATop = 255, colorRLowAlt = 155, colorRTopAlt = 175, colorGLowAlt = 65, colorGTopAlt = 100, colorBLowAlt = 15, colorBTopAlt = 40, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		local exhaustionPower = tal.getGraviticExhaustion(self, tal)
		local exhaustionDuration = tal.getGraviticExhaustionDuration(self, tal)
		local pushDistance = tal.getPushDist(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Gravitic, combining both Physical and Temporal.
		Effect: Inflict %d Physical and %d Temporal damage, and pull targets %d tiles torwards you (if the spell originates on you, like a beam or a spiral, or is a lingering effect) or the center of the spell and inflicting them with Gravitic Exhausion for %d turns, reducing their knockback resistance by %d%%. Pull distance and resistance reduction are modified by Spellweave Multiplier (but pull distance is minimum 1).]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), pushDistance, exhaustionDuration, exhaustionPower)
	end,
	getSpellElementInfo = "Gravitic-Pull",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY)
		local exhaustionPower = tal.getGraviticExhaustion(self, tal) * chance
		local exhaustionDuration = tal.getGraviticExhaustionDuration(self, tal)
		local pushDistance = math.max(1, tal.getPushDist(self, tal) * chance)
		if alternate then
			return ([[This damage pulls targets %d tiles torwards you (if the spell originates on you, like a beam or a spiral, or is a lingering effect) or the center of the spell and reduces their knockback resistance by %d%% for %d turns]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		elseif isSecond then 
			return ([[and pulls targets %d tiles torwards you (if the spell originates on you, like a beam or a spiral, or is a lingering effect) or the center of the spell and reduces their knockback resistance by %d%% for %d turns]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		else
			return ([[Additionally, this pulls targets %d tiles torwards you (if the spell originates on you, like a beam or a spiral, or is a lingering effect) or the center of the spell and reduces their knockback resistance by %d%% for %d turns]]):
			tformat(pushDistance, exhaustionPower, exhaustionDuration)
		end
	end,
--	getStatusEffectTypes = { temporal = true, physical = true },
}

newTalent{
	name = "Fever",
	short_name = "KAM_ELEMENT_FEVER",
	image = "talents/kam_spellweaver_fever.png",
--	image = "talents/energy_absorption.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.BLIGHT, DamageType.FIRE
	end,
	getSpellNameElement = "Feverish ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_FEVER_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_FEVER_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_FEVER)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 90, colorRTop = 130, colorGLow = 90, colorGTop = 145, colorBLow = 45, colorBTop = 60, colorALow = 225, colorATop = 255, colorRLowAlt = 200, colorRTopAlt = 255, colorGLowAlt = 30, colorGTopAlt = 170, colorBLowAlt = 0, colorBTopAlt = 10, colorALowAlt = 220, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_FEVER)
		local feverDamage = tal.getFeverDamage(self, tal)
		local feverDuration = tal.getFeverDuration(self, tal)
		local feverPower = tal.getFeverPower(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Plaguefire, combining both Blight and Fire.
		Effect: Inflict %d Blight and %d Fire damage, and inflict targets with a draining fever, reducing their magic, willpower, or cunning by %d for %d turns. These diseases stack, and diseases with the greatest effect are prioritized. Additionally, diseased targets will take %d draining Plaguefire damage over the fever's duration, healing you for amount of damage dealt. Draining damage and stat reduction are multiplied by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), feverPower, feverDuration, feverDamage)
	end,
	getSpellElementInfo = "Plaguefire",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_FEVER)
		local feverDamage = tal.getFeverDamage(self, tal) * chance
		local feverDuration = tal.getFeverDuration(self, tal)
		local feverPower = tal.getFeverPower(self, tal) * chance
		if alternate then
			return ([[This damage inflicts targets with a draining fever, reducing their magic, willpower, or cunning by %d for %d turns and dealing %d draining Plaguefire damage over the fever's duration (diseases with the greatest effect will be prioritized)]]):
			tformat(feverPower, feverDuration, feverDamage)
		elseif isSecond then 
			return ([[and inflicts targets with a draining fever, reducing their magic, willpower, or cunning by %d for %d turns and dealing %d draining Plaguefire damage over the fever's duration (diseases with the greatest effect will be prioritized)]]):
			tformat(feverPower, feverDuration, feverDamage)
		else
			return ([[Additionally, this inflicts targets with a draining fever, reducing their magic, willpower, or cunning by %d for %d turns and dealing %d draining Plaguefire damage over the fever's duration (diseases with the greatest effect will be prioritized)]]):
			tformat(feverPower, feverDuration, feverDamage)
		end
	end,
--	getStatusEffectTypes = { blight = true, fire = true },
}

newTalent{
	name = "Manastorm",
	short_name = "KAM_ELEMENT_MANASTORM",
	image = "talents/kam_spellweaver_manastorm.png",
--	image = "talents/anomaly_invigorate.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.ARCANE, DamageType.LIGHTNING
	end,
	getSpellNameElement = "Manastorming ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_MANASTORM_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_MANASTORM_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MANASTORM)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MANASTORM)
		return tal.getChance(self, tal, level)
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 120, colorRTop = 200, colorGLow = 0, colorGTop = 100, colorBLow = 130, colorBTop = 255, colorALow = 225, colorATop = 255, colorRLowAlt = 50, colorRTopAlt = 175, colorGLowAlt = 65, colorGTopAlt = 205, colorBLowAlt = 184, colorBTopAlt = 255, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MANASTORM)
		local resourceDrain = tal.getResourceDrain(self, tal)
		local radius = tal.getRadius(self, tal)
		local duration = tal.getDuration(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Manastorm, combining both Arcane and Lightning.
		Effect: Inflict %d Arcane and %d Lightning damage, with a %d%% to surround targets with a Manastorm, draining %d resources (based on the resource scaling in the Manastorm talent in the Elementalist tree) from every enemy around them in radius %d for %d turns, and restoring your mana based on the amount drained. The chance of inflicting a Manastorm is multiplied by Spellweave Multiplier, but is reduced by 15%% for each Manastorm present on the level (additively).]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), t.getStatusChance(self, t) * tal.getChanceMod(self, tal), resourceDrain, radius, duration)
	end,
	getSpellElementInfo = "Manastorm",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MANASTORM)
		local resourceDrain = tal.getResourceDrain(self, tal)
		chance = chance * tal.getChanceMod(self, tal)
		local radius = tal.getRadius(self, tal)
		local duration = tal.getDuration(self, tal)
		if alternate then
			return ([[This damage has a %d%% chance (reduced by 15%% for each Manastorm on the level) to surround targets with a Manastorm, draining %d resources (based on the resource scaling in the Manastorm talent in the Elementalist tree), from every enemy around them in radius %d for %d turns]]):
			tformat(chance, resourceDrain, radius, duration)
		elseif isSecond then 
			return ([[and a %d%% chance (reduced by 15%% for each Manastorm on the level) to surround targets with a Manastorm, draining %d resources (based on the resource scaling in the Manastorm talent in the Elementalist tree), from every enemy around them in radius %d for %d turns]]):
			tformat(chance, resourceDrain, radius, duration)
		else
			return ([[Additionally, gain a %d%% chance (reduced by 15%% for each Manastorm on the level) to surround targets with a Manastorm, draining %d resources (based on the resource scaling in the Manastorm talent in the Elementalist tree), from every enemy around them in radius %d for %d turns]]):
			tformat(chance, resourceDrain, radius, duration)
		end
	end,
--	getStatusEffectTypes = { arcane = true, lightning = true },
}

newTalent{
	name = "Corroding Brilliance",
	short_name = "KAM_ELEMENT_CORRODING_BRILLIANCE",
	image = "talents/kam_spellweaver_corrosive_brilliance.png",
--	image = "talents/charge_leech.png",
	type = {"spellweaving/elements", 1},
	points = 3,
	mode = "passive",
	isKamElement = true,
	isKamDoubleElement = true,
	getKamDoubleElements = function()
		return DamageType.ACID, DamageType.LIGHT
	end,
	getSpellNameElement = "Radiat ", -- It means nothing, but corrosively brilliant is just too long. Skill names get silly enough here.
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_CORRODING_BRILLIANCE_DAMAGE_TYPE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_CORRODING_BRILLIANCE_SECOND
	end,
	getElementDamage = function(self, t, level)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE)
		return tal.getDamage(self, tal, level) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 220, colorRTop = 255, colorGLow = 200, colorGTop = 230, colorBLow = 0, colorBTop = 5, colorALow = 220, colorATop = 255, colorRLowAlt = 145, colorRTopAlt = 205, colorGLowAlt = 170, colorGTopAlt = 245, colorBLowAlt = 70, colorBTopAlt = 160, colorALowAlt = 225, colorATopAlt = 255}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE)
		local repeatChance = tal.getRepeatChance(self, tal)
		local drainPower = tal.getDrain(self, tal)
		local radiamarkDuration = tal.getDuration(self, tal)
		local elementOne, elementTwo = t.getKamDoubleElements()
		return ([[Set the element of your spell to Corrosive Brilliance, combining both Acid and Light.
		Effect: Inflict %d Acid and %d Light damage, and inflict targets with Radiamarks for %d turns, causing your melee attacks made against them to heal you for %d%% of the damage dealt and to have a %d%% chance to instantly make a bonus attack (each target can only have one bonus attack made against them per turn), and preventing them from gaining evasion benefits for being unseen. Melee attack repetition chance and life restoring is modified by Spellweave Multiplier.]]):
		tformat(self:damDesc(elementOne, t.getElementDamage(self, t) / 2), self:damDesc(elementTwo, t.getElementDamage(self, t) / 2), radiamarkDuration, drainPower, repeatChance)
	end,
	getSpellElementInfo = "Radiat",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE)
		local repeatChance = tal.getRepeatChance(self, tal) * chance
		local drainPower = tal.getDrain(self, tal) * chance
		local radiamarkDuration = tal.getDuration(self, tal)
		if alternate then
			return ([[This damage inflicts targets with Radiamarks for %d turns, causing your melee attacks made against them to heal you for %d%% of the damage dealt and to have a %d%% chance to instantly make a bonus attack (each target can only have one bonus attack made against them per turn), and preventing them from gaining evasion benefits for being unseen]]):
			tformat(radiamarkDuration, drainPower, repeatChance)
		elseif isSecond then 
			return ([[and inflicts targets with Radiamarks for %d turns, causing your melee attacks made against them to heal you for %d%% of the damage dealt and to have a %d%% chance to instantly make a bonus attack (each target can only have one bonus attack made against them per turn), and preventing them from gaining evasion benefits for being unseen]]):
			tformat(radiamarkDuration, drainPower, repeatChance)
		else
			return ([[Additionally, this inflicts targets with Radiamarks for %d turns, causing your melee attacks made against them to heal you for %d%% of the damage dealt and to have a %d%% chance to instantly make a bonus attack (each target can only have one bonus attack made against them per turn), and preventing them from gaining evasion benefits for being unseen]]):
			tformat(radiamarkDuration, drainPower, repeatChance)
		end
	end,
--	getStatusEffectTypes = { acid = true, light = true },
}

-- Special "elements" that function weirdly.
newTalent{
	name = "Duo",
	short_name = "KAM_ELEMENT_DOUBLE",
	image = "talents/kam_spellweaver_two.png",
--	image = "talents/darkness.png",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	isKamElement = true,
	isKamNotRandomElement = true,
	isKamDuo = true,
	getSpellNameElement = "and ",
	no_npc_use = true,
	getElement = function(self, t) 
		return true
	end,
	getSecond = function(self, t)
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getStatusChance = function(self, t)
		return nil
	end,
	getElementColors = function(self, argsList, t)
		return nil
	end,
	info = function(self, t)
		return ([[Set the element of your spell to two other elements, gaining both of their damages and effects, with both at half power.]])
	end,
	getSpellElementInfo = "and",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[If you see this, please report with this note: (Duo, alternate = true) and the set of components used to make the spell. Thank you.]]):tformat()
		elseif isSecond then 
			return ([[You should never see this, if you do please report this with this note: (Duo, isSecond = true) and the set of compontents needed to make the spell. Thank you.]])
		else
			return ([[You should never see this, if you do please report this with this note: (Duo, isSecond = false) and the set of compontents needed to make the spell. Thank you.]])
		end
	end,
}

newTalent{
	name = "Random",
	short_name = "KAM_ELEMENT_ELEMENTAL_RANDOM",
	image = "talents/kam_spellweaver_element_random.png", -- I just realized I typo'd this to nullfication. Meh.
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	isKamElement = true,
	isKamElementRandom = true,
	getSpellNameElement = "Random ",
	no_npc_use = true,
	getElement = function(self, t)
		if game.state.kam_spellweaver_random_element then
			return game.state.kam_spellweaver_random_element.getElement(self, game.state.kam_spellweaver_random_element)
		end
		return DamageType.KAM_ELEMENTLESS_DAMAGE
	end,
	getSecond = function(self, t)
		if game.state.kam_spellweaver_random_element then
			return game.state.kam_spellweaver_random_element.getSecond(self, game.state.kam_spellweaver_random_element)
		end
		return DamageType.KAM_ELEMENTLESS_SECOND
	end,
	getElementDamage = function(self, t)
		if game.state.kam_spellweaver_random_element then
			return 1.1 * game.state.kam_spellweaver_random_element.getElementDamage(self, game.state.kam_spellweaver_random_element, game.state.kam_spellweaver_random_element_level)
		end
		return 1.1 * KamCalc:coreSpellweaveElementDamageFunction(self, KamCalc:getAverageHighestElementTalentLevel(self, 3) * 5, 5)
	end,
	getStatusChance = function(self, t)
		if game.state.kam_spellweaver_random_element then
			return 1.1 * game.state.kam_spellweaver_random_element.getStatusChance(self, game.state.kam_spellweaver_random_element, game.state.kam_spellweaver_random_element_level)
		end
		return 0
	end,
	getElementColors = function(self, argsList, t)
		if t.isKamDoubleShape and t.isKamElementRandom1 and t.isKamElementRandom2 then -- I don't want to re-write a bunch of code for this one super niche situtation.
			local colorsTable = {colorRLow = 0, colorRTop = 255, colorGLow = 0, colorGTop = 255, colorBLow = 0, colorBTop = 255, colorALow = 220, colorATop = 255}
			table.mergeAdd(argsList, colorsTable)
		else
			if game.state.kam_spellweaver_random_element then
				game.state.kam_spellweaver_random_element.getElementColors(self, argsList, game.state.kam_spellweaver_random_element)
			else
				local colorsTable = {colorRLow = 0, colorRTop = 255, colorGLow = 0, colorGTop = 255, colorBLow = 0, colorBTop = 255, colorALow = 220, colorATop = 255}
				table.mergeAdd(argsList, colorsTable)
			end
		end
	end,
	info = function(self, t)
		local approximateDamage = KamCalc:coreSpellweaveElementDamageFunction(self, KamCalc:getAverageHighestElementTalentLevel(self, 3) * 5, 5)
		return ([[Set the element of your spell to random, choosing a random element when the spell is casted. The average of your highest three talent levels will be used as the talent level for whatever random element is selected.
		Effect: Inflict around %d damage of a random element, including the chance to inflict its effects. The Spellweave Multiplier for this spell's damage and status chance and power is increased by 10%%.]]):tformat(approximateDamage)
	end,
	getSpellElementInfo = "Random",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage can inflict the status effect of the randomly chosen element with 10%% increased chance and power]]):tformat()
		elseif isSecond then 
			return ([[and can inflict the status effect of the randomly chosen element with 10%% increased chance and power]]):tformat()
		else
			return ([[Additionally, gain a chance to inflict the status effect of the randomly chosen element with 10%% increased chance and power]]):tformat()
		end
	end,
--	getStatusEffectTypes = { },
}

newTalent{
	name = "Elemental Purification",
	short_name = "KAM_ELEMENT_ELEMENTAL_PURIFICATION",
	image = "status/kam_spellweaver_elemental_nullfication.png", -- I just realized I typo'd this to nullfication. Meh.
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	isKamElement = true,
	getSpellNameElement = "Pure ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE
	end,
	getSecond = function(self, t)
		return DamageType.KAM_ELEMENTLESS_SECOND
	end,
	getElementDamage = function(self, t)
		return KamCalc:coreSpellweaveElementDamageFunction(self, KamCalc:getAverageHighestElementTalentLevel(self, 1), 1) * getDamageMultiplier(self)
	end,
	getStatusChance = function(self, t)
		return 50
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 127, colorRTop = 150, colorGLow = 127, colorGTop = 150, colorBLow = 127, colorBTop = 150, colorALow = 150, colorATop = 200}
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to elementless.
		Effect: Inflict %d piercing elementless damage, which ignores all elemental resists and half of the targets all resistance (before resistance piercing) but only benefits from your all damage increase, with a %d%% chance to elementally nullify targets for 5 turns, converting all of their damage to non-piercing elementless damage, which does not ignore all resistance, and reducing all of it by 30%%. Damage and nullification chance are both multiplied by Spellweave Multiplier.]]):tformat(self:damDesc(t.getElement(self, t), t.getElementDamage(self, t)), t.getStatusChance(self, t))
	end,
	getSpellElementInfo = "Pure",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a %d%% chance to Elementally Nullify targets for 5 turns, converting their damage to elementless damage and reducing it by 30%%]]):tformat(chance)
		elseif isSecond then 
			return ([[and a %d%% chance to Elementally Nullify targets for 5 turns, converting their damage to elementless damage and reducing it by 30%%]]):tformat(chance)
		else
			return ([[Additionally, gain a %d%% chance to Elementally Nullify targets for 5 turns, converting their damage to elementless damage and reducing it by 30%%]]):tformat(chance)
		end
	end,
--	getStatusEffectTypes = { },
}

-- Note: Does not bold crits correctly. Not sure if there's a great way to fix it given how crits are divided out among things but...
newTalent{ -- This thing had some truly NIGHTMARISH special cases, but most of them have now been removed after I redesigned how it handled damage to be... actually understandable to anyone, ever.
	name = "Prismatic",
	short_name = "KAM_ELEMENT_PRISMA",
	image = "talents/kam_spellweaver_spellweaver_adept.png",
--	image = "talents/chromatic_fury.png",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	isKamElement = true,
	isKamNotRandomElement = true,
	isKamPrismatic = true, -- Used for special effects of things like the resistance changing effects.
	getSpellNameElement = "Prismatic ",
	no_npc_use = true,
	getElement = function(self, t) 
		return DamageType.KAM_SPELLWEAVE_PRISMATIC
	end,
	getSecond = function(self, t)
		return DamageType.KAM_SPELLWEAVE_PRISMATIC_SECONDARY
	end,
	getElementCount = function(self) 
		return countElements(self)
	end,
	getElementDamage = function(self, t)
		return KamCalc:coreSpellweaveElementDamageFunction(self, KamCalc:getAverageHighestElementTalentLevel(self, 3) * 20, 20) * getDamageMultiplier(self) -- Note: The *20, max 20 is to prevent number issues from occuring if the number is less than 1.
	end,
	getStatusChance = function(self, t)
		return 1
	end,
	getElementColors = function(self, argsList, t)
		local colorsTable = {colorRLow = 0, colorRTop = 255, colorGLow = 0, colorGTop = 255, colorBLow = 0, colorBTop = 255, colorALow = 220, colorATop = 255} -- Less silly than you might think.
		table.mergeAdd(argsList, colorsTable)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to every single basic element you have unlocked, dealing %d divided out between all of their damage types and potentially inflicting any of the statuses they can inflict. The power is based on your three highest level element talents (including non-basic elements).]]):
		tformat(self:damDesc(DamageType.KAM_SPELLWEAVE_PRISMATIC, t.getElementDamage(self, t)))
	end,
	getSpellElementInfo = "Prismatic",
	getSpellStatusInflict = function(self, t, chance, isSecond, alternate)
		if alternate then
			return ([[This damage has a chance to apply the status effects of any of the basic elements, with chances based on your highest three element talents (including non-basic elements)]]):tformat(chance)
		elseif isSecond then 
			return ([[and a chance to apply any of the status effects inflicted by any of the basic elements, with chances based on your highest three element talents (including non-basic elements)]])
		else
			return ([[Additionally, gain a chance to apply any of the status effects inflicted by any of the basic elements, with chances based on your highest three element talents (including non-basic elements)]]):tformat()
		end
	end, -- ... yes, I know. I'm just not sure if listing 10 different status effects or saying math is worse.
--	getStatusEffectTypes = { fire = true, blight = true, acid = true, temporal = true, arcane = true, cold = true, lightning = true, physical = true, light = true, dark = true },
}
