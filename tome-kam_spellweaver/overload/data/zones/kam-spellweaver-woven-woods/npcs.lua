
local Talents = require("engine.interface.ActorTalents")

local elementSets = {
	{
		addText = {"fiery", "flaming", "burning"},
		wildElementCore = "T_KAM_ELEMENTS_MOLTEN",
		wildElement = "T_KAM_ELEMENT_FLAME",
		resistWeaknessText = {"Fire", "Cold"},
		resists = { [DamageType.FIRE] = 50, [DamageType.COLD] = -100 }
	},
	{
		addText = {"frigid", "arctic", "icey"},
		wildElementCore = "T_KAM_ELEMENTS_WIND_AND_RAIN",
		wildElement = "T_KAM_ELEMENT_COLD",
		resistWeaknessText = {"Cold", "Fire"},
		resists = { [DamageType.COLD] = 50, [DamageType.FIRE] = -100 }
	},
	{
		addText = {"thunderous", "shocking", "electric"},
		wildElementCore = "T_KAM_ELEMENTS_WIND_AND_RAIN",
		wildElement = "T_KAM_ELEMENT_LIGHTNING",
		resistWeaknessText = {"Lightning", "Physical"},
		resists = { [DamageType.LIGHTNING] = 50, [DamageType.PHYSICAL] = -100 }
	},
	{
		addText = {"earthen", "stoney", "rocky"},
		wildElementCore = "T_KAM_ELEMENTS_MOLTEN",
		wildElement = "T_KAM_ELEMENT_PHYSICAL",
		resistWeaknessText = {"Physical", "Lightning"},
		resists = { [DamageType.PHYSICAL] = 50, [DamageType.LIGHTNING] = -100 }
	},
	{
		addText = {"shining", "brilliant", "glowing", "beaming", "luminous"},
		wildElementCore = "T_KAM_ELEMENTS_ECLIPSE",
		wildElement = "T_KAM_ELEMENT_LIGHT",
		resistWeaknessText = {"Light", "Darkness"},
		resists = { [DamageType.LIGHT] = 50, [DamageType.DARKNESS] = -100 }
	},
	{
		addText = {"lightless", "shadowey", "darkened", "nightdark", "shaded"},
		wildElementCore = "T_KAM_ELEMENTS_ECLIPSE",
		wildElement = "T_KAM_ELEMENT_DARKNESS",
		resistWeaknessText = {"Darkness", "Light"},
		resists = { [DamageType.DARKNESS] = 50, [DamageType.LIGHT] = -100 }
	},
	{
		addText = {"aetheric", "arcane", "mystic"},
		wildElementCore = "T_KAM_ELEMENTS_OTHERWORLDLY",
		wildElement = "T_KAM_ELEMENT_ARCANE",
		resistWeaknessText = {"Arcane", "Acid"},
		resists = { [DamageType.ARCANE] = 50, [DamageType.ACID] = -100 }
	},
	{
		addText = {"eonic", "temporal", "unending"},
		wildElementCore = "T_KAM_ELEMENTS_OTHERWORLDLY",
		wildElement = "T_KAM_ELEMENT_TEMPORAL",
		resistWeaknessText = {"Temporal", "Blight"},
		resists = { [DamageType.TEMPORAL] = 50, [DamageType.BLIGHT] = -100 }
	},
	{
		addText = {"decaying", "blighted", "foul", "diseased", "rotting"},
		wildElementCore = "T_KAM_ELEMENTS_RUIN",
		wildElement = "T_KAM_ELEMENT_BLIGHT",
		resistWeaknessText = {"Blight", "Temporal"},
		resists = { [DamageType.BLIGHT] = 50, [DamageType.TEMPORAL] = -100 }
	},
	{
		addText = {"acidic", "corrosive", "dissolving"},
		wildElementCore = "T_KAM_ELEMENTS_RUIN",
		wildElement = "T_KAM_ELEMENT_ACID",
		resistWeaknessText = {"Acid", "Arcane"},
		resists = { [DamageType.ACID] = 50, [DamageType.ARCANE] = -100 }
	}
}

