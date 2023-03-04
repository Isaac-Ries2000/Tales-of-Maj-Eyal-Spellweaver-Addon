local KamCalc = require "mod.KamHelperFunctions"

-- Dummy trees. These trees are not actually implemented, since a player can never actually obtain them.
newTalentType{ type = "spellweaving/arcane-visions", no_silence = true, is_spell = true, name = _t("arcane visions", "talent type"), description = _t"Through advanced Spellweaving techniques, you have created an entirely new kind of arcane eye." }


-- Arcane Visions: Professor Hundredeyes' signature tree, weird Arcane Eye tricks.
newTalent{
	name = "Eyetracking",
	short_name = "KAM_ARCANE_VISIONS_EYETRACKING",
	type = {"spellweaving/arcane-visions", 1},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[One arcane eye can show you one thing, but dozens can show you everything. For 20 turns, you see everything within radius 100.]]):tformat()
	end,
}

newTalent{
	name = "Vision Casting",
	short_name = "KAM_ARCANE_VISIONS_VISION_CASTING",
	type = {"spellweaving/arcane-visions", 2},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You see all, and you can strike at a distance. You can cast Spellwoven spells on your Arcane Eyes, ignoring walls and talent radius, within range 10.]]):tformat()
	end,
}

newTalent{
	name = "Watchful Eyes",
	short_name = "KAM_ARCANE_VISIONS_WATCHFUL_EYES",
	type = {"spellweaving/arcane-visions", 3},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You never lose sight of anything. The duration of Arcane Eyes you create is increased by 100. Additionally, when you create Arcane Eyes, the most recent 10 last forever, ignoring duration.]]):tformat()
	end,
}

newTalent{
	name = "All Knowing Hundredeyes",
	short_name = "KAM_ARCANE_VISIONS_HUNDREDEYES",
	type = {"spellweaving/arcane-visions", 4},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[They say you see everyhing in Var'Eyal, and while that probably isn't true, you always see a bit more than everyone else.
		When you enter a floor, immediately create 10 Arcane Eyes on random enemies. These Arcane Eyes last as long as the enemies they follow, and do not count against your permanent Arcane Eyes from Watchful Eyes.]]):tformat()
	end,
}

newTalentType{ type = "spellweaving/historical-advantage", no_silence = true, is_spell = true, name = _t("historical advantage", "talent type"), description = _t"You have been around for a lot of history, and you've read every single text you can find about it. One thing you've learned is that everything has a weakness, and history can teach you how to find them." }


-- Historical Advantage: Ifnai's Signature Tree, weird out-there talents..
newTalent{
	name = "Historical Advantage",
	short_name = "KAM_HISTORICAL_ADVANTAGE_HISTORICAL_ADVANTAGE",
	type = {"spellweaving/historical-advantage", 1},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You know just about every piece of recorded Eyalian history, from horrifying tomes about battles beyond mortal comprehension to the questionable tales of would-be adventurers.
		Whenever an enemy enters your line of sight, you use your historical knowledge to recall a secret weakness, permanently reducing its resistance to 2 random elements by 30%%.
		At talent level 5, two elemental resistances are reduced instead of one.]]):tformat()
	end,
}

newTalent{
	name = "Historical Edge",
	short_name = "KAM_HISTORICAL_ADVANTAGE_HISTORICAL_EDGE",
	type = {"spellweaving/historical-advantage", 2},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You already have an idea of how they'll fight, but they have no idea of how you'll fight.
		When you first see an enemy, permanently reduce all damage it deals to you by 100%%. When it deals damage to you, reduce the power of this effect by 20%%. This reduction can only occur once per enemy for each of your turns.]]):tformat()
	end,
}

newTalent{
	name = "Historical Technique",
	short_name = "KAM_HISTORICAL_ADVANTAGE_HISTORICAL_TECHNIQUE",
	type = {"spellweaving/historical-advantage", 3},
	points = 5,
	mana = 0,
	vim = 0, 
	hate = 0,
	soul = 0,
	equilbrium = 0,
	paradox = 0,
	positive = 0,
	negative = 0,
	psi = 0,
	feedback = 0,
	mode = "passive",
	info = function(self, t)
		return ([[Your studies of history have taught you about nearly every combat technique, and even if you don't really know enough to actually use them, you can certainly know enough to be able to copy them when you see them.
		Choose one enemy within range 10 and copy two random (non-antimagic) skills it knows that you do not. You keep these skills for 6 turns (note that you may be unable to use talents that require resources you don't have or that require weapons you are not wearing).
		Additionally, gain every normal resource pool.]]):tformat()
	end,
}

newTalent{
	name = "New History",
	short_name = "KAM_HISTORICAL_ADVANTAGE_NEW_HISTORY",
	type = {"spellweaving/historical-advantage", 4},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[As you act, the present becomes the past, and you remember it all. You create the future, and thus you create a new history.
		Whenever you defeat an enemy, permanently gain +0.3%% damage against that Type of opponent (up to 15%%) and +0.6%% resistance to that Subtype of opponent (up to 30%%).]]):tformat()
	end,
}

