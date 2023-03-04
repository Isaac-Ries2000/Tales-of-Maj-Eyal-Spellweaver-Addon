
newChat{ id="welcome",
	text = _t[[#LIGHT_GREEN#*As the Controller Construct crumbles, it starts to glow incredibly brightly with unreleased elemental energy.*
	*It's going to explode!*#WHITE#]],
	answers = {
		{_t"*Pull out the teleport scroll and activate it.*", jump="teleport"},
	}
}

newChat{ id="teleport",
	text = _t[[#LIGHT_GREEN#*The massive release of energy appears to be messing up the teleport. Every item in the room swirls into the warp as you teleport to... somewhere, although you also feel the excess energy restoring you.*]],
	answers = {
		{_t"...", action = function(npc, player)
			game:onTickEnd(function()

				local objs = {} -- Based on Dreamscape, grab up all of the items on the floor and add them to the table.
				for i = 0, game.level.map.w - 1 do 
					for j = 0, game.level.map.h - 1 do
						for z = game.level.map:getObjectTotal(i, j), 1, -1 do
							objs[#objs+1] = game.level.map:getObject(i, j, z)
							game.level.map:removeObject(i, j, z)
						end
					end
				end
				
				-- Section added to make sure that players can be healthy when they get teleported to some random place.
				player:resetToFull() -- Fully heal the player so that they can be safer.
				local effs = {}
				for eff_id, p in pairs(player.tmp) do
					local e = player.tempeffect_def[eff_id]
					if e.status == "detrimental" then effs[#effs+1] = {"effect", eff_id} end
				end
				while #effs > 0 do
					local eff = rng.tableRemove(effs)
					player:removeEffect(eff[2])
				end
				for k, v in pairs(player.talents_cd) do
					player.talents_cd[k] = 0
				end
				--
				
				game:changeLevel(2, (rng.table{"trollmire","ruins-kor-pul","scintillating-caves","rhaloren-camp","norgos-lair","heart-gloom"}), {direct_switch=true})

				game.level.map:particleEmitter(player.x, player.y, 1, "teleport")

				for _, o in ipairs(objs) do -- And now pop all of the items out on the player position so that they don't lose the rod of recall or any boss drops forever, unavoidably.
					game.level.map:addObject(player.x, player.y, o)
				end


				game:onLevelLoad("wilderness-1", function(zone, level, data)
					local list = {}
					for i = 0, level.map.w - 1 do for j = 0, level.map.h - 1 do
						local idx = i + j * level.map.w
						if level.map.map[idx][engine.Map.TERRAIN] and level.map.map[idx][engine.Map.TERRAIN].change_zone == data.from then
							list[#list+1] = {i, j}
						end
					end end
					if #list > 0 then
						game.player.wild_x, game.player.wild_y = unpack(rng.table(list))
					end
				end, {from=game.zone.short_name})

				local chat = require("engine.Chat").new("kam-spellweaver-defeated-controller-construct", npc, player)
				chat:invoke("arrive")
			end)
		end},
	}
}

newChat{ id="arrive",
	text = _t[[#LIGHT_GREEN#*You arrived safely, although you aren't sure where. You'll need to figure out a way home.*]],
	answers = {
		{_t"...", action = function(_, player)
			player:setQuestStatus("start-spellweaver", engine.Quest.COMPLETED, "defeat-controller")
		end},
	}
}

return "welcome"
