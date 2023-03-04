
return {
	name = _t"Woven Woods",
	level_range = {1, 7},
	level_scheme = "player",
	max_level = 4, -- Note: 4th floor only contains boss.
	decay = {300, 800},
	actor_adjust_level = function(zone, level, e) return zone.base_level + level.level-1 + e:getRankLevelAdjust() + 1 end,
	width = 50, height = 54,
	tier1 = true,
--	all_remembered = true,
	all_lited = true,
	persistent = "zone",
	ambient_music = "Kam Spellweaver Songs - Woven Woods.ogg",
	max_material_level = 1,
	nicer_tiler_overlay = "DungeonWallsGrass",
	generator =  {
		map = {
			class = "engine.generator.map.Roomer",
			nb_rooms = 10,
			rooms = {"forest_clearing"},
			edge_entrances = {2,8},
			up = "GRASS_UP2",
			down = "GRASS_DOWN8",
			door = "GRASS",
			['.'] = function() if rng.chance(20) then return "FLOWER" else return "GRASS" end end,
			['#'] = "TREE",
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
			nb_trap = {0, 0},
		},
	},
	levels =
	{
		[1] = {
			generator = { 
				map = {
					up = "GRASS",
					do_ponds = {
						nb = {0, 2},
						size = {w=25, h=25},
						pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
					},
				}, 
			},
		},
		[2] = {
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
			generator =  { 
				map = {
					class = "engine.generator.map.Static",
					map = "zones/kam_woven_woods_entry_to_boss",
				}, 
--				do_ponds = {
--					nb = {0, 1},
--					size = {w=25, h=25},
--					pond = {{0.6, "DEEP_WATER"}, {0.8, "DEEP_WATER"}},
--				},
			},
		},
		[4] = {
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
		if level.level == 4 then
			game.log("As you enter the room, a stray bolt of magic damages the stairs behind you. It seems like there's no way out.")
		end
	end,
}
