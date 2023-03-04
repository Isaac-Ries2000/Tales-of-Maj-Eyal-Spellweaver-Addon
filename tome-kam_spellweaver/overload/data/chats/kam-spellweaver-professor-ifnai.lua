local player = game.player

local KamCalc = require "mod.KamHelperFunctions"
local Talents = require "engine.interface.ActorTalents"

local artifactCount = 0 -- Ifnai's historical interest means that the more artifacts you have, the cooler xe thinks you are. Plot and quest excluded though because those Don't Count.

player:inventoryApplyAll(function(inven, item, object)
	if object.unique and not object.plot and not object.quest then
		artifactCount = artifactCount + 1
	end
end)

if (not player.kam_talked_to_professor_ifnai) and (not (player.descriptor.subclass == "Spellweaver" and artifactCount >= 10)) then

newChat{ id = "welcome",
text = _t[[Ah, @playername@. Are you here for some historical lecture transcriptions?]],
	answers = {
		{_t"What lectures do you have?", action=function(npc, player)
			npc.store:loadup(game.level, game.zone)
			npc.store:interact(player)
		end},
		{_t"Do you need any help?", jump = "hinttext"},
		{_t"I don't need any right now."}
	}
}

newChat{ id = "hinttext", -- Artifacts hint hint.
text = _t[[Hmm... well, I do not know if there's much you could help with. I'm just doing some historical research. Recently I have been researching notable adventuring equipment. Some of those artifacts were created thousands of years ago and are still in incredible shape today.]],
	answers = {
		{_t"Makes sense."}
	}
}

elseif not player.kam_talked_to_professor_ifnai then


newChat{ id = "welcome",
text = _t[[#LIGHT_GREEN# Professor Ifnai turns to look at you, then startles.
#WHITE#... @playername@, where in the world did you get all of that? Do you know what some of this stuff is?]],
	answers = {
		{_t"What?", jump="artifacts"}
	}
}

newChat{ id = "artifacts",
text = _t[[Those artifacts you're carrying. Some of those are ancient, some made with incredible techniques we don't even know anymore. You #{bold}#must#{normal}# let me take a look at them. I could even, say, teach you a special, rare Spellweaving technique in exchange?]],
	answers = {
		{_t"Deal.", jump="artifacts2"}
	}
}

newChat{ id = "artifacts2",
text = _t[[Here. By channeling magic like this, you can shape your spell into a new shape...
#LIGHT_GREEN#This description continues for some time.#WHITE#]],
	answers = {
		{_t"Thank you.", jump="artifacts-finish"}
	}
}

newChat{ id = "artifacts-finish",
text = _t[[No, thank you. It's been a long time since I've seen such an excellent collection of artifacts. Feel free to come back and show me more any time.]],
	answers = {
		{_t"Will do, Professor Ifnai.", action = function(_, player)
			player:learnTalent(Talents.T_KAM_SHAPE_EIGHTPOINT, true)
			player.kam_talked_to_professor_ifnai = true
			game.log("#YELLOW#You have learned the Eightpoint Spell Shape!")
		end}
	}
}

else

newChat{ id = "welcome",
text = _t[[Ah, @playername@. Do you need any more transcriptions from old Spellweaving lectures? Or have you found any interesting artifacts or historical information while you were adventuring?]],
	answers = {
		{_t"What lectures do you have?", action=function(npc, player)
			npc.store:loadup(game.level, game.zone)
			npc.store:interact(player)
		end},
		{_t"*Spend a while talking about history and artifacts with Professor Ifnai.*"}
	}
}
end

return "welcome"