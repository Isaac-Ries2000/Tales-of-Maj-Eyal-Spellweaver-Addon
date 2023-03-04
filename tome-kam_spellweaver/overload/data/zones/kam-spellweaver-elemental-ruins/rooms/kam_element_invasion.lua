-- Modified version of data\rooms\random_room.lua

local list = {
	"simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple", "simple"}--,
--	"pilar", "oval","s","cells","inner_checkerboard","y","inner","small_inner_cross","small_cross","big_cells","cells2","inner_cross","cells3","cells4","cells5","cells6","cross","equal2","pilar2","cells7","cells8","double_y","equal","center_arrows","h","pilar_big",
--	"big_cross", "broken_room", "cells9", "double_helix", "inner_fort", "multi_pillar", "split2", "womb", "big_inner_circle", "broken_x", "circle_cross", "inner_circle2", "inner_pillar", "small_x", "weird1", "xroads", "broken_infinity", "cells10", "cross_circled", "inner_circle", "micro_pillar", "split1", "weird2",
--	"basic_cell", "circular", "cross_quartet", "double_t", "five_blocks", "five_pillars", "five_walls", "four_blocks", "four_chambers", "hollow_cross", "interstice", "long_hall", "long_hall2", "narrow_spiral", "nine_chambers", "sideways_s", "side_passages_2", "side_passages_4", "spiral_cell", "thick_n", "thick_wall", "tiny_pillars", "two_domes", "two_passages", "zigzag",
--}

local max_w, max_h = 50, 50

-- Load a random normal room file and use it
return function(gen, id, lev, old_lev)

	local roomfile = rng.table(list)
	local room = gen:loadRoom(roomfile)
	-- If this is a function, we can just return the room's method
	local retval
	if type(room) == "function" then 
		retval = room(gen, id, lev, old_lev)
	else 
		retval = room 
	end
	if (type(retval) == "table") then
		retval.kam_elemental_ruins_old_generator_func = retval.generator
		local elements = gen.zone.kam_elemental_ruins_element_table[lev]
		local element = rng.table(gen.zone.kam_elemental_ruins_possible_elements_table)
		while (element == elements[1] or element == elements[2] or element == elements[3]) do
			element = rng.table(gen.zone.kam_elemental_ruins_possible_elements_table)
		end
		retval.generator = function(self, x, y, is_lit)
			gen.self_tiles = gen.self_tiles or {}
			local tempFloorStore = gen.self_tiles["."] or "FLOOR"
			local tempWallStore = gen.self_tiles["#"] or "WALL"
			gen.self_tiles["."] = "GRASS"
			gen.self_tiles["#"] = "TREE"
			
			retval.kam_elemental_ruins_old_generator_func(self, x, y, is_lit)
			gen.self_tiles["."] = tempFloorStore
			gen.self_tiles["#"] = tempWallStore
			
			for i = x, x + self.w - 1 do 
				for j = y, y + self.h - 1 do
					gen.map.room_map[i][j].kam_elemental_ruins_element_floor = element["id"]
					if is_lit then
						gen.map.lites(i, j, true) 
					end
				end 
			end
		end
	else
		local room_map = engine.Map.new(max_w, max_h)
		local data = table.clone(gen.data)
		data.map = retval
		local room = data.map and Static.new(gen.zone, room_map, gen.level, data)
		room:generate(lev, old_lev)
		local w = room_map.w
		local h = room_map.h
		local elements = gen.zone.kam_elemental_ruins_element_table[lev]
		local element = rng.table(gen.zone.kam_elemental_ruins_possible_elements_table)
		while (element == elements[1] or element == elements[2] or element == elements[3]) do
			element = rng.table(gen.zone.kam_elemental_ruins_possible_elements_table)
		end
		return { name="invasion_room-"..roomfile.."-"..w.."x"..h, w=w, h=h,
			generator = function(self, x, y, is_lit)
				for i = x, x + w - 1 do 
					for j = y, y + h - 1 do
						gen.map.room_map[i][j].kam_elemental_ruins_element_floor = element["id"]
						if is_lit then 
							gen.map.lites(i-1+x, j-1+y, true) 
						end
					end 
				end
			end,
			removed = function(self, lev, old_lev) -- clean up any uniques spawned if the vault can't be placed
				vault:removed(lev, old_lev)
			end
		}
	end
--	gen.data['.'] = "FLOOR"
--	gen.data['#'] = "WALL"
	return retval
end
