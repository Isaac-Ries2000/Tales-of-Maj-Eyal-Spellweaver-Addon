newTalentType{ type = "spellweaving/spellwoven-enhancements", no_silence = true, is_spell = true, name = _t("spellwoven enhancements", "talent type"), description = _t"Spellweavers typically focus on weaving magic outside of themselves, but some focus on weaving magic into themselves, enhancing and modifying their own abilities." }

-- Currently a dummy tree since Arbus needs it, but if I ever actually work on the Enchanter class, this will be full redesigned into something more fitting for Spellweaver addon.
-- (I make no promises I will actually do that though)
newTalent{ -- Enhance one "physical" stat.
	name = "Basic Enhancing",
	short_name = "KAM_SPELLWOVEN_ENHANCEMENTS_CORE",
	type = {"spellweaving/spellwoven-enhancements", 1},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[You know how to weave magic into your own body to augment it, granting you whatever powers you need.
		Choose 1 of the following benefits. You gain that benefit until you select a new one:
		- Gain 30 Constitution and reduce the duration of all detrimental effects applied to you by 20%%.
		- Gain 30 Dexterity and reduce all of your Spellwoven cooldown durations by 20%%.
		- Gain 30 Strength and cause all weapons you equip to gain an additional 20%% Magic modifier.]]):
		tformat()
	end,
}

newTalent{
	name = "Striking Enhancements",
	short_name = "KAM_SPELLWOVEN_ENHANCEMENTS_COMBAT",
	type = {"spellweaving/spellwoven-enhancements", 2},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[Your enhancements prepare you to fight on the frontlines far better than a normal fighter.
		Choose 1 of the following benefits. You gain that benefit until you select a new one:
		- You gain 20%% attack speed.
		- When attacked in melee, you gain a 50%% chance to freely counterattack, immediately attacking your attacker. If you are wielding a bow or sling, you will freely shoot the target instead. Additionally, you gain 30 accuracy.
		- You gain 20%% resist all, 30 armor, and 30 defense.]]):tformat()
	end,
}

newTalent{
	name = "Nimble Enhancements",
	short_name = "KAM_SPELLWOVEN_ENHANCEMENTS_MOBILITY",
	type = {"spellweaving/spellwoven-enhancements", 3},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[Your enhancements render you quick, able to run circles around your enemies or to disappear in a flash.
		Choose 1 of the following benefits. You gain that benefit until you select a new one:
		- You gain 50%% move speed.
		- When you move from a tile adjacent to an enemy to another tile adjacent to the same enemy, reduce its damage to you by 20%% for 1 turn and make a free attack on it at 50%% power. You can only deal damage once per enemy turn this way.
		- You gain 20%% Spell speed.]]):tformat()
	end,
}

newTalent{
	name = "Advanced Enhancements",
	short_name = "KAM_SPELLWOVEN_ENHANCEMENTS_MASTERY",
	type = {"spellweaving/spellwoven-enhancements", 4},
	points = 5,
	mode = "passive",
	info = function(self, t)
		return ([[Your enhacements allow you to do things that few have ever considered.
		Choose 1 of the following abilities. You gain that ability until you select a new one:
		- Mimic: Activated - Choose 1 enemy, then gain 3 random skills it knows for 10 turns.
		- Wisp: Sustain - Reduce all damage you take by a flat 20%%.
		- Feral: Passive - When you attack in melee, you briefly form claws and fangs and make a second unarmed attack with them for 50%% increased damage.]]):tformat()
	end,
}