load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/autumn_forest.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/cave.lua")

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