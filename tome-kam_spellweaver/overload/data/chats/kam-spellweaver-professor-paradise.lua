local player = game.player

local KamCalc = require "mod.KamHelperFunctions"
local Talents = require "engine.interface.ActorTalents"

local elementCount = KamCalc:countSpellwovenElements(player)

if not player.kam_talked_to_professor_paradise and (not player.subclass == "Spellweaver" or elementCount < 15) then

newChat{ id = "welcome",
text = _t[[#SLATE#Strange runes form in air around Professor Paradise, but you cannot make sense of them. Perhaps if you understood elemental Spellweaving better, you could understand them, but this is hopeless.
After a few tries, Professor Paradise floats off.]],
	answers = {
		{_t"*Walk away*"}
	}
}

elseif not player.kam_talked_to_professor_paradise then

newChat{ id = "welcome",
text = _t[[#LIGHT_GREEN#Strange runes form in air around Professor Paradise... it takes a minute, but you recognize them as the Spellwoven elemental runes used in some of the books you read by older Spellweavers. Thinking about their meanings for a moment, you are able to parse out a message:
#WHITE#Hello.]],
	answers = {
		{_t"Hello?", jump="linguistics"}
	}
}

newChat{ id = "linguistics",
text = _t[[#LIGHT_GREEN#Professor Paradise almost startles, then the runes reform into a new message:
#WHITE#You are able to understand elemental runes. You must be quite the elementalist.]],
	answers = {
		{_t"I have studied the elements in the field, and it all clicked when I saw the runes.", jump="linguistics2"}
	}
}

newChat{ id = "linguistics2",
text = _t[[#LIGHT_GREEN#The runes reform into a new message:
#WHITE#Impressive. I will teach you a new Spellweaving technique.]],
	answers = {
		{_t"Thank you.", jump="linguistics-finish"}
	}
}

newChat{ id = "linguistics-finish",
text = _t[[#LIGHT_GREEN#The runes reform into a new message:
#WHITE#Best of luck, young one. You may visit again if you wish to discuss more.]],
	answers = {
		{_t"See you Professor Paradise.", action = function(_, player)
			player:learnTalent(Talents.T_KAM_SHAPE_SMILEY, true)
			player.kam_talked_to_professor_paradise = true
			game.log("#YELLOW#You have learned the Smiley Spell Shape!")
		end}
	}
}

else

newChat{ id = "welcome",
text = _t[[#LIGHT_GREEN#Professor Paradise's runes form into various messages, and you take a moment to chat with Professor Paradise.]],
	answers = {
		{_t"Bye!"}
	}
}
end

return "welcome"