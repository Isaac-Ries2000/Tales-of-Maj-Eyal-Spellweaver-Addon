load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/autumn_forest.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/cave.lua")
load("/data/general/grids/mountain.lua")

newEntity{ base="WATER_BASE",
	define_as = "ELEMENTAL_RUINS_SHALLOW_WATER",
	name = "shallow water",
	image="terrain/water_grass_5_1.png",
}

newEntity{
	define_as = "ELEMENTAL_RUINS_FIRST_DOWN",
	name = "entrance to the Elemental Ruins",
	display = '>', color=colors.PURPLE, image = "terrain/marble_floor.png", add_mos = {{image = "terrain/stair_down.png"}},
	notice = true,
	always_remember = true,
	change_level = 2, -- change_zone = "kam-spellweaver-elemental-ruins",
	block_move = function(self, x, y, who, act)
		if self.kam_lore_got or not who or not who.player or not act then 
			return false 
		end
		game.party:learnLore("kam-spellweaver-elemental-ruins-entry")
		self.block_move = nil
		self.kam_lore_got = true
		return false
	end,
}