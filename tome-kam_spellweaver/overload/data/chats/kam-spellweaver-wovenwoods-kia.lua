local q = game.player:hasQuest("start-spellweaver")
local player = game.player

if q and not q:isCompleted("talked-to-kia") then

	newChat{ id = "welcome",
		text = _t[[#WHITE#Oh, thank the weave, another Spellweaver.]],
		answers = {
			{_t"What happened?", jump="what-happened"},
		}
	}
		
	newChat{ id = "what-happened",
		text = _t[[#WHITE#I was working on enhancing the Controller Construct that lets me keep so many of my Spellwoven animals active at once, but some orc hunter suddenly attacked me and damaged it. Now it's gone haywire and I can't control it or any of my Spellwoven animals.]],
		answers = {
			{_t"I already cleared a path to get here, I'll handle the controller.", jump="solving-problems"},
		}
	}
		
	newChat{ id = "solving-problems",
		text = _t[[#WHITE#Thank you so much. I'll get out of here and find a new patch of forest to restart work in. The Controller Construct might explode when it's destroyed, so make sure to get away before it does.]],
		answers = {
			{_t"I have a teleport scroll. Make sure to stay safe.", action = function(_, player)
				player:setQuestStatus("start-spellweaver", engine.Quest.COMPLETED, "talked-to-kia")
			end}
		}
	}

	return "welcome"

else 
	newChat{ id = "welcome",
		text = _t[[#WHITE#You can go ahead, @playername@. I'm just taking a minute to prepare some spells in case I run into any more berserk animals or excessively hostile orcs. Good luck, and thank you again.]],
		answers = {
			{_t"Don't worry, I've got this."},
		}
	}

	return "welcome"
end