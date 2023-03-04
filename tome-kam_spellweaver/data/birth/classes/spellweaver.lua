-- The Spellweaver.

newBirthDescriptor{
	type = "subclass",
	name = "Spellweaver",
	desc = {
		_t"Many people throughout Eyal sought magics, even those born without them. From Arcane Blades to Sun Paladins, they strived to control the threads that make up the world.",
		_t"However, some of these mages, rather than just trying to find power, wanted to understand it.",
		_t"Possibly the greatest of these are the Spellweavers, mages who learned how to weave their own spells with the very magical threads that make up this world.",
		_t"With unparalleled flexibility but less raw power than Archmages, Spellweavers must learn how to use their vast variety of spells to best effect.",
		_t"Additionally, because the Spellweavers accept necromancy, Ghoul and Skeleton Spellweavers will start with them instead (and will not need a Cloak of Deception, since Spellweaver enchanting has produced more effective methods for easier use).",
		_t"Their most important stats are: Magic and Willpower.", 
		_t"#GOLD#Stat modifiers:",
		_t"#LIGHT_BLUE# * +0 Strength, + Dexterity, +0 Constitution",
		_t"#LIGHT_BLUE# * +4 Magic, +4 Willpower, +3 Cunning",
		_t"#GOLD#Life per level:#LIGHT_BLUE# -2",
	},
	not_on_random_boss = true, -- Hahahah no.
	power_source = {arcane=true},
	stats = { mag=4, wil=4, cun=3, },
	talents_types = {
	-- Class talents
		["spellweaving/eclipse"]={true, 0.3}, -- This was the first tree, so it's special to me.
		["spellweaving/molten"]={true, 0.3},
		["spellweaving/wind-and-rain"]={true, 0.3},
		["spellweaving/otherworldly"]={true, 0.3},
		["spellweaving/ruin"]={true, 0.3},
		["spellweaving/spellweaver"] = {true, 0.3},
	-- Locked Class Talents. The Fancy stuff.
		["spellweaving/advanced-staff-combat"] = {false, 0.3},
		["spellweaving/elementalist"] = {false, 0.3},
		["spellweaving/spellweaving-mastery"] = {false, 0.3},
	-- Generics talents
		["cunning/survival"]={true, 0.2},
		["spell/staff-combat"]={true, 0.3},
		["spellweaving/shieldweaving"]={true, 0.3},
		["spellweaving/warpweaving"] = {true, 0.3},
		["technique/combat-training"] = {true, 0.0},
	-- Locked generics. The Weird and Fancy stuff. (also divination)
		["spellweaving/runic-mastery"] = {false, 0.3},
		["spellweaving/metaweaving"] = {false, 0.0},
		["spell/divination"]={false, 0.0}
	},
	talents = { -- Unusually large number of talents because knowing more elements isn't really inherently stronger.
		[ActorTalents.T_KAM_SPELLWEAVER_CORE] = 1,
		[ActorTalents.T_KAM_ELEMENTS_ECLIPSE] = 1,
		[ActorTalents.T_KAM_ELEMENTS_MOLTEN] = 1,
		[ActorTalents.T_KAM_ELEMENTS_WIND_AND_RAIN] = 1,
		[ActorTalents.T_KAM_ELEMENTS_OTHERWORLDLY] = 1,
		[ActorTalents.T_KAM_ELEMENTS_RUIN] = 1,
		[ActorTalents.T_KAM_SPELLWEAVER_SHIELDS_CORE] = 1,
		[ActorTalents.T_KAM_SPELLWEAVER_WARP_CORE] = 1,
	},
	copy = {
		max_life = 100,
		mage_equip_filters,
		resolvers.equipbirth{ id=true,
			{type="weapon", subtype="staff", name="elm staff", autoreq=true, ego_chance=-1000},
			{type="armor", subtype="cloth", name="linen robe", autoreq=true, ego_chance=-1000},
		},
		class_start_check = function(self) -- Yes, this overrides undead start. It also sets your faction and frankly I've played undead start to death so (and undead live at Woven Home anyways, so).
			if self.descriptor.world == "Maj'Eyal" and (((self.descriptor.race == "Human" or self.descriptor.race == "Elf" or self.descriptor.race == "Dwarf") and not self._forbid_start_override) or self.descriptor.subrace == "Skeleton" or self.descriptor.subrace == "Ghoul") then
				self.default_wilderness = {"playerpop", "woven-home-start"}
				self.starting_zone = "kam-towns-woven-home"
				self.starting_quest = "start-spellweaver"
				self.starting_intro = "spellweaver"
				self.faction = "spellweavers" -- If you're undead this will fail and be handled in the Wovenhome starting zone undead handler.
				self.starting_level = 1 
				self.starting_level_force_down = false
				self.calendar = "spellweavers"
			end
		end,
	},
	copy_add = { -- Made very slightly less squishy. 50 whole extra life by level 50, wooh?
		life_rating = -2,
	},
}

-- They're Mages.
getBirthDescriptor("class", "Mage").descriptor_choices.subclass["Spellweaver"] = "allow"