newTalentType{ type = "spellweaving/elemental-harmony", no_silence = true, is_spell = true, name = _t("elemental harmony", "talent type"), description = _t"You are a being of the elements, and you can use them to perform techniques that nobody has ever managed." }

-- Elemental Harmony: Professor Paradise's Signature tree, weird elemental stuff.
newTalent{
	name = "Elemental Soul",
	short_name = "KAM_ELEMENTAL_HARMONY_ELEMENTAL_SOUL",
	type = {"spellweaving/elemental-harmony", 1},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You are a being of the elements, and they are fundamentally part of you.
		Whenever you cast a Spellwoven spell, gain 100%% resistance and 100%% resistance cap for each element used in that spell for 1 turn, but this effect cannot give resistance to any element used in that spell for 6 turns.]]):tformat()
	end,
}

newTalent{
	name = "Elemental Overpower",
	short_name = "KAM_ELEMENTAL_HARMONY_ELEMENTAL_OVERPOWER",
	type = {"spellweaving/elemental-harmony", 2},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You are a being of the elements, and you can use them to produce incredibly powerful effects. The Spellweave Multiplier of the next Spellwoven spell you cast is multiplied by 4.]]):tformat()
	end,
}

newTalent{
	name = "Elemental Ascendance",
	short_name = "KAM_ELEMENTAL_HARMONY_ELEMENTAL_ASCENDANCE",
	type = {"spellweaving/elemental-harmony", 3},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You are a being of the elements, and when you want to be, you can be one with them.
		Choose 1 element (from your unlocked basic Spellwoven elements). For 5 turns, you gain 100%% affinity and 100%% resistance to that element, and your resistance and affinity caps are increased by 100%%. Additionally, your damage in that element increases by 100%%.]]):tformat()
	end,
}

newTalent{
	name = "Elemental Purification",
	short_name = "KAM_ELEMENTAL_HARMONY_ELEMENTAL_PURIFICATION",
	type = {"spellweaving/elemental-harmony", 4},
	points = 1,
	mode = "passive",
	getDamage = function(self, t) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, t) 
	end,
	info = function(self, t)
		return ([[You are a being of elements, and you know that to combine them unleashes a force that few understand.
		Gain the Elemental Purification element, if you do not already know it. It deals %d damage, ignoring all of your elemental damage increases and your target's resistances. Elemental Purification damage also has a 100%% chance to inflict targets with Elementally Nulled for 15 turns, reducing all of their damage by a flat 50%% and converting all of it into elementless damage.]]):
		tformat(t.getDamage(self, t))
	end,
}

newTalent{
	name = "Elemental Purification",
	short_name = "KAM_FAKE_ELEMENT_ELEMENTAL_PURIFICATION",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	hide = true,
	getElementDamage = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_ELEMENTAL_HARMONY_ELEMENTAL_PURIFICATION)
		return tal.getDamage(self, tal)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Elemental Purification, removing all elements (and thus ignoring elemental damage increases and resistances).
		Effect: Inflict %d elementless damage, and gain a 100%% chance to Elementally Null targets for 15 turns, reducing their damage by a flat 50%% and converting all of their damage into elementless damage.]]):
		tformat(t.getElementDamage(self, t))
	end,
}

newTalentType{ type = "spellweaving/blightweaver", no_silence = true, is_spell = true, name = _t("blightweaver", "talent type"), description = _t"Although most people find weaving nightmare diseases from pure magic horrifying, you find it to be a fun hobby. It's not like they can't be removed easily with magic after all, so nobody's at any real risk." }

-- Blightweaver: Faller's weird blight tree.

newTalent{
	name = "Chilling Blight",
	short_name = "KAM_BLIGHTWEAVER_COLD",
	type = {"spellweaving/blightweaver", 1},
	points = 3,
	mode = "passive",
	getDamage = function(self, t) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, t) 
	end,
	info = function(self, t)
		return ([[Cold and Blight combine into a horrible creeping disease that sucks the energy out of all of your foes.
		Gain the Chillblight element, which deals %d damage, divided equally between Cold and Blight. Chillblight damage also inflicts foes with a Cold, stackingly dealing 50 damage (equally divided between Cold and Blight) each turn for 6 turns. Additionally, targets will spread the Cold to nearby targets, inflicting them with the same diseases and refreshing the duration on both targets (each enemy can only be affected by each spread of Cold once). Cold damage is modified by Spellweave Multiplier.]]):
		tformat(t.getDamage(self, t))
	end,
}

