-- Starting quest.
name = _t"Weaver of Life"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = _t"You have been studying Spellweaving at Wovenhome for many years."
	desc[#desc+1] = _t"However, this quiet lifestyle has simply become boring, so you have asked Professor Hundredeyes for more field work."
	desc[#desc+1] = _t"Now you are going to go to the Woven Woods, where a Spellweaver named Kia, who specializes in the creation of animal-like Spellwoven constructs, has gone silent and stopped sending regular shipments of food."
	desc[#desc+1] = _t"Professor Hundredeyes can send you to the Woven Woods when you are prepared."
	if not (self:isCompleted("talked-to-kia") or self:isCompleted("defeat-controller")) then
		desc[#desc+1] = _t"#SLATE#* Kia should be somewhere in the Woven Woods. You need to find and help him.#WHITE#"
	else
		desc[#desc+1] = _t"#LIGHT_GREEN#* You have made it through the Spellwoven creatures and found Kia.#WHITE#"
		if self:isCompleted("defeat-controller") then 
			desc[#desc+1] = _t"#LIGHT_GREEN#* You have defeated the controller construct, although the magical backlash has sent you somewhere unexpected..." 
		else
			desc[#desc+1] = _t"#SLATE#* Now you need to destroy the controller construct to ensure the Spellwoven creatures cause no more problems."
		end
	end
	if self:isStatus(engine.Quest.DONE) then 
		desc[#desc+1] = _t"#LIGHT_GREEN#* You have returned safely to Wovenhome, although it seems that there is no time to rest on your laurels." 
	end
	return table.concat(desc, "\n")
end

on_grant = function(self, who)
	if who.faction == "undead" then -- Spellweavers always have the "illusion" up. 
		who.faction = "spellweavers"
		if who.descriptor and who.descriptor.race and who:attr("undead") then who.descriptor.fake_race = "Human" end
		if who.descriptor and who.descriptor.subrace and who:attr("undead") then who.descriptor.fake_subrace = "Cornac" end
		local o = game.zone:makeEntityByName(game.level, "object", "KAM_SPELLWEAVER_ORB_OF_ILLUSIONS")
		if not o then return end
		o:identify(true)
		game.zone:addEntity(game.level, o, "object")
		who:addObject(who:getInven("INVEN"), o)
	end
	
	-- Reveal Wovenhome on the map.
	game:onLevelLoad("wilderness-1", function(zone, level)
		local spot = level:pickSpot({type = "playerpop", subtype = "woven-home-start"})
		game.state:locationRevealAround(spot.x, spot.y)
	end)
	
	local npc
	for uid, e in pairs(game.level.entities) do
		if e.define_as and e.define_as == "KAM_WOVENHOME_PROF_HUNDREDEYES" then npc = e break end
	end

	local Chat = require"engine.Chat"
	local chat = Chat.new("kam-spellweaver-professor-hundredeyes-start-quest", npc, who)
	chat:invoke()
end

on_status_change = function(self, who, status, sub)
	if self:isCompleted("return") then
		who:setQuestStatus(self.id, engine.Quest.DONE)
	end
end