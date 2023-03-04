
local Stats = require "engine.interface.ActorStats"
local Talents = require "engine.interface.ActorTalents"

newEntity{ base = "BASE_WIZARD_HAT",
	power_source = {arcane = true},
	unique=true,
	name = "The Glasses of Professor Hundredeyes",
	unided_name = _t"strange spectacles",
	image = "object/artifact/mirror_image_rune.png", -- ... I know, I really have nothing so.
--	moddable_tile = "special/", -- Not in use for now. It's a hat, so that looks weird, but I've got nothing.
	special_desc = function(self) return _t"Your damage is increased by 10% against targets revealed by your Arcane Eyes. Additionally, your Spellweaving modifier is globally increased by 7.5%" end,
	desc = _t[[A pair of glasses stolen from the from the near legendary Spellweaver Professor Hundredeyes. Attempts to steal further pairs were made after students tried to make a game of stealing from the expert of Arcane Eyes, but no other attempt has ever been successful.]],
	color = colors.PURPLE, 
	level_range = {30, 40},
	rarity = 250,
	cost = 500,
	material_level = 4,
	wielder = {
		combat_armor = 0,
		combat_def = 0,
		lite = 2,
		blind_immune = 1,
		inc_stats = { [Stats.STAT_WIL] = 6, [Stats.STAT_MAG] = 6 },
		talents_types_mastery = { -- Have some masteries!
			["spellweaving/warpweaving"] = 0.2,
			["spellweaving/shieldweaving"] = 0.2,
			["spellweaving/spellweaver"] = 0.2,
			["spellweaving/spellweaving-mastery"] = 0.2,
			["spell/divination"] = 0.2,
		},
		kam_spellweaver_hundredeyes_glasses_bonus_power = 0.075,
		kam_spellweaver_hundredeyes_glasses_bonus = 0.1
	},
	talent_on_spell = {
		{chance=100, talent=Talents.T_ARCANE_EYE, level=5},
	},
}