local alteringFunction = function(add, mult) 
	add = add or 0
	mult = mult or 1
	return function(e)
		if e.rarity then
			local elementTable = rng.table(elementSets)
			e.type = "construct"
			e.color = colors.PURPLE
			local possible_talents
			if e.rank == 2 or rng.range(1,2) == 2 then
				possible_talents = {"T_KAM_KIA_ANIMAL_BEAM", "T_KAM_KIA_ANIMAL_AOE"}
			else 
				possible_talents = {"T_KAM_KIA_ANIMAL_BEAM"}
			end
			e[#e+1] = resolvers.talents{
				[Talents[rng.table(possible_talents)]] = {base=1, every=5, max=6}, 
				[Talents.T_KAM_KIA_ANIMAL_MELEE] = {base=1, every=5, max=6},
				[Talents[elementTable.wildElementCore]] = 1,
				[Talents.T_KAM_KIA_ANIMAL_PARTICLES] = 1
			}
			e.kamWildElement = elementTable.wildElement
			e.rarity = math.ceil(e.rarity * mult + add)
			e.max_mana = 100
			e.autolevel = "warriormage"
			e.stats.mag = 15
			e.kamWildElementResistText = elementTable.resistWeaknessText
			table.mergeAdd(e.resists, elementTable.resists)
			e.see_invisible = 30

			e.not_power_source = e.not_power_source or {}
			e.not_power_source.antimagic = true
			e.power_source = e.power_source or {}
			e.power_source.arcane = true
			e.power_source.antimagic = false
			
			e.name = rng.table(elementTable.addText).." "..e:getName()
		end
	end
end

load("/data/general/npcs/rodent.lua", alteringFunction(5))
load("/data/general/npcs/vermin.lua", alteringFunction(2))
load("/data/general/npcs/canine.lua", alteringFunction(0))
load("/data/general/npcs/snake.lua", alteringFunction(3))
load("/data/general/npcs/plant.lua", alteringFunction(0))
load("/data/general/npcs/swarm.lua", alteringFunction(3))
load("/data/general/npcs/bear.lua", alteringFunction(2))

newEntity{ define_as = "KAM_WOVENWOODS_CONTROLLER_CONSTRUCT", -- Every 3 turns, realigns, getting 2 weaknesses and 2 resistance (never the same), then gaining that damage type.
	type = "construct", subtype = "spellwoven",
	unique = true,
	name = "Controller Construct",
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/atamathon.png", display_h=1, display_y=0}}}, tint=colors.PURPLE, -- Note: Not the actual atamathon image. Some odd construct that was probably old atamathon?
	faction = "enemies",
	color=colors.VIOLET,
desc = _t[[A strange machination of metal, crystal, and runes, with a glowing core of brilliant purple. Elemental sparks flicker off from it at random angles.
Evidently its been absorbing magical energy, and it seems you have plenty.]],
	killer_message = _t"and drained of all magical energy",
	level_range = {2, nil}, exp_worth = 2,
	max_mana = 5000, -- Its spells cost 0 mana, this is just flavor.
	max_life = 260, life_rating = 13, fixed_rating = true, -- Note: Bulkiness substantially reduced to adjust for the correction of Spellwoven spells incorrect scaling.
	stats = { str=1, dex=10, cun=1, wil=1, mag=10, con=10 }, -- It is a basic construct, it lacks will or cunning entirely since it cannot think.
	rank = 4,
	tier1 = true,
	size_category = 3,
	infravision = 10,
	instakill_immune = 1,
	move_others=true,
	inc_damage = { all = -30}, -- Damage reduction because its supposed to be a relatively easy boss.
	
	see_invisible = 200, -- It's detecting your magic. There is no hiding by using MORE magic.
	
	no_difficulty_random_class = true, -- Too many custom spells, it would work weirdly for MOST possible classes.
	-- Might be worth considering melee classes for harder difficulties since they mostly wouldn't interfere but that's for future testing.

	combat = { dam=resolvers.levelup(8, 1, 0.9), atk=6, apr=3 }, -- Low damage since Elemental Charge is just pure added damage.

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	resolvers.equip{
		{type="weapon", subtype="staff", defined="KAM_COMMAND_CONSTRUCT_STAFF"}, -- Note that it won't benefit from the special effect of the staff since it doesn't actually use Spellwoven spells.
	},
	resolvers.inscriptions(1, {"blink rune"}),
	resolvers.drops{chance=100, nb=3, {tome_drops="boss"} },
	
	no_auto_resists = true,

	resolvers.talents{
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY]=1,
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY_STRENGTHEN]=2,
		[Talents.T_KAM_ELEMENTS_MOLTEN]=1,
		[Talents.T_KAM_ELEMENTS_MOLTEN_STRENGTHEN]=2,
		[Talents.T_KAM_ELEMENTS_ECLIPSE]=1,
		[Talents.T_KAM_ELEMENTS_ECLIPSE_STRENGTHEN]=2,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN]=1,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN_STRENGTHEN]=2,
		[Talents.T_KAM_ELEMENTS_RUIN]=1,
		[Talents.T_KAM_ELEMENTS_RUIN_STRENGTHEN]=2,
		[Talents.T_KAM_ELEMENTS_GRAVECHILL]=1,
		[Talents.T_KAM_ELEMENTS_GRAVITY]=1,
		[Talents.T_KAM_ELEMENTS_FEVER]=1,
		[Talents.T_KAM_ELEMENTS_MANASTORM]=1,
		[Talents.T_KAM_ELEMENTS_CORRODING_BRILLIANCE]=1,
		[Talents.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY]=1,
		[Talents.T_KAM_ELEMENTS_MOLTEN_MASTERY]=1,
		[Talents.T_KAM_ELEMENTS_ECLIPSE_MASTERY]=1,
		[Talents.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY]=1,
		[Talents.T_KAM_ELEMENTS_RUIN_MASTERY]=1,
		[Talents.T_KAM_KIA_CONSTRUCT_SHUFFLE]=1,
		[Talents.T_KAM_KIA_CONSTRUCT_MELEE]=1,
		[Talents.T_KAM_KIA_CONSTRUCT_LINGERING]=1,
		[Talents.T_KAM_KIA_CONSTRUCT_HARM]=1,
		[Talents.T_KAM_KIA_CONSTRUCT_RUSH]=1,
	},
	resolvers.sustains_at_birth(),

	autolevel = "warriormage",
	ai = "tactical", ai_state = { talent_in=2 },
	ai_tactic = resolvers.tactic"caster",
	
