
return {
	name = _t"Wovenhome",
	level_range = {30, 50},
	level_scheme = "player",
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
	update_base_level_on_enter = true,
	max_level = 1,
	width = 47, height = 32,
--	decay = {300, 800, only={object=false}, no_respawn=true}, -- No item despawn, you live here and they aren't jerks.
	persistent = "memory",
	persistent = "zone",
	all_remembered = true,
	day_night = true,
	all_lited = true,
	ambient_music = "Kam Spellweaver Songs - Wovenhome.ogg",
	allow_respec = "limited",

	min_material_level = 3,
	max_material_level = 5,
	effects = {"EFF_ZONE_AURA_KAM_WOVEN_HOME"},
	store_levels_by_restock = { 40, 40, 45, 45, 50, 60 },

	generator =  {
		map = {
			class = "engine.generator.map.Static",
			map = "towns/woven_home",
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {0, 0},
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {0, 0},
		},
	},
	
	post_process = function(level)
		game.state:makeAmbientSounds(level, {
			town_large={ chance=200, volume_mod=1, pitch=1, random_pos={rad=10}, files={"ambient/town/town_large1","ambient/town/town_large2","ambient/town/town_large3"}},
		})
		
		local p = game:getPlayer(true)
		if p.faction ~= "spellweavers" then return end

		game:onTickEnd(function()
			local spot = game.level:pickSpot{type="pop-birth", subtype="spellweavers"}
			game.player:move(spot.x, spot.y, true)
		end)
	end,
}