newTalent{
	name = "Chilling Blight",
	short_name = "KAM_FAKE_ELEMENT_BLIGHTWEAVER_COLD",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	getElementDamage = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_BLIGHTWEAVER_COLD)
		return tal.getDamage(self, tal)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Chillblight, combining Blight and Cold.
		Effect: Inflict %d Blight and %d Cold damage (modified by Spellweave Multiplier), and afflict targets with a Cold, stackingly dealing 50 damage (equally divided between Cold and Blight) each turn for 6 turns. Additionally, targets will spread the Cold to nearby targets, inflicting them with the same diseases and refreshing the duration on both targets (each enemy can only be affected by each spread of Cold once). Cold damage is modified by Spellweave Multiplier.]]):
		tformat(t.getElementDamage(self, t) / 2, t.getElementDamage(self, t) / 2)
	end,
}

newTalent{
	name = "Hex Sickness",
	short_name = "KAM_BLIGHTWEAVER_ARCANE",
	type = {"spellweaving/blightweaver", 1},
	points = 3,
	mode = "passive",
	getDamage = function(self, t) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, t) 
	end,
	info = function(self, t)
		local extraText = [[]]
		if game:isAddonActive("orcs") and game:isAddonActive("cults") then
			extraText = (([[Steam, Insanity, and ]]):tformat())
		elseif game:isAddonActive("orcs") then
			extraText = (([[Steam and ]]):tformat())
		elseif game:isAddonActive("cults") then
			extraText = (([[Insanity and ]]):tformat())
		end
		return ([[Blight and Arcane combine into a strange sickness that saps away a target's power and turns it against them.
		Gain the Hexblight element, which deals %d damage, divided equally between Blight and Arcane. Hexblight also afflicts targets with Hex Sickness, stackingly draining 50 resources (resource scaling below) each turn and dealing damage based on resources drained (see resource scaling) to all enemies within radius 2. Additionally, targets will spread the Hex Sickness to nearby targets, inflicting them with the same disease and refreshing the duration on both targets (each enemy can only be affected by each spread of Hex Sickness once). Resource draining is modified by Spellweave Multiplier.
		Resource scaling: 
		Mana: Draining 100%% of the value, dealing 100%% of amount drained as Arcane and Blight damage.
		Vim and Stamina: Draining 50%% of the value, dealing 200%% of the amount drained as Arcane and Blight damage.
		Psi, Positive and Negative Energies: Draining 25%% of the value, dealing 400%% of the amount drained as Arcane and Blight damage.
		%sHate: Draining 10%% of the value, dealing 1000%% of the amount drained as Arcane and Blight damage.]]):
		tformat(t.getDamage(self, t), extraText)
	end,
}

newTalent{
	name = "Hex Sickness",
	short_name = "KAM_FAKE_ELEMENT_BLIGHTWEAVER_ARCANE",
	type = {"spellweaving/elements", 1},
	points = 1,
	mode = "passive",
	getElementDamage = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_BLIGHTWEAVER_ARCANE)
		return tal.getDamage(self, tal)
	end,
	info = function(self, t)
		return ([[Set the element of your spell to Hexblight, combining Blight and Arcane.
		Effect: Inflict %d Blight and %d Arcane damage (modified by Spellweave Multiplier), and afflict targets with Hex Sickness, stackingly draining 50 resources (see resource scaling in Hexblight talent in the Blightweaver tree) each turn and dealing damage based on resources drained (see resource scaling) to all enemies within radius 2. Additionally, targets will spread the Hex Sickness to nearby targets, inflicting them with the same disease and refreshing the duration on both targets (each enemy can only be affected by each spread of Hex Sickness once). Resource draining is modified by Spellweave Multiplier.]]):
		tformat(t.getElementDamage(self, t) / 2, t.getElementDamage(self, t) / 2)
	end,
}

newTalentType{ type = "spellweaving/lifeweaver", no_silence = true, is_spell = true, name = _t("lifeweaver", "talent type"), description = _t"Bring life to the world with the power of pure magic." }


newTalent{
	name = "Lifeweave",
	short_name = "KAM_FAKE_TALENT_LIFEWEAVE",
	type = {"spellweaving/lifeweaver", 1},
	points = 1,
	mode = "passive",
	info = function(self, t)
		return ([[Weave magic into a Spellwoven animal.
		This talent takes an exceptionally long time to use, but it summons 1 Spellwoven animal that you can control.
		Without a Controller Construct, you can only control 1 Spellwoven animal at a time safely.]]):
		tformat()
	end,
}