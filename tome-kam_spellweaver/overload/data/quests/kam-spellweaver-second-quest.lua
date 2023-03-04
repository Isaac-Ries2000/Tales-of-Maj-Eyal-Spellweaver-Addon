-- Starting quest.
name = _t"Threads of the Past"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = _t"Following your return, Grath of the Wovenhome Orcs has asked you to look into an old ruin that some orcs from the Vor Pride had been poking around in."
	desc[#desc+1] = _t"It can apparently be found by following the river to the north of Wovenhome to the west and up into the mountains nearby."
	desc[#desc+1] = _t"The Spellweavers have built very little outside of Wovenhome, so the exact story behind the ruin is unclear."
	if not self:isCompleted("ruins-found") then
		desc[#desc+1] = _t"#SLATE#* The ruins should be found by following the river to the north of Wovenhome to the west and up into the mountains.#WHITE#"
	else
		desc[#desc+1] = _t"#LIGHT_GREEN#* You have found the ruins. There was a strange warning, but it appears that the Vor pride orcs already entered...#WHITE#"
	end
	if self:isCompleted("defeat-tyrant") then
		desc[#desc+1] = _t"#LIGHT_GREEN#* At the bottom, you found a powerful elemental who you managed to defeat. You should report back to Grath.#WHITE#"
	end
	if self:isStatus(engine.Quest.DONE) then 
		desc[#desc+1] = _t"#LIGHT_GREEN#* Grath has been notified, and you recieved an enchanted token as well as the appreciation of the Wovenhome orcs." 
	end
	return table.concat(desc, "\n")
end

on_grant = function(self, who) -- Add the dungeon to the map.
	game:onLevelLoad("wilderness-1", function(zone, level)
		local g = game.zone:makeEntityByName(game.level, "terrain", "KAM_ELEMENTAL_RUINS_PATH")
		local spot = {153, 10}
		game.zone:addEntity(level, g, "terrain", spot[1], spot[2])
		game.nicer_tiles:updateAround(game.level, spot[1], spot[2])
		game.state:locationRevealAround(spot[1], spot[2])
	end)
end

on_status_change = function(self, who, status, sub)
	if self:isCompleted("returnToGrath") then
		who:setQuestStatus(self.id, engine.Quest.DONE)
	end
end