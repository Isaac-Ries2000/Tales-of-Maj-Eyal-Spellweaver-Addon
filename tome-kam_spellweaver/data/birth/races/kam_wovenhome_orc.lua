-- This code is very much copied from Orcs file for orcs, but I've changed the important stuff.

local wovenhomeOrcsRaceDescriptor
if profile.mod.allow_build.kam_race_wovenhome_orcs then 
	wovenhomeOrcsRaceDescriptor = {
		_t"Orcs have a long and sad history. They are seen, and are, as an aggressive race that more than one time managed to imperil all of Maj'Eyal.",
		_t"However, after some disagreement within the prides, the Kruk Pride fled the mainland, and many other orcs fled into the wilderness.",
		_t"With the leadership of Grath, they found shelter with the Spellweavers of Wovenhome.",
		_t"But some grow tired of the peaceful lifestyle and seek adventure.",
	}
else
	wovenhomeOrcsRaceDescriptor = {
		_t"#YELLOW#You have not unlocked this race, but you can play it anyways, in case you don't actually want to go unlock it. Here's your locked description:",
		_t"They turned against us, we did not fall.\nWith our new allies, we will stand tall.\n#WHITE#",
		_t"Orcs have a long and sad history. They are seen, and are, as an aggressive race that more than one time managed to imperil all of Maj'Eyal.",
		_t"However, after some disagreement within the prides, the Kruk Pride fled the mainland, and many other orcs fled into the wilderness.",
		_t"With the leadership of Grath, they found shelter with the Spellweavers of Wovenhome.",
		_t"But some grow tired of the peaceful lifestyle and seek adventure.",
	}
end

