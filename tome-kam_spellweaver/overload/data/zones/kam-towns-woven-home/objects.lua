local Stats = require "engine.interface.ActorStats"
local Talents = require("engine.interface.ActorTalents")

-- We are in the far east so its appropriate
load("/data/general/objects/objects-far-east.lua")

-- Orb of Illusion: Plot item for Ghouls and Skeletons. Does not actually do anything. Just narrative excuse for changing the faction and setting.
newEntity{ define_as = "KAM_SPELLWEAVER_ORB_OF_ILLUSIONS",
	power_source = {arcane=true},
	unique = true,
	type = "orb", subtype="orb", no_unique_lore=true, -- Although it does have unique special lore, I don't exactly want it popping up every single time.
	unided_name = _t"mirage-like orb",
	name = "Orb of Illusions",
	level_range = {1, 1},
	display = "*", color=colors.PURPLE, image = "object/artifact/orb_many_ways.png",
	encumber = 0,
	plot = true, quest = true,
desc = _t[[Every undead occupant of Wovenhome is given an Orb of Illusions. Most of them choose not to use them at Wovenhome, but when leaving for the Sunwall or for any of the coastal settlements of Var'Eyal, it's standard use practice.
Additionally, it's advised, although not required, to use it around any visitors (it isn't like some people don't already know about necromancy in the Spellweavers, but it's best to be careful).
When you hold it, you appear as a relatively non-descript Cornac, mostly forgettable, although after the "identical town" incident, each illusion is unique.]],

	on_drop = function(self, who)
		if who == game.player then
			game.logPlayer(who, "It would be a remarkably bad idea to drop the %s.", self:getName())
			return true
		end
	end,
}

newEntity{ define_as = "KAM_GRATH_QUEST_REWARD_SPELLWEAVERS", base = "BASE_TOOL_MISC", 
	power_source = {arcane=true},
	unique = true,
	name = "Grath's Token", color = colors.BLUE, image = "object/artifact/bladed_rift.png",
	unided_name = _t"slightly-enchanted rock", -- It really doesn't seem like much without context.
	desc = _t[[Grath gave this to you as thanks for your help. Mostly it just seems to be a greyish rock, but you can feel a powerful enchantment on it, as well as the support of Grath and the other Wovenhome orcs.]],
	rarity = false,
	cost = 0, -- The merchant will not want this greyish rock, buddy.
	material_level = 5,
	use_no_energy = true,
	wielder = {
		resists = { [DamageType.PHYSICAL] = 15},
		combat_physresist = 10,
		combat_mentalresist = 10,
		combat_spellresist = 10,
		inc_stats = { [Stats.STAT_WIL] = 6, [Stats.STAT_MAG] = 6,},
		esp = { ["humanoid/orc"]=1 },
	},
	max_power = 30, power_regen = 1, -- Tap into the Wovenhome Orc racials.
	use_talent = { id = Talents.T_KAM_WOVENHOME_ORC_RAGE, level = 5, power = 25 },
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_HISTORY_LECTURE",
	subtype = "lecture on purpose", unique=true, no_unique_lore=true, not_in_stores=false,
	name = "On the History and Purpose of the Spellweavers", lore="kam-spellweaver-history-note",
	desc = _t[[A transcription of a lecture about the history and purpose of the Spellweavers given by Professor Lekkia in the 600th year of the Age of Weaving, recorded by Lorekeeper Adt'dria'at.]],
	rarity = false,
	cost = 2,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_TECHNIQUE_LECTURE",
	subtype = "lecture on technique", unique=true, no_unique_lore=true, not_in_stores=false,
	name = "The Theory of Spellweaving", lore="kam-spellweaver-theory-note",
	desc = _t[[A transcription of a lecture about the Spellwoven Theory given by Professor Michael in the 824th year of the Age of Weaving, recorded by Lorekeeper Malem.]],
	rarity = false,
	cost = 2,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_CALENDAR_LECTURE",
	subtype = "lecture on the calendar", unique=true, no_unique_lore=true, not_in_stores=false,
	name = "The Weaver's Calendar", lore="kam-spellweaver-calendar-note",
	desc = _t[[A transcription of a lecture about the Weaver's Calendar, given by Professors Tracy and Letis in the 843rd year of the Age of Weaving, recorded by Lorekeeper Malem.]],
	rarity = false,
	cost = 2,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ORCS_LECTURE",
	subtype = "address regarding wovenhome orcs", unique=true, no_unique_lore=true, not_in_stores=false,
	name = "Address Regarding Orcs", lore="kam-spellweaver-orcs-note",
	desc = _t[[A transcription of the address Professor Hundredeyes gave to the students of Wovenhome back when Grath and the other orcs moved in here.]],
	rarity = false,
	cost = 2,
}

-- For Embers. May be wildly unbalanced?
newEntity{ base = "BASE_RING", define_as = "KAM_RING_OF_HARMONIC_PEACE",
	power_source = {arcane=true},
	image="object/artifact/glory_of_the_pride.png",
	unided_name = _t"scintillating ring",
	color = colors.VIOLET,
	rarity = false,
	name = "Ring of Harmonic Peace", unique=true,
	desc = _t[[The ring left behind by the Spellweavers glows with every color imaginable. When you put it on, you feel an immense sense of peace.]],
	special_desc = function(self) 
		return _t"All damage you deal (including via Summons) and recieve is reduced by a flat 50%. When you take the ring off, the reduction to damage you deal (but not to damage you take) will remain for 20 turns." 
	end,
	cost = 0,
	material_level = 5,
	wielder = {
		max_mana = 50,
		inc_stats = { [Stats.STAT_WIL] = 5, [Stats.STAT_CUN] = 5 },
		kam_ring_of_harmonic_peace = 1,
	},
}