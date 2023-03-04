local DamageType = require "engine.DamageType"
local possibleElementDescriptors = {
	{
		id = "fire",
		addText = {"fiery", "flaming", "burning", "ashen", "incinerating"},
		coreElement = "T_KAM_ELEMENTS_MOLTEN",
		elementDamageTalent = "T_KAM_ELEMENT_FLAME",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Fire).ogg",
		element = DamageType.FIRE,
	},
	{
		id = "physical",
		addText = {"earthen", "stoney", "rocky", "muddy", "solid"},
		coreElement = "T_KAM_ELEMENTS_MOLTEN",
		elementDamageTalent = "T_KAM_ELEMENT_PHYSICAL",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Earth).ogg",
		element = DamageType.PHYSICAL,
	},
	{
		id = "ice",
		addText = {"frigid", "arctic", "icey", "chilling", "freezing"},
		coreElement = "T_KAM_ELEMENTS_WIND_AND_RAIN",
		elementDamageTalent = "T_KAM_ELEMENT_COLD",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Ice).ogg",
		element = DamageType.COLD,
	},
	{
		id = "lightning",
		addText = {"thunderous", "shocking", "electric", "sparking", "crackling"},
		coreElement = "T_KAM_ELEMENTS_WIND_AND_RAIN",
		elementDamageTalent = "T_KAM_ELEMENT_LIGHTNING",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Lightning).ogg",
		element = DamageType.LIGHTNING,
	},
	{
		id = "light",
		addText = {"shining", "brilliant", "glowing", "beaming", "luminous", "coruscant"},
		coreElement = "T_KAM_ELEMENTS_ECLIPSE",
		elementDamageTalent = "T_KAM_ELEMENT_LIGHT",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Light).ogg",
		element = DamageType.LIGHT,
	},
	{
		id = "dark",
		addText = {"lightless", "shadowey", "darkened", "nightdark", "shaded", "faint"},
		coreElement = "T_KAM_ELEMENTS_ECLIPSE",
		elementDamageTalent = "T_KAM_ELEMENT_DARKNESS",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Dark).ogg",
		element = DamageType.DARKNESS,
	},
	{
		id = "arcane",
		addText = {"aetheric", "arcane", "mystic", "sorcerous", "enchanted"},
		coreElement = "T_KAM_ELEMENTS_OTHERWORLDLY",
		elementDamageTalent = "T_KAM_ELEMENT_ARCANE",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Arcane).ogg",
		element = DamageType.ARCANE,
	},
	{
		id = "temporal",
		addText = {"eonic", "temporal", "unending", "timeless", "ageless"},
		coreElement = "T_KAM_ELEMENTS_OTHERWORLDLY",
		elementDamageTalent = "T_KAM_ELEMENT_TEMPORAL",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Temporal).ogg",
		element = DamageType.TEMPORAL,
	},
	{
		id = "blight",
		addText = {"decaying", "blighted", "foul", "diseased", "rotting"},
		coreElement = "T_KAM_ELEMENTS_RUIN",
		elementDamageTalent = "T_KAM_ELEMENT_BLIGHT",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Blight).ogg",
		element = DamageType.BLIGHT,
	},
	{
		id = "acid",
		addText = {"acidic", "corrosive", "dissolving", "melting", "caustic"},
		coreElement = "T_KAM_ELEMENTS_RUIN",
		elementDamageTalent = "T_KAM_ELEMENT_ACID",
		music = "Kam Spellweaver Songs - Elemental Annihilation (Acid).ogg",
		element = DamageType.ACID,
	}
}

local elementsTable = {}

for i = 1, 5 do
	local eleOne = rng.table(possibleElementDescriptors)
	local eleTwo = eleOne
	while (eleTwo == eleOne) do
		eleTwo = rng.table(possibleElementDescriptors)
	end
	local eleThree = eleOne
	while (eleThree == eleOne or eleThree == eleTwo) do
		eleThree = rng.table(possibleElementDescriptors)
	end
	
	elementsTable[i] = {eleOne, eleTwo, eleThree}
end
local function addElement(act, index, element)
	act["kamElementalRuinsElement"..index] = element.id
	act.name = (rng.table(element.addText)).." "..(act:getName())
	if (not act:knowTalent(element.coreElement)) then
		act:learnTalent(element.coreElement, true, (math.floor(math.min(act.level - 35, 0) / 5) + 5))
	end
	act["kamElementalRuinsDamageTalent"..index] = element.elementDamageTalent
	act["kamElementalRuinsDamageType"..index] = element.element
	act.resists = act.resists or {}
	act.resists[element.element] = 50
end

