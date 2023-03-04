local Stats = require "engine.interface.ActorStats"
local Talents = require("engine.interface.ActorTalents")

load("/data/general/objects/objects-far-east.lua")

-- Fixed drop from the first boss. A unique and special item just for Spellweavers. :)
newEntity{ base = "BASE_STAFF", define_as = "KAM_COMMAND_CONSTRUCT_STAFF",
	power_source = {arcane=true},
	image = "object/artifact/lightbringers_rod.png",
	unided_name = _t"commanding staff",
	color = colors.VIOLET,
	rarity = false,
	metallic = true,
	name = "Spellshattered Staff", unique=true,
desc = _t[[The gem in the center of the Controller Construct seems to have been conveniently attached to a chunk of metal and crystal that makes a decent, if very heavy, staff.
Despite its unusual weight, you notice that your spells seem to be charged up a little with the excess elemental power of the Controller Construct.]],
	special_desc = function(self) return _t"Spellwoven spells gain a small amount of bonus damage (10% of normal power) of a random element you have unlocked, including any status chances associated with that element." end,
	require = { stat = { mag=20, str=10 } },
	cost = 60,
	material_level = 2,
	combat = {
		dam = 20,
		apr = 5,
		staff_power = 17, -- Slightly better since the element bonus is low and doesn't benefit from element bonuses other than all.
		physcrit = 3.5,
		dammod = {mag=1.1},
	},
	wielder = {
		combat_spellpower = 12,
		combat_spellcrit = 8,
		inc_damage = {},
		max_mana = 30,
		fatigue = 7, -- It's heavy and inconvenient, but it has wonderful special powers.
		inc_stats = { [Stats.STAT_MAG] = 3, [Stats.STAT_WIL] = 3, [Stats.STAT_CUN] = 3 },
		learn_talent = {[Talents.T_COMMAND_STAFF] = 1},
		kam_commanding_staff_attr = 0.1, -- Here's the special trick.
	},
	resolvers.staff_element(),
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS1",
	name = "Discarded Memo", lore="kam-spellweaver-elemental-ruins-one",
	desc = _t[[It seems some kind of note was abandoned here.]],
	rarity = false,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS2",
	name = "Charred Log", lore="kam-spellweaver-elemental-ruins-one-alt",
	desc = _t[[It looks like there used to be more to this journal, but the rest is just ashes.]],
	rarity = false,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS3",
	name = "Abandoned Journal Page", lore="kam-spellweaver-elemental-ruins-two",
	desc = _t[[An old journal page, somehow mostly un-incinerated.]],
	rarity = false,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS4",
	name = "Damaged Design Plans", lore="kam-spellweaver-elemental-ruins-three",
	desc = _t[[What looks to be design plans, although with all the elemental damage, barely readable.]],
	rarity = false,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS5",
	name = "Hastily Written Journal Page", lore="kam-spellweaver-elemental-ruins-four",
	desc = _t[[A journal page, lost surprisingly deep in this place. A little water-stained, but still readable.]],
	rarity = false,
}

newEntity{ base = "BASE_LORE",
	define_as = "KAM_SPELLWEAVER_ELEMENTAL_RUINS6",
	name = "Undamaged Journal Page", lore="kam-spellweaver-elemental-ruins-five",
	desc = _t[[A journal page. Oddly enough, not even the slightest bit damaged.]],
	rarity = false,
}