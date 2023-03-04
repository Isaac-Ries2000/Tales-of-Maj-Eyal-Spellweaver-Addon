
local Talents = require("engine.interface.ActorTalents")
newEntity{
	define_as = "BASE_NPC_KAM_ELEMENTAL_RUINS",
	type = "elemental", subtype = "anarchic",
	blood_color = colors.WHITE,
	display = "E", color=colors.WHITE,

	body = { INVEN = 10 },
	lite = 1,
	immune_possession = 1, -- Sorry, but this would 100% cause issues with these extremely gimmick designed enemies.

	infravision = 5,
	life_rating = 8,
	rank = 3,
	size_category = 3,
	levitation = 1,

	no_breath = 1,
	
	resolvers.talents{
		[Talents.T_KAM_ELEMENTAL_RUINS_PARTICLES] = 1,
		[Talents.T_KAM_ELEMENTAL_RUINS_MELEE] = 1,
	},
}

newEntity{ base = "BASE_NPC_KAM_ELEMENTAL_RUINS",
	name = "guardian elemental",
	desc = _t[[This elemental seems sturdier than the others. Still wreathed in elemental energies of course, but it seems denser?]],
	level_range = {35, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(150,200), life_rating = 12,
	combat_armor = 20, combat_def = 20,
	inc_damage = { all = -30 },
	kam_spellweavers_is_guardian_elemental = 1, -- Don't protect them so that if a group of them spawned as tanky randbosses then they would only be so awful. 

	resolvers.talents{
		[Talents.T_FLAME]={base=3, every=10, max=7},
	},
}

newEntity{ base = "BASE_NPC_FAEROS",
	name = "greater faeros", color=colors.ORANGE,
	desc = _t[[Faeros are highly intelligent fire elementals, rarely seen outside volcanoes. They are probably not native to this world.]],
	level_range = {25, nil}, exp_worth = 1,
	rarity = 3,
	max_life = resolvers.rngavg(70,80), life_rating = 10,
	combat_armor = 0, combat_def = 20,
	on_melee_hit = { [DamageType.FIRE] = resolvers.mbonus(20, 10), },

	resolvers.talents{
		[Talents.T_FLAME]={base=4, every=10, max=8},
		[Talents.T_FIERY_HANDS]={base=3, every=10, max=7},
	},
	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_FAEROS",
	name = "ultimate faeros", color=colors.ORANGE,
	desc = _t[[Faeros are highly intelligent fire elementals, rarely seen outside volcanoes. They are probably not native to this world.]],
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/elemental_fire_ultimate_faeros.png", display_h=2, display_y=-1}}},
	level_range = {35, nil}, exp_worth = 1,
	rarity = 5,
	rank = 3,
	max_life = resolvers.rngavg(70,80),
	combat_armor = 0, combat_def = 20,
	on_melee_hit = { [DamageType.FIRE] = resolvers.mbonus(20, 10), },

	ai = "tactical",

	resolvers.talents{
		[Talents.T_FLAME]={base=4, every=7},
		[Talents.T_FIERY_HANDS]={base=3, every=7},
		[Talents.T_FLAMESHOCK]={base=3, every=7},
		[Talents.T_INFERNO]={base=3, every=7},
	},
	resolvers.sustains_at_birth(),
}



newEntity{ define_as = "KAM_ELEMENTAL_RUINS_ELEMENTAL_TYRANT",
	type = "elemental", subtype = "harmonic",
	unique = true,
	name = "Elemental Tyrant",
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/atamathon.png", display_h=1, display_y=0}}}, tint=colors.PURPLE, -- Note: Temporary.
	faction = "enemies",
	color = colors.VIOLET,
desc = _t[[Thought to be the height of the Spellwoven elementalist's art, the Harmonic Elemental. It was believed that the only one ever made was Professor Paradise, in the time of the earliest Spellweavers, by some mysterious property.
Somehow, you have found another. 
... however, this one seems enraged and is lashing out at everything around it.
It seems to be able to nullify attacks of most elements, so blindly lashing out at it is unlikely to work.
... this could be a problem.]],
	killer_message = _t"and was also bludgeoned, energized, scorched, frozen, shocked, dissolved, infected, radiated, darkened, and paradoxed, just for good measure, ",
	level_range = {45, nil}, exp_worth = 1,
	rank = 5,
	max_mana = 10000000, -- Its spells cost 0 mana, this remains flavor.
	max_life = 200, life_rating = 15, fixed_rating = true, -- Note: Bulkiness should be kept low because of the defensive gimmick.
	stats = { str=20, dex=20, cun=20, wil=25, mag=25, con=20 }, -- All around good stats.
	size_category = 5,
	infravision = 20, -- There is no escape on this floor.
	instakill_immune = 1,
	move_others=true,
	inc_damage = { all = 100 }, -- Note: For aesthetic purposes. Make sure to tune down damage it does accordingly.
	
	no_difficulty_random_class = true, -- Extremely fixed boss.

--	combat = { dam=resolvers.levelup(8, 1, 0.9), atk=6, apr=3 }, -- It should never attack with melee anyways.

	body = { INVEN = 10 }, -- No equipment.

	resolvers.inscriptions(0, {}),
	resolvers.drops{chance=100, nb=5, {tome_drops="boss"} },
	resolvers.drops{chance=100, nb=1, {defined="KAM_SPELLWEAVERS_ELEMENTAL_HEART"} },
	
	no_auto_resists = true,

	resolvers.talents{
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY]=5,
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY_STRENGTHEN]=5,
		[Talents.T_KAM_ELEMENTS_MOLTEN]=5,
		[Talents.T_KAM_ELEMENTS_MOLTEN_STRENGTHEN]=5,
		[Talents.T_KAM_ELEMENTS_ECLIPSE]=5,
		[Talents.T_KAM_ELEMENTS_ECLIPSE_STRENGTHEN]=5,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN]=5,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN_STRENGTHEN]=5,
		[Talents.T_KAM_ELEMENTS_RUIN]=5,
		[Talents.T_KAM_ELEMENTS_RUIN_STRENGTHEN]=5,
		[Talents.T_KAM_ELEMENTS_GRAVECHILL]=5,
		[Talents.T_KAM_ELEMENTS_GRAVITY]=5,
		[Talents.T_KAM_ELEMENTS_FEVER]=5,
		[Talents.T_KAM_ELEMENTS_MANASTORM]=5,
		[Talents.T_KAM_ELEMENTS_CORRODING_BRILLIANCE]=5,
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY]=5,
		[Talents.T_KAM_ELEMENTS_MOLTEN_MASTERY]=5,
		[Talents.T_KAM_ELEMENTS_ECLIPSE_MASTERY]=5,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY]=5,
		[Talents.T_KAM_ELEMENTS_RUIN_MASTERY]=5,
	},
	resolvers.sustains_at_birth(),

	autolevel = "caster",
	ai = "tactical", ai_state = { talent_in=2 },
	ai_tactic = resolvers.tactic"caster",
	

	-- Cannot move anyways soooo...
	low_level_tactics_override = {escape=0},

	on_die = function(self, who)
		if self.kamControllerElementParticleOne then
			self:removeParticles(self.kamControllerElementParticleOne)
		end
		if self.kamControllerElementParticleTwo then
			self:removeParticles(self.kamControllerElementParticleTwo)
		end
		local Chat = require"engine.Chat" -- Prevents upvalue error to require here.
		local chat = Chat.new("kam-spellweaver-defeated-controller-construct", game.player, game.player) -- Not really a "chat" per say, since it's mostly Events That Happen To You.
		chat:invoke()
	end,
}