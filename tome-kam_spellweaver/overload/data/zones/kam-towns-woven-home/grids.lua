
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/mountain.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/basic.lua")
load("/data/general/grids/fortress.lua")
--load("/data/general/grids/sand.lua") -- In case I add this back so I don't have to find it again.

newEntity{
	define_as = "APPROXIMATE_CAULDRON",
	type = "wall", subtype = "floor",
	name = "bubbling cauldron", image = "terrain/marble_floor.png", add_mos={{image="terrain/troll_stew.png"}},
	display = '~', color=colors.LIGHT_RED, back_color=colors.RED,
	does_block_move = true,
	pass_projectile = true,
}

newEntity{ -- Undiggable renamed glass walls.
	define_as = "KAM_WINDOW",
	type = "wall", subtype = "floor",
	name = "window", image = "terrain/glasswall.png",
	display = '#', color=colors.AQUAMARINE, back_color=colors.GREY,
	z = 3,
	nice_tiler = { method="wall3d", inner="KAM_WINDOWF", north="KAM_WINDOW_NORTH", south="KAM_WINDOW_SOUTH", north_south="KAM_WINDOW_NORTH_SOUTH", small_pillar="KAM_WINDOW_SMALL_PILLAR", pillar_2="KAM_WINDOW_PILLAR_2", pillar_8="KAM_WINDOW_PILLAR_8", pillar_4="KAM_WINDOW_PILLAR_4", pillar_6="KAM_WINDOW_PILLAR_6" },
	does_block_move = true,
	can_pass = {pass_wall=1},
	air_level = -20,
}

newEntity{ base = "KAM_WINDOW", define_as = "KAM_WINDOWF", image = "terrain/marble_floor.png",add_mos={{image = "terrain/glass/wall_glass_middle_01_64.png"}}}
newEntity{ base = "KAM_WINDOW", define_as = "KAM_WINDOW_NORTH", image = "terrain/marble_floor.png",add_mos={{image = "terrain/glass/wall_glass_middle_01_64.png"}}, z = 3, add_displays = {class.new{image="terrain/glass/wall_glass_top_01_64.png", z=18, display_y=-1}}}
newEntity{ base = "KAM_WINDOW", define_as = "KAM_WINDOW_NORTH_SOUTH", image = "terrain/marble_floor.png",add_mos={{image = "terrain/glass/wall_glass_01_64.png"}}, z = 3, add_displays = {class.new{image="terrain/glass/wall_glass_top_01_64.png", z=18, display_y=-1}}}
newEntity{ base = "KAM_WINDOW", define_as = "KAM_WINDOW_SOUTH", image = "terrain/marble_floor.png",add_mos={{image = "terrain/glass/wall_glass_01_64.png"}}, z = 3}
newEntity{ base = "KAM_WINDOW_NORTH_SOUTH", define_as = "KAM_WINDOW_PILLAR_6"}
newEntity{ base = "KAM_WINDOW_NORTH_SOUTH", define_as = "KAM_WINDOW_PILLAR_4"}
newEntity{ base = "KAM_WINDOW_NORTH_SOUTH", define_as = "KAM_WINDOW_SMALL_PILLAR"}
newEntity{ base = "KAM_WINDOW_NORTH", define_as = "KAM_WINDOW_PILLAR_8"}
newEntity{ base = "KAM_WINDOW_SOUTH", define_as = "KAM_WINDOW_PILLAR_2"}

local gold_mountain_editer = {method="borders_def", def="gold_mountain"}
newEntity{
	define_as = "GOLDEN_MOUNTAIN",
	type = "rockwall", subtype = "grass",
	name = "Sunwall mountain", image = "terrain/golden_mountain5_1.png",
	display = '#', color=colors.GOLD, back_color={r=44,g=95,b=43},
	always_remember = true,
	does_block_move = true,
	block_sight = true,
	block_sense = true,
	block_esp = true,
	air_level = -20,
	nice_editer = gold_mountain_editer,
	nice_tiler = { method="replace", base={"GOLDEN_MOUNTAIN_WALL", 70, 1, 6} },
}
for i = 1, 6 do newEntity{ base="GOLDEN_MOUNTAIN", define_as = "GOLDEN_MOUNTAIN_WALL"..i, image = "terrain/golden_mountain5_"..i..".png"} end

newEntity{
	define_as = "KAM_WOVENHOME_PATH_TO_WILDERNESS",
	type = "floor", subtype = "floor", road="oldstone",
	name = "exit to the worldmap", image = "terrain/marble_floor.png", add_mos = {{image="terrain/worldmap.png"}},
	display = '<', color_r=255, color_g=0, color_b=255,
	change_level_check = function() -- No leaving before doing the quest (no never look back and there again for you).
		local q = game.player:hasQuest("start-spellweaver")
		if q and not q:isCompleted("defeat-controller") then
			game.log("You need to talk to Professor Hundredeyes to get to the Woven Woods, since orc patrols make the journey dangerous otherwise.") 
			return true 
		end 
		return false
	end,
	always_remember = true,
	notice = true,
	change_level = 1,
	change_zone = "wilderness",
	nice_editer2 = { method="roads_def", def="oldstone" },
}


newEntity{
	define_as = "KAM_WOVENHOME_BIG_TREE",
	type = "wall", subtype = "grass",
	name = "Weaver's Tree",
	image = "terrain/grass.png",
	add_displays = {
		class.new{image="terrain/trees/willow_02_shadow.png", display_x=0, display_y=0, display_w=1, display_h=1, z = 16},
		class.new{image="terrain/trees/willow_02_trunk.png", display_x=0, display_y=0, display_w=1, display_h=1, z = 17}, 
		class.new{image="terrain/trees/willow_moss_foliage_summer.png", display_x=0, display_y=-1, display_w=1, display_h=2, z = 18}, 
	},
	display = '#', color=colors.LIGHT_GREEN, back_color={r=44,g=95,b=43},
	always_remember = true,
	can_pass = {pass_tree=1},
	does_block_move = true,
	block_sight = true,
	nice_editer = grass_editer,
}