--	resolvers.auto_equip_filters("Arcane Blade"),

	-- No kiting.
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

newEntity{ define_as = "KAM_WOVENWOODS_KIA",
	type = "humanoid", subtype = "elf",
	display = "k",
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/humanoid_elenulach_thief.png", display_h=1, display_y=0}}},
	faction = "spellweavers",
	name = "Kia", color=colors.GREEN, unique = true,
desc = ([[Kia, the lifeweaver. One of the stranger Spellweavers, he has spent years working on creating animals with Spellwoven magics. He actually provides a substantial portion of the food for Wovenhome, since he originally started by growing crops with magic, since they're a little simpler.
However, right now, he seems harried and exhausted. Whatever caused the Spellwoven animals to become so hostile, he was definitely no more safe than you.]]):tformat(),
	level_range = {10, nil}, exp_worth = 0,
	rank = 3,
	size_category = 2,
	mana_regen = 10,
	max_mana = 500,
	max_life = 320, life_rating = 10, fixed_rating = true,
	infravision = 5,
	stats = { str=5, dex=6, cun=40, mag=20, con=4, wil=40 }, -- High stats, but only ones that aren't good for actually fighting. He's not good at planning, only at doing stupid things with magic.
	instakill_immune = 1,
	teleport_immune = 1,
	move_others=true,
	combat_spellpower = 10,
	anger_emote = _t"",
	hates_antimagic = 0,
	invulnerable = 1,
	negative_status_effect_immune = 1,

	open_door = true,

	resolvers.inscriptions(1, "rune"),
	resolvers.inscriptions(1, {"manasurge rune"}),

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },

	resolvers.equip{
		{type="weapon", subtype="staff", autoreq=true, forbid_power_source={antimagic=true}, tome_drops="store"},
		{type="armor", subtype="cloth", autoreq=true, forbid_power_source={antimagic=true}, tome_drops="store"},
	},

	resolvers.talents{
		[Talents.T_KAM_SPELLWEAVER_CORE]=3,
		[Talents.T_KAM_SPELLWEAVER_POWER]=1,
		[Talents.T_KAM_SPELLWEAVER_FINESSE]=5,
		[Talents.T_KAM_SPELLWEAVER_ADEPT]=3,
		[Talents.T_KAM_SPELLWOVEN_MASTERY]=3,
		[Talents.T_KAM_SPELLWOVEN_PERFECTION]=5,
		[Talents.T_KAM_SPELLWEAVER_SHIELDS_CORE]=3,
		[Talents.T_KAM_SPELLWEAVER_WARP_CORE]=3,
		[Talents.T_KAM_NATURAL_SPELLWEAVING_CORE]=1,
		[Talents.T_KAM_NATURAL_SPELLWEAVING_STRENGTHEN]=2,
		[Talents.T_KAM_NATURAL_SPELLWEAVING_SUSTAIN]=2,
		[Talents.T_KAM_NATURAL_SPELLWEAVING_UNITY]=1,
		[Talents.T_KAM_FAKE_ELEMENT_NATURE]=1,
		[Talents.T_KAM_FAKE_TALENT_LIFEWEAVE]=5,
	},
	
	can_talk = "kam-spellweaver-wovenwoods-kia",
}