newBirthDescriptor{
	type = "race",
	name = "KamWovenhomeOrc",
	display_name = _t"Wovenhome Orc", -- Can't use the EoR race section since they appear in different campaigns, so it just looks like this. For this, it'll look weird like Whitehooves do in ID but it's fine.
--	locked = function() return profile.mod.allow_build.kam_race_wovenhome_orcs end, -- Cut because most people would never unlock it if I did that.
--	locked_desc = _t"They turned against us, we did not fall.\nWith our new allies, we will stand tall.",
	desc = wovenhomeOrcsRaceDescriptor,
	descriptor_choices =
	{
		subrace =
		{
			__ALL__ = "disallow",
			["Wovenhome Orc"] = "allow",
		},
	},
	
	copy = {
		auto_id = 100,
		faction = "spellweavers",
		type = "humanoid", subtype="orc",
		default_wilderness = {"playerpop", "woven-home-start"},
		starting_zone = "kam-towns-woven-home",
		starting_quest = "start-spellweaver", -- Need to change this one later.
		starting_intro = "wovenhome_orcs",
		resolvers.inscription("RUNE:_SHIELDING", {cooldown=14, dur=5, power=100}, 1), -- Two from orcs, one magic for Spellweavers. Adaptability.
		resolvers.inscription("INFUSION:_WILD", {cooldown=14, what={physical=true}, dur=4, power=14}, 2),
		resolvers.inscription("INFUSION:_HEALING", {cooldown=12, heal=50}, 3),
	},
	random_escort_possibilities = { {"tier1.1", 1, 2}, {"tier1.2", 1, 2}, {"daikara", 1, 2}, {"old-forest", 1, 4}, {"dreadfell", 1, 8}, {"reknor", 1, 2}, },

	moddable_attachement_spots = "race_orc",

	cosmetic_options = {
		skin = {
			{name=_t"Skin Color 1", file="base_01"},
			{name=_t"Skin Color 2", file="base_02"},
			{name=_t"Skin Color 3", file="base_03"},
			{name=_t"Skin Color 4", file="base_04"},
			{name=_t"Skin Color 5", file="base_05"},
			{name=_t"Demonic Red Skin", file="demonic_01", addons={"ashes-urhrok"}, unlock="cosmetic_red_skin"},
		},
		facial_features = {
			{name=_t"Goggles 1", file="face_goggles_01"},
			{name=_t"Goggles 2", file="face_goggles_02"},
			{name=_t"Goggles 3", file="face_goggles_03"},
			{name=_t"Goggles 4", file="face_goggles_04"},
			{name=_t"Jaws 1", file="face_jaws_01"},
			{name=_t"Jaws 2", file="face_jaws_02"},
			{name=_t"Mechbiter 1", file="face_mechbiter_01"},
			{name=_t"Mechbiter 2", file="face_mechbiter_02"},
			{name=_t"Monocle Left 1", file="face_monocle_left_01"},
			{name=_t"Monocle Left 2", file="face_monocle_left_02"},
			{name=_t"Monocle Right 1", file="face_monocle_right_01"},
			{name=_t"Monocle Right 2", file="face_monocle_right_02"},
		},
		tatoos = {
			{name=_t"Tatoos 1", file="tattoo_01"},
			{name=_t"Tatoos 2", file="tattoo_02"},
			{name=_t"Tatoos 3", file="tattoo_03"},
		},
		horns = {
			{name=_t"Demonic Horns 1", file="horns_01", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 2", file="horns_02", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 3", file="horns_03", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 4", file="horns_04", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 5", file="horns_05", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 6", file="horns_06", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 7", file="horns_07", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
			{name=_t"Demonic Horns 8", file="horns_08", addons={"ashes-urhrok"}, unlock="cosmetic_doomhorns"},
		},
		special = {
			{name=_t"Bikini / Mankini", birth_only=true, on_actor=function(actor, birther, last)
				if not last then local o = birther.obj_list_by_name[birther.descriptors_by_type.sex == 'Female' and 'Bikini' or 'Mankini'] if not o then print("No bikini/mankini found!") return end actor:getInven(actor.INVEN_BODY)[1] = o:cloneFull() actor.moddable_tile_nude = 1
				else actor:registerOnBirthForceWear(birther.descriptors_by_type.sex == 'Female' and "FUN_BIKINI" or "FUN_MANKINI") end
			end},
		},
	},
}

---------------------------------------------------------
--                        Orcs                         --
---------------------------------------------------------
newBirthDescriptor
{
	type = "subrace",
	name = "Wovenhome Orc",
	display_name = _t"Wovenhome Orcs", -- Can't use the EoR race section since they appear in different campaigns, so we specify. Will look slightly off in Infinite Dungeon but not bad.
	desc = {
		_t"Orcs have a long and sad history. They are seen, and are, as an aggressive race that more than one time managed to imperil all of Maj'Eyal.",
		_t"However, after some disagreement within the prides, the Kruk Pride fled the mainland, and many other orcs fled into the wilderness.",
		_t"With the leadership of Grath, those not of the Kruk Pride found shelter with the Spellweavers of Wovenhome.",
		_t"But some grow tired of the peaceful lifestyle and seek adventure.",
		_t"They possess the #GOLD#Peaceful Rage#WHITE# talent which allows them to increase all their damage to a single target for several turns at the cost of ignoring all other targets.",
		_t"#GOLD#Stat modifiers:",
		_t"#LIGHT_BLUE# * +0 Strength, +1 Dexterity, +0 Constitution",
		_t"#LIGHT_BLUE# * +1 Magic, +1 Willpower, +2 Cunning",
		_t"#GOLD#Life per level:#LIGHT_BLUE# 12",
		_t"#GOLD#Experience penalty:#LIGHT_BLUE# 12%",
	},
	inc_stats = { str=0, con=0, dex=1, wil=1, cun=2, mag=1 },
	talents_types = { ["race/wovenhome-orc"]={true, 0} },
	talents = {
		[ActorTalents.T_KAM_WOVENHOME_ORC_RAGE]=1,
	},
	copy = {
		moddable_tile = "orc_#sex#",
		life_rating=12,
	},
	experience = 1.12,
}

getBirthDescriptor("world", "Maj'Eyal").descriptor_choices.race.KamWovenhomeOrc = "allow"
getBirthDescriptor("world", "Infinite").descriptor_choices.race.KamWovenhomeOrc = "allow"
getBirthDescriptor("world", "Arena").descriptor_choices.race.KamWovenhomeOrc = "allow"