local function addElementHelperMatchElement(act, index, element)
	for key, elementTable in pairs(possibleElementDescriptors) do
		if (element == elementTable.id) then
			addElement(act, index, elementTable)
			break
		end
	end
end


local function applyFloorElements(act, level) 
	local elementOne = nil
	local elementTwo = nil
	while (elementOne == elementTwo) do
		elementOne = rng.table(elementsTable[level])
		elementTwo = rng.table(elementsTable[level])
	end
	addElement(act, 1, elementOne)
	addElement(act, 2, elementTwo)
end

return {
	name = _t"Elemental Ruins",
	level_range = {35, 60},
	level_scheme = "player",
	kam_elemental_ruins_element_table = elementsTable,
	kam_elemental_ruins_possible_elements_table = possibleElementDescriptors,
	max_level = 7, -- Note: 1st floor is a safe floor, 7th floor only contains boss.
	decay = {300, 800},
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
	width = 50, height = 50,
--	all_remembered = true,
	all_lited = true,
	ambient_music = "Kam Spellweaver Songs - Woven Woods.ogg",
	min_material_level = 4,
	max_material_level = 5,
	effects = {"EFF_ZONE_AURA_KAM_ELEMENTAL_RUINS"}, -- Say goodbye to resistance piercing.
	generator =  {
		map = {
			class = "engine.generator.map.Roomer",
			nb_rooms = 10,
			rooms = {"!kam_element_invasion"},
			--rooms = {"random_room", {"!kam_element_invasion", 8}},
			up = "UP",
			down = "DOWN",
			door = "DOOR",
			['.'] = "FLOOR",
			['#'] = "WALL",
			lite_room_chance = 100,
		},
		actor = {
			class = "mod.class.generator.actor.Random",
			nb_npc = {7, 10},
			filters = { {max_ood=2}, },
			randelite = 0,
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {6, 9},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {3, 6},
		},
	},
	levels =
	{
		[1] = {
			generator =  { 
				map = {
					class = "engine.generator.map.Static",
					map = "zones/kam_elemental_ruins_entry_floor",
				},
				actor = {
					class = "mod.class.generator.actor.Random",
					nb_npc = {0, 0},
					randelite = 0,
				}, 
				object = {
					class = "engine.generator.object.Random",
					nb_object = {0, 0},
				},
				trap = {
					class = "engine.generator.trap.Random",
					nb_trap = {0, 0},
				},
			},
		},
		[2] = {
			ambient_music = {elementsTable[1][1].music, elementsTable[1][2].music, elementsTable[1][3].music},
			generator = {
				map = {
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				},
			},
		},
		[3] = {
			ambient_music = {elementsTable[2][1].music, elementsTable[2][2].music, elementsTable[2][3].music},
			generator = {
				map = {
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				},
			},
		},
		[4] = {
			ambient_music = {elementsTable[3][1].music, elementsTable[3][2].music, elementsTable[3][3].music},
			generator = {
				map = {
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				},
			},
		},
		[5] = {
			ambient_music = {elementsTable[4][1].music, elementsTable[4][2].music, elementsTable[4][3].music},
			generator = {
				map = {
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				},
			},
		},
		[6] = {
			ambient_music = {elementsTable[5][1].music, elementsTable[5][2].music, elementsTable[5][3].music},
			generator = {
				map = {
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				},
			},
		},
		[7] = {
			generator =  { 
				map = {
					class = "engine.generator.map.Static",
					map = "zones/kam_woven_woods_boss_floor",
				},
				actor = {
					class = "mod.class.generator.actor.Random",
					nb_npc = {0, 0},
					randelite = 0,
				}, 
			},
		},
	},
	post_process = function(level)
		if level.level == 2 then
			game:placeRandomLoreObject("KAM_SPELLWEAVER_ELEMENTAL_RUINS1")
			game:placeRandomLoreObject("KAM_SPELLWEAVER_ELEMENTAL_RUINS2")
		end
		if (level.level >= 3) and (level.level < 7) then
			game:placeRandomLoreObject("KAM_SPELLWEAVER_ELEMENTAL_RUINS"..level.level)
		end
		local Map = require "engine.Map"
		if (level.level > 1 and level.level < 7) then
			for i = 1, level.map.w do 
				for j = 1, level.map.h do
					local act = level.map(i, j, Map.ACTOR)
					if (act and act ~= game.player) then
						applyFloorElements(act, level.level)
						if (level.map.room_map[i][j].kam_elemental_ruins_element_floor) then
							addElementHelperMatchElement(act, 3, level.map.room_map[i][j].kam_elemental_ruins_element_floor)
						end
					end
				end
			end
		end
	end,
}
