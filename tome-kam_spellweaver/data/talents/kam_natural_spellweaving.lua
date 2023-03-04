local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/natural-spellweaving", no_silence = true, is_spell = true, name = _t("natural spellweaving", "talent type"), description = _t"All Spellweavers weave the threads of magic, but most forget the source of many of the greatest powers in Eyal, Eyal itself. By connecting with it, you have learned to combine Natural techniques with your Spellweaving techniques." }

-- Currently a dummy tree since Arbus needs it, but should eventually be an actual tree for the Class Evo. Probably will change what it does though.
newTalent{
	name = "Natural Spellweaving",
	short_name = "KAM_NATURAL_SPELLWEAVING_CORE",
	type = {"spellweaving/natural-spellweaving", 1},
	points = 3,
	mode = "passive",
	getDamage = function(self, t) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, t) 
	end,
	info = function(self, t)
		return ([[With your connection to Eyal fully established, you can tap into the boundless power of nature.
		Gain the Nature element, which deals %d damage. Nature damage also has a 50%% chance to strip targets of a random sustain and a 50%% chance to strip targets of a random beneficial effect.
		Additionally, you are permanently immune to silencing effects.]]):
		tformat(t.getDamage(self, t))
	end,
}

newTalent{
	name = "Nature",
	short_name = "KAM_FAKE_ELEMENT_NATURE",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	getElementDamage = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_NATURAL_SPELLWEAVING_CORE)
		return tal.getDamage(self, tal)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Nature.
		Effect: Inflict %d Nature damage. Nature damage has a 50%% chance to strip targets of a random sustain and an additional 50%% chance to strip targets of a random beneficial effect.]]):
		tformat(t.getElementDamage(self, t))
	end,
}

newTalent{
	name = "Natural Force",
	short_name = "KAM_NATURAL_SPELLWEAVING_STRENGTHEN",
	type = {"spellweaving/natural-spellweaving", 2},
	points = 3,
	mode = "passive",
	getDamageIncrease = function(self, t) 
		return KamCalc:getDamageIncForElementTalents(self, t) * 1.25
	end,
	getResistPierce = function(self, t) 
		return KamCalc:getResistancePiercingForElementTalents(self, t) * 1.25
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "inc_damage", {[DamageType.NATURE] = t.getDamageIncrease(self, t)})
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.NATURE] = t.getResistPierce(self, t)})
	end,
	info = function(self, t)
		return ([[Nature is already surrounding everything in Eyal. There is no hiding from it.
		Increase your Nature damage by %0.1f%% and gain %d%% Nature resistance penetration.]]):tformat(t.getDamageIncrease(self, t), t.getResistPierce(self, t))
	end,
}

newTalent{
	name = "Natural Disruption",
	short_name = "KAM_NATURAL_SPELLWEAVING_SUSTAIN",
	type = {"spellweaving/natural-spellweaving", 3},
	points = 3,
	mode = "passive",
	info = function(self, t)
		return ([[Nature has a way of getting into things and wearing them down. Every stone path will eventually just be a field, every column crumble to the ground.
		When you strip a target of a Sustain or beneficial effect with a Spellwoven spell, also deal 300 Nature damage to that target and to all enemies around them in radius 3.
		Additionally, all of your Spellwoven spells gain a 10%% chance to strip targets of a random sustain or beneficial effect when they are cast. This chance is modified by the Spellweave Multiplier of the shape of the Spell.]]):tformat()
	end,
}

newTalent{
	name = "Unity",
	short_name = "KAM_NATURAL_SPELLWEAVING_UNITY",
	type = {"spellweaving/natural-spellweaving", 4},
	points = 3,
	mode = "passive",
	getDamage = function(self, t) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, t) * 1.05
	end,
	info = function(self, t)
		return ([[The divide that most people see between Nature and Magic is much less real than antimagics would have you believe. Although combining them can be difficult, there is nothing to actually stop you from doing so.
		Gain the Unity element, which deals %d damage, evenly divided between Arcane and Nature. Unity damage also grants you Unity, stackingly increasing your damage by 1%% (capping at 200%%).]]):tformat(t.getDamage(self, t))
	end,
}