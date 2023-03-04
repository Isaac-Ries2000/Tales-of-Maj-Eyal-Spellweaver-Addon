-- 163 24
newEntity{ base="ZONE_PLAINS", define_as = "KAM_WOVEN_HOME_PATH",
	name="path up to Wovenhome",
	color=colors.WHITE,
	add_displays={mod.class.Grid.new{image="terrain/road_upwards_01.png", display_h=2, display_y=-1}},
	change_zone="kam-towns-woven-home",
	desc = _t"The path up to Wovenhome, which is less secret and more just inconveniently placed.",
}

-- 154 10
newEntity{ base="ZONE_PLAINS", define_as = "KAM_ELEMENTAL_RUINS_PATH",
	name="path to some ruins",
	color=colors.WHITE,
	add_displays={mod.class.Grid.new{image="terrain/road_upwards_01.png", display_h=2, display_y=-1}},
	change_zone="kam-spellweaver-elemental-ruins",
	desc = _t"A path up to some abandoned ruins, hidden away in a mountain chain